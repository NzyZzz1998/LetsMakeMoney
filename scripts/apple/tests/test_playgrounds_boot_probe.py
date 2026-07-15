import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
EXPORTER = ROOT / "scripts" / "apple" / "export_playgrounds_boot_probe.ps1"


class PlaygroundsBootProbeTests(unittest.TestCase):
    def test_probe_is_minimal_and_visually_unambiguous(self):
        source = EXPORTER.read_text(encoding="utf-8")
        self.assertTrue(source.isascii())
        self.assertIn('Text("BOOT OK")', source)
        self.assertIn("Color.green", source)
        self.assertNotIn("SalaryCore", source)
        self.assertNotIn("resources:", source)
        self.assertNotIn("#Preview", source)


if __name__ == "__main__":
    unittest.main()
