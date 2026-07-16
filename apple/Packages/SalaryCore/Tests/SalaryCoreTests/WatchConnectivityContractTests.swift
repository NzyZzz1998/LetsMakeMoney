import Foundation
import Testing
@testable import SalaryCore

@Suite("Apple Watch connectivity contract")
struct WatchConnectivityContractTests {
    private let generatedAt = Date(timeIntervalSince1970: 1_752_528_800)

    @Test("Versioned messages round-trip and reject unsupported schemas")
    func versionedMessages() throws {
        let message = WatchMessageEnvelope.snapshotUpdate(
            messageID: "snapshot-1",
            sentAt: generatedAt,
            snapshot: snapshot(status: .working),
            schedule: SharedScheduleSnapshot(
                workStart: "08:00",
                lunchStart: "12:00",
                lunchEnd: "14:00",
                workEnd: "18:00"
            )
        )

        let encoded = try WatchMessageCodec.encode(message)
        #expect(try WatchMessageCodec.decode(encoded) == message)

        var object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        object["schemaVersion"] = WatchMessageSchema.currentVersion + 1
        let future = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: WatchMessageCodecError.unsupportedSchema(
            WatchMessageSchema.currentVersion + 1
        )) {
            try WatchMessageCodec.decode(future)
        }
    }

    @Test("Remaining time explains work end and lunch resume")
    func remainingTimeSemantics() {
        let working = WatchMetricPresentation.make(
            snapshot: snapshot(status: .working, remainingSeconds: 3_661),
            metric: .remainingTime
        )
        #expect(working.titleKey == "watch.metric.until_work_end")
        #expect(working.value == "1:01:01")

        let oneMinuteLater = WatchMetricPresentation.make(
            snapshot: snapshot(status: .working, remainingSeconds: 3_661),
            metric: .remainingTime,
            now: generatedAt.addingTimeInterval(61)
        )
        #expect(oneMinuteLater.value == "1:00:00")

        let lunch = WatchMetricPresentation.make(
            snapshot: snapshot(status: .lunchBreak, remainingSeconds: 1_800),
            metric: .remainingTime
        )
        #expect(lunch.titleKey == "watch.metric.until_resume")
        #expect(lunch.value == "0:30:00")
    }

    @Test("Remaining time is projected from the configured work schedule")
    func remainingTimeProjection() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let configuration = AppConfiguration.defaultValue

        let beforeWork = try WatchRemainingTimeProjection.seconds(
            configuration: configuration,
            salary: salary(status: .beforeWork),
            generatedAt: try #require(calendar.date(from: DateComponents(
                year: 2026, month: 7, day: 15, hour: 7, minute: 30
            ))),
            timeZone: calendar.timeZone
        )
        #expect(beforeWork == 1_800)

        let working = try WatchRemainingTimeProjection.seconds(
            configuration: configuration,
            salary: salary(status: .working),
            generatedAt: try #require(calendar.date(from: DateComponents(
                year: 2026, month: 7, day: 15, hour: 10
            ))),
            timeZone: calendar.timeZone
        )
        #expect(working == 28_800)

        let lunch = try WatchRemainingTimeProjection.seconds(
            configuration: configuration,
            salary: salary(status: .lunchBreak),
            generatedAt: try #require(calendar.date(from: DateComponents(
                year: 2026, month: 7, day: 15, hour: 12, minute: 30
            ))),
            timeZone: calendar.timeZone
        )
        #expect(lunch == 5_400)

        let finished = try WatchRemainingTimeProjection.seconds(
            configuration: configuration,
            salary: salary(status: .finished),
            generatedAt: try #require(calendar.date(from: DateComponents(
                year: 2026, month: 7, day: 15, hour: 18
            ))),
            timeZone: calendar.timeZone
        )
        #expect(finished == 0)
    }

    @Test("Income and progress are explicit user-selectable metrics")
    func alternateMetrics() {
        let income = WatchMetricPresentation.make(
            snapshot: snapshot(status: .working),
            metric: .todayIncome
        )
        #expect(income.titleKey == "watch.metric.today_income")
        #expect(income.value == "¥123.45")

        let progress = WatchMetricPresentation.make(
            snapshot: snapshot(status: .working),
            metric: .progress
        )
        #expect(progress.titleKey == "watch.metric.progress")
        #expect(progress.value == "56%")
    }

    @Test("Activity requests stay pending until iPhone confirmation")
    func noOptimisticSuccess() throws {
        var state = WatchConnectionState()
        state.setReachable(true)
        let request = try state.beginActivityRequest(
            .start,
            requestID: "request-1",
            at: generatedAt
        )

        #expect(request.kind == .activityRequest)
        #expect(state.activityState == .pending(
            requestID: "request-1",
            command: .start,
            startedAt: generatedAt
        ))
        #expect(!state.canRequestActivity)

        state.applyActivityResult(.init(
            requestID: "request-1",
            command: .start,
            outcome: .confirmed,
            feedbackKey: "activity.manual.started"
        ))
        #expect(state.activityState == .confirmed(
            command: .start,
            feedbackKey: "activity.manual.started"
        ))
    }

    @Test("Offline, failure, cancellation and timeout remain visible")
    func failureStates() throws {
        var state = WatchConnectionState()
        #expect(throws: WatchConnectionError.iPhoneUnavailable) {
            try state.beginActivityRequest(.start, requestID: "offline", at: generatedAt)
        }

        state.setReachable(true)
        _ = try state.beginActivityRequest(.stop, requestID: "failure", at: generatedAt)
        state.applyActivityResult(.init(
            requestID: "failure",
            command: .stop,
            outcome: .failed,
            feedbackKey: "activity.manual.failed"
        ))
        #expect(state.activityState == .failed(
            command: .stop,
            feedbackKey: "activity.manual.failed"
        ))

        _ = try state.beginActivityRequest(
            .start,
            requestID: "cancelled",
            at: generatedAt.addingTimeInterval(1)
        )
        state.cancelPendingRequest()
        #expect(state.activityState == .cancelled(command: .start))

        _ = try state.beginActivityRequest(
            .start,
            requestID: "timeout",
            at: generatedAt.addingTimeInterval(2)
        )
        state.expirePendingRequest(
            now: generatedAt.addingTimeInterval(WatchMessageSchema.requestTimeout + 3)
        )
        #expect(state.activityState == .timedOut(command: .start))
    }

    @Test("Offline mode keeps the latest snapshot and reconnect asks for refresh")
    func offlineAndReconnect() {
        var state = WatchConnectionState()
        let latest = snapshot(status: .working)
        state.applySnapshot(latest, schedule: nil)
        state.setReachable(false)

        #expect(state.latestSnapshot == latest)
        #expect(state.showsOfflineNotice)
        #expect(!state.canRequestActivity)

        state.setReachable(true)
        #expect(state.needsSnapshotRefresh)
        state.markSnapshotRefreshRequested()
        #expect(!state.needsSnapshotRefresh)
    }

    @Test("Snapshots from another calendar day are marked stale after restart")
    func crossDayRecovery() {
        var state = WatchConnectionState()
        state.applySnapshot(snapshot(status: .finished), schedule: nil)

        #expect(state.isSnapshotStale(
            at: generatedAt.addingTimeInterval(86_400),
            calendar: Calendar(identifier: .gregorian)
        ))
    }

    private func snapshot(
        status: SalaryStatus,
        remainingSeconds: Int = 3_600
    ) -> WatchSnapshot {
        WatchSnapshot(
            snapshotID: "watch-1",
            generatedAt: generatedAt,
            status: status,
            todayEarnedMinor: 12_345,
            progressBasisPoints: 5_600,
            remainingSeconds: remainingSeconds,
            metric: .remainingTime
        )
    }

    private func salary(status: SalaryStatus) -> SalarySnapshot {
        SalarySnapshot(
            monthPaidWorkdays: 23,
            dailySalaryMinor: 43_478,
            standardHourlySalaryMinor: 5_435,
            todayEarnedMinor: 12_345,
            monthEarnedMinor: 123_450,
            completedEffectiveSeconds: 10_000,
            progressBasisPoints: 3_472,
            status: status,
            warnings: []
        )
    }
}
