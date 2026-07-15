import Foundation

public enum SalaryActivityLaunchContextError: Error, Equatable, Sendable {
    case invalidSchedule
}

public enum SalaryActivityLaunchContextFactory {
    public static func make(
        configuration: AppConfiguration,
        salary: SalarySnapshot,
        snapshotID: String,
        generatedAt: Date,
        timeZone: TimeZone = .current
    ) throws -> SalaryActivityStaticContext {
        guard let workStart = SalaryParsing.minutes(configuration.workStart),
              let lunchStart = SalaryParsing.minutes(configuration.lunchStart),
              let lunchEnd = SalaryParsing.minutes(configuration.lunchEnd),
              let workEnd = SalaryParsing.minutes(configuration.workEnd)
        else { throw SalaryActivityLaunchContextError.invalidSchedule }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let day = calendar.dateComponents([.year, .month, .day], from: generatedAt)

        guard let workStartAt = date(minutes: workStart, day: day, calendar: calendar),
              let lunchStartAt = date(minutes: lunchStart, day: day, calendar: calendar),
              let lunchEndAt = date(minutes: lunchEnd, day: day, calendar: calendar),
              let workEndAt = date(minutes: workEnd, day: day, calendar: calendar),
              workStartAt <= lunchStartAt,
              lunchStartAt <= lunchEndAt,
              lunchEndAt <= workEndAt
        else { throw SalaryActivityLaunchContextError.invalidSchedule }

        let year = day.year ?? 0
        let month = day.month ?? 0
        let dayOfMonth = day.day ?? 0
        return SalaryActivityStaticContext(
            activityID: snapshotID,
            currencyCode: configuration.currencyCode,
            workDate: String(format: "%04d-%02d-%02d", year, month, dayOfMonth),
            workStartAt: workStartAt,
            lunchStartAt: lunchStartAt,
            lunchEndAt: lunchEndAt,
            workEndAt: workEndAt,
            dailySalaryMinor: salary.dailySalaryMinor,
            standardWorkSeconds: configuration.standardWorkSeconds
        )
    }

    private static func date(
        minutes: Int,
        day: DateComponents,
        calendar: Calendar
    ) -> Date? {
        var components = day
        components.hour = minutes / 60
        components.minute = minutes % 60
        components.second = 0
        return calendar.date(from: components)
    }
}

public enum SalaryActivityManualUnavailableReason: Equatable, Sendable {
    case activitiesDisabled
    case missingLaunchContext
}

public enum SalaryActivityManualDecision: Equatable, Sendable {
    case start
    case stop
    case unavailable(SalaryActivityManualUnavailableReason)
}

public enum SalaryActivityManualAccessPolicy {
    public static func decision(
        notificationPreference: NotificationPreference,
        activitiesEnabled: Bool,
        hasLaunchContext: Bool,
        hasActiveActivity: Bool
    ) -> SalaryActivityManualDecision {
        _ = notificationPreference
        if hasActiveActivity { return .stop }
        guard activitiesEnabled else { return .unavailable(.activitiesDisabled) }
        guard hasLaunchContext else { return .unavailable(.missingLaunchContext) }
        return .start
    }
}

