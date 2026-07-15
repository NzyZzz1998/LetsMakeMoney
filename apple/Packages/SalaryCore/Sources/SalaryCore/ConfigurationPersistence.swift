import Foundation

public enum ConfigurationPersistenceError: Error, Equatable, Sendable {
    case malformedDocument
    case missingSchemaVersion
    case unsupportedLegacyVersion(Int)
    case futureSchemaVersion(Int)
    case unknownField(String)
    case validationFailed([ConfigurationValidationIssue])
    case readBackMismatch
    case commitFailed
}

public struct DecodedConfiguration: Equatable, Sendable {
    public let configuration: AppConfiguration
    public let migratedFromVersion: Int?
}

public struct ConfigurationCodec: Sendable {
    private let configurationKeys: Set<String> = [
        "schemaVersion", "monthlySalaryMinor", "currencyCode", "restMode",
        "alternatingAnchor", "workStart", "workEnd", "lunchStart", "lunchEnd",
        "standardWorkSeconds", "dateOverrides", "holidayDatasetVersion",
        "notificationPreference", "watchMetric"
    ]
    private let legacyKeys: Set<String> = [
        "schemaVersion", "monthlySalaryMinor", "currencyCode", "restMode",
        "alternatingAnchor", "workStart", "workEnd", "lunchStart", "lunchEnd",
        "standardWorkSeconds", "dateOverrides"
    ]
    private let overrideKeys: Set<String> = ["date", "isWorkday", "isPaid", "effectiveWorkSeconds"]

    public init() {}

    public func encode(_ configuration: AppConfiguration) throws -> Data {
        let issues = configuration.validationIssues()
        guard issues.isEmpty else { throw ConfigurationPersistenceError.validationFailed(issues) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try encoder.encode(configuration)
    }

    public func decode(_ data: Data) throws -> DecodedConfiguration {
        let jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw ConfigurationPersistenceError.malformedDocument
        }
        guard var object = jsonObject as? [String: Any] else {
            throw ConfigurationPersistenceError.malformedDocument
        }
        guard let version = object["schemaVersion"] as? Int else {
            throw ConfigurationPersistenceError.missingSchemaVersion
        }
        if version > 1 { throw ConfigurationPersistenceError.futureSchemaVersion(version) }
        if version < 0 { throw ConfigurationPersistenceError.unsupportedLegacyVersion(version) }

        let allowedKeys = version == 0 ? legacyKeys : configurationKeys
        if let unknown = Set(object.keys).subtracting(allowedKeys).sorted().first {
            throw ConfigurationPersistenceError.unknownField(unknown)
        }
        try validateOverrideKeys(in: object)

        var migratedFromVersion: Int?
        if version == 0 {
            migratedFromVersion = 0
            object["schemaVersion"] = 1
            object["alternatingAnchor"] = object["alternatingAnchor"] ?? NSNull()
            object["holidayDatasetVersion"] = "cn-mainland-2025-2026-v1"
            object["notificationPreference"] = NotificationPreference.notRequested.rawValue
            object["watchMetric"] = WatchMetric.remainingTime.rawValue
        }

        let normalized = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let configuration: AppConfiguration
        do {
            configuration = try JSONDecoder().decode(AppConfiguration.self, from: normalized)
        } catch {
            throw ConfigurationPersistenceError.malformedDocument
        }
        let issues = configuration.validationIssues()
        guard issues.isEmpty else { throw ConfigurationPersistenceError.validationFailed(issues) }
        return DecodedConfiguration(configuration: configuration, migratedFromVersion: migratedFromVersion)
    }

    private func validateOverrideKeys(in object: [String: Any]) throws {
        guard let overrides = object["dateOverrides"] as? [[String: Any]] else { return }
        for override in overrides {
            if let unknown = Set(override.keys).subtracting(overrideKeys).sorted().first {
                throw ConfigurationPersistenceError.unknownField("dateOverrides.\(unknown)")
            }
        }
    }
}

public enum ConfigurationSaveResult: Equatable, Sendable {
    case saved
    case unchanged
}

public struct ConfigurationRecovery: Equatable, Sendable {
    public let backupURL: URL
    public let reason: String
}

public struct ConfigurationLoadOutcome: Equatable, Sendable {
    public let configuration: AppConfiguration
    public let recovery: ConfigurationRecovery?
    public let migratedFromVersion: Int?
    public let migrationBackupURL: URL?
}

public actor ConfigurationStore {
    public typealias BeforeCommit = @Sendable (URL) throws -> Void

    private let directoryURL: URL
    private let fileURL: URL
    private let codec: ConfigurationCodec
    private let beforeCommit: BeforeCommit

    public init(
        directoryURL: URL,
        codec: ConfigurationCodec = ConfigurationCodec(),
        beforeCommit: @escaping BeforeCommit = { _ in }
    ) {
        self.directoryURL = directoryURL
        self.fileURL = directoryURL.appending(path: "config.json")
        self.codec = codec
        self.beforeCommit = beforeCommit
    }

    public func load() throws -> ConfigurationLoadOutcome {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return ConfigurationLoadOutcome(
                configuration: .defaultValue,
                recovery: nil,
                migratedFromVersion: nil,
                migrationBackupURL: nil
            )
        }

        let data = try Data(contentsOf: fileURL)
        do {
            let decoded = try codec.decode(data)
            var migrationBackupURL: URL?
            if let sourceVersion = decoded.migratedFromVersion {
                let backup = backupURL(prefix: "config.migration-v\(sourceVersion)")
                try data.write(to: backup, options: .withoutOverwriting)
                migrationBackupURL = backup
                _ = try write(decoded.configuration, previousData: nil)
            }
            return ConfigurationLoadOutcome(
                configuration: decoded.configuration,
                recovery: nil,
                migratedFromVersion: decoded.migratedFromVersion,
                migrationBackupURL: migrationBackupURL
            )
        } catch let error as ConfigurationPersistenceError {
            switch error {
            case .futureSchemaVersion, .unknownField:
                throw error
            default:
                let backup = backupURL(prefix: "config.invalid")
                try FileManager.default.moveItem(at: fileURL, to: backup)
                return ConfigurationLoadOutcome(
                    configuration: .defaultValue,
                    recovery: ConfigurationRecovery(backupURL: backup, reason: String(describing: error)),
                    migratedFromVersion: nil,
                    migrationBackupURL: nil
                )
            }
        }
    }

    public func save(_ configuration: AppConfiguration) throws -> ConfigurationSaveResult {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let newData = try codec.encode(configuration)
        let previousData = try? Data(contentsOf: fileURL)
        if let previousData,
           let previous = try? codec.decode(previousData).configuration,
           previous == configuration {
            return .unchanged
        }
        return try write(configuration, previousData: newData)
    }

    private func write(
        _ configuration: AppConfiguration,
        previousData suppliedData: Data?
    ) throws -> ConfigurationSaveResult {
        let data = try suppliedData ?? codec.encode(configuration)
        let temporaryURL = directoryURL.appending(path: "config.json.tmp.\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: temporaryURL) }
        try data.write(to: temporaryURL, options: .withoutOverwriting)
        let readBack = try Data(contentsOf: temporaryURL)
        guard try codec.decode(readBack).configuration == configuration else {
            throw ConfigurationPersistenceError.readBackMismatch
        }
        try beforeCommit(temporaryURL)
        do {
            try readBack.write(to: fileURL, options: .atomic)
        } catch {
            throw ConfigurationPersistenceError.commitFailed
        }
        return .saved
    }

    private func backupURL(prefix: String) -> URL {
        let timestamp = Int(Date().timeIntervalSince1970 * 1_000)
        return directoryURL.appending(path: "\(prefix).\(timestamp).json")
    }
}
