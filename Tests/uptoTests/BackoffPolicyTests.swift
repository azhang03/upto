import Foundation
import Testing
@testable import UptoCore

@Suite struct BackoffPolicyTests {
    @Test func doublesFromBaseWithoutJitter() {
        let policy = BackoffPolicy(base: .seconds(1), cap: .seconds(30), jitter: 0)
        #expect(policy.delay(attempt: 0) == .seconds(1))
        #expect(policy.delay(attempt: 1) == .seconds(2))
        #expect(policy.delay(attempt: 2) == .seconds(4))
        #expect(policy.delay(attempt: 4) == .seconds(16))
    }

    @Test func capsAtMaximum() {
        let policy = BackoffPolicy(base: .seconds(1), cap: .seconds(30), jitter: 0)
        #expect(policy.delay(attempt: 5) == .seconds(30))
        #expect(policy.delay(attempt: 50) == .seconds(30))
    }

    @Test func jitterStaysInBounds() {
        let policy = BackoffPolicy(base: .seconds(1), cap: .seconds(30), jitter: 0.2)
        for attempt in 0..<6 {
            let reference = BackoffPolicy(base: .seconds(1), cap: .seconds(30), jitter: 0).delay(attempt: attempt)
            for _ in 0..<20 {
                let delay = policy.delay(attempt: attempt)
                #expect(delay.totalSeconds >= reference.totalSeconds * 0.8 - 0.0001)
                #expect(delay.totalSeconds <= reference.totalSeconds * 1.2 + 0.0001)
            }
        }
    }

    @Test func negativeAttemptClampsToBase() {
        let policy = BackoffPolicy(base: .seconds(1), cap: .seconds(30), jitter: 0)
        #expect(policy.delay(attempt: -3) == .seconds(1))
    }
}
