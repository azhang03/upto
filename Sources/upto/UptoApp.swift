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
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 980, height: 640)

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
// The center of the cross is an open ring only while the presence is
// actually live. The images load as NSImage with an explicit template
// flag and point size, so the menu bar tints and scales them correctly.
private struct MenuBarLabel: View {
    let presence: PresenceController

    private static let connected = template("uptoTemplate")
    private static let offline = template("uptoOfflineTemplate")

    private static func template(_ name: String) -> NSImage {
        let image = Bundle.module.image(forResource: name) ?? NSImage()
        image.isTemplate = true
        image.size = NSSize(width: 16, height: 16)
        return image
    }

    var body: some View {
        Image(nsImage: presence.isReady ? Self.connected : Self.offline)
    }
}
