import AppIntents
import SalaryCore
import SwiftUI
import WidgetKit

struct WatchProgressEntry: TimelineEntry {
    let date: Date
    let message: WatchMessageEnvelope?
    let metric: WatchMetric
}

struct WatchProgressProvider: AppIntentTimelineProvider {
    typealias Intent = WatchMetricIntent
    typealias Entry = WatchProgressEntry

    func placeholder(in context: Context) -> WatchProgressEntry {
        WatchProgressEntry(date: .now, message: nil, metric: .remainingTime)
    }

    func snapshot(
        for configuration: WatchMetricIntent,
        in context: Context
    ) async -> WatchProgressEntry {
        entry(for: configuration)
    }

    func timeline(
        for configuration: WatchMetricIntent,
        in context: Context
    ) async -> Timeline<WatchProgressEntry> {
        Timeline(entries: [entry(for: configuration)], policy: .after(.now.addingTimeInterval(900)))
    }

    func recommendations() -> [AppIntentRecommendation<WatchMetricIntent>] {
        [
            recommendation(
                .remainingTime,
                description: String(localized: "watch.metric.remaining_time")
            ),
            recommendation(
                .todayIncome,
                description: String(localized: "watch.metric.today_income")
            ),
            recommendation(
                .progress,
                description: String(localized: "watch.metric.progress")
            )
        ]
    }

    private func recommendation(
        _ metric: WatchMetricOption,
        description: String
    ) -> AppIntentRecommendation<WatchMetricIntent> {
        var intent = WatchMetricIntent()
        intent.metric = metric
        return AppIntentRecommendation(intent: intent, description: description)
    }

    private func entry(for configuration: WatchMetricIntent) -> WatchProgressEntry {
        let appGroup = Bundle.main.object(
            forInfoDictionaryKey: "LMMAppGroupIdentifier"
        ) as? String
        return WatchProgressEntry(
            date: .now,
            message: WatchMessageStore(appGroupIdentifier: appGroup).load(),
            metric: configuration.metric.metric
        )
    }
}

struct WatchProgressWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WatchProgressEntry

    var body: some View {
        Group {
            if let snapshot = entry.message?.snapshot {
                content(snapshot)
            } else {
                Label("watch.widget.waiting", systemImage: "iphone")
            }
        }
        .containerBackground(.orange.opacity(0.14), for: .widget)
        .widgetURL(URL(string: "letsmakemoney://watch?metric=\(entry.metric.rawValue)"))
    }

    @ViewBuilder
    private func content(_ snapshot: WatchSnapshot) -> some View {
        switch family {
        case .accessoryInline:
            Text(title(snapshot)) + Text(" ") + Text(shortValue(snapshot))
        case .accessoryCircular:
            Gauge(
                value: Double(min(10_000, max(0, snapshot.progressBasisPoints))),
                in: 0...10_000
            ) {
                Image(systemName: "yensign")
            } currentValueLabel: {
                Text(shortValue(snapshot)).monospacedDigit()
            }
            .gaugeStyle(.accessoryCircular)
        default:
            VStack(alignment: .leading, spacing: 2) {
                Text(title(snapshot)).font(.caption2).foregroundStyle(.secondary)
                dynamicValue(snapshot)
                    .font(.headline)
                    .monospacedDigit()
                Text(status(snapshot.status)).font(.caption2)
            }
        }
    }

    private func dynamicValue(_ snapshot: WatchSnapshot) -> Text {
        if entry.metric == .remainingTime {
            let end = snapshot.generatedAt.addingTimeInterval(
                TimeInterval(max(0, snapshot.remainingSeconds))
            )
            return Text(timerInterval: entry.date...max(entry.date, end), countsDown: true)
        }
        return Text(shortValue(snapshot))
    }

    private func title(_ snapshot: WatchSnapshot) -> LocalizedStringKey {
        switch entry.metric {
        case .remainingTime:
            snapshot.status == .lunchBreak
                ? "watch.metric.until_resume"
                : "watch.metric.until_work_end"
        case .todayIncome: "watch.metric.today_income"
        case .progress: "watch.metric.progress"
        }
    }

    private func shortValue(_ snapshot: WatchSnapshot) -> String {
        switch entry.metric {
        case .remainingTime:
            let value = max(
                0,
                snapshot.remainingSeconds - Int(entry.date.timeIntervalSince(snapshot.generatedAt))
            )
            return value >= 3_600 ? "\(value / 3_600)h" : "\(value / 60)m"
        case .todayIncome:
            return "¥\(snapshot.todayEarnedMinor / 100)"
        case .progress:
            return "\((min(10_000, max(0, snapshot.progressBasisPoints)) + 50) / 100)%"
        }
    }

    private func status(_ status: SalaryStatus) -> LocalizedStringKey {
        switch status {
        case .beforeWork: "status.beforeWork"
        case .working: "status.working"
        case .lunchBreak: "status.lunchBreak"
        case .finished: "status.finished"
        case .restDay: "status.restDay"
        }
    }
}

struct LetsMakeMoneyWatchWidget: Widget {
    let kind = "LetsMakeMoneyWatchProgress"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: WatchMetricIntent.self,
            provider: WatchProgressProvider()
        ) { entry in
            WatchProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("watch.widget.display_name")
        .description("watch.widget.description")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}
