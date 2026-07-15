import Testing
@testable import SalaryCore

@Suite("Date override editing")
struct DateOverrideEditorTests {
    @Test("save replaces the selected date without duplicating it")
    func replaceOverride() {
        let original = SalaryDateOverride(date: "2026-07-15", isWorkday: false, isPaid: false)
        var configuration = configured(overrides: [original])
        var editor = DateOverrideEditor(date: "2026-07-15", existing: original)
        editor.value.isWorkday = true
        editor.value.isPaid = true
        editor.value.effectiveWorkSeconds = 21_600

        editor.save(into: &configuration)

        #expect(configuration.dateOverrides.count == 1)
        #expect(configuration.dateOverrides[0] == editor.value)
        #expect(editor.hasChanges == false)
    }

    @Test("cancel restores the original and delete removes only selected date")
    func cancelAndDelete() {
        let selected = SalaryDateOverride(date: "2026-07-15", isWorkday: false, isPaid: false)
        let other = SalaryDateOverride(date: "2026-07-16", isWorkday: true, isPaid: true)
        var editor = DateOverrideEditor(date: selected.date, existing: selected)
        editor.value.isPaid = true
        editor.cancel()
        #expect(editor.value == selected)

        var configuration = configured(overrides: [selected, other])
        #expect(editor.delete(from: &configuration) == true)
        #expect(configuration.dateOverrides == [other])
    }

    private func configured(overrides: [SalaryDateOverride]) -> AppConfiguration {
        var value = AppConfiguration.defaultValue
        value.monthlySalaryMinor = 1_200_000
        value.dateOverrides = overrides
        return value
    }
}
