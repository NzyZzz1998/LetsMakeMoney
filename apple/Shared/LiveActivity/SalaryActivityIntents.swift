import AppIntents
import SalaryCore

struct StartSalaryActivityIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "activity.intent.start.title"
    static let description = IntentDescription("activity.intent.start.description")

    func perform() async throws -> some IntentResult {
        _ = await SystemSalaryActivityCoordinator().start()
        return .result()
    }
}

struct StopSalaryActivityIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "activity.intent.stop.title"
    static let description = IntentDescription("activity.intent.stop.description")

    func perform() async throws -> some IntentResult {
        _ = await SystemSalaryActivityCoordinator().stop()
        return .result()
    }
}

struct ToggleSalaryActivityIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "activity.intent.toggle.title"
    static let description = IntentDescription("activity.intent.toggle.description")

    func perform() async throws -> some IntentResult {
        _ = await SystemSalaryActivityCoordinator().toggle(
            notificationPreference: .notRequested
        )
        return .result()
    }
}
