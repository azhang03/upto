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

        VStack(spacing: 0) {
            HeaderBar(
                showingSavePrompt: $showingSavePrompt,
                showingImporter: $showingImporter,
                newPresetName: $newPresetName
            )
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
        }
        .ignoresSafeArea(.container, edges: .top)
        .background(Theme.Colors.bgWindow.ignoresSafeArea())
        .background(WindowConfigurator())
        .frame(minWidth: 780, minHeight: 520)
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

    private func importPresetFile(_ url: URL) {
        guard let preset = library.importFile(url) else { return }
        library.activate(preset, model: model, presence: presence)
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
