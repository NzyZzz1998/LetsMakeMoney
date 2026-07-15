import Foundation
@testable import SalaryCore

enum TestSupport {
    static let shanghai = TimeZone(identifier: "Asia/Shanghai")!

    static var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static var contractRoot: URL {
        repositoryRoot.appending(path: "shared/salary-schema/v1")
    }

    static func localDate(_ value: String, timeZone: TimeZone = shanghai) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: value)!
    }

    static func holidayCalendar() throws -> HolidayCalendar {
        let decoder = JSONDecoder()
        let files = ["cn-2025.json", "cn-2026.json"].map {
            contractRoot.appending(path: "holidays/\($0)")
        }
        let datasets = try files.map { url in
            try decoder.decode(OfficialHolidayDataset.self, from: Data(contentsOf: url))
        }
        return HolidayCalendar(
            version: "cn-mainland-2025-2026-v1",
            officialDatasets: datasets,
            coveredYears: [2025, 2026]
        )
    }
}
