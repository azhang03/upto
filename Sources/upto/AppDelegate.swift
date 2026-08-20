import AppKit

// Receives .upto files opened from Finder or dropped on the Dock icon.
// Files that arrive before the UI is ready wait in the buffer.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var openHandler: (([URL]) -> Void)?
    static var pendingURLs: [URL] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The app ships dark only. The design tokens assume it.
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if let handler = Self.openHandler {
            handler(urls)
        } else {
            Self.pendingURLs.append(contentsOf: urls)
        }
    }
}
