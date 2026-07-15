import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[3]


class LiveActivityManualEntriesTests(unittest.TestCase):
    def read(self, relative: str) -> str:
        return (ROOT / relative).read_text(encoding="utf-8")

    def test_shared_coordinator_uses_activitykit_and_shared_snapshot(self) -> None:
        source = self.read("apple/Shared/LiveActivity/SalaryActivityCoordinator.swift")
        self.assertIn("import ActivityKit", source)
        self.assertIn("SharedSnapshotStore", source)
        self.assertIn("SalaryActivityManualAccessPolicy.decision", source)
        self.assertIn("Activity<SalaryActivityAttributes>.request", source)
        self.assertIn("Activity<SalaryActivityAttributes>.activities", source)
        self.assertIn("dismissalPolicy:", source)
        self.assertNotIn("requestAuthorization", source)

    def test_intents_and_control_widget_are_registered(self) -> None:
        intents = self.read("apple/Shared/LiveActivity/SalaryActivityIntents.swift")
        control = self.read("apple/WidgetExtension/SalaryActivityControl.swift")
        bundle = self.read("apple/WidgetExtension/LetsMakeMoneyWidgetBundle.swift")
        project = self.read("apple/project.yml")

        self.assertIn("StartSalaryActivityIntent: LiveActivityIntent", intents)
        self.assertIn("StopSalaryActivityIntent: LiveActivityIntent", intents)
        self.assertIn("ToggleSalaryActivityIntent: LiveActivityIntent", intents)
        self.assertIn("ControlWidgetButton", control)
        self.assertIn("SalaryActivityControl()", bundle)
        self.assertGreaterEqual(project.count("path: Shared/LiveActivity"), 2)

    def test_app_and_widget_expose_manual_actions(self) -> None:
        app_model = self.read("apple/App/AppModel.swift")
        today = self.read("apple/App/Features/Today/TodayView.swift")
        widget = self.read("apple/WidgetExtension/SalaryWidget.swift")
        plist = self.read("apple/App/Info.plist")

        self.assertIn("toggleLiveActivity", app_model)
        self.assertIn("refreshLiveActivityDecision", app_model)
        self.assertIn("activity.manual", today)
        self.assertIn("Button(intent: ToggleSalaryActivityIntent())", widget)
        self.assertIn("NSSupportsLiveActivities", plist)

    def test_notification_denial_is_not_a_manual_activity_gate(self) -> None:
        coordinator = self.read("apple/Shared/LiveActivity/SalaryActivityCoordinator.swift")
        self.assertNotIn("notificationStatus == .allowed", coordinator)
        self.assertNotIn("notificationPreference == .allowed", coordinator)

    def test_m4_gate_runs_manual_activity_contract(self) -> None:
        gate = self.read("scripts/apple/check_ios_m4.ps1")
        self.assertIn("test_live_activity_manual_entries", gate)


if __name__ == "__main__":
    unittest.main()
