import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
APP = ROOT / "apple" / "App"
CONTROLLER = APP / "Platform" / "NotificationPermissionController.swift"
APP_MODEL = APP / "AppModel.swift"
SETTINGS = APP / "Features" / "Settings" / "SettingsView.swift"
ROOT_VIEW = APP / "AppRootView.swift"
CATALOG = ROOT / "apple" / "Shared" / "Resources" / "Localizable.xcstrings"
APP_PROBE = (
    ROOT
    / "apple"
    / "Packages"
    / "ApplePlatformGate"
    / "Sources"
    / "G3AppProbe"
    / "G3AppProbe.swift"
)


class NotificationPermissionFlowTests(unittest.TestCase):
    def test_system_adapter_reads_requests_and_opens_notification_settings(self):
        self.assertTrue(CONTROLLER.is_file())
        source = CONTROLLER.read_text(encoding="utf-8")
        for needle in {
            "import UIKit",
            "import UserNotifications",
            "protocol NotificationPermissionControlling",
            "SystemNotificationPermissionController",
            "notificationSettings()",
            "requestAuthorization(options: [.alert, .sound, .badge])",
            "UIApplication.openNotificationSettingsURLString",
        }:
            self.assertIn(needle, source, needle)

    def test_app_model_uses_runtime_system_status_and_logs_each_path(self):
        source = APP_MODEL.read_text(encoding="utf-8")
        for needle in {
            "notificationStatus",
            "NotificationPermissionControlling",
            "refreshNotificationStatus",
            "requestNotificationAuthorization",
            "openNotificationSettings",
            "NotificationPermissionPolicy.primaryAction",
            'event: "notification.status_refreshed"',
            'event: "notification.request_succeeded"',
            'event: "notification.request_failed"',
            'event: "notification.settings_opened"',
            'event: "notification.settings_open_failed"',
        }:
            self.assertIn(needle, source, needle)

    def test_settings_uses_system_fact_and_never_edits_the_configured_preference(self):
        source = SETTINGS.read_text(encoding="utf-8")
        for needle in {
            "model.notificationStatus",
            "model.requestNotificationAuthorization()",
            "model.openNotificationSettings()",
            '"notification.request"',
            '"notification.open_settings"',
        }:
            self.assertIn(needle, source, needle)
        self.assertNotIn("binding.value.notificationPreference", source)

    def test_foreground_activation_refreshes_revoked_permission(self):
        source = ROOT_VIEW.read_text(encoding="utf-8")
        self.assertIn("scenePhase", source)
        self.assertIn("refreshNotificationStatus", source)

    def test_catalog_and_apple_probe_cover_notification_boundary(self):
        strings = json.loads(CATALOG.read_text(encoding="utf-8"))["strings"]
        required = {
            "notification.request",
            "notification.open_settings",
            "notification.request_failed",
            "notification.settings_failed",
        }
        self.assertEqual(required - set(strings), set())
        self.assertIn(
            "import UserNotifications",
            APP_PROBE.read_text(encoding="utf-8"),
        )


if __name__ == "__main__":
    unittest.main()
