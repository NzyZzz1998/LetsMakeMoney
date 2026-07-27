use serde::{Deserialize, Serialize};
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
    AppHandle, Manager, PhysicalPosition, Position, WebviewUrl, WebviewWindow,
    WebviewWindowBuilder, WindowEvent,
};

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
        height: 120.0,
        min_width: 344.0,
        min_height: 120.0,
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

#[derive(Clone, Serialize)]
struct PlatformCapabilities {
    webview2_available: bool,
    tray_available: bool,
    explorer_available: bool,
    tray_recovery: &'static str,
}

#[derive(Deserialize)]
struct TodayRequest {
    owner_date: String,
    now_date: String,
    now_time: String,
    schedule: domain::SalarySchedule,
    month_salary: domain::MonthSalary,
    calendar: domain::CalendarData,
}

#[tauri::command]
fn load_calendar_year(
    app: AppHandle,
    year: i32,
) -> Result<calendar_data::CalendarDatasetResponse, String> {
    match calendar_data::load_calendar_year(year) {
        Ok(dataset) => {
            append_log(
                &app,
                "calendar.dataset.loaded",
                &format!("year={year} version={}", dataset.dataset_version),
            );
            Ok(dataset)
        }
        Err(error) => {
            append_log(
                &app,
                "calendar.dataset.failed",
                &format!("year={year} reason={error}"),
            );
            Err(error)
        }
    }
}

#[tauri::command]
fn calculate_month_salary(
    app: AppHandle,
    month: String,
    schedule: domain::SalarySchedule,
    calendar: domain::CalendarData,
) -> Result<domain::MonthSalary, String> {
    let result = domain::calculate_month(&month, &schedule, &calendar);
    if let Err(error) = &result {
        append_log(
            &app,
            "salary.calculate.invalid",
            &format!("scope=month month={month} reason={error}"),
        );
    }
    result
}

#[tauri::command]
fn calculate_today_income(
    app: AppHandle,
    request: TodayRequest,
) -> Result<domain::TodaySnapshot, String> {
    let result = domain::calculate_today(
        &request.owner_date,
        &request.now_date,
        &request.now_time,
        &request.schedule,
        &request.month_salary,
        &request.calendar,
    );
    if let Err(error) = &result {
        append_log(
            &app,
            "salary.calculate.invalid",
            &format!("scope=today owner_date={} reason={error}", request.owner_date),
        );
    }
    result
}

#[tauri::command]
fn resolve_schedule_owner_date(
    now_date: String,
    now_time: String,
    schedule: domain::SalarySchedule,
) -> Result<String, String> {
    domain::resolve_schedule_owner_date(&now_date, &now_time, &schedule)
}

#[tauri::command]
fn resolve_calendar_month(
    month: String,
    schedule: domain::SalarySchedule,
    calendar: domain::CalendarData,
) -> Result<Vec<domain::CalendarDay>, String> {
    domain::resolve_month_days(&month, &schedule, &calendar)
}

#[tauri::command]
fn resolve_next_workday(
    after_date: String,
    schedule: domain::SalarySchedule,
    calendar: domain::CalendarData,
) -> Result<Option<String>, String> {
    domain::next_workday(&after_date, &schedule, &calendar)
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
    draft: config::AppConfig,
) -> Result<config::SaveResult, String> {
    let mut current = state.0.lock().map_err(|_| "config_lock_failed")?;
    let data_dir = app
        .path()
        .app_data_dir()
        .map_err(|error| error.to_string())?;
    let initialized = configuration_state.0.load(Ordering::SeqCst);
    let config_path = data_dir.join("config.json");
    let result = if initialized {
        config::save_transactional(&config_path, &current, &draft, config::SaveFault::None)
    } else {
        config::save_initial(&config_path, &current, &draft)
    };
    let logger = support::RotatingLogger::new(data_dir.join("debug.log"), 2_000_000, 3);
    let event = match result.status {
        config::SaveStatus::Saved => "settings.saved",
        config::SaveStatus::Unchanged => "settings.unchanged",
        config::SaveStatus::Failed => "settings.save_failed",
    };
    let _ = logger.append(event, &result.message);
    if result.status == config::SaveStatus::Saved {
        *current = draft;
        configuration_state.0.store(true, Ordering::SeqCst);
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
    let mut current = state.0.lock().map_err(|_| "config_lock_failed")?;
    let data_dir = app
        .path()
        .app_data_dir()
        .map_err(|error| error.to_string())?;
    let config_path = data_dir.join("config.json");
    let (result, runtime) = config::save_date_override_transactional(
        &config_path,
        &current,
        &date,
        kind,
        config::SaveFault::None,
    );
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
    if matches!(
        result.status,
        config::SaveStatus::Saved | config::SaveStatus::Unchanged
    ) {
        *current = runtime;
    }
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
        .map_err(|error| format!("failed to create {} window: {error}", spec.label))?;
    position_new_window(&window, spec.label)?;
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

fn append_log(app: &AppHandle, event: &str, message: &str) {
    if let Ok(data_dir) = app.path().app_data_dir() {
        let logger = support::RotatingLogger::new(data_dir.join("debug.log"), 2_000_000, 3);
        let _ = logger.append(event, message);
    }
}

fn safe_window_position(window: &WebviewWindow) -> Result<(), String> {
    let position = window.outer_position().map_err(|error| error.to_string())?;
    let size = window.outer_size().map_err(|error| error.to_string())?;
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
        platform::Rect {
            x: position.x,
            y: position.y,
            width: size.width,
            height: size.height,
        },
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
    window
        .set_skip_taskbar(spec.skip_taskbar)
        .map_err(|error| error.to_string())?;
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
    }
    safe_window_position(window)?;
    append_log(
        app,
        "window.policy_applied",
        &format!("label={label} skip_taskbar={}", spec.skip_taskbar),
    );
    Ok(())
}

fn show_window_internal(app: &AppHandle, label: &str) -> Result<(), String> {
    append_log(app, "window.show_requested", &format!("label={label}"));
    let window = ensure_window(app, label)?;
    apply_window_policy(app, &window, label)?;
    let _ = window.eval("window.dispatchEvent(new CustomEvent('lmm:window-shown'))");
    window.show().map_err(|error| error.to_string())?;
    window.unminimize().map_err(|error| error.to_string())?;
    window.set_focus().map_err(|error| {
        append_log(
            app,
            "window.activation_failed",
            &format!("label={label} reason={error}"),
        );
        error.to_string()
    })?;
    append_log(app, "window.shown", &format!("label={label}"));
    Ok(())
}

fn hide_window_internal(app: &AppHandle, label: &str) -> Result<(), String> {
    let window = ensure_window(app, label)?;
    window.hide().map_err(|error| error.to_string())?;
    append_log(app, "window.hidden", &format!("label={label}"));
    Ok(())
}

fn toggle_mini_window(app: &AppHandle) -> Result<(), String> {
    let window = ensure_window(app, "mini")?;
    if window.is_visible().map_err(|error| error.to_string())? {
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
    "M5"
}

#[tauri::command]
fn show_app_window(app: AppHandle, label: String) -> Result<(), String> {
    show_window_internal(&app, &label)
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

fn persist_runtime_mini_position(app: &AppHandle) -> Result<(), String> {
    let draft = app
        .state::<RuntimeConfig>()
        .0
        .lock()
        .map_err(|_| "config_lock_failed")?
        .clone();
    let data_dir = app
        .path()
        .app_data_dir()
        .map_err(|error| error.to_string())?;
    let config_path = data_dir.join("config.json");
    let persisted = config::load_or_migrate(&config_path).unwrap_or_default();
    let result =
        config::save_transactional(&config_path, &persisted, &draft, config::SaveFault::None);
    match result.status {
        config::SaveStatus::Saved | config::SaveStatus::Unchanged => {
            if let Some(position) = draft.mini_window_position {
                append_log(
                    app,
                    "window.position_saved",
                    &format!("label=mini x={} y={}", position.x, position.y),
                );
            }
            Ok(())
        }
        config::SaveStatus::Failed => Err(result.message),
    }
}

fn schedule_mini_position_save(app: &AppHandle, position: PhysicalPosition<i32>) {
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
            for spec in WINDOW_SPECS {
                if spec.label != "mini" {
                    build_window(app.handle(), spec)?;
                }
            }
            let data_dir = app.path().app_data_dir()?;
            let config_path = data_dir.join("config.json");
            let previous_config_version = config::stored_config_version(&config_path);
            let config_result = config::load_or_migrate(&config_path);
            let configuration_initialized = config_path.is_file() && config_result.is_ok();
            let config = config_result.unwrap_or_else(|_| config::AppConfig::default());
            app.manage(RuntimeConfig(Mutex::new(config)));
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
            if matches!(previous_config_version, Some(5 | 6)) && configuration_initialized {
                append_log(
                    app.handle(),
                    "date_override.migrated",
                    &format!(
                        "from_version={} to_version=7",
                        previous_config_version.unwrap_or_default()
                    ),
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
                if let Some(mini) = app.get_webview_window("mini") {
                    let _ = mini.hide();
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
                    let _ = window.hide();
                    append_log(
                        window.app_handle(),
                        "window.close_hidden",
                        &format!("label={}", window.label()),
                    );
                }
            }
            _ => {}
        })
        .invoke_handler(tauri::generate_handler![
            implementation_phase,
            show_app_window,
            hide_app_window,
            toggle_mini,
            move_app_window,
            window_drag_origin,
            window_snapshot,
            platform_capabilities,
            open_data_directory,
            exit_application,
            load_calendar_year,
            calculate_month_salary,
            calculate_today_income,
            resolve_schedule_owner_date,
            resolve_calendar_month,
            resolve_next_workday,
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
mod config;
mod domain;
mod platform;
mod support;
