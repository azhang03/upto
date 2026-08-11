import SwiftUI

@main
struct UptoApp: App {
    @State private var presence = PresenceController()

    var body: some Scene {
        WindowGroup("upto", id: "editor") {
            EditorShellView()
                .environment(presence)
        }

        MenuBarExtra("upto", systemImage: "dot.radiowaves.left.and.right") {
            MenuBarView()
                .environment(presence)
        }
    }
}
