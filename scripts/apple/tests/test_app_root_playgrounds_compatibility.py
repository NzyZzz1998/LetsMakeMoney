import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
APP_ROOT = ROOT / "apple" / "App" / "AppRootView.swift"


class AppRootPlaygroundsCompatibilityTests(unittest.TestCase):
    def test_navigation_binding_uses_explicit_setter_closure(self):
        source = APP_ROOT.read_text(encoding="utf-8")
        self.assertIn("set: { model.select($0) }", source)
        self.assertNotIn("set: model.select", source)


if __name__ == "__main__":
    unittest.main()
