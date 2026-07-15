import AppIntents
import SwiftUI
import WidgetKit

struct SalaryActivityControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "LetsMakeMoneySalaryActivityControl") {
            ControlWidgetButton(action: ToggleSalaryActivityIntent()) {
                Label("activity.control.title", systemImage: "timer")
            }
        }
        .displayName("activity.control.title")
        .description("activity.control.description")
    }
}
