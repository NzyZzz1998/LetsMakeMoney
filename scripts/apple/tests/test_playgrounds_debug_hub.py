import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
EXPORTER = ROOT / "scripts" / "apple" / "export_playgrounds_debug_hub.ps1"


class PlaygroundsDebugHubTests(unittest.TestCase):
    def test_debug_hub_is_recoverable_and_covers_app_layers(self):
        source = EXPORTER.read_text(encoding="utf-8")
        self.assertTrue(source.isascii())
        self.assertIn("LMMDebugHub.swiftpm", source)
        self.assertIn("DebugBootTrace", source)
        self.assertIn("UserDefaults.standard", source)
        self.assertIn("lastStage", source)
        self.assertIn("markOpening", source)
        self.assertIn("markVisible", source)
        self.assertIn("TodayView()", source)
        self.assertIn("SalaryCalendarView(compact: false)", source)
        self.assertIn("SettingsView()", source)
        self.assertIn("OnboardingView()", source)
        self.assertIn("AppRootView()", source)
        self.assertIn("set: { model.select($0) }", source)
        self.assertNotIn("set: model.select", source)

    def test_debug_hub_excludes_the_production_main_and_previews(self):
        source = EXPORTER.read_text(encoding="utf-8")
        self.assertIn("LetsMakeMoneyApp.swift", source)
        self.assertIn("PreviewSupport.swift", source)
        self.assertIn("AppRootView.swift", source)
        self.assertIn("#Preview", source)
        self.assertIn("Localizable.strings", source)
        self.assertIn("cn-2025.json", source)
        self.assertIn("cn-2026.json", source)


if __name__ == "__main__":
    unittest.main()
