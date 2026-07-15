import Foundation
import Testing
@testable import SalaryCore

@Suite("Live Activity time projection")
struct SalaryActivityProjectionTests {
    private let workStart = Date(timeIntervalSince1970: 1_721_059_200)

    private var context: SalaryActivityStaticContext {
        SalaryActivityStaticContext(
            activityID: "activity-projection",
            currencyCode: "CNY",
            workDate: "2026-07-15",
            workStartAt: workStart,
            lunchStartAt: workStart.addingTimeInterval(4 * 3_600),
            lunchEndAt: workStart.addingTimeInterval(6 * 3_600),
            workEndAt: workStart.addingTimeInterval(10 * 3_600),
            dailySalaryMinor: 50_000,
            standardWorkSeconds: 28_800
        )
    }

    @Test("Projection follows the salary core rounding rule")
    func followsSalaryRounding() throws {
        let projection = try SalaryActivityProjection(context: context)

        let value = projection.value(at: workStart.addingTimeInterval(60))

        #expect(value.completedEffectiveSeconds == 60)
        #expect(value.todayEarnedMinor == 104)
        #expect(value.progressBasisPoints == 21)
    }

    @Test("Lunch freezes money and progress until work resumes")
    func freezesDuringLunch() throws {
        let projection = try SalaryActivityProjection(context: context)
        let lunchStart = projection.value(at: context.lunchStartAt)
        let lunchMiddle = projection.value(
            at: context.lunchStartAt.addingTimeInterval(3_600)
        )
        let lunchEnd = projection.value(at: context.lunchEndAt)

        #expect(lunchStart.completedEffectiveSeconds == 14_400)
        #expect(lunchMiddle == lunchStart)
        #expect(lunchEnd == lunchStart)
        #expect(lunchStart.todayEarnedMinor == 25_000)
        #expect(lunchStart.progressBasisPoints == 5_000)
    }

    @Test("Afternoon projection excludes lunch and finishes at the daily cap")
    func excludesLunchAndClampsAtFinish() throws {
        let projection = try SalaryActivityProjection(context: context)

        let afternoon = projection.value(
            at: context.lunchEndAt.addingTimeInterval(3_600)
        )
        let finished = projection.value(at: context.workEndAt)
        let later = projection.value(
            at: context.workEndAt.addingTimeInterval(86_400)
        )

        #expect(afternoon.completedEffectiveSeconds == 18_000)
        #expect(afternoon.todayEarnedMinor == 31_250)
        #expect(afternoon.progressBasisPoints == 6_250)
        #expect(finished.completedEffectiveSeconds == 28_800)
        #expect(finished.todayEarnedMinor == 50_000)
        #expect(finished.progressBasisPoints == 10_000)
        #expect(later == finished)
    }

    @Test("Zero-duration lunch projects continuously")
    func zeroDurationLunch() throws {
        let noLunch = SalaryActivityStaticContext(
            activityID: "activity-no-lunch",
            currencyCode: "CNY",
            workDate: "2026-07-15",
            workStartAt: workStart,
            lunchStartAt: workStart.addingTimeInterval(4 * 3_600),
            lunchEndAt: workStart.addingTimeInterval(4 * 3_600),
            workEndAt: workStart.addingTimeInterval(8 * 3_600),
            dailySalaryMinor: 50_000,
            standardWorkSeconds: 28_800
        )
        let projection = try SalaryActivityProjection(context: noLunch)

        let value = projection.value(
            at: noLunch.lunchEndAt.addingTimeInterval(3_600)
        )

        #expect(value.completedEffectiveSeconds == 18_000)
        #expect(value.todayEarnedMinor == 31_250)
    }

    @Test("Invalid schedules and rates are rejected")
    func rejectsInvalidContext() {
        let invalid = SalaryActivityStaticContext(
            activityID: "invalid",
            currencyCode: "CNY",
            workDate: "2026-07-15",
            workStartAt: workStart,
            lunchStartAt: workStart.addingTimeInterval(5 * 3_600),
            lunchEndAt: workStart.addingTimeInterval(4 * 3_600),
            workEndAt: workStart.addingTimeInterval(8 * 3_600),
            dailySalaryMinor: 50_000,
            standardWorkSeconds: 0
        )

        #expect(throws: SalaryActivityProjectionError.invalidContext) {
            try SalaryActivityProjection(context: invalid)
        }

        let overflowing = SalaryActivityStaticContext(
            activityID: "overflowing",
            currencyCode: "CNY",
            workDate: "2026-07-15",
            workStartAt: workStart,
            lunchStartAt: workStart.addingTimeInterval(4 * 3_600),
            lunchEndAt: workStart.addingTimeInterval(4 * 3_600),
            workEndAt: workStart.addingTimeInterval(8 * 3_600),
            dailySalaryMinor: .max,
            standardWorkSeconds: 28_800
        )

        #expect(throws: SalaryActivityProjectionError.invalidContext) {
            try SalaryActivityProjection(context: overflowing)
        }
    }
}
