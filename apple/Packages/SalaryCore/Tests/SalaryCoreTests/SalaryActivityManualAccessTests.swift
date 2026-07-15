import Foundation
import Testing
@testable import SalaryCore

@Suite("Live Activity manual access")
struct SalaryActivityManualAccessTests {
    @Test("Notification denial never disables a valid manual start")
    func deniedNotificationStillAllowsManualStart() {
        let decision = SalaryActivityManualAccessPolicy.decision(
            notificationPreference: .denied,
            activitiesEnabled: true,
            hasLaunchContext: true,
            hasActiveActivity: false
        )

        #expect(decision == .start)
    }

    @Test("An active activity changes the manual action to stop")
    func activeActivityStops() {
        let decision = SalaryActivityManualAccessPolicy.decision(
            notificationPreference: .notRequested,
            activitiesEnabled: true,
            hasLaunchContext: true,
            hasActiveActivity: true
        )

        #expect(decision == .stop)
    }

    @Test("System and snapshot failures remain explainable")
    func unavailableReasons() {
        #expect(SalaryActivityManualAccessPolicy.decision(
            notificationPreference: .allowed,
            activitiesEnabled: false,
            hasLaunchContext: true,
            hasActiveActivity: false
        ) == .unavailable(.activitiesDisabled))

        #expect(SalaryActivityManualAccessPolicy.decision(
            notificationPreference: .allowed,
            activitiesEnabled: true,
            hasLaunchContext: false,
            hasActiveActivity: false
        ) == .unavailable(.missingLaunchContext))
    }
}

