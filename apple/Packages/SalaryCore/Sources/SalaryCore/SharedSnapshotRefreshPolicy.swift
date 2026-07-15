import Foundation

public enum SharedSnapshotFreshness: Equatable, Sendable {
    case current
    case expired
}

public struct SharedSnapshotRefreshPolicy: Equatable, Sendable {
    public let refreshInterval: TimeInterval
    public let expirationInterval: TimeInterval

    public init(
        refreshInterval: TimeInterval = 15 * 60,
        expirationInterval: TimeInterval = 30 * 60
    ) {
        self.refreshInterval = refreshInterval
        self.expirationInterval = expirationInterval
    }

    public func freshness(generatedAt: Date, now: Date) -> SharedSnapshotFreshness {
        now >= expirationDate(generatedAt: generatedAt) ? .expired : .current
    }

    public func expirationDate(generatedAt: Date) -> Date {
        generatedAt.addingTimeInterval(expirationInterval)
    }

    public func nextRefreshDate(generatedAt: Date, now: Date) -> Date {
        let periodicRefresh = now.addingTimeInterval(refreshInterval)
        let expiration = expirationDate(generatedAt: generatedAt)
        guard expiration > now else { return periodicRefresh }
        return min(periodicRefresh, expiration)
    }
}
