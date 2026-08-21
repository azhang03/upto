import AppKit
import SwiftUI
import UptoCore

// The strip below the header: every preset as a chip, plus chips to
// save and import. Right click a chip for save changes, export, and
// delete.
struct PresetsBar: View {
    @Environment(PresenceController.self) private var presence
    @Environment(EditorModel.self) private var model
    @Environment(PresetLibrary.self) private var library
    @AppStorage("applicationID") private var applicationID = ""

    @Binding var showingSavePrompt: Bool
    @Binding var showingImporter: Bool
    @Binding var newPresetName: String

    @State private var pendingDelete: StoredPreset?

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            SectionHeader("Presets")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(library.presets, id: \.preset.id) { stored in
                        presetChip(stored)
                    }

                    Button {
                        newPresetName = library.selectedPreset?.name ?? ""
                        showingSavePrompt = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(ChipButtonStyle(isDashed: true))
                    .accessibilityLabel("Save as new preset")
                    .help("Save the current setup as a new preset.")

                    Button {
                        showingImporter = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .buttonStyle(ChipButtonStyle(isDashed: true))
                    .accessibilityLabel("Import presets")
                    .help("Import preset files.")

                    if library.presets.isEmpty {
                        Text("Save the current setup as a preset.")
                            .font(.footnote)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.s)
        .background(Theme.Colors.bgWindow)
        .confirmationDialog(
            "Delete the preset \"\(pendingDelete?.preset.name ?? "")\"?",
            isPresented: deletePrompt,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let stored = pendingDelete {
                    library.delete(id: stored.preset.id)
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
            }
        }
    }

    private var deletePrompt: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }

    private func presetChip(_ stored: StoredPreset) -> some View {
        let isSelected = library.selectedID == stored.preset.id
        return Button(stored.preset.name) {
            library.activate(stored.preset, model: model, presence: presence)
        }
        .buttonStyle(ChipButtonStyle(isSelected: isSelected))
        .contextMenu {
            if isSelected {
                Button("Save Changes to \"\(stored.preset.name)\"") {
                    library.saveChanges(
                        applicationID: applicationID.isEmpty ? nil : applicationID,
                        draft: model.draft
                    )
                }
            }
            Button("Export \"\(stored.preset.name)\"...") {
                exportPreset(stored.preset)
            }
            Button("Delete \"\(stored.preset.name)\"...", role: .destructive) {
                pendingDelete = stored
            }
        }
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
