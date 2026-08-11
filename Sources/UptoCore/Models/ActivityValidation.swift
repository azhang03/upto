import Foundation

public enum ActivityField: Sendable, Equatable, Hashable {
    case name
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
    case timestamps
    case party
    case buttons
    case buttonLabel(Int)
    case buttonURL(Int)
}

public struct ActivityValidationIssue: Sendable, Equatable {
    public enum Severity: Sendable, Equatable {
        case error
        case warning
    }

    public let field: ActivityField
    public let severity: Severity
    public let message: String

    public init(field: ActivityField, severity: Severity, message: String) {
        self.field = field
        self.severity = severity
        self.message = message
    }
}

public struct ActivityValidationError: Error, Sendable, Equatable {
    public let issues: [ActivityValidationIssue]

    public init(issues: [ActivityValidationIssue]) {
        self.issues = issues
    }
}

extension Activity {
    // Discord silently drops the whole update when a field breaks its
    // limits, so everything here gets checked before anything is sent.
    // Warnings flag combinations that are legal but will not render.
    public func validate() -> [ActivityValidationIssue] {
        var issues: [ActivityValidationIssue] = []

        checkText(name, field: .name, name: "Name", into: &issues)
        checkText(details, field: .details, name: "Details", into: &issues)
        checkText(state, field: .state, name: "State", into: &issues)
        checkText(assets?.largeText, field: .largeText, name: "Large image text", into: &issues)
        checkText(assets?.smallText, field: .smallText, name: "Small image text", into: &issues)

        if detailsURL != nil, details == nil {
            issues.append(.init(field: .detailsURL, severity: .error, message: "A details link needs details text."))
        }
        if stateURL != nil, state == nil {
            issues.append(.init(field: .stateURL, severity: .error, message: "A state link needs state text."))
        }
        checkLink(detailsURL, field: .detailsURL, name: "Details link", into: &issues)
        checkLink(stateURL, field: .stateURL, name: "State link", into: &issues)
        checkLink(assets?.largeURL, field: .largeURL, name: "Large image link", into: &issues)
        checkLink(assets?.smallURL, field: .smallURL, name: "Small image link", into: &issues)

        checkImage(assets?.largeImage, field: .largeImage, name: "Large image", into: &issues)
        checkImage(assets?.smallImage, field: .smallImage, name: "Small image", into: &issues)

        if let timestamps, let start = timestamps.start, let end = timestamps.end, end <= start {
            issues.append(.init(field: .timestamps, severity: .error, message: "The end time must be after the start time."))
        }

        if let size = party?.size {
            if size.current < 1 || size.max < 1 || size.current > size.max {
                issues.append(.init(field: .party, severity: .error, message: "Party size must be at least 1 of 1, and the current count cannot exceed the maximum."))
            }
        }
        if party?.size != nil, type != .playing {
            issues.append(.init(field: .party, severity: .warning, message: "Discord only shows the party count for the Playing type."))
        }

        if let buttons {
            if buttons.count > 2 {
                issues.append(.init(field: .buttons, severity: .error, message: "Discord allows at most 2 buttons."))
            }
            for (index, button) in buttons.enumerated() {
                if button.label.isEmpty || button.label.count > 32 {
                    issues.append(.init(field: .buttonLabel(index), severity: .error, message: "Button labels must be 1 to 32 characters."))
                }
                if button.url.isEmpty || button.url.count > 512 {
                    issues.append(.init(field: .buttonURL(index), severity: .error, message: "Button links must be 1 to 512 characters."))
                } else if !Self.isWebURL(button.url) {
                    issues.append(.init(field: .buttonURL(index), severity: .error, message: "Button links must start with http:// or https://."))
                }
            }
        }

        if type == .listening || type == .watching {
            let hasStart = timestamps?.start != nil
            let hasEnd = timestamps?.end != nil
            if hasStart != hasEnd {
                issues.append(.init(field: .timestamps, severity: .warning, message: "Discord shows a counter for this. Set both a start and an end time to show a progress bar instead."))
            }
        }

        return issues
    }

    public var hasValidationErrors: Bool {
        validate().contains { $0.severity == .error }
    }

    private func checkText(_ value: String?, field: ActivityField, name: String, into issues: inout [ActivityValidationIssue]) {
        guard let value else { return }
        if value.count < 2 || value.count > 128 {
            issues.append(.init(field: field, severity: .error, message: "\(name) must be 2 to 128 characters."))
        }
    }

    private func checkLink(_ value: String?, field: ActivityField, name: String, into issues: inout [ActivityValidationIssue]) {
        guard let value else { return }
        if value.count > 512 {
            issues.append(.init(field: field, severity: .error, message: "\(name) must be at most 512 characters."))
        } else if !Self.isWebURL(value) {
            issues.append(.init(field: field, severity: .error, message: "\(name) must start with http:// or https://."))
        }
    }

    private func checkImage(_ value: String?, field: ActivityField, name: String, into issues: inout [ActivityValidationIssue]) {
        guard let value else { return }
        if value.count > 256 {
            issues.append(.init(field: field, severity: .error, message: "\(name) must be at most 256 characters."))
        } else if value.contains("://"), !Self.isWebURL(value) {
            issues.append(.init(field: field, severity: .error, message: "\(name) must be an asset key or a link that starts with http:// or https://."))
        }
    }

    private static func isWebURL(_ string: String) -> Bool {
        guard let components = URLComponents(string: string),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host, !host.isEmpty
        else { return false }
        return true
    }
}
