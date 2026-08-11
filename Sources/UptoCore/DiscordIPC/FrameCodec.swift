import Foundation

// Discord frames its IPC messages as a header of two little endian
// 32 bit integers (opcode, payload length) followed by a JSON payload.

public enum IPCOpcode: UInt32, Sendable {
    case handshake = 0
    case frame = 1
    case close = 2
    case ping = 3
    case pong = 4
}

public struct Frame: Sendable, Equatable {
    public var opcode: IPCOpcode
    public var payload: Data

    public init(opcode: IPCOpcode, payload: Data) {
        self.opcode = opcode
        self.payload = payload
    }
}

public enum FrameDecodingError: Error, Equatable {
    case unknownOpcode(UInt32)
    case oversizedPayload(UInt32)
}

public enum FrameCodec {
    public static func encode(_ frame: Frame) -> Data {
        var data = Data(capacity: 8 + frame.payload.count)
        withUnsafeBytes(of: frame.opcode.rawValue.littleEndian) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: UInt32(frame.payload.count).littleEndian) { data.append(contentsOf: $0) }
        data.append(frame.payload)
        return data
    }
}

// Reads from a socket can split one frame across chunks or pack several
// frames into one chunk. The decoder buffers bytes until whole frames
// are available. A nonsense header means the stream is out of sync, and
// the only safe recovery is to drop the connection.
public struct FrameDecoder: Sendable {
    public static let maxPayloadSize: UInt32 = 1 << 20

    private var buffer = Data()

    public init() {}

    public mutating func append(_ bytes: Data) throws -> [Frame] {
        buffer.append(bytes)
        var frames: [Frame] = []
        while buffer.count >= 8 {
            let rawOpcode = buffer.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 0, as: UInt32.self) }.littleEndian
            let length = buffer.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 4, as: UInt32.self) }.littleEndian
            guard let opcode = IPCOpcode(rawValue: rawOpcode) else {
                throw FrameDecodingError.unknownOpcode(rawOpcode)
            }
            guard length <= Self.maxPayloadSize else {
                throw FrameDecodingError.oversizedPayload(length)
            }
            let total = 8 + Int(length)
            guard buffer.count >= total else { break }
            let start = buffer.startIndex
            let payload = Data(buffer[start.advanced(by: 8) ..< start.advanced(by: total)])
            frames.append(Frame(opcode: opcode, payload: payload))
            buffer.removeFirst(total)
        }
        return frames
    }
}
