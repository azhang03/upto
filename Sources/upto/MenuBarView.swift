import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text("Not connected")

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
