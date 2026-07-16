import Foundation
import Testing
@testable import SalaryCore

@Suite("Cross-target snapshot consistency")
struct CrossTargetConsistencyTests {
    private let generatedAt = Date(timeIntervalSince1970: 1_721_085_600)

    @Test("One shared bundle produces consistent facts for every target")
    func consistentBundle() throws {
        let bundle = makeBundle()

        let report = CrossTargetSnapshotComparator.inspect(
            bundle,
            expectedConfigurationSchemaVersion: 1,
            expectedHolidayDatasetVersion: "cn-mainland-2025-2026-v1"
        )

        #expect(report.isConsistent)
        #expect(report.issues.isEmpty)
        #expect(report.snapshotID == bundle.salary.id)
        #expect(report.lastSynchronizedAt == generatedAt)
        #expect(Set(report.facts.map(\.target)) == Set(CrossTargetKind.allCases))
    }

    @Test("Target drift and metadata drift remain individually diagnosable")
    func detectsDrift() {
        let bundle = makeBundle()
        var facts = CrossTargetSnapshotComparator.facts(from: bundle)
        facts.removeAll { $0.target == .widget }
        facts = facts.map { fact in
            guard fact.target == .watch else { return fact }
            return CrossTargetSnapshotFacts(
                target: .watch,
                snapshotID: "stale-watch",
                generatedAt: generatedAt.addingTimeInterval(-60),
                status: .lunchBreak,
                todayEarnedMinor: fact.todayEarnedMinor + 1,
                progressBasisPoints: fact.progressBasisPoints + 1
            )
        }

        let report = CrossTargetSnapshotComparator.compare(
            facts: facts,
            configurationSchemaVersion: 0,
            holidayDatasetVersion: "stale-holidays",
            expectedConfigurationSchemaVersion: 1,
            expectedHolidayDatasetVersion: "cn-mainland-2025-2026-v1"
        )

        #expect(!report.isConsistent)
        #expect(report.issues.contains(.missingTarget(.widget)))
        #expect(report.issues.contains(.snapshotIdentityMismatch))
        #expect(report.issues.contains(.generatedAtMismatch))
        #expect(report.issues.contains(.statusMismatch))
        #expect(report.issues.contains(.amountMismatch))
        #expect(report.issues.contains(.progressMismatch))
        #expect(report.issues.contains(.configurationSchemaVersionMismatch))
        #expect(report.issues.contains(.holidayDatasetVersionMismatch))
    }

    private func makeBundle() -> SharedSnapshotBundle {
        let salary = SalarySnapshot(
            monthPaidWorkdays: 23,
            dailySalaryMinor: 43_478,
            standardHourlySalaryMinor: 5_435,
            todayEarnedMinor: 10_870,
            monthEarnedMinor: 315_216,
            completedEffectiveSeconds: 7_200,
            progressBasisPoints: 2_500,
            status: .working,
            warnings: []
        )
        return SharedSnapshotBundle.make(
            configuration: .defaultValue,
            salary: salary,
            generatedAt: generatedAt,
            remainingSeconds: 7_200,
            id: "snapshot-m6"
        )
    }
}
