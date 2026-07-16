import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PROJECT_SPEC = ROOT / "apple" / "project.yml"
WORKFLOW = ROOT / ".github" / "workflows" / "apple-sdk-experimental.yml"
APP_SOURCE = ROOT / "apple" / "App" / "LetsMakeMoneyApp.swift"
PHONE_SESSION = ROOT / "apple" / "Shared" / "Watch" / "WatchConnectivityController.swift"
WATCH_APP = ROOT / "apple" / "WatchApp" / "LetsMakeMoneyWatchApp.swift"
WATCH_HOME = ROOT / "apple" / "WatchApp" / "WatchHomeView.swift"
WATCH_WIDGET = ROOT / "apple" / "WatchWidgetExtension" / "WatchProgressWidget.swift"
WATCH_INTENT = ROOT / "apple" / "WatchWidgetExtension" / "WatchMetricIntent.swift"
M5_GATE = ROOT / "scripts" / "apple" / "check_ios_m5.ps1"


class WatchProductTargetTests(unittest.TestCase):
    def test_project_declares_embedded_watch_app_and_widget_targets(self):
        source = PROJECT_SPEC.read_text(encoding="utf-8")
        self.assertIn('watchOS: "11.0"', source)
        self.assertIn("LetsMakeMoneyWatchApp:", source)
        self.assertIn("platform: watchOS", source)
        self.assertIn("path: WatchApp", source)
        self.assertIn("LetsMakeMoneyWatchWidget:", source)
        self.assertIn("path: WatchWidgetExtension", source)
        self.assertIn("WATCH_BUNDLE_IDENTIFIER", source)
        self.assertIn("WATCH_WIDGET_BUNDLE_IDENTIFIER", source)

    def test_ios_app_embeds_watch_app_and_activates_phone_session(self):
        project = PROJECT_SPEC.read_text(encoding="utf-8")
        self.assertIn("target: LetsMakeMoneyWatchApp", project)
        self.assertIn("path: Shared/Watch", project)

        app = APP_SOURCE.read_text(encoding="utf-8")
        self.assertIn("PhoneWatchConnectivityController", app)
        self.assertIn("activate()", app)

        session = PHONE_SESSION.read_text(encoding="utf-8")
        self.assertIn("WCSessionDelegate", session)
        self.assertIn("WatchMessageCodec", session)
        self.assertIn("updateApplicationContext", session)
        self.assertIn("SystemSalaryActivityCoordinator", session)

    def test_watch_app_is_read_only_and_waits_for_iphone_activity_confirmation(self):
        app = WATCH_APP.read_text(encoding="utf-8")
        home = WATCH_HOME.read_text(encoding="utf-8")
        session = PHONE_SESSION.read_text(encoding="utf-8")

        self.assertIn("WatchSessionController", app)
        self.assertIn("WatchMetricPresentation", home)
        self.assertIn("TimelineView", home)
        self.assertIn("requestActivity", home)
        self.assertIn("pending", home)
        self.assertIn("showsOfflineNotice", home)
        self.assertNotIn("ConfigurationStore", home)
        self.assertIn("requestTimeout", session)
        self.assertIn("applyActivityResult", session)

    def test_watch_metric_switch_avoids_swift_61_picker_irgen_crash(self):
        home = WATCH_HOME.read_text(encoding="utf-8")

        self.assertIn("cycleMetric", home)
        self.assertIn("metricSwitchLabel", home)
        self.assertNotIn('Picker("watch.metric.picker"', home)

    def test_watch_widget_supports_complications_smart_stack_and_metric_intent(self):
        widget = WATCH_WIDGET.read_text(encoding="utf-8")
        intent = WATCH_INTENT.read_text(encoding="utf-8")

        self.assertIn("AppIntentConfiguration", widget)
        self.assertIn("func recommendations()", widget)
        for family in (
            ".accessoryInline",
            ".accessoryCircular",
            ".accessoryRectangular",
        ):
            self.assertIn(family, widget)
        self.assertIn("widgetURL", widget)
        self.assertIn("WatchMetricIntent", intent)
        self.assertIn("AppEnum", intent)

    def test_macos_ci_builds_formal_watch_products(self):
        workflow = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("-scheme LetsMakeMoneyWatchApp", workflow)
        self.assertIn("generic/platform=watchOS Simulator", workflow)
        self.assertIn("LetsMakeMoneyWatchWidget.appex", workflow)
        self.assertIn("LetsMakeMoneyWatchApp.app", workflow)

    def test_m5_gate_runs_watch_contracts_and_m4_regression(self):
        source = M5_GATE.read_text(encoding="utf-8")
        self.assertIn("check_ios_m4.ps1", source)
        self.assertIn("test_watch_product_targets", source)
        self.assertIn("WatchConnectivityContractTests", source)
        self.assertIn("swift test", source)


if __name__ == "__main__":
    unittest.main()
