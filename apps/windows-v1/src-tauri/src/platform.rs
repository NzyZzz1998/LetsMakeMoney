#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Rect {
    pub x: i32,
    pub y: i32,
    pub width: u32,
    pub height: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EdgeDockSide {
    Left,
    Right,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct EdgeDockPositions {
    pub expanded: (i32, i32),
    pub retracted: (i32, i32),
}

pub const MINI_EDGE_DOCK_THRESHOLD_LOGICAL_PX: i32 = 16;
pub const MINI_EDGE_PRIVACY_TAB_LOGICAL_PX: i32 = 40;
pub const MINI_EDGE_UNDOCK_THRESHOLD_LOGICAL_PX: i32 = 24;
pub const MINI_EDGE_FALLBACK_MARGIN_LOGICAL_PX: i32 = 12;
pub const MINI_EDGE_TRANSITION_MS: u64 = 180;

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

pub fn physical_pixels(logical_pixels: i32, scale_factor: f64) -> i32 {
    let scale = if scale_factor.is_finite() && scale_factor > 0.0 {
        scale_factor
    } else {
        1.0
    };
    (f64::from(logical_pixels) * scale).round() as i32
}

#[cfg(target_os = "windows")]
pub fn work_area_for_rect(window: Rect) -> Result<Rect, String> {
    use std::ffi::c_void;
    use std::mem::size_of;

    type MonitorHandle = *mut c_void;
    const MONITOR_DEFAULT_TO_NEAREST: u32 = 2;

    #[repr(C)]
    struct WinRect {
        left: i32,
        top: i32,
        right: i32,
        bottom: i32,
    }

    #[repr(C)]
    struct MonitorInfo {
        size: u32,
        monitor: WinRect,
        work: WinRect,
        flags: u32,
    }

    #[link(name = "user32")]
    extern "system" {
        fn MonitorFromRect(rect: *const WinRect, flags: u32) -> MonitorHandle;
        fn GetMonitorInfoW(monitor: MonitorHandle, info: *mut MonitorInfo) -> i32;
    }

    let rect = WinRect {
        left: window.x,
        top: window.y,
        right: window.x.saturating_add(window.width as i32),
        bottom: window.y.saturating_add(window.height as i32),
    };
    let monitor = unsafe { MonitorFromRect(&rect, MONITOR_DEFAULT_TO_NEAREST) };
    if monitor.is_null() {
        return Err("work_area_monitor_unavailable".into());
    }
    let mut info = MonitorInfo {
        size: size_of::<MonitorInfo>() as u32,
        monitor: WinRect {
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
        },
        work: WinRect {
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
        },
        flags: 0,
    };
    if unsafe { GetMonitorInfoW(monitor, &mut info) } == 0 {
        return Err("work_area_query_failed".into());
    }
    let width = info.work.right.saturating_sub(info.work.left);
    let height = info.work.bottom.saturating_sub(info.work.top);
    if width <= 0 || height <= 0 {
        return Err("work_area_invalid".into());
    }
    Ok(Rect {
        x: info.work.left,
        y: info.work.top,
        width: width as u32,
        height: height as u32,
    })
}

#[cfg(not(target_os = "windows"))]
pub fn work_area_for_rect(_window: Rect) -> Result<Rect, String> {
    Err("work_area_unsupported".into())
}

#[cfg(test)]
pub fn detect_edge_dock(
    window: Rect,
    work_area: Rect,
    scale_factor: f64,
    threshold_logical_px: i32,
) -> Option<EdgeDockSide> {
    detect_edge_dock_with_preference(window, work_area, scale_factor, threshold_logical_px, None)
}

pub fn detect_edge_dock_with_preference(
    window: Rect,
    work_area: Rect,
    scale_factor: f64,
    threshold_logical_px: i32,
    current_side: Option<EdgeDockSide>,
) -> Option<EdgeDockSide> {
    let threshold = physical_pixels(threshold_logical_px.max(0), scale_factor);
    let work_right = work_area.x.saturating_add(work_area.width as i32);
    let window_right = window.x.saturating_add(window.width as i32);
    let left_distance = i64::from(window.x).abs_diff(i64::from(work_area.x));
    let right_distance = i64::from(window_right).abs_diff(i64::from(work_right));
    let threshold = threshold as u64;

    match (left_distance <= threshold, right_distance <= threshold) {
        (true, true) if left_distance == right_distance => {
            Some(current_side.unwrap_or(EdgeDockSide::Right))
        }
        (true, true) if left_distance < right_distance => Some(EdgeDockSide::Left),
        (true, true) => Some(EdgeDockSide::Right),
        (true, false) => Some(EdgeDockSide::Left),
        (false, true) => Some(EdgeDockSide::Right),
        (false, false) => None,
    }
}

pub fn edge_dock_positions(
    window: Rect,
    work_area: Rect,
    side: EdgeDockSide,
    scale_factor: f64,
    privacy_tab_logical_px: i32,
) -> EdgeDockPositions {
    let work_right = work_area.x.saturating_add(work_area.width as i32);
    let visible_width =
        physical_pixels(privacy_tab_logical_px.max(0), scale_factor).min(window.width as i32);
    let (_, y) = clamp_window_to_monitor(window, work_area, 0);
    let expanded_x = match side {
        EdgeDockSide::Left => work_area.x,
        EdgeDockSide::Right => work_right.saturating_sub(window.width as i32),
    };
    let retracted_x = match side {
        EdgeDockSide::Left => work_area
            .x
            .saturating_sub(window.width as i32)
            .saturating_add(visible_width),
        EdgeDockSide::Right => work_right.saturating_sub(visible_width),
    };

    EdgeDockPositions {
        expanded: (expanded_x, y),
        retracted: (retracted_x, y),
    }
}

pub fn fallback_to_work_area(
    window: Rect,
    primary_work_area: Rect,
    scale_factor: f64,
    margin_logical_px: i32,
) -> (i32, i32) {
    clamp_window_to_monitor(
        window,
        primary_work_area,
        physical_pixels(margin_logical_px.max(0), scale_factor),
    )
}

pub fn should_undock(
    inward_displacement_physical_px: i32,
    scale_factor: f64,
    threshold_logical_px: i32,
) -> bool {
    inward_displacement_physical_px >= physical_pixels(threshold_logical_px.max(0), scale_factor)
}

pub fn is_known_tray_command(id: &str) -> bool {
    matches!(
        id,
        TRAY_TOGGLE_MINI | TRAY_WORKBENCH | TRAY_SETTINGS | TRAY_WIZARD | TRAY_DATA_DIR | TRAY_EXIT
    )
}

#[cfg(target_os = "windows")]
pub fn webview2_runtime_available() -> bool {
    // Tauri calls setup only after the startup WebView has been created. Re-querying
    // the registry here launches up to three reg.exe processes and delays every
    // startup without providing stronger capability evidence than the live WebView.
    true
}

#[cfg(not(target_os = "windows"))]
pub fn webview2_runtime_available() -> bool {
    true
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde::Deserialize;

    #[derive(Debug, Deserialize)]
    struct GeometryFixture {
        contract: GeometryContract,
        dock_cases: Vec<DockCase>,
        fallback_cases: Vec<FallbackCase>,
        undock_cases: Vec<UndockCase>,
    }

    #[derive(Debug, Deserialize)]
    struct GeometryContract {
        dock_threshold_logical_px: i32,
        privacy_tab_logical_px: i32,
        undock_threshold_logical_px: i32,
        fallback_margin_logical_px: i32,
    }

    #[derive(Debug, Deserialize)]
    struct Point {
        x: i32,
        y: i32,
    }

    #[derive(Debug, Deserialize)]
    struct DockCase {
        id: String,
        scale_factor: f64,
        work_area: RectFixture,
        window: RectFixture,
        expected_side: String,
        expected_expanded: Option<Point>,
        expected_retracted: Option<Point>,
    }

    #[derive(Debug, Deserialize)]
    struct FallbackCase {
        id: String,
        scale_factor: f64,
        primary_work_area: RectFixture,
        window: RectFixture,
        expected_position: Point,
    }

    #[derive(Debug, Deserialize)]
    struct UndockCase {
        id: String,
        scale_factor: f64,
        inward_displacement_physical_px: i32,
        expected_undock: bool,
    }

    #[derive(Debug, Deserialize)]
    struct RectFixture {
        x: i32,
        y: i32,
        width: u32,
        height: u32,
    }

    impl From<&RectFixture> for Rect {
        fn from(value: &RectFixture) -> Self {
            Self {
                x: value.x,
                y: value.y,
                width: value.width,
                height: value.height,
            }
        }
    }

    fn geometry_fixture() -> GeometryFixture {
        serde_json::from_str(include_str!(
            "../../tests/fixtures/v104-mini-edge-geometry.json"
        ))
        .expect("v1.0.4 geometry fixture must parse")
    }

    fn v105_geometry_fixture() -> GeometryFixture {
        serde_json::from_str(include_str!(
            "../../tests/fixtures/v105-mini-edge-geometry.json"
        ))
        .expect("v1.0.5 geometry fixture must parse")
    }

    fn v107_geometry_fixture() -> GeometryFixture {
        serde_json::from_str(include_str!(
            "../../tests/fixtures/v107-mini-edge-geometry.json"
        ))
        .expect("v1.0.7 geometry fixture must parse")
    }

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

    #[test]
    fn v104_edge_dock_geometry_matches_work_area_and_dpi_fixtures() {
        let fixture = geometry_fixture();
        for case in fixture.dock_cases {
            let side = detect_edge_dock(
                Rect::from(&case.window),
                Rect::from(&case.work_area),
                case.scale_factor,
                fixture.contract.dock_threshold_logical_px,
            );
            let expected_side = match case.expected_side.as_str() {
                "left" => Some(EdgeDockSide::Left),
                "right" => Some(EdgeDockSide::Right),
                "none" => None,
                other => panic!("unknown fixture side: {other}"),
            };
            assert_eq!(side, expected_side, "fixture {}", case.id);
            if let Some(side) = side {
                let positions = edge_dock_positions(
                    Rect::from(&case.window),
                    Rect::from(&case.work_area),
                    side,
                    case.scale_factor,
                    fixture.contract.privacy_tab_logical_px,
                );
                let expanded = case
                    .expected_expanded
                    .as_ref()
                    .expect("docked case needs expanded position");
                let retracted = case
                    .expected_retracted
                    .as_ref()
                    .expect("docked case needs retracted position");
                assert_eq!(
                    positions.expanded,
                    (expanded.x, expanded.y),
                    "fixture {}",
                    case.id
                );
                assert_eq!(
                    positions.retracted,
                    (retracted.x, retracted.y),
                    "fixture {}",
                    case.id
                );
            }
        }
    }

    #[test]
    fn v105_privacy_tab_geometry_remains_reproducible() {
        let fixture = v105_geometry_fixture();
        assert_eq!(fixture.contract.privacy_tab_logical_px, 28);
        for case in fixture.dock_cases {
            let side = match case.expected_side.as_str() {
                "left" => EdgeDockSide::Left,
                "right" => EdgeDockSide::Right,
                other => panic!("unexpected v1.0.5 fixture side: {other}"),
            };
            let positions = edge_dock_positions(
                Rect::from(&case.window),
                Rect::from(&case.work_area),
                side,
                case.scale_factor,
                fixture.contract.privacy_tab_logical_px,
            );
            let expected = case
                .expected_retracted
                .as_ref()
                .expect("v1.0.5 docked case needs a retracted position");
            assert_eq!(
                positions.retracted,
                (expected.x, expected.y),
                "fixture {}",
                case.id
            );
        }
    }

    #[test]
    fn privacy_tab_keeps_40_logical_pixels_visible() {
        let fixture = v107_geometry_fixture();
        assert_eq!(fixture.contract.privacy_tab_logical_px, 40);
        assert_eq!(
            MINI_EDGE_PRIVACY_TAB_LOGICAL_PX, fixture.contract.privacy_tab_logical_px,
            "production privacy-tab width must follow the current readable contract"
        );
        for case in fixture.dock_cases {
            let side = match case.expected_side.as_str() {
                "left" => EdgeDockSide::Left,
                "right" => EdgeDockSide::Right,
                other => panic!("unexpected v1.0.7 fixture side: {other}"),
            };
            let positions = edge_dock_positions(
                Rect::from(&case.window),
                Rect::from(&case.work_area),
                side,
                case.scale_factor,
                fixture.contract.privacy_tab_logical_px,
            );
            let expected = case
                .expected_retracted
                .as_ref()
                .expect("v1.0.7 docked case needs a retracted position");
            assert_eq!(
                positions.retracted,
                (expected.x, expected.y),
                "fixture {}",
                case.id
            );
        }
    }

    #[test]
    fn v104_missing_monitor_fallback_uses_primary_work_area() {
        let fixture = geometry_fixture();
        for case in fixture.fallback_cases {
            let actual = fallback_to_work_area(
                Rect::from(&case.window),
                Rect::from(&case.primary_work_area),
                case.scale_factor,
                fixture.contract.fallback_margin_logical_px,
            );
            assert_eq!(
                actual,
                (case.expected_position.x, case.expected_position.y),
                "fixture {}",
                case.id
            );
        }
    }

    #[test]
    fn v104_undock_threshold_is_scaled_from_logical_pixels() {
        let fixture = geometry_fixture();
        for case in fixture.undock_cases {
            assert_eq!(
                should_undock(
                    case.inward_displacement_physical_px,
                    case.scale_factor,
                    fixture.contract.undock_threshold_logical_px,
                ),
                case.expected_undock,
                "fixture {}",
                case.id
            );
        }
    }

    #[test]
    fn v104_equal_edge_distance_preserves_current_side_or_defaults_right() {
        let work_area = Rect {
            x: 0,
            y: 0,
            width: 100,
            height: 100,
        };
        let window = Rect {
            x: 0,
            y: 10,
            width: 100,
            height: 50,
        };
        assert_eq!(
            detect_edge_dock_with_preference(window, work_area, 1.0, 16, None),
            Some(EdgeDockSide::Right)
        );
        assert_eq!(
            detect_edge_dock_with_preference(window, work_area, 1.0, 16, Some(EdgeDockSide::Left)),
            Some(EdgeDockSide::Left)
        );
    }
}
