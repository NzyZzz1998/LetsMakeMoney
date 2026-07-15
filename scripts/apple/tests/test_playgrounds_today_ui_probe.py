import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
EXPORTER = ROOT / "scripts" / "apple" / "export_playgrounds_today_ui_probe.ps1"


class PlaygroundsTodayUIProbeTests(unittest.TestCase):
    def test_probe_contains_only_today_ui_slice(self):
        source = EXPORTER.read_text(encoding="utf-8")
        self.assertTrue(source.isascii())
        self.assertIn("apple\\App\\Design\\WarmTheme.swift", source)
        self.assertIn("apple\\App\\Features\\Today\\TodayView.swift", source)
        self.assertIn("apple\\App\\AppModel.swift", source)
        self.assertIn("TodayView()", source)
        self.assertIn('Text("TODAY UI PROBE")', source)
        self.assertNotIn("SettingsView.swift", source)
        self.assertNotIn("OnboardingView.swift", source)
        self.assertNotIn("SalaryCalendarView.swift", source)
        self.assertNotIn("AppRootView.swift", source)
        self.assertNotIn("resources:", source)


if __name__ == "__main__":
    unittest.main()
