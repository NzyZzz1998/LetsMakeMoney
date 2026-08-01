use serde::Serialize;
use std::process::Command;
use std::sync::{
    atomic::{AtomicBool, AtomicU64, Ordering},
    Mutex,
};
use std::thread;
use std::time::Duration;
use tauri::{
    menu::{Menu, MenuItem, PredefinedMenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, LogicalSize, Manager, PhysicalPosition, Position, Size, WebviewUrl, WebviewWindow,
    WebviewWindowBuilder, WindowEvent,
};
#[cfg(target_os = "windows")]
use webview2_com::{Microsoft::Web::WebView2::Win32::ICoreWebView2_3, TrySuspendCompletedHandler};
#[cfg(target_os = "windows")]
use windows_core::Interface;

#[derive(Clone, Copy)]
struct WindowSpec {
    label: &'static str,
    title: &'static str,
    width: f64,
    height: f64,
    min_width: f64,
    min_height: f64,
    resizable: bool,
    skip_taskbar: bool,
}

const WINDOW_SPECS: [WindowSpec; 4] = [
    WindowSpec {
        label: "mini",
        title: "LetsMakeMoney",
        width: 344.0,
        height: 108.0,
        min_width: 344.0,
        min_height: 108.0,
        resizable: false,
        skip_taskbar: true,
    },
    WindowSpec {
        label: "workbench",
        title: "LetsMakeMoney 今日工作台",
        width: 920.0,
        height: 640.0,
        min_width: 820.0,
        min_height: 560.0,
        resizable: true,
        skip_taskbar: false,
    },
    WindowSpec {
        label: "settings",
        title: "LetsMakeMoney 设置",
        width: 760.0,
        height: 560.0,
        min_width: 720.0,
        min_height: 520.0,
        resizable: false,
        skip_taskbar: false,
    },
    WindowSpec {
        label: "wizard",
        title: "LetsMakeMoney 开始配置",
        width: 780.0,
        height: 580.0,
        min_width: 740.0,
        min_height: 540.0,
        resizable: false,
        skip_taskbar: false,
    },
];

#[derive(Serialize)]
struct WindowSnapshot {
    label: String,
    exists: bool,
    visible: bool,
    focused: bool,
    scale_factor: f64,
    width: u32,
    height: u32,
}

#[derive(Serialize)]
struct WindowDragOrigin {
    x: i32,
    y: i32,
    scale_factor: f64,
}

struct RuntimeConfig(Mutex<config::AppConfig>);
struct ConfigurationState(AtomicBool);
struct ExitState(AtomicBool);
struct PositionSaveRevision(AtomicU64);
struct PlatformRuntime(Mutex<PlatformCapabilities>);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum MiniEdgeVisibility {
    Expanded,
    Retracted,
}

struct MiniEdgeWindowState {
    dock: config::MiniEdgeDock,
    visibility: MiniEdgeVisibility,
    suppress_position_persistence: bool,
}

struct MiniEdgeRuntime {
    state: Mutex<MiniEdgeWindowState>,
    animation_revision: AtomicU64,
}

impl MiniEdgeRuntime {
    fn new(config: &config::AppConfig) -> Self {
        Self {
            state: Mutex::new(MiniEdgeWindowState {
                dock: if config.mini_edge_auto_hide {
                    config.mini_edge_dock
                } else {
                    config::MiniEdgeDock::None
                },
                visibility: MiniEdgeVisibility::Expanded,
                suppress_position_persistence: false,
            }),
            animation_revision: AtomicU64::new(0),
        }
    }
}

#[derive(Clone, Debug, Serialize)]
struct MiniEdgeStatus {
    auto_hide: bool,
    dock: config::MiniEdgeDock,
    visibility: &'static str,
    notice: Option<&'static str>,
}

#[derive(Clone, Serialize)]
struct PlatformCapabilities {
    webview2_available: bool,
    tray_available: bool,
    explorer_available: bool,
    tray_recovery: &'static str,
}

#[tauri::command]
fn load_calendar_year(
    app: AppHandle,
    year: i32,
) -> Result<calendar_data::CalendarDatasetResponse, String> {
    match calendar_data::load_calendar_year(year) {
        Ok(dataset) => {
            match dataset.coverage.mode {
                calendar_data::CalendarCoverageMode::Official => append_log(
                    &app,
                    "calendar.coverage.resolved",
                    &format!(
                        "year={year} mode=official version={}",
                        dataset.dataset_version.as_deref().unwrap_or("unknown")
                    ),
                ),
                calendar_data::CalendarCoverageMode::Estimated => append_log(
                    &app,
                    "calendar.coverage.estimated",
                    &format!("year={year} mode=estimated"),
                ),
            }
            Ok(dataset)
        }
        Err(error) => {
            append_log(
                &app,
                "calendar.coverage.integrity_failed",
                &format!("year={year} reason={error}"),
            );
            Err(error)
        }
    }
}

#[tauri::command]
fn read_configuration(state: tauri::State<'_, RuntimeConfig>) -> Result<config::AppConfig, String> {
    state
        .0
        .lock()
        .map(|value| value.clone())
        .map_err(|_| "config_lock_failed".into())
}

#[tauri::command]
fn save_configuration(
    app: AppHandle,
    state: tauri::State<'_, RuntimeConfig>,
    configuration_state: tauri::State<'_, ConfigurationState>,
    mut draft: config::AppConfig,
) -> Result<config::SaveResult, String> {
    if !draft.mini_edge_auto_hide {
        draft.mini_edge_dock = config::MiniEdgeDock::None;
    }
    let requested_edge_auto_hide = draft.mini_edge_auto_hide;
    let data_dir = app
        .path()
        .app_data_dir()
        .map_err(|error| error.to_string())?;
    let initialized = configuration_state.0.load(Ordering::SeqCst);
    let repository = repositories::configuration_repository::FileConfigurationRepository::new(
        data_dir.join("config.json"),
    );
    let outcome = services::configuration_service::save_user_configuration(
        &state.0,
        &repository,
        initialized,
        draft,
    )?;
    let previous_theme = outcome.previous_theme;
    let requested_theme = outcome.requested_theme;
    let result = outcome.result;
    let logger = support::RotatingLogger::new(data_dir.join("debug.log"), 2_000_000, 3);
    let event = match result.status {
        config::SaveStatus::Saved => "settings.saved",
        config::SaveStatus::Unchanged => "settings.unchanged",
        config::SaveStatus::Failed => "settings.save_failed",
    };
    let _ = logger.append(event, &result.message);
    if previous_theme != requested_theme {
        let (theme_event, theme_detail) = match result.status {
            config::SaveStatus::Saved => ("theme.saved", format!("theme={requested_theme:?}")),
            config::SaveStatus::Unchanged => {
                ("theme.unchanged", format!("theme={previous_theme:?}"))
            }
            config::SaveStatus::Failed => (
                "theme.reverted",
                format!(
                    "requested={requested_theme:?} restored={previous_theme:?} reason={}",
                    result.message.replace(['\r', '\n'], " ")
                ),
            ),
        };
        let _ = logger.append(theme_event, &theme_detail.to_lowercase());
    }
    if result.status == config::SaveStatus::Saved {
        configuration_state.0.store(true, Ordering::SeqCst);
    }
    if !requested_edge_auto_hide
        && matches!(
            result.status,
            config::SaveStatus::Saved | config::SaveStatus::Unchanged
        )
    {
        if let Err(error) = disable_mini_edge_auto_hide_internal(&app) {
            append_log(
                &app,
                "mini.edge_dock.failed",
                &format!("stage=settings_disabled reason={error}"),
            );
        }
    }
    Ok(result)
}

#[tauri::command]
fn save_date_override(
    app: AppHandle,
    state: tauri::State<'_, RuntimeConfig>,
    date: String,
    kind: Option<domain::DateOverrideKind>,
) -> Result<config::SaveResult, String> {
    let data_dir = app
        .path()
        .app_data_dir()
        .map_err(|error| error.to_string())?;
    let repository = repositories::configuration_repository::FileConfigurationRepository::new(
        data_dir.join("config.json"),
    );
    let result =
        services::configuration_service::save_date_override(&state.0, &repository, &date, kind)?;
    let kind_label = match kind {
        Some(domain::DateOverrideKind::Workday) => "workday",
        Some(domain::DateOverrideKind::PaidRest) => "paid_rest",
        Some(domain::DateOverrideKind::UnpaidRest) => "unpaid_rest",
        None => "automatic",
    };
    let event = match result.status {
        config::SaveStatus::Saved if kind.is_none() => "date_override.removed",
        config::SaveStatus::Saved => "date_override.saved",
        config::SaveStatus::Unchanged => "date_override.unchanged",
        config::SaveStatus::Failed => "date_override.failed",
    };
    append_log(
        &app,
        event,
        &format!(
            "date={date} kind={kind_label} result={}",
            result.message.replace(['\r', '\n'], " ")
        ),
    );
    Ok(result)
}

#[tauri::command]
fn configuration_initialized(state: tauri::State<'_, ConfigurationState>) -> bool {
    state.0.load(Ordering::SeqCst)
}

#[tauri::command]
fn diagnostic_summary(state: tauri::State<'_, RuntimeConfig>) -> Result<String, String> {
    let value = state.0.lock().map_err(|_| "config_lock_failed")?;
    Ok(support::DiagnosticSummary {
        app_version: env!("CARGO_PKG_VERSION").into(),
        config_version: value.config_version,
        platform: "Windows".into(),
        log_level: value.log_level.clone(),
        config_status: "正常".into(),
        native_status: "可用".into(),
    }
    .render())
}

#[tauri::command]
fn data_directory_path(app: AppHandle) -> Result<String, String> {
    let base = app
        .path()
        .app_data_dir()
        .map_err(|error| error.to_string())?;
    Ok(
        support::data_directory(base.parent().unwrap_or(base.as_path()))
            .display()
            .to_string(),
    )
}

#[tauri::command]
fn evaluate_update_response(
    current_version: String,
    response_body: Option<String>,
    failure_reason: Option<String>,
) -> support::UpdateResult {
    let response = match response_body.as_deref() {
        Some(body) => Ok(body),
        None => Err(failure_reason.as_deref().unwrap_or("网络不可用")),
    };
    support::parse_release_response(&current_version, response)
}

#[tauri::command]
fn record_semantic_event(app: AppHandle, event: String, detail: String) -> Result<(), String> {
    if event.is_empty()
        || !event
            .chars()
            .all(|character| character.is_ascii_alphanumeric() || "._-".contains(character))
    {
        return Err("invalid event name".into());
    }
    append_log(&app, &event, &detail);
    Ok(())
}

fn window_spec(label: &str) -> Result<WindowSpec, String> {
    WINDOW_SPECS
        .iter()
        .copied()
        .find(|spec| spec.label == label)
        .ok_or_else(|| format!("unknown window label: {label}"))
}

fn build_window(app: &AppHandle, spec: WindowSpec) -> Result<WebviewWindow, String> {
    append_log(
        app,
        "window.build_started",
        &format!("label={}", spec.label),
    );
    let route = format!("index.html?window={}", spec.label);
    let window = WebviewWindowBuilder::new(app, spec.label, WebviewUrl::App(route.into()))
        .title(spec.title)
        .inner_size(spec.width, spec.height)
        .min_inner_size(spec.min_width, spec.min_height)
        .resizable(spec.resizable)
        .decorations(false)
        .transparent(true)
        .shadow(true)
        .skip_taskbar(spec.skip_taskbar)
        .visible(spec.label == "mini")
        .build()
        .map_err(|error| {
            let reason = format!("failed to create {} window: {error}", spec.label);
            append_log(
                app,
                "window.build_failed",
                &format!("label={} reason={reason}", spec.label),
            );
            reason
        })?;
    append_log(
        app,
        "window.build_completed",
        &format!("label={}", spec.label),
    );
    append_log(
        app,
        "window.position_started",
        &format!("label={} source=initial", spec.label),
    );
    position_new_window(&window, spec.label).map_err(|error| {
        append_log(
            app,
            "window.position_failed",
            &format!("label={} source=initial reason={error}", spec.label),
        );
        error
    })?;
    append_log(
        app,
        "window.position_completed",
        &format!("label={} source=initial", spec.label),
    );
    Ok(window)
}

fn position_new_window(window: &WebviewWindow, label: &str) -> Result<(), String> {
    let Some(monitor) = window
        .current_monitor()
        .ok()
        .flatten()
        .or_else(|| window.primary_monitor().ok().flatten())
    else {
        return Ok(());
    };
    let origin = monitor.position();
    let monitor_size = monitor.size();
    let size = window.inner_size().map_err(|error| error.to_string())?;
    let (x, y) = if label == "mini" {
        (
            origin.x + monitor_size.width as i32 - size.width as i32 - 28,
            origin.y + monitor_size.height as i32 - size.height as i32 - 76,
        )
    } else {
        (
            origin.x + (monitor_size.width as i32 - size.width as i32) / 2,
            origin.y + (monitor_size.height as i32 - size.height as i32) / 2,
        )
    };
    window
        .set_position(Position::Physical(PhysicalPosition::new(x, y)))
        .map_err(|error| error.to_string())
}

fn ensure_window(app: &AppHandle, label: &str) -> Result<WebviewWindow, String> {
    if let Some(window) = app.get_webview_window(label) {
        return Ok(window);
    }
    build_window(app, window_spec(label)?)
}

#[tauri::command]
fn set_mini_window_state(app: AppHandle, state: String) -> Result<(), String> {
    let height = match state.as_str() {
        "normal" | "loading" => 108.0,
        "error" => 120.0,
        _ => return Err("invalid_mini_window_state".into()),
    };
    let window = ensure_window(&app, "mini")?;
    window
        .set_size(Size::Logical(LogicalSize::new(344.0, height)))
        .map_err(|error| error.to_string())?;
    append_log(
        &app,
        "mini.window.size_applied",
        &format!("state={state} width=344 height={height:.0}"),
    );
    if mini_edge_status_internal(&app)?.visibility == "retracted" {
        set_mini_edge_retracted_internal(&app, true, "size_changed", true)?;
    }
    Ok(())
}

fn append_log(app: &AppHandle, event: &str, message: &str) {
    if let Ok(data_dir) = app.path().app_data_dir() {
        let logger = support::RotatingLogger::new(data_dir.join("debug.log"), 2_000_000, 3);
        let _ = logger.append(event, message);
    }
}

fn mini_window_rect(window: &WebviewWindow) -> Result<platform::Rect, String> {
    let position = window.outer_position().map_err(|error| error.to_string())?;
    let size = window.outer_size().map_err(|error| error.to_string())?;
    Ok(platform::Rect {
        x: position.x,
        y: position.y,
        width: size.width,
        height: size.height,
    })
}

fn mini_edge_side(dock: config::MiniEdgeDock) -> Option<platform::EdgeDockSide> {
    match dock {
        config::MiniEdgeDock::Left => Some(platform::EdgeDockSide::Left),
        config::MiniEdgeDock::Right => Some(platform::EdgeDockSide::Right),
        config::MiniEdgeDock::None => None,
    }
}

fn mini_edge_dock(side: platform::EdgeDockSide) -> config::MiniEdgeDock {
    match side {
        platform::EdgeDockSide::Left => config::MiniEdgeDock::Left,
        platform::EdgeDockSide::Right => config::MiniEdgeDock::Right,
    }
}

fn mini_edge_label(dock: config::MiniEdgeDock) -> &'static str {
    match dock {
        config::MiniEdgeDock::Left => "left",
        config::MiniEdgeDock::Right => "right",
        config::MiniEdgeDock::None => "none",
    }
}

fn mini_edge_source(source: &str) -> &'static str {
    match source {
        "pointer_enter" => "pointer_enter",
        "pointer_leave" => "pointer_leave",
        "focus_inside" => "focus_inside",
        "menu_open" => "menu_open",
        "modal_open" => "modal_open",
        "drag_start" => "drag_start",
        "drag_complete" => "drag_complete",
        "lock_released" => "lock_released",
        "refresh" => "refresh",
        "privacy_activate" => "privacy_activate",
        "tray_restore" => "tray_restore",
        "window_shown" => "window_shown",
        "size_changed" => "size_changed",
        "settings_disabled" => "settings_disabled",
        _ => "unknown",
    }
}

fn mini_edge_status_internal(app: &AppHandle) -> Result<MiniEdgeStatus, String> {
    let auto_hide = app
        .state::<RuntimeConfig>()
        .0
        .lock()
        .map(|config| config.mini_edge_auto_hide)
        .map_err(|_| "config_lock_failed".to_string())?;
    let mini_edge_runtime = app.state::<MiniEdgeRuntime>();
    let state = mini_edge_runtime
        .state
        .lock()
        .map_err(|_| "mini_edge_state_lock_failed".to_string())?;
    let dock = if auto_hide {
        state.dock
    } else {
        config::MiniEdgeDock::None
    };
    Ok(MiniEdgeStatus {
        auto_hide,
        dock,
        visibility: match state.visibility {
            MiniEdgeVisibility::Expanded => "expanded",
            MiniEdgeVisibility::Retracted => "retracted",
        },
        notice: None,
    })
}

fn mini_edge_position_persistence_suppressed(app: &AppHandle) -> bool {
    app.state::<MiniEdgeRuntime>()
        .state
        .lock()
        .map(|state| {
            state.suppress_position_persistence || state.visibility == MiniEdgeVisibility::Retracted
        })
        .unwrap_or(true)
}

fn update_runtime_mini_edge_config(
    app: &AppHandle,
    dock: config::MiniEdgeDock,
    position: Option<(i32, i32)>,
) -> Result<(), String> {
    let runtime_config = app.state::<RuntimeConfig>();
    let mut runtime = runtime_config
        .0
        .lock()
        .map_err(|_| "config_lock_failed".to_string())?;
    runtime.mini_edge_dock = dock;
    if let Some((x, y)) = position {
        runtime.mini_window_position = Some(config::WindowPosition {
            x: f64::from(x),
            y: f64::from(y),
        });
    }
    Ok(())
}

fn set_mini_edge_runtime_state(
    app: &AppHandle,
    dock: config::MiniEdgeDock,
    visibility: MiniEdgeVisibility,
    suppress_position_persistence: bool,
) -> Result<(), String> {
    let mini_edge_runtime = app.state::<MiniEdgeRuntime>();
    let mut state = mini_edge_runtime
        .state
        .lock()
        .map_err(|_| "mini_edge_state_lock_failed".to_string())?;
    state.dock = dock;
    state.visibility = visibility;
    state.suppress_position_persistence = suppress_position_persistence;
    Ok(())
}

fn mini_saved_window_rect(
    app: &AppHandle,
    window: &WebviewWindow,
) -> Result<platform::Rect, String> {
    let mut rect = mini_window_rect(window)?;
    let position = app
        .state::<RuntimeConfig>()
        .0
        .lock()
        .map_err(|_| "config_lock_failed".to_string())?
        .mini_window_position
        .clone();
    if let Some(position) = position {
        rect.x = position.x.round() as i32;
        rect.y = position.y.round() as i32;
    }
    Ok(rect)
}

fn mini_saved_center_is_on_available_monitor(
    app: &AppHandle,
    window: &WebviewWindow,
) -> Result<bool, String> {
    let rect = mini_saved_window_rect(app, window)?;
    mini_rect_center_is_on_available_monitor(window, rect)
}

fn mini_rect_center_is_on_available_monitor(
    window: &WebviewWindow,
    rect: platform::Rect,
) -> Result<bool, String> {
    let center_x = rect.x.saturating_add((rect.width / 2) as i32);
    let center_y = rect.y.saturating_add((rect.height / 2) as i32);
    let monitors = window
        .available_monitors()
        .map_err(|error| error.to_string())?;
    Ok(monitors.iter().any(|monitor| {
        let origin = monitor.position();
        let size = monitor.size();
        platform::point_in_rect(
            center_x,
            center_y,
            platform::Rect {
                x: origin.x,
                y: origin.y,
                width: size.width,
                height: size.height,
            },
        )
    }))
}

fn animate_mini_position(
    app: &AppHandle,
    window: &WebviewWindow,
    target: (i32, i32),
    reduced_motion: bool,
) -> Result<(), String> {
    let origin = window.outer_position().map_err(|error| error.to_string())?;
    let revision = app
        .state::<MiniEdgeRuntime>()
        .animation_revision
        .fetch_add(1, Ordering::SeqCst)
        + 1;
    if reduced_motion || (origin.x == target.0 && origin.y == target.1) {
        return window
            .set_position(Position::Physical(PhysicalPosition::new(
                target.0, target.1,
            )))
            .map_err(|_| "mini_edge_move_failed".to_string());
    }
    const STEPS: u64 = 6;
    for step in 1..=STEPS {
        if app
            .state::<MiniEdgeRuntime>()
            .animation_revision
            .load(Ordering::SeqCst)
            != revision
        {
            return Ok(());
        }
        let progress = step as f64 / STEPS as f64;
        let eased = 1.0 - (1.0 - progress).powi(3);
        let x = f64::from(origin.x) + f64::from(target.0 - origin.x) * eased;
        let y = f64::from(origin.y) + f64::from(target.1 - origin.y) * eased;
        window
            .set_position(Position::Physical(PhysicalPosition::new(
                x.round() as i32,
                y.round() as i32,
            )))
            .map_err(|_| "mini_edge_move_failed".to_string())?;
        if step < STEPS {
            thread::sleep(Duration::from_millis(
                platform::MINI_EDGE_TRANSITION_MS / STEPS,
            ));
        }
    }
    Ok(())
}

fn mini_primary_work_area(
    window: &WebviewWindow,
    rect: platform::Rect,
) -> Result<platform::Rect, String> {
    let primary = window
        .primary_monitor()
        .map_err(|error| error.to_string())?
        .ok_or_else(|| "primary_monitor_unavailable".to_string())?;
    let origin = primary.position();
    let size = primary.size();
    platform::work_area_for_rect(platform::Rect {
        x: origin.x,
        y: origin.y,
        width: size.width.max(rect.width),
        height: size.height.max(rect.height),
    })
}

fn persist_mini_edge_snapshot(app: &AppHandle) {
    if let Err(error) = persist_runtime_mini_position(app) {
        append_log(
            app,
            "mini.edge_dock.failed",
            &format!("stage=persist reason={error}"),
        );
    }
}

fn restore_mini_edge_fallback(
    app: &AppHandle,
    window: &WebviewWindow,
    reason: &str,
) -> Result<MiniEdgeStatus, String> {
    let rect = mini_window_rect(window)?;
    let scale = window.scale_factor().map_err(|error| error.to_string())?;
    let work_area = mini_primary_work_area(window, rect)
        .or_else(|_| platform::work_area_for_rect(rect))
        .map_err(|error| {
            append_log(
                app,
                "mini.edge_dock.failed",
                &format!("stage=fallback_work_area reason={error}"),
            );
            error
        })?;
    let target = platform::fallback_to_work_area(
        rect,
        work_area,
        scale,
        platform::MINI_EDGE_FALLBACK_MARGIN_LOGICAL_PX,
    );
    set_mini_edge_runtime_state(
        app,
        config::MiniEdgeDock::None,
        MiniEdgeVisibility::Expanded,
        true,
    )?;
    window
        .set_position(Position::Physical(PhysicalPosition::new(
            target.0, target.1,
        )))
        .map_err(|error| error.to_string())?;
    update_runtime_mini_edge_config(app, config::MiniEdgeDock::None, Some(target))?;
    set_mini_edge_runtime_state(
        app,
        config::MiniEdgeDock::None,
        MiniEdgeVisibility::Expanded,
        false,
    )?;
    append_log(
        app,
        "mini.edge_dock.restore_fallback",
        &format!("reason={}", mini_edge_source(reason)),
    );
    persist_mini_edge_snapshot(app);
    let mut status = mini_edge_status_internal(app)?;
    status.notice = Some("fallback");
    Ok(status)
}

fn set_mini_edge_retracted_internal(
    app: &AppHandle,
    retracted: bool,
    source: &str,
    reduced_motion: bool,
) -> Result<MiniEdgeStatus, String> {
    let status = mini_edge_status_internal(app)?;
    if !status.auto_hide || status.dock == config::MiniEdgeDock::None {
        return Ok(status);
    }
    let window = ensure_window(app, "mini")?;
    if !mini_saved_center_is_on_available_monitor(app, &window).unwrap_or(false) {
        return restore_mini_edge_fallback(app, &window, source);
    }
    let rect = mini_window_rect(&window)?;
    let scale = window.scale_factor().map_err(|error| error.to_string())?;
    let work_area = match platform::work_area_for_rect(rect) {
        Ok(value) => value,
        Err(_) => return restore_mini_edge_fallback(app, &window, source),
    };
    let side = mini_edge_side(status.dock).ok_or_else(|| "mini_edge_side_missing".to_string())?;
    let positions = platform::edge_dock_positions(
        rect,
        work_area,
        side,
        scale,
        platform::MINI_EDGE_PRIVACY_TAB_LOGICAL_PX,
    );
    let visibility = if retracted {
        MiniEdgeVisibility::Retracted
    } else {
        MiniEdgeVisibility::Expanded
    };
    set_mini_edge_runtime_state(app, status.dock, visibility, true)?;
    let target = if retracted {
        positions.retracted
    } else {
        positions.expanded
    };
    if let Err(error) = animate_mini_position(app, &window, target, reduced_motion) {
        append_log(
            app,
            "mini.edge_dock.failed",
            &format!(
                "stage={} side={} reason={error}",
                if retracted { "retract" } else { "reveal" },
                mini_edge_label(status.dock)
            ),
        );
        return restore_mini_edge_fallback(app, &window, source);
    }
    set_mini_edge_runtime_state(app, status.dock, visibility, false)?;
    if !retracted {
        update_runtime_mini_edge_config(app, status.dock, Some(positions.expanded))?;
    }
    append_log(
        app,
        if retracted {
            "mini.edge_dock.retracted"
        } else {
            "mini.edge_dock.revealed"
        },
        &format!(
            "side={} source={}",
            mini_edge_label(status.dock),
            mini_edge_source(source)
        ),
    );
    mini_edge_status_internal(app)
}

fn complete_mini_drag_internal(
    app: &AppHandle,
    reduced_motion: bool,
) -> Result<MiniEdgeStatus, String> {
    let window = ensure_window(app, "mini")?;
    let rect = mini_window_rect(&window)?;
    let scale = window.scale_factor().map_err(|error| error.to_string())?;
    let auto_hide = app
        .state::<RuntimeConfig>()
        .0
        .lock()
        .map(|config| config.mini_edge_auto_hide)
        .map_err(|_| "config_lock_failed".to_string())?;
    let current_dock = app
        .state::<MiniEdgeRuntime>()
        .state
        .lock()
        .map(|state| state.dock)
        .map_err(|_| "mini_edge_state_lock_failed".to_string())?;

    if !auto_hide {
        update_runtime_mini_edge_config(app, config::MiniEdgeDock::None, Some((rect.x, rect.y)))?;
        set_mini_edge_runtime_state(
            app,
            config::MiniEdgeDock::None,
            MiniEdgeVisibility::Expanded,
            false,
        )?;
        persist_mini_edge_snapshot(app);
        return mini_edge_status_internal(app);
    }

    let work_area = match platform::work_area_for_rect(rect) {
        Ok(value) => value,
        Err(_) => return restore_mini_edge_fallback(app, &window, "drag_start"),
    };
    let detected = platform::detect_edge_dock_with_preference(
        rect,
        work_area,
        scale,
        platform::MINI_EDGE_DOCK_THRESHOLD_LOGICAL_PX,
        mini_edge_side(current_dock),
    );
    let retained = if detected.is_none() {
        mini_edge_side(current_dock).filter(|side| {
            let work_right = work_area.x.saturating_add(work_area.width as i32);
            let window_right = rect.x.saturating_add(rect.width as i32);
            let inward = match side {
                platform::EdgeDockSide::Left => rect.x.saturating_sub(work_area.x),
                platform::EdgeDockSide::Right => work_right.saturating_sub(window_right),
            };
            !platform::should_undock(
                inward,
                scale,
                platform::MINI_EDGE_UNDOCK_THRESHOLD_LOGICAL_PX,
            )
        })
    } else {
        None
    };
    let chosen = detected.or(retained);

    if let Some(side) = chosen {
        let dock = mini_edge_dock(side);
        let positions = platform::edge_dock_positions(
            rect,
            work_area,
            side,
            scale,
            platform::MINI_EDGE_PRIVACY_TAB_LOGICAL_PX,
        );
        set_mini_edge_runtime_state(app, dock, MiniEdgeVisibility::Expanded, true)?;
        if let Err(error) = animate_mini_position(app, &window, positions.expanded, reduced_motion)
        {
            append_log(
                app,
                "mini.edge_dock.failed",
                &format!(
                    "stage=drag_dock side={} reason={error}",
                    mini_edge_label(dock)
                ),
            );
            return restore_mini_edge_fallback(app, &window, "drag_start");
        }
        if let Err(error) = update_runtime_mini_edge_config(app, dock, Some(positions.expanded)) {
            append_log(
                app,
                "mini.edge_dock.failed",
                &format!(
                    "stage=drag_state side={} reason={error}",
                    mini_edge_label(dock)
                ),
            );
            return restore_mini_edge_fallback(app, &window, "drag_start");
        }
        set_mini_edge_runtime_state(app, dock, MiniEdgeVisibility::Expanded, false)?;
        append_log(
            app,
            "mini.edge_dock.detected",
            &format!("side={}", mini_edge_label(dock)),
        );
    } else {
        if let Err(error) = safe_window_position(&window) {
            append_log(
                app,
                "mini.edge_dock.failed",
                &format!("stage=drag_float reason={error}"),
            );
            return restore_mini_edge_fallback(app, &window, "drag_start");
        }
        let position = window.outer_position().map_err(|error| error.to_string())?;
        update_runtime_mini_edge_config(
            app,
            config::MiniEdgeDock::None,
            Some((position.x, position.y)),
        )?;
        set_mini_edge_runtime_state(
            app,
            config::MiniEdgeDock::None,
            MiniEdgeVisibility::Expanded,
            false,
        )?;
        if current_dock != config::MiniEdgeDock::None {
            append_log(
                app,
                "mini.edge_dock.canceled",
                &format!("previous_side={}", mini_edge_label(current_dock)),
            );
        }
    }
    persist_mini_edge_snapshot(app);
    mini_edge_status_internal(app)
}

fn disable_mini_edge_auto_hide_internal(app: &AppHandle) -> Result<(), String> {
    let dock = app
        .state::<MiniEdgeRuntime>()
        .state
        .lock()
        .map(|state| state.dock)
        .map_err(|_| "mini_edge_state_lock_failed".to_string())?;
    let window = ensure_window(app, "mini")?;
    if dock != config::MiniEdgeDock::None {
        if !mini_saved_center_is_on_available_monitor(app, &window).unwrap_or(false) {
            restore_mini_edge_fallback(app, &window, "settings_disabled")?;
            return Ok(());
        }
        let result = (|| -> Result<(), String> {
            let rect = mini_saved_window_rect(app, &window)?;
            let side = mini_edge_side(dock).ok_or_else(|| "mini_edge_side_missing".to_string())?;
            let work_area = platform::work_area_for_rect(rect)?;
            let scale = window.scale_factor().map_err(|error| error.to_string())?;
            let positions = platform::edge_dock_positions(
                rect,
                work_area,
                side,
                scale,
                platform::MINI_EDGE_PRIVACY_TAB_LOGICAL_PX,
            );
            set_mini_edge_runtime_state(app, dock, MiniEdgeVisibility::Expanded, true)?;
            animate_mini_position(app, &window, positions.expanded, true)?;
            update_runtime_mini_edge_config(
                app,
                config::MiniEdgeDock::None,
                Some(positions.expanded),
            )?;
            Ok(())
        })();
        if let Err(error) = result {
            append_log(
                app,
                "mini.edge_dock.failed",
                &format!("stage=settings_disabled reason={error}"),
            );
            restore_mini_edge_fallback(app, &window, "settings_disabled")?;
            return Ok(());
        }
    }
    set_mini_edge_runtime_state(
        app,
        config::MiniEdgeDock::None,
        MiniEdgeVisibility::Expanded,
        false,
    )?;
    append_log(app, "mini.edge_dock.canceled", "reason=settings_disabled");
    persist_mini_edge_snapshot(app);
    Ok(())
}

fn safe_window_position(window: &WebviewWindow) -> Result<(), String> {
    let position = window.outer_position().map_err(|error| error.to_string())?;
    let size = window.outer_size().map_err(|error| error.to_string())?;
    let window_rect = platform::Rect {
        x: position.x,
        y: position.y,
        width: size.width,
        height: size.height,
    };
    if let Ok(work_area) = platform::work_area_for_rect(window_rect) {
        let scale = window.scale_factor().map_err(|error| error.to_string())?;
        let (x, y) = platform::fallback_to_work_area(
            window_rect,
            work_area,
            scale,
            platform::MINI_EDGE_FALLBACK_MARGIN_LOGICAL_PX,
        );
        if x != position.x || y != position.y {
            window
                .set_position(Position::Physical(PhysicalPosition::new(x, y)))
                .map_err(|error| error.to_string())?;
        }
        return Ok(());
    }
    let monitors = window
        .available_monitors()
        .map_err(|error| error.to_string())?;
    let center_x = position.x.saturating_add((size.width / 2) as i32);
    let center_y = position.y.saturating_add((size.height / 2) as i32);
    let selected = monitors
        .iter()
        .find(|monitor| {
            let origin = monitor.position();
            let monitor_size = monitor.size();
            platform::point_in_rect(
                center_x,
                center_y,
                platform::Rect {
                    x: origin.x,
                    y: origin.y,
                    width: monitor_size.width,
                    height: monitor_size.height,
                },
            )
        })
        .cloned()
        .or_else(|| window.primary_monitor().ok().flatten())
        .or_else(|| monitors.into_iter().next());

    let Some(monitor) = selected else {
        return Ok(());
    };
    let origin = monitor.position();
    let monitor_size = monitor.size();
    let (x, y) = platform::clamp_window_to_monitor(
        window_rect,
        platform::Rect {
            x: origin.x,
            y: origin.y,
            width: monitor_size.width,
            height: monitor_size.height,
        },
        12,
    );
    if x != position.x || y != position.y {
        window
            .set_position(Position::Physical(PhysicalPosition::new(x, y)))
            .map_err(|error| error.to_string())?;
    }
    Ok(())
}

fn apply_window_policy(app: &AppHandle, window: &WebviewWindow, label: &str) -> Result<(), String> {
    let spec = window_spec(label)?;
    append_log(app, "window.policy_started", &format!("label={label}"));
    window
        .set_skip_taskbar(spec.skip_taskbar)
        .map_err(|error| error.to_string())?;
    append_log(
        app,
        "window.taskbar_policy_applied",
        &format!("label={label} skip_taskbar={}", spec.skip_taskbar),
    );
    if label == "mini" {
        let config = app
            .state::<RuntimeConfig>()
            .0
            .lock()
            .map(|config| config.clone())
            .unwrap_or_default();
        window
            .set_always_on_top(config.mini_window_always_on_top)
            .map_err(|error| error.to_string())?;
        if let Some(position) = config.mini_window_position {
            window
                .set_position(Position::Physical(PhysicalPosition::new(
                    position.x.round() as i32,
                    position.y.round() as i32,
                )))
                .map_err(|error| error.to_string())?;
        } else {
            position_new_window(window, label)?;
        }
        let saved_monitor_available =
            mini_saved_center_is_on_available_monitor(app, window).unwrap_or(false);
        if !saved_monitor_available {
            restore_mini_edge_fallback(app, window, "window_shown")?;
        } else {
            let restore_result = (|| -> Result<(), String> {
                safe_window_position(window)?;
                if config.mini_edge_auto_hide && config.mini_edge_dock != config::MiniEdgeDock::None
                {
                    let rect = mini_saved_window_rect(app, window)?;
                    let scale = window.scale_factor().map_err(|error| error.to_string())?;
                    let work_area = platform::work_area_for_rect(rect)
                        .map_err(|_| "mini_edge_work_area_unavailable".to_string())?;
                    let side = mini_edge_side(config.mini_edge_dock)
                        .ok_or_else(|| "mini_edge_side_missing".to_string())?;
                    let positions = platform::edge_dock_positions(
                        rect,
                        work_area,
                        side,
                        scale,
                        platform::MINI_EDGE_PRIVACY_TAB_LOGICAL_PX,
                    );
                    set_mini_edge_runtime_state(
                        app,
                        config.mini_edge_dock,
                        MiniEdgeVisibility::Expanded,
                        true,
                    )?;
                    window
                        .set_position(Position::Physical(PhysicalPosition::new(
                            positions.expanded.0,
                            positions.expanded.1,
                        )))
                        .map_err(|error| error.to_string())?;
                    update_runtime_mini_edge_config(
                        app,
                        config.mini_edge_dock,
                        Some(positions.expanded),
                    )?;
                    set_mini_edge_runtime_state(
                        app,
                        config.mini_edge_dock,
                        MiniEdgeVisibility::Expanded,
                        false,
                    )?;
                } else {
                    set_mini_edge_runtime_state(
                        app,
                        config::MiniEdgeDock::None,
                        MiniEdgeVisibility::Expanded,
                        false,
                    )?;
                }
                Ok(())
            })();
            if let Err(error) = restore_result {
                append_log(
                    app,
                    "mini.edge_dock.failed",
                    &format!("stage=window_shown reason={error}"),
                );
                restore_mini_edge_fallback(app, window, "window_shown")?;
            }
        }
    }
    append_log(
        app,
        "window.position_started",
        &format!("label={label} source=safe_area"),
    );
    if label != "mini" {
        safe_window_position(window)?;
    }
    append_log(
        app,
        "window.position_completed",
        &format!("label={label} source=safe_area"),
    );
    append_log(
        app,
        "window.policy_applied",
        &format!("label={label} skip_taskbar={}", spec.skip_taskbar),
    );
    Ok(())
}

fn window_show_error(app: &AppHandle, label: &str, stage: &str, error: String) -> String {
    append_log(
        app,
        "window.show_failed",
        &format!("label={label} stage={stage} reason={error}"),
    );
    error
}

#[cfg(target_os = "windows")]
fn suspend_webview_internal(app: &AppHandle, window: &WebviewWindow, label: &str) {
    append_log(
        app,
        "window.webview_suspend_requested",
        &format!("label={label}"),
    );
    let callback_app = app.clone();
    let callback_label = label.to_string();
    if let Err(error) = window.with_webview(move |webview| {
        let controller = webview.controller();
        if let Err(error) = unsafe { controller.SetIsVisible(false) } {
            append_log(
                &callback_app,
                "window.webview_suspend_failed",
                &format!("label={} stage=visibility reason={error}", callback_label),
            );
            return;
        }
        let core = unsafe {
            controller
                .CoreWebView2()
                .and_then(|core| core.cast::<ICoreWebView2_3>())
        };
        let core = match core {
            Ok(core) => core,
            Err(error) => {
                append_log(
                    &callback_app,
                    "window.webview_suspend_failed",
                    &format!("label={} stage=controller reason={error}", callback_label),
                );
                return;
            }
        };

        let completion_app = callback_app.clone();
        let completion_label = callback_label.clone();
        let handler = TrySuspendCompletedHandler::create(Box::new(move |result, suspended| {
            match result {
                Ok(()) => append_log(
                    &completion_app,
                    "window.webview_suspend_completed",
                    &format!("label={completion_label} suspended={suspended}"),
                ),
                Err(error) => append_log(
                    &completion_app,
                    "window.webview_suspend_failed",
                    &format!("label={completion_label} stage=completion reason={error}"),
                ),
            }
            Ok(())
        }));

        if let Err(error) = unsafe { core.TrySuspend(&handler) } {
            append_log(
                &callback_app,
                "window.webview_suspend_failed",
                &format!("label={} stage=request reason={error}", callback_label),
            );
        }
    }) {
        append_log(
            app,
            "window.webview_suspend_failed",
            &format!("label={label} stage=dispatch reason={error}"),
        );
    }
}

#[cfg(not(target_os = "windows"))]
fn suspend_webview_internal(_app: &AppHandle, _window: &WebviewWindow, _label: &str) {}

#[cfg(target_os = "windows")]
fn resume_webview_internal(app: &AppHandle, window: &WebviewWindow, label: &str) {
    append_log(
        app,
        "window.webview_resume_requested",
        &format!("label={label}"),
    );
    let callback_app = app.clone();
    let callback_label = label.to_string();
    if let Err(error) = window.with_webview(move |webview| {
        let controller = webview.controller();
        let resume_result = unsafe {
            controller
                .CoreWebView2()
                .and_then(|core| core.cast::<ICoreWebView2_3>())
                .and_then(|core| core.Resume())
        };
        let visibility_result = unsafe { controller.SetIsVisible(true) };
        match (resume_result, visibility_result) {
            (Ok(()), Ok(())) => append_log(
                &callback_app,
                "window.webview_resume_completed",
                &format!("label={callback_label}"),
            ),
            (Err(error), _) => append_log(
                &callback_app,
                "window.webview_resume_failed",
                &format!("label={callback_label} stage=resume reason={error}"),
            ),
            (Ok(()), Err(error)) => append_log(
                &callback_app,
                "window.webview_resume_failed",
                &format!("label={callback_label} stage=visibility reason={error}"),
            ),
        }
    }) {
        append_log(
            app,
            "window.webview_resume_failed",
            &format!("label={label} stage=dispatch reason={error}"),
        );
    }
}

#[cfg(not(target_os = "windows"))]
fn resume_webview_internal(_app: &AppHandle, _window: &WebviewWindow, _label: &str) {}

fn show_window_internal(app: &AppHandle, label: &str) -> Result<(), String> {
    append_log(app, "window.show_requested", &format!("label={label}"));
    let window = ensure_window(app, label)
        .map_err(|error| window_show_error(app, label, "ensure", error))?;
    append_log(app, "window.ensure_completed", &format!("label={label}"));
    apply_window_policy(app, &window, label)
        .map_err(|error| window_show_error(app, label, "policy", error))?;
    resume_webview_internal(app, &window, label);
    window
        .show()
        .map_err(|error| window_show_error(app, label, "show", error.to_string()))?;
    append_log(app, "window.visible", &format!("label={label}"));
    window
        .unminimize()
        .map_err(|error| window_show_error(app, label, "unminimize", error.to_string()))?;
    window.set_focus().map_err(|error| {
        append_log(
            app,
            "window.activation_failed",
            &format!("label={label} reason={error}"),
        );
        window_show_error(app, label, "focus", error.to_string())
    })?;
    append_log(app, "window.focused", &format!("label={label}"));
    if let Err(error) = window.eval("window.dispatchEvent(new CustomEvent('lmm:window-shown'))") {
        append_log(
            app,
            "window.lifecycle_event_failed",
            &format!("label={label} event=shown reason={error}"),
        );
    }
    append_log(app, "window.shown", &format!("label={label}"));
    Ok(())
}

fn hide_window_internal(app: &AppHandle, label: &str) -> Result<(), String> {
    let window = ensure_window(app, label)?;
    if let Err(error) = window.eval("window.dispatchEvent(new CustomEvent('lmm:window-hidden'))") {
        append_log(
            app,
            "window.lifecycle_event_failed",
            &format!("label={label} event=hidden reason={error}"),
        );
    }
    window.hide().map_err(|error| error.to_string())?;
    append_log(app, "window.hidden", &format!("label={label}"));
    suspend_webview_internal(app, &window, label);
    Ok(())
}

fn toggle_mini_window(app: &AppHandle) -> Result<(), String> {
    let window = ensure_window(app, "mini")?;
    if window.is_visible().map_err(|error| error.to_string())? {
        if mini_edge_status_internal(app)?.visibility == "retracted" {
            set_mini_edge_retracted_internal(app, false, "tray_restore", true)?;
            window.set_focus().map_err(|error| error.to_string())?;
            if let Err(error) =
                window.eval("window.dispatchEvent(new CustomEvent('lmm:window-shown'))")
            {
                append_log(
                    app,
                    "window.lifecycle_event_failed",
                    &format!("label=mini event=shown reason={error}"),
                );
            }
            return Ok(());
        }
        hide_window_internal(app, "mini")
    } else {
        show_window_internal(app, "mini")
    }
}

fn open_data_directory_internal(app: &AppHandle) -> Result<String, String> {
    let base = app
        .path()
        .app_data_dir()
        .map_err(|error| error.to_string())?;
    std::fs::create_dir_all(&base).map_err(|error| error.to_string())?;
    Command::new("explorer.exe")
        .arg(&base)
        .spawn()
        .map_err(|error| error.to_string())?;
    append_log(app, "support.data_directory_opened", "result=success");
    Ok(base.display().to_string())
}

#[tauri::command]
fn platform_capabilities(
    state: tauri::State<'_, PlatformRuntime>,
) -> Result<PlatformCapabilities, String> {
    state
        .0
        .lock()
        .map(|status| status.clone())
        .map_err(|_| "platform_status_lock_failed".into())
}

fn dispatch_tray_command(app: &AppHandle, id: &str) {
    append_log(app, "tray.command", &format!("id={id}"));
    if !platform::is_known_tray_command(id) {
        append_log(
            app,
            "tray.command_failed",
            &format!("id={id} reason=unknown"),
        );
        return;
    }
    let result = match id {
        platform::TRAY_TOGGLE_MINI => toggle_mini_window(app),
        platform::TRAY_WORKBENCH => show_window_internal(app, "workbench"),
        platform::TRAY_SETTINGS => show_window_internal(app, "settings"),
        platform::TRAY_WIZARD => show_window_internal(app, "wizard"),
        platform::TRAY_DATA_DIR => open_data_directory_internal(app).map(|_| ()),
        platform::TRAY_EXIT => {
            app.state::<ExitState>().0.store(true, Ordering::SeqCst);
            append_log(app, "app.exit_requested", "source=tray");
            app.exit(0);
            Ok(())
        }
        _ => unreachable!("known tray command must be handled"),
    };
    if let Err(error) = result {
        append_log(
            app,
            "tray.command_failed",
            &format!("id={id} reason={error}"),
        );
    }
}

fn build_tray(app: &AppHandle) -> Result<(), String> {
    let toggle = MenuItem::with_id(
        app,
        platform::TRAY_TOGGLE_MINI,
        "显示 / 隐藏迷你收入",
        true,
        None::<&str>,
    )
    .map_err(|error| error.to_string())?;
    let workbench = MenuItem::with_id(
        app,
        platform::TRAY_WORKBENCH,
        "打开今日工作台",
        true,
        None::<&str>,
    )
    .map_err(|error| error.to_string())?;
    let settings = MenuItem::with_id(app, platform::TRAY_SETTINGS, "偏好设置", true, None::<&str>)
        .map_err(|error| error.to_string())?;
    let wizard = MenuItem::with_id(app, platform::TRAY_WIZARD, "重新配置", true, None::<&str>)
        .map_err(|error| error.to_string())?;
    let data_dir = MenuItem::with_id(
        app,
        platform::TRAY_DATA_DIR,
        "打开数据目录",
        true,
        None::<&str>,
    )
    .map_err(|error| error.to_string())?;
    let exit = MenuItem::with_id(
        app,
        platform::TRAY_EXIT,
        "退出 LetsMakeMoney",
        true,
        None::<&str>,
    )
    .map_err(|error| error.to_string())?;
    let separator = PredefinedMenuItem::separator(app).map_err(|error| error.to_string())?;
    let menu = Menu::with_items(
        app,
        &[
            &toggle, &workbench, &settings, &wizard, &data_dir, &separator, &exit,
        ],
    )
    .map_err(|error| error.to_string())?;

    let mut tray = TrayIconBuilder::with_id("main")
        .menu(&menu)
        .show_menu_on_left_click(false)
        .tooltip("LetsMakeMoney")
        .on_menu_event(|app, event| dispatch_tray_command(app, event.id().as_ref()))
        .on_tray_icon_event(|tray, event| {
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            } = event
            {
                let app = tray.app_handle();
                append_log(app, "tray.left_click", "action=toggle_mini");
                if let Err(error) = toggle_mini_window(app) {
                    append_log(app, "tray.left_click_failed", &error);
                }
            }
        });
    if let Some(icon) = app.default_window_icon().cloned() {
        tray = tray.icon(icon);
    }
    tray.build(app).map_err(|error| error.to_string())?;
    append_log(
        app,
        "tray.registered",
        "provider=tray-icon-0.24.1 explorer_recovery=TaskbarCreated",
    );
    Ok(())
}

#[tauri::command]
fn implementation_phase() -> &'static str {
    "M6"
}

#[tauri::command]
async fn show_app_window(app: AppHandle, label: String) -> Result<(), String> {
    let task_app = app.clone();
    let task_label = label.clone();
    tauri::async_runtime::spawn_blocking(move || show_window_internal(&task_app, &task_label))
        .await
        .map_err(|error| {
            window_show_error(
                &app,
                &label,
                "dispatch",
                format!("window show task failed: {error}"),
            )
        })?
}

#[tauri::command]
fn hide_app_window(app: AppHandle, label: String) -> Result<(), String> {
    hide_window_internal(&app, &label)
}

#[tauri::command]
fn move_app_window(app: AppHandle, label: String, x: i32, y: i32) -> Result<(), String> {
    let window = ensure_window(&app, &label)?;
    window
        .set_position(Position::Physical(PhysicalPosition::new(x, y)))
        .map_err(|error| error.to_string())?;
    safe_window_position(&window)
}

#[tauri::command]
fn window_drag_origin(app: AppHandle, label: String) -> Result<WindowDragOrigin, String> {
    let window = ensure_window(&app, &label)?;
    let position = window.outer_position().map_err(|error| error.to_string())?;
    Ok(WindowDragOrigin {
        x: position.x,
        y: position.y,
        scale_factor: window.scale_factor().map_err(|error| error.to_string())?,
    })
}

#[tauri::command]
fn mini_edge_status(app: AppHandle) -> Result<MiniEdgeStatus, String> {
    mini_edge_status_internal(&app)
}

#[tauri::command]
fn complete_mini_drag(app: AppHandle, reduced_motion: bool) -> Result<MiniEdgeStatus, String> {
    complete_mini_drag_internal(&app, reduced_motion)
}

#[tauri::command]
fn set_mini_edge_retracted(
    app: AppHandle,
    retracted: bool,
    source: String,
    reduced_motion: bool,
) -> Result<MiniEdgeStatus, String> {
    set_mini_edge_retracted_internal(&app, retracted, &source, reduced_motion)
}

fn persist_runtime_mini_position(app: &AppHandle) -> Result<(), String> {
    let data_dir = app
        .path()
        .app_data_dir()
        .map_err(|error| error.to_string())?;
    let repository = repositories::configuration_repository::FileConfigurationRepository::new(
        data_dir.join("config.json"),
    );
    let outcome = services::configuration_service::persist_runtime_snapshot(
        &app.state::<RuntimeConfig>().0,
        &repository,
    )?;
    match outcome.result.status {
        config::SaveStatus::Saved | config::SaveStatus::Unchanged => {
            if outcome.mini_window_position.is_some() {
                append_log(app, "window.position_saved", "label=mini result=success");
            }
            Ok(())
        }
        config::SaveStatus::Failed => Err(outcome.result.message),
    }
}

fn schedule_mini_position_save(app: &AppHandle, position: PhysicalPosition<i32>) {
    if mini_edge_position_persistence_suppressed(app) {
        return;
    }
    if let Ok(mut config) = app.state::<RuntimeConfig>().0.lock() {
        config.mini_window_position = Some(config::WindowPosition {
            x: position.x as f64,
            y: position.y as f64,
        });
    }
    let revision = app
        .state::<PositionSaveRevision>()
        .0
        .fetch_add(1, Ordering::SeqCst)
        + 1;
    let app = app.clone();
    thread::spawn(move || {
        thread::sleep(Duration::from_millis(300));
        if app.state::<PositionSaveRevision>().0.load(Ordering::SeqCst) == revision {
            if mini_edge_position_persistence_suppressed(&app) {
                return;
            }
            if let Err(error) = persist_runtime_mini_position(&app) {
                append_log(
                    &app,
                    "window.position_save_failed",
                    &format!("label=mini reason={error}"),
                );
            }
        }
    });
}

#[tauri::command]
fn toggle_mini(app: AppHandle) -> Result<(), String> {
    toggle_mini_window(&app)
}

#[tauri::command]
fn open_data_directory(app: AppHandle) -> Result<String, String> {
    open_data_directory_internal(&app)
}

#[tauri::command]
fn exit_application(app: AppHandle) {
    app.state::<ExitState>().0.store(true, Ordering::SeqCst);
    append_log(&app, "app.exit_requested", "source=ui");
    app.exit(0);
}

#[tauri::command]
fn window_snapshot(app: AppHandle, label: String) -> Result<WindowSnapshot, String> {
    let Some(window) = app.get_webview_window(&label) else {
        return Ok(WindowSnapshot {
            label,
            exists: false,
            visible: false,
            focused: false,
            scale_factor: 1.0,
            width: 0,
            height: 0,
        });
    };
    let size = window.inner_size().map_err(|error| error.to_string())?;
    Ok(WindowSnapshot {
        label,
        exists: true,
        visible: window.is_visible().map_err(|error| error.to_string())?,
        focused: window.is_focused().map_err(|error| error.to_string())?,
        scale_factor: window.scale_factor().map_err(|error| error.to_string())?,
        width: size.width,
        height: size.height,
    })
}

#[cfg(target_os = "windows")]
mod single_instance {
    use std::ffi::c_void;
    use std::ptr;

    type Handle = *mut c_void;
    const ERROR_ALREADY_EXISTS: u32 = 183;
    const SW_RESTORE: i32 = 9;

    #[link(name = "kernel32")]
    extern "system" {
        fn CreateMutexW(
            mutex_attributes: *const c_void,
            initial_owner: i32,
            name: *const u16,
        ) -> Handle;
        fn GetLastError() -> u32;
        fn CloseHandle(object: Handle) -> i32;
    }

    #[link(name = "user32")]
    extern "system" {
        fn FindWindowW(class_name: *const u16, window_name: *const u16) -> Handle;
        fn ShowWindow(window: Handle, command: i32) -> i32;
        fn SetForegroundWindow(window: Handle) -> i32;
    }

    pub struct Guard(Handle);

    unsafe impl Send for Guard {}
    unsafe impl Sync for Guard {}

    impl Drop for Guard {
        fn drop(&mut self) {
            unsafe {
                CloseHandle(self.0);
            }
        }
    }

    pub fn acquire() -> Result<Guard, ()> {
        let name: Vec<u16> = "Local\\LetsMakeMoney-v1\0".encode_utf16().collect();
        let handle = unsafe { CreateMutexW(ptr::null(), 1, name.as_ptr()) };
        if handle.is_null() {
            return Err(());
        }
        if unsafe { GetLastError() } == ERROR_ALREADY_EXISTS {
            let title: Vec<u16> = "LetsMakeMoney\0".encode_utf16().collect();
            let window = unsafe { FindWindowW(ptr::null(), title.as_ptr()) };
            if !window.is_null() {
                unsafe {
                    ShowWindow(window, SW_RESTORE);
                    SetForegroundWindow(window);
                }
            }
            unsafe {
                CloseHandle(handle);
            }
            return Err(());
        }
        Ok(Guard(handle))
    }
}

#[cfg(not(target_os = "windows"))]
mod single_instance {
    pub struct Guard;
    pub fn acquire() -> Result<Guard, ()> {
        Ok(Guard)
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let Ok(instance_guard) = single_instance::acquire() else {
        return;
    };

    tauri::Builder::default()
        .setup(|app| {
            // The configured Mini window is the only startup WebView. Secondary
            // windows are created by ensure_window when the user opens them.
            let data_dir = app.path().app_data_dir()?;
            let config_path = data_dir.join("config.json");
            let previous_config_version = config::stored_config_version(&config_path);
            let theme_fallback_required = config::stored_theme_requires_fallback(&config_path);
            let config_result = config::load_or_migrate(&config_path);
            let configuration_initialized = config_path.is_file() && config_result.is_ok();
            let config = config_result.unwrap_or_else(|_| config::AppConfig::default());
            let mini_edge_runtime = MiniEdgeRuntime::new(&config);
            app.manage(RuntimeConfig(Mutex::new(config)));
            app.manage(mini_edge_runtime);
            app.manage(ConfigurationState(AtomicBool::new(
                configuration_initialized,
            )));
            app.manage(ExitState(AtomicBool::new(false)));
            app.manage(PositionSaveRevision(AtomicU64::new(0)));
            app.manage(PlatformRuntime(Mutex::new(PlatformCapabilities {
                webview2_available: platform::webview2_runtime_available(),
                tray_available: false,
                explorer_available: std::env::var_os("WINDIR")
                    .map(std::path::PathBuf::from)
                    .map(|path| path.join("explorer.exe").is_file())
                    .unwrap_or(false),
                tray_recovery: "TaskbarCreated",
            })));
            app.manage(instance_guard);
            if matches!(previous_config_version, Some(5..=7)) && configuration_initialized {
                if matches!(previous_config_version, Some(5 | 6)) {
                    append_log(
                        app.handle(),
                        "date_override.migrated",
                        &format!(
                            "from_version={} to_version=8",
                            previous_config_version.unwrap_or_default()
                        ),
                    );
                }
                append_log(
                    app.handle(),
                    "config.migrated",
                    &format!(
                        "from_version={} to_version=8 theme=light",
                        previous_config_version.unwrap_or_default()
                    ),
                );
            }
            if theme_fallback_required && configuration_initialized {
                append_log(
                    app.handle(),
                    "theme.invalid_fallback",
                    "invalid_or_missing_value restored=light",
                );
            }
            if configuration_initialized {
                if let Some(mini) = app.get_webview_window("mini") {
                    apply_window_policy(app.handle(), &mini, "mini")?;
                }
            }
            match build_tray(app.handle()) {
                Ok(()) => {
                    if let Ok(mut status) = app.state::<PlatformRuntime>().0.lock() {
                        status.tray_available = true;
                    }
                }
                Err(error) => {
                    append_log(
                        app.handle(),
                        "tray.unavailable",
                        &format!("reason={error} fallback=settings_window"),
                    );
                }
            }
            if !configuration_initialized {
                if app.get_webview_window("mini").is_some() {
                    let _ = hide_window_internal(app.handle(), "mini");
                }
                show_window_internal(app.handle(), "wizard")?;
                append_log(
                    app.handle(),
                    "wizard.opened",
                    "source=startup reason=config_missing_or_invalid",
                );
            }
            Ok(())
        })
        .on_window_event(|window, event| match event {
            WindowEvent::Moved(position) if window.label() == "mini" => {
                schedule_mini_position_save(window.app_handle(), *position);
            }
            WindowEvent::CloseRequested { api, .. } => {
                let exiting = window
                    .app_handle()
                    .state::<ExitState>()
                    .0
                    .load(Ordering::SeqCst);
                if !exiting {
                    api.prevent_close();
                    if hide_window_internal(window.app_handle(), window.label()).is_ok() {
                        append_log(
                            window.app_handle(),
                            "window.close_hidden",
                            &format!("label={}", window.label()),
                        );
                    }
                }
            }
            _ => {}
        })
        .invoke_handler(tauri::generate_handler![
            implementation_phase,
            show_app_window,
            hide_app_window,
            toggle_mini,
            set_mini_window_state,
            move_app_window,
            window_drag_origin,
            mini_edge_status,
            complete_mini_drag,
            set_mini_edge_retracted,
            window_snapshot,
            platform_capabilities,
            open_data_directory,
            exit_application,
            load_calendar_year,
            commands::income::calculate_month_salary,
            commands::income::calculate_today_income,
            commands::income::resolve_schedule_owner_date,
            commands::income::resolve_calendar_month,
            commands::income::resolve_next_workday,
            read_configuration,
            save_configuration,
            save_date_override,
            configuration_initialized,
            diagnostic_summary,
            data_directory_path,
            evaluate_update_response,
            record_semantic_event
        ])
        .run(tauri::generate_context!())
        .expect("failed to run LetsMakeMoney");
}
mod calendar_data;
mod commands;
mod config;
mod domain;
mod models;
mod platform;
mod repositories;
mod services;
mod support;
