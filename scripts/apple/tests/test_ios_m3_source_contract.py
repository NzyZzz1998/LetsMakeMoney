import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
APP = ROOT / "apple" / "App"
CATALOG = ROOT / "apple" / "Shared" / "Resources" / "Localizable.xcstrings"


class IOSM3SourceContractTests(unittest.TestCase):
    def test_required_swiftui_features_exist(self):
        required = {
            "LetsMakeMoneyApp.swift": ["@main", "AppRootView"],
            "AppModel.swift": ["ObservableObject", "ConfigurationStore", "AppNavigationState"],
            "HolidayDataLoader.swift": ["HolidayDataLoader", "[2025, 2026]", '"cn-\\(year)"'],
            "PreviewSupport.swift": ["PreviewSupport", "AppConfiguration.defaultValue", "seedPreview"],
            "Design/WarmTheme.swift": ["WarmPalette", "WarmMetrics", "ButtonStyle"],
            "AppRootView.swift": ["NavigationSplitView", "compactNavigation", "horizontalSizeClass"],
            "Features/Today/TodayView.swift": ["today.amount", "today.schedule", "accessibilityLabel"],
            "Features/Calendar/SalaryCalendarView.swift": ["calendar.title", "DateOverrideSheet"],
            "Features/Calendar/DateOverrideSheet.swift": ["DateOverrideEditor", "common.save", "common.delete"],
            "Features/Settings/SettingsView.swift": ["settings.salary", "settings.schedule", "settings.system"],
            "Features/Onboarding/OnboardingView.swift": ["OnboardingSession", "onboarding.next", "onboarding.back"],
        }
        for relative, needles in required.items():
            path = APP / relative
            self.assertTrue(path.is_file(), relative)
            source = path.read_text(encoding="utf-8")
            for needle in needles:
                self.assertIn(needle, source, f"{relative}: {needle}")

    def test_catalog_covers_m3_navigation_and_feedback(self):
        strings = json.loads(CATALOG.read_text(encoding="utf-8"))["strings"]
        required = {
            "nav.today", "nav.calendar", "nav.settings",
            "onboarding.step.compensation", "onboarding.step.schedule", "onboarding.step.summary",
            "onboarding.next", "onboarding.back", "onboarding.complete", "onboarding.retry",
            "onboarding.month_workdays", "onboarding.daily_salary", "onboarding.today_preview",
            "today.amount", "today.month_total", "today.progress", "today.schedule",
            "calendar.title", "calendar.override", "calendar.out_of_range",
            "calendar.official_holiday", "calendar.adjusted_workday",
            "settings.salary", "settings.schedule", "settings.notifications", "settings.system",
            "feedback.saved", "feedback.unchanged", "feedback.save_failed",
            "common.cancel", "common.close", "common.save", "common.delete",
        }
        self.assertEqual(required - set(strings), set())

    def test_ipad_playgrounds_compatible_swiftui_surface(self):
        swift_files = list(APP.rglob("*.swift"))
        combined = "\n".join(path.read_text(encoding="utf-8") for path in swift_files)
        self.assertNotIn("List(selection:", combined)
        self.assertNotIn("accessibilityLiveRegion", combined)
        self.assertNotIn("binding.step.wrappedValue", combined)
        warm_theme = (APP / "Design" / "WarmTheme.swift").read_text(encoding="utf-8")
        self.assertIn("UIColor(dynamicProvider:", warm_theme)

    def test_onboarding_uses_constrained_inputs_and_keyboard_safe_layout(self):
        source = (APP / "Features" / "Onboarding" / "OnboardingView.swift").read_text(encoding="utf-8")
        required = {
            "SalaryAmountDraft",
            "AlternatingWeekSelection",
            "AlternatingWeekResolver",
            "WorkScheduleDraft",
            "ScheduleEntryStage",
            "scheduleEntryStage",
            "advanceScheduleEntry",
            "moveBackFromScheduleEntry",
            "lunchDurationText(minutes)",
            "setInferredWorkStart",
            "DatePicker(",
            'Text("onboarding.lunch_duration")',
            ".pickerStyle(.segmented)",
            ".pickerStyle(.menu)",
            "ScrollView",
            ".safeAreaInset(edge: .bottom)",
        }
        for needle in required:
            self.assertIn(needle, source, needle)

        self.assertNotIn('TextField("time.placeholder"', source)
        self.assertNotIn('LocalizedStringKey("onboarding.step.', source)
        self.assertNotIn('LocalizedStringKey("onboarding.lunch_duration.', source)
        self.assertNotIn('Picker("onboarding.lunch_duration"', source)

    def test_adaptive_navigation_matches_confirmed_ipad_portrait_contract(self):
        source = (APP / "AppRootView.swift").read_text(encoding="utf-8")
        required = {
            "GeometryReader",
            "usesLandscapeSidebar",
            "size.width > size.height",
            "NavigationSplitView",
            "compactTabBar",
            "compactDestination",
            "compactSettingsButton",
            "WarmPalette.canvas.ignoresSafeArea()",
        }
        for needle in required:
            self.assertIn(needle, source, needle)

        self.assertIn("horizontalSizeClass == .regular", source)
        self.assertNotIn("TabView(selection: destinationBinding)", source)

    def test_today_status_and_onboarding_errors_use_fixed_localization_keys(self):
        today = (APP / "Features" / "Today" / "TodayView.swift").read_text(encoding="utf-8")
        onboarding = (APP / "Features" / "Onboarding" / "OnboardingView.swift").read_text(encoding="utf-8")
        catalog = json.loads(CATALOG.read_text(encoding="utf-8"))["strings"]

        for needle in {
            "statusTitle(",
            'return "status.beforeWork"',
            'return "status.working"',
            'return "status.lunchBreak"',
            'return "status.finished"',
            'return "status.restDay"',
            ".frame(maxWidth: .infinity, maxHeight: .infinity",
        }:
            self.assertIn(needle, today, needle)
        self.assertNotIn('LocalizedStringKey("status.\\(', today)

        self.assertIn("private var validationMessageKey: LocalizedStringKey", onboarding)
        self.assertIn('return "onboarding.validation.salary"', onboarding)
        self.assertIn("Text(validationMessageKey)", onboarding)
        self.assertIn("onboarding.validation.salary", catalog)

    def test_onboarding_uses_step_specific_titles_and_fixed_rest_localization(self):
        source = (APP / "Features" / "Onboarding" / "OnboardingView.swift").read_text(encoding="utf-8")
        required = {
            ".navigationTitle(stepTitle)",
            "private var stepTitle: LocalizedStringKey",
            'return "onboarding.step.compensation"',
            'return "onboarding.step.schedule"',
            'return "onboarding.step.summary"',
            "restModeTitle(",
            'return "rest.single_weekend"',
            'return "rest.double_weekend"',
            'return "rest.alternating_weekend"',
        }
        for needle in required:
            self.assertIn(needle, source, needle)

        self.assertNotIn('LocalizedStringKey("rest.\\(', source)

    def test_preview_and_ui_automation_matrix_matches_current_navigation(self):
        root = (APP / "AppRootView.swift").read_text(encoding="utf-8")
        app = (APP / "LetsMakeMoneyApp.swift").read_text(encoding="utf-8")
        ui_test = (
            ROOT / "apple" / "Tests" / "UITests" / "M3SmokeUITests.swift"
        ).read_text(encoding="utf-8")

        for preview in {
            '#Preview("iPhone portrait")',
            '#Preview("iPad portrait")',
            '#Preview("iPad landscape")',
            '#Preview("Dark")',
            '#Preview("Dynamic type")',
            '#Preview("Settings")',
            '#Preview("Onboarding")',
        }:
            self.assertIn(preview, root, preview)

        for identifier in {
            '"nav.tab.\\(destination.rawValue)"',
            '"nav.settings"',
        }:
            self.assertIn(identifier, root, identifier)

        self.assertIn('"-ui-test-configured"', app)
        self.assertIn('"-ui-test-reset-configuration"', app)
        self.assertIn('app.buttons["nav.tab.calendar"]', ui_test)
        self.assertIn('app.buttons["nav.settings"]', ui_test)
        self.assertIn('app.buttons["settings.cancel"]', ui_test)
        self.assertIn('app.otherElements["onboarding.root"]', ui_test)
        self.assertNotIn("app.tabBars", ui_test)


if __name__ == "__main__":
    unittest.main()
