import Foundation
import Testing
@testable import UptoCore

@Suite struct SocketLocatorTests {
    @Test func resolutionOrderPrefersXDGThenTMPDIR() {
        let locator = DiscordSocketLocator(environment: [
            "XDG_RUNTIME_DIR": "/run/user/501",
            "TMPDIR": "/var/tmp-a/",
        ])
        let paths = locator.candidatePaths()
        #expect(paths.first == "/run/user/501/discord-ipc-0")
        #expect(!paths.contains("/var/tmp-a//discord-ipc-0"))
        #expect(paths.contains("/var/tmp-a/discord-ipc-0"))
        #expect(paths.last == "/tmp/discord-ipc-9")
    }

    @Test func fallsBackToSlashTmp() {
        let locator = DiscordSocketLocator(environment: [:])
        let paths = locator.candidatePaths()
        #expect(paths == (0...9).map { "/tmp/discord-ipc-\($0)" })
    }

    @Test func enumeratesIndicesZeroThroughNine() {
        let locator = DiscordSocketLocator(environment: ["TMPDIR": "/x"])
        let paths = locator.candidatePaths()
        let indices = paths.filter { $0.hasPrefix("/x/") }
        #expect(indices == (0...9).map { "/x/discord-ipc-\($0)" })
    }

    @Test func skipsOverlongPaths() {
        let long = "/" + String(repeating: "d", count: 120)
        let locator = DiscordSocketLocator(environment: ["TMPDIR": long])
        let paths = locator.candidatePaths()
        #expect(paths.allSatisfy { $0.hasPrefix("/tmp/") })
    }

    @Test func duplicateDirectoriesAreListedOnce() {
        let locator = DiscordSocketLocator(environment: ["TMPDIR": "/tmp", "TMP": "/tmp"])
        let paths = locator.candidatePaths()
        #expect(paths.count == 10)
    }
}
