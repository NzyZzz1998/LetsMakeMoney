import SalaryCore
import UIKit
import UserNotifications

@MainActor
protocol NotificationPermissionControlling {
    func currentStatus() async -> NotificationPreference
    func requestAuthorization() async throws -> NotificationPreference
    func openSystemSettings() async -> Bool
}

@MainActor
final class SystemNotificationPermissionController: NotificationPermissionControlling {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func currentStatus() async -> NotificationPreference {
        map(await center.notificationSettings().authorizationStatus)
    }

    func requestAuthorization() async throws -> NotificationPreference {
        _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        return await currentStatus()
    }

    func openSystemSettings() async -> Bool {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            return false
        }
        return await withCheckedContinuation { continuation in
            UIApplication.shared.open(url, options: [:]) { opened in
                continuation.resume(returning: opened)
            }
        }
    }

    private func map(
        _ status: UNAuthorizationStatus
    ) -> NotificationPreference {
        switch status {
        case .notDetermined:
            return .notRequested
        case .denied:
            return .denied
        case .authorized, .provisional, .ephemeral:
            return .allowed
        @unknown default:
            return .denied
        }
    }
}
