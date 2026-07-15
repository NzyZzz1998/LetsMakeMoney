import Foundation

public struct SalaryAmountDraft: Equatable, Sendable {
    public private(set) var text: String

    public init(minorUnits: Int64) {
        text = Self.format(minorUnits: minorUnits)
    }

    public mutating func beginEditing() {
        if minorUnits == 0 {
            text = ""
        }
    }

    public mutating func updateText(_ value: String) {
        text = value
    }

    public var minorUnits: Int64? {
        guard !text.isEmpty else { return nil }
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2,
              let wholeText = parts.first,
              !wholeText.isEmpty,
              wholeText.allSatisfy(\.isNumber),
              let whole = Int64(wholeText)
        else { return nil }

        let fractionText = parts.count == 2 ? String(parts[1]) : ""
        guard fractionText.count <= 2,
              fractionText.allSatisfy(\.isNumber)
        else { return nil }

        let fraction: Int64
        switch fractionText.count {
        case 0: fraction = 0
        case 1: fraction = Int64(fractionText)! * 10
        default: fraction = Int64(fractionText)!
        }

        let (scaledWhole, multipliedOverflow) = whole.multipliedReportingOverflow(by: 100)
        let (result, addedOverflow) = scaledWhole.addingReportingOverflow(fraction)
        guard !multipliedOverflow,
              !addedOverflow,
              result <= 9_000_000_000_000
        else { return nil }
        return result
    }

    public var normalizedText: String? {
        minorUnits.map(Self.format(minorUnits:))
    }

    private static func format(minorUnits: Int64) -> String {
        let whole = minorUnits / 100
        let fraction = minorUnits % 100
        return "\(whole).\(String(format: "%02lld", fraction))"
    }
}

public enum AlternatingWeekSelection: String, CaseIterable, Sendable {
    case bigWeek
    case smallWeek
}

public enum AlternatingWeekResolver {
    public static func anchor(
        for selection: AlternatingWeekSelection,
        containing date: Date,
        calendar input: Calendar = .current
    ) throws -> String {
        let calendar = input
        let saturday = try currentSaturday(containing: date, calendar: calendar)
        let anchor: Date
        switch selection {
        case .smallWeek:
            anchor = saturday
        case .bigWeek:
            guard let nextSaturday = calendar.date(byAdding: .day, value: 7, to: saturday) else {
                throw SalaryCoreError.invalidConfiguration
            }
            anchor = nextSaturday
        }
        return dateString(anchor, calendar: calendar)
    }

    public static func selection(
        forAnchor anchor: String,
        containing date: Date,
        calendar input: Calendar = .current
    ) -> AlternatingWeekSelection? {
        let calendar = input
        guard let anchorDate = SalaryParsing.date(anchor, calendar: calendar),
              calendar.component(.weekday, from: anchorDate) == 7,
              let saturday = try? currentSaturday(containing: date, calendar: calendar)
        else { return nil }

        let days = calendar.dateComponents([.day], from: saturday, to: anchorDate).day ?? 0
        guard days.isMultiple(of: 7) else { return nil }
        return (days / 7).isMultiple(of: 2) ? .smallWeek : .bigWeek
    }

    private static func currentSaturday(containing date: Date, calendar: Calendar) throws -> Date {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else {
            throw SalaryCoreError.invalidConfiguration
        }
        let daysFromWeekStart = (7 - calendar.firstWeekday + 7) % 7
        guard let saturday = calendar.date(byAdding: .day, value: daysFromWeekStart, to: week.start) else {
            throw SalaryCoreError.invalidConfiguration
        }
        return calendar.startOfDay(for: saturday)
    }

    private static func dateString(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }
}

public struct WorkScheduleDraft: Equatable, Sendable {
    public private(set) var workStart: String
    public private(set) var workEnd: String
    public private(set) var lunchStart: String
    public private(set) var lunchEnd: String
    public private(set) var effectiveWorkSeconds: Int

    public var lunchDurationMinutes: Int {
        (SalaryParsing.minutes(lunchEnd) ?? 0) - (SalaryParsing.minutes(lunchStart) ?? 0)
    }

    public static func inferred(
        workStart: String = "08:00",
        lunchStart: String = "12:00",
        lunchDurationMinutes: Int = 120,
        effectiveWorkMinutes: Int = 480
    ) throws -> WorkScheduleDraft {
        guard lunchDurationMinutes >= 0,
              lunchDurationMinutes <= 180,
              lunchDurationMinutes.isMultiple(of: 30),
              effectiveWorkMinutes > 0,
              let start = SalaryParsing.minutes(workStart),
              let lunch = SalaryParsing.minutes(lunchStart)
        else { throw SalaryCoreError.invalidTimeRange }

        let lunchEnd = lunch + lunchDurationMinutes
        let workEnd = start + effectiveWorkMinutes + lunchDurationMinutes
        guard lunchEnd < 1_440, workEnd < 1_440 else {
            throw SalaryCoreError.invalidTimeRange
        }
        return try WorkScheduleDraft(
            workStart: workStart,
            workEnd: format(minutes: workEnd),
            lunchStart: lunchStart,
            lunchEnd: format(minutes: lunchEnd)
        )
    }

    public init(workStart: String, workEnd: String, lunchStart: String, lunchEnd: String) throws {
        self.workStart = workStart
        self.workEnd = workEnd
        self.lunchStart = lunchStart
        self.lunchEnd = lunchEnd
        effectiveWorkSeconds = try WorkScheduleMetrics.effectiveWorkSeconds(
            workStart: workStart,
            workEnd: workEnd,
            lunchStart: lunchStart,
            lunchEnd: lunchEnd
        )
    }

    public mutating func setLunchStart(_ value: String) throws {
        guard let start = SalaryParsing.minutes(value) else {
            throw SalaryCoreError.invalidTimeRange
        }
        let candidate = try WorkScheduleDraft(
            workStart: workStart,
            workEnd: workEnd,
            lunchStart: value,
            lunchEnd: Self.format(minutes: start + lunchDurationMinutes)
        )
        self = candidate
    }

    public mutating func setLunchEnd(_ value: String) throws {
        guard let end = SalaryParsing.minutes(value), end >= lunchDurationMinutes else {
            throw SalaryCoreError.invalidTimeRange
        }
        let candidate = try WorkScheduleDraft(
            workStart: workStart,
            workEnd: workEnd,
            lunchStart: Self.format(minutes: end - lunchDurationMinutes),
            lunchEnd: value
        )
        self = candidate
    }

    public mutating func setLunchDuration(minutes: Int) throws {
        guard minutes >= 0,
              minutes <= 180,
              minutes.isMultiple(of: 30),
              let start = SalaryParsing.minutes(workStart),
              let lunch = SalaryParsing.minutes(lunchStart)
        else { throw SalaryCoreError.invalidTimeRange }

        let workEndMinutes = start + effectiveWorkSeconds / 60 + minutes
        let lunchEndMinutes = lunch + minutes
        guard workEndMinutes < 1_440, lunchEndMinutes < 1_440 else {
            throw SalaryCoreError.invalidTimeRange
        }
        let candidate = try WorkScheduleDraft(
            workStart: workStart,
            workEnd: Self.format(minutes: workEndMinutes),
            lunchStart: lunchStart,
            lunchEnd: Self.format(minutes: lunchEndMinutes)
        )
        self = candidate
    }

    public mutating func setWorkStart(_ value: String) throws {
        let candidate = try WorkScheduleDraft(
            workStart: value,
            workEnd: workEnd,
            lunchStart: lunchStart,
            lunchEnd: lunchEnd
        )
        self = candidate
    }

    public mutating func setInferredWorkStart(
        _ value: String,
        effectiveWorkMinutes: Int = 480
    ) throws {
        guard effectiveWorkMinutes > 0,
              let start = SalaryParsing.minutes(value),
              let lunch = SalaryParsing.minutes(lunchStart)
        else { throw SalaryCoreError.invalidTimeRange }

        let workEndMinutes = start + effectiveWorkMinutes + lunchDurationMinutes
        guard start <= lunch, workEndMinutes < 1_440 else {
            throw SalaryCoreError.invalidTimeRange
        }
        let candidate = try WorkScheduleDraft(
            workStart: value,
            workEnd: Self.format(minutes: workEndMinutes),
            lunchStart: lunchStart,
            lunchEnd: lunchEnd
        )
        self = candidate
    }

    public mutating func setWorkEnd(_ value: String) throws {
        let candidate = try WorkScheduleDraft(
            workStart: workStart,
            workEnd: value,
            lunchStart: lunchStart,
            lunchEnd: lunchEnd
        )
        self = candidate
    }

    private static func format(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}
