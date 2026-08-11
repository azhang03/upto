import Foundation

public enum TransportEvent: Sendable {
    case bytes(Data)
    case closed(Error?)
}

public protocol IPCTransportConnection: Sendable {
    var events: AsyncStream<TransportEvent> { get }
    func send(_ data: Data) async throws
    func close()
}

public protocol IPCTransportFactory: Sendable {
    func connect(to path: String) async throws -> any IPCTransportConnection
}

public protocol SocketLocator: Sendable {
    func candidatePaths() -> [String]
}
