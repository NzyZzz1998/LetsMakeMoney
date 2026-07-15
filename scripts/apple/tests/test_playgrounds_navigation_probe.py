import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
EXPORTER = ROOT / "scripts" / "apple" / "export_playgrounds_navigation_probe.ps1"


class PlaygroundsNavigationProbeTests(unittest.TestCase):
    def test_probe_uses_app_model_navigation_in_minimal_tab_view(self):
        source = EXPORTER.read_text(encoding="utf-8")
        self.assertTrue(source.isascii())
        self.assertIn("apple\\App\\AppModel.swift", source)
        self.assertIn("TabView(selection: destinationBinding)", source)
        self.assertIn("model.navigation.destination", source)
        self.assertIn("set: { model.select($0) }", source)
        self.assertNotIn("set: model.select", source)
        self.assertIn("AppDestination.today", source)
        self.assertIn("AppDestination.calendar", source)
        self.assertNotIn("AppRootView.swift", source)
        self.assertNotIn("WarmTheme.swift", source)
        self.assertNotIn("resources:", source)


if __name__ == "__main__":
    unittest.main()
