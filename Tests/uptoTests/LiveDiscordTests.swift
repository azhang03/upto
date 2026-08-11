import Foundation
import Testing
@testable import UptoCore

// Talks to the real Discord desktop app. Off by default so normal test
// runs never depend on the local environment. Run it with:
//   UPTO_LIVE_TEST=1 UPTO_LIVE_APP_ID=<application id> swift test --filter LiveDiscord
@Suite struct LiveDiscordTests {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["UPTO_LIVE_TEST"] == "1"
    }

    @Test(.enabled(if: isEnabled))
    func connectSetAndClearPresence() async throws {
        let appID = try #require(ProcessInfo.processInfo.environment["UPTO_LIVE_APP_ID"])

        let client = DiscordIPCClient()
        var iterator = await client.stateUpdates().makeAsyncIterator()
        await client.connect(applicationID: appID)

        let ready = await awaitState(&iterator) { if case .ready = $0 { return true }; return false }
        guard case .ready(let user) = ready else {
            Issue.record("Never reached ready state")
            return
        }
        #expect(user != nil)

        var activity = Activity(type: .playing, details: "Live test", state: "From the test suite")
        activity.timestamps = Timestamps(start: Int64(Date().timeIntervalSince1970 * 1000))
        try await client.setActivity(activity)

        let ack = await awaitEvent(&iterator) {
            if case .activityAcknowledged = $0 { return true }
            if case .rpcError = $0 { return true }
            return false
        }
        #expect(ack == .activityAcknowledged)

        try await client.setActivity(nil)
        try await Task.sleep(for: .seconds(1))
        await client.disconnect()
    }
}
