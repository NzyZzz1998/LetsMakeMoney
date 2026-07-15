import Foundation

enum SalaryParsing {
    static let utc = TimeZone(secondsFromGMT: 0)!

    static func minutes(_ value: String) -> Int? {
        let parts = value.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2,
              parts[0].count == 2,
              parts[1].count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute)
        else { return nil }
        return hour * 60 + minute
    }

    static func date(_ value: String, calendar input: Calendar? = nil) -> Date? {
        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4,
              parts[1].count == 2,
              parts[2].count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else { return nil }
        var calendar = input ?? Calendar(identifier: .gregorian)
        if input == nil { calendar.timeZone = utc }
        let result = calendar.date(from: DateComponents(year: year, month: month, day: day))
        guard let result else { return nil }
        let check = calendar.dateComponents([.year, .month, .day], from: result)
        return check.year == year && check.month == month && check.day == day ? result : nil
    }
}

extension SalaryConfiguration {
    public func validate() throws {
        guard schemaVersion == 1 else { throw SalaryCoreError.unsupportedSchemaVersion }
        guard (0...9_000_000_000_000).contains(monthlySalaryMinor),
              currencyCode.count == 3,
              currencyCode.allSatisfy({ $0.isASCII && $0.isUppercase }),
              !holidayDatasetVersion.isEmpty,
              (1...86_400).contains(standardWorkSeconds)
        else { throw SalaryCoreError.invalidConfiguration }

        if restMode == .alternatingWeekend {
            guard let alternatingAnchor,
                  let anchor = SalaryParsing.date(alternatingAnchor)
            else { throw SalaryCoreError.missingAlternatingAnchor }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = SalaryParsing.utc
            guard calendar.component(.weekday, from: anchor) == 7 else {
                throw SalaryCoreError.missingAlternatingAnchor
            }
        } else if let alternatingAnchor, SalaryParsing.date(alternatingAnchor) == nil {
            throw SalaryCoreError.invalidConfiguration
        }

        guard let start = SalaryParsing.minutes(workStart),
              let end = SalaryParsing.minutes(workEnd),
              let lunchStart = SalaryParsing.minutes(lunchStart),
              let lunchEnd = SalaryParsing.minutes(lunchEnd),
              start < lunchStart,
              lunchStart <= lunchEnd,
              lunchEnd <= end,
              ((lunchStart - start) + (end - lunchEnd)) * 60 == standardWorkSeconds
        else { throw SalaryCoreError.invalidTimeRange }

        var seen = Set<String>()
        for override in dateOverrides {
            guard SalaryParsing.date(override.date) != nil else {
                throw SalaryCoreError.invalidConfiguration
            }
            guard seen.insert(override.date).inserted else {
                throw SalaryCoreError.duplicateDateOverride
            }
            if let seconds = override.effectiveWorkSeconds,
               !(1...86_400).contains(seconds) {
                throw SalaryCoreError.invalidConfiguration
            }
        }
    }
}
