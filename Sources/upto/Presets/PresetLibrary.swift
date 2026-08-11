import Foundation
import Observation
import UptoCore

@MainActor
@Observable
final class PresetLibrary {
    private static let selectedKey = "selectedPresetID"

    private let store: PresetStore?
    private(set) var presets: [StoredPreset] = []
    var lastError: String?

    var selectedID: UUID? {
        didSet {
            UserDefaults.standard.set(selectedID?.uuidString, forKey: Self.selectedKey)
        }
    }

    init() {
        store = try? PresetStore()
        if let raw = UserDefaults.standard.string(forKey: Self.selectedKey) {
            selectedID = UUID(uuidString: raw)
        }
        refresh()
    }

    var selectedPreset: Preset? {
        presets.first { $0.preset.id == selectedID }?.preset
    }

    func refresh() {
        presets = store?.list() ?? []
        if let current = selectedID, !presets.contains(where: { $0.preset.id == current }) {
            selectedID = nil
        }
    }

    func saveAsNew(name: String, applicationID: String?, draft: ActivityDraft) {
        let preset = Preset(name: name, applicationID: applicationID, draft: draft)
        perform {
            try store?.save(preset)
        }
        selectedID = preset.id
    }

    func saveChanges(applicationID: String?, draft: ActivityDraft) {
        guard var preset = selectedPreset else { return }
        preset.applicationID = applicationID
        preset.draft = draft
        perform {
            try store?.save(preset)
        }
    }

    func delete(id: UUID) {
        perform {
            try store?.delete(id: id)
        }
    }

    func importFile(_ url: URL) -> Preset? {
        var imported: Preset?
        perform {
            imported = try store?.importPreset(from: url)
        }
        return imported
    }

    func export(_ preset: Preset, to url: URL) {
        do {
            try store?.export(preset, to: url)
        } catch {
            lastError = "Could not export the preset."
        }
    }

    // The one shared path for switching presets, used by the editor
    // toolbar and the menu bar. Loads the draft, reconnects when the
    // preset carries a different application, and applies right away
    // when a connection is up.
    func activate(_ preset: Preset, model: EditorModel, presence: PresenceController) {
        selectedID = preset.id
        model.draft = preset.draft
        let defaults = UserDefaults.standard
        let currentAppID = defaults.string(forKey: "applicationID") ?? ""
        if let presetAppID = preset.applicationID, !presetAppID.isEmpty, presetAppID != currentAppID {
            defaults.set(presetAppID, forKey: "applicationID")
            presence.connect(applicationID: presetAppID)
        }
        if presence.isBusy {
            model.markApplied()
            presence.apply(model.draft.buildActivity())
        }
    }

    private func perform(_ work: () throws -> Void) {
        do {
            try work()
            lastError = nil
        } catch {
            lastError = "Could not update the preset library."
        }
        refresh()
    }
}
