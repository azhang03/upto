import Foundation
import Testing
@testable import UptoCore

@Suite struct ActivityDraftTests {
    @Test func emptyDraftBuildsBareActivity() {
        let activity = ActivityDraft().buildActivity()
        #expect(activity == Activity(type: .playing))
    }

    @Test func whitespaceFieldsAreDropped() {
        var draft = ActivityDraft()
        draft.details = "  padded  "
        draft.state = "   "
        let activity = draft.buildActivity()
        #expect(activity.details == "padded")
        #expect(activity.state == nil)
    }

    @Test func statusDisplayNameEmitsNilOnWire() {
        var draft = ActivityDraft()
        draft.statusDisplay = .name
        #expect(draft.buildActivity().statusDisplayType == nil)
        draft.statusDisplay = .state
        #expect(draft.buildActivity().statusDisplayType == .state)
        draft.statusDisplay = .details
        #expect(draft.buildActivity().statusDisplayType == .details)
    }

    @Test func initFromActivityMapsNilStatusDisplayToName() {
        let draft = ActivityDraft(activity: Activity(type: .playing))
        #expect(draft.statusDisplay == .name)
    }

    @Test func sinceApplyUsesInjectedNow() {
        var draft = ActivityDraft()
        draft.timestampMode = .sinceApply
        let now = Date(timeIntervalSince1970: 1723400000.5)
        let activity = draft.buildActivity(now: now)
        #expect(activity.timestamps?.start == 1723400000500)
        #expect(activity.timestamps?.end == nil)
    }

    @Test func customTimestampsConvertToMilliseconds() {
        var draft = ActivityDraft()
        draft.timestampMode = .custom
        draft.customStart = Date(timeIntervalSince1970: 1000)
        draft.endEnabled = true
        draft.customEnd = Date(timeIntervalSince1970: 2000)
        let activity = draft.buildActivity()
        #expect(activity.timestamps?.start == 1_000_000)
        #expect(activity.timestamps?.end == 2_000_000)
    }

    @Test func disabledEndIsOmitted() {
        var draft = ActivityDraft()
        draft.timestampMode = .custom
        draft.customStart = Date(timeIntervalSince1970: 1000)
        draft.endEnabled = false
        #expect(draft.buildActivity().timestamps?.end == nil)
    }

    @Test func partyDisabledYieldsNoParty() {
        var draft = ActivityDraft()
        draft.partyEnabled = false
        draft.partyCurrent = "3"
        draft.partyMax = "5"
        #expect(draft.buildActivity().party == nil)
    }

    @Test func partyStringsParse() {
        var draft = ActivityDraft()
        draft.partyEnabled = true
        draft.partyCurrent = " 3 "
        draft.partyMax = "5"
        #expect(draft.buildActivity().party?.size == PartySize(current: 3, max: 5))
        #expect(draft.localIssues().isEmpty)
    }

    @Test func unparseablePartyReportsLocalIssue() {
        var draft = ActivityDraft()
        draft.partyEnabled = true
        draft.partyCurrent = "three"
        draft.partyMax = "5"
        #expect(draft.buildActivity().party == nil)
        let issues = draft.localIssues()
        #expect(issues.count == 1)
        #expect(issues.first?.field == .party)
        #expect(issues.first?.severity == .error)
    }

    @Test func blankButtonRowsAreDropped() {
        var draft = ActivityDraft()
        draft.buttons = [DraftButton(label: "Visit", url: "https://example.com"), DraftButton()]
        let buttons = draft.buildActivity().buttons
        #expect(buttons == [ActivityButton(label: "Visit", url: "https://example.com")])
    }

    @Test func roundTripMatchesNormalizedOriginal() {
        var original = Activity(type: .listening, details: "Song", state: "Artist")
        original.detailsURL = "https://example.com/song"
        original.statusDisplayType = .state
        original.assets = Assets(largeImage: "cover", largeText: "Album", smallImage: "badge")
        original.timestamps = Timestamps(start: 1_723_400_000_000, end: 1_723_400_060_000)
        original.party = Party(size: PartySize(current: 2, max: 4))
        original.buttons = [ActivityButton(label: "Listen", url: "https://example.com")]

        let rebuilt = ActivityDraft(activity: original).buildActivity()
        #expect(rebuilt == original.normalized())
    }

    @Test func codableRoundTripPreservesDraft() throws {
        var draft = ActivityDraft()
        draft.type = .watching
        draft.details = "A show"
        draft.timestampMode = .custom
        draft.customStart = Date(timeIntervalSince1970: 12345)
        draft.partyEnabled = true
        draft.partyCurrent = "2"
        let data = try JSONEncoder().encode(draft)
        let decoded = try JSONDecoder().decode(ActivityDraft.self, from: data)
        #expect(decoded == draft)
    }
}
