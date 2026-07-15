import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PROJECT_SPEC = ROOT / "apple" / "project.yml"
APP_ENTITLEMENTS = ROOT / "apple" / "Config" / "LetsMakeMoneyApp.entitlements"
WIDGET_ENTITLEMENTS = ROOT / "apple" / "Config" / "LetsMakeMoneyWidget.entitlements"
APP_MODEL = ROOT / "apple" / "App" / "AppModel.swift"
WIDGET_BUNDLE = ROOT / "apple" / "WidgetExtension" / "LetsMakeMoneyWidgetBundle.swift"
WIDGET_SOURCE = ROOT / "apple" / "WidgetExtension" / "SalaryWidget.swift"
ACTIVITY_ATTRIBUTES = (
    ROOT / "apple" / "Shared" / "LiveActivity" / "SalaryActivityAttributes.swift"
)
LIVE_ACTIVITY_SOURCE = (
    ROOT / "apple" / "WidgetExtension" / "SalaryLiveActivity.swift"
)
ACTIVITY_PROJECTION = (
    ROOT
    / "apple"
    / "Packages"
    / "SalaryCore"
    / "Sources"
    / "SalaryCore"
    / "SalaryActivityProjection.swift"
)
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

    def test_medium_widget_adds_progress_without_changing_content_states(self):
        widget_source = WIDGET_SOURCE.read_text(encoding="utf-8")
        self.assertIn("@Environment(\\.widgetFamily)", widget_source)
        self.assertIn("mediumReadyView", widget_source)
        self.assertIn("progressBasisPoints", widget_source)
        self.assertIn("ProgressView", widget_source)
        self.assertIn('Text("today.progress")', widget_source)
        for family in (".systemSmall", ".systemMedium", ".systemLarge"):
            self.assertIn(family, widget_source)
        self.assertEqual(widget_source.count("enum SalaryWidgetContentState"), 1)

    def test_large_widget_adds_today_schedule_from_shared_projection(self):
        widget_source = WIDGET_SOURCE.read_text(encoding="utf-8")
        self.assertIn("largeReadyView", widget_source)
        self.assertIn("snapshot.schedule", widget_source)
        self.assertIn('Text("today.schedule")', widget_source)
        self.assertIn('scheduleRow("schedule.work_start"', widget_source)
        self.assertIn('scheduleRow("schedule.lunch"', widget_source)
        self.assertIn('scheduleRow("schedule.work_end"', widget_source)
        self.assertIn(".systemLarge", widget_source)
        self.assertEqual(widget_source.count("enum SalaryWidgetContentState"), 1)

    def test_lock_screen_families_use_compact_views_and_narrow_width_fallback(self):
        widget_source = WIDGET_SOURCE.read_text(encoding="utf-8")
        for family in (
            ".accessoryInline",
            ".accessoryCircular",
            ".accessoryRectangular",
        ):
            self.assertIn(family, widget_source)

        for view in (
            "accessoryInlineReadyView",
            "accessoryCircularReadyView",
            "accessoryRectangularReadyView",
            "accessoryEmptyStateView",
        ):
            self.assertIn(view, widget_source)

        self.assertIn("ViewThatFits(in: .horizontal)", widget_source)
        self.assertIn("inlineSummary", widget_source)
        self.assertIn("widgetFamily.isAccessory", widget_source)
        self.assertIn(".widgetAccentable()", widget_source)
        self.assertIn(
            "[.systemSmall, .systemMedium, .systemLarge, .accessoryInline, "
            ".accessoryCircular, .accessoryRectangular]",
            widget_source,
        )
        self.assertEqual(widget_source.count("enum SalaryWidgetContentState"), 1)

    def test_timeline_exposes_last_update_and_transitions_to_expired_state(self):
        widget_source = WIDGET_SOURCE.read_text(encoding="utf-8")
        self.assertIn("SharedSnapshotRefreshPolicy", widget_source)
        self.assertIn("case expired(SharedSnapshotBundle)", widget_source)
        self.assertIn("expirationDate(generatedAt:", widget_source)
        self.assertIn("nextRefreshDate(", widget_source)
        self.assertIn("generatedAt: generatedAt", widget_source)
        self.assertIn("expiredEntry", widget_source)
        self.assertIn('Text("widget.updated")', widget_source)
        self.assertIn('Text("widget.expired")', widget_source)
        self.assertIn("snapshot.salary.generatedAt", widget_source)

        localizations = LOCALIZATIONS.read_text(encoding="utf-8")
        self.assertIn('"widget.updated"', localizations)
        self.assertIn('"widget.expired"', localizations)

    def test_live_activity_attributes_bind_activitykit_to_the_versioned_core_contract(self):
        source = ACTIVITY_ATTRIBUTES.read_text(encoding="utf-8")
        self.assertIn("import ActivityKit", source)
        self.assertIn("struct SalaryActivityAttributes: ActivityAttributes", source)
        self.assertIn(
            "typealias ContentState = SalaryActivityContentState",
            source,
        )
        self.assertIn("SalaryActivityStaticContext", source)

    def test_lock_screen_live_activity_covers_all_phases_and_hides_lunch_amount(self):
        source = LIVE_ACTIVITY_SOURCE.read_text(encoding="utf-8")
        bundle_source = WIDGET_BUNDLE.read_text(encoding="utf-8")

        self.assertIn("struct SalaryLiveActivity: Widget", source)
        self.assertIn("ActivityConfiguration(for: SalaryActivityAttributes.self)", source)
        self.assertIn("SalaryLockScreenLiveActivityView", source)
        self.assertIn("case .working", source)
        self.assertIn("case .lunchBreak", source)
        self.assertIn("case .finished", source)
        self.assertIn("case .endedEarly", source)
        self.assertIn("showsEarnedAmount", source)
        self.assertIn("timerInterval:", source)
        self.assertIn("ProgressView", source)
        self.assertIn("activityBackgroundTint", source)
        self.assertIn("accessibilityLabel", source)
        self.assertIn("SalaryLiveActivity()", bundle_source)

    def test_dynamic_island_has_minimal_compact_expanded_and_narrow_fallbacks(self):
        source = LIVE_ACTIVITY_SOURCE.read_text(encoding="utf-8")

        for region in (
            "DynamicIslandExpandedRegion(.leading)",
            "DynamicIslandExpandedRegion(.trailing)",
            "DynamicIslandExpandedRegion(.bottom)",
            "compactLeading:",
            "compactTrailing:",
            "minimal:",
        ):
            self.assertIn(region, source)

        self.assertIn("SalaryDynamicIslandContent", source)
        self.assertIn("return DynamicIsland {", source)
        self.assertIn("expandedLeading", source)
        self.assertIn("expandedTrailing", source)
        self.assertIn("expandedBottom", source)
        self.assertIn("compactLeading", source)
        self.assertIn("compactTrailing", source)
        self.assertIn("minimal", source)
        self.assertIn("ViewThatFits(in: .horizontal)", source)
        self.assertIn("showsEarnedAmount", source)
        self.assertIn("timerInterval:", source)
        self.assertIn("accessibilityLabel", source)

    def test_live_activity_projection_uses_anchors_without_background_timers(self):
        projection = ACTIVITY_PROJECTION.read_text(encoding="utf-8")
        state_machine = (
            ROOT
            / "apple"
            / "Packages"
            / "SalaryCore"
            / "Sources"
            / "SalaryCore"
            / "SalaryActivityStateMachine.swift"
        ).read_text(encoding="utf-8")

        self.assertIn("struct SalaryActivityProjection", projection)
        self.assertIn("completedEffectiveSeconds", projection)
        self.assertIn("dailySalaryMinor", projection)
        self.assertIn("SalaryActivityProjection(context: context)", state_machine)
        for forbidden in (
            "Timer.",
            "scheduledTimer",
            "DispatchSourceTimer",
            "Task.sleep",
        ):
            self.assertNotIn(forbidden, projection)
            self.assertNotIn(forbidden, state_machine)


if __name__ == "__main__":
    unittest.main()
