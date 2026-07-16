import Foundation
import SalaryCore
import WatchConnectivity

#if os(iOS)
private final class WatchReplyHandler: @unchecked Sendable {
    private let handler: ([String: Any]) -> Void

    init(_ handler: @escaping ([String: Any]) -> Void) {
        self.handler = handler
    }

    func callAsFunction(_ reply: [String: Any]) {
        handler(reply)
    }
}

final class PhoneWatchConnectivityController: NSObject, WatchSnapshotPublishing,
    WCSessionDelegate, @unchecked Sendable {
    private let session: WCSession
    private let snapshotReader: any SharedSnapshotReading
    private let activityCoordinator: SystemSalaryActivityCoordinator

    init(
        session: WCSession = .default,
        snapshotReader: any SharedSnapshotReading,
        activityCoordinator: SystemSalaryActivityCoordinator = .init()
    ) {
        self.session = session
        self.snapshotReader = snapshotReader
        self.activityCoordinator = activityCoordinator
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    func publish(_ bundle: SharedSnapshotBundle) {
        let message = WatchMessageEnvelope.snapshotUpdate(
            messageID: bundle.watch.snapshotID,
            sentAt: bundle.watch.generatedAt,
            snapshot: bundle.watch,
            schedule: bundle.schedule
        )
        guard let payload = try? WatchMessageCodec.encode(message) else { return }
        try? session.updateApplicationContext(["payload": payload])
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard let payload = message["payload"] as? Data,
              let envelope = try? WatchMessageCodec.decode(payload)
        else {
            replyHandler(["error": "watch.message.invalid"])
            return
        }
        let reply = WatchReplyHandler(replyHandler)
        Task {
            let response = await response(to: envelope)
            guard let data = try? WatchMessageCodec.encode(response) else {
                reply(["error": "watch.message.encode_failed"])
                return
            }
            reply(["payload": data])
        }
    }

    private func response(to message: WatchMessageEnvelope) async -> WatchMessageEnvelope {
        switch message.kind {
        case .snapshotRequest:
            if let bundle = try? await snapshotReader.read() {
                return .snapshotUpdate(
                    messageID: bundle.watch.snapshotID,
                    sentAt: bundle.watch.generatedAt,
                    snapshot: bundle.watch,
                    schedule: bundle.schedule
                )
            }
            return failedResult(
                requestID: message.messageID,
                command: .start,
                feedbackKey: "watch.snapshot.unavailable"
            )
        case .activityRequest:
            guard let command = message.activityCommand else {
                return failedResult(
                    requestID: message.messageID,
                    command: .start,
                    feedbackKey: "watch.activity.invalid_request"
                )
            }
            let operation: SalaryActivityOperationResult
            switch command {
            case .start: operation = await activityCoordinator.start()
            case .stop: operation = await activityCoordinator.stop()
            }
            let result: WatchActivityResult
            switch operation {
            case .started, .stopped:
                result = WatchActivityResult(
                    requestID: message.messageID,
                    command: command,
                    outcome: .confirmed,
                    feedbackKey: operation.feedbackKey
                )
            case .unavailable, .failed:
                result = WatchActivityResult(
                    requestID: message.messageID,
                    command: command,
                    outcome: .failed,
                    feedbackKey: operation.feedbackKey
                )
            }
            return .activityResult(
                messageID: UUID().uuidString,
                sentAt: Date(),
                result: result
            )
        case .snapshotUpdate, .activityResult:
            return failedResult(
                requestID: message.messageID,
                command: message.activityCommand ?? .start,
                feedbackKey: "watch.message.unsupported"
            )
        }
    }

    private func failedResult(
        requestID: String,
        command: WatchActivityCommand,
        feedbackKey: String
    ) -> WatchMessageEnvelope {
        .activityResult(
            messageID: UUID().uuidString,
            sentAt: Date(),
            result: WatchActivityResult(
                requestID: requestID,
                command: command,
                outcome: .failed,
                feedbackKey: feedbackKey
            )
        )
    }
}
#endif

#if os(watchOS)
@MainActor
final class WatchSessionController: NSObject, ObservableObject {
    @Published private(set) var state = WatchConnectionState()
    @Published private(set) var selectedMetric: WatchMetric

    private let session: WCSession
    private let store: WatchMessageStore

    init(
        session: WCSession = .default,
        appGroupIdentifier: String? = Bundle.main.object(
            forInfoDictionaryKey: "LMMAppGroupIdentifier"
        ) as? String
    ) {
        self.session = session
        self.store = WatchMessageStore(appGroupIdentifier: appGroupIdentifier)
        self.selectedMetric = store.loadMetric()
        super.init()
        if let cached = store.load(), let snapshot = cached.snapshot {
            state.applySnapshot(snapshot, schedule: cached.schedule)
        }
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
        state.setReachable(session.isReachable)
    }

    func selectMetric(_ metric: WatchMetric) {
        selectedMetric = metric
        store.saveMetric(metric)
    }

    func requestSnapshot() {
        guard session.isReachable else { return }
        state.markSnapshotRefreshRequested()
        let message = WatchMessageEnvelope.snapshotRequest(
            messageID: UUID().uuidString,
            sentAt: Date()
        )
        send(message)
    }

    func requestActivity(_ command: WatchActivityCommand) {
        let requestID = UUID().uuidString
        let message: WatchMessageEnvelope
        do {
            message = try state.beginActivityRequest(command, requestID: requestID, at: Date())
        } catch {
            return
        }
        send(message)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(WatchMessageSchema.requestTimeout))
            self?.state.expirePendingRequest(now: Date())
        }
    }

    func cancelPendingRequest() {
        state.cancelPendingRequest()
    }

    private func send(_ envelope: WatchMessageEnvelope) {
        guard let payload = try? WatchMessageCodec.encode(envelope) else { return }
        session.sendMessage(
            ["payload": payload],
            replyHandler: { [weak self] reply in
                guard let data = reply["payload"] as? Data else { return }
                self?.receive(data)
            },
            errorHandler: { [weak self] _ in
                Task { @MainActor in self?.state.setReachable(false) }
            }
        )
    }

    nonisolated private func receive(_ data: Data) {
        guard let message = try? WatchMessageCodec.decode(data) else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch message.kind {
            case .snapshotUpdate:
                guard let snapshot = message.snapshot else { return }
                state.applySnapshot(snapshot, schedule: message.schedule)
                try? store.save(message)
            case .activityResult:
                guard let result = message.activityResult else { return }
                state.applyActivityResult(result)
            case .snapshotRequest, .activityRequest:
                break
            }
        }
    }
}

extension WatchSessionController: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.state.setReachable(session.isReachable)
            if session.isReachable { self?.requestSnapshot() }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor [weak self] in
            self?.state.setReachable(session.isReachable)
            if session.isReachable { self?.requestSnapshot() }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard let data = applicationContext["payload"] as? Data else { return }
        receive(data)
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        guard let data = message["payload"] as? Data else { return }
        receive(data)
    }
}
#endif
