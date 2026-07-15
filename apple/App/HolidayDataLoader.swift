import Foundation
import SalaryCore

enum HolidayDataLoader {
    static func load(bundle: Bundle = .main) -> HolidayCalendar {
        let decoder = JSONDecoder()
        let datasets = [2025, 2026].compactMap { year -> OfficialHolidayDataset? in
            guard let url = bundle.url(forResource: "cn-\(year)", withExtension: "json") else {
                return nil
            }
            return try? decoder.decode(OfficialHolidayDataset.self, from: Data(contentsOf: url))
        }
        return HolidayCalendar(
            version: "cn-mainland-2025-2026-v1",
            officialDatasets: datasets,
            coveredYears: Set(datasets.map(\.year))
        )
    }
}
