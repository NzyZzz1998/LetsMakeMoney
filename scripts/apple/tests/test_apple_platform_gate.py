import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "apple" / "Packages" / "ApplePlatformGate" / "Package.swift"
APP_PROBE = (
    ROOT
    / "apple"
    / "Packages"
    / "ApplePlatformGate"
    / "Sources"
    / "G3AppProbe"
    / "G3AppProbe.swift"
)
WIDGET_PROBE = (
    ROOT
    / "apple"
    / "Packages"
    / "ApplePlatformGate"
    / "Sources"
    / "G3WidgetActivityProbe"
    / "G3WidgetActivityProbe.swift"
)
WATCH_PROBE = (
    ROOT
    / "apple"
    / "Packages"
    / "ApplePlatformGate"
    / "Sources"
    / "G3WatchProbe"
    / "G3WatchProbe.swift"
)
WORKFLOW = ROOT / ".github" / "workflows" / "apple-sdk-experimental.yml"
M4_GATE = ROOT / "scripts" / "apple" / "check_ios_m4.ps1"


class ApplePlatformGateTests(unittest.TestCase):
    def test_platform_gate_package_declares_all_g3_probe_targets(self):
        source = PACKAGE.read_text(encoding="utf-8")
        self.assertIn('name: "G3AppProbe"', source)
        self.assertIn('name: "G3WidgetActivityProbe"', source)
        self.assertIn('name: "G3WatchProbe"', source)
        self.assertIn('.package(path: "../SalaryCore")', source)

    def test_probes_cover_required_apple_framework_boundaries(self):
        self.assertIn("import SwiftUI", APP_PROBE.read_text(encoding="utf-8"))

        widget_source = WIDGET_PROBE.read_text(encoding="utf-8")
        self.assertIn("import ActivityKit", widget_source)
        self.assertIn("import AppIntents", widget_source)
        self.assertIn("import WidgetKit", widget_source)

        watch_source = WATCH_PROBE.read_text(encoding="utf-8")
        self.assertIn("import SwiftUI", watch_source)
        self.assertIn("import WatchConnectivity", watch_source)
        self.assertIn("import WidgetKit", watch_source)

    def test_github_gate_builds_each_probe_for_its_apple_simulator_sdk(self):
        source = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("-scheme G3AppProbe", source)
        self.assertIn("-scheme G3WidgetActivityProbe", source)
        self.assertIn("-scheme G3WatchProbe", source)
        self.assertIn("generic/platform=iOS Simulator", source)
        self.assertIn("generic/platform=watchOS Simulator", source)
        self.assertIn("apple/Packages/ApplePlatformGate", source)

    def test_windows_m4_gate_keeps_m3_and_platform_contracts(self):
        source = M4_GATE.read_text(encoding="utf-8")
        self.assertIn("check_ios_m3.ps1", source)
        self.assertIn("test_apple_platform_gate", source)
        self.assertIn("APPLE_PLATFORM_G3_BUILD_PENDING", source)


if __name__ == "__main__":
    unittest.main()
