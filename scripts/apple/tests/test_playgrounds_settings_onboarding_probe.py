import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
EXPORTER = ROOT / "scripts" / "apple" / "export_playgrounds_settings_onboarding_probe.ps1"


class PlaygroundsSettingsOnboardingProbeTests(unittest.TestCase):
    def test_probe_contains_settings_and_onboarding_without_other_feature_views(self):
        source = EXPORTER.read_text(encoding="utf-8")
        self.assertTrue(source.isascii())
        self.assertIn("SettingsView.swift", source)
        self.assertIn("OnboardingView.swift", source)
        self.assertIn("WarmTheme.swift", source)
        self.assertIn("AppModel.swift", source)
        self.assertIn("SettingsView()", source)
        self.assertIn("OnboardingView()", source)
        self.assertIn('Text("SHOW SETTINGS")', source)
        self.assertIn('Text("SHOW ONBOARDING")', source)
        self.assertNotIn("TodayView.swift", source)
        self.assertNotIn("SalaryCalendarView.swift", source)
        self.assertNotIn("AppRootView.swift", source)
        self.assertNotIn("resources:", source)


if __name__ == "__main__":
    unittest.main()
