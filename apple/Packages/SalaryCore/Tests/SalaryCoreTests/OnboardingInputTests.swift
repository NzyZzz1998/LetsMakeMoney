import Foundation
import Testing
@testable import SalaryCore

@Suite("Onboarding input contracts")
struct OnboardingInputTests {
    @Test("Zero salary clears on focus while an existing salary stays intact")
    func salaryFocusBehavior() {
        var zero = SalaryAmountDraft(minorUnits: 0)
        #expect(zero.text == "0.00")
        zero.beginEditing()
        #expect(zero.text.isEmpty)

        var existing = SalaryAmountDraft(minorUnits: 1_200_000)
        existing.beginEditing()
        #expect(existing.text == "12000.00")
    }

    @Test("Salary accepts integer and at most two decimals without destroying invalid input")
    func salaryParsingAndNormalization() {
        var draft = SalaryAmountDraft(minorUnits: 0)

        draft.updateText("12000")
        #expect(draft.minorUnits == 1_200_000)
        #expect(draft.normalizedText == "12000.00")

        draft.updateText("12000.5")
        #expect(draft.minorUnits == 1_200_050)
        #expect(draft.normalizedText == "12000.50")

        draft.updateText("12000.55")
        #expect(draft.minorUnits == 1_200_055)

        draft.updateText("12000.555")
        #expect(draft.text == "12000.555")
        #expect(draft.minorUnits == nil)

        draft.updateText("12a")
        #expect(draft.text == "12a")
        #expect(draft.minorUnits == nil)
    }

    @Test("Big and small week choices map to the existing rest-Saturday anchor")
    func alternatingWeekAnchorMapping() throws {
        let calendar = utcCalendar()
        let monday = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 13)))

        #expect(try AlternatingWeekResolver.anchor(
            for: .smallWeek,
            containing: monday,
            calendar: calendar
        ) == "2026-07-18")
        #expect(try AlternatingWeekResolver.anchor(
            for: .bigWeek,
            containing: monday,
            calendar: calendar
        ) == "2026-07-25")

        #expect(AlternatingWeekResolver.selection(
            forAnchor: "2026-07-18",
            containing: monday,
            calendar: calendar
        ) == .smallWeek)
        #expect(AlternatingWeekResolver.selection(
            forAnchor: "2026-07-25",
            containing: monday,
            calendar: calendar
        ) == .bigWeek)
    }

    @Test("Saturday itself belongs to the current big or small week")
    func alternatingWeekOnSaturday() throws {
        let calendar = utcCalendar()
        let saturday = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 18)))

        #expect(try AlternatingWeekResolver.anchor(
            for: .smallWeek,
            containing: saturday,
            calendar: calendar
        ) == "2026-07-18")
        #expect(try AlternatingWeekResolver.anchor(
            for: .bigWeek,
            containing: saturday,
            calendar: calendar
        ) == "2026-07-25")
    }

    @Test("Sunday still resolves to the Saturday in the same Monday-based week")
    func alternatingWeekOnSunday() throws {
        let calendar = utcCalendar()
        let sunday = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 19)))

        #expect(try AlternatingWeekResolver.anchor(
            for: .smallWeek,
            containing: sunday,
            calendar: calendar
        ) == "2026-07-18")
    }

    @Test("Schedule inference derives the default end times and supports zero lunch")
    func scheduleInference() throws {
        let standard = try WorkScheduleDraft.inferred()
        #expect(standard.workStart == "08:00")
        #expect(standard.lunchStart == "12:00")
        #expect(standard.lunchEnd == "14:00")
        #expect(standard.workEnd == "18:00")
        #expect(standard.effectiveWorkSeconds == 28_800)

        let noLunch = try WorkScheduleDraft.inferred(lunchDurationMinutes: 0)
        #expect(noLunch.lunchStart == "12:00")
        #expect(noLunch.lunchEnd == "12:00")
        #expect(noLunch.workEnd == "16:00")
        #expect(noLunch.effectiveWorkSeconds == 28_800)
    }

    @Test("Schedule inference rejects cross-day and non-half-hour lunch durations")
    func scheduleInferenceBoundaries() {
        #expect(throws: SalaryCoreError.invalidTimeRange) {
            try WorkScheduleDraft.inferred(workStart: "14:00", lunchStart: "15:00")
        }
        #expect(throws: SalaryCoreError.invalidTimeRange) {
            try WorkScheduleDraft.inferred(lunchDurationMinutes: 45)
        }
        #expect(throws: SalaryCoreError.invalidTimeRange) {
            try WorkScheduleDraft.inferred(lunchDurationMinutes: 210)
        }
    }

    @Test("Lunch start and end adjustments preserve the selected lunch duration")
    func linkedLunchAdjustments() throws {
        var draft = try WorkScheduleDraft.inferred()

        try draft.setLunchStart("12:30")
        #expect(draft.lunchStart == "12:30")
        #expect(draft.lunchEnd == "14:30")
        #expect(draft.lunchDurationMinutes == 120)

        try draft.setLunchEnd("14:00")
        #expect(draft.lunchStart == "12:00")
        #expect(draft.lunchEnd == "14:00")
        #expect(draft.lunchDurationMinutes == 120)
    }

    @Test("Changing lunch duration keeps effective work time and infers both end times")
    func lunchDurationAdjustment() throws {
        var draft = try WorkScheduleDraft.inferred()

        try draft.setLunchDuration(minutes: 60)
        #expect(draft.lunchStart == "12:00")
        #expect(draft.lunchEnd == "13:00")
        #expect(draft.workEnd == "17:00")
        #expect(draft.effectiveWorkSeconds == 28_800)

        try draft.setLunchDuration(minutes: 0)
        #expect(draft.lunchStart == "12:00")
        #expect(draft.lunchEnd == "12:00")
        #expect(draft.workEnd == "16:00")
        #expect(draft.effectiveWorkSeconds == 28_800)

        #expect(throws: SalaryCoreError.invalidTimeRange) {
            try draft.setLunchDuration(minutes: 45)
        }
        #expect(draft.lunchDurationMinutes == 0)
    }

    @Test("Initial work-start choice always infers an eight-hour workday")
    func initialWorkStartInference() throws {
        var draft = try WorkScheduleDraft.inferred()

        try draft.setInferredWorkStart("09:00")
        #expect(draft.workStart == "09:00")
        #expect(draft.lunchStart == "12:00")
        #expect(draft.lunchEnd == "14:00")
        #expect(draft.workEnd == "19:00")
        #expect(draft.effectiveWorkSeconds == 28_800)

        #expect(throws: SalaryCoreError.invalidTimeRange) {
            try draft.setInferredWorkStart("13:00")
        }
        #expect(draft.workStart == "09:00")
        #expect(draft.workEnd == "19:00")
    }

    @Test("Work boundary adjustments recalculate effective work time and preserve the last valid schedule")
    func workBoundaryAdjustments() throws {
        var draft = try WorkScheduleDraft.inferred()

        try draft.setWorkStart("09:00")
        #expect(draft.effectiveWorkSeconds == 25_200)

        try draft.setWorkEnd("19:00")
        #expect(draft.effectiveWorkSeconds == 28_800)

        #expect(throws: SalaryCoreError.invalidTimeRange) {
            try draft.setWorkEnd("13:00")
        }
        #expect(draft.workEnd == "19:00")
        #expect(draft.effectiveWorkSeconds == 28_800)
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }
}
