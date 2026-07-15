import Foundation
import Testing
@testable import SalaryCore

@Suite("App navigation and onboarding")
struct AppFlowTests {
    @Test("navigation keeps one primary destination and modal state")
    func navigationState() {
        var state = AppNavigationState()
        #expect(state.destination == .today)
        #expect(state.modal == nil)

        state.select(.calendar)
        state.present(.settings)
        #expect(state.destination == .calendar)
        #expect(state.modal == .settings)

        state.dismissModal()
        #expect(state.modal == nil)
    }

    @Test("first-launch cancellation requires confirmation and preserves draft")
    func firstLaunchCancellation() {
        var session = OnboardingSession(configuration: configured(), mode: .firstLaunch)
        session.draft.value.monthlySalaryMinor = 1_500_000

        #expect(session.cancel() == .requiresExitConfirmation)
        #expect(session.draft.value.monthlySalaryMinor == 1_500_000)
    }

    @Test("reconfiguration cancellation restores effective configuration")
    func reconfigurationCancellation() {
        let original = configured()
        var session = OnboardingSession(configuration: original, mode: .reconfiguration)
        session.draft.value.monthlySalaryMinor = 1_500_000

        #expect(session.cancel() == .dismissed)
        #expect(session.draft.value == original)
    }

    @Test("step validation blocks invalid salary and schedule")
    func stepValidation() {
        var session = OnboardingSession(configuration: .defaultValue, mode: .firstLaunch)
        #expect(session.advance() == .invalid([.monthlySalary]))
        #expect(session.step == .compensation)

        session.draft.value.monthlySalaryMinor = 1_200_000
        #expect(session.advance() == .advanced(.schedule))

        session.draft.value.lunchEnd = "19:00"
        #expect(session.advance() == .invalid([.workSchedule]))
        #expect(session.step == .schedule)
    }

    @Test("back keeps edits and completion failure remains retryable")
    func retryableCompletion() {
        var session = OnboardingSession(configuration: configured(), mode: .firstLaunch)
        #expect(session.advance() == .advanced(.schedule))
        session.draft.value.workStart = "09:00"
        session.draft.value.lunchStart = "12:00"
        session.draft.value.lunchEnd = "14:00"
        session.draft.value.workEnd = "19:00"
        #expect(session.advance() == .advanced(.summary))

        session.moveBack()
        #expect(session.step == .schedule)
        #expect(session.draft.value.workStart == "09:00")
        #expect(session.advance() == .advanced(.summary))

        session.recordCompletionFailure("disk-full")
        #expect(session.completionFailureReason == "disk-full")
        #expect(session.step == .summary)
        session.clearCompletionFailure()
        #expect(session.completionFailureReason == nil)
    }

    private func configured() -> AppConfiguration {
        var value = AppConfiguration.defaultValue
        value.monthlySalaryMinor = 1_200_000
        return value
    }
}
