import AppIntents
import SalaryCore
import WidgetKit

enum WatchMetricOption: String, AppEnum {
    case remainingTime
    case todayIncome
    case progress

    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "watch.intent.metric.type"
    )
    static let caseDisplayRepresentations: [WatchMetricOption: DisplayRepresentation] = [
        .remainingTime: "watch.metric.remaining_time",
        .todayIncome: "watch.metric.today_income",
        .progress: "watch.metric.progress"
    ]

    var metric: WatchMetric {
        WatchMetric(rawValue: rawValue) ?? .remainingTime
    }
}

struct WatchMetricIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "watch.intent.metric.type"
    static let description = IntentDescription("watch.intent.metric.description")

    @Parameter(title: "watch.intent.metric.parameter", default: .remainingTime)
    var metric: WatchMetricOption
}
