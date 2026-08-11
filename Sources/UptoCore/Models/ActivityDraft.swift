import Foundation

public struct DraftButton: Codable, Equatable, Hashable, Sendable {
    public var label: String
    public var url: String

    public init(label: String = "", url: String = "") {
        self.label = label
        self.url = url
    }
}

// The editable working copy behind the editor form. Text fields stay
// String typed so every keystroke reaches the live preview; building
// the Activity does the parsing and cleanup in one place.
public struct ActivityDraft: Codable, Equatable, Sendable {
    public enum TimestampMode: String, Codable, CaseIterable, Sendable {
        case off
        case sinceApply
        case custom
    }

    public var type: ActivityType = .playing
    public var statusDisplay: StatusDisplayType = .name
    public var details = ""
    public var detailsURL = ""
    public var state = ""
    public var stateURL = ""
    public var largeImage = ""
    public var largeText = ""
    public var largeURL = ""
    public var smallImage = ""
    public var smallText = ""
    public var smallURL = ""
    public var timestampMode: TimestampMode = .off
    public var customStart = Date(timeIntervalSince1970: 0)
    public var endEnabled = false
    public var customEnd = Date(timeIntervalSince1970: 0)
    public var partyEnabled = false
    public var partyCurrent = "1"
    public var partyMax = "4"
    public var buttons: [DraftButton] = [DraftButton(), DraftButton()]

    public init() {}

    public init(activity: Activity) {
        type = activity.type
        statusDisplay = activity.statusDisplayType ?? .name
        details = activity.details ?? ""
        detailsURL = activity.detailsURL ?? ""
        state = activity.state ?? ""
        stateURL = activity.stateURL ?? ""
        largeImage = activity.assets?.largeImage ?? ""
        largeText = activity.assets?.largeText ?? ""
        largeURL = activity.assets?.largeURL ?? ""
        smallImage = activity.assets?.smallImage ?? ""
        smallText = activity.assets?.smallText ?? ""
        smallURL = activity.assets?.smallURL ?? ""

        if let timestamps = activity.timestamps, timestamps.start != nil || timestamps.end != nil {
            timestampMode = .custom
            if let start = timestamps.start {
                customStart = Date(timeIntervalSince1970: Double(start) / 1000)
            }
            if let end = timestamps.end {
                endEnabled = true
                customEnd = Date(timeIntervalSince1970: Double(end) / 1000)
            }
        }

        if let size = activity.party?.size {
            partyEnabled = true
            partyCurrent = String(size.current)
            partyMax = String(size.max)
        }

        var loaded = (activity.buttons ?? []).map { DraftButton(label: $0.label, url: $0.url) }
        while loaded.count < 2 {
            loaded.append(DraftButton())
        }
        buttons = loaded
    }

    public func buildActivity(now: Date = Date()) -> Activity {
        var activity = Activity(type: type)
        activity.details = details
        activity.detailsURL = detailsURL
        activity.state = state
        activity.stateURL = stateURL
        activity.statusDisplayType = statusDisplay == .name ? nil : statusDisplay
        activity.assets = Assets(
            largeImage: largeImage, largeText: largeText, largeURL: largeURL,
            smallImage: smallImage, smallText: smallText, smallURL: smallURL
        )

        switch timestampMode {
        case .off:
            break
        case .sinceApply:
            activity.timestamps = Timestamps(start: Self.unixMilliseconds(now))
        case .custom:
            var timestamps = Timestamps(start: Self.unixMilliseconds(customStart))
            if endEnabled {
                timestamps.end = Self.unixMilliseconds(customEnd)
            }
            activity.timestamps = timestamps
        }

        if partyEnabled,
           let current = Int(partyCurrent.trimmingCharacters(in: .whitespaces)),
           let max = Int(partyMax.trimmingCharacters(in: .whitespaces)) {
            activity.party = Party(size: PartySize(current: current, max: max))
        }

        let filled = buttons
            .filter { !$0.label.trimmingCharacters(in: .whitespaces).isEmpty || !$0.url.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { ActivityButton(label: $0.label, url: $0.url) }
        activity.buttons = filled.isEmpty ? nil : filled

        return activity.normalized()
    }

    // Errors the Activity model cannot express because the raw strings
    // never make it into the built value.
    public func localIssues() -> [ActivityValidationIssue] {
        var issues: [ActivityValidationIssue] = []
        if partyEnabled {
            let current = Int(partyCurrent.trimmingCharacters(in: .whitespaces))
            let max = Int(partyMax.trimmingCharacters(in: .whitespaces))
            if current == nil || max == nil {
                issues.append(ActivityValidationIssue(
                    field: .party,
                    severity: .error,
                    message: "Party sizes must be whole numbers."
                ))
            }
        }
        return issues
    }

    private static func unixMilliseconds(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000).rounded())
    }
}
