import Foundation

public enum CrossTargetKind: String, CaseIterable, Codable, Hashable, Sendable {
    case app
    case widget
    case activity
    case watch
}

public struct CrossTargetSnapshotFacts: Codable, Equatable, Sendable {
    public let target: CrossTargetKind
    public let snapshotID: String
    public let generatedAt: Date
    public let status: SalaryStatus
    public let todayEarnedMinor: Int64
    public let progressBasisPoints: Int

    public init(
        target: CrossTargetKind,
        snapshotID: String,
        generatedAt: Date,
        status: SalaryStatus,
        todayEarnedMinor: Int64,
        progressBasisPoints: Int
    ) {
        self.target = target
        self.snapshotID = snapshotID
        self.generatedAt = generatedAt
        self.status = status
        self.todayEarnedMinor = todayEarnedMinor
        self.progressBasisPoints = progressBasisPoints
    }
}

public enum CrossTargetConsistencyIssue: Codable, Equatable, Sendable {
    case missingTarget(CrossTargetKind)
    case duplicateTarget(CrossTargetKind)
    case snapshotIdentityMismatch
    case generatedAtMismatch
    case statusMismatch
    case amountMismatch
    case progressMismatch
    case configurationSchemaVersionMismatch
    case holidayDatasetVersionMismatch
}

public struct CrossTargetConsistencyReport: Codable, Equatable, Sendable {
    public let facts: [CrossTargetSnapshotFacts]
    public let snapshotID: String?
    public let lastSynchronizedAt: Date?
    public let configurationSchemaVersion: Int
    public let holidayDatasetVersion: String
    public let issues: [CrossTargetConsistencyIssue]

    public var isConsistent: Bool { issues.isEmpty }
}

public enum CrossTargetSnapshotComparator {
    public static func inspect(
        _ bundle: SharedSnapshotBundle,
        expectedConfigurationSchemaVersion: Int,
        expectedHolidayDatasetVersion: String
    ) -> CrossTargetConsistencyReport {
        compare(
            facts: facts(from: bundle),
            configurationSchemaVersion: bundle.salary.configurationSchemaVersion,
            holidayDatasetVersion: bundle.salary.holidayDatasetVersion,
            expectedConfigurationSchemaVersion: expectedConfigurationSchemaVersion,
            expectedHolidayDatasetVersion: expectedHolidayDatasetVersion
        )
    }

    public static func facts(from bundle: SharedSnapshotBundle) -> [CrossTargetSnapshotFacts] {
        let salary = bundle.salary
        let salaryFacts = salary.value
        return [
            CrossTargetSnapshotFacts(
                target: .app,
                snapshotID: salary.id,
                generatedAt: salary.generatedAt,
                status: salaryFacts.status,
                todayEarnedMinor: salaryFacts.todayEarnedMinor,
                progressBasisPoints: salaryFacts.progressBasisPoints
            ),
            CrossTargetSnapshotFacts(
                target: .widget,
                snapshotID: salary.id,
                generatedAt: salary.generatedAt,
                status: salaryFacts.status,
                todayEarnedMinor: salaryFacts.todayEarnedMinor,
                progressBasisPoints: salaryFacts.progressBasisPoints
            ),
            CrossTargetSnapshotFacts(
                target: .activity,
                snapshotID: bundle.activity.snapshotID,
                generatedAt: bundle.activity.generatedAt,
                status: bundle.activity.status,
                todayEarnedMinor: bundle.activity.todayEarnedMinor,
                progressBasisPoints: bundle.activity.progressBasisPoints
            ),
            CrossTargetSnapshotFacts(
                target: .watch,
                snapshotID: bundle.watch.snapshotID,
                generatedAt: bundle.watch.generatedAt,
                status: bundle.watch.status,
                todayEarnedMinor: bundle.watch.todayEarnedMinor,
                progressBasisPoints: bundle.watch.progressBasisPoints
            ),
        ]
    }

    public static func compare(
        facts: [CrossTargetSnapshotFacts],
        configurationSchemaVersion: Int,
        holidayDatasetVersion: String,
        expectedConfigurationSchemaVersion: Int,
        expectedHolidayDatasetVersion: String
    ) -> CrossTargetConsistencyReport {
        var issues: [CrossTargetConsistencyIssue] = []
        for target in CrossTargetKind.allCases {
            let count = facts.lazy.filter { $0.target == target }.count
            if count == 0 { issues.append(.missingTarget(target)) }
            if count > 1 { issues.append(.duplicateTarget(target)) }
        }

        let identities = Set(facts.map(\.snapshotID))
        let generatedAtValues = Set(facts.map(\.generatedAt))
        let statuses = Set(facts.map(\.status))
        let amounts = Set(facts.map(\.todayEarnedMinor))
        let progressValues = Set(facts.map(\.progressBasisPoints))

        if identities.count != 1 { issues.append(.snapshotIdentityMismatch) }
        if generatedAtValues.count != 1 { issues.append(.generatedAtMismatch) }
        if statuses.count != 1 { issues.append(.statusMismatch) }
        if amounts.count != 1 { issues.append(.amountMismatch) }
        if progressValues.count != 1 { issues.append(.progressMismatch) }
        if configurationSchemaVersion != expectedConfigurationSchemaVersion {
            issues.append(.configurationSchemaVersionMismatch)
        }
        if holidayDatasetVersion != expectedHolidayDatasetVersion {
            issues.append(.holidayDatasetVersionMismatch)
        }

        return CrossTargetConsistencyReport(
            facts: facts,
            snapshotID: identities.count == 1 ? identities.first : nil,
            lastSynchronizedAt: generatedAtValues.count == 1 ? generatedAtValues.first : nil,
            configurationSchemaVersion: configurationSchemaVersion,
            holidayDatasetVersion: holidayDatasetVersion,
            issues: issues
        )
    }
}
