import Foundation
import Testing
@testable import UptoCore

@Suite struct TokenBucketTests {
    @Test func allowsBurstOfCapacityThenDenies() {
        var bucket = TokenBucket(capacity: 5, refillInterval: .seconds(4))
        let now = ContinuousClock().now
        for _ in 0..<5 {
            let granted = bucket.tryConsume(at: now)
            #expect(granted)
        }
        let sixth = bucket.tryConsume(at: now)
        #expect(!sixth)
    }

    @Test func refillsOverTime() {
        var bucket = TokenBucket(capacity: 5, refillInterval: .seconds(4))
        let start = ContinuousClock().now
        for _ in 0..<5 {
            _ = bucket.tryConsume(at: start)
        }
        let early = bucket.tryConsume(at: start.advanced(by: .seconds(3)))
        #expect(!early)
        let refilled = bucket.tryConsume(at: start.advanced(by: .seconds(4)))
        #expect(refilled)
    }

    @Test func nextAvailableIsNowWhenTokensRemain() {
        var bucket = TokenBucket(capacity: 5, refillInterval: .seconds(4))
        let now = ContinuousClock().now
        let next = bucket.nextAvailable(after: now)
        #expect(next == now)
    }

    @Test func nextAvailableAfterExhaustion() {
        var bucket = TokenBucket(capacity: 1, refillInterval: .seconds(4))
        let start = ContinuousClock().now
        _ = bucket.tryConsume(at: start)
        let next = bucket.nextAvailable(after: start)
        let wait = start.duration(to: next)
        #expect(wait > .seconds(3.9) && wait <= .seconds(4))
    }

    @Test func idleNeverExceedsCapacity() {
        var bucket = TokenBucket(capacity: 5, refillInterval: .seconds(4))
        let start = ContinuousClock().now
        _ = bucket.tryConsume(at: start)
        let later = start.advanced(by: .seconds(1000))
        var granted = 0
        while bucket.tryConsume(at: later) {
            granted += 1
        }
        #expect(granted == 5)
    }
}
