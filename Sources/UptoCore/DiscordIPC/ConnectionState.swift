import Foundation

// Partial user object from the READY event. Every field is optional on
// purpose. Schema drift on Discord's side must never break the connection.
public struct DiscordUser: Codable, Sendable, Equatable, Hashable {
    public var id: String?
    public var username: String?
    public var globalName: String?

    public init(id: String? = nil, username: String? = nil, globalName: String? = nil) {
        self.id = id
        self.username = username
        self.globalName = globalName
    }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case globalName = "global_name"
    }
}

public enum DisconnectReason: Sendable, Equatable {
    case noSocketFound
    case connectionLost
    case protocolError
}

public enum ConnectionFailure: Sendable, Equatable {
    case invalidApplicationID
}

public enum ConnectionState: Sendable, Equatable {
    case idle
    case scanning
    case ready(user: DiscordUser?)
    case backoff(attempt: Int, reason: DisconnectReason)
    case failed(ConnectionFailure)
}

public enum ClientEvent: Sendable, Equatable {
    case stateChanged(ConnectionState)
    case activityAcknowledged
    case rpcError(code: Int, message: String)
}
