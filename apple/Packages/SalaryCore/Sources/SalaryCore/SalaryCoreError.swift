import Foundation

public enum SalaryCoreError: String, Error, Codable, Equatable, Sendable {
    case unsupportedSchemaVersion
    case invalidConfiguration
    case missingAlternatingAnchor
    case invalidTimeRange
    case duplicateDateOverride
    case noPaidWorkdays
    case holidayDatasetMismatch
}

public extension SalaryCoreError {
    var localizationKey: String {
        switch self {
        case .unsupportedSchemaVersion: "salary.error.unsupported_schema"
        case .invalidConfiguration: "salary.error.invalid_configuration"
        case .missingAlternatingAnchor: "salary.error.missing_alternating_anchor"
        case .invalidTimeRange: "salary.error.invalid_time_range"
        case .duplicateDateOverride: "salary.error.duplicate_date_override"
        case .noPaidWorkdays: "salary.error.no_paid_workdays"
        case .holidayDatasetMismatch: "salary.error.holiday_dataset_mismatch"
        }
    }
}
