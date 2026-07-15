public enum NotificationPermissionAction: Equatable, Sendable {
    case requestAuthorization
    case openSystemSettings
    case none
}

public enum NotificationPermissionPolicy {
    public static func primaryAction(
        for status: NotificationPreference
    ) -> NotificationPermissionAction {
        switch status {
        case .notRequested:
            return .requestAuthorization
        case .denied:
            return .openSystemSettings
        case .allowed:
            return .none
        }
    }
}
