import Foundation

// Computes what Discord will actually render for an activity, so the
// preview shows the truth instead of echoing the form. All render rules
// live here where they can be tested without any UI.
public struct PresencePreviewModel: Equatable, Sendable {
    public struct LinkableLine: Equatable, Sendable {
        public let text: String
        public let isLink: Bool

        public init(text: String, isLink: Bool) {
            self.text = text
            self.isLink = isLink
        }
    }

    public struct PartySuffix: Equatable, Sendable {
        public let text: String
        // False means Discord ignores the party for this activity type
        // and the preview shows it grayed out.
        public let rendersOnDiscord: Bool

        public init(text: String, rendersOnDiscord: Bool) {
            self.text = text
            self.rendersOnDiscord = rendersOnDiscord
        }
    }

    public enum TimerLine: Equatable, Sendable {
        case elapsed(String)
        case remaining(String)
    }

    public struct ProgressInfo: Equatable, Sendable {
        public let fraction: Double
        public let elapsedText: String
        public let totalText: String

        public init(fraction: Double, elapsedText: String, totalText: String) {
            self.fraction = fraction
            self.elapsedText = elapsedText
            self.totalText = totalText
        }
    }

    public let headerText: String
    public let detailsLine: LinkableLine?
    public let stateLine: LinkableLine?
    public let partySuffix: PartySuffix?
    public let timer: TimerLine?
    public let progress: ProgressInfo?
    public let largeImagePresent: Bool
    public let smallImagePresent: Bool
    public let largeImageIsLink: Bool
    public let smallImageIsLink: Bool
    public let largeTooltip: String?
    public let smallTooltip: String?
    public let buttons: [String]
    public let memberListText: String

    public init(activity: Activity, appName: String, now: Date = Date()) {
        headerText = Self.verbLine(type: activity.type, subject: appName)

        detailsLine = activity.details.map {
            LinkableLine(text: $0, isLink: activity.detailsURL != nil)
        }
        stateLine = activity.state.map {
            LinkableLine(text: $0, isLink: activity.stateURL != nil)
        }

        if let size = activity.party?.size {
            partySuffix = PartySuffix(
                text: "(\(size.current) of \(size.max))",
                rendersOnDiscord: activity.type == .playing
            )
        } else {
            partySuffix = nil
        }

        let start = activity.timestamps?.start
        let end = activity.timestamps?.end
        let nowMS = Int64((now.timeIntervalSince1970 * 1000).rounded())
        let barShown = (activity.type == .listening || activity.type == .watching)
            && start != nil && end != nil

        if barShown, let start, let end, end > start {
            let fraction = min(1, max(0, Double(nowMS - start) / Double(end - start)))
            progress = ProgressInfo(
                fraction: fraction,
                elapsedText: Self.clockText(milliseconds: max(0, min(nowMS, end) - start)),
                totalText: Self.clockText(milliseconds: end - start)
            )
            timer = nil
        } else if let end {
            timer = .remaining(Self.clockText(milliseconds: max(0, end - nowMS)) + " left")
            progress = nil
        } else if let start {
            timer = .elapsed(Self.clockText(milliseconds: max(0, nowMS - start)) + " elapsed")
            progress = nil
        } else {
            timer = nil
            progress = nil
        }

        largeImagePresent = activity.assets?.largeImage != nil
        smallImagePresent = activity.assets?.smallImage != nil
        largeImageIsLink = activity.assets?.largeURL != nil
        smallImageIsLink = activity.assets?.smallURL != nil
        largeTooltip = activity.assets?.largeText
        smallTooltip = activity.assets?.smallText

        buttons = (activity.buttons ?? []).prefix(2).map(\.label)

        // The member list keeps the type verb and swaps in the chosen
        // field, falling back to the app name when that field is empty.
        switch activity.statusDisplayType ?? .name {
        case .name:
            memberListText = Self.verbLine(type: activity.type, subject: appName)
        case .state:
            memberListText = Self.verbLine(type: activity.type, subject: activity.state ?? appName)
        case .details:
            memberListText = Self.verbLine(type: activity.type, subject: activity.details ?? appName)
        }
    }

    private static func verbLine(type: ActivityType, subject: String) -> String {
        switch type {
        case .playing: return "Playing \(subject)"
        case .listening: return "Listening to \(subject)"
        case .watching: return "Watching \(subject)"
        case .competing: return "Competing in \(subject)"
        }
    }

    static func clockText(milliseconds: Int64) -> String {
        let totalSeconds = Int(milliseconds / 1000)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
