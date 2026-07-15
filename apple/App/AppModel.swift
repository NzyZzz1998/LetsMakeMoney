import Foundation
import SalaryCore
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var configuration: AppConfiguration = .defaultValue
    @Published private(set) var presentation: AppPresentation = .unconfigured
    @Published var navigation = AppNavigationState()
    @Published var feedbackKey: String?
    @Published var selectedDate: Date?

    private let store: ConfigurationStore
    private let logger: LocalEventLogger
    private let holidays: HolidayCalendar
    private let timeZone: TimeZone

    init(
        store: ConfigurationStore,
        logger: LocalEventLogger,
        holidays: HolidayCalendar,
        timeZone: TimeZone = .current
    ) {
        self.store = store
        self.logger = logger
        self.holidays = holidays
        self.timeZone = timeZone
    }

    func load(now: Date = Date()) async {
        do {
            let result = try await store.load()
            configuration = result.configuration
            refresh(now: now)
            if configuration.monthlySalaryMinor <= 0 { present(.onboarding) }
            try? await logger.record(level: .info, event: "app.configuration.loaded")
        } catch {
            presentation = .error(.invalidConfiguration)
            try? await logger.record(level: .error, event: "app.configuration.load_failed")
        }
    }

    func refresh(now: Date = Date()) {
        do {
            let snapshot = try SalaryCalculator.calculate(
                configuration: configuration,
                now: now,
                timeZone: timeZone,
                holidays: holidays
            )
            presentation = AppPresentation.build(configuration: configuration, snapshot: snapshot, failure: nil)
        } catch let error as SalaryCoreError {
            presentation = AppPresentation.build(configuration: configuration, snapshot: nil, failure: error)
        } catch {
            presentation = .error(.invalidConfiguration)
        }
    }

    func save(_ value: AppConfiguration, now: Date = Date()) async -> Bool {
        do {
            switch try await store.save(value) {
            case .saved:
                configuration = value
                feedbackKey = "feedback.saved"
                try? await logger.record(level: .info, event: "settings.saved")
            case .unchanged:
                feedbackKey = "feedback.unchanged"
                try? await logger.record(level: .info, event: "settings.unchanged")
            }
            refresh(now: now)
            return true
        } catch {
            feedbackKey = "feedback.save_failed"
            try? await logger.record(level: .error, event: "settings.save_failed")
            return false
        }
    }

    func calendarDay(for date: Date) -> SalaryCalendarDay? {
        try? SalaryCalendarResolver.resolve(
            date: date,
            configuration: configuration,
            holidays: holidays,
            timeZone: timeZone
        )
    }

    func preview(configuration: AppConfiguration, now: Date = Date()) -> SalarySnapshot? {
        try? SalaryCalculator.calculate(
            configuration: configuration,
            now: now,
            timeZone: timeZone,
            holidays: holidays
        )
    }

    func select(_ destination: AppDestination) { navigation.select(destination) }
    func present(_ modal: AppModal) { navigation.present(modal) }
    func dismissModal() { navigation.dismissModal() }

    func seedPreview(configuration: AppConfiguration, snapshot: SalarySnapshot) {
        self.configuration = configuration
        self.presentation = .ready(snapshot, isHolidayDataOutOfRange: false)
    }
}
