import Foundation
import Testing
@testable import SalaryCore

@Suite("Configuration persistence")
struct ConfigurationStoreTests {
    @Test("Save persists once and reports unchanged without rewriting")
    func saveAndUnchanged() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(directoryURL: directory)
        var configuration = AppConfiguration.defaultValue
        configuration.monthlySalaryMinor = 1_300_000

        #expect(try await store.save(configuration) == .saved)
        let modified = try #require(fileModificationDate(at: directory.appending(path: "config.json")))
        #expect(try await store.save(configuration) == .unchanged)
        #expect(fileModificationDate(at: directory.appending(path: "config.json")) == modified)
        #expect(try await store.load().configuration == configuration)
    }

    @Test("Commit failure preserves the previous file and caller draft")
    func saveFailurePreservesState() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let stableStore = ConfigurationStore(directoryURL: directory)
        var original = AppConfiguration.defaultValue
        original.monthlySalaryMinor = 1_000_000
        _ = try await stableStore.save(original)

        var draft = original
        draft.monthlySalaryMinor = 1_300_000
        let failingStore = ConfigurationStore(directoryURL: directory) { _ in
            throw ConfigurationPersistenceError.commitFailed
        }

        await #expect(throws: ConfigurationPersistenceError.commitFailed) {
            try await failingStore.save(draft)
        }
        #expect(draft.monthlySalaryMinor == 1_300_000)
        #expect(try await stableStore.load().configuration == original)
    }

    @Test("Corrupt configuration is backed up before defaults are restored")
    func corruptRecovery() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "config.json")
        try Data("{broken".utf8).write(to: file)
        let store = ConfigurationStore(directoryURL: directory)

        let outcome = try await store.load()

        #expect(outcome.configuration == .defaultValue)
        #expect(outcome.recovery != nil)
        let backup = try #require(outcome.recovery?.backupURL)
        #expect(FileManager.default.fileExists(atPath: backup.path))
        #expect(!FileManager.default.fileExists(atPath: file.path))
    }

    @Test("Legacy migration keeps the original bytes as a backup")
    func migrationBackup() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "config.json")
        let legacy: [String: Any] = [
            "schemaVersion": 0,
            "monthlySalaryMinor": 1_000_000,
            "currencyCode": "CNY",
            "restMode": "doubleWeekend",
            "workStart": "08:00",
            "workEnd": "18:00",
            "lunchStart": "12:00",
            "lunchEnd": "14:00",
            "standardWorkSeconds": 28_800,
            "dateOverrides": []
        ]
        try JSONSerialization.data(withJSONObject: legacy).write(to: file)

        let outcome = try await ConfigurationStore(directoryURL: directory).load()

        #expect(outcome.migratedFromVersion == 0)
        #expect(outcome.migrationBackupURL.map { FileManager.default.fileExists(atPath: $0.path) } == true)
        #expect(outcome.configuration.schemaVersion == 1)
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "lmm-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func fileModificationDate(at url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate]) as? Date
    }
}
