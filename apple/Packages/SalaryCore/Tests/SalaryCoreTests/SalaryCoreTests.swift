import Foundation
import Testing
@testable import SalaryCore

private let baseline = SalaryConfiguration(
    schemaVersion: 1,
    monthlySalaryMinor: 1_000_000,
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

@Suite("SalaryCore rules")
struct SalaryCoreTests {
    @Test("Core errors expose stable localization keys instead of embedded copy")
    func stableLocalizationKeys() {
        #expect(SalaryCoreError.unsupportedSchemaVersion.localizationKey == "salary.error.unsupported_schema")
        #expect(SalaryCoreError.invalidConfiguration.localizationKey == "salary.error.invalid_configuration")
        #expect(SalaryCoreError.missingAlternatingAnchor.localizationKey == "salary.error.missing_alternating_anchor")
        #expect(SalaryCoreError.invalidTimeRange.localizationKey == "salary.error.invalid_time_range")
        #expect(SalaryCoreError.duplicateDateOverride.localizationKey == "salary.error.duplicate_date_override")
        #expect(SalaryCoreError.noPaidWorkdays.localizationKey == "salary.error.no_paid_workdays")
        #expect(SalaryCoreError.holidayDatasetMismatch.localizationKey == "salary.error.holiday_dataset_mismatch")
    }

    @Test("Morning progress uses only effective work seconds")
    func workingMorning() throws {
        let calendar = try TestSupport.holidayCalendar()
        let snapshot = try SalaryCalculator.calculate(
            configuration: baseline,
            now: TestSupport.localDate("2026-07-14T10:00:00"),
            timeZone: TestSupport.shanghai,
            holidays: calendar
        )
        #expect(snapshot.todayEarnedMinor == 10_870)
        #expect(snapshot.progressBasisPoints == 2_500)
        #expect(snapshot.status == .working)
    }

    @Test("Lunch freezes earnings")
    func lunchBreak() throws {
        let snapshot = try SalaryCalculator.calculate(
            configuration: baseline,
            now: TestSupport.localDate("2026-07-14T13:00:00"),
            timeZone: TestSupport.shanghai,
            holidays: try TestSupport.holidayCalendar()
        )
        #expect(snapshot.completedEffectiveSeconds == 14_400)
        #expect(snapshot.todayEarnedMinor == 21_739)
        #expect(snapshot.status == .lunchBreak)
    }

    @Test("Manual override wins over an official holiday")
    func manualOverridePriority() throws {
        var config = baseline
        config.dateOverrides = [
            SalaryDateOverride(date: "2026-10-02", isWorkday: true, isPaid: true)
        ]
        let snapshot = try SalaryCalculator.calculate(
            configuration: config,
            now: TestSupport.localDate("2026-10-02T10:00:00"),
            timeZone: TestSupport.shanghai,
            holidays: try TestSupport.holidayCalendar()
        )
        #expect(snapshot.status == .working)
        #expect(snapshot.monthPaidWorkdays == 19)
    }

    @Test("Alternating weekends require a Saturday anchor")
    func missingAlternatingAnchor() {
        var config = baseline
        config.restMode = .alternatingWeekend
        #expect(throws: SalaryCoreError.missingAlternatingAnchor) {
            try config.validate()
        }
    }

    @Test("Invalid lunch range is rejected")
    func invalidLunch() {
        var config = baseline
        config.lunchStart = "19:00"
        #expect(throws: SalaryCoreError.invalidTimeRange) {
            try config.validate()
        }
    }

    @Test("Duplicate overrides are rejected")
    func duplicateOverride() {
        var config = baseline
        let item = SalaryDateOverride(date: "2026-07-14", isWorkday: true, isPaid: true)
        config.dateOverrides = [item, item]
        #expect(throws: SalaryCoreError.duplicateDateOverride) {
            try config.validate()
        }
    }
}
