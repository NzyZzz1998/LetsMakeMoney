import Foundation

public enum RestMode: String, Codable, Sendable {
    case doubleWeekend
    case singleWeekend
    case alternatingWeekend
}

public enum NotificationPreference: String, Codable, Sendable {
    case notRequested
    case allowed
    case denied
}

public enum WatchMetric: String, Codable, Sendable {
    case remainingTime
    case todayIncome
    case progress
}

public enum SalaryStatus: String, Codable, Sendable {
    case beforeWork
    case working
    case lunchBreak
    case finished
    case restDay
}

public enum SalaryWarning: String, Codable, Sendable {
    case holidayDatasetOutOfRange
}

public struct SalaryDateOverride: Codable, Equatable, Sendable {
    public var date: String
    public var isWorkday: Bool
    public var isPaid: Bool
    public var effectiveWorkSeconds: Int?

    public init(
        date: String,
        isWorkday: Bool,
        isPaid: Bool,
        effectiveWorkSeconds: Int? = nil
    ) {
        self.date = date
        self.isWorkday = isWorkday
        self.isPaid = isPaid
        self.effectiveWorkSeconds = effectiveWorkSeconds
    }
}

public struct SalaryConfiguration: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var monthlySalaryMinor: Int64
    public var currencyCode: String
    public var restMode: RestMode
    public var alternatingAnchor: String?
    public var workStart: String
    public var workEnd: String
    public var lunchStart: String
    public var lunchEnd: String
    public var standardWorkSeconds: Int
    public var dateOverrides: [SalaryDateOverride]
    public var holidayDatasetVersion: String
    public var notificationPreference: NotificationPreference
    public var watchMetric: WatchMetric

    public init(
        schemaVersion: Int,
        monthlySalaryMinor: Int64,
        currencyCode: String,
        restMode: RestMode,
        alternatingAnchor: String? = nil,
        workStart: String,
        workEnd: String,
        lunchStart: String,
        lunchEnd: String,
        standardWorkSeconds: Int,
        dateOverrides: [SalaryDateOverride],
        holidayDatasetVersion: String,
        notificationPreference: NotificationPreference,
        watchMetric: WatchMetric
    ) {
        self.schemaVersion = schemaVersion
        self.monthlySalaryMinor = monthlySalaryMinor
        self.currencyCode = currencyCode
        self.restMode = restMode
        self.alternatingAnchor = alternatingAnchor
        self.workStart = workStart
        self.workEnd = workEnd
        self.lunchStart = lunchStart
        self.lunchEnd = lunchEnd
        self.standardWorkSeconds = standardWorkSeconds
        self.dateOverrides = dateOverrides
        self.holidayDatasetVersion = holidayDatasetVersion
        self.notificationPreference = notificationPreference
        self.watchMetric = watchMetric
    }
}

public struct SalarySnapshot: Codable, Equatable, Sendable {
    public let monthPaidWorkdays: Int
    public let dailySalaryMinor: Int64
    public let standardHourlySalaryMinor: Int64
    public let todayEarnedMinor: Int64
    public let monthEarnedMinor: Int64
    public let completedEffectiveSeconds: Int
    public let progressBasisPoints: Int
    public let status: SalaryStatus
    public let warnings: [SalaryWarning]

    public init(
        monthPaidWorkdays: Int,
        dailySalaryMinor: Int64,
        standardHourlySalaryMinor: Int64,
        todayEarnedMinor: Int64,
        monthEarnedMinor: Int64,
        completedEffectiveSeconds: Int,
        progressBasisPoints: Int,
        status: SalaryStatus,
        warnings: [SalaryWarning]
    ) {
        self.monthPaidWorkdays = monthPaidWorkdays
        self.dailySalaryMinor = dailySalaryMinor
        self.standardHourlySalaryMinor = standardHourlySalaryMinor
        self.todayEarnedMinor = todayEarnedMinor
        self.monthEarnedMinor = monthEarnedMinor
        self.completedEffectiveSeconds = completedEffectiveSeconds
        self.progressBasisPoints = progressBasisPoints
        self.status = status
        self.warnings = warnings
    }
}
