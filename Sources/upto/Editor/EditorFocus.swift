import Foundation
import UptoCore

// Every focusable control in the editor. Some cases are UI concepts
// with no ActivityField counterpart, so they map to preview targets
// directly.
enum EditorFocus: Hashable {
    case applicationID
    case activityType
    case statusDisplay
    case timestampMode
    case details
    case state
    case largeImage
    case largeText
    case smallImage
    case smallText
    case timestampStart
    case timestampEnd
    case partyCurrent
    case partyMax

    var activityField: ActivityField? {
        switch self {
        case .details: return .details
        case .state: return .state
        case .largeImage: return .largeImage
        case .largeText: return .largeText
        case .smallImage: return .smallImage
        case .smallText: return .smallText
        case .timestampStart, .timestampEnd: return .timestamps
        case .partyCurrent, .partyMax: return .party
        case .applicationID, .activityType, .statusDisplay, .timestampMode: return nil
        }
    }

    func previewTargets(in activity: Activity) -> [PreviewTarget] {
        switch self {
        case .applicationID:
            let statusDisplay = activity.statusDisplayType ?? .name
            return statusDisplay == .name ? [.cardHeader, .memberListStatus] : [.cardHeader]
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
