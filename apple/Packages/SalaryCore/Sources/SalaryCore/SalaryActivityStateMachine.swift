import Foundation

public enum SalaryActivityStateMachineError: Error, Equatable, Sendable {
    case invalidSchedule
    case beforeWorkStart
    case staleEvent
}

public enum SalaryActivityEvent: Equatable, Sendable {
    case clock(Date)
    case confirmEarlyEnd(Date)

    var occurredAt: Date {
        switch self {
        case let .clock(date), let .confirmEarlyEnd(date):
            date
        }
    }
}

public extension SalaryActivityPhase {
    var isTerminal: Bool {
        self == .finished || self == .endedEarly
    }

    var showsEarnedAmount: Bool {
        self != .lunchBreak
    }
}

public extension SalaryActivityContentState {
    var isTerminal: Bool {
        phase.isTerminal
    }

    var showsEarnedAmount: Bool {
        phase.showsEarnedAmount
    }
}

public struct SalaryActivityStateMachine: Sendable {
    public let context: SalaryActivityStaticContext
    private let projection: SalaryActivityProjection

    public init(context: SalaryActivityStaticContext) throws {
        guard context.workStartAt <= context.lunchStartAt,
              context.lunchStartAt <= context.lunchEndAt,
              context.lunchEndAt <= context.workEndAt,
              context.standardWorkSeconds > 0
        else {
            throw SalaryActivityStateMachineError.invalidSchedule
        }
        self.context = context
        do {
            self.projection = try SalaryActivityProjection(context: context)
        } catch {
            throw SalaryActivityStateMachineError.invalidSchedule
        }
    }

    public func initialState(
        from snapshot: ActivityState,
        at date: Date
    ) throws -> SalaryActivityContentState {
        try makeState(
            snapshotID: snapshot.snapshotID,
            generatedAt: date,
            at: date
        )
    }

    public func transition(
        _ current: SalaryActivityContentState,
        event: SalaryActivityEvent
    ) throws -> SalaryActivityContentState {
        let date = event.occurredAt
        guard date >= current.generatedAt else {
            throw SalaryActivityStateMachineError.staleEvent
        }

        if current.phase.isTerminal {
            return current
        }

        switch event {
        case .clock:
            return try makeState(
                snapshotID: current.snapshotID,
                generatedAt: date,
                at: date
            )
        case .confirmEarlyEnd:
            guard date >= context.workStartAt else {
                throw SalaryActivityStateMachineError.beforeWorkStart
            }
            let phase: SalaryActivityPhase = date >= context.workEndAt
                ? .finished
                : .endedEarly
            let projected = projection.value(at: date)
            return SalaryActivityContentState(
                snapshotID: current.snapshotID,
                generatedAt: date,
                phase: phase,
                todayEarnedMinor: projected.todayEarnedMinor,
                progressBasisPoints: projected.progressBasisPoints,
                nextTransitionAt: nil
            )
        }
    }

    private func makeState(
        snapshotID: String,
        generatedAt: Date,
        at date: Date
    ) throws -> SalaryActivityContentState {
        guard date >= context.workStartAt else {
            throw SalaryActivityStateMachineError.beforeWorkStart
        }

        let phase: SalaryActivityPhase
        let nextTransitionAt: Date?

        if date >= context.workEndAt {
            phase = .finished
            nextTransitionAt = nil
        } else if context.lunchStartAt < context.lunchEndAt,
                  date >= context.lunchStartAt,
                  date < context.lunchEndAt {
            phase = .lunchBreak
            nextTransitionAt = context.lunchEndAt
        } else {
            phase = .working
            nextTransitionAt = date < context.lunchStartAt
                ? context.lunchStartAt
                : context.workEndAt
        }

        let projected = projection.value(at: date)
        return SalaryActivityContentState(
            snapshotID: snapshotID,
            generatedAt: generatedAt,
            phase: phase,
            todayEarnedMinor: projected.todayEarnedMinor,
            progressBasisPoints: projected.progressBasisPoints,
            nextTransitionAt: nextTransitionAt
        )
    }
}
