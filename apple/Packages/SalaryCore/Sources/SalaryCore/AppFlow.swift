import Foundation

public enum AppDestination: String, Codable, CaseIterable, Sendable {
    case today
    case calendar
}
public enum AppModal: String, Codable, Sendable {
    case settings
    case onboarding
    case dateOverride
}

public struct AppNavigationState: Equatable, Sendable {
    public private(set) var destination: AppDestination
    public private(set) var modal: AppModal?

    public init(destination: AppDestination = .today, modal: AppModal? = nil) {
        self.destination = destination
        self.modal = modal
    }

    public mutating func select(_ destination: AppDestination) {
        self.destination = destination
    }

    public mutating func present(_ modal: AppModal) {
        self.modal = modal
    }

    public mutating func dismissModal() {
        modal = nil
    }
}

public enum OnboardingMode: String, Sendable {
    case firstLaunch
    case reconfiguration
}

public enum OnboardingStep: Int, CaseIterable, Sendable {
    case compensation = 1
    case schedule = 2
    case summary = 3
}

public enum OnboardingField: String, Equatable, Sendable {
    case monthlySalary
    case currency
    case alternatingAnchor
    case workSchedule
}

public enum OnboardingAdvanceResult: Equatable, Sendable {
    case advanced(OnboardingStep)
    case readyToComplete
    case invalid([OnboardingField])
}

public enum OnboardingCancelResult: Equatable, Sendable {
    case requiresExitConfirmation
    case dismissed
}

public struct OnboardingSession: Equatable, Sendable {
    public let mode: OnboardingMode
    public private(set) var step: OnboardingStep
    public var draft: ConfigurationDraft
    public private(set) var completionFailureReason: String?

    public init(
        configuration: AppConfiguration,
        mode: OnboardingMode,
        step: OnboardingStep = .compensation
    ) {
        self.mode = mode
        self.step = step
        self.draft = ConfigurationDraft(original: configuration)
        self.completionFailureReason = nil
    }

    public mutating func advance() -> OnboardingAdvanceResult {
        let invalid = invalidFields(for: step)
        guard invalid.isEmpty else { return .invalid(invalid) }
        completionFailureReason = nil
        switch step {
        case .compensation:
            step = .schedule
            return .advanced(.schedule)
        case .schedule:
            step = .summary
            return .advanced(.summary)
        case .summary:
            return .readyToComplete
        }
    }

    public mutating func moveBack() {
        completionFailureReason = nil
        switch step {
        case .compensation: break
        case .schedule: step = .compensation
        case .summary: step = .schedule
        }
    }

    public mutating func cancel() -> OnboardingCancelResult {
        completionFailureReason = nil
        if mode == .firstLaunch {
            return .requiresExitConfirmation
        }
        draft.cancel()
        step = .compensation
        return .dismissed
    }

    public mutating func recordCompletionFailure(_ reason: String) {
        completionFailureReason = reason
    }

    public mutating func clearCompletionFailure() {
        completionFailureReason = nil
    }

    private func invalidFields(for step: OnboardingStep) -> [OnboardingField] {
        switch step {
        case .compensation:
            var fields: [OnboardingField] = []
            if draft.value.monthlySalaryMinor <= 0 { fields.append(.monthlySalary) }
            if draft.value.currencyCode.count != 3 { fields.append(.currency) }
            if draft.value.restMode == .alternatingWeekend,
               draft.value.validationIssues().contains(where: { $0.field == "alternatingAnchor" }) {
                fields.append(.alternatingAnchor)
            }
            return fields
        case .schedule:
            return draft.value.validationIssues().contains(where: { $0.field == "workSchedule" })
                ? [.workSchedule]
                : []
        case .summary:
            return []
        }
    }
}
