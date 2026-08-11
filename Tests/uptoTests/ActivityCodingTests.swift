import Foundation
import Testing
@testable import UptoCore

@Suite struct ActivityCodingTests {
    private func encodeToJSON(_ value: some Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }

    @Test func snakeCaseKeysAreExact() throws {
        var activity = Activity(type: .listening, details: "Song title", state: "Artist")
        activity.detailsURL = "https://example.com/song"
        activity.stateURL = "https://example.com/artist"
        activity.statusDisplayType = .details
        activity.assets = Assets(largeImage: "cover", largeText: "Album", largeURL: "https://example.com/album")
        let json = try encodeToJSON(activity)
        #expect(json.contains("\"details_url\":\"https:\\/\\/example.com\\/song\""))
        #expect(json.contains("\"state_url\""))
        #expect(json.contains("\"status_display_type\":2"))
        #expect(json.contains("\"large_image\":\"cover\""))
        #expect(json.contains("\"large_text\":\"Album\""))
        #expect(json.contains("\"large_url\""))
        #expect(json.contains("\"type\":2"))
    }

    @Test func partySizeEncodesAsArray() throws {
        let party = Party(id: "party1", size: PartySize(current: 1, max: 4))
        let json = try encodeToJSON(party)
        #expect(json.contains("\"size\":[1,4]"))
    }

    @Test func partySizeDecodesFromArray() throws {
        let json = Data("{\"id\":\"p\",\"size\":[2,5]}".utf8)
        let party = try JSONDecoder().decode(Party.self, from: json)
        #expect(party.size == PartySize(current: 2, max: 5))
    }

    @Test func nilFieldsAreOmittedNotNull() throws {
        let activity = Activity(type: .playing, details: "Just details")
        let json = try encodeToJSON(activity)
        #expect(!json.contains("null"))
        #expect(!json.contains("state"))
        #expect(!json.contains("assets"))
    }

    @Test func timestampsEncodeAsIntegers() throws {
        let activity = Activity(type: .playing, timestamps: Timestamps(start: 1723400000000, end: 1723400060000))
        let json = try encodeToJSON(activity)
        #expect(json.contains("\"start\":1723400000000"))
        #expect(json.contains("\"end\":1723400060000"))
    }

    @Test func activityTypeRawValues() {
        #expect(ActivityType.playing.rawValue == 0)
        #expect(ActivityType.listening.rawValue == 2)
        #expect(ActivityType.watching.rawValue == 3)
        #expect(ActivityType.competing.rawValue == 5)
    }

    @Test func normalizationTrimsAndDropsEmpties() {
        var activity = Activity(type: .playing, details: "  padded  ", state: "   ")
        activity.assets = Assets(largeImage: "", largeText: nil)
        activity.party = Party(id: "")
        activity.timestamps = Timestamps()
        activity.buttons = [ActivityButton(label: " ", url: "")]
        let normalized = activity.normalized()
        #expect(normalized.details == "padded")
        #expect(normalized.state == nil)
        #expect(normalized.assets == nil)
        #expect(normalized.party == nil)
        #expect(normalized.timestamps == nil)
        #expect(normalized.buttons == nil)
    }

    @Test func roundTripPreservesActivity() throws {
        var activity = Activity(type: .competing, details: "Ranked match", state: "In queue")
        activity.party = Party(id: "abc", size: PartySize(current: 3, max: 5))
        activity.buttons = [ActivityButton(label: "Watch", url: "https://example.com")]
        activity.timestamps = Timestamps(start: 1000, end: 2000)
        let data = try JSONEncoder().encode(activity)
        let decoded = try JSONDecoder().decode(Activity.self, from: data)
        #expect(decoded == activity)
    }
}
