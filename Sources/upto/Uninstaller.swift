import AppKit
import ServiceManagement
import UptoCore

// Removes everything upto ever put on disk, then quits. The app and
// the preset folder move to the Trash so a mistake stays recoverable.
// The small regenerable files are removed outright.
@MainActor
enum Uninstaller {
    static func run(presence: PresenceController, onFailure: @escaping @MainActor (String) -> Void) {
        presence.disconnect()

        // Release the login item while the bundle still exists.
        if SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.unregister()
        }

        let bundleID = Bundle.main.bundleIdentifier ?? "io.github.azhang03.upto"
        UserDefaults.standard.removePersistentDomain(forName: bundleID)

        let fileManager = FileManager.default
        let sweep = UninstallSweep(home: fileManager.homeDirectoryForCurrentUser, bundleID: bundleID)
        sweep.run(using: fileManager)

        var trashTargets = sweep.trashCandidates.filter { fileManager.fileExists(atPath: $0.path) }

        // A copy that runs straight from the mounted DMG sits on a read
        // only volume. Leave that bundle alone; it goes away on eject.
        let bundleURL = Bundle.main.bundleURL
        if bundleURL.pathExtension == "app", !isOnReadOnlyVolume(bundleURL) {
            trashTargets.append(bundleURL)
        }

        guard !trashTargets.isEmpty else {
            finish(bundleID: bundleID)
            return
        }
        NSWorkspace.shared.recycle(trashTargets) { _, error in
            Task { @MainActor in
                if let error {
                    onFailure("Could not move everything to the Trash. \(error.localizedDescription)")
                } else {
                    finish(bundleID: bundleID)
                }
            }
        }
    }

    // AppKit writes window state back to the preferences during app
    // teardown, so the last crumbs can only go after the app exits.
    private static func finish(bundleID: String) {
        let cleaner = Process()
        cleaner.executableURL = URL(fileURLWithPath: "/bin/sh")
        cleaner.arguments = ["-c",
            "sleep 2; /usr/bin/defaults delete \(bundleID) >/dev/null 2>&1; rm -f \"$HOME/Library/Preferences/\(bundleID).plist\""]
        try? cleaner.run()
        NSApp.terminate(nil)
    }

    private static func isOnReadOnlyVolume(_ url: URL) -> Bool {
        let values = try? url.resourceValues(forKeys: [.volumeIsReadOnlyKey])
        return values?.volumeIsReadOnly ?? false
    }
}
