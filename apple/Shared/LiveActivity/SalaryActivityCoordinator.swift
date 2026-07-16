import ActivityKit
import Foundation
import SalaryCore

enum SalaryActivityOperationResult: Equatable {
    case started
    case stopped
    case unavailable(SalaryActivityManualUnavailableReason)
    case failed(String)

    var feedbackKey: String {
        switch self {
        case .started: "activity.manual.started"
        case .stopped: "activity.manual.stopped"
        case .unavailable(.activitiesDisabled): "activity.manual.disabled"
        case .unavailable(.missingLaunchContext): "activity.manual.unavailable"
        case .failed: "activity.manual.failed"
        }
    }
}

struct SystemSalaryActivityCoordinator: Sendable {
    private let bundle: Bundle
    private let now: @Sendable () -> Date

    init(bundle: Bundle = .main, now: @escaping @Sendable () -> Date = Date.init) {
        self.bundle = bundle
        self.now = now
    }

    func decision(
        notificationPreference: NotificationPreference
    ) async -> SalaryActivityManualDecision {
        let active = !Activity<SalaryActivityAttributes>.activities.isEmpty
        let snapshot = try? await snapshotStore()?.read()
        return SalaryActivityManualAccessPolicy.decision(
            notificationPreference: notificationPreference,
            activitiesEnabled: ActivityAuthorizationInfo().areActivitiesEnabled,
            hasLaunchContext: snapshot?.activityLaunchContext != nil,
            hasActiveActivity: active
        )
    }

    func toggle(
        notificationPreference: NotificationPreference
    ) async -> SalaryActivityOperationResult {
        switch await decision(notificationPreference: notificationPreference) {
        case .start:
            return await start()
        case .stop:
            return await stop()
        case .unavailable(let reason):
            await record(
                level: .warning,
                event: "activity.manual.unavailable",
                metadata: ["reasonCode": unavailableReasonCode(reason)]
            )
            return .unavailable(reason)
        }
    }

    func start() async -> SalaryActivityOperationResult {
        guard Activity<SalaryActivityAttributes>.activities.isEmpty else {
            return .started
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return .unavailable(.activitiesDisabled)
        }
        do {
            guard let store = snapshotStore() else {
                return .unavailable(.missingLaunchContext)
            }
            let snapshot = try await store.read()
            guard let context = snapshot.activityLaunchContext else {
                return .unavailable(.missingLaunchContext)
            }
            let state = try SalaryActivityStateMachine(context: context)
                .initialState(from: snapshot.activity, at: now())
            guard !state.isTerminal else {
                return .unavailable(.missingLaunchContext)
            }
            let content = ActivityContent(
                state: state,
                staleDate: state.nextTransitionAt
            )
            _ = try Activity<SalaryActivityAttributes>.request(
                attributes: SalaryActivityAttributes(context: context),
                content: content,
                pushType: nil
            )
            await record(level: .info, event: "activity.manual.started")
            return .started
        } catch {
            await record(
                level: .error,
                event: "activity.manual.start_failed",
                metadata: ["errorCode": activityErrorCode(error)]
            )
            return .failed(activityErrorCode(error))
        }
    }

    func stop() async -> SalaryActivityOperationResult {
        let activities = Activity<SalaryActivityAttributes>.activities
        guard !activities.isEmpty else { return .stopped }

        for activity in activities {
            let finalContent = await finalContent(for: activity)
            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
        await record(level: .info, event: "activity.manual.stopped")
        return .stopped
    }

    private func finalContent(
        for activity: Activity<SalaryActivityAttributes>
    ) async -> ActivityContent<SalaryActivityContentState>? {
        guard let store = snapshotStore(),
              let snapshot = try? await store.read(),
              let initial = try? SalaryActivityStateMachine(context: activity.attributes.context)
                .initialState(from: snapshot.activity, at: max(now(), activity.attributes.context.workStartAt)),
              let ended = try? SalaryActivityStateMachine(context: activity.attributes.context)
                .transition(initial, event: .confirmEarlyEnd(now()))
        else { return nil }
        return ActivityContent(state: ended, staleDate: nil)
    }

    private func snapshotStore() -> SharedSnapshotStore? {
        guard let identifier = bundle.object(
            forInfoDictionaryKey: "LMMAppGroupIdentifier"
        ) as? String,
              !identifier.isEmpty,
              let directoryURL = try? AppGroupContainerProvider(
                  identifier: identifier
              ).containerURL()
        else { return nil }
        return SharedSnapshotStore(directoryURL: directoryURL)
    }

    private func record(
        level: LocalLogLevel,
        event: String,
        metadata: [String: String] = [:]
    ) async {
        let root = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appending(path: "LetsMakeMoney")
        try? await LocalEventLogger(directoryURL: root).record(
            level: level,
            event: event,
            metadata: metadata
        )
    }

    private func unavailableReasonCode(
        _ reason: SalaryActivityManualUnavailableReason
    ) -> String {
        switch reason {
        case .activitiesDisabled: "activities_disabled"
        case .missingLaunchContext: "missing_launch_context"
        }
    }

    private func activityErrorCode(_ error: Error) -> String {
        if let readError = error as? SharedSnapshotReadError {
            switch readError {
            case .missingSnapshot: return "snapshot_missing"
            case .invalidSnapshot: return "snapshot_invalid"
            }
        }
        if error is SharedContainerError { return "app_group_unavailable" }
        return "activity_request_failed"
    }
}
