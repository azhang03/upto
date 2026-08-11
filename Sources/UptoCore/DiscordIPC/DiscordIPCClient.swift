import Foundation

// The client that talks to the local Discord desktop app. It scans for
// the IPC socket, performs the handshake, keeps the connection alive,
// and replays the last requested presence after every reconnect.
//
// Callers set a desired presence with setActivity and never think about
// rate limits or reconnects. The newest request always wins.
public actor DiscordIPCClient {
    public private(set) var state: ConnectionState = .idle

    private let transportFactory: any IPCTransportFactory
    private let locator: any SocketLocator
    private let backoffPolicy: BackoffPolicy
    private let handshakeTimeout: Duration
    private let keepaliveInterval: Duration
    private let clock = ContinuousClock()

    private var applicationID: String?
    private var connection: (any IPCTransportConnection)?
    private var frameDecoder = FrameDecoder()
    private var generation = 0

    private var scanTask: Task<Void, Never>?
    private var eventTask: Task<Void, Never>?
    private var backoffTask: Task<Void, Never>?
    private var keepaliveTask: Task<Void, Never>?
    private var drainWakeupTask: Task<Void, Never>?

    private var backoffAttempt = 0
    private var bucket: TokenBucket

    private enum ActivitySlot {
        case unset
        case clear
        case set(Activity)
    }

    private var desired: ActivitySlot = .unset
    private var dirty = false
    private var inflightNonce: String?

    private enum HandshakeOutcome {
        case ready(DiscordUser?)
        case connectFailed
        case closedEarly
        case timedOut
        case sendFailed
        case cancelled
    }

    private var handshakeContinuation: CheckedContinuation<HandshakeOutcome, Never>?
    private var subscribers: [UUID: AsyncStream<ClientEvent>.Continuation] = [:]

    public init(
        transport: any IPCTransportFactory = UnixSocketTransportFactory(),
        locator: any SocketLocator = DiscordSocketLocator(),
        backoff: BackoffPolicy = .default,
        handshakeTimeout: Duration = .seconds(5),
        keepaliveInterval: Duration = .seconds(60),
        bucket: TokenBucket = TokenBucket()
    ) {
        self.transportFactory = transport
        self.locator = locator
        self.backoffPolicy = backoff
        self.handshakeTimeout = handshakeTimeout
        self.keepaliveInterval = keepaliveInterval
        self.bucket = bucket
    }

    // MARK: Public API

    public func connect(applicationID: String) {
        self.applicationID = applicationID.trimmingCharacters(in: .whitespacesAndNewlines)
        cancelAllWork()
        tearDownConnection()
        backoffAttempt = 0
        setState(.scanning)
        startScan()
    }

    public func disconnect() {
        cancelAllWork()
        tearDownConnection()
        setState(.idle)
    }

    // Passing nil clears the presence. The desired activity survives
    // disconnects so it can be replayed on the next READY.
    public func setActivity(_ activity: Activity?) throws {
        if let activity {
            let normalized = activity.normalized()
            let issues = normalized.validate()
            if issues.contains(where: { $0.severity == .error }) {
                throw ActivityValidationError(issues: issues)
            }
            desired = .set(normalized)
        } else {
            desired = .clear
        }
        dirty = true
        Task { await self.drain() }
    }

    public func stateUpdates() -> AsyncStream<ClientEvent> {
        let id = UUID()
        let currentState = state
        return AsyncStream { continuation in
            continuation.yield(.stateChanged(currentState))
            subscribers[id] = continuation
            continuation.onTermination = { _ in
                Task { await self.removeSubscriber(id) }
            }
        }
    }

    // MARK: Scanning and handshake

    private func startScan() {
        scanTask?.cancel()
        scanTask = Task { await self.scan() }
    }

    private func scan() async {
        guard let appID = applicationID, !appID.isEmpty else {
            setState(.failed(.invalidApplicationID))
            return
        }
        for path in locator.candidatePaths() {
            if Task.isCancelled { return }
            let outcome = await attempt(path: path, applicationID: appID)
            if Task.isCancelled { return }
            switch outcome {
            case .ready(let user):
                becameReady(user: user)
                return
            case .closedEarly:
                // A live socket that accepts the connection and then drops
                // it during the handshake is rejecting the application ID.
                // Retrying would only earn a timeout from Discord.
                tearDownConnection()
                setState(.failed(.invalidApplicationID))
                return
            case .connectFailed, .timedOut, .sendFailed:
                tearDownConnection()
                continue
            case .cancelled:
                return
            }
        }
        scheduleReconnect(reason: .noSocketFound)
    }

    private func attempt(path: String, applicationID: String) async -> HandshakeOutcome {
        guard let transport = try? await transportFactory.connect(to: path) else {
            return .connectFailed
        }
        generation += 1
        let gen = generation
        connection = transport
        frameDecoder = FrameDecoder()

        eventTask = Task { [weak self] in
            for await event in transport.events {
                await self?.handleTransportEvent(event, generation: gen)
            }
        }

        guard let payload = try? Self.makeEncoder().encode(HandshakePayload(v: 1, clientID: applicationID)) else {
            return .sendFailed
        }

        let timeoutTask = Task {
            try? await self.clock.sleep(for: self.handshakeTimeout)
            guard !Task.isCancelled else { return }
            self.resolveHandshake(.timedOut, generation: gen)
        }

        let outcome = await withCheckedContinuation { (continuation: CheckedContinuation<HandshakeOutcome, Never>) in
            handshakeContinuation = continuation
            Task {
                do {
                    try await transport.send(FrameCodec.encode(Frame(opcode: .handshake, payload: payload)))
                } catch {
                    self.resolveHandshake(.sendFailed, generation: gen)
                }
            }
        }
        timeoutTask.cancel()
        return outcome
    }

    private func resolveHandshake(_ outcome: HandshakeOutcome, generation gen: Int) {
        guard gen == generation, let continuation = handshakeContinuation else { return }
        handshakeContinuation = nil
        continuation.resume(returning: outcome)
    }

    private func becameReady(user: DiscordUser?) {
        backoffAttempt = 0
        setState(.ready(user: user))
        startKeepalive()
        if case .unset = desired {
            return
        }
        dirty = true
        Task { await self.drain() }
    }

    // MARK: Incoming events

    private func handleTransportEvent(_ event: TransportEvent, generation gen: Int) async {
        guard gen == generation else { return }
        switch event {
        case .bytes(let data):
            let frames: [Frame]
            do {
                frames = try frameDecoder.append(data)
            } catch {
                if handshakeContinuation != nil {
                    resolveHandshake(.closedEarly, generation: gen)
                } else {
                    connectionDropped(reason: .protocolError)
                }
                return
            }
            for frame in frames {
                await handleFrame(frame, generation: gen)
            }
        case .closed:
            if handshakeContinuation != nil {
                resolveHandshake(.closedEarly, generation: gen)
            } else {
                connectionDropped(reason: .connectionLost)
            }
        }
    }

    private func handleFrame(_ frame: Frame, generation gen: Int) async {
        switch frame.opcode {
        case .ping:
            await sendFrame(Frame(opcode: .pong, payload: frame.payload))
        case .close:
            if handshakeContinuation != nil {
                resolveHandshake(.closedEarly, generation: gen)
            } else {
                connectionDropped(reason: .connectionLost)
            }
        case .frame:
            handlePayloadFrame(frame.payload, generation: gen)
        case .handshake, .pong:
            break
        }
    }

    private func handlePayloadFrame(_ payload: Data, generation gen: Int) {
        guard let envelope = try? Self.makeDecoder().decode(IncomingEnvelope.self, from: payload) else { return }

        if envelope.evt == "READY" {
            let user = (try? Self.makeDecoder().decode(ReadyEnvelope.self, from: payload))?.data?.user
            resolveHandshake(.ready(user), generation: gen)
            return
        }

        if envelope.evt == "ERROR" {
            let data = (try? Self.makeDecoder().decode(ErrorEnvelope.self, from: payload))?.data
            if envelope.nonce != nil, envelope.nonce == inflightNonce {
                inflightNonce = nil
            }
            broadcast(.rpcError(code: data?.code ?? -1, message: data?.message ?? "Unknown error"))
            return
        }

        if let nonce = envelope.nonce, nonce == inflightNonce {
            inflightNonce = nil
            broadcast(.activityAcknowledged)
        }
    }

    // MARK: Reconnection

    private func connectionDropped(reason: DisconnectReason) {
        tearDownConnection()
        keepaliveTask?.cancel()
        keepaliveTask = nil
        scheduleReconnect(reason: reason)
    }

    private func scheduleReconnect(reason: DisconnectReason) {
        backoffAttempt += 1
        setState(.backoff(attempt: backoffAttempt, reason: reason))
        let delay = backoffPolicy.delay(attempt: backoffAttempt - 1)
        backoffTask?.cancel()
        backoffTask = Task {
            try? await self.clock.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self.retryAfterBackoff()
        }
    }

    private func retryAfterBackoff() {
        guard case .backoff = state else { return }
        setState(.scanning)
        startScan()
    }

    // MARK: Keepalive

    private func startKeepalive() {
        keepaliveTask?.cancel()
        keepaliveTask = Task {
            while !Task.isCancelled {
                try? await self.clock.sleep(for: self.keepaliveInterval)
                guard !Task.isCancelled else { return }
                await self.sendKeepalivePing()
            }
        }
    }

    private func sendKeepalivePing() async {
        guard case .ready = state else { return }
        await sendFrame(Frame(opcode: .ping, payload: Data("{}".utf8)))
    }

    // MARK: Sending

    private func sendFrame(_ frame: Frame) async {
        guard let connection else { return }
        do {
            try await connection.send(FrameCodec.encode(frame))
        } catch {
            if handshakeContinuation == nil {
                connectionDropped(reason: .connectionLost)
            }
        }
    }

    private func drain() async {
        guard case .ready = state, dirty else { return }
        let now = clock.now
        guard bucket.tryConsume(at: now) else {
            scheduleDrainWakeup(at: bucket.nextAvailable(after: now))
            return
        }

        let activity: Activity?
        switch desired {
        case .unset:
            dirty = false
            return
        case .clear:
            activity = nil
        case .set(let value):
            activity = value
        }

        let nonce = UUID().uuidString
        let command = SetActivityCommand(
            nonce: nonce,
            args: SetActivityArgs(pid: Int32(ProcessInfo.processInfo.processIdentifier), activity: activity)
        )
        guard let payload = try? Self.makeEncoder().encode(command) else { return }
        dirty = false
        inflightNonce = nonce
        await sendFrame(Frame(opcode: .frame, payload: payload))
    }

    private func scheduleDrainWakeup(at instant: ContinuousClock.Instant) {
        guard drainWakeupTask == nil else { return }
        drainWakeupTask = Task {
            try? await self.clock.sleep(until: instant, tolerance: nil)
            await self.drainWakeupFired()
        }
    }

    private func drainWakeupFired() async {
        drainWakeupTask = nil
        await drain()
    }

    // MARK: Housekeeping

    private func cancelAllWork() {
        scanTask?.cancel()
        scanTask = nil
        backoffTask?.cancel()
        backoffTask = nil
        keepaliveTask?.cancel()
        keepaliveTask = nil
        drainWakeupTask?.cancel()
        drainWakeupTask = nil
    }

    private func tearDownConnection() {
        generation += 1
        eventTask?.cancel()
        eventTask = nil
        connection?.close()
        connection = nil
        inflightNonce = nil
        if let continuation = handshakeContinuation {
            handshakeContinuation = nil
            continuation.resume(returning: .cancelled)
        }
    }

    private func setState(_ newState: ConnectionState) {
        guard newState != state else { return }
        state = newState
        broadcast(.stateChanged(newState))
    }

    private func broadcast(_ event: ClientEvent) {
        for continuation in subscribers.values {
            continuation.yield(event)
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        JSONDecoder()
    }
}
