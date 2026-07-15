import Testing
@testable import SalaryCore

@Suite("Salary calendar presentation rules")
struct SalaryCalendarResolverTests {
    @Test("manual override, official holiday and adjusted workday remain distinguishable")
    func kinds() throws {
        let holidays = try TestSupport.holidayCalendar()
        var configuration = configured()
        configuration.dateOverrides = [
            SalaryDateOverride(date: "2026-10-01", isWorkday: true, isPaid: true)
        ]

        let manual = try SalaryCalendarResolver.resolve(
            date: TestSupport.localDate("2026-10-01T08:00:00"),
            configuration: configuration,
            holidays: holidays,
            timeZone: TestSupport.shanghai
        )
        #expect(manual.kind == .manualWorkday)

        configuration.dateOverrides = []
        let holiday = try SalaryCalendarResolver.resolve(
            date: TestSupport.localDate("2026-10-02T08:00:00"),
            configuration: configuration,
            holidays: holidays,
            timeZone: TestSupport.shanghai
        )
        #expect(holiday.kind == .officialHoliday)

        let adjusted = try SalaryCalendarResolver.resolve(
            date: TestSupport.localDate("2026-10-10T08:00:00"),
            configuration: configuration,
            holidays: holidays,
            timeZone: TestSupport.shanghai
        )
        #expect(adjusted.kind == .adjustedWorkday)
    }

    private func configured() -> AppConfiguration {
        var value = AppConfiguration.defaultValue
        value.monthlySalaryMinor = 1_200_000
        return value
    }
}
