import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(PresenceController.self) private var presence
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(presence.statusText)

        Divider()

        Button("Open upto") {
            openWindow(id: "editor")
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        Button("Quit upto") {
            NSApp.terminate(nil)
        }
    }
}
