import AppKit
import SwiftUI
import UptoCore

struct MenuBarView: View {
    @Environment(PresenceController.self) private var presence
    @Environment(EditorModel.self) private var model
    @Environment(PresetLibrary.self) private var library
    @Environment(\.openWindow) private var openWindow
    @AppStorage("applicationID") private var applicationID = ""

    var body: some View {
        Text(presence.statusText)
        if let guidance = presence.state.userGuidance {
            Text(guidance)
        }

        Divider()

        connectionActions

        if !library.presets.isEmpty {
            Menu("Presets") {
                ForEach(library.presets, id: \.preset.id) { stored in
                    Button {
                        library.activate(stored.preset, model: model, presence: presence)
                    } label: {
                        if library.selectedID == stored.preset.id {
                            Label(stored.preset.name, systemImage: "checkmark")
                        } else {
                            Text(stored.preset.name)
                        }
                    }
                }
            }
        }

        Divider()

        Button("Open upto") {
            openWindow(id: "editor")
            NSApp.activate(ignoringOtherApps: true)
        }

        SettingsLink {
            Text("Settings...")
        }

        Divider()

        Button("Quit upto") {
            NSApp.terminate(nil)
        }
    }

    @ViewBuilder
    private var connectionActions: some View {
        if presence.isBusy {
            Button("Disconnect") {
                presence.disconnect()
            }
            Button("Reconnect now") {
                presence.disconnect()
                presence.connect(applicationID: applicationID)
                model.markApplied()
                presence.apply(model.draft.buildActivity())
            }
        } else {
            Button("Connect") {
                presence.connect(applicationID: applicationID)
                model.markApplied()
                presence.apply(model.draft.buildActivity())
            }
            .disabled(applicationID.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
