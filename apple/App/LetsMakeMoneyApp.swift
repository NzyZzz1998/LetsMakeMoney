import SalaryCore
import SwiftUI

@main
struct LetsMakeMoneyApp: App {
    @StateObject private var model: AppModel

    init() {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "LetsMakeMoney")
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ui-test-reset-configuration") {
            try? FileManager.default.removeItem(at: root.appending(path: "config.json"))
        }
        if arguments.contains("-ui-test-configured") {
            try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            var configuration = AppConfiguration.defaultValue
            configuration.monthlySalaryMinor = 1_200_000
            if let data = try? ConfigurationCodec().encode(configuration) {
                try? data.write(to: root.appending(path: "config.json"), options: .atomic)
            }
        }
        let holidays = HolidayDataLoader.load()
        let sharedSnapshotWriter = Self.makeSharedSnapshotWriter()
        _model = StateObject(wrappedValue: AppModel(
            store: ConfigurationStore(directoryURL: root),
            logger: LocalEventLogger(directoryURL: root),
            holidays: holidays,
            sharedSnapshotWriter: sharedSnapshotWriter
        ))
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(model)
                .task { await model.load() }
        }
    }

    private static func makeSharedSnapshotWriter() -> (any SharedSnapshotWriting)? {
        guard let identifier = Bundle.main.object(
            forInfoDictionaryKey: "LMMAppGroupIdentifier"
        ) as? String,
              !identifier.isEmpty,
              let directoryURL = try? AppGroupContainerProvider(
                  identifier: identifier
              ).containerURL()
        else { return nil }
        return SharedSnapshotStore(directoryURL: directoryURL)
    }
}
