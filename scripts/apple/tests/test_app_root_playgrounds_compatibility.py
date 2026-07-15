import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
APP_ROOT = ROOT / "apple" / "App" / "AppRootView.swift"


class AppRootPlaygroundsCompatibilityTests(unittest.TestCase):
    def test_custom_navigation_uses_explicit_actions_and_stable_identifiers(self):
        source = APP_ROOT.read_text(encoding="utf-8")
        self.assertIn("Button { model.select(destination) }", source)
        self.assertIn('accessibilityIdentifier("nav.tab.\\(destination.rawValue)")', source)
        self.assertNotIn("List(selection:", source)
        self.assertNotIn("NavigationLink(value:", source)


if __name__ == "__main__":
    unittest.main()
