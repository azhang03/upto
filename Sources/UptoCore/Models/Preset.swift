import Foundation

// A named presence configuration. The same JSON is used for the local
// library and for exported .upto files, so sharing a preset is a plain
// file copy.
public struct Preset: Codable, Equatable, Sendable, Identifiable {
    public static let currentVersion = 1

    public var version: Int
    public var id: UUID
    public var name: String
    // Optional so a preset can carry its own Discord application.
    // Nil means keep whatever application is currently connected.
    public var applicationID: String?
    public var draft: ActivityDraft

    public init(id: UUID = UUID(), name: String, applicationID: String? = nil, draft: ActivityDraft) {
        self.version = Self.currentVersion
        self.id = id
        self.name = name
        self.applicationID = applicationID
        self.draft = draft
    }

    enum CodingKeys: String, CodingKey {
        case version, id, name, applicationID, draft
    }

    // Files can come from older or newer app versions and from other
    // people. Decode what is there and fall back for the rest.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Imported preset"
        applicationID = try container.decodeIfPresent(String.self, forKey: .applicationID)
        draft = try container.decodeIfPresent(ActivityDraft.self, forKey: .draft) ?? ActivityDraft()
    }
}
