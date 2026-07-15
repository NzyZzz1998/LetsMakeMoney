import Foundation
import Testing
@testable import SalaryCore

@Suite("Live Activity launch context")
struct SalaryActivityLaunchContextTests {
    private let timeZone = TimeZone(secondsFromGMT: 8 * 3_600)!

    @Test("Shared snapshot carries a deterministic launch context")
    func launchContext() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let generatedAt = try #require(calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 15, hour: 10)
        ))
        let salary = sampleSalarySnapshot()

        let bundle = SharedSnapshotBundle.make(
            configuration: .defaultValue,
            salary: salary,
            generatedAt: generatedAt,
            remainingSeconds: 28_800,
            id: "snapshot-1",
            timeZone: timeZone
        )

        let context = try #require(bundle.activityLaunchContext)
        #expect(context.activityID == "snapshot-1")
        #expect(context.currencyCode == "CNY")
        #expect(context.workDate == "2026-07-15")
        #expect(context.dailySalaryMinor == salary.dailySalaryMinor)
        #expect(context.standardWorkSeconds == 28_800)
        #expect(calendar.component(.hour, from: context.workStartAt) == 8)
        #expect(calendar.component(.hour, from: context.lunchStartAt) == 12)
        #expect(calendar.component(.hour, from: context.lunchEndAt) == 14)
        #expect(calendar.component(.hour, from: context.workEndAt) == 18)
    }

    @Test("Older shared snapshots remain decodable without launch context")
    func legacySnapshot() throws {
        let bundle = SharedSnapshotBundle.make(
            configuration: .defaultValue,
            salary: sampleSalarySnapshot(),
            generatedAt: Date(timeIntervalSince1970: 1_721_085_600),
            remainingSeconds: 0
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        var object = try #require(
            JSONSerialization.jsonObject(with: encoder.encode(bundle)) as? [String: Any]
        )
        object.removeValue(forKey: "activityLaunchContext")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let decoded = try decoder.decode(
            SharedSnapshotBundle.self,
            from: JSONSerialization.data(withJSONObject: object)
        )

        #expect(decoded.activityLaunchContext == nil)
        #expect(decoded.activity == bundle.activity)
    }

    @Test("Invalid schedule does not publish a launch context")
    func invalidSchedule() {
        var configuration = AppConfiguration.defaultValue
        configuration.workStart = "invalid"

        let bundle = SharedSnapshotBundle.make(
            configuration: configuration,
            salary: sampleSalarySnapshot(),
            generatedAt: Date(),
            remainingSeconds: 0
        )

        #expect(bundle.activityLaunchContext == nil)
    }

    private func sampleSalarySnapshot() -> SalarySnapshot {
        SalarySnapshot(
            monthPaidWorkdays: 23,
            dailySalaryMinor: 43_478,
            standardHourlySalaryMinor: 5_435,
            todayEarnedMinor: 10_870,
            monthEarnedMinor: 315_216,
            completedEffectiveSeconds: 7_200,
            progressBasisPoints: 2_500,
            status: .working,
            warnings: []
        )
    }
}
