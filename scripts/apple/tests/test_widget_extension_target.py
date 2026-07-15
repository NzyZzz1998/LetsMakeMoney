import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PROJECT_SPEC = ROOT / "apple" / "project.yml"
APP_ENTITLEMENTS = ROOT / "apple" / "Config" / "LetsMakeMoneyApp.entitlements"
WIDGET_ENTITLEMENTS = ROOT / "apple" / "Config" / "LetsMakeMoneyWidget.entitlements"
APP_MODEL = ROOT / "apple" / "App" / "AppModel.swift"
WIDGET_BUNDLE = ROOT / "apple" / "WidgetExtension" / "LetsMakeMoneyWidgetBundle.swift"
WIDGET_SOURCE = ROOT / "apple" / "WidgetExtension" / "SalaryWidget.swift"
LOCALIZATIONS = ROOT / "apple" / "Shared" / "Resources" / "Localizable.xcstrings"
BOOTSTRAP = ROOT / "scripts" / "apple" / "bootstrap_xcodegen.sh"
WORKFLOW = ROOT / ".github" / "workflows" / "apple-sdk-experimental.yml"
M4_GATE = ROOT / "scripts" / "apple" / "check_ios_m4.ps1"


class WidgetExtensionTargetTests(unittest.TestCase):
    def test_project_declares_real_app_and_widget_extension_targets(self):
        source = PROJECT_SPEC.read_text(encoding="utf-8")
        self.assertIn("LetsMakeMoneyApp:", source)
        self.assertIn("type: application", source)
        self.assertIn("LetsMakeMoneyWidget:", source)
        self.assertIn("type: app-extension", source)
        self.assertIn("embed: true", source)
        self.assertIn("path: Packages/SalaryCore", source)

    def test_app_and_widget_share_the_same_app_group_contract(self):
        for path in (APP_ENTITLEMENTS, WIDGET_ENTITLEMENTS):
            source = path.read_text(encoding="utf-8")
            self.assertIn("com.apple.security.application-groups", source)
            self.assertIn("$(APP_GROUP_IDENTIFIER)", source)

        project = PROJECT_SPEC.read_text(encoding="utf-8")
        self.assertIn("LMMAppGroupIdentifier", project)
        self.assertIn("$(APP_GROUP_IDENTIFIER)", project)

    def test_app_publishes_and_widget_only_reads_shared_snapshot_bundle(self):
        app_source = APP_MODEL.read_text(encoding="utf-8")
        self.assertIn("SharedSnapshotWriting", app_source)
        self.assertIn("publishSharedSnapshot", app_source)

        bundle_source = WIDGET_BUNDLE.read_text(encoding="utf-8")
        self.assertIn("@main", bundle_source)
        self.assertIn("WidgetBundle", bundle_source)

        widget_source = WIDGET_SOURCE.read_text(encoding="utf-8")
        self.assertIn("SharedSnapshotReading", widget_source)
        self.assertIn("SharedSnapshotStore", widget_source)
        self.assertIn("WidgetTimelineCompletion", widget_source)
        self.assertIn("@unchecked Sendable", widget_source)
        self.assertNotIn(".write(", widget_source)

    def test_github_generates_and_builds_the_real_widget_extension(self):
        bootstrap = BOOTSTRAP.read_text(encoding="utf-8")
        self.assertIn("2.45.4", bootstrap)
        self.assertIn("090ec29491aad50aec10631bf6e62253fed733c50f3aab0f5ffc86bc170bdbef", bootstrap.lower())

        workflow = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("bootstrap_xcodegen.sh", workflow)
        self.assertIn("xcodegen generate", workflow)
        self.assertIn("-scheme LetsMakeMoneyApp", workflow)
        self.assertIn("LetsMakeMoneyWidget.appex", workflow)

        gate = M4_GATE.read_text(encoding="utf-8")
        self.assertIn("test_widget_extension_target", gate)

    def test_small_widget_distinguishes_ready_unconfigured_and_unavailable_states(self):
        widget_source = WIDGET_SOURCE.read_text(encoding="utf-8")
        self.assertIn("enum SalaryWidgetContentState", widget_source)
        self.assertIn("case ready(SharedSnapshotBundle)", widget_source)
        self.assertIn("case unconfigured", widget_source)
        self.assertIn("case unavailable", widget_source)
        self.assertIn("SharedSnapshotReadError.missingSnapshot", widget_source)
        self.assertIn('title: "widget.unavailable.title"', widget_source)
        self.assertIn('message: "widget.unavailable.message"', widget_source)
        self.assertIn('message: "widget.configure.message"', widget_source)

        localizations = LOCALIZATIONS.read_text(encoding="utf-8")
        for key in (
            "widget.unavailable.title",
            "widget.unavailable.message",
            "widget.configure.message",
        ):
            self.assertIn(f'"{key}"', localizations)

    def test_small_widget_renders_amount_and_localized_salary_status(self):
        widget_source = WIDGET_SOURCE.read_text(encoding="utf-8")
        self.assertIn("smallReadyView", widget_source)
        self.assertIn("todayEarnedMinor", widget_source)
        for key in (
            '"status.beforeWork"',
            '"status.working"',
            '"status.lunchBreak"',
            '"status.finished"',
            '"status.restDay"',
        ):
            self.assertIn(key, widget_source)


if __name__ == "__main__":
    unittest.main()
