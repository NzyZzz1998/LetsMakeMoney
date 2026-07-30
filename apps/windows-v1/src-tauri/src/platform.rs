#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Rect {
    pub x: i32,
    pub y: i32,
    pub width: u32,
    pub height: u32,
}

pub const TRAY_TOGGLE_MINI: &str = "tray-toggle-mini";
pub const TRAY_WORKBENCH: &str = "tray-workbench";
pub const TRAY_SETTINGS: &str = "tray-settings";
pub const TRAY_WIZARD: &str = "tray-wizard";
pub const TRAY_DATA_DIR: &str = "tray-data-dir";
pub const TRAY_EXIT: &str = "tray-exit";

pub fn clamp_window_to_monitor(window: Rect, monitor: Rect, margin: i32) -> (i32, i32) {
    let monitor_right = monitor.x.saturating_add(monitor.width as i32);
    let monitor_bottom = monitor.y.saturating_add(monitor.height as i32);
    let max_x = monitor_right
        .saturating_sub(window.width as i32)
        .saturating_sub(margin);
    let max_y = monitor_bottom
        .saturating_sub(window.height as i32)
        .saturating_sub(margin);
    let min_x = monitor.x.saturating_add(margin);
    let min_y = monitor.y.saturating_add(margin);

    (
        window.x.clamp(min_x.min(max_x), min_x.max(max_x)),
        window.y.clamp(min_y.min(max_y), min_y.max(max_y)),
    )
}

pub fn point_in_rect(x: i32, y: i32, rect: Rect) -> bool {
    x >= rect.x
        && y >= rect.y
        && x < rect.x.saturating_add(rect.width as i32)
        && y < rect.y.saturating_add(rect.height as i32)
}

pub fn is_known_tray_command(id: &str) -> bool {
    matches!(
        id,
        TRAY_TOGGLE_MINI | TRAY_WORKBENCH | TRAY_SETTINGS | TRAY_WIZARD | TRAY_DATA_DIR | TRAY_EXIT
    )
}

#[cfg(target_os = "windows")]
pub fn webview2_runtime_available() -> bool {
    const CLIENT: &str =
        r"SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}";
    [
        r"HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}".to_string(),
        format!(r"HKLM\{CLIENT}"),
        format!(r"HKCU\{CLIENT}"),
    ]
    .iter()
    .any(|key| {
        std::process::Command::new("reg.exe")
            .args(["query", key, "/v", "pv"])
            .output()
            .map(|output| output.status.success())
            .unwrap_or(false)
    })
}

#[cfg(not(target_os = "windows"))]
pub fn webview2_runtime_available() -> bool {
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn clamps_offscreen_window_inside_monitor() {
        let monitor = Rect {
            x: 0,
            y: 0,
            width: 1920,
            height: 1080,
        };
        let window = Rect {
            x: 2100,
            y: -400,
            width: 760,
            height: 560,
        };
        assert_eq!(clamp_window_to_monitor(window, monitor, 12), (1148, 12));
    }

    #[test]
    fn supports_monitors_left_of_primary_display() {
        let monitor = Rect {
            x: -1600,
            y: 0,
            width: 1600,
            height: 900,
        };
        let window = Rect {
            x: -1700,
            y: 800,
            width: 344,
            height: 120,
        };
        assert_eq!(clamp_window_to_monitor(window, monitor, 12), (-1588, 768));
    }

    #[test]
    fn recognizes_only_declared_tray_commands() {
        for id in [
            TRAY_TOGGLE_MINI,
            TRAY_WORKBENCH,
            TRAY_SETTINGS,
            TRAY_WIZARD,
            TRAY_DATA_DIR,
            TRAY_EXIT,
        ] {
            assert!(is_known_tray_command(id));
        }
        assert!(!is_known_tray_command("tray-pet-mode"));
    }
}
