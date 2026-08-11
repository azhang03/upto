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
            Image(systemName: presence.isBusy ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
        }

        Settings {
            SettingsView()
        }
    }
}
