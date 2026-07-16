import SalaryCore
import SwiftUI

struct WatchHomeView: View {
    @ObservedObject var controller: WatchSessionController

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    connectionNotice
                    metricCard
                    scheduleCard
                    activityCard
                    syncLabel
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle("watch.title.today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    metricPicker
                }
            }
            .refreshable { controller.requestSnapshot() }
        }
    }

    @ViewBuilder
    private var connectionNotice: some View {
        if controller.state.showsOfflineNotice {
            Label("watch.connection.offline", systemImage: "iphone.slash")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }

    private var metricCard: some View {
        Group {
            if let snapshot = controller.state.latestSnapshot {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let presentation = WatchMetricPresentation.make(
                        snapshot: snapshot,
                        metric: controller.selectedMetric,
                        now: context.date
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(metricTitle(presentation.titleKey))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(presentation.value)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .monospacedDigit()
                        ProgressView(
                            value: Double(min(10_000, max(0, snapshot.progressBasisPoints))),
                            total: 10_000
                        )
                        .tint(.orange)
                        Text(statusText(snapshot.status))
                            .font(.caption2)
                    }
                }
            } else {
                ContentUnavailableView(
                    "watch.sync.waiting.title",
                    systemImage: "arrow.triangle.2.circlepath",
                    description: Text("watch.sync.waiting.message")
                )
            }
        }
        .padding(10)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var scheduleCard: some View {
        if let schedule = controller.state.latestSchedule {
            VStack(alignment: .leading, spacing: 5) {
                Text("watch.schedule.title").font(.caption).bold()
                scheduleRow("schedule.work_start", schedule.workStart)
                scheduleRow("schedule.lunch", "\(schedule.lunchStart)-\(schedule.lunchEnd)")
                scheduleRow("schedule.work_end", schedule.workEnd)
            }
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("watch.activity.title").font(.caption).bold()
            HStack {
                Button("watch.activity.start") { controller.requestActivity(.start) }
                    .buttonStyle(.borderedProminent)
                Button("watch.activity.stop") { controller.requestActivity(.stop) }
                    .buttonStyle(.bordered)
            }
            .disabled(!controller.state.canRequestActivity)
            activityFeedback
        }
    }

    @ViewBuilder
    private var activityFeedback: some View {
        switch controller.state.activityState {
        case .idle:
            EmptyView()
        case .pending:
            HStack {
                ProgressView()
                Text("watch.activity.pending")
            }
            .font(.caption2)
        case .confirmed(let command, _):
            let key: LocalizedStringKey = command == .start
                ? "watch.activity.started"
                : "watch.activity.stopped"
            Label {
                Text(key)
            } icon: {
                Image(systemName: "checkmark.circle.fill")
            }
            .font(.caption2)
            .foregroundStyle(.green)
        case .failed:
            Label("watch.activity.failed", systemImage: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundStyle(.red)
        case .cancelled:
            Text("watch.activity.cancelled").font(.caption2).foregroundStyle(.secondary)
        case .timedOut:
            Label("watch.activity.timed_out", systemImage: "clock.badge.exclamationmark")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private var syncLabel: some View {
        if let snapshot = controller.state.latestSnapshot {
            HStack(spacing: 3) {
                Text("watch.sync.recent")
                Text(snapshot.generatedAt, style: .relative)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private var metricPicker: some View {
        Picker("watch.metric.picker", selection: Binding(
            get: { controller.selectedMetric },
            set: controller.selectMetric
        )) {
            Text("watch.metric.remaining_time").tag(WatchMetric.remainingTime)
            Text("watch.metric.today_income").tag(WatchMetric.todayIncome)
            Text("watch.metric.progress").tag(WatchMetric.progress)
        }
        .pickerStyle(.navigationLink)
    }

    private func scheduleRow(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit()
        }
        .font(.caption2)
    }

    private func metricTitle(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(key)
    }

    private func statusText(_ status: SalaryStatus) -> LocalizedStringKey {
        switch status {
        case .beforeWork: "status.beforeWork"
        case .working: "status.working"
        case .lunchBreak: "status.lunchBreak"
        case .finished: "status.finished"
        case .restDay: "status.restDay"
        }
    }
}
