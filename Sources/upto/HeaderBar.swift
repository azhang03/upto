import AppKit
import SwiftUI
import UptoCore

// The strip across the top of the window: the brand block on the left
// and the main actions on the right. It replaces the system toolbar.
struct HeaderBar: View {
    @Environment(PresenceController.self) private var presence
    @Environment(EditorModel.self) private var model
    @Environment(PresetLibrary.self) private var library
    @AppStorage("applicationID") private var applicationID = ""

    @Binding var showingSavePrompt: Bool
    @Binding var showingImporter: Bool
    @Binding var newPresetName: String

    private static let mark: NSImage = {
        let image = Bundle.module.image(forResource: "uptoTemplate") ?? NSImage()
        image.isTemplate = true
        return image
    }()

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                Image(nsImage: Self.mark)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Theme.Colors.accent)
                Text("upto")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            Spacer(minLength: Theme.Spacing.l)

            StatusPill(presence: presence)
            presetsMenu
            pushButton
            Button("Clear") {
                model.markCleared()
                presence.clearPresence()
            }
            .buttonStyle(PillButtonStyle(variant: .neutral))
            .disabled(!presence.isReady)
        }
        .padding(.leading, Theme.Metrics.trafficLightInset)
        .padding(.trailing, Theme.Spacing.l)
        .frame(maxWidth: .infinity)
        .frame(height: Theme.Metrics.headerHeight)
        .background(Theme.Colors.bgHeader)
    }

    private var pushButton: some View {
        Button {
            model.markApplied()
            presence.apply(model.draft.buildActivity())
        } label: {
            if model.isDirty {
                Text("Push")
            } else {
                Label("Pushed", systemImage: "checkmark")
            }
        }
        .buttonStyle(PillButtonStyle(variant: .accent))
        .disabled(!presence.isReady || model.hasErrors)
    }

    private var presetsMenu: some View {
        Menu {
            ForEach(library.presets, id: \.preset.id) { stored in
                Button {
                    switchTo(stored.preset)
                } label: {
                    if library.selectedID == stored.preset.id {
                        Label(stored.preset.name, systemImage: "checkmark")
                    } else {
                        Text(stored.preset.name)
                    }
                }
            }

            if !library.presets.isEmpty {
                Divider()
            }

            if let selected = library.selectedPreset {
                Button("Save Changes to \"\(selected.name)\"") {
                    library.saveChanges(
                        applicationID: applicationID.isEmpty ? nil : applicationID,
                        draft: model.draft
                    )
                }
            }
            Button("Save as New Preset...") {
                newPresetName = library.selectedPreset?.name ?? ""
                showingSavePrompt = true
            }

            Divider()

            Button("Import...") {
                showingImporter = true
            }
            if let selected = library.selectedPreset {
                Button("Export \"\(selected.name)\"...") {
                    exportPreset(selected)
                }
            }

            if !library.presets.isEmpty {
                Menu("Delete") {
                    ForEach(library.presets, id: \.preset.id) { stored in
                        Button(stored.preset.name, role: .destructive) {
                            library.delete(id: stored.preset.id)
                        }
                    }
                }
            }
        } label: {
            Label("Presets", systemImage: "square.stack.3d.up")
        }
        .menuStyle(.button)
        .buttonStyle(PillButtonStyle(variant: .neutral))
    }

    private func switchTo(_ preset: Preset) {
        library.activate(preset, model: model, presence: presence)
    }

    private func exportPreset(_ preset: Preset) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.uptoPreset]
        panel.nameFieldStringValue = "\(preset.name).upto"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                library.export(preset, to: url)
            }
        }
    }
}
