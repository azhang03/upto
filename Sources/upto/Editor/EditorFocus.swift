import Foundation
import UptoCore

// Every focusable control in the editor. Some cases are UI concepts
// with no ActivityField counterpart, so they map to preview targets
// directly.
enum EditorFocus: Hashable {
    case applicationID
    case activityType
    case activityName
    case statusDisplay
    case timestampMode
    case details
    case detailsURL
    case state
    case stateURL
    case largeImage
    case largeText
    case largeURL
    case smallImage
    case smallText
    case smallURL
    case timestampStart
    case timestampEnd
    case partyCurrent
    case partyMax
    case buttonLabel(Int)
    case buttonURL(Int)

    var activityField: ActivityField? {
        switch self {
        case .activityName: return .name
        case .details: return .details
        case .detailsURL: return .detailsURL
        case .state: return .state
        case .stateURL: return .stateURL
        case .largeImage: return .largeImage
        case .largeText: return .largeText
        case .largeURL: return .largeURL
        case .smallImage: return .smallImage
        case .smallText: return .smallText
        case .smallURL: return .smallURL
        case .timestampStart, .timestampEnd: return .timestamps
        case .partyCurrent, .partyMax: return .party
        case .buttonLabel(let index): return .buttonLabel(index)
        case .buttonURL(let index): return .buttonURL(index)
        case .applicationID, .activityType, .statusDisplay, .timestampMode: return nil
        }
    }

    func previewTargets(in activity: Activity) -> [PreviewTarget] {
        switch self {
        case .applicationID:
            let statusDisplay = activity.statusDisplayType ?? .name
            // Playing shows the app name as its own line in the card
            // body. The other types carry it in the header.
            let nameTarget: PreviewTarget = activity.type == .playing ? .cardAppName : .cardHeader
            return statusDisplay == .name ? [nameTarget, .memberListStatus] : [nameTarget]
        case .activityType:
            return [.cardHeader]
        case .statusDisplay:
            return [.memberListStatus]
        case .timestampMode:
            return UptoCore.previewTargets(for: .timestamps, in: activity)
        default:
            guard let field = activityField else { return [] }
            return UptoCore.previewTargets(for: field, in: activity)
        }
    }
}
