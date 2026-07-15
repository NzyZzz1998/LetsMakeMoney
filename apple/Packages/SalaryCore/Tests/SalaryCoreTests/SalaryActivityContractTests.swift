import Foundation
import Testing
@testable import SalaryCore

@Suite("Live Activity data contract")
struct SalaryActivityContractTests {
    @Test("Content state round-trips with the current schema")
    func currentContentStateRoundTrip() throws {
        let state = SalaryActivityContentState(
            snapshotID: "snapshot-1",
            generatedAt: Date(timeIntervalSince1970: 1_721_085_600),
            phase: .working,
            todayEarnedMinor: 18_642,
            progressBasisPoints: 5_600,
            nextTransitionAt: Date(timeIntervalSince1970: 1_721_089_200)
        )

        let decoded = try JSONDecoder().decode(
            SalaryActivityContentState.self,
            from: JSONEncoder().encode(state)
        )

        #expect(decoded == state)
        #expect(decoded.schemaVersion == SalaryActivityContract.currentSchemaVersion)
    }

    @Test("Legacy content state without a schema version decodes as version one")
    func legacyContentStateDefaultsToVersionOne() throws {
        let data = Data(
            #"{"snapshotID":"legacy","generatedAt":0,"phase":"lunchBreak","todayEarnedMinor":0,"progressBasisPoints":5000}"#.utf8
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let decoded = try decoder.decode(SalaryActivityContentState.self, from: data)

        #expect(decoded.schemaVersion == 1)
        #expect(decoded.phase == .lunchBreak)
        #expect(decoded.nextTransitionAt == nil)
    }

    @Test("Future content state schema fails explicitly")
    func futureContentStateFails() throws {
        let data = Data(
            #"{"schemaVersion":2,"snapshotID":"future","generatedAt":0,"phase":"working","todayEarnedMinor":0,"progressBasisPoints":0}"#.utf8
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        #expect(throws: DecodingError.self) {
            try decoder.decode(SalaryActivityContentState.self, from: data)
        }
    }

    @Test("Static context uses the same compatibility rule")
    func staticContextCompatibility() throws {
        let context = SalaryActivityStaticContext(
            activityID: "activity-1",
            currencyCode: "CNY",
            workDate: "2026-07-15",
            workStartAt: Date(timeIntervalSince1970: 1_721_059_200),
            lunchStartAt: Date(timeIntervalSince1970: 1_721_073_600),
            lunchEndAt: Date(timeIntervalSince1970: 1_721_080_800),
            workEndAt: Date(timeIntervalSince1970: 1_721_095_200),
            dailySalaryMinor: 50_000,
            standardWorkSeconds: 28_800
        )

        let decoded = try JSONDecoder().decode(
            SalaryActivityStaticContext.self,
            from: JSONEncoder().encode(context)
        )

        #expect(decoded == context)
        #expect(decoded.schemaVersion == SalaryActivityContract.currentSchemaVersion)

        let encoder = JSONEncoder()
        var legacyObject = try #require(
            JSONSerialization.jsonObject(with: encoder.encode(context)) as? [String: Any]
        )
        legacyObject.removeValue(forKey: "schemaVersion")
        let legacy = try JSONDecoder().decode(
            SalaryActivityStaticContext.self,
            from: JSONSerialization.data(withJSONObject: legacyObject)
        )
        #expect(legacy.schemaVersion == 1)

        legacyObject["schemaVersion"] = 2
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(
                SalaryActivityStaticContext.self,
                from: JSONSerialization.data(withJSONObject: legacyObject)
            )
        }
    }
}
