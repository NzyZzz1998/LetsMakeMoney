import SalaryCore
import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("nav.today").font(.largeTitle.bold())
                    Spacer()
                }
                content
            }
            .padding(WarmMetrics.pagePadding)
            .frame(maxWidth: 620, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(WarmPalette.canvas.ignoresSafeArea())
    }

    @ViewBuilder
    private var content: some View {
        switch model.presentation {
        case .unconfigured:
            ContentUnavailableView {
                Label("state.unconfigured", systemImage: "slider.horizontal.3")
            } actions: {
                Button("state.configure") { model.present(.onboarding) }
                    .buttonStyle(WarmPrimaryButtonStyle())
            }
        case .error(let error):
            ContentUnavailableView {
                Label("state.configuration_error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(LocalizedStringKey(error.localizationKey))
            } actions: {
                Button("common.retry") { model.refresh() }
                    .buttonStyle(WarmPrimaryButtonStyle())
            }
        case .ready(let snapshot, let isOutOfRange):
            amountCard(snapshot)
            HStack(spacing: 12) {
                metricCard("today.month_total", value: money(snapshot.monthEarnedMinor))
                metricCard("today.progress", value: percent(snapshot.progressBasisPoints))
            }
            scheduleCard
            if isOutOfRange {
                Label("calendar.out_of_range", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(WarmPalette.muted)
                    .accessibilityLabel("calendar.out_of_range")
            }
        }
    }

    private func amountCard(_ snapshot: SalarySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("today.amount").font(.subheadline).foregroundStyle(WarmPalette.muted)
            Text(money(snapshot.todayEarnedMinor))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.72)
                .accessibilityLabel("today.amount")
                .accessibilityIdentifier("today.amount")
            Text(statusTitle(snapshot.status))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(WarmPalette.orange)
            ProgressView(value: Double(snapshot.progressBasisPoints), total: 10_000)
                .tint(WarmPalette.coin)
                .accessibilityLabel("today.progress")
        }
        .warmCard()
    }

    private func metricCard(_ key: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(key)).font(.caption).foregroundStyle(WarmPalette.muted)
            Text(value).font(.headline).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("today.schedule").font(.headline)
            scheduleRow("schedule.work_start", model.configuration.workStart)
            Divider()
            scheduleRow("schedule.lunch", "\(model.configuration.lunchStart)-\(model.configuration.lunchEnd)")
            Divider()
            scheduleRow("schedule.work_end", model.configuration.workEnd)
        }
        .warmCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("today.schedule")
    }

    private func scheduleRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(LocalizedStringKey(key)).foregroundStyle(WarmPalette.muted)
            Spacer()
            Text(value).monospacedDigit()
        }
    }

    private func money(_ minor: Int64) -> String {
        (Double(minor) / 100).formatted(.currency(code: model.configuration.currencyCode))
    }

    private func percent(_ basisPoints: Int) -> String {
        (Double(basisPoints) / 10_000).formatted(.percent.precision(.fractionLength(0)))
    }

    private func statusTitle(_ status: SalaryStatus) -> LocalizedStringKey {
        switch status {
        case .beforeWork: return "status.beforeWork"
        case .working: return "status.working"
        case .lunchBreak: return "status.lunchBreak"
        case .finished: return "status.finished"
        case .restDay: return "status.restDay"
        }
    }
}
