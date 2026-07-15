import Testing
@testable import SalaryCore

@Suite("Notification permission policy")
struct NotificationPermissionPolicyTests {
    @Test("First request is only offered before the system prompt has been answered")
    func firstRequestOnlyWhenNotRequested() {
        #expect(
            NotificationPermissionPolicy.primaryAction(for: .notRequested)
                == .requestAuthorization
        )
        #expect(
            NotificationPermissionPolicy.primaryAction(for: .denied)
                != .requestAuthorization
        )
        #expect(
            NotificationPermissionPolicy.primaryAction(for: .allowed)
                != .requestAuthorization
        )
    }

    @Test("Denied permission routes to system settings instead of prompting again")
    func deniedRoutesToSettings() {
        #expect(
            NotificationPermissionPolicy.primaryAction(for: .denied)
                == .openSystemSettings
        )
    }

    @Test("Allowed permission needs no primary recovery action")
    func allowedNeedsNoAction() {
        #expect(
            NotificationPermissionPolicy.primaryAction(for: .allowed)
                == .none
        )
    }
}
