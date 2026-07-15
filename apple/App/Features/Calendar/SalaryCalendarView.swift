import SalaryCore
import SwiftUI

struct SalaryCalendarView: View {
    @EnvironmentObject private var model: AppModel
    @State private var month = Date()
    let compact: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("calendar.title")
                    .font(compact ? .title2.bold() : .largeTitle.bold())
                    .accessibilityIdentifier("calendar.title")
                monthHeader
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(weekdayKeys, id: \.self) { Text(LocalizedStringKey($0)).font(.caption) }
                    ForEach(monthCells, id: \.id) { cell in
                        if let date = cell.date {
                            Button { model.selectedDate = date } label: {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .frame(maxWidth: .infinity, minHeight: compact ? 34 : 42)
                                    .background(dayColor(date), in: RoundedRectangle(cornerRadius: 9))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
                        } else {
                            Color.clear.frame(height: compact ? 34 : 42)
                        }
                    }
                }
                legend
            }
            .padding(WarmMetrics.pagePadding)
            .frame(maxWidth: compact ? 480 : 720)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(WarmPalette.canvas.ignoresSafeArea())
        .sheet(isPresented: selectedDateBinding) {
            if let date = model.selectedDate { DateOverrideSheet(date: date) }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(month.formatted(.dateTime.year().month(.wide))).font(.headline)
            Spacer()
            Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
        }
        .buttonStyle(.plain)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 14) {
                Label("calendar.workday", systemImage: "circle.fill").foregroundStyle(WarmPalette.mint)
                Label("calendar.rest_day", systemImage: "circle.fill").foregroundStyle(WarmPalette.muted)
                Label("calendar.override", systemImage: "circle.fill").foregroundStyle(WarmPalette.coin)
            }
            HStack(spacing: 14) {
                Label("calendar.official_holiday", systemImage: "circle.fill").foregroundStyle(WarmPalette.orange)
                Label("calendar.adjusted_workday", systemImage: "circle.fill").foregroundStyle(WarmPalette.mint)
            }
        }
        .font(.caption)
    }

    private var selectedDateBinding: Binding<Bool> {
        Binding(get: { model.selectedDate != nil }, set: { if !$0 { model.selectedDate = nil } })
    }

    private var weekdayKeys: [String] {
        (1...7).map { "calendar.weekday.\($0)" }
    }

    private struct MonthCell: Identifiable {
        let id: Int
        let date: Date?
    }

    private var monthCells: [MonthCell] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let days = calendar.range(of: .day, in: .month, for: month)
        else { return [] }
        let offset = calendar.component(.weekday, from: interval.start) - 1
        return Array(repeating: nil as Date?, count: offset).enumerated().map {
            MonthCell(id: $0.offset, date: $0.element)
        } + days.enumerated().map { index, day in
            MonthCell(
                id: offset + index,
                date: calendar.date(byAdding: .day, value: day - 1, to: interval.start)
            )
        }
    }

    private func dayColor(_ date: Date) -> Color {
        switch model.calendarDay(for: date)?.kind {
        case .manualWorkday, .manualRestDay:
            return WarmPalette.coin.opacity(0.65)
        case .officialHoliday:
            return WarmPalette.orange.opacity(0.28)
        case .adjustedWorkday:
            return WarmPalette.mint.opacity(0.48)
        case .regularWorkday:
            return WarmPalette.mint.opacity(0.20)
        case .regularRestDay:
            return WarmPalette.border
        case nil:
            return WarmPalette.border
        }
    }

    private func changeMonth(_ delta: Int) {
        if let value = Calendar.current.date(byAdding: .month, value: delta, to: month) { month = value }
    }
}
