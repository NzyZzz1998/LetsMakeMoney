import Foundation
import Testing
@testable import SalaryCore

@Suite("Shared snapshots and diagnostics")
struct SharedSupportTests {
    @Test("Every target projection shares one snapshot identity")
    func sharedIdentity() throws {
        let configuration = AppConfiguration.defaultValue
        let salary = sampleSalarySnapshot()
        let generatedAt = Date(timeIntervalSince1970: 1_721_085_600)

        let bundle = SharedSnapshotBundle.make(
            configuration: configuration,
            salary: salary,
            generatedAt: generatedAt,
            remainingSeconds: 7_200
        )

        #expect(bundle.salary.id == bundle.activity.snapshotID)
        #expect(bundle.salary.id == bundle.watch.snapshotID)
        #expect(bundle.watch.metric == .remainingTime)
        #expect(bundle.watch.remainingSeconds == 7_200)
        #expect(bundle.schedule == SharedScheduleSnapshot(
            workStart: "08:00",
            lunchStart: "12:00",
            lunchEnd: "14:00",
            workEnd: "18:00"
        ))
    }

    @Test("Older shared snapshots remain decodable without a schedule projection")
    func legacySnapshotWithoutSchedule() throws {
        let bundle = SharedSnapshotBundle.make(
            configuration: .defaultValue,
            salary: sampleSalarySnapshot(),
            generatedAt: Date(timeIntervalSince1970: 1_721_085_600),
            remainingSeconds: 7_200
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        var object = try #require(
            JSONSerialization.jsonObject(with: encoder.encode(bundle)) as? [String: Any]
        )
        object.removeValue(forKey: "schedule")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let decoded = try decoder.decode(
            SharedSnapshotBundle.self,
            from: JSONSerialization.data(withJSONObject: object)
        )

        #expect(decoded.schedule == nil)
        #expect(decoded.salary == bundle.salary)
    }

    @Test("Snapshot readers never observe partial JSON during replacement")
    func concurrentSnapshotRead() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "lmm-snapshot-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SharedSnapshotStore(directoryURL: directory)

        let initial = SharedSnapshotBundle.make(
            configuration: .defaultValue,
            salary: sampleSalarySnapshot(),
            generatedAt: Date(timeIntervalSince1970: 0),
            remainingSeconds: 0
        )
        try await store.write(initial)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 1...20 {
                group.addTask {
                    let observed = try await store.read()
                    #expect(observed.salary.id == observed.activity.snapshotID)
                    #expect(observed.salary.id == observed.watch.snapshotID)
                }
                group.addTask {
                    let bundle = makeSnapshot(index: index)
                    try await store.write(bundle)
                    let observed = try await store.read()
                    #expect(observed.salary.id == observed.activity.snapshotID)
                    #expect(observed.salary.id == observed.watch.snapshotID)
                }
            }
            try await group.waitForAll()
        }
    }

    @Test("Missing shared snapshot has a structured read error")
    func missingSharedSnapshot() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "lmm-missing-snapshot-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = SharedSnapshotStore(directoryURL: directory)
        do {
            _ = try await store.read()
            Issue.record("Expected a missing snapshot error")
        } catch let error as SharedSnapshotReadError {
            #expect(error == .missingSnapshot)
        }
    }

    @Test("Invalid shared snapshot has a structured read error")
    func invalidSharedSnapshot() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "lmm-invalid-snapshot-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("not-json".utf8).write(to: directory.appending(path: "salary-snapshot.json"))

        let store = SharedSnapshotStore(directoryURL: directory)
        do {
            _ = try await store.read()
            Issue.record("Expected an invalid snapshot error")
        } catch let error as SharedSnapshotReadError {
            #expect(error == .invalidSnapshot)
        }
    }

    private func makeSnapshot(index: Int) -> SharedSnapshotBundle {
            var salary = sampleSalarySnapshot()
            salary = SalarySnapshot(
                monthPaidWorkdays: salary.monthPaidWorkdays,
                dailySalaryMinor: salary.dailySalaryMinor,
                standardHourlySalaryMinor: salary.standardHourlySalaryMinor,
                todayEarnedMinor: Int64(index),
                monthEarnedMinor: salary.monthEarnedMinor,
                completedEffectiveSeconds: salary.completedEffectiveSeconds,
                progressBasisPoints: salary.progressBasisPoints,
                status: salary.status,
                warnings: salary.warnings
            )
            return SharedSnapshotBundle.make(
                configuration: .defaultValue,
                salary: salary,
                generatedAt: Date(timeIntervalSince1970: TimeInterval(index)),
                remainingSeconds: 0
            )
    }

    @Test("Unavailable App Group produces a structured degradation error")
    func appGroupUnavailable() {
        #if os(Windows)
        #expect(throws: SharedContainerError.appGroupUnavailable) {
            try AppGroupContainerProvider(identifier: "group.invalid.test").containerURL()
        }
        #endif
    }

    @Test("Logger redacts private values and rotates bounded files")
    func loggerRedactionAndRotation() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "lmm-log-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let logger = LocalEventLogger(directoryURL: directory, maximumBytes: 180, retainedFiles: 2)

        for index in 0..<8 {
            try await logger.record(
                level: .info,
                event: "configuration.saved",
                metadata: [
                    "schemaVersion": "1",
                    "path": "C:\\Users\\private\\config.json",
                    "monthlySalaryMinor": "1300000",
                    "index": "\(index)"
                ]
            )
        }

        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        #expect(files.count <= 2)
        let content = try files.map { try String(contentsOf: $0, encoding: .utf8) }.joined()
        #expect(!content.contains("private"))
        #expect(!content.contains("1300000"))
        #expect(content.contains("[REDACTED]"))
    }

    private func sampleSalarySnapshot() -> SalarySnapshot {
        SalarySnapshot(
            monthPaidWorkdays: 23,
            dailySalaryMinor: 43_478,
            standardHourlySalaryMinor: 5_435,
            todayEarnedMinor: 10_870,
            monthEarnedMinor: 315_216,
            completedEffectiveSeconds: 7_200,
            progressBasisPoints: 2_500,
            status: .working,
            warnings: []
        )
    }
}
