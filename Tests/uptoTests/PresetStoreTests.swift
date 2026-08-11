import Foundation
import Testing
@testable import UptoCore

@Suite struct PresetStoreTests {
    private func makeStore() throws -> PresetStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("upto-tests-\(UUID().uuidString)", isDirectory: true)
        return try PresetStore(directory: directory)
    }

    private func makePreset(name: String, details: String = "Some details") -> Preset {
        var draft = ActivityDraft()
        draft.details = details
        return Preset(name: name, applicationID: "12345", draft: draft)
    }

    @Test func saveAndListRoundTrip() throws {
        let store = try makeStore()
        let preset = makePreset(name: "Gaming night")
        try store.save(preset)
        let listed = store.list()
        #expect(listed.count == 1)
        #expect(listed.first?.preset == preset)
        #expect(listed.first?.fileURL.lastPathComponent == "Gaming night.upto")
    }

    @Test func filenameSanitization() {
        #expect(PresetStore.sanitizedFilename("A/B:C") == "A-B-C")
        #expect(PresetStore.sanitizedFilename("...hidden") == "hidden")
        #expect(PresetStore.sanitizedFilename("   ") == "Preset")
    }

    @Test func nameCollisionGetsSuffix() throws {
        let store = try makeStore()
        try store.save(makePreset(name: "Same"))
        let secondURL = try store.save(makePreset(name: "Same"))
        #expect(secondURL.lastPathComponent == "Same 2.upto")
        #expect(store.list().count == 2)
    }

    @Test func renamingMovesTheFile() throws {
        let store = try makeStore()
        var preset = makePreset(name: "Old name")
        try store.save(preset)
        preset.name = "New name"
        let url = try store.save(preset)
        #expect(url.lastPathComponent == "New name.upto")
        let listed = store.list()
        #expect(listed.count == 1)
        #expect(listed.first?.preset.name == "New name")
    }

    @Test func savingSameIDReplacesContent() throws {
        let store = try makeStore()
        var preset = makePreset(name: "Stable", details: "Before")
        try store.save(preset)
        preset.draft.details = "After"
        try store.save(preset)
        let listed = store.list()
        #expect(listed.count == 1)
        #expect(listed.first?.preset.draft.details == "After")
    }

    @Test func deleteRemovesFile() throws {
        let store = try makeStore()
        let preset = makePreset(name: "Doomed")
        try store.save(preset)
        try store.delete(id: preset.id)
        #expect(store.list().isEmpty)
        #expect(throws: PresetStoreError.presetNotFound) {
            try store.delete(id: preset.id)
        }
    }

    @Test func exportThenImportReproducesPreset() throws {
        let source = try makeStore()
        let destination = try makeStore()
        let preset = makePreset(name: "Traveler")
        try source.save(preset)

        let exportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("travel-\(UUID().uuidString).upto")
        try source.export(preset, to: exportURL)

        let imported = try destination.importPreset(from: exportURL)
        #expect(imported == preset)
        #expect(destination.list().first?.preset == preset)
    }

    @Test func reimportingSameIDUpsertsInsteadOfDuplicating() throws {
        let store = try makeStore()
        let preset = makePreset(name: "Once")
        let exportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("once-\(UUID().uuidString).upto")
        try store.export(preset, to: exportURL)

        try store.importPreset(from: exportURL)
        try store.importPreset(from: exportURL)
        #expect(store.list().count == 1)
    }

    @Test func tolerantDecodingOfForeignFiles() throws {
        let store = try makeStore()
        let minimal = Data("{\"name\":\"Bare\",\"someFutureKey\":true}".utf8)
        let url = store.directory.appendingPathComponent("Bare.upto")
        try minimal.write(to: url)
        let listed = store.list()
        #expect(listed.count == 1)
        #expect(listed.first?.preset.name == "Bare")
        #expect(listed.first?.preset.applicationID == nil)
        #expect(listed.first?.preset.draft == ActivityDraft())
    }

    @Test func unreadableFilesAreSkippedInList() throws {
        let store = try makeStore()
        try Data("not json".utf8).write(to: store.directory.appendingPathComponent("junk.upto"))
        try store.save(makePreset(name: "Good"))
        #expect(store.list().count == 1)
    }

    @Test func presetCodableRoundTrip() throws {
        let preset = makePreset(name: "Round trip")
        let data = try JSONEncoder().encode(preset)
        let decoded = try JSONDecoder().decode(Preset.self, from: data)
        #expect(decoded == preset)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("\"version\":1"))
    }
}
