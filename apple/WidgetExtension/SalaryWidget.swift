import Foundation
import SalaryCore
import SwiftUI
import WidgetKit

struct SalaryWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedSnapshotBundle?
}

struct SalaryWidgetProvider: TimelineProvider {
    private let reader: any SharedSnapshotReading

    init(reader: any SharedSnapshotReading = WidgetSnapshotReader.make()) {
        self.reader = reader
    }

    func placeholder(in context: Context) -> SalaryWidgetEntry {
        SalaryWidgetEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SalaryWidgetEntry) -> Void) {
        load(completion: completion)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SalaryWidgetEntry>) -> Void) {
        load { entry in
            completion(Timeline(
                entries: [entry],
                policy: .after(entry.date.addingTimeInterval(15 * 60))
            ))
        }
    }

    private func load(completion: @escaping (SalaryWidgetEntry) -> Void) {
        let timelineCompletion = WidgetTimelineCompletion(completion)
        Task {
            timelineCompletion.call(
                SalaryWidgetEntry(date: Date(), snapshot: try? await reader.read())
            )
        }
    }
}

private final class WidgetTimelineCompletion<Value>: @unchecked Sendable {
    private let callback: (Value) -> Void

    init(_ callback: @escaping (Value) -> Void) {
        self.callback = callback
    }

    func call(_ value: Value) {
        callback(value)
    }
}

private enum WidgetSnapshotReader {
    static func make(bundle: Bundle = .main) -> any SharedSnapshotReading {
        guard let identifier = bundle.object(
            forInfoDictionaryKey: "LMMAppGroupIdentifier"
        ) as? String,
              !identifier.isEmpty,
              let directoryURL = try? AppGroupContainerProvider(
                  identifier: identifier
              ).containerURL()
        else { return MissingSharedSnapshotReader() }
        return SharedSnapshotStore(directoryURL: directoryURL)
    }
}

private struct MissingSharedSnapshotReader: SharedSnapshotReading {
    func read() async throws -> SharedSnapshotBundle {
        throw SharedContainerError.appGroupUnavailable
    }
}

struct SalaryWidgetView: View {
    let entry: SalaryWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("today.amount")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let snapshot = entry.snapshot {
                Text(amount(snapshot.salary.value.todayEarnedMinor))
                    .font(.title2.weight(.semibold).monospacedDigit())
                Text(LocalizedStringKey("status.\(snapshot.salary.value.status.rawValue)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("state.configure")
                    .font(.subheadline.weight(.medium))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.background, for: .widget)
    }

    private func amount(_ minor: Int64) -> String {
        (Double(minor) / 100).formatted(
            .currency(code: "CNY").precision(.fractionLength(2))
        )
    }
}

struct SalaryWidget: Widget {
    let kind = "LetsMakeMoneySalaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalaryWidgetProvider()) { entry in
            SalaryWidgetView(entry: entry)
        }
        .configurationDisplayName("app.title")
        .description("today.amount")
        .supportedFamilies([.systemSmall])
    }
}
