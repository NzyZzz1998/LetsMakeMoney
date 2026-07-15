import Foundation

public struct DateOverrideEditor: Equatable, Sendable {
    public let date: String
    public private(set) var original: SalaryDateOverride?
    public var value: SalaryDateOverride

    public init(date: String, existing: SalaryDateOverride?) {
        self.date = date
        self.original = existing
        self.value = existing ?? SalaryDateOverride(
            date: date,
            isWorkday: true,
            isPaid: true,
            effectiveWorkSeconds: nil
        )
    }

    public var hasChanges: Bool { value != original }

    public mutating func save(into configuration: inout AppConfiguration) {
        configuration.dateOverrides.removeAll { $0.date == date }
        configuration.dateOverrides.append(value)
        configuration.dateOverrides.sort { $0.date < $1.date }
        original = value
    }

    @discardableResult
    public mutating func delete(from configuration: inout AppConfiguration) -> Bool {
        let previousCount = configuration.dateOverrides.count
        configuration.dateOverrides.removeAll { $0.date == date }
        original = nil
        value = SalaryDateOverride(date: date, isWorkday: true, isPaid: true)
        return configuration.dateOverrides.count != previousCount
    }

    public mutating func cancel() {
        value = original ?? SalaryDateOverride(date: date, isWorkday: true, isPaid: true)
    }
}
