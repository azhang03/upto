import Foundation

// The elements of the live preview a form field can point at.
public enum PreviewTarget: Hashable, Sendable {
    case cardHeader
    case cardDetails
    case cardState
    case cardLargeImage
    case cardSmallImage
    case cardLargeImageTooltip
    case cardSmallImageTooltip
    case cardLargeTextLine
    case cardTimer
    case cardProgressBar
    case cardButton(Int)
    case memberListStatus
}

// Maps a field to the preview elements it affects for the current
// activity. The first element is where the connector line ends; every
// element gets highlighted.
public func previewTargets(for field: ActivityField, in activity: Activity) -> [PreviewTarget] {
    let statusDisplay = activity.statusDisplayType ?? .name

    switch field {
    case .details:
        return statusDisplay == .details ? [.cardDetails, .memberListStatus] : [.cardDetails]
    case .detailsURL:
        return [.cardDetails]
    case .state:
        return statusDisplay == .state ? [.cardState, .memberListStatus] : [.cardState]
    case .stateURL:
        return [.cardState]
    case .largeImage, .largeURL:
        return [.cardLargeImage]
    case .largeText:
        // Listening shows the large image text twice: as a visible
        // third line under State and as the image hover tooltip.
        return activity.type == .listening
            ? [.cardLargeTextLine, .cardLargeImageTooltip]
            : [.cardLargeImageTooltip]
    case .smallImage, .smallURL:
        return [.cardSmallImage]
    case .smallText:
        return [.cardSmallImageTooltip]
    case .timestamps:
        let barShown = (activity.type == .listening || activity.type == .watching)
            && activity.timestamps?.start != nil
            && activity.timestamps?.end != nil
        return barShown ? [.cardProgressBar] : [.cardTimer]
    case .party:
        return [.cardState]
    case .buttons:
        return [.cardButton(0), .cardButton(1)]
    case .buttonLabel(let index), .buttonURL(let index):
        return [.cardButton(index)]
    }
}
