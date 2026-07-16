import Foundation

public enum WatchMessageSchema {
    public static let currentVersion = 1
    public static let requestTimeout: TimeInterval = 15
}

public enum WatchMessageKind: String, Codable, Sendable {
    case snapshotRequest
    case snapshotUpdate
    case activityRequest
    case activityResult
}

public enum WatchActivityCommand: String, Codable, Sendable {
    case start
    case stop
}

public enum WatchActivityOutcome: String, Codable, Sendable {
    case confirmed
    case failed
    case cancelled
}

public struct WatchActivityResult: Codable, Equatable, Sendable {
    public let requestID: String
    public let command: WatchActivityCommand
    public let outcome: WatchActivityOutcome
    public let feedbackKey: String

    public init(
        requestID: String,
        command: WatchActivityCommand,
        outcome: WatchActivityOutcome,
        feedbackKey: String
    ) {
        self.requestID = requestID
        self.command = command
        self.outcome = outcome
        self.feedbackKey = feedbackKey
    }
}

public struct WatchMessageEnvelope: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let messageID: String
    public let sentAt: Date
    public let kind: WatchMessageKind
    public let snapshot: WatchSnapshot?
    public let schedule: SharedScheduleSnapshot?
    public let activityCommand: WatchActivityCommand?
    public let activityResult: WatchActivityResult?

    public static func snapshotRequest(
        messageID: String,
        sentAt: Date
    ) -> WatchMessageEnvelope {
        WatchMessageEnvelope(
            schemaVersion: WatchMessageSchema.currentVersion,
            messageID: messageID,
            sentAt: sentAt,
            kind: .snapshotRequest
        )
    }

    public static func snapshotUpdate(
        messageID: String,
        sentAt: Date,
        snapshot: WatchSnapshot,
        schedule: SharedScheduleSnapshot?
    ) -> WatchMessageEnvelope {
        WatchMessageEnvelope(
            schemaVersion: WatchMessageSchema.currentVersion,
            messageID: messageID,
            sentAt: sentAt,
            kind: .snapshotUpdate,
            snapshot: snapshot,
            schedule: schedule
        )
    }

    public static func activityRequest(
        requestID: String,
        sentAt: Date,
        command: WatchActivityCommand
    ) -> WatchMessageEnvelope {
        WatchMessageEnvelope(
            schemaVersion: WatchMessageSchema.currentVersion,
            messageID: requestID,
            sentAt: sentAt,
            kind: .activityRequest,
            activityCommand: command
        )
    }

    public static func activityResult(
        messageID: String,
        sentAt: Date,
        result: WatchActivityResult
    ) -> WatchMessageEnvelope {
        WatchMessageEnvelope(
            schemaVersion: WatchMessageSchema.currentVersion,
            messageID: messageID,
            sentAt: sentAt,
            kind: .activityResult,
            activityResult: result
        )
    }

    public init(
        schemaVersion: Int = WatchMessageSchema.currentVersion,
        messageID: String,
        sentAt: Date,
        kind: WatchMessageKind,
        snapshot: WatchSnapshot? = nil,
        schedule: SharedScheduleSnapshot? = nil,
        activityCommand: WatchActivityCommand? = nil,
        activityResult: WatchActivityResult? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.messageID = messageID
        self.sentAt = sentAt
        self.kind = kind
        self.snapshot = snapshot
        self.schedule = schedule
        self.activityCommand = activityCommand
        self.activityResult = activityResult
    }
}

public enum WatchMessageCodecError: Error, Equatable, Sendable {
    case unsupportedSchema(Int)
    case malformedPayload
}

public enum WatchMessageCodec {
    public static func encode(_ message: WatchMessageEnvelope) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(message)
    }

    public static func decode(_ data: Data) throws -> WatchMessageEnvelope {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let message: WatchMessageEnvelope
        do {
            message = try decoder.decode(WatchMessageEnvelope.self, from: data)
        } catch {
            throw WatchMessageCodecError.malformedPayload
        }
        guard message.schemaVersion == WatchMessageSchema.currentVersion else {
            throw WatchMessageCodecError.unsupportedSchema(message.schemaVersion)
        }
        return message
    }
}

public protocol WatchSnapshotPublishing: Sendable {
    func publish(_ bundle: SharedSnapshotBundle)
}

public enum WatchRemainingTimeProjection {
    public static func seconds(
        configuration: AppConfiguration,
        salary: SalarySnapshot,
        generatedAt: Date,
        timeZone: TimeZone = .current
    ) throws -> Int {
        guard salary.status != .finished, salary.status != .restDay else { return 0 }
        let context = try SalaryActivityLaunchContextFactory.make(
            configuration: configuration,
            salary: salary,
            snapshotID: "watch-remaining-time",
            generatedAt: generatedAt,
            timeZone: timeZone
        )
        let target = switch salary.status {
        case .beforeWork:
            context.workStartAt
        case .working:
            context.workEndAt
        case .lunchBreak:
            context.lunchEndAt
        case .finished, .restDay:
            generatedAt
        }
        return max(0, Int(target.timeIntervalSince(generatedAt)))
    }
}

public struct WatchMetricPresentation: Equatable, Sendable {
    public let titleKey: String
    public let value: String

    public static func make(
        snapshot: WatchSnapshot,
        metric: WatchMetric
    ) -> WatchMetricPresentation {
        switch metric {
        case .remainingTime:
            return WatchMetricPresentation(
                titleKey: remainingTitleKey(for: snapshot.status),
                value: duration(snapshot.remainingSeconds)
            )
        case .todayIncome:
            return WatchMetricPresentation(
                titleKey: "watch.metric.today_income",
                value: money(snapshot.todayEarnedMinor)
            )
        case .progress:
            let clamped = min(10_000, max(0, snapshot.progressBasisPoints))
            return WatchMetricPresentation(
                titleKey: "watch.metric.progress",
                value: "\((clamped + 50) / 100)%"
            )
        }
    }

    public static func make(
        snapshot: WatchSnapshot,
        metric: WatchMetric,
        now: Date
    ) -> WatchMetricPresentation {
        guard metric == .remainingTime else {
            return make(snapshot: snapshot, metric: metric)
        }
        let elapsed = max(0, Int(now.timeIntervalSince(snapshot.generatedAt)))
        return WatchMetricPresentation(
            titleKey: remainingTitleKey(for: snapshot.status),
            value: duration(max(0, snapshot.remainingSeconds - elapsed))
        )
    }

    private static func remainingTitleKey(for status: SalaryStatus) -> String {
        switch status {
        case .working: "watch.metric.until_work_end"
        case .lunchBreak: "watch.metric.until_resume"
        case .beforeWork: "watch.metric.until_work_start"
        case .finished, .restDay: "watch.metric.remaining_unavailable"
        }
    }

    private static func duration(_ seconds: Int) -> String {
        let value = max(0, seconds)
        return String(
            format: "%d:%02d:%02d",
            value / 3_600,
            (value % 3_600) / 60,
            value % 60
        )
    }

    private static func money(_ minor: Int64) -> String {
        let sign = minor < 0 ? "-" : ""
        let absolute = minor.magnitude
        return "\(sign)¥\(absolute / 100).\(String(format: "%02llu", absolute % 100))"
    }
}

public enum WatchConnectionError: Error, Equatable, Sendable {
    case iPhoneUnavailable
    case requestAlreadyPending
}

public enum WatchActivityRequestState: Equatable, Sendable {
    case idle
    case pending(requestID: String, command: WatchActivityCommand, startedAt: Date)
    case confirmed(command: WatchActivityCommand, feedbackKey: String)
    case failed(command: WatchActivityCommand, feedbackKey: String)
    case cancelled(command: WatchActivityCommand)
    case timedOut(command: WatchActivityCommand)
}

public struct WatchConnectionState: Equatable, Sendable {
    public private(set) var latestSnapshot: WatchSnapshot?
    public private(set) var latestSchedule: SharedScheduleSnapshot?
    public private(set) var isReachable = false
    public private(set) var activityState: WatchActivityRequestState = .idle
    public private(set) var needsSnapshotRefresh = true

    public init() {}

    public var canRequestActivity: Bool {
        guard isReachable else { return false }
        if case .pending = activityState { return false }
        return true
    }

    public var showsOfflineNotice: Bool { !isReachable }

    public mutating func setReachable(_ reachable: Bool) {
        if reachable && !isReachable { needsSnapshotRefresh = true }
        isReachable = reachable
    }

    public mutating func applySnapshot(
        _ snapshot: WatchSnapshot,
        schedule: SharedScheduleSnapshot?
    ) {
        latestSnapshot = snapshot
        latestSchedule = schedule
        needsSnapshotRefresh = false
    }

    public mutating func markSnapshotRefreshRequested() {
        needsSnapshotRefresh = false
    }

    public mutating func beginActivityRequest(
        _ command: WatchActivityCommand,
        requestID: String,
        at date: Date
    ) throws -> WatchMessageEnvelope {
        guard isReachable else { throw WatchConnectionError.iPhoneUnavailable }
        if case .pending = activityState {
            throw WatchConnectionError.requestAlreadyPending
        }
        activityState = .pending(requestID: requestID, command: command, startedAt: date)
        return .activityRequest(requestID: requestID, sentAt: date, command: command)
    }

    public mutating func applyActivityResult(_ result: WatchActivityResult) {
        guard case .pending(let requestID, let command, _) = activityState,
              requestID == result.requestID,
              command == result.command
        else { return }
        switch result.outcome {
        case .confirmed:
            activityState = .confirmed(command: command, feedbackKey: result.feedbackKey)
        case .failed:
            activityState = .failed(command: command, feedbackKey: result.feedbackKey)
        case .cancelled:
            activityState = .cancelled(command: command)
        }
    }

    public mutating func cancelPendingRequest() {
        guard case .pending(_, let command, _) = activityState else { return }
        activityState = .cancelled(command: command)
    }

    public mutating func expirePendingRequest(now: Date) {
        guard case .pending(_, let command, let startedAt) = activityState,
              now.timeIntervalSince(startedAt) >= WatchMessageSchema.requestTimeout
        else { return }
        activityState = .timedOut(command: command)
    }

    public func isSnapshotStale(at date: Date, calendar: Calendar) -> Bool {
        guard let latestSnapshot else { return true }
        return !calendar.isDate(latestSnapshot.generatedAt, inSameDayAs: date)
    }
}
