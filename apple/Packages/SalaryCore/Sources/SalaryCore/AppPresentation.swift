import Foundation

public enum AppPresentation: Equatable, Sendable {
    case unconfigured
    case error(SalaryCoreError)
    case ready(SalarySnapshot, isHolidayDataOutOfRange: Bool)

    public static func build(
        configuration: AppConfiguration,
        snapshot: SalarySnapshot?,
        failure: SalaryCoreError?
    ) -> AppPresentation {
        if let failure { return .error(failure) }
        guard configuration.monthlySalaryMinor > 0 else { return .unconfigured }
        guard let snapshot else { return .error(.invalidConfiguration) }
        return .ready(
            snapshot,
            isHolidayDataOutOfRange: snapshot.warnings.contains(.holidayDatasetOutOfRange)
        )
    }
}
