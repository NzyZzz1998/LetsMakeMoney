import Foundation
import SalaryCore
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var session: OnboardingSession?
    @State private var salaryDraft = SalaryAmountDraft(minorUnits: 0)
    @State private var alternatingWeekSelection = AlternatingWeekSelection.smallWeek
    @State private var scheduleDraft: WorkScheduleDraft?
    @State private var scheduleEntryStage = ScheduleEntryStage.workStart
    @State private var invalidFields: [OnboardingField] = []
    @State private var confirmFirstLaunchExit = false
    @FocusState private var salaryFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                progressHeader
                ScrollView {
                    if let binding = sessionBinding {
                        Group {
                            switch binding.wrappedValue.step {
                            case .compensation: compensationStep(binding)
                            case .schedule: scheduleStep(binding)
                            case .summary: summaryStep(binding)
                            }
                        }
                        .frame(maxWidth: 620, alignment: .top)
                        .frame(maxWidth: .infinity)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .padding(.horizontal, WarmMetrics.pagePadding)
            .padding(.top, 8)
            .background(WarmPalette.canvas.ignoresSafeArea())
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("onboarding.root")
            .safeAreaInset(edge: .bottom) {
                actionBar
                    .padding(.horizontal, WarmMetrics.pagePadding)
                    .padding(.vertical, 10)
                    .background(WarmPalette.canvas)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close") { requestCancel() }
                }
            }
            .confirmationDialog("onboarding.confirm_exit", isPresented: $confirmFirstLaunchExit) {
                Button("onboarding.exit", role: .destructive) { model.dismissModal(); dismiss() }
                Button("common.cancel", role: .cancel) {}
            }
        }
        .interactiveDismissDisabled(session?.mode == .firstLaunch)
        .onAppear(perform: prepareSession)
    }

    private var sessionBinding: Binding<OnboardingSession>? {
        guard session != nil else { return nil }
        return Binding(get: { session! }, set: { session = $0 })
    }

    private var progressHeader: some View {
        ProgressView(value: Double(session?.step.rawValue ?? 1), total: 3)
            .tint(WarmPalette.coin)
            .accessibilityLabel("onboarding.progress")
    }

    private var stepTitle: LocalizedStringKey {
        switch session?.step {
        case .compensation: return "onboarding.step.compensation"
        case .schedule: return "onboarding.step.schedule"
        case .summary: return "onboarding.step.summary"
        case nil: return "onboarding.title"
        }
    }

    private func compensationStep(_ session: Binding<OnboardingSession>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("onboarding.salary_prompt")
                .font(.headline)
            TextField("onboarding.salary_placeholder", text: salaryTextBinding(session))
                .keyboardType(.decimalPad)
                .focused($salaryFocused)
                .textFieldStyle(.roundedBorder)
                .monospacedDigit()
                .onChange(of: salaryFocused) { focused in
                    if focused {
                        salaryDraft.beginEditing()
                    } else if let normalized = salaryDraft.normalizedText {
                        salaryDraft.updateText(normalized)
                    }
                }
            Picker("settings.currency", selection: session.draft.value.currencyCode) {
                Text("currency.cny").tag("CNY")
            }
            Picker("settings.rest_mode", selection: restModeBinding(session)) {
                Text("rest.double_weekend").tag(RestMode.doubleWeekend)
                Text("rest.single_weekend").tag(RestMode.singleWeekend)
                Text("rest.alternating_weekend").tag(RestMode.alternatingWeekend)
            }
            .pickerStyle(.segmented)
            if session.draft.value.restMode.wrappedValue == .alternatingWeekend {
                VStack(alignment: .leading, spacing: 8) {
                    Text("onboarding.current_week_prompt")
                        .font(.subheadline.weight(.semibold))
                    Picker("onboarding.current_week_prompt", selection: alternatingWeekBinding(session)) {
                        Text("onboarding.big_week").tag(AlternatingWeekSelection.bigWeek)
                        Text("onboarding.small_week").tag(AlternatingWeekSelection.smallWeek)
                    }
                    .pickerStyle(.segmented)
                }
            }
            validationMessage
        }
        .warmCard()
    }

    private func scheduleStep(_ session: Binding<OnboardingSession>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("onboarding.schedule_prompt")
                .font(.headline)
            if scheduleDraft != nil {
                timePickerRow("schedule.work_start", field: .workStart, session: session)
                if scheduleEntryStage != .workStart {
                    HStack {
                        Text("onboarding.lunch_duration")
                        Spacer()
                        Picker("", selection: lunchDurationBinding(session)) {
                            ForEach(Array(stride(from: 0, through: 180, by: 30)), id: \.self) { minutes in
                                Text(lunchDurationText(minutes))
                                    .tag(minutes)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                }
                if scheduleEntryStage == .review {
                    Divider()
                    Text("onboarding.inferred_schedule")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WarmPalette.muted)
                    timePickerRow("schedule.lunch_start", field: .lunchStart, session: session)
                    timePickerRow("schedule.lunch_end", field: .lunchEnd, session: session)
                    timePickerRow("schedule.work_end", field: .workEnd, session: session)
                    LabeledContent("settings.effective_hours") {
                        Text(effectiveHoursText)
                            .monospacedDigit()
                    }
                }
            }
            validationMessage
        }
        .warmCard()
    }

    private func summaryStep(_ session: Binding<OnboardingSession>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("onboarding.summary.ready", systemImage: "checkmark.seal.fill")
                .font(.title3.bold()).foregroundStyle(WarmPalette.mint)
            LabeledContent("settings.monthly_salary") {
                Text((Double(session.draft.value.monthlySalaryMinor.wrappedValue) / 100).formatted(.currency(code: "CNY")))
            }
            LabeledContent("settings.effective_hours") {
                Text(effectiveHoursText).monospacedDigit()
            }
            LabeledContent("settings.rest_mode") {
                Text(restModeTitle(session.draft.value.restMode.wrappedValue))
            }
            if let preview = model.preview(configuration: session.draft.value.wrappedValue) {
                LabeledContent("onboarding.month_workdays") {
                    Text("\(preview.monthPaidWorkdays)").monospacedDigit()
                }
                LabeledContent("onboarding.daily_salary") {
                    Text((Double(preview.dailySalaryMinor) / 100).formatted(.currency(code: "CNY")))
                        .monospacedDigit()
                }
                LabeledContent("onboarding.today_preview") {
                    Text((Double(preview.todayEarnedMinor) / 100).formatted(.currency(code: "CNY")))
                        .monospacedDigit()
                }
            }
            if session.wrappedValue.completionFailureReason != nil {
                Text("feedback.save_failed").foregroundStyle(WarmPalette.danger)
            }
        }
        .warmCard()
    }

    @ViewBuilder
    private var validationMessage: some View {
        if !invalidFields.isEmpty {
            Text(validationMessageKey)
                .font(.footnote).foregroundStyle(WarmPalette.danger)
                .accessibilityLabel(validationMessageKey)
        }
    }

    private var validationMessageKey: LocalizedStringKey {
        if invalidFields.contains(.monthlySalary) {
            return "onboarding.validation.salary"
        }
        return "onboarding.validation_failed"
    }

    private var actionBar: some View {
        HStack {
            if session?.step != .compensation {
                Button("onboarding.back") { moveBackFromScheduleEntry() }
                    .buttonStyle(WarmSecondaryButtonStyle())
            }
            Spacer()
            Button(primaryActionKey) { advance() }
                .buttonStyle(WarmPrimaryButtonStyle())
        }
    }

    private var primaryActionKey: LocalizedStringKey {
        if session?.completionFailureReason != nil { return "onboarding.retry" }
        return session?.step == .summary ? "onboarding.complete" : "onboarding.next"
    }

    private var effectiveHoursText: String {
        guard let scheduleDraft else { return "0" }
        let hours = Double(scheduleDraft.effectiveWorkSeconds) / 3_600
        return String(format: hours.rounded() == hours ? "%.0f" : "%.1f", hours)
    }

    private func prepareSession() {
        guard session == nil else { return }
        let configuration = model.configuration
        let mode: OnboardingMode = configuration.monthlySalaryMinor > 0
            ? .reconfiguration
            : .firstLaunch
        session = OnboardingSession(configuration: configuration, mode: mode)
        salaryDraft = SalaryAmountDraft(minorUnits: configuration.monthlySalaryMinor)
        alternatingWeekSelection = configuration.alternatingAnchor.flatMap {
            AlternatingWeekResolver.selection(forAnchor: $0, containing: Date())
        } ?? .smallWeek
        scheduleDraft = try? WorkScheduleDraft(
            workStart: configuration.workStart,
            workEnd: configuration.workEnd,
            lunchStart: configuration.lunchStart,
            lunchEnd: configuration.lunchEnd
        )
        if scheduleDraft == nil {
            scheduleDraft = try? WorkScheduleDraft.inferred()
        }
    }

    private func advance() {
        guard var session else { return }
        if session.step == .compensation {
            guard let minorUnits = salaryDraft.minorUnits, minorUnits > 0 else {
                invalidFields = [.monthlySalary]
                return
            }
            session.draft.value.monthlySalaryMinor = minorUnits
            salaryDraft.updateText(salaryDraft.normalizedText ?? salaryDraft.text)
            if session.draft.value.restMode == .alternatingWeekend {
                applyAlternatingWeek(to: &session)
            }
        }
        if session.step == .schedule, advanceScheduleEntry() {
            invalidFields = []
            return
        }
        if session.step == .schedule, let scheduleDraft {
            applySchedule(scheduleDraft, to: &session)
        }
        switch session.advance() {
        case .advanced:
            invalidFields = []
            self.session = session
        case .invalid(let fields):
            invalidFields = fields
            self.session = session
        case .readyToComplete:
            Task {
                if await model.save(session.draft.value) {
                    model.dismissModal(); dismiss()
                } else {
                    session.recordCompletionFailure("save-failed")
                    self.session = session
                }
            }
        }
    }

    private func requestCancel() {
        guard var session else { return }
        switch session.cancel() {
        case .requiresExitConfirmation:
            self.session = session
            confirmFirstLaunchExit = true
        case .dismissed:
            self.session = session
            model.dismissModal(); dismiss()
        }
    }

    private func salaryTextBinding(_ session: Binding<OnboardingSession>) -> Binding<String> {
        Binding(
            get: { salaryDraft.text },
            set: { value in
                salaryDraft.updateText(value)
                if let minorUnits = salaryDraft.minorUnits {
                    session.draft.value.monthlySalaryMinor.wrappedValue = minorUnits
                    invalidFields.removeAll { $0 == .monthlySalary }
                }
            }
        )
    }

    private func restModeBinding(_ session: Binding<OnboardingSession>) -> Binding<RestMode> {
        Binding(
            get: { session.draft.value.restMode.wrappedValue },
            set: { value in
                salaryFocused = false
                var updated = session.wrappedValue
                updated.draft.value.restMode = value
                if value == .alternatingWeekend {
                    applyAlternatingWeek(to: &updated)
                } else {
                    updated.draft.value.alternatingAnchor = nil
                }
                session.wrappedValue = updated
            }
        )
    }

    private func alternatingWeekBinding(_ session: Binding<OnboardingSession>) -> Binding<AlternatingWeekSelection> {
        Binding(
            get: { alternatingWeekSelection },
            set: { value in
                alternatingWeekSelection = value
                var updated = session.wrappedValue
                applyAlternatingWeek(to: &updated)
                session.wrappedValue = updated
            }
        )
    }

    private func applyAlternatingWeek(to session: inout OnboardingSession) {
        session.draft.value.alternatingAnchor = try? AlternatingWeekResolver.anchor(
            for: alternatingWeekSelection,
            containing: Date()
        )
    }

    private enum ScheduleEntryStage {
        case workStart
        case lunchDuration
        case review
    }

    @discardableResult
    private func advanceScheduleEntry() -> Bool {
        switch scheduleEntryStage {
        case .workStart:
            scheduleEntryStage = .lunchDuration
            return true
        case .lunchDuration:
            scheduleEntryStage = .review
            return true
        case .review:
            return false
        }
    }

    private func moveBackFromScheduleEntry() {
        guard var session else { return }
        invalidFields = []
        if session.step == .summary {
            session.moveBack()
            scheduleEntryStage = .review
        } else if session.step == .schedule {
            switch scheduleEntryStage {
            case .review:
                scheduleEntryStage = .lunchDuration
            case .lunchDuration:
                scheduleEntryStage = .workStart
            case .workStart:
                session.moveBack()
            }
        }
        self.session = session
    }

    private func lunchDurationText(_ minutes: Int) -> LocalizedStringKey {
        switch minutes {
        case 0: return "onboarding.lunch_duration.0"
        case 30: return "onboarding.lunch_duration.30"
        case 60: return "onboarding.lunch_duration.60"
        case 90: return "onboarding.lunch_duration.90"
        case 120: return "onboarding.lunch_duration.120"
        case 150: return "onboarding.lunch_duration.150"
        default: return "onboarding.lunch_duration.180"
        }
    }

    private func restModeTitle(_ mode: RestMode) -> LocalizedStringKey {
        switch mode {
        case .singleWeekend: return "rest.single_weekend"
        case .doubleWeekend: return "rest.double_weekend"
        case .alternatingWeekend: return "rest.alternating_weekend"
        }
    }

    private enum ScheduleField {
        case workStart
        case lunchStart
        case lunchEnd
        case workEnd
    }

    private func timePickerRow(
        _ key: String,
        field: ScheduleField,
        session: Binding<OnboardingSession>
    ) -> some View {
        DatePicker(
            selection: scheduleTimeBinding(field, session: session),
            displayedComponents: .hourAndMinute
        ) {
            Text(LocalizedStringKey(key))
        }
        .datePickerStyle(.compact)
    }

    private func scheduleTimeBinding(
        _ field: ScheduleField,
        session: Binding<OnboardingSession>
    ) -> Binding<Date> {
        Binding(
            get: { dateForTime(scheduleValue(field)) },
            set: { date in
                guard var updatedDraft = scheduleDraft else { return }
                let value = timeString(date)
                do {
                    switch field {
                    case .workStart:
                        if scheduleEntryStage == .review {
                            try updatedDraft.setWorkStart(value)
                        } else {
                            try updatedDraft.setInferredWorkStart(value)
                        }
                    case .lunchStart: try updatedDraft.setLunchStart(value)
                    case .lunchEnd: try updatedDraft.setLunchEnd(value)
                    case .workEnd: try updatedDraft.setWorkEnd(value)
                    }
                    scheduleDraft = updatedDraft
                    var updatedSession = session.wrappedValue
                    applySchedule(updatedDraft, to: &updatedSession)
                    session.wrappedValue = updatedSession
                    invalidFields.removeAll { $0 == .workSchedule }
                } catch {
                    invalidFields = [.workSchedule]
                }
            }
        )
    }

    private func lunchDurationBinding(_ session: Binding<OnboardingSession>) -> Binding<Int> {
        Binding(
            get: { scheduleDraft?.lunchDurationMinutes ?? 0 },
            set: { minutes in
                guard var updatedDraft = scheduleDraft else { return }
                do {
                    try updatedDraft.setLunchDuration(minutes: minutes)
                    scheduleDraft = updatedDraft
                    var updatedSession = session.wrappedValue
                    applySchedule(updatedDraft, to: &updatedSession)
                    session.wrappedValue = updatedSession
                    invalidFields.removeAll { $0 == .workSchedule }
                } catch {
                    invalidFields = [.workSchedule]
                }
            }
        )
    }

    private func applySchedule(_ draft: WorkScheduleDraft, to session: inout OnboardingSession) {
        session.draft.value.workStart = draft.workStart
        session.draft.value.workEnd = draft.workEnd
        session.draft.value.lunchStart = draft.lunchStart
        session.draft.value.lunchEnd = draft.lunchEnd
        session.draft.value.standardWorkSeconds = draft.effectiveWorkSeconds
    }

    private func scheduleValue(_ field: ScheduleField) -> String {
        guard let scheduleDraft else { return "00:00" }
        switch field {
        case .workStart: return scheduleDraft.workStart
        case .lunchStart: return scheduleDraft.lunchStart
        case .lunchEnd: return scheduleDraft.lunchEnd
        case .workEnd: return scheduleDraft.workEnd
        }
    }

    private func dateForTime(_ value: String) -> Date {
        let parts = value.split(separator: ":").compactMap { Int($0) }
        var components = DateComponents()
        components.year = 2001
        components.month = 1
        components.day = 1
        components.hour = parts.first ?? 0
        components.minute = parts.count > 1 ? parts[1] : 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private func timeString(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
