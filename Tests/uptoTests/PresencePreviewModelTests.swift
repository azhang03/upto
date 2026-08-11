import Foundation
import Testing
@testable import UptoCore

@Suite struct PresencePreviewModelTests {
    private let now = Date(timeIntervalSince1970: 1_723_400_100)

    @Test func headerVerbPerType() {
        let cases: [(ActivityType, String)] = [
            (.playing, "Playing Your app"),
            (.listening, "Listening to Your app"),
            (.watching, "Watching Your app"),
            (.competing, "Competing in Your app"),
        ]
        for (type, expected) in cases {
            let model = PresencePreviewModel(activity: Activity(type: type), appName: "Your app", now: now)
            #expect(model.headerText == expected)
        }
    }

    @Test func partySuffixRendersOnlyOnPlaying() {
        var activity = Activity(type: .listening)
        activity.party = Party(size: PartySize(current: 1, max: 4))
        var model = PresencePreviewModel(activity: activity, appName: "App", now: now)
        #expect(model.partySuffix == PresencePreviewModel.PartySuffix(text: "(1 of 4)", rendersOnDiscord: false))

        activity.type = .playing
        model = PresencePreviewModel(activity: activity, appName: "App", now: now)
        #expect(model.partySuffix?.rendersOnDiscord == true)
    }

    @Test func progressBarOnlyForListeningWatchingWithBothStamps() {
        let startMS = Int64(1_723_400_000_000)
        let endMS = Int64(1_723_400_200_000)

        var activity = Activity(type: .listening)
        activity.timestamps = Timestamps(start: startMS, end: endMS)
        var model = PresencePreviewModel(activity: activity, appName: "App", now: now)
        #expect(model.progress != nil)
        #expect(model.timer == nil)
        #expect(abs((model.progress?.fraction ?? 0) - 0.5) < 0.001)
        #expect(model.progress?.totalText == "3:20")

        activity.type = .playing
        model = PresencePreviewModel(activity: activity, appName: "App", now: now)
        #expect(model.progress == nil)
        #expect(model.timer == .remaining("1:40 left"))
    }

    @Test func elapsedTimerForStartOnly() {
        var activity = Activity(type: .playing)
        activity.timestamps = Timestamps(start: 1_723_400_000_000)
        let model = PresencePreviewModel(activity: activity, appName: "App", now: now)
        #expect(model.timer == .elapsed("1:40 elapsed"))
    }

    @Test func noTimestampsMeansNoTimer() {
        let model = PresencePreviewModel(activity: Activity(type: .playing), appName: "App", now: now)
        #expect(model.timer == nil)
        #expect(model.progress == nil)
    }

    @Test func memberListTextFollowsStatusDisplay() {
        var activity = Activity(type: .listening, details: "Song title", state: "Artist name")
        activity.statusDisplayType = .state
        var model = PresencePreviewModel(activity: activity, appName: "App", now: now)
        #expect(model.memberListText == "Listening to Artist name")

        activity.statusDisplayType = .details
        model = PresencePreviewModel(activity: activity, appName: "App", now: now)
        #expect(model.memberListText == "Listening to Song title")

        activity.statusDisplayType = nil
        model = PresencePreviewModel(activity: activity, appName: "App", now: now)
        #expect(model.memberListText == "Listening to App")
    }

    @Test func memberListFallsBackWhenChosenFieldEmpty() {
        var activity = Activity(type: .watching)
        activity.statusDisplayType = .state
        let model = PresencePreviewModel(activity: activity, appName: "App", now: now)
        #expect(model.memberListText == "Watching App")
    }

    @Test func linkFlagsTrackURLFields() {
        var activity = Activity(type: .playing, details: "Details here")
        activity.detailsURL = "https://example.com"
        activity.assets = Assets(largeImage: "img", largeURL: "https://example.com/large")
        let model = PresencePreviewModel(activity: activity, appName: "App", now: now)
        #expect(model.detailsLine?.isLink == true)
        #expect(model.largeImageIsLink)
        #expect(!model.smallImageIsLink)
    }

    @Test func largeTextBecomesThirdLineOnlyForListening() {
        var activity = Activity(type: .listening, details: "Song", state: "Artist")
        activity.assets = Assets(largeImage: "cover", largeText: "Album name")
        var model = PresencePreviewModel(activity: activity, appName: "App", now: now)
        #expect(model.largeTextLine == "Album name")
        #expect(model.largeTooltip == "Album name")

        activity.type = .playing
        model = PresencePreviewModel(activity: activity, appName: "App", now: now)
        #expect(model.largeTextLine == nil)
        #expect(model.largeTooltip == "Album name")
    }

    @Test func buttonsAreCappedAtTwoLabels() {
        var activity = Activity(type: .playing)
        activity.buttons = [
            ActivityButton(label: "One", url: "https://a.example"),
            ActivityButton(label: "Two", url: "https://b.example"),
        ]
        let model = PresencePreviewModel(activity: activity, appName: "App", now: now)
        #expect(model.buttons == ["One", "Two"])
    }

    @Test func clockTextFormats() {
        #expect(PresencePreviewModel.clockText(milliseconds: 61_000) == "1:01")
        #expect(PresencePreviewModel.clockText(milliseconds: 3_661_000) == "1:01:01")
        #expect(PresencePreviewModel.clockText(milliseconds: 0) == "0:00")
    }
}
