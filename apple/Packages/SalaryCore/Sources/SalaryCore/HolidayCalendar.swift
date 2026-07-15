import Foundation

public struct OfficialHolidayDataset: Codable, Equatable, Sendable {
    public let year: Int
    public let status: String
    public let documentId: String
    public let publishedAt: String
    public let sourceUrl: String
    public let holidays: [String]
    public let adjustedWorkdays: [String]

    public init(
        year: Int,
        status: String,
        documentId: String,
        publishedAt: String,
        sourceUrl: String,
        holidays: [String],
        adjustedWorkdays: [String]
    ) {
        self.year = year
        self.status = status
        self.documentId = documentId
        self.publishedAt = publishedAt
        self.sourceUrl = sourceUrl
        self.holidays = holidays
        self.adjustedWorkdays = adjustedWorkdays
    }
}

public struct HolidayCalendar: Sendable {
    public let version: String
    public let coveredYears: Set<Int>
    private let holidays: Set<String>
    private let adjustedWorkdays: Set<String>

    public init(
        version: String,
        officialDatasets: [OfficialHolidayDataset],
        coveredYears: Set<Int>
    ) {
        self.version = version
        self.coveredYears = coveredYears
        self.holidays = Set(officialDatasets.flatMap(\.holidays))
        self.adjustedWorkdays = Set(officialDatasets.flatMap(\.adjustedWorkdays))
    }

    func officialRule(for dateKey: String, year: Int) -> Bool? {
        guard coveredYears.contains(year) else { return nil }
        if holidays.contains(dateKey) { return false }
        if adjustedWorkdays.contains(dateKey) { return true }
        return nil
    }
}
