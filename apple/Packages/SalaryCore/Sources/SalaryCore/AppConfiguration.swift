import Foundation

public typealias AppConfiguration = SalaryConfiguration

extension SalaryConfiguration {
    public static var defaultValue: SalaryConfiguration {
        SalaryConfiguration(
            schemaVersion: 1,
            monthlySalaryMinor: 0,
            currencyCode: "CNY",
            restMode: .doubleWeekend,
            alternatingAnchor: nil,
            workStart: "08:00",
            workEnd: "18:00",
            lunchStart: "12:00",
            lunchEnd: "14:00",
            standardWorkSeconds: 28_800,
            dateOverrides: [],
            holidayDatasetVersion: "cn-mainland-2025-2026-v1",
            notificationPreference: .notRequested,
            watchMetric: .remainingTime
        )
    }

    public func validationIssues() -> [ConfigurationValidationIssue] {
        var issues: [ConfigurationValidationIssue] = []
        if schemaVersion != 1 {
            issues.append(.init(field: "schemaVersion", code: "unsupportedSchemaVersion"))
        }
        if !(0...9_000_000_000_000).contains(monthlySalaryMinor) {
            issues.append(.init(field: "monthlySalaryMinor", code: "outOfRange"))
        }
        if currencyCode.count != 3 || !currencyCode.allSatisfy({ $0.isASCII && $0.isUppercase }) {
            issues.append(.init(field: "currencyCode", code: "invalidCurrencyCode"))
        }
        if holidayDatasetVersion.isEmpty {
            issues.append(.init(field: "holidayDatasetVersion", code: "required"))
        }
        if !(1...86_400).contains(standardWorkSeconds) {
            issues.append(.init(field: "standardWorkSeconds", code: "outOfRange"))
        }

        if restMode == .alternatingWeekend {
            guard let alternatingAnchor,
                  let anchor = SalaryParsing.date(alternatingAnchor)
            else {
                issues.append(.init(field: "alternatingAnchor", code: "requiredSaturday"))
                return issues + timeAndOverrideIssues()
            }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = SalaryParsing.utc
            if calendar.component(.weekday, from: anchor) != 7 {
                issues.append(.init(field: "alternatingAnchor", code: "requiredSaturday"))
            }
        } else if let alternatingAnchor, SalaryParsing.date(alternatingAnchor) == nil {
            issues.append(.init(field: "alternatingAnchor", code: "invalidDate"))
        }

        issues.append(contentsOf: timeAndOverrideIssues())
        return issues
    }

    private func timeAndOverrideIssues() -> [ConfigurationValidationIssue] {
        var issues: [ConfigurationValidationIssue] = []
        guard let effectiveSeconds = try? WorkScheduleMetrics.effectiveWorkSeconds(
            workStart: workStart,
            workEnd: workEnd,
            lunchStart: lunchStart,
            lunchEnd: lunchEnd
        ), effectiveSeconds == standardWorkSeconds
        else {
            issues.append(.init(field: "workSchedule", code: "invalidTimeRange"))
            return issues
        }

        var seen = Set<String>()
        for override in dateOverrides {
            if SalaryParsing.date(override.date) == nil {
                issues.append(.init(field: "dateOverrides", code: "invalidDate"))
            }
            if !seen.insert(override.date).inserted {
                issues.append(.init(field: "dateOverrides", code: "duplicateDate"))
            }
            if let seconds = override.effectiveWorkSeconds, !(1...86_400).contains(seconds) {
                issues.append(.init(field: "dateOverrides", code: "invalidEffectiveWorkSeconds"))
            }
        }
        return issues
    }
}

public struct ConfigurationValidationIssue: Codable, Equatable, Sendable {
    public let field: String
    public let code: String

    public init(field: String, code: String) {
        self.field = field
        self.code = code
    }
}

public struct ConfigurationDraft: Equatable, Sendable {
    public private(set) var original: AppConfiguration
    public var value: AppConfiguration

    public init(original: AppConfiguration) {
        self.original = original
        self.value = original
    }

    public var hasChanges: Bool { value != original }

    public mutating func cancel() {
        value = original
    }

    public mutating func acceptSavedValue() {
        original = value
    }
}
