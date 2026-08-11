import Foundation
import Testing
@testable import UptoCore

@Suite struct ActivityValidationTests {
    private func errors(_ activity: Activity) -> [ActivityField] {
        activity.validate().filter { $0.severity == .error }.map(\.field)
    }

    private func warnings(_ activity: Activity) -> [ActivityField] {
        activity.validate().filter { $0.severity == .warning }.map(\.field)
    }

    @Test func nameLengthBoundaries() {
        #expect(errors(Activity(name: "x")) == [.name])
        #expect(errors(Activity(name: "ok")).isEmpty)
        #expect(errors(Activity(name: String(repeating: "a", count: 128))).isEmpty)
        #expect(errors(Activity(name: String(repeating: "a", count: 129))) == [.name])
    }

    @Test func detailsLengthBoundaries() {
        #expect(errors(Activity(details: "x")) == [.details])
        #expect(errors(Activity(details: "xy")).isEmpty)
        #expect(errors(Activity(details: String(repeating: "a", count: 128))).isEmpty)
        #expect(errors(Activity(details: String(repeating: "a", count: 129))) == [.details])
    }

    @Test func stateLengthBoundaries() {
        #expect(errors(Activity(state: "x")) == [.state])
        #expect(errors(Activity(state: "ok")).isEmpty)
    }

    @Test func tooltipLengths() {
        var activity = Activity()
        activity.assets = Assets(largeText: "a")
        #expect(errors(activity) == [.largeText])
    }

    @Test func linkNeedsItsTextLine() {
        var activity = Activity()
        activity.detailsURL = "https://example.com"
        #expect(errors(activity).contains(.detailsURL))
        activity.details = "Some details"
        #expect(errors(activity).isEmpty)
    }

    @Test func linkSchemeChecks() {
        var activity = Activity(details: "Some details")
        activity.detailsURL = "ftp://example.com"
        #expect(errors(activity) == [.detailsURL])
        activity.detailsURL = "https://example.com"
        #expect(errors(activity).isEmpty)
    }

    @Test func buttonRules() {
        var activity = Activity()
        activity.buttons = [
            ActivityButton(label: "One", url: "https://example.com/1"),
            ActivityButton(label: "Two", url: "https://example.com/2"),
            ActivityButton(label: "Three", url: "https://example.com/3"),
        ]
        #expect(errors(activity) == [.buttons])

        activity.buttons = [ActivityButton(label: String(repeating: "a", count: 33), url: "https://example.com")]
        #expect(errors(activity) == [.buttonLabel(0)])

        activity.buttons = [ActivityButton(label: "Fine", url: "not a url")]
        #expect(errors(activity) == [.buttonURL(0)])

        activity.buttons = [ActivityButton(label: "Fine", url: "https://example.com")]
        #expect(errors(activity).isEmpty)
    }

    @Test func timestampOrder() {
        var activity = Activity()
        activity.timestamps = Timestamps(start: 2000, end: 1000)
        #expect(errors(activity) == [.timestamps])
        activity.timestamps = Timestamps(start: 1000, end: 2000)
        #expect(errors(activity).isEmpty)
    }

    @Test func partyBounds() {
        var activity = Activity()
        activity.party = Party(size: PartySize(current: 0, max: 4))
        #expect(errors(activity) == [.party])
        activity.party = Party(size: PartySize(current: 5, max: 4))
        #expect(errors(activity) == [.party])
        activity.party = Party(size: PartySize(current: 2, max: 4))
        #expect(errors(activity).isEmpty)
    }

    @Test func partyWarnsOffPlayingType() {
        var activity = Activity(type: .listening)
        activity.party = Party(size: PartySize(current: 1, max: 2))
        #expect(warnings(activity).contains(.party))
        activity.type = .playing
        #expect(!warnings(activity).contains(.party))
    }

    @Test func progressBarWarnsOnHalfTimestamps() {
        var activity = Activity(type: .listening)
        activity.timestamps = Timestamps(start: 1000)
        #expect(warnings(activity).contains(.timestamps))
        activity.timestamps = Timestamps(start: 1000, end: 2000)
        #expect(!warnings(activity).contains(.timestamps))
    }

    @Test func imageFieldAcceptsKeyOrHTTPS() {
        var activity = Activity()
        activity.assets = Assets(largeImage: "my_asset_key")
        #expect(errors(activity).isEmpty)
        activity.assets = Assets(largeImage: "https://example.com/image.png")
        #expect(errors(activity).isEmpty)
        activity.assets = Assets(largeImage: "file:///etc/passwd")
        #expect(errors(activity) == [.largeImage])
    }
}
