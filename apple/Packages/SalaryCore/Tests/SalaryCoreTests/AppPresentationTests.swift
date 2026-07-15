import Testing
@testable import SalaryCore

@Suite("App presentation state")
struct AppPresentationTests {
    @Test("missing salary produces an unconfigured state")
    func unconfigured() {
        let state = AppPresentation.build(configuration: .defaultValue, snapshot: nil, failure: nil)
        #expect(state == .unconfigured)
    }

    @Test("calculator failure wins over stale snapshot")
    func error() {
        let state = AppPresentation.build(
            configuration: configured(),
            snapshot: sampleSnapshot(status: .working),
            failure: .holidayDatasetMismatch
        )
        #expect(state == .error(.holidayDatasetMismatch))
    }

    @Test("covered snapshot exposes explicit work and out-of-range states")
    func ready() {
        let normal = AppPresentation.build(
            configuration: configured(),
            snapshot: sampleSnapshot(status: .lunchBreak),
            failure: nil
        )
        #expect(normal == .ready(sampleSnapshot(status: .lunchBreak), isHolidayDataOutOfRange: false))

        let warning = AppPresentation.build(
            configuration: configured(),
            snapshot: sampleSnapshot(status: .restDay, warnings: [.holidayDatasetOutOfRange]),
            failure: nil
        )
        #expect(warning == .ready(
            sampleSnapshot(status: .restDay, warnings: [.holidayDatasetOutOfRange]),
            isHolidayDataOutOfRange: true
        ))
    }

    private func configured() -> AppConfiguration {
        var value = AppConfiguration.defaultValue
        value.monthlySalaryMinor = 1_200_000
        return value
    }

    private func sampleSnapshot(
        status: SalaryStatus,
        warnings: [SalaryWarning] = []
    ) -> SalarySnapshot {
        SalarySnapshot(
            monthPaidWorkdays: 22,
            dailySalaryMinor: 54_545,
            standardHourlySalaryMinor: 6_818,
            todayEarnedMinor: 18_642,
            monthEarnedMinor: 384_200,
            completedEffectiveSeconds: 14_400,
            progressBasisPoints: 5_000,
            status: status,
            warnings: warnings
        )
    }
}
