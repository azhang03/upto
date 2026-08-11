import Foundation

public struct StoredPreset: Sendable, Equatable {
    public let preset: Preset
    public let fileURL: URL

    public init(preset: Preset, fileURL: URL) {
        self.preset = preset
        self.fileURL = fileURL
    }
}

public enum PresetStoreError: Error, Equatable {
    case presetNotFound
    case unreadableFile
}

// Keeps the preset library as one .upto file per preset in a plain
// directory. Files are named after the preset so the folder stays
// readable in Finder; identity lives in the id inside the file.
public final class PresetStore: Sendable {
    public let directory: URL

    public init(directory: URL? = nil) throws {
        let resolved = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("upto/Presets", isDirectory: true)
        try FileManager.default.createDirectory(at: resolved, withIntermediateDirectories: true)
        // Temp and home paths can reach the same file through symlinks
        // (/var vs /private/var). Resolving here keeps every URL the
        // store builds comparable with what directory listing returns.
        self.directory = resolved.resolvingSymlinksInPath()
    }

    public func list() -> [StoredPreset] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return urls
            .filter { $0.pathExtension.lowercased() == "upto" }
            .compactMap { url in
                (try? load(from: url)).map { StoredPreset(preset: $0, fileURL: url) }
            }
            .sorted { $0.preset.name.localizedCaseInsensitiveCompare($1.preset.name) == .orderedAscending }
    }

    public func load(from url: URL) throws -> Preset {
        guard let data = try? Data(contentsOf: url) else {
            throw PresetStoreError.unreadableFile
        }
        guard let preset = try? Self.decoder().decode(Preset.self, from: data) else {
            throw PresetStoreError.unreadableFile
        }
        return preset
    }

    // Writes the preset, replacing its previous file when the id is
    // already in the library. A name change moves the file.
    @discardableResult
    public func save(_ preset: Preset) throws -> URL {
        let existing = list().first { $0.preset.id == preset.id }
        let target = availableURL(for: preset, allowing: existing?.fileURL)
        let data = try Self.encoder().encode(preset)
        try data.write(to: target, options: .atomic)
        if let oldURL = existing?.fileURL,
           oldURL.resolvingSymlinksInPath().path != target.resolvingSymlinksInPath().path {
            try? FileManager.default.removeItem(at: oldURL)
        }
        return target
    }

    public func delete(id: UUID) throws {
        guard let stored = list().first(where: { $0.preset.id == id }) else {
            throw PresetStoreError.presetNotFound
        }
        try FileManager.default.removeItem(at: stored.fileURL)
    }

    // Copies an external file into the library. A preset with the same
    // id replaces its existing entry instead of duplicating it.
    @discardableResult
    public func importPreset(from url: URL) throws -> Preset {
        let preset = try load(from: url)
        try save(preset)
        return preset
    }

    public func export(_ preset: Preset, to url: URL) throws {
        let data = try Self.encoder().encode(preset)
        try data.write(to: url, options: .atomic)
    }

    private func availableURL(for preset: Preset, allowing reusable: URL?) -> URL {
        let base = Self.sanitizedFilename(preset.name)
        var candidate = directory.appendingPathComponent("\(base).upto")
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            if candidate == reusable {
                return candidate
            }
            // A different preset owns this filename only if its id differs.
            if let occupant = try? load(from: candidate), occupant.id == preset.id {
                return candidate
            }
            candidate = directory.appendingPathComponent("\(base) \(counter).upto")
            counter += 1
        }
        return candidate
    }

    static func sanitizedFilename(_ name: String) -> String {
        var cleaned = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        while cleaned.hasPrefix(".") {
            cleaned.removeFirst()
        }
        return cleaned.isEmpty ? "Preset" : cleaned
    }

    private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static func decoder() -> JSONDecoder {
        JSONDecoder()
    }
}
