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
