import SwiftUI

@main
struct UptoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var presence = PresenceController()
    @State private var model = EditorModel()
    @State private var library = PresetLibrary()

    var body: some Scene {
        WindowGroup("upto", id: "editor") {
            EditorShellView()
                .environment(presence)
                .environment(model)
                .environment(library)
        }

        MenuBarExtra {
            MenuBarView()
                .environment(presence)
                .environment(model)
                .environment(library)
        } label: {
            MenuBarLabel(presence: presence)
        }

        Settings {
            SettingsView()
        }
    }
}

// A separate view so the icon reliably re-renders on state changes.
// The antenna only shows unslashed while the presence is actually live.
private struct MenuBarLabel: View {
    let presence: PresenceController

    var body: some View {
        Image(systemName: presence.isReady
            ? "antenna.radiowaves.left.and.right"
            : "antenna.radiowaves.left.and.right.slash")
    }
}
