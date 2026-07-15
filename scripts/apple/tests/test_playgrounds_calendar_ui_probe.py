import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
EXPORTER = ROOT / "scripts" / "apple" / "export_playgrounds_calendar_ui_probe.ps1"


class PlaygroundsCalendarUIProbeTests(unittest.TestCase):
    def test_probe_contains_only_calendar_ui_slice(self):
        source = EXPORTER.read_text(encoding="utf-8")
        self.assertTrue(source.isascii())
        self.assertIn("SalaryCalendarView.swift", source)
        self.assertIn("DateOverrideSheet.swift", source)
        self.assertIn("WarmTheme.swift", source)
        self.assertIn("AppModel.swift", source)
        self.assertIn("SalaryCalendarView(compact: false)", source)
        self.assertIn('Text("CALENDAR UI PROBE")', source)
        self.assertNotIn("TodayView.swift", source)
        self.assertNotIn("SettingsView.swift", source)
        self.assertNotIn("OnboardingView.swift", source)
        self.assertNotIn("AppRootView.swift", source)
        self.assertNotIn("resources:", source)


if __name__ == "__main__":
    unittest.main()
