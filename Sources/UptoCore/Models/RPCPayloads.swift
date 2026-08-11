import Foundation

struct HandshakePayload: Encodable {
    let v: Int
    let clientID: String

    enum CodingKeys: String, CodingKey {
        case v
        case clientID = "client_id"
    }
}

struct SetActivityArgs: Encodable {
    let pid: Int32
    let activity: Activity?

    // A clear must omit the activity key entirely, not send null.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pid, forKey: .pid)
        if let activity {
            try container.encode(activity, forKey: .activity)
        }
    }

    enum CodingKeys: String, CodingKey {
        case pid
        case activity
    }
}

struct SetActivityCommand: Encodable {
    let cmd = "SET_ACTIVITY"
    let nonce: String
    let args: SetActivityArgs
}

// First decode pass. The payload shape varies by command and event, so
// the envelope is read alone and the data field is decoded on demand.
struct IncomingEnvelope: Decodable {
    let cmd: String?
    let evt: String?
    let nonce: String?
}

struct ReadyEnvelope: Decodable {
    struct ReadyData: Decodable {
        let v: Int?
        let user: DiscordUser?
    }

    let data: ReadyData?
}

struct ErrorEnvelope: Decodable {
    struct ErrorData: Decodable {
        let code: Int?
        let message: String?
    }

    let data: ErrorData?
}
