import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
WORKFLOW = ROOT / ".github" / "workflows" / "apple-sdk-experimental.yml"
M3_GATE = ROOT / "scripts" / "apple" / "check_ios_m3.ps1"


class AppleSDKWorkflowTests(unittest.TestCase):
    def test_windows_m3_gate_covers_compatibility_and_workflow_contracts(self):
        source = M3_GATE.read_text(encoding="utf-8")
        self.assertIn("test_app_root_playgrounds_compatibility", source)
        self.assertIn("test_apple_sdk_workflow", source)

    def test_workflow_is_manual_or_ios_branch_scoped_and_uses_a_macos_runner(self):
        source = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("workflow_dispatch:", source)
        self.assertNotIn("pull_request:", source)
        self.assertIn("push:", source)
        self.assertIn("- ios-main", source)
        self.assertIn("- 'apple/**'", source)
        self.assertIn("- 'scripts/apple/**'", source)
        self.assertIn("runs-on: macos-", source)
        self.assertIn("xcodebuild -version", source)
        self.assertIn("swift test --package-path apple/Packages/SalaryCore", source)
        self.assertIn("export_playgrounds_m3.ps1", source)
        self.assertIn("xcodebuild", source)
        self.assertIn("CODE_SIGNING_ALLOWED=NO", source)
        self.assertIn("upload-artifact", source)
        self.assertIn("experimental", source.lower())


if __name__ == "__main__":
    unittest.main()
