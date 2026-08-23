import Foundation

// Finds the small files the app leaves behind and removes them, given
// the home directory to search from. The preset folder is not part of
// the removal set on purpose: user data goes to the Trash instead of
// straight deletion, and the Trash step needs AppKit, so it lives with
// the app target. This type only lists that folder.
public struct UninstallSweep: Sendable {
    // Removed outright when present. All of these grow back if the app
    // runs again.
    public let deleteCandidates: [URL]

    // Moved to the Trash by the caller. This is the user's data.
    public let trashCandidates: [URL]

    public init(home: URL, bundleID: String) {
        let library = home.appendingPathComponent("Library", isDirectory: true)
        deleteCandidates = [
            library.appendingPathComponent("Preferences/\(bundleID).plist"),
            library.appendingPathComponent("Caches/\(bundleID)", isDirectory: true),
            library.appendingPathComponent("HTTPStorages/\(bundleID)", isDirectory: true),
            library.appendingPathComponent("Saved Application State/\(bundleID).savedState", isDirectory: true),
        ]
        trashCandidates = [
            library.appendingPathComponent("Application Support/upto", isDirectory: true),
        ]
    }

    // Removes the delete candidates that exist. A missing file is not a
    // failure. Returns the paths that could not be removed.
    @discardableResult
    public func run(using fileManager: FileManager = .default) -> [URL] {
        var failures: [URL] = []
        for url in deleteCandidates {
            guard fileManager.fileExists(atPath: url.path) else { continue }
            do {
                try fileManager.removeItem(at: url)
            } catch {
                failures.append(url)
            }
        }
        return failures
    }
}
