import Foundation

public struct IdentifiedSalarySnapshot: Codable, Equatable, Sendable {
    public let id: String
    public let generatedAt: Date
    public let configurationSchemaVersion: Int
    public let holidayDatasetVersion: String
    public let value: SalarySnapshot
}

public struct ActivityState: Codable, Equatable, Sendable {
    public let snapshotID: String
    public let generatedAt: Date
    public let status: SalaryStatus
    public let todayEarnedMinor: Int64
    public let progressBasisPoints: Int
}

public struct WatchSnapshot: Codable, Equatable, Sendable {
    public let snapshotID: String
    public let generatedAt: Date
    public let status: SalaryStatus
    public let todayEarnedMinor: Int64
    public let progressBasisPoints: Int
    public let remainingSeconds: Int
    public let metric: WatchMetric
}

public struct SharedSnapshotBundle: Codable, Equatable, Sendable {
    public let salary: IdentifiedSalarySnapshot
    public let activity: ActivityState
    public let watch: WatchSnapshot

    public static func make(
        configuration: AppConfiguration,
        salary: SalarySnapshot,
        generatedAt: Date,
        remainingSeconds: Int,
        id: String = UUID().uuidString
    ) -> SharedSnapshotBundle {
        SharedSnapshotBundle(
            salary: IdentifiedSalarySnapshot(
                id: id,
                generatedAt: generatedAt,
                configurationSchemaVersion: configuration.schemaVersion,
                holidayDatasetVersion: configuration.holidayDatasetVersion,
                value: salary
            ),
            activity: ActivityState(
                snapshotID: id,
                generatedAt: generatedAt,
                status: salary.status,
                todayEarnedMinor: salary.todayEarnedMinor,
                progressBasisPoints: salary.progressBasisPoints
            ),
            watch: WatchSnapshot(
                snapshotID: id,
                generatedAt: generatedAt,
                status: salary.status,
                todayEarnedMinor: salary.todayEarnedMinor,
                progressBasisPoints: salary.progressBasisPoints,
                remainingSeconds: max(0, remainingSeconds),
                metric: configuration.watchMetric
            )
        )
    }
}

public protocol SharedSnapshotReading: Sendable {
    func read() async throws -> SharedSnapshotBundle
}

public protocol SharedSnapshotWriting: Sendable {
    func write(_ bundle: SharedSnapshotBundle) async throws
}

public enum SharedSnapshotReadError: Error, Equatable, Sendable {
    case missingSnapshot
    case invalidSnapshot
}

public actor SharedSnapshotStore: SharedSnapshotReading, SharedSnapshotWriting {
    private let directoryURL: URL
    private let fileURL: URL

    public init(directoryURL: URL) {
        self.directoryURL = directoryURL
        self.fileURL = directoryURL.appending(path: "salary-snapshot.json")
    }

    public func write(_ bundle: SharedSnapshotBundle) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(bundle).write(to: fileURL, options: .atomic)
    }

    public func read() throws -> SharedSnapshotBundle {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw SharedSnapshotReadError.missingSnapshot
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        do {
            return try decoder.decode(SharedSnapshotBundle.self, from: Data(contentsOf: fileURL))
        } catch {
            throw SharedSnapshotReadError.invalidSnapshot
        }
    }
}

public enum SharedContainerError: Error, Equatable, Sendable {
    case appGroupUnavailable
}

public protocol SharedContainerProviding: Sendable {
    func containerURL() throws -> URL
}

public struct FixedContainerProvider: SharedContainerProviding {
    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func containerURL() throws -> URL { url }
}

public struct AppGroupContainerProvider: SharedContainerProviding {
    private let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }

    public func containerURL() throws -> URL {
        #if os(iOS) || os(macOS) || os(watchOS) || os(tvOS) || os(visionOS)
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) else {
            throw SharedContainerError.appGroupUnavailable
        }
        return url
        #else
        throw SharedContainerError.appGroupUnavailable
        #endif
    }
}
