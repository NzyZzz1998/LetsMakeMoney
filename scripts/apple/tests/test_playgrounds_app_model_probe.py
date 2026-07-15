import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
EXPORTER = ROOT / "scripts" / "apple" / "export_playgrounds_app_model_probe.ps1"


class PlaygroundsAppModelProbeTests(unittest.TestCase):
    def test_probe_runs_real_app_model_without_full_ui_or_resources(self):
        source = EXPORTER.read_text(encoding="utf-8")
        self.assertTrue(source.isascii())
        self.assertIn("apple\\App\\AppModel.swift", source)
        self.assertIn("@StateObject private var model: AppModel", source)
        self.assertIn(".task {", source)
        self.assertIn("await model.load()", source)
        self.assertIn("loadCompleted = true", source)
        self.assertIn('"APP MODEL LOADING"', source)
        self.assertIn('"APP MODEL OK"', source)
        self.assertIn("ConfigurationStore", source)
        self.assertIn("LocalEventLogger", source)
        self.assertNotIn("resources:", source)
        self.assertNotIn("AppRootView", source)
        self.assertNotIn("#Preview", source)


if __name__ == "__main__":
    unittest.main()
