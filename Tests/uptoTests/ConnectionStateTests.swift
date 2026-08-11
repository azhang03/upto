import Foundation
import Testing
@testable import UptoCore

@Suite struct ConnectionStateTests {
    @Test func guidanceOnlyForFixableStates() {
        #expect(ConnectionState.backoff(attempt: 1, reason: .noSocketFound).userGuidance != nil)
        #expect(ConnectionState.failed(.invalidApplicationID).userGuidance != nil)

        #expect(ConnectionState.idle.userGuidance == nil)
        #expect(ConnectionState.scanning.userGuidance == nil)
        #expect(ConnectionState.ready(user: nil).userGuidance == nil)
        #expect(ConnectionState.backoff(attempt: 1, reason: .connectionLost).userGuidance == nil)
        #expect(ConnectionState.backoff(attempt: 1, reason: .protocolError).userGuidance == nil)
    }
}
