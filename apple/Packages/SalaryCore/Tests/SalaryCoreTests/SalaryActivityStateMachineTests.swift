import Foundation
import Testing
@testable import SalaryCore

@Suite("Live Activity state machine")
struct SalaryActivityStateMachineTests {
    private let workStart = Date(timeIntervalSince1970: 1_721_059_200)

    private var context: SalaryActivityStaticContext {
        SalaryActivityStaticContext(
            activityID: "activity-1",
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

    private var snapshot: ActivityState {
        ActivityState(
            snapshotID: "snapshot-1",
            generatedAt: workStart,
            status: .working,
            todayEarnedMinor: 12_500,
            progressBasisPoints: 2_500
        )
    }

    @Test("Work and lunch boundaries expose the next transition")
    func workAndLunchBoundaries() throws {
        let machine = try SalaryActivityStateMachine(context: context)

        let morning = try machine.initialState(
            from: snapshot,
            at: workStart.addingTimeInterval(60)
        )
        #expect(morning.phase == .working)
        #expect(morning.nextTransitionAt == context.lunchStartAt)
        #expect(morning.showsEarnedAmount)

        let lunch = try machine.transition(
            morning,
            event: .clock(context.lunchStartAt)
        )
        #expect(lunch.phase == .lunchBreak)
        #expect(lunch.nextTransitionAt == context.lunchEndAt)
        #expect(!lunch.showsEarnedAmount)

        let afternoon = try machine.transition(
            lunch,
            event: .clock(context.lunchEndAt)
        )
        #expect(afternoon.phase == .working)
        #expect(afternoon.nextTransitionAt == context.workEndAt)
        #expect(afternoon.showsEarnedAmount)
    }

    @Test("Work end automatically enters a stable finished state")
    func automaticFinishIsTerminal() throws {
        let machine = try SalaryActivityStateMachine(context: context)
        let active = try machine.initialState(
            from: snapshot,
            at: context.lunchEndAt
        )

        let finished = try machine.transition(
            active,
            event: .clock(context.workEndAt)
        )
        #expect(finished.phase == .finished)
        #expect(finished.nextTransitionAt == nil)
        #expect(finished.isTerminal)

        let later = try machine.transition(
            finished,
            event: .clock(context.workEndAt.addingTimeInterval(3_600))
        )
        #expect(later.phase == .finished)
        #expect(later.isTerminal)
    }

    @Test("Confirmed early end is terminal and cannot resume")
    func confirmedEarlyEndIsTerminal() throws {
        let machine = try SalaryActivityStateMachine(context: context)
        let active = try machine.initialState(
            from: snapshot,
            at: workStart.addingTimeInterval(3_600)
        )
        let endedAt = workStart.addingTimeInterval(2 * 3_600)

        let ended = try machine.transition(
            active,
            event: .confirmEarlyEnd(endedAt)
        )
        #expect(ended.phase == .endedEarly)
        #expect(ended.nextTransitionAt == nil)
        #expect(ended.isTerminal)

        let later = try machine.transition(
            ended,
            event: .clock(context.workEndAt.addingTimeInterval(60))
        )
        #expect(later.phase == .endedEarly)
    }

    @Test("Early-end confirmation at scheduled work end remains finished")
    func confirmationAtWorkEndUsesFinished() throws {
        let machine = try SalaryActivityStateMachine(context: context)
        let active = try machine.initialState(
            from: snapshot,
            at: context.lunchEndAt
        )

        let state = try machine.transition(
            active,
            event: .confirmEarlyEnd(context.workEndAt)
        )

        #expect(state.phase == .finished)
    }

    @Test("Zero-duration lunch skips the lunch phase")
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
        let machine = try SalaryActivityStateMachine(context: noLunch)

        let state = try machine.initialState(
            from: snapshot,
            at: noLunch.lunchStartAt
        )

        #expect(state.phase == .working)
        #expect(state.nextTransitionAt == noLunch.workEndAt)
    }

    @Test("State machine rejects invalid schedules, pre-work starts and stale events")
    func rejectsInvalidInputs() throws {
        let invalid = SalaryActivityStaticContext(
            activityID: "invalid",
            currencyCode: "CNY",
            workDate: "2026-07-15",
            workStartAt: workStart,
            lunchStartAt: workStart.addingTimeInterval(6 * 3_600),
            lunchEndAt: workStart.addingTimeInterval(5 * 3_600),
            workEndAt: workStart.addingTimeInterval(10 * 3_600),
            dailySalaryMinor: 50_000,
            standardWorkSeconds: 28_800
        )

        #expect(throws: SalaryActivityStateMachineError.invalidSchedule) {
            try SalaryActivityStateMachine(context: invalid)
        }

        let machine = try SalaryActivityStateMachine(context: context)
        #expect(throws: SalaryActivityStateMachineError.beforeWorkStart) {
            try machine.initialState(
                from: snapshot,
                at: workStart.addingTimeInterval(-1)
            )
        }

        let current = try machine.initialState(
            from: snapshot,
            at: workStart.addingTimeInterval(60)
        )
        #expect(throws: SalaryActivityStateMachineError.staleEvent) {
            try machine.transition(
                current,
                event: .clock(current.generatedAt.addingTimeInterval(-1))
            )
        }
    }

    @Test("State transitions carry the latest snapshot values without deriving money")
    func carriesSnapshotValues() throws {
        let machine = try SalaryActivityStateMachine(context: context)
        let state = try machine.initialState(
            from: snapshot,
            at: workStart.addingTimeInterval(60)
        )
        let lunch = try machine.transition(
            state,
            event: .clock(context.lunchStartAt)
        )

        #expect(lunch.snapshotID == snapshot.snapshotID)
        #expect(lunch.todayEarnedMinor == snapshot.todayEarnedMinor)
        #expect(lunch.progressBasisPoints == snapshot.progressBasisPoints)
    }
}
