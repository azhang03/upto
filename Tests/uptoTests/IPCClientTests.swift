import Foundation
import Testing
@testable import UptoCore

@Suite struct IPCClientTests {
    private func decodePayload(_ frame: Frame?) -> [String: Any] {
        guard let payload = frame?.payload,
              let object = try? JSONSerialization.jsonObject(with: payload) as? [String: Any]
        else { return [:] }
        return object
    }

    @Test func happyHandshakeCapturesUser() async throws {
        let connection = FakeConnection()
        let factory = FakeFactory(["/fake/discord-ipc-0": [connection]])
        let client = DiscordIPCClient(transport: factory, locator: FixedLocator(paths: ["/fake/discord-ipc-0"]), backoff: .fast)
        var iterator = await client.stateUpdates().makeAsyncIterator()

        await client.connect(applicationID: "  12345  ")

        let handshake = await connection.nextSentFrame()
        #expect(handshake?.opcode == .handshake)
        let payload = decodePayload(handshake)
        #expect(payload["v"] as? Int == 1)
        #expect(payload["client_id"] as? String == "12345")

        connection.emitFrame(Fixtures.readyFrame(username: "andrew"), chunkSize: 1)

        let ready = await awaitState(&iterator) { if case .ready = $0 { return true }; return false }
        #expect(ready == .ready(user: DiscordUser(id: "1", username: "andrew")))
    }

    @Test func scanSkipsDeadCandidates() async throws {
        let connection = FakeConnection()
        let paths = (0...3).map { "/fake/discord-ipc-\($0)" }
        let factory = FakeFactory(["/fake/discord-ipc-3": [connection]])
        let client = DiscordIPCClient(transport: factory, locator: FixedLocator(paths: paths), backoff: .fast)
        var iterator = await client.stateUpdates().makeAsyncIterator()

        await client.connect(applicationID: "12345")
        _ = await connection.nextSentFrame()
        connection.emitFrame(Fixtures.readyFrame())

        _ = await awaitState(&iterator) { if case .ready = $0 { return true }; return false }
        #expect(factory.attempts == paths)
    }

    @Test func immediateCloseDuringHandshakeIsInvalidAppID() async throws {
        let connection = FakeConnection()
        let factory = FakeFactory(["/fake/discord-ipc-0": [connection]])
        let client = DiscordIPCClient(transport: factory, locator: FixedLocator(paths: ["/fake/discord-ipc-0"]), backoff: .fast)
        var iterator = await client.stateUpdates().makeAsyncIterator()

        await client.connect(applicationID: "badid")
        _ = await connection.nextSentFrame()
        connection.emitClosed()

        let failed = await awaitState(&iterator) { if case .failed = $0 { return true }; return false }
        #expect(failed == .failed(.invalidApplicationID))

        // No reconnect attempts follow a rejected application ID.
        try await Task.sleep(for: .milliseconds(100))
        #expect(factory.attempts.count == 1)
    }

    @Test func setActivitySendsPidNonceAndActivity() async throws {
        let connection = FakeConnection()
        let factory = FakeFactory(["/fake/discord-ipc-0": [connection]])
        let client = DiscordIPCClient(transport: factory, locator: FixedLocator(paths: ["/fake/discord-ipc-0"]), backoff: .fast)
        var iterator = await client.stateUpdates().makeAsyncIterator()

        await client.connect(applicationID: "12345")
        _ = await connection.nextSentFrame()
        connection.emitFrame(Fixtures.readyFrame())
        _ = await awaitState(&iterator) { if case .ready = $0 { return true }; return false }

        try await client.setActivity(Activity(type: .watching, details: "A test"))

        let sent = await connection.nextSentFrame()
        #expect(sent?.opcode == .frame)
        let payload = decodePayload(sent)
        #expect(payload["cmd"] as? String == "SET_ACTIVITY")
        #expect((payload["nonce"] as? String)?.isEmpty == false)
        let args = payload["args"] as? [String: Any]
        #expect(args?["pid"] as? Int == Int(ProcessInfo.processInfo.processIdentifier))
        let activity = args?["activity"] as? [String: Any]
        #expect(activity?["details"] as? String == "A test")
        #expect(activity?["type"] as? Int == 3)
    }

    @Test func clearOmitsActivityKey() async throws {
        let connection = FakeConnection()
        let factory = FakeFactory(["/fake/discord-ipc-0": [connection]])
        let client = DiscordIPCClient(transport: factory, locator: FixedLocator(paths: ["/fake/discord-ipc-0"]), backoff: .fast)
        var iterator = await client.stateUpdates().makeAsyncIterator()

        await client.connect(applicationID: "12345")
        _ = await connection.nextSentFrame()
        connection.emitFrame(Fixtures.readyFrame())
        _ = await awaitState(&iterator) { if case .ready = $0 { return true }; return false }

        try await client.setActivity(nil)

        let sent = await connection.nextSentFrame()
        let args = decodePayload(sent)["args"] as? [String: Any]
        #expect(args?["pid"] != nil)
        #expect(args?["activity"] == nil)
    }

    @Test func invalidActivityThrowsBeforeSending() async throws {
        let client = DiscordIPCClient(transport: FakeFactory([:]), locator: FixedLocator(paths: []), backoff: .fast)
        var activity = Activity(details: "x")
        activity.buttons = [
            ActivityButton(label: "1", url: "https://a.example"),
            ActivityButton(label: "2", url: "https://b.example"),
            ActivityButton(label: "3", url: "https://c.example"),
        ]
        await #expect(throws: ActivityValidationError.self) {
            try await client.setActivity(activity)
        }
    }

    @Test func rapidUpdatesAreRateLimitedAndCoalesced() async throws {
        let connection = FakeConnection()
        let factory = FakeFactory(["/fake/discord-ipc-0": [connection]])
        let client = DiscordIPCClient(
            transport: factory,
            locator: FixedLocator(paths: ["/fake/discord-ipc-0"]),
            backoff: .fast,
            bucket: TokenBucket(capacity: 5, refillInterval: .milliseconds(60))
        )
        var iterator = await client.stateUpdates().makeAsyncIterator()

        await client.connect(applicationID: "12345")
        _ = await connection.nextSentFrame()
        connection.emitFrame(Fixtures.readyFrame())
        _ = await awaitState(&iterator) { if case .ready = $0 { return true }; return false }

        for round in 1...7 {
            try await client.setActivity(Activity(details: "Update number \(round)"))
        }

        var details: [String] = []
        for _ in 0..<5 {
            let frame = await connection.nextSentFrame(within: .milliseconds(500))
            let activity = (decodePayload(frame)["args"] as? [String: Any])?["activity"] as? [String: Any]
            if let text = activity?["details"] as? String {
                details.append(text)
            }
        }
        #expect(details.count == 5)

        // The held back update arrives once the bucket refills, and it
        // carries the newest content only.
        let coalesced = await connection.nextSentFrame(within: .milliseconds(500))
        let activity = (decodePayload(coalesced)["args"] as? [String: Any])?["activity"] as? [String: Any]
        #expect(activity?["details"] as? String == "Update number 7")

        let extra = await connection.nextSentFrame(within: .milliseconds(200))
        #expect(extra == nil)
    }

    @Test func reconnectRescansAndReplaysActivity() async throws {
        let first = FakeConnection()
        let second = FakeConnection()
        let factory = FakeFactory([
            "/fake/discord-ipc-0": [first],
            "/fake/discord-ipc-1": [second],
        ])
        let client = DiscordIPCClient(
            transport: factory,
            locator: FixedLocator(paths: ["/fake/discord-ipc-0", "/fake/discord-ipc-1"]),
            backoff: .fast
        )
        var iterator = await client.stateUpdates().makeAsyncIterator()

        await client.connect(applicationID: "12345")
        _ = await first.nextSentFrame()
        first.emitFrame(Fixtures.readyFrame())
        _ = await awaitState(&iterator) { if case .ready = $0 { return true }; return false }

        try await client.setActivity(Activity(details: "Persistent presence"))
        _ = await first.nextSentFrame()

        first.emitClosed()

        _ = await awaitState(&iterator) { if case .backoff(_, .connectionLost) = $0 { return true }; return false }

        // Discord came back on a different socket index.
        let handshake = await second.nextSentFrame()
        #expect(handshake?.opcode == .handshake)
        second.emitFrame(Fixtures.readyFrame())
        _ = await awaitState(&iterator) { if case .ready = $0 { return true }; return false }

        // The last activity replays without a new setActivity call.
        let replay = await second.nextSentFrame(within: .seconds(2))
        let activity = (decodePayload(replay)["args"] as? [String: Any])?["activity"] as? [String: Any]
        #expect(activity?["details"] as? String == "Persistent presence")
    }

    @Test func pingIsEchoedAsPong() async throws {
        let connection = FakeConnection()
        let factory = FakeFactory(["/fake/discord-ipc-0": [connection]])
        let client = DiscordIPCClient(transport: factory, locator: FixedLocator(paths: ["/fake/discord-ipc-0"]), backoff: .fast)
        var iterator = await client.stateUpdates().makeAsyncIterator()

        await client.connect(applicationID: "12345")
        _ = await connection.nextSentFrame()
        connection.emitFrame(Fixtures.readyFrame())
        _ = await awaitState(&iterator) { if case .ready = $0 { return true }; return false }

        let ping = Fixtures.pingFrame()
        connection.emitFrame(ping)

        let pong = await connection.nextSentFrame()
        #expect(pong?.opcode == .pong)
        #expect(pong?.payload == ping.payload)
    }

    @Test func rpcErrorIsSurfacedWithoutDisconnecting() async throws {
        let connection = FakeConnection()
        let factory = FakeFactory(["/fake/discord-ipc-0": [connection]])
        let client = DiscordIPCClient(transport: factory, locator: FixedLocator(paths: ["/fake/discord-ipc-0"]), backoff: .fast)
        var iterator = await client.stateUpdates().makeAsyncIterator()

        await client.connect(applicationID: "12345")
        _ = await connection.nextSentFrame()
        connection.emitFrame(Fixtures.readyFrame())
        _ = await awaitState(&iterator) { if case .ready = $0 { return true }; return false }

        connection.emitFrame(Fixtures.errorFrame(code: 4000, message: "Invalid payload"))

        let event = await awaitEvent(&iterator) {
            if case .rpcError = $0 { return true }
            return false
        }
        #expect(event == .rpcError(code: 4000, message: "Invalid payload"))
        let state = await client.state
        #expect(state == .ready(user: DiscordUser(id: "1", username: "tester")))
    }

    @Test func disconnectClosesTransportAndKeepsSlotForReplay() async throws {
        let first = FakeConnection()
        let second = FakeConnection()
        let factory = FakeFactory(["/fake/discord-ipc-0": [first, second]])
        let client = DiscordIPCClient(transport: factory, locator: FixedLocator(paths: ["/fake/discord-ipc-0"]), backoff: .fast)
        var iterator = await client.stateUpdates().makeAsyncIterator()

        await client.connect(applicationID: "12345")
        _ = await first.nextSentFrame()
        first.emitFrame(Fixtures.readyFrame())
        _ = await awaitState(&iterator) { if case .ready = $0 { return true }; return false }
        try await client.setActivity(Activity(details: "Sticky presence"))
        _ = await first.nextSentFrame()

        await client.disconnect()
        let idle = await awaitState(&iterator) { $0 == .idle }
        #expect(idle == .idle)
        #expect(first.closed)

        // A later connect replays the retained activity.
        await client.connect(applicationID: "12345")
        _ = await second.nextSentFrame()
        second.emitFrame(Fixtures.readyFrame())
        let replay = await second.nextSentFrame(within: .seconds(2))
        let activity = (decodePayload(replay)["args"] as? [String: Any])?["activity"] as? [String: Any]
        #expect(activity?["details"] as? String == "Sticky presence")
    }

    @Test func handshakeTimeoutMovesOn() async throws {
        let silent = FakeConnection()
        let factory = FakeFactory(["/fake/discord-ipc-0": [silent]])
        let client = DiscordIPCClient(
            transport: factory,
            locator: FixedLocator(paths: ["/fake/discord-ipc-0"]),
            backoff: .fast,
            handshakeTimeout: .milliseconds(50)
        )
        var iterator = await client.stateUpdates().makeAsyncIterator()

        await client.connect(applicationID: "12345")
        _ = await silent.nextSentFrame()

        let backoff = await awaitState(&iterator) { if case .backoff(_, .noSocketFound) = $0 { return true }; return false }
        #expect(backoff != nil)
    }
}
