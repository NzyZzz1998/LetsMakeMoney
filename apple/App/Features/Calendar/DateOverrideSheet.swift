import SalaryCore
import SwiftUI

struct DateOverrideSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var editor: DateOverrideEditor
    @State private var showSaveConfirmation = false
    @State private var showDeleteConfirmation = false

    init(date: Date) {
        let key = date.formatted(.iso8601.year().month().day().dateSeparator(.dash))
        _editor = State(initialValue: DateOverrideEditor(date: key, existing: nil))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("calendar.override") {
                    Toggle("calendar.is_workday", isOn: $editor.value.isWorkday)
                    Toggle("calendar.is_paid", isOn: $editor.value.isPaid)
                    Stepper(
                        "calendar.effective_hours",
                        value: effectiveHours,
                        in: 1...16
                    )
                }
                if editor.original != nil {
                    Button("common.delete", role: .destructive) { showDeleteConfirmation = true }
                }
            }
            .navigationTitle(editor.date)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { editor.cancel(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { showSaveConfirmation = true }.disabled(!editor.hasChanges)
                }
            }
            .confirmationDialog("calendar.confirm_change", isPresented: $showSaveConfirmation) {
                Button("common.save") { Task { await save() } }
                Button("common.cancel", role: .cancel) {}
            }
            .confirmationDialog("calendar.confirm_delete", isPresented: $showDeleteConfirmation) {
                Button("common.delete", role: .destructive) { Task { await delete() } }
                Button("common.cancel", role: .cancel) {}
            }
        }
        .onAppear {
            let existing = model.configuration.dateOverrides.first { $0.date == editor.date }
            editor = DateOverrideEditor(date: editor.date, existing: existing)
        }
    }

    private var effectiveHours: Binding<Int> {
        Binding(
            get: { (editor.value.effectiveWorkSeconds ?? model.configuration.standardWorkSeconds) / 3_600 },
            set: { editor.value.effectiveWorkSeconds = $0 * 3_600 }
        )
    }

    private func save() async {
        var value = model.configuration
        editor.save(into: &value)
        if await model.save(value) { dismiss() }
    }

    private func delete() async {
        var value = model.configuration
        _ = editor.delete(from: &value)
        if await model.save(value) { dismiss() }
    }
}
