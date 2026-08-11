import Foundation
@testable import UptoCore

// A transport connection driven by the test. It records what the client
// sends and lets the test feed bytes and lifecycle events back.
final class FakeConnection: IPCTransportConnection, @unchecked Sendable {
    let events: AsyncStream<TransportEvent>
    private let eventContinuation: AsyncStream<TransportEvent>.Continuation

    private let sentStream: AsyncStream<Data>
    private let sentContinuation: AsyncStream<Data>.Continuation
    private var sentIterator: AsyncStream<Data>.AsyncIterator

    private let lock = NSLock()
    private var _closed = false
    private var _failSends = false

    init() {
        var eventCont: AsyncStream<TransportEvent>.Continuation!
        events = AsyncStream { eventCont = $0 }
        eventContinuation = eventCont

        var sentCont: AsyncStream<Data>.Continuation!
        sentStream = AsyncStream { sentCont = $0 }
        sentContinuation = sentCont
        sentIterator = sentStream.makeAsyncIterator()
    }

    var closed: Bool {
        lock.withLock { _closed }
    }

    func setFailSends(_ value: Bool) {
        lock.withLock { _failSends = value }
    }

    func send(_ data: Data) async throws {
        let shouldFail = lock.withLock { _failSends }
        if shouldFail {
            throw SocketError.writeFailed(errno: EPIPE)
        }
        sentContinuation.yield(data)
    }

    func close() {
        let alreadyClosed = lock.withLock {
            let was = _closed
            _closed = true
            return was
        }
        guard !alreadyClosed else { return }
        eventContinuation.finish()
    }

    func emit(_ bytes: Data) {
        eventContinuation.yield(.bytes(bytes))
    }

    func emitFrame(_ frame: Frame, chunkSize: Int = .max) {
        let data = FrameCodec.encode(frame)
        if chunkSize >= data.count {
            emit(data)
            return
        }
        var index = data.startIndex
        while index < data.endIndex {
            let end = data.index(index, offsetBy: chunkSize, limitedBy: data.endIndex) ?? data.endIndex
            emit(Data(data[index..<end]))
            index = end
        }
    }

    func emitClosed() {
        eventContinuation.yield(.closed(nil))
        eventContinuation.finish()
    }

    func nextSentFrame() async -> Frame? {
        guard let data = await sentIterator.next() else { return nil }
        var decoder = FrameDecoder()
        return (try? decoder.append(data))?.first
    }

    // Returns nil when nothing is sent within the window. Used to prove
    // that the rate limiter is holding an update back.
    func nextSentFrame(within window: Duration) async -> Frame? {
        await withTaskGroup(of: Frame?.self) { group in
            group.addTask { await self.nextSentFrame() }
            group.addTask {
                try? await ContinuousClock().sleep(for: window)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}

// Hands out planned connections per path. A path with an exhausted or
// missing plan behaves like a dead socket file.
final class FakeFactory: IPCTransportFactory, @unchecked Sendable {
    private let lock = NSLock()
    private var plans: [String: [FakeConnection]]
    private var _attempts: [String] = []

    init(_ plans: [String: [FakeConnection]]) {
        self.plans = plans
    }

    var attempts: [String] {
        lock.withLock { _attempts }
    }

    func connect(to path: String) async throws -> any IPCTransportConnection {
        try lock.withLock {
            _attempts.append(path)
            guard var queue = plans[path], !queue.isEmpty else {
                throw SocketError.connectFailed(errno: ENOENT)
            }
            let connection = queue.removeFirst()
            plans[path] = queue
            return connection
        }
    }
}

struct FixedLocator: SocketLocator {
    let paths: [String]

    func candidatePaths() -> [String] {
        paths
    }
}

extension BackoffPolicy {
    static let fast = BackoffPolicy(base: .milliseconds(5), cap: .milliseconds(20), jitter: 0)
}

enum Fixtures {
    static func readyFrame(username: String? = "tester") -> Frame {
        let userPart = username.map { "\"user\":{\"id\":\"1\",\"username\":\"\($0)\"}," } ?? ""
        let json = "{\"cmd\":\"DISPATCH\",\"evt\":\"READY\",\"data\":{\(userPart)\"v\":1}}"
        return Frame(opcode: .frame, payload: Data(json.utf8))
    }

    static func ackFrame(nonce: String) -> Frame {
        let json = "{\"cmd\":\"SET_ACTIVITY\",\"nonce\":\"\(nonce)\",\"data\":{}}"
        return Frame(opcode: .frame, payload: Data(json.utf8))
    }

    static func errorFrame(code: Int, message: String, nonce: String? = nil) -> Frame {
        let noncePart = nonce.map { "\"nonce\":\"\($0)\"," } ?? ""
        let json = "{\"cmd\":\"SET_ACTIVITY\",\(noncePart)\"evt\":\"ERROR\",\"data\":{\"code\":\(code),\"message\":\"\(message)\"}}"
        return Frame(opcode: .frame, payload: Data(json.utf8))
    }

    static func pingFrame(payload: String = "{\"marker\":42}") -> Frame {
        Frame(opcode: .ping, payload: Data(payload.utf8))
    }
}

// Walks the event stream until a state matching the predicate arrives.
func awaitState(
    _ iterator: inout AsyncStream<ClientEvent>.AsyncIterator,
    where predicate: (ConnectionState) -> Bool
) async -> ConnectionState? {
    while let event = await iterator.next() {
        if case .stateChanged(let state) = event, predicate(state) {
            return state
        }
    }
    return nil
}

func awaitEvent(
    _ iterator: inout AsyncStream<ClientEvent>.AsyncIterator,
    where predicate: (ClientEvent) -> Bool
) async -> ClientEvent? {
    while let event = await iterator.next() {
        if predicate(event) {
            return event
        }
    }
    return nil
}
