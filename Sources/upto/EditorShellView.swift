import AppKit
import SwiftUI
import UniformTypeIdentifiers
import UptoCore

extension UTType {
    static let uptoPreset = UTType(exportedAs: "io.github.azhang03.upto.preset", conformingTo: .json)
}

struct EditorShellView: View {
    @Environment(PresenceController.self) private var presence
    @Environment(EditorModel.self) private var model
    @Environment(PresetLibrary.self) private var library
    @FocusState private var focus: EditorFocus?
    @AppStorage("applicationID") private var applicationID = ""

    @State private var showingImporter = false
    @State private var showingSavePrompt = false
    @State private var newPresetName = ""

    var body: some View {
        let activity = model.builtActivity
        let focusedTargets = Set(focus?.previewTargets(in: activity) ?? [])

        HSplitView {
            EditorFormView(model: model, focus: $focus)
                .frame(minWidth: 340, idealWidth: 430)
            PreviewPane(
                activity: activity,
                issues: model.issues,
                focusedTargets: focusedTargets,
                displayName: presence.userDisplayName ?? "You",
                appliedAt: model.appliedAt
            )
            .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlayPreferenceValue(ConnectorAnchorsKey.self) { anchors in
            ConnectorOverlay(anchors: anchors, focus: focus, activity: activity)
        }
        .frame(minWidth: 780, minHeight: 520)
        .toolbar {
            ToolbarItem(placement: .status) {
                StatusPill(presence: presence)
            }
            ToolbarItem {
                presetsMenu
            }
            ToolbarItem(placement: .primaryAction) {
                updateButton
            }
            ToolbarItem {
                Button("Clear") {
                    model.markCleared()
                    presence.clearPresence()
                }
                .buttonStyle(PillButtonStyle(variant: .neutral))
                .disabled(!presence.isReady)
            }
        }
        .alert("Save Preset", isPresented: $showingSavePrompt) {
            TextField("Name", text: $newPresetName)
            Button("Save") {
                let trimmed = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
                library.saveAsNew(
                    name: trimmed.isEmpty ? "Untitled" : trimmed,
                    applicationID: applicationID.isEmpty ? nil : applicationID,
                    draft: model.draft
                )
            }
            Button("Cancel", role: .cancel) {}
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.uptoPreset], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                urls.forEach(importPresetFile)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
        .onAppear {
            AppDelegate.openHandler = { urls in
                urls.forEach(importPresetFile)
            }
            let pending = AppDelegate.pendingURLs
            AppDelegate.pendingURLs = []
            pending.forEach(importPresetFile)
            autoConnectIfWanted()
        }
    }

    private var updateButton: some View {
        Button {
            model.markApplied()
            presence.apply(model.draft.buildActivity())
        } label: {
            if model.isDirty {
                Text("Update")
            } else {
                Label("Applied", systemImage: "checkmark")
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
    }

    private func switchTo(_ preset: Preset) {
        library.activate(preset, model: model, presence: presence)
    }

    private func importPresetFile(_ url: URL) {
        guard let preset = library.importFile(url) else { return }
        switchTo(preset)
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

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            accepted = true
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                var url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let direct = item as? URL {
                    url = direct
                }
                guard let url, url.pathExtension.lowercased() == "upto" else { return }
                Task { @MainActor in
                    importPresetFile(url)
                }
            }
        }
        return accepted
    }

    private func autoConnectIfWanted() {
        guard UserDefaults.standard.bool(forKey: "connectOnLaunch"),
              presence.state == .idle,
              !applicationID.trimmingCharacters(in: .whitespaces).isEmpty
        else { return }
        presence.connect(applicationID: applicationID)
        model.markApplied()
        presence.apply(model.draft.buildActivity())
    }
}
