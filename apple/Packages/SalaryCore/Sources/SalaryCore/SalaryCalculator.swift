import Foundation

private struct DayRule {
    let isWorkday: Bool
    let isPaid: Bool
    let effectiveWorkSeconds: Int
}

public enum SalaryCalculator {
    public static func calculate(
        configuration: SalaryConfiguration,
        now: Date,
        timeZone: TimeZone,
        holidays: HolidayCalendar
    ) throws -> SalarySnapshot {
        try configuration.validate()
        guard configuration.holidayDatasetVersion == holidays.version else {
            throw SalaryCoreError.holidayDatasetMismatch
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let nowParts = calendar.dateComponents([.year, .month, .day], from: now)
        guard let year = nowParts.year,
              let month = nowParts.month,
              let day = nowParts.day,
              let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let dayRange = calendar.range(of: .day, in: .month, for: monthStart)
        else { throw SalaryCoreError.invalidConfiguration }

        let overrides = Dictionary(uniqueKeysWithValues: configuration.dateOverrides.map { ($0.date, $0) })
        let monthDates = try dayRange.map { dayNumber -> Date in
            guard let result = calendar.date(from: DateComponents(year: year, month: month, day: dayNumber)) else {
                throw SalaryCoreError.invalidConfiguration
            }
            return result
        }
        let rules = try Dictionary(uniqueKeysWithValues: monthDates.map { item in
            let key = dateKey(item, calendar: calendar)
            return (key, try rule(
                for: item,
                key: key,
                configuration: configuration,
                overrides: overrides,
                holidays: holidays,
                calendar: calendar
            ))
        })
        let paidKeys = monthDates.compactMap { item -> String? in
            let key = dateKey(item, calendar: calendar)
            guard let rule = rules[key], rule.isWorkday, rule.isPaid else { return nil }
            return key
        }
        guard !paidKeys.isEmpty else { throw SalaryCoreError.noPaidWorkdays }

        let daily = rounded(configuration.monthlySalaryMinor, by: Int64(paidKeys.count))
        let hourly = rounded(daily * 3_600, by: Int64(configuration.standardWorkSeconds))
        let todayKey = String(format: "%04d-%02d-%02d", year, month, day)
        guard let todayRule = rules[todayKey] else { throw SalaryCoreError.invalidConfiguration }
        let completion: (seconds: Int, status: SalaryStatus)
        if todayRule.isWorkday {
            completion = completedWork(at: now, configuration: configuration, calendar: calendar)
        } else {
            completion = (0, .restDay)
        }

        let fullToday = todayRule.isWorkday && todayRule.isPaid
            ? rounded(daily * Int64(todayRule.effectiveWorkSeconds), by: Int64(configuration.standardWorkSeconds))
            : 0
        let todayEarned = rounded(
            fullToday * Int64(completion.seconds),
            by: Int64(configuration.standardWorkSeconds)
        )
        var monthEarned: Int64 = 0
        for key in paidKeys where key < todayKey {
            guard let item = rules[key] else { continue }
            monthEarned += rounded(
                daily * Int64(item.effectiveWorkSeconds),
                by: Int64(configuration.standardWorkSeconds)
            )
        }
        monthEarned += todayEarned
        let progress = min(
            10_000,
            Int(rounded(Int64(completion.seconds) * 10_000, by: Int64(configuration.standardWorkSeconds)))
        )
        let warnings: [SalaryWarning] = holidays.coveredYears.contains(year)
            ? []
            : [.holidayDatasetOutOfRange]

        return SalarySnapshot(
            monthPaidWorkdays: paidKeys.count,
            dailySalaryMinor: daily,
            standardHourlySalaryMinor: hourly,
            todayEarnedMinor: todayEarned,
            monthEarnedMinor: monthEarned,
            completedEffectiveSeconds: completion.seconds,
            progressBasisPoints: progress,
            status: completion.status,
            warnings: warnings
        )
    }

    private static func rule(
        for day: Date,
        key: String,
        configuration: SalaryConfiguration,
        overrides: [String: SalaryDateOverride],
        holidays: HolidayCalendar,
        calendar: Calendar
    ) throws -> DayRule {
        if let override = overrides[key] {
            return DayRule(
                isWorkday: override.isWorkday,
                isPaid: override.isPaid,
                effectiveWorkSeconds: override.effectiveWorkSeconds ?? configuration.standardWorkSeconds
            )
        }
        let year = calendar.component(.year, from: day)
        if let official = holidays.officialRule(for: key, year: year) {
            return DayRule(
                isWorkday: official,
                isPaid: official,
                effectiveWorkSeconds: configuration.standardWorkSeconds
            )
        }
        let weekday = calendar.component(.weekday, from: day)
        let workday: Bool
        switch configuration.restMode {
        case .doubleWeekend:
            workday = (2...6).contains(weekday)
        case .singleWeekend:
            workday = (2...7).contains(weekday)
        case .alternatingWeekend:
            if (2...6).contains(weekday) {
                workday = true
            } else if weekday == 1 {
                workday = false
            } else {
                guard let anchorValue = configuration.alternatingAnchor,
                      let anchor = SalaryParsing.date(anchorValue, calendar: calendar),
                      let delta = calendar.dateComponents([.day], from: anchor, to: day).day
                else { throw SalaryCoreError.missingAlternatingAnchor }
                let weekDelta = Int(floor(Double(delta) / 7.0))
                workday = weekDelta % 2 != 0
            }
        }
        return DayRule(
            isWorkday: workday,
            isPaid: workday,
            effectiveWorkSeconds: configuration.standardWorkSeconds
        )
    }

    private static func completedWork(
        at now: Date,
        configuration: SalaryConfiguration,
        calendar: Calendar
    ) -> (seconds: Int, status: SalaryStatus) {
        let parts = calendar.dateComponents([.hour, .minute, .second], from: now)
        let current = ((parts.hour ?? 0) * 3_600) + ((parts.minute ?? 0) * 60) + (parts.second ?? 0)
        let start = SalaryParsing.minutes(configuration.workStart)! * 60
        let end = SalaryParsing.minutes(configuration.workEnd)! * 60
        let lunchStart = SalaryParsing.minutes(configuration.lunchStart)! * 60
        let lunchEnd = SalaryParsing.minutes(configuration.lunchEnd)! * 60
        let morning = lunchStart - start
        if current < start { return (0, .beforeWork) }
        if current < lunchStart { return (current - start, .working) }
        if current < lunchEnd { return (morning, .lunchBreak) }
        if current < end { return (morning + current - lunchEnd, .working) }
        return (configuration.standardWorkSeconds, .finished)
    }

    private static func rounded(_ numerator: Int64, by denominator: Int64) -> Int64 {
        (numerator + denominator / 2) / denominator
    }

    private static func dateKey(_ value: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: value)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }
}
