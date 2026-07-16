import Foundation
import SalaryCore

final class WatchMessageStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let payloadKey = "watch.latest_message"
    private let metricKey = "watch.selected_metric"

    init(appGroupIdentifier: String?) {
        if let appGroupIdentifier,
           let shared = UserDefaults(suiteName: appGroupIdentifier) {
            defaults = shared
        } else {
            defaults = .standard
        }
    }

    func save(_ message: WatchMessageEnvelope) throws {
        defaults.set(try WatchMessageCodec.encode(message), forKey: payloadKey)
    }

    func load() -> WatchMessageEnvelope? {
        guard let data = defaults.data(forKey: payloadKey) else { return nil }
        return try? WatchMessageCodec.decode(data)
    }

    func saveMetric(_ metric: WatchMetric) {
        defaults.set(metric.rawValue, forKey: metricKey)
    }

    func loadMetric() -> WatchMetric {
        defaults.string(forKey: metricKey).flatMap(WatchMetric.init(rawValue:))
            ?? .remainingTime
    }
}
