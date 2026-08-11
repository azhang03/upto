import Foundation

// The activity types Discord accepts over SET_ACTIVITY. Streaming (1)
// and Custom (4) are rejected by the RPC layer, so they are absent here.
public enum ActivityType: Int, Codable, Sendable, CaseIterable {
    case playing = 0
    case listening = 2
    case watching = 3
    case competing = 5
}

// Controls which field shows as the status text in the member list.
public enum StatusDisplayType: Int, Codable, Sendable, CaseIterable {
    case name = 0
    case state = 1
    case details = 2
}

public struct Timestamps: Codable, Sendable, Equatable, Hashable {
    // Unix milliseconds.
    public var start: Int64?
    public var end: Int64?

    public init(start: Int64? = nil, end: Int64? = nil) {
        self.start = start
        self.end = end
    }
}

public struct Assets: Codable, Sendable, Equatable, Hashable {
    // Image fields take an uploaded asset key or a plain https URL.
    public var largeImage: String?
    public var largeText: String?
    public var largeURL: String?
    public var smallImage: String?
    public var smallText: String?
    public var smallURL: String?

    public init(
        largeImage: String? = nil, largeText: String? = nil, largeURL: String? = nil,
        smallImage: String? = nil, smallText: String? = nil, smallURL: String? = nil
    ) {
        self.largeImage = largeImage
        self.largeText = largeText
        self.largeURL = largeURL
        self.smallImage = smallImage
        self.smallText = smallText
        self.smallURL = smallURL
    }

    enum CodingKeys: String, CodingKey {
        case largeImage = "large_image"
        case largeText = "large_text"
        case largeURL = "large_url"
        case smallImage = "small_image"
        case smallText = "small_text"
        case smallURL = "small_url"
    }

    var isEmpty: Bool {
        largeImage == nil && largeText == nil && largeURL == nil
            && smallImage == nil && smallText == nil && smallURL == nil
    }
}

// Discord renders the party size as "(current of max)".
// The wire format is a two element array.
public struct PartySize: Codable, Sendable, Equatable, Hashable {
    public var current: Int
    public var max: Int

    public init(current: Int, max: Int) {
        self.current = current
        self.max = max
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        current = try container.decode(Int.self)
        max = try container.decode(Int.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(current)
        try container.encode(max)
    }
}

public struct Party: Codable, Sendable, Equatable, Hashable {
    public var id: String?
    public var size: PartySize?

    public init(id: String? = nil, size: PartySize? = nil) {
        self.id = id
        self.size = size
    }

    var isEmpty: Bool { id == nil && size == nil }
}

public struct ActivityButton: Codable, Sendable, Equatable, Hashable {
    public var label: String
    public var url: String

    public init(label: String, url: String) {
        self.label = label
        self.url = url
    }
}

public struct Activity: Codable, Sendable, Equatable, Hashable {
    public var type: ActivityType
    // Overrides the application name Discord displays. Not in the
    // official RPC docs, but the desktop client honors it.
    public var name: String?
    public var details: String?
    public var detailsURL: String?
    public var state: String?
    public var stateURL: String?
    public var statusDisplayType: StatusDisplayType?
    public var timestamps: Timestamps?
    public var assets: Assets?
    public var party: Party?
    public var buttons: [ActivityButton]?
    public var instance: Bool?

    public init(
        type: ActivityType = .playing,
        name: String? = nil,
        details: String? = nil, detailsURL: String? = nil,
        state: String? = nil, stateURL: String? = nil,
        statusDisplayType: StatusDisplayType? = nil,
        timestamps: Timestamps? = nil,
        assets: Assets? = nil,
        party: Party? = nil,
        buttons: [ActivityButton]? = nil,
        instance: Bool? = nil
    ) {
        self.type = type
        self.name = name
        self.details = details
        self.detailsURL = detailsURL
        self.state = state
        self.stateURL = stateURL
        self.statusDisplayType = statusDisplayType
        self.timestamps = timestamps
        self.assets = assets
        self.party = party
        self.buttons = buttons
        self.instance = instance
    }

    enum CodingKeys: String, CodingKey {
        case type
        case name
        case details
        case detailsURL = "details_url"
        case state
        case stateURL = "state_url"
        case statusDisplayType = "status_display_type"
        case timestamps
        case assets
        case party
        case buttons
        case instance
    }

    // Trims whitespace and drops empty values so they are omitted from
    // the JSON instead of being sent as empty strings, which Discord
    // rejects. Empty containers collapse to nil.
    public func normalized() -> Activity {
        var copy = self
        copy.name = Self.cleaned(name)
        copy.details = Self.cleaned(details)
        copy.detailsURL = Self.cleaned(detailsURL)
        copy.state = Self.cleaned(state)
        copy.stateURL = Self.cleaned(stateURL)

        if var assets = copy.assets {
            assets.largeImage = Self.cleaned(assets.largeImage)
            assets.largeText = Self.cleaned(assets.largeText)
            assets.largeURL = Self.cleaned(assets.largeURL)
            assets.smallImage = Self.cleaned(assets.smallImage)
            assets.smallText = Self.cleaned(assets.smallText)
            assets.smallURL = Self.cleaned(assets.smallURL)
            copy.assets = assets.isEmpty ? nil : assets
        }

        if var party = copy.party {
            party.id = Self.cleaned(party.id)
            copy.party = party.isEmpty ? nil : party
        }

        if let timestamps = copy.timestamps, timestamps.start == nil, timestamps.end == nil {
            copy.timestamps = nil
        }

        if let buttons = copy.buttons {
            let kept = buttons
                .map { ActivityButton(label: Self.cleaned($0.label) ?? "", url: Self.cleaned($0.url) ?? "") }
                .filter { !$0.label.isEmpty || !$0.url.isEmpty }
            copy.buttons = kept.isEmpty ? nil : kept
        }

        return copy
    }

    private static func cleaned(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
