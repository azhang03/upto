import Foundation
import Dispatch

public struct UnixSocketTransportFactory: IPCTransportFactory {
    public init() {}

    public func connect(to path: String) async throws -> any IPCTransportConnection {
        try await UnixSocketTransport.connect(to: path)
    }
}

public enum SocketError: Error, Equatable {
    case pathTooLong
    case socketCreationFailed(errno: Int32)
    case connectFailed(errno: Int32)
    case writeFailed(errno: Int32)
    case connectionClosed
}

// Thread safety: every mutable property is touched only on `queue`.
// The Sendable conformance is unchecked because the compiler cannot see
// that invariant. Keep it that way when changing this file.
final class UnixSocketTransport: IPCTransportConnection, @unchecked Sendable {
    let events: AsyncStream<TransportEvent>

    private let fd: Int32
    private let queue: DispatchQueue
    private let readSource: DispatchSourceRead
    private let eventContinuation: AsyncStream<TransportEvent>.Continuation

    private var writeSource: DispatchSourceWrite?
    private var outbound = Data()
    private var pendingWrites: [CheckedContinuation<Void, Error>] = []
    private var isClosed = false

    static func connect(to path: String) async throws -> UnixSocketTransport {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let fd = try openSocket(path: path)
                    continuation.resume(returning: UnixSocketTransport(fd: fd))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // Connecting to a Unix socket either succeeds or fails immediately,
    // so a plain blocking connect off the main thread is enough. The fd
    // switches to non blocking mode afterwards for the read loop.
    private static func openSocket(path: String) throws -> Int32 {
        guard path.utf8.count <= DiscordSocketLocator.maxPathLength else {
            throw SocketError.pathTooLong
        }

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            throw SocketError.socketCreationFailed(errno: errno)
        }

        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = Array(path.utf8)
        withUnsafeMutableBytes(of: &address.sun_path) { raw in
            raw.copyBytes(from: pathBytes)
        }

        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                Darwin.connect(fd, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard result == 0 else {
            let savedErrno = errno
            Darwin.close(fd)
            throw SocketError.connectFailed(errno: savedErrno)
        }

        var noSigpipe: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &noSigpipe, socklen_t(MemoryLayout<Int32>.size))
        let flags = fcntl(fd, F_GETFL, 0)
        _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)

        return fd
    }

    private init(fd: Int32) {
        self.fd = fd
        self.queue = DispatchQueue(label: "upto.ipc.socket")

        var continuation: AsyncStream<TransportEvent>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.eventContinuation = continuation

        self.readSource = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        readSource.setEventHandler { [weak self] in
            self?.drainReadable()
        }
        readSource.setCancelHandler {
            Darwin.close(fd)
        }
        readSource.resume()
    }

    func send(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                guard !self.isClosed else {
                    continuation.resume(throwing: SocketError.connectionClosed)
                    return
                }
                self.outbound.append(data)
                self.pendingWrites.append(continuation)
                self.drainWritable()
            }
        }
    }

    func close() {
        queue.async {
            self.tearDown(error: nil)
        }
    }

    // Runs on `queue`.
    private func drainReadable() {
        guard !isClosed else { return }
        var chunk = [UInt8](repeating: 0, count: 65536)
        while true {
            let count = read(fd, &chunk, chunk.count)
            if count > 0 {
                eventContinuation.yield(.bytes(Data(chunk[0..<count])))
                continue
            }
            if count == 0 {
                tearDown(error: nil)
                return
            }
            if errno == EAGAIN || errno == EWOULDBLOCK {
                return
            }
            if errno == EINTR {
                continue
            }
            tearDown(error: SocketError.connectionClosed)
            return
        }
    }

    // Runs on `queue`.
    private func drainWritable() {
        guard !isClosed else { return }
        while !outbound.isEmpty {
            let written = outbound.withUnsafeBytes { raw in
                write(fd, raw.baseAddress, raw.count)
            }
            if written > 0 {
                outbound.removeFirst(written)
                continue
            }
            if errno == EAGAIN || errno == EWOULDBLOCK {
                armWriteSource()
                return
            }
            if errno == EINTR {
                continue
            }
            failPendingWrites(SocketError.writeFailed(errno: errno))
            tearDown(error: SocketError.writeFailed(errno: errno))
            return
        }
        writeSource?.cancel()
        writeSource = nil
        let waiters = pendingWrites
        pendingWrites = []
        for waiter in waiters {
            waiter.resume()
        }
    }

    // Runs on `queue`.
    private func armWriteSource() {
        guard writeSource == nil else { return }
        let source = DispatchSource.makeWriteSource(fileDescriptor: fd, queue: queue)
        source.setEventHandler { [weak self] in
            self?.drainWritable()
        }
        source.resume()
        writeSource = source
    }

    // Runs on `queue`.
    private func failPendingWrites(_ error: Error) {
        let waiters = pendingWrites
        pendingWrites = []
        for waiter in waiters {
            waiter.resume(throwing: error)
        }
    }

    // Runs on `queue`. The read source's cancel handler closes the fd
    // after both sources are done with it.
    private func tearDown(error: Error?) {
        guard !isClosed else { return }
        isClosed = true
        failPendingWrites(error ?? SocketError.connectionClosed)
        writeSource?.cancel()
        writeSource = nil
        readSource.cancel()
        eventContinuation.yield(.closed(error))
        eventContinuation.finish()
    }
}
