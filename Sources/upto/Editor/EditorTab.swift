import Foundation
import UptoCore

// The editor's tab pages and the labels the editor shows for the
// draft enums. The labels live here, on the UI side, so UptoCore
// stays free of display text.
enum EditorTab: CaseIterable, Hashable {
    case activity
    case images
    case timing
    case party
    case buttons

    var title: String {
        switch self {
        case .activity: return "Activity"
        case .images: return "Images"
        case .timing: return "Timing"
        case .party: return "Party"
        case .buttons: return "Buttons"
        }
    }
}

extension EditorFocus {
    // The tab that shows each control. The application row is pinned
    // above the tabs, so it has no tab.
    var tab: EditorTab? {
        switch self {
        case .applicationID:
            return nil
        case .activityType, .activityName, .statusDisplay,
             .details, .detailsURL, .state, .stateURL:
            return .activity
        case .largeImage, .largeText, .largeURL,
             .smallImage, .smallText, .smallURL:
            return .images
        case .timestampMode, .timestampStart, .timestampEnd:
            return .timing
        case .partyCurrent, .partyMax:
            return .party
        case .buttonLabel, .buttonURL:
            return .buttons
        }
    }
}

extension ActivityType {
    var displayName: String {
        switch self {
        case .playing: return "Playing"
        case .listening: return "Listening"
        case .watching: return "Watching"
        case .competing: return "Competing"
        }
    }
}

extension StatusDisplayType {
    var displayName: String {
        switch self {
        case .name: return "Name"
        case .state: return "State"
        case .details: return "Details"
        }
    }
}

extension ActivityDraft.TimestampMode {
    var displayName: String {
        switch self {
        case .off: return "Off"
        case .sinceApply: return "Time since update"
        case .custom: return "Custom"
        }
    }
}
