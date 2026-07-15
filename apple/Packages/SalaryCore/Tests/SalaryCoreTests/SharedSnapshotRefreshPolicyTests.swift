import Foundation
import Testing
@testable import SalaryCore

@Suite("Shared snapshot refresh policy")
struct SharedSnapshotRefreshPolicyTests {
    private let policy = SharedSnapshotRefreshPolicy(
        refreshInterval: 15 * 60,
        expirationInterval: 30 * 60
    )

    @Test("Fresh snapshots request a periodic refresh before expiration")
    func freshSnapshot() {
        let generatedAt = Date(timeIntervalSince1970: 1_000)
        let now = generatedAt.addingTimeInterval(5 * 60)

        #expect(policy.freshness(generatedAt: generatedAt, now: now) == .current)
        #expect(policy.nextRefreshDate(generatedAt: generatedAt, now: now) == now.addingTimeInterval(15 * 60))
        #expect(policy.expirationDate(generatedAt: generatedAt) == generatedAt.addingTimeInterval(30 * 60))
    }

    @Test("Refresh advances to the expiration boundary when it is closer")
    func refreshAtExpirationBoundary() {
        let generatedAt = Date(timeIntervalSince1970: 2_000)
        let now = generatedAt.addingTimeInterval(20 * 60)

        #expect(policy.freshness(generatedAt: generatedAt, now: now) == .current)
        #expect(policy.nextRefreshDate(generatedAt: generatedAt, now: now) == generatedAt.addingTimeInterval(30 * 60))
    }

    @Test("Expired snapshots remain visible but retry on the periodic interval")
    func expiredSnapshot() {
        let generatedAt = Date(timeIntervalSince1970: 3_000)
        let now = generatedAt.addingTimeInterval(45 * 60)

        #expect(policy.freshness(generatedAt: generatedAt, now: now) == .expired)
        #expect(policy.nextRefreshDate(generatedAt: generatedAt, now: now) == now.addingTimeInterval(15 * 60))
    }

    @Test("A future timestamp never postpones the periodic refresh")
    func futureTimestamp() {
        let now = Date(timeIntervalSince1970: 4_000)
        let generatedAt = now.addingTimeInterval(60 * 60)

        #expect(policy.freshness(generatedAt: generatedAt, now: now) == .current)
        #expect(policy.nextRefreshDate(generatedAt: generatedAt, now: now) == now.addingTimeInterval(15 * 60))
    }
}
