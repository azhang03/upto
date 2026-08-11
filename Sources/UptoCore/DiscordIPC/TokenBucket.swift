import Foundation

// Discord allows five presence updates per twenty seconds. The bucket
// takes explicit clock instants so tests never have to sleep.
public struct TokenBucket: Sendable {
    public let capacity: Int
    public let refillInterval: Duration

    private var available: Double
    private var lastRefill: ContinuousClock.Instant?

    public init(capacity: Int = 5, refillInterval: Duration = .seconds(4)) {
        self.capacity = capacity
        self.refillInterval = refillInterval
        self.available = Double(capacity)
    }

    public mutating func tryConsume(at now: ContinuousClock.Instant) -> Bool {
        refill(at: now)
        guard available >= 1 else { return false }
        available -= 1
        return true
    }

    public mutating func nextAvailable(after now: ContinuousClock.Instant) -> ContinuousClock.Instant {
        refill(at: now)
        guard available < 1 else { return now }
        let missing = 1 - available
        return now.advanced(by: .seconds(refillInterval.totalSeconds * missing))
    }

    private mutating func refill(at now: ContinuousClock.Instant) {
        guard let last = lastRefill else {
            lastRefill = now
            return
        }
        guard now > last else { return }
        let elapsed = last.duration(to: now).totalSeconds
        available = min(Double(capacity), available + elapsed / refillInterval.totalSeconds)
        lastRefill = now
    }
}
