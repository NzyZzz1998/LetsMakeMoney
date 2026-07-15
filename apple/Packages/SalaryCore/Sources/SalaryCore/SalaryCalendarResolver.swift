import Foundation

public enum SalaryCalendarDayKind: String, Codable, Equatable, Sendable {
    case manualWorkday
    case manualRestDay
    case officialHoliday
    case adjustedWorkday
    case regularWorkday
    case regularRestDay
}

public struct SalaryCalendarDay: Equatable, Sendable {
    public let dateKey: String
    public let kind: SalaryCalendarDayKind
    public let isWorkday: Bool
    public let isPaid: Bool
    public let effectiveWorkSeconds: Int

    public init(
        dateKey: String,
        kind: SalaryCalendarDayKind,
        isWorkday: Bool,
        isPaid: Bool,
        effectiveWorkSeconds: Int
    ) {
        self.dateKey = dateKey
        self.kind = kind
        self.isWorkday = isWorkday
        self.isPaid = isPaid
        self.effectiveWorkSeconds = effectiveWorkSeconds
    }
}

public enum SalaryCalendarResolver {
    public static func resolve(
        date: Date,
        configuration: AppConfiguration,
        holidays: HolidayCalendar,
        timeZone: TimeZone
    ) throws -> SalaryCalendarDay {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let key = dateKey(date, calendar: calendar)
        if let override = configuration.dateOverrides.first(where: { $0.date == key }) {
            return SalaryCalendarDay(
                dateKey: key,
                kind: override.isWorkday ? .manualWorkday : .manualRestDay,
                isWorkday: override.isWorkday,
                isPaid: override.isPaid,
                effectiveWorkSeconds: override.effectiveWorkSeconds ?? configuration.standardWorkSeconds
            )
        }

        let year = calendar.component(.year, from: date)
        if let official = holidays.officialRule(for: key, year: year) {
            return SalaryCalendarDay(
                dateKey: key,
                kind: official ? .adjustedWorkday : .officialHoliday,
                isWorkday: official,
                isPaid: official,
                effectiveWorkSeconds: configuration.standardWorkSeconds
            )
        }

        let workday = try regularWorkday(
            date: date,
            configuration: configuration,
            calendar: calendar
        )
        return SalaryCalendarDay(
            dateKey: key,
            kind: workday ? .regularWorkday : .regularRestDay,
            isWorkday: workday,
            isPaid: workday,
            effectiveWorkSeconds: configuration.standardWorkSeconds
        )
    }

    private static func regularWorkday(
        date: Date,
        configuration: AppConfiguration,
        calendar: Calendar
    ) throws -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        switch configuration.restMode {
        case .doubleWeekend:
            return (2...6).contains(weekday)
        case .singleWeekend:
            return (2...7).contains(weekday)
        case .alternatingWeekend:
            if (2...6).contains(weekday) { return true }
            if weekday == 1 { return false }
            guard let value = configuration.alternatingAnchor,
                  let anchor = SalaryParsing.date(value, calendar: calendar),
                  let delta = calendar.dateComponents([.day], from: anchor, to: date).day
            else { throw SalaryCoreError.missingAlternatingAnchor }
            return Int(floor(Double(delta) / 7.0)) % 2 != 0
        }
    }

    private static func dateKey(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }
}
