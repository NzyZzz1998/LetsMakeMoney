import SalaryCore
import SwiftUI

@MainActor
enum PreviewSupport {
    static func unconfiguredModel() -> AppModel {
        makeModel(suffix: "unconfigured")
    }

    static func model() -> AppModel {
        let model = makeModel(suffix: "configured")
        var configuration = AppConfiguration.defaultValue
        configuration.monthlySalaryMinor = 1_200_000
        model.seedPreview(
            configuration: configuration,
            snapshot: SalarySnapshot(
                monthPaidWorkdays: 22,
                dailySalaryMinor: 54_545,
                standardHourlySalaryMinor: 6_818,
                todayEarnedMinor: 18_642,
                monthEarnedMinor: 384_200,
                completedEffectiveSeconds: 14_400,
                progressBasisPoints: 5_600,
                status: .working,
                warnings: []
            )
        )
        return model
    }

    private static func makeModel(suffix: String) -> AppModel {
        let root = FileManager.default.temporaryDirectory.appending(path: "lmm-preview-\(suffix)")
        return AppModel(
            store: ConfigurationStore(directoryURL: root),
            logger: LocalEventLogger(directoryURL: root),
            holidays: HolidayDataLoader.load()
        )
    }
}
