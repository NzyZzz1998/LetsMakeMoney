import Foundation
import Testing
@testable import SalaryCore

@Suite("App configuration and drafts")
struct AppConfigurationTests {
    @Test("Schedule metrics derive effective work time around lunch")
    func scheduleMetrics() throws {
        #expect(try WorkScheduleMetrics.effectiveWorkSeconds(
            workStart: "09:00",
            workEnd: "18:30",
            lunchStart: "12:00",
            lunchEnd: "13:30"
        ) == 28_800)
        #expect(throws: SalaryCoreError.invalidTimeRange) {
            try WorkScheduleMetrics.effectiveWorkSeconds(
                workStart: "09:00",
                workEnd: "18:00",
                lunchStart: "19:00",
                lunchEnd: "20:00"
            )
        }
    }

    @Test("Default configuration is valid and deterministic")
    func defaultConfiguration() throws {
        let configuration = AppConfiguration.defaultValue

        try configuration.validate()
        #expect(configuration.schemaVersion == 1)
        #expect(configuration.workStart == "08:00")
        #expect(configuration.workEnd == "18:00")
        #expect(configuration.lunchStart == "12:00")
        #expect(configuration.lunchEnd == "14:00")
        #expect(configuration.standardWorkSeconds == 28_800)
    }

    @Test("Field validation returns structured issues")
    func structuredValidation() {
        var configuration = AppConfiguration.defaultValue
        configuration.monthlySalaryMinor = -1
        configuration.currencyCode = "cn"

        let issues = configuration.validationIssues()

        #expect(issues.contains { $0.field == "monthlySalaryMinor" })
        #expect(issues.contains { $0.field == "currencyCode" })
    }

    @Test("Cancel restores the original draft without changing the effective value")
    func draftCancel() {
        let original = AppConfiguration.defaultValue
        var draft = ConfigurationDraft(original: original)
        draft.value.monthlySalaryMinor = 1_300_000

        #expect(draft.hasChanges)
        draft.cancel()
        #expect(!draft.hasChanges)
        #expect(draft.value == original)
    }

    @Test("Codec rejects unknown fields and future schemas")
    func strictCodec() throws {
        let codec = ConfigurationCodec()
        let valid = try codec.encode(.defaultValue)
        var object = try #require(JSONSerialization.jsonObject(with: valid) as? [String: Any])
        object["unexpected"] = true
        let unknown = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: ConfigurationPersistenceError.unknownField("unexpected")) {
            try codec.decode(unknown)
        }

        object.removeValue(forKey: "unexpected")
        object["schemaVersion"] = 2
        let future = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: ConfigurationPersistenceError.futureSchemaVersion(2)) {
            try codec.decode(future)
        }
    }

    @Test("Legacy schema zero migrates with explicit defaults")
    func legacyMigration() throws {
        let legacy: [String: Any] = [
            "schemaVersion": 0,
            "monthlySalaryMinor": 1_000_000,
            "currencyCode": "CNY",
            "restMode": "doubleWeekend",
            "workStart": "08:00",
            "workEnd": "18:00",
            "lunchStart": "12:00",
            "lunchEnd": "14:00",
            "standardWorkSeconds": 28_800,
            "dateOverrides": []
        ]
        let data = try JSONSerialization.data(withJSONObject: legacy)

        let decoded = try ConfigurationCodec().decode(data)

        #expect(decoded.migratedFromVersion == 0)
        #expect(decoded.configuration.schemaVersion == 1)
        #expect(decoded.configuration.notificationPreference == .notRequested)
        #expect(decoded.configuration.watchMetric == .remainingTime)
    }
}
