import Foundation

public enum SalaryActivityProjectionError: Error, Equatable, Sendable {
    case invalidContext
}

public struct SalaryActivityProjectedValue: Equatable, Sendable {
    public let completedEffectiveSeconds: Int
    public let todayEarnedMinor: Int64
    public let progressBasisPoints: Int

    public init(
        completedEffectiveSeconds: Int,
        todayEarnedMinor: Int64,
        progressBasisPoints: Int
    ) {
        self.completedEffectiveSeconds = completedEffectiveSeconds
        self.todayEarnedMinor = todayEarnedMinor
        self.progressBasisPoints = progressBasisPoints
    }
}

public struct SalaryActivityProjection: Sendable {
    public let context: SalaryActivityStaticContext

    public init(context: SalaryActivityStaticContext) throws {
        guard context.workStartAt <= context.lunchStartAt,
              context.lunchStartAt <= context.lunchEndAt,
              context.lunchEndAt <= context.workEndAt,
              context.dailySalaryMinor >= 0,
              context.standardWorkSeconds > 0,
              context.dailySalaryMinor <= Int64.max / Int64(context.standardWorkSeconds)
        else {
            throw SalaryActivityProjectionError.invalidContext
        }
        self.context = context
    }

    public func value(at date: Date) -> SalaryActivityProjectedValue {
        let completed = completedEffectiveSeconds(at: date)
        let denominator = Int64(context.standardWorkSeconds)
        let amount = rounded(
            context.dailySalaryMinor * Int64(completed),
            by: denominator
        )
        let progress = Int(rounded(Int64(completed) * 10_000, by: denominator))

        return SalaryActivityProjectedValue(
            completedEffectiveSeconds: completed,
            todayEarnedMinor: min(max(amount, 0), context.dailySalaryMinor),
            progressBasisPoints: min(max(progress, 0), 10_000)
        )
    }

    private func completedEffectiveSeconds(at date: Date) -> Int {
        if date <= context.workStartAt {
            return 0
        }
        if date >= context.workEndAt {
            return context.standardWorkSeconds
        }

        let morningSeconds = wholeSeconds(
            from: context.workStartAt,
            to: context.lunchStartAt
        )
        let completed: Int
        if date < context.lunchStartAt {
            completed = wholeSeconds(from: context.workStartAt, to: date)
        } else if date < context.lunchEndAt {
            completed = morningSeconds
        } else {
            completed = morningSeconds + wholeSeconds(
                from: context.lunchEndAt,
                to: date
            )
        }

        return min(max(completed, 0), context.standardWorkSeconds)
    }

    private func wholeSeconds(from start: Date, to end: Date) -> Int {
        Int(end.timeIntervalSince(start).rounded(.down))
    }

    private func rounded(_ numerator: Int64, by denominator: Int64) -> Int64 {
        (numerator + denominator / 2) / denominator
    }
}
