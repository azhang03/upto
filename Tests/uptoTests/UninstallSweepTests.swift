import Foundation
import Testing
@testable import UptoCore

@Suite struct UninstallSweepTests {
    private let bundleID = "io.github.azhang03.upto"

    private func makeHome() throws -> URL {
        let home = FileManager.default.temporaryDirectory
            .appendingPathComponent("sweep-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        return home
    }

    @Test func candidatesStayInsideTheGivenHome() throws {
        let home = try makeHome()
        defer { try? FileManager.default.removeItem(at: home) }
        let sweep = UninstallSweep(home: home, bundleID: bundleID)
        let all = sweep.deleteCandidates + sweep.trashCandidates
        let homePath = home.resolvingSymlinksInPath().path
        for url in all {
            let resolved = url.resolvingSymlinksInPath().path
            #expect(resolved.hasPrefix(homePath))
        }
    }

    @Test func candidatesCoverTheKnownFootprint() throws {
        let home = try makeHome()
        defer { try? FileManager.default.removeItem(at: home) }
        let sweep = UninstallSweep(home: home, bundleID: bundleID)
        let paths = sweep.deleteCandidates.map { $0.path }
        #expect(paths.contains { $0.hasSuffix("Preferences/\(bundleID).plist") })
        #expect(paths.contains { $0.hasSuffix("Caches/\(bundleID)") })
        #expect(paths.contains { $0.hasSuffix("Saved Application State/\(bundleID).savedState") })
        let trashPaths = sweep.trashCandidates.map { $0.path }
        #expect(trashPaths.contains { $0.hasSuffix("Application Support/upto") })
    }

    @Test func runRemovesExistingCrumbs() throws {
        let home = try makeHome()
        defer { try? FileManager.default.removeItem(at: home) }
        let sweep = UninstallSweep(home: home, bundleID: bundleID)
        let plist = sweep.deleteCandidates[0]
        let caches = sweep.deleteCandidates[1]
        try FileManager.default.createDirectory(
            at: plist.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("test".utf8).write(to: plist)
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
        try Data().write(to: caches.appendingPathComponent("cache.dat"))

        let failures = sweep.run()

        #expect(failures.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: plist.path))
        #expect(!FileManager.default.fileExists(atPath: caches.path))
    }

    @Test func runSkipsMissingFilesWithoutFailing() throws {
        let home = try makeHome()
        defer { try? FileManager.default.removeItem(at: home) }
        let sweep = UninstallSweep(home: home, bundleID: bundleID)
        let failures = sweep.run()
        #expect(failures.isEmpty)
    }

    @Test func runLeavesTheTrashCandidatesAlone() throws {
        let home = try makeHome()
        defer { try? FileManager.default.removeItem(at: home) }
        let sweep = UninstallSweep(home: home, bundleID: bundleID)
        let presets = sweep.trashCandidates[0].appendingPathComponent("Presets", isDirectory: true)
        try FileManager.default.createDirectory(at: presets, withIntermediateDirectories: true)
        try Data("preset".utf8).write(to: presets.appendingPathComponent("Sample.upto"))

        sweep.run()

        #expect(FileManager.default.fileExists(atPath: presets.appendingPathComponent("Sample.upto").path))
    }
}
