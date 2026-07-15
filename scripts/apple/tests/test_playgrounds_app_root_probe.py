import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
EXPORTER = ROOT / "scripts" / "apple" / "export_playgrounds_app_root_probe.ps1"


class PlaygroundsAppRootProbeTests(unittest.TestCase):
    def test_probe_uses_real_app_root_with_stub_feature_views(self):
        source = EXPORTER.read_text(encoding="utf-8")
        self.assertTrue(source.isascii())
        self.assertIn("apple\\App\\AppRootView.swift", source)
        self.assertIn("$appRoot = [regex]::Replace", source)
        self.assertIn(r"\.toolbar \{.*?", source)
        self.assertIn("fullScreenCover", source)
        self.assertIn("struct TodayView: View", source)
        self.assertIn("struct SalaryCalendarView: View", source)
        self.assertIn("struct SettingsView: View", source)
        self.assertIn("struct OnboardingView: View", source)
        self.assertIn("AppRootView()", source)
        self.assertIn(r".environment(\.horizontalSizeClass, .compact)", source)
        self.assertNotIn("await model.load()", source)
        self.assertNotIn("TodayView.swift", source)
        self.assertNotIn("SalaryCalendarView.swift", source)
        self.assertNotIn("SettingsView.swift", source)
        self.assertNotIn("OnboardingView.swift", source)
        self.assertNotIn("resources:", source)


if __name__ == "__main__":
    unittest.main()
