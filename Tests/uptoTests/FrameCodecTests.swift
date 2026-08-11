import Foundation
import Testing
@testable import UptoCore

@Suite struct FrameCodecTests {
    @Test func encodeProducesLittleEndianHeader() {
        let frame = Frame(opcode: .handshake, payload: Data("{\"v\":1}".utf8))
        let encoded = FrameCodec.encode(frame)
        #expect(Array(encoded.prefix(4)) == [0, 0, 0, 0])
        #expect(Array(encoded[4..<8]) == [7, 0, 0, 0])
        #expect(Data(encoded.dropFirst(8)) == frame.payload)
    }

    @Test func decodeSingleFrame() throws {
        var decoder = FrameDecoder()
        let frame = Frame(opcode: .frame, payload: Data("{\"a\":1}".utf8))
        let frames = try decoder.append(FrameCodec.encode(frame))
        #expect(frames == [frame])
    }

    @Test func decodeHeaderSplitAcrossReads() throws {
        var decoder = FrameDecoder()
        let encoded = FrameCodec.encode(Frame(opcode: .ping, payload: Data("{}".utf8)))
        #expect(try decoder.append(Data(encoded.prefix(3))).isEmpty)
        #expect(try decoder.append(Data(encoded[3..<8])).isEmpty)
        let frames = try decoder.append(Data(encoded.dropFirst(8)))
        #expect(frames.count == 1)
        #expect(frames.first?.opcode == .ping)
    }

    @Test func decodeBodySplitAcrossReads() throws {
        var decoder = FrameDecoder()
        let encoded = FrameCodec.encode(Frame(opcode: .frame, payload: Data("{\"long\":\"payload\"}".utf8)))
        #expect(try decoder.append(Data(encoded.prefix(12))).isEmpty)
        let frames = try decoder.append(Data(encoded.dropFirst(12)))
        #expect(frames.count == 1)
    }

    @Test func decodeByteByByte() throws {
        var decoder = FrameDecoder()
        let frame = Frame(opcode: .frame, payload: Data("{\"b\":2}".utf8))
        let encoded = FrameCodec.encode(frame)
        var collected: [Frame] = []
        for byte in encoded {
            collected.append(contentsOf: try decoder.append(Data([byte])))
        }
        #expect(collected == [frame])
    }

    @Test func decodeTwoFramesInOneRead() throws {
        var decoder = FrameDecoder()
        let first = Frame(opcode: .frame, payload: Data("{\"n\":1}".utf8))
        let second = Frame(opcode: .close, payload: Data("{\"n\":2}".utf8))
        var combined = FrameCodec.encode(first)
        combined.append(FrameCodec.encode(second))
        let frames = try decoder.append(combined)
        #expect(frames == [first, second])
    }

    @Test func decodeFramePlusPartialTail() throws {
        var decoder = FrameDecoder()
        let first = Frame(opcode: .frame, payload: Data("{\"n\":1}".utf8))
        let second = Frame(opcode: .frame, payload: Data("{\"n\":2}".utf8))
        var combined = FrameCodec.encode(first)
        combined.append(FrameCodec.encode(second).prefix(10))
        let frames = try decoder.append(combined)
        #expect(frames == [first])
        let rest = try decoder.append(Data(FrameCodec.encode(second).dropFirst(10)))
        #expect(rest == [second])
    }

    @Test func decodeEmptyPayloadFrame() throws {
        var decoder = FrameDecoder()
        let frames = try decoder.append(FrameCodec.encode(Frame(opcode: .pong, payload: Data())))
        #expect(frames == [Frame(opcode: .pong, payload: Data())])
    }

    @Test func unknownOpcodeThrows() {
        var decoder = FrameDecoder()
        var bad = Data()
        withUnsafeBytes(of: UInt32(9).littleEndian) { bad.append(contentsOf: $0) }
        withUnsafeBytes(of: UInt32(0).littleEndian) { bad.append(contentsOf: $0) }
        #expect(throws: FrameDecodingError.unknownOpcode(9)) {
            _ = try decoder.append(bad)
        }
    }

    @Test func oversizedPayloadThrows() {
        var decoder = FrameDecoder()
        var bad = Data()
        withUnsafeBytes(of: UInt32(1).littleEndian) { bad.append(contentsOf: $0) }
        withUnsafeBytes(of: UInt32(FrameDecoder.maxPayloadSize + 1).littleEndian) { bad.append(contentsOf: $0) }
        #expect(throws: FrameDecodingError.oversizedPayload(FrameDecoder.maxPayloadSize + 1)) {
            _ = try decoder.append(bad)
        }
    }
}
