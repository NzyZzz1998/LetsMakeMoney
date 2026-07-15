import Foundation
import SalaryCore
import SwiftUI
import WidgetKit

enum SalaryWidgetContentState: Equatable {
    case placeholder
    case ready(SharedSnapshotBundle)
    case unconfigured
    case unavailable
}

struct SalaryWidgetEntry: TimelineEntry {
    let date: Date
    let content: SalaryWidgetContentState
}

struct SalaryWidgetProvider: TimelineProvider {
    private let reader: any SharedSnapshotReading

    init(reader: any SharedSnapshotReading = WidgetSnapshotReader.make()) {
        self.reader = reader
    }

    func placeholder(in context: Context) -> SalaryWidgetEntry {
        SalaryWidgetEntry(date: Date(), content: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SalaryWidgetEntry) -> Void) {
        load(completion: completion)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SalaryWidgetEntry>) -> Void) {
        load { entry in
            completion(Timeline(
                entries: [entry],
                policy: .after(entry.date.addingTimeInterval(15 * 60))
            ))
        }
    }

    private func load(completion: @escaping (SalaryWidgetEntry) -> Void) {
        let timelineCompletion = WidgetTimelineCompletion(completion)
        Task {
            timelineCompletion.call(
                SalaryWidgetEntry(date: Date(), content: await loadContent())
            )
        }
    }

    private func loadContent() async -> SalaryWidgetContentState {
        do {
            return .ready(try await reader.read())
        } catch SharedSnapshotReadError.missingSnapshot {
            return .unconfigured
        } catch {
            return .unavailable
        }
    }
}

private final class WidgetTimelineCompletion<Value>: @unchecked Sendable {
    private let callback: (Value) -> Void

    init(_ callback: @escaping (Value) -> Void) {
        self.callback = callback
    }

    func call(_ value: Value) {
        callback(value)
    }
}

private enum WidgetSnapshotReader {
    static func make(bundle: Bundle = .main) -> any SharedSnapshotReading {
        guard let identifier = bundle.object(
            forInfoDictionaryKey: "LMMAppGroupIdentifier"
        ) as? String,
              !identifier.isEmpty,
              let directoryURL = try? AppGroupContainerProvider(
                  identifier: identifier
              ).containerURL()
        else { return MissingSharedSnapshotReader() }
        return SharedSnapshotStore(directoryURL: directoryURL)
    }
}

private struct MissingSharedSnapshotReader: SharedSnapshotReading {
    func read() async throws -> SharedSnapshotBundle {
        throw SharedContainerError.appGroupUnavailable
    }
}

private extension WidgetFamily {
    var isAccessory: Bool {
        self == .accessoryInline
            || self == .accessoryCircular
            || self == .accessoryRectangular
    }
}

struct SalaryWidgetView: View {
    let entry: SalaryWidgetEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        Group {
            switch entry.content {
            case .placeholder:
                placeholderView
            case .ready(let snapshot):
                readyView(snapshot)
            case .unconfigured:
                emptyStateView(
                    icon: "slider.horizontal.3",
                    title: "state.configure",
                    message: "widget.configure.message"
                )
            case .unavailable:
                emptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "widget.unavailable.title",
                    message: "widget.unavailable.message"
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            if widgetFamily.isAccessory {
                Color.clear
            } else {
                Color(red: 1.0, green: 0.97, blue: 0.90)
            }
        }
    }

    @ViewBuilder
    private func readyView(_ snapshot: SharedSnapshotBundle) -> some View {
        if widgetFamily == .accessoryInline {
            accessoryInlineReadyView(snapshot)
        } else if widgetFamily == .accessoryCircular {
            accessoryCircularReadyView(snapshot)
        } else if widgetFamily == .accessoryRectangular {
            accessoryRectangularReadyView(snapshot)
        } else if widgetFamily == .systemLarge {
            largeReadyView(snapshot)
        } else if widgetFamily == .systemMedium {
            mediumReadyView(snapshot)
        } else {
            smallReadyView(snapshot)
        }
    }

    @ViewBuilder
    private var placeholderView: some View {
        if widgetFamily.isAccessory {
            accessoryPlaceholderView
        } else if widgetFamily == .systemLarge {
            largePlaceholderView
        } else if widgetFamily == .systemMedium {
            mediumPlaceholderView
        } else {
            smallPlaceholderView
        }
    }

    private func smallReadyView(_ snapshot: SharedSnapshotBundle) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: "yensign.circle.fill")
                    .foregroundStyle(Color(red: 0.95, green: 0.58, blue: 0.12))
                Text("today.amount")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(red: 0.40, green: 0.29, blue: 0.18))
            }

            Text(amount(snapshot.salary.value.todayEarnedMinor))
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(Color(red: 0.20, green: 0.14, blue: 0.09))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 2)

            statusBadge(snapshot.salary.value.status)
        }
    }

    private var smallPlaceholderView: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("today.amount", systemImage: "yensign.circle.fill")
                .font(.caption.weight(.medium))
            Text("¥ 186.42")
                .font(.title2.weight(.bold).monospacedDigit())
            Spacer(minLength: 2)
            Text("status.working")
                .font(.caption2.weight(.semibold))
        }
        .redacted(reason: .placeholder)
    }

    private func accessoryInlineReadyView(_ snapshot: SharedSnapshotBundle) -> some View {
        ViewThatFits(in: .horizontal) {
            inlineSummary(snapshot)
            Text(statusKey(snapshot.salary.value.status))
        }
        .font(.caption.weight(.semibold).monospacedDigit())
        .widgetAccentable()
    }

    private func inlineSummary(_ snapshot: SharedSnapshotBundle) -> Text {
        Text(statusKey(snapshot.salary.value.status))
            + Text(verbatim: " · \(amount(snapshot.salary.value.todayEarnedMinor))")
    }

    private func accessoryCircularReadyView(_ snapshot: SharedSnapshotBundle) -> some View {
        let progress = Double(clampedProgress(snapshot.salary.value.progressBasisPoints)) / 10_000
        return ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.24), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text(percent(snapshot.salary.value.progressBasisPoints))
                .font(.caption2.weight(.bold).monospacedDigit())
                .minimumScaleFactor(0.72)
        }
        .widgetAccentable()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("today.progress")
        .accessibilityValue(percent(snapshot.salary.value.progressBasisPoints))
    }

    private func accessoryRectangularReadyView(_ snapshot: SharedSnapshotBundle) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(amount(snapshot.salary.value.todayEarnedMinor))
                .font(.headline.weight(.bold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            HStack(spacing: 5) {
                Text(statusKey(snapshot.salary.value.status))
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(percent(snapshot.salary.value.progressBasisPoints))
                    .monospacedDigit()
            }
            .font(.caption2.weight(.semibold))

            ProgressView(
                value: Double(clampedProgress(snapshot.salary.value.progressBasisPoints)),
                total: 10_000
            )
            .accessibilityLabel("today.progress")
        }
        .widgetAccentable()
    }

    @ViewBuilder
    private var accessoryPlaceholderView: some View {
        Group {
            if widgetFamily == .accessoryInline {
                Text("status.working") + Text(verbatim: " · ¥ 186.42")
            } else if widgetFamily == .accessoryCircular {
                ZStack {
                    Circle().stroke(Color.secondary.opacity(0.24), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: 0.56)
                        .stroke(Color.accentColor, lineWidth: 4)
                        .rotationEffect(.degrees(-90))
                    Text("56%")
                        .font(.caption2.weight(.bold).monospacedDigit())
                }
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Text("¥ 186.42")
                        .font(.headline.weight(.bold).monospacedDigit())
                    HStack {
                        Text("status.working")
                        Spacer()
                        Text("56%").monospacedDigit()
                    }
                    .font(.caption2.weight(.semibold))
                    ProgressView(value: 0.56)
                }
            }
        }
        .widgetAccentable()
        .redacted(reason: .placeholder)
    }

    private func mediumReadyView(_ snapshot: SharedSnapshotBundle) -> some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 7) {
                Label("today.amount", systemImage: "yensign.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(red: 0.40, green: 0.29, blue: 0.18))

                Text(amount(snapshot.salary.value.todayEarnedMinor))
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color(red: 0.20, green: 0.14, blue: 0.09))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                statusBadge(snapshot.salary.value.status)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .overlay(Color(red: 0.55, green: 0.42, blue: 0.28).opacity(0.18))

            VStack(alignment: .leading, spacing: 8) {
                Text("today.progress")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(red: 0.40, green: 0.29, blue: 0.18))

                Text(percent(snapshot.salary.value.progressBasisPoints))
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color(red: 0.20, green: 0.14, blue: 0.09))

                ProgressView(
                    value: Double(clampedProgress(snapshot.salary.value.progressBasisPoints)),
                    total: 10_000
                )
                .tint(Color(red: 0.95, green: 0.58, blue: 0.12))
                .accessibilityLabel("today.progress")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var mediumPlaceholderView: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 7) {
                Label("today.amount", systemImage: "yensign.circle.fill")
                    .font(.caption.weight(.medium))
                Text("¥ 186.42")
                    .font(.title2.weight(.bold).monospacedDigit())
                Text("status.working")
                    .font(.caption2.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("today.progress")
                    .font(.caption.weight(.medium))
                Text("56%")
                    .font(.title3.weight(.bold).monospacedDigit())
                ProgressView(value: 0.56)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .redacted(reason: .placeholder)
    }

    private func largeReadyView(_ snapshot: SharedSnapshotBundle) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("today.amount", systemImage: "yensign.circle.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(red: 0.40, green: 0.29, blue: 0.18))
                    Text(amount(snapshot.salary.value.todayEarnedMinor))
                        .font(.title.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color(red: 0.20, green: 0.14, blue: 0.09))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    statusBadge(snapshot.salary.value.status)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("today.progress")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(red: 0.40, green: 0.29, blue: 0.18))
                    Text(percent(snapshot.salary.value.progressBasisPoints))
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color(red: 0.20, green: 0.14, blue: 0.09))
                    ProgressView(
                        value: Double(clampedProgress(snapshot.salary.value.progressBasisPoints)),
                        total: 10_000
                    )
                    .tint(Color(red: 0.95, green: 0.58, blue: 0.12))
                    .accessibilityLabel("today.progress")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
                .overlay(Color(red: 0.55, green: 0.42, blue: 0.28).opacity(0.18))

            VStack(alignment: .leading, spacing: 11) {
                Text("today.schedule")
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.20, green: 0.14, blue: 0.09))

                if let schedule = snapshot.schedule {
                    scheduleRow("schedule.work_start", value: schedule.workStart)
                    Divider()
                    scheduleRow(
                        "schedule.lunch",
                        value: "\(schedule.lunchStart)-\(schedule.lunchEnd)"
                    )
                    Divider()
                    scheduleRow("schedule.work_end", value: schedule.workEnd)
                } else {
                    Text("widget.unavailable.message")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.46, green: 0.36, blue: 0.25))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.56))
            )
        }
    }

    private var largePlaceholderView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("today.amount", systemImage: "yensign.circle.fill")
                    Text("¥ 186.42").font(.title.weight(.bold).monospacedDigit())
                    Text("status.working")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("today.progress")
                    Text("56%").font(.title2.weight(.bold).monospacedDigit())
                    ProgressView(value: 0.56)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
            Text("today.schedule").font(.headline)
            scheduleRow("schedule.work_start", value: "08:00")
            scheduleRow("schedule.lunch", value: "12:00-14:00")
            scheduleRow("schedule.work_end", value: "18:00")
        }
        .redacted(reason: .placeholder)
    }

    private func scheduleRow(_ key: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(key)
                .foregroundStyle(Color(red: 0.46, green: 0.36, blue: 0.25))
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundStyle(Color(red: 0.20, green: 0.14, blue: 0.09))
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private func emptyStateView(
        icon: String,
        title: LocalizedStringKey,
        message: LocalizedStringKey
    ) -> some View {
        if widgetFamily.isAccessory {
            accessoryEmptyStateView(icon: icon, title: title)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color(red: 0.95, green: 0.58, blue: 0.12))
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(red: 0.20, green: 0.14, blue: 0.09))
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(Color(red: 0.46, green: 0.36, blue: 0.25))
                    .lineLimit(3)
            }
        }
    }

    @ViewBuilder
    private func accessoryEmptyStateView(
        icon: String,
        title: LocalizedStringKey
    ) -> some View {
        Group {
            if widgetFamily == .accessoryInline {
                Label(title, systemImage: icon)
                    .font(.caption.weight(.semibold))
            } else if widgetFamily == .accessoryCircular {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 7) {
                    Image(systemName: icon)
                        .font(.headline.weight(.semibold))
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(2)
                }
            }
        }
        .widgetAccentable()
    }

    private func statusKey(_ status: SalaryStatus) -> LocalizedStringKey {
        switch status {
        case .beforeWork: "status.beforeWork"
        case .working: "status.working"
        case .lunchBreak: "status.lunchBreak"
        case .finished: "status.finished"
        case .restDay: "status.restDay"
        }
    }

    private func statusColor(_ status: SalaryStatus) -> Color {
        switch status {
        case .working: Color(red: 0.39, green: 0.66, blue: 0.43)
        case .lunchBreak: Color(red: 0.95, green: 0.58, blue: 0.12)
        case .finished: Color(red: 0.31, green: 0.60, blue: 0.46)
        case .beforeWork, .restDay: Color(red: 0.53, green: 0.43, blue: 0.31)
        }
    }

    private func statusBadge(_ status: SalaryStatus) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusColor(status))
                .frame(width: 7, height: 7)
            Text(statusKey(status))
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(Color(red: 0.34, green: 0.25, blue: 0.16))
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.white.opacity(0.62)))
    }

    private func clampedProgress(_ basisPoints: Int) -> Int {
        min(max(basisPoints, 0), 10_000)
    }

    private func percent(_ basisPoints: Int) -> String {
        (Double(clampedProgress(basisPoints)) / 10_000).formatted(
            .percent.precision(.fractionLength(0))
        )
    }

    private func amount(_ minor: Int64) -> String {
        (Double(minor) / 100).formatted(
            .currency(code: "CNY").precision(.fractionLength(2))
        )
    }
}

struct SalaryWidget: Widget {
    let kind = "LetsMakeMoneySalaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalaryWidgetProvider()) { entry in
            SalaryWidgetView(entry: entry)
        }
        .configurationDisplayName("app.title")
        .description("today.amount")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}
