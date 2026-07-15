import ActivityKit
import Foundation
import SalaryCore
import SwiftUI
import WidgetKit

struct SalaryLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SalaryActivityAttributes.self) { context in
            SalaryLockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color(red: 1.0, green: 0.97, blue: 0.90))
                .activitySystemActionForegroundColor(
                    Color(red: 0.20, green: 0.14, blue: 0.09)
                )
        } dynamicIsland: { context in
            let content = SalaryDynamicIslandContent(context: context)
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    content.expandedLeading
                }
                DynamicIslandExpandedRegion(.trailing) {
                    content.expandedTrailing
                }
                DynamicIslandExpandedRegion(.bottom) {
                    content.expandedBottom
                }
            } compactLeading: {
                content.compactLeading
            } compactTrailing: {
                content.compactTrailing
            } minimal: {
                content.minimal
            }
            .keylineTint(Color(red: 0.95, green: 0.58, blue: 0.12))
        }
    }
}

struct SalaryLockScreenLiveActivityView: View {
    let context: ActivityViewContext<SalaryActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Label(phaseTitle, systemImage: phaseIcon(context.state.phase))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(phaseColor)
                    .lineLimit(1)

                Spacer(minLength: 8)

                transitionLabel
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color(red: 0.40, green: 0.29, blue: 0.18))
                    .lineLimit(1)
            }

            if context.state.showsEarnedAmount {
                Text(amount(context.state.todayEarnedMinor, currencyCode: context.attributes.context.currencyCode))
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color(red: 0.20, green: 0.14, blue: 0.09))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .accessibilityLabel("today.amount")
            } else {
                Text("activity.lunch.amount_hidden")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.46, green: 0.36, blue: 0.25))
            }

            HStack(spacing: 10) {
                ProgressView(
                    value: Double(clampedProgress(context.state.progressBasisPoints)),
                    total: 10_000
                )
                .tint(Color(red: 0.95, green: 0.58, blue: 0.12))
                .accessibilityLabel("today.progress")
                .accessibilityValue(percent(context.state.progressBasisPoints))

                Text(percent(context.state.progressBasisPoints))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color(red: 0.34, green: 0.25, blue: 0.16))
                    .frame(minWidth: 34, alignment: .trailing)
            }
        }
        .padding(16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(phaseTitle)
    }

    @ViewBuilder
    private var transitionLabel: some View {
        switch context.state.phase {
        case .working:
            countdownLabel(
                title: "activity.until_work_end",
                end: context.attributes.context.workEndAt
            )
        case .lunchBreak:
            countdownLabel(
                title: "activity.until_resume",
                end: context.state.nextTransitionAt ?? context.attributes.context.lunchEndAt
            )
        case .finished:
            Text("activity.finished")
        case .endedEarly:
            Text("activity.ended_early")
        }
    }

    private func countdownLabel(title: LocalizedStringKey, end: Date) -> some View {
        HStack(spacing: 4) {
            Text(title)
            Text(
                timerInterval: min(context.state.generatedAt, end)...end,
                countsDown: true
            )
        }
        .accessibilityElement(children: .combine)
    }

    private var phaseTitle: LocalizedStringKey {
        switch context.state.phase {
        case .working: "status.working"
        case .lunchBreak: "status.lunchBreak"
        case .finished: "status.finished"
        case .endedEarly: "activity.ended_early"
        }
    }

    private var phaseColor: Color {
        switch context.state.phase {
        case .working: Color(red: 0.31, green: 0.60, blue: 0.46)
        case .lunchBreak: Color(red: 0.84, green: 0.50, blue: 0.10)
        case .finished: Color(red: 0.31, green: 0.60, blue: 0.46)
        case .endedEarly: Color(red: 0.53, green: 0.43, blue: 0.31)
        }
    }
}

private struct SalaryDynamicIslandContent {
    let context: ActivityViewContext<SalaryActivityAttributes>

    var expandedLeading: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(phaseTitle, systemImage: phaseIcon(context.state.phase))
                .font(.caption.weight(.semibold))

            if context.state.showsEarnedAmount {
                Text(amount(
                    context.state.todayEarnedMinor,
                    currencyCode: context.attributes.context.currencyCode
                ))
                .font(.headline.weight(.bold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .accessibilityLabel("today.amount")
            } else {
                Text("activity.lunch.amount_hidden")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .contain)
    }

    var expandedTrailing: some View {
        transitionLabel(showTitle: true)
            .font(.caption.weight(.semibold).monospacedDigit())
            .multilineTextAlignment(.trailing)
            .lineLimit(2)
    }

    var expandedBottom: some View {
        HStack(spacing: 10) {
            ProgressView(
                value: Double(clampedProgress(context.state.progressBasisPoints)),
                total: 10_000
            )
            .tint(Color(red: 0.95, green: 0.58, blue: 0.12))
            .accessibilityLabel("today.progress")
            .accessibilityValue(percent(context.state.progressBasisPoints))

            Text(percent(context.state.progressBasisPoints))
                .font(.caption.weight(.semibold).monospacedDigit())
                .frame(minWidth: 34, alignment: .trailing)
        }
    }

    var compactLeading: some View {
        Image(systemName: phaseIcon(context.state.phase))
            .foregroundStyle(Color(red: 0.95, green: 0.58, blue: 0.12))
            .accessibilityLabel(phaseTitle)
    }

    @ViewBuilder
    var compactTrailing: some View {
        ViewThatFits(in: .horizontal) {
            compactPrimary
            Text(percent(context.state.progressBasisPoints))
                .monospacedDigit()
        }
        .font(.caption2.weight(.semibold))
    }

    var minimal: some View {
        Image(systemName: phaseIcon(context.state.phase))
            .foregroundStyle(Color(red: 0.95, green: 0.58, blue: 0.12))
            .accessibilityLabel(phaseTitle)
    }

    @ViewBuilder
    private var compactPrimary: some View {
        if context.state.showsEarnedAmount {
            Text(compactAmount(
                context.state.todayEarnedMinor,
                currencyCode: context.attributes.context.currencyCode
            ))
            .monospacedDigit()
        } else {
            transitionLabel(showTitle: false)
        }
    }

    @ViewBuilder
    private func transitionLabel(showTitle: Bool) -> some View {
        switch context.state.phase {
        case .working:
            timerLabel(
                title: "activity.until_work_end",
                end: context.attributes.context.workEndAt,
                showTitle: showTitle
            )
        case .lunchBreak:
            timerLabel(
                title: "activity.until_resume",
                end: context.state.nextTransitionAt ?? context.attributes.context.lunchEndAt,
                showTitle: showTitle
            )
        case .finished:
            Text("activity.finished")
        case .endedEarly:
            Text("activity.ended_early")
        }
    }

    private func timerLabel(
        title: LocalizedStringKey,
        end: Date,
        showTitle: Bool
    ) -> some View {
        HStack(spacing: 3) {
            if showTitle {
                Text(title)
            }
            Text(
                timerInterval: min(context.state.generatedAt, end)...end,
                countsDown: true
            )
        }
        .accessibilityElement(children: .combine)
    }

    private var phaseTitle: LocalizedStringKey {
        switch context.state.phase {
        case .working: "status.working"
        case .lunchBreak: "status.lunchBreak"
        case .finished: "status.finished"
        case .endedEarly: "activity.ended_early"
        }
    }
}

private func phaseIcon(_ phase: SalaryActivityPhase) -> String {
    switch phase {
    case .working: "yensign.circle.fill"
    case .lunchBreak: "cup.and.saucer.fill"
    case .finished: "checkmark.circle.fill"
    case .endedEarly: "stop.circle.fill"
    }
}

private func clampedProgress(_ basisPoints: Int) -> Int {
    min(max(basisPoints, 0), 10_000)
}

private func percent(_ basisPoints: Int) -> String {
    (Double(clampedProgress(basisPoints)) / 10_000).formatted(
        .percent.precision(.fractionLength(0))
    )
}

private func amount(_ minor: Int64, currencyCode: String) -> String {
    (Double(minor) / 100).formatted(
        .currency(code: currencyCode).precision(.fractionLength(2))
    )
}

private func compactAmount(_ minor: Int64, currencyCode: String) -> String {
    (Double(minor) / 100).formatted(
        .currency(code: currencyCode).precision(.fractionLength(0))
    )
}
