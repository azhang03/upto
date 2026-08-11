import Foundation

public struct BackoffPolicy: Sendable {
    public var base: Duration
    public var cap: Duration
    public var jitter: Double

    public init(base: Duration = .seconds(1), cap: Duration = .seconds(30), jitter: Double = 0.2) {
        self.base = base
        self.cap = cap
        self.jitter = jitter
    }

    public static let `default` = BackoffPolicy()

    public func delay(attempt: Int) -> Duration {
        let exponent = min(max(attempt, 0), 16)
        let raw = base.totalSeconds * pow(2.0, Double(exponent))
        let capped = min(raw, cap.totalSeconds)
        let spread = jitter == 0 ? 0 : Double.random(in: -jitter...jitter)
        return .seconds(capped * (1 + spread))
    }
}

extension Duration {
    var totalSeconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1e18
    }
}
