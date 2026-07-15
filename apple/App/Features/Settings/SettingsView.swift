import SalaryCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ConfigurationDraft?

    var body: some View {
        NavigationStack {
            Form {
                if let binding = draftBinding {
                    Section("settings.salary") {
                        TextField("settings.monthly_salary", text: salaryBinding(binding))
                            .keyboardType(.decimalPad)
                        Picker("settings.rest_mode", selection: binding.value.restMode) {
                            Text("rest.double_weekend").tag(RestMode.doubleWeekend)
                            Text("rest.single_weekend").tag(RestMode.singleWeekend)
                            Text("rest.alternating_weekend").tag(RestMode.alternatingWeekend)
                        }
                    }
                    Section("settings.schedule") {
                        scheduleField("schedule.work_start", binding, \.workStart)
                        scheduleField("schedule.lunch_start", binding, \.lunchStart)
                        scheduleField("schedule.lunch_end", binding, \.lunchEnd)
                        scheduleField("schedule.work_end", binding, \.workEnd)
                    }
                    Section("settings.notifications") {
                        LabeledContent("settings.notification_status") {
                            Text(LocalizedStringKey("notification.\(model.notificationStatus.rawValue)"))
                        }
                        switch NotificationPermissionPolicy.primaryAction(for: model.notificationStatus) {
                        case .requestAuthorization:
                            Button("notification.request") {
                                Task { await model.requestNotificationAuthorization() }
                            }
                        case .openSystemSettings:
                            Button("notification.open_settings") {
                                Task { await model.openNotificationSettings() }
                            }
                        case .none:
                            EmptyView()
                        }
                    }
                    Section("settings.system") {
                        LabeledContent("settings.holiday_version", value: binding.value.holidayDatasetVersion.wrappedValue)
                        Button("settings.reconfigure") { model.present(.onboarding); dismiss() }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(WarmPalette.canvas)
            .navigationTitle("nav.settings")
            .accessibilityIdentifier("settings.root")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { draft?.cancel(); dismiss() }
                        .accessibilityIdentifier("settings.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { Task { await save() } }
                        .accessibilityIdentifier("settings.save")
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let key = model.feedbackKey {
                    Text(LocalizedStringKey(key))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(key == "feedback.save_failed" ? WarmPalette.danger : WarmPalette.mint)
                        .padding(10)
                        .accessibilityLabel(LocalizedStringKey(key))
                }
            }
        }
        .onAppear { draft = ConfigurationDraft(original: model.configuration) }
    }

    private var draftBinding: Binding<ConfigurationDraft>? {
        guard draft != nil else { return nil }
        return Binding(get: { draft! }, set: { draft = $0 })
    }

    private func salaryBinding(_ draft: Binding<ConfigurationDraft>) -> Binding<String> {
        Binding(
            get: { String(format: "%.2f", Double(draft.value.monthlySalaryMinor.wrappedValue) / 100) },
            set: { draft.value.monthlySalaryMinor.wrappedValue = Int64((Double($0) ?? 0) * 100) }
        )
    }

    private func scheduleField(
        _ key: String,
        _ draft: Binding<ConfigurationDraft>,
        _ field: WritableKeyPath<AppConfiguration, String>
    ) -> some View {
        HStack {
            Text(LocalizedStringKey(key))
            Spacer()
            TextField("time.placeholder", text: Binding(
                get: { draft.value.wrappedValue[keyPath: field] },
                set: { newValue in
                    var updated = draft.wrappedValue
                    updated.value[keyPath: field] = newValue
                    updateEffectiveHours(&updated.value)
                    draft.wrappedValue = updated
                }
            ))
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(maxWidth: 92)
        }
    }

    private func updateEffectiveHours(_ configuration: inout AppConfiguration) {
        if let seconds = try? WorkScheduleMetrics.effectiveWorkSeconds(
            workStart: configuration.workStart,
            workEnd: configuration.workEnd,
            lunchStart: configuration.lunchStart,
            lunchEnd: configuration.lunchEnd
        ) {
            configuration.standardWorkSeconds = seconds
        }
    }

    private func save() async {
        guard var draft else { return }
        if await model.save(draft.value) {
            draft.acceptSavedValue()
            self.draft = draft
        }
    }
}
