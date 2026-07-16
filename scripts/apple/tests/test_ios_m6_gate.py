import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]


class IOSM6GateTests(unittest.TestCase):
    def read(self, relative: str) -> str:
        return (ROOT / relative).read_text(encoding="utf-8")

    def test_gate_runs_prerequisite_consistency_quality_and_prototype_checks(self):
        gate = self.read("scripts/apple/check_ios_m6.ps1")
        for marker in (
            "check_ios_m5.ps1",
            "test_apple_product_quality",
            "test_ios_prototype_contract",
            "validate_apple_localization.py",
            "validate_apple_product_quality.py",
            "validate_ios_prototype_contract.py",
            "CrossTargetConsistencyTests",
            "IOS_M6_AUTOMATED_GATE_PASS",
            "M6_REAL_DEVICE_MATRIX_PENDING",
        ):
            self.assertIn(marker, gate)

    def test_accessibility_and_appearance_readiness_contract_exists(self):
        theme = self.read("apple/App/Design/WarmTheme.swift")
        app_root = self.read("apple/App/AppRootView.swift")
        widget = self.read("apple/WidgetExtension/SalaryWidget.swift")
        watch = self.read("apple/WatchApp/WatchHomeView.swift")

        self.assertIn("dynamicProvider", theme)
        self.assertIn("colorSchemeContrast", theme)
        self.assertIn("accessibilityReduceMotion", theme)
        self.assertIn('Preview("Dark")', app_root)
        self.assertIn("dynamicTypeSize", app_root)
        self.assertIn("accessibilityLabel", widget)
        self.assertIn("accessibilityLabel", watch)

    def test_privacy_limit_build_and_device_matrix_documents_exist(self):
        for relative in (
            "apple/README.md",
            "doc/releases/ios-v0.1/privacy.md",
            "doc/releases/ios-v0.1/known-limitations.md",
            "doc/releases/ios-v0.1/m6-device-verification.md",
        ):
            content = self.read(relative)
            self.assertGreater(len(content), 300)
            self.assertNotIn("�", content)

        matrix = self.read("doc/releases/ios-v0.1/m6-device-verification.md")
        for marker in (
            "浅色/深色矩阵",
            "辅助功能矩阵",
            "时区、跨日、锁屏、重启与低电量",
            "证据失效条件",
            "待补证",
        ):
            self.assertIn(marker, matrix)


if __name__ == "__main__":
    unittest.main()
