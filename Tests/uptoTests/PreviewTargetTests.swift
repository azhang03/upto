import Foundation
import Testing
@testable import UptoCore

@Suite struct PreviewTargetTests {
    private func activity(
        type: ActivityType = .playing,
        statusDisplay: StatusDisplayType? = nil,
        start: Int64? = nil,
        end: Int64? = nil
    ) -> Activity {
        var activity = Activity(type: type)
        activity.statusDisplayType = statusDisplay
        if start != nil || end != nil {
            activity.timestamps = Timestamps(start: start, end: end)
        }
        return activity
    }

    @Test func detailsIncludesMemberListOnlyWhenStatusShowsDetails() {
        #expect(previewTargets(for: .details, in: activity(statusDisplay: .details)) == [.cardDetails, .memberListStatus])
        #expect(previewTargets(for: .details, in: activity(statusDisplay: .state)) == [.cardDetails])
        #expect(previewTargets(for: .details, in: activity(statusDisplay: nil)) == [.cardDetails])
    }

    @Test func stateIncludesMemberListOnlyWhenStatusShowsState() {
        #expect(previewTargets(for: .state, in: activity(statusDisplay: .state)) == [.cardState, .memberListStatus])
        #expect(previewTargets(for: .state, in: activity(statusDisplay: .details)) == [.cardState])
        #expect(previewTargets(for: .state, in: activity(statusDisplay: nil)) == [.cardState])
    }

    @Test func timestampsMapToProgressBarOnlyWithBothStampsOnListeningOrWatching() {
        #expect(previewTargets(for: .timestamps, in: activity(type: .listening, start: 1, end: 2)) == [.cardProgressBar])
        #expect(previewTargets(for: .timestamps, in: activity(type: .watching, start: 1, end: 2)) == [.cardProgressBar])
        #expect(previewTargets(for: .timestamps, in: activity(type: .playing, start: 1, end: 2)) == [.cardTimer])
        #expect(previewTargets(for: .timestamps, in: activity(type: .listening, start: 1)) == [.cardTimer])
        #expect(previewTargets(for: .timestamps, in: activity(type: .competing)) == [.cardTimer])
    }

    @Test func tooltipFieldsPointAtTooltips() {
        #expect(previewTargets(for: .largeText, in: activity()) == [.cardLargeImageTooltip])
        #expect(previewTargets(for: .smallText, in: activity()) == [.cardSmallImageTooltip])
    }

    @Test func imageAndImageLinkFieldsPointAtImages() {
        #expect(previewTargets(for: .largeImage, in: activity()) == [.cardLargeImage])
        #expect(previewTargets(for: .largeURL, in: activity()) == [.cardLargeImage])
        #expect(previewTargets(for: .smallImage, in: activity()) == [.cardSmallImage])
        #expect(previewTargets(for: .smallURL, in: activity()) == [.cardSmallImage])
    }

    @Test func buttonFieldsPointAtTheirButton() {
        #expect(previewTargets(for: .buttonLabel(0), in: activity()) == [.cardButton(0)])
        #expect(previewTargets(for: .buttonURL(1), in: activity()) == [.cardButton(1)])
        #expect(previewTargets(for: .buttons, in: activity()) == [.cardButton(0), .cardButton(1)])
    }

    @Test func partyPointsAtStateLineForEveryType() {
        for type in ActivityType.allCases {
            #expect(previewTargets(for: .party, in: activity(type: type)) == [.cardState])
        }
    }

    @Test func everyFieldHasAtLeastOneTarget() {
        let fields: [ActivityField] = [
            .details, .detailsURL, .state, .stateURL,
            .largeImage, .largeText, .largeURL,
            .smallImage, .smallText, .smallURL,
            .timestamps, .party, .buttons, .buttonLabel(0), .buttonURL(0),
        ]
        for field in fields {
            #expect(!previewTargets(for: field, in: activity()).isEmpty)
        }
    }
}
