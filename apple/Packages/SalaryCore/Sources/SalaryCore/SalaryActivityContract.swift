import Foundation

public enum SalaryActivityContract {
    public static let currentSchemaVersion = 1

    static func decodeSchemaVersion<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> Int {
        let version = try container.decodeIfPresent(Int.self, forKey: key) ?? 1
        guard version == currentSchemaVersion else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "Unsupported Live Activity schema version: \(version)"
            )
        }
        return version
    }
}

public enum SalaryActivityPhase: String, Codable, Hashable, Sendable {
    case working
    case lunchBreak
    case finished
    case endedEarly
}

public struct SalaryActivityContentState: Codable, Equatable, Hashable, Sendable {
    public let schemaVersion: Int
    public let snapshotID: String
    public let generatedAt: Date
    public let phase: SalaryActivityPhase
    public let todayEarnedMinor: Int64
    public let progressBasisPoints: Int
    public let nextTransitionAt: Date?

    public init(
        snapshotID: String,
        generatedAt: Date,
        phase: SalaryActivityPhase,
        todayEarnedMinor: Int64,
        progressBasisPoints: Int,
        nextTransitionAt: Date?
    ) {
        self.schemaVersion = SalaryActivityContract.currentSchemaVersion
        self.snapshotID = snapshotID
        self.generatedAt = generatedAt
        self.phase = phase
        self.todayEarnedMinor = todayEarnedMinor
        self.progressBasisPoints = progressBasisPoints
        self.nextTransitionAt = nextTransitionAt
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case snapshotID
        case generatedAt
        case phase
        case todayEarnedMinor
        case progressBasisPoints
        case nextTransitionAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try SalaryActivityContract.decodeSchemaVersion(
            from: container,
            forKey: .schemaVersion
        )
        snapshotID = try container.decode(String.self, forKey: .snapshotID)
        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
        phase = try container.decode(SalaryActivityPhase.self, forKey: .phase)
        todayEarnedMinor = try container.decode(Int64.self, forKey: .todayEarnedMinor)
        progressBasisPoints = try container.decode(Int.self, forKey: .progressBasisPoints)
        nextTransitionAt = try container.decodeIfPresent(Date.self, forKey: .nextTransitionAt)
    }
}

public struct SalaryActivityStaticContext: Codable, Equatable, Hashable, Sendable {
    public let schemaVersion: Int
    public let activityID: String
    public let currencyCode: String
    public let workDate: String
    public let workStartAt: Date
    public let lunchStartAt: Date
    public let lunchEndAt: Date
    public let workEndAt: Date
    public let dailySalaryMinor: Int64
    public let standardWorkSeconds: Int

    public init(
        activityID: String,
        currencyCode: String,
        workDate: String,
        workStartAt: Date,
        lunchStartAt: Date,
        lunchEndAt: Date,
        workEndAt: Date,
        dailySalaryMinor: Int64,
        standardWorkSeconds: Int
    ) {
        self.schemaVersion = SalaryActivityContract.currentSchemaVersion
        self.activityID = activityID
        self.currencyCode = currencyCode
        self.workDate = workDate
        self.workStartAt = workStartAt
        self.lunchStartAt = lunchStartAt
        self.lunchEndAt = lunchEndAt
        self.workEndAt = workEndAt
        self.dailySalaryMinor = dailySalaryMinor
        self.standardWorkSeconds = standardWorkSeconds
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case activityID
        case currencyCode
        case workDate
        case workStartAt
        case lunchStartAt
        case lunchEndAt
        case workEndAt
        case dailySalaryMinor
        case standardWorkSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try SalaryActivityContract.decodeSchemaVersion(
            from: container,
            forKey: .schemaVersion
        )
        activityID = try container.decode(String.self, forKey: .activityID)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        workDate = try container.decode(String.self, forKey: .workDate)
        workStartAt = try container.decode(Date.self, forKey: .workStartAt)
        lunchStartAt = try container.decode(Date.self, forKey: .lunchStartAt)
        lunchEndAt = try container.decode(Date.self, forKey: .lunchEndAt)
        workEndAt = try container.decode(Date.self, forKey: .workEndAt)
        dailySalaryMinor = try container.decode(Int64.self, forKey: .dailySalaryMinor)
        standardWorkSeconds = try container.decode(Int.self, forKey: .standardWorkSeconds)
    }
}
