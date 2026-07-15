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
    @Published private(set) var notificationStatus: NotificationPreference = .notRequested

    private let store: ConfigurationStore
    private let logger: LocalEventLogger
    private let holidays: HolidayCalendar
    private let timeZone: TimeZone
    private let sharedSnapshotWriter: (any SharedSnapshotWriting)?
    private let notificationController: any NotificationPermissionControlling

    init(
        store: ConfigurationStore,
        logger: LocalEventLogger,
        holidays: HolidayCalendar,
        timeZone: TimeZone = .current,
        sharedSnapshotWriter: (any SharedSnapshotWriting)? = nil,
        notificationController: any NotificationPermissionControlling = SystemNotificationPermissionController()
    ) {
        self.store = store
        self.logger = logger
        self.holidays = holidays
        self.timeZone = timeZone
        self.sharedSnapshotWriter = sharedSnapshotWriter
        self.notificationController = notificationController
    }

    func load(now: Date = Date()) async {
        await refreshNotificationStatus()
        do {
            let result = try await store.load()
            configuration = result.configuration
            let snapshot = refresh(now: now)
            await publishSharedSnapshot(snapshot, generatedAt: now)
            if configuration.monthlySalaryMinor <= 0 { present(.onboarding) }
            try? await logger.record(level: .info, event: "app.configuration.loaded")
        } catch {
            presentation = .error(.invalidConfiguration)
            try? await logger.record(level: .error, event: "app.configuration.load_failed")
        }
    }

    @discardableResult
    func refresh(now: Date = Date()) -> SalarySnapshot? {
        do {
            let snapshot = try SalaryCalculator.calculate(
                configuration: configuration,
                now: now,
                timeZone: timeZone,
                holidays: holidays
            )
            presentation = AppPresentation.build(configuration: configuration, snapshot: snapshot, failure: nil)
            return snapshot
        } catch let error as SalaryCoreError {
            presentation = AppPresentation.build(configuration: configuration, snapshot: nil, failure: error)
            return nil
        } catch {
            presentation = .error(.invalidConfiguration)
            return nil
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
            let snapshot = refresh(now: now)
            await publishSharedSnapshot(snapshot, generatedAt: now)
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

    func refreshNotificationStatus() async {
        notificationStatus = await notificationController.currentStatus()
        try? await logger.record(
            level: .info,
            event: "notification.status_refreshed",
            metadata: ["status": notificationStatus.rawValue]
        )
    }

    func requestNotificationAuthorization() async {
        guard NotificationPermissionPolicy.primaryAction(for: notificationStatus)
            == .requestAuthorization
        else { return }
        do {
            notificationStatus = try await notificationController.requestAuthorization()
            feedbackKey = nil
            try? await logger.record(
                level: .info,
                event: "notification.request_succeeded",
                metadata: ["status": notificationStatus.rawValue]
            )
        } catch {
            feedbackKey = "notification.request_failed"
            try? await logger.record(level: .error, event: "notification.request_failed")
        }
    }

    func openNotificationSettings() async {
        guard NotificationPermissionPolicy.primaryAction(for: notificationStatus)
            == .openSystemSettings
        else { return }
        if await notificationController.openSystemSettings() {
            feedbackKey = nil
            try? await logger.record(level: .info, event: "notification.settings_opened")
        } else {
            feedbackKey = "notification.settings_failed"
            try? await logger.record(level: .error, event: "notification.settings_open_failed")
        }
    }

    private func publishSharedSnapshot(_ snapshot: SalarySnapshot?, generatedAt: Date) async {
        guard let snapshot, let sharedSnapshotWriter else { return }
        let bundle = SharedSnapshotBundle.make(
            configuration: configuration,
            salary: snapshot,
            generatedAt: generatedAt,
            remainingSeconds: 0
        )
        do {
            try await sharedSnapshotWriter.write(bundle)
            try? await logger.record(level: .info, event: "shared_snapshot.published")
        } catch {
            try? await logger.record(level: .warning, event: "shared_snapshot.publish_failed")
        }
    }

    func seedPreview(configuration: AppConfiguration, snapshot: SalarySnapshot) {
        self.configuration = configuration
        self.presentation = .ready(snapshot, isHolidayDataOutOfRange: false)
    }
}
