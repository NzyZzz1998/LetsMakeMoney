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
    AppHandle, Emitter, LogicalSize, Manager, PhysicalPosition, Position, Size, WebviewUrl,
    WebviewWindow, WebviewWindowBuilder, WindowEvent,
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

const WINDOW_SPECS: [WindowSpec; 5] = [
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
        label: "pet",
        title: "LetsMakeMoney Classic",
        width: 256.0,
        height: 208.0,
        min_width: 256.0,
        min_height: 208.0,
        resizable: false,
        skip_taskbar: true,
    },
    WindowSpec {
        label: "workbench",
        title: "LetsMakeMoney 今日工作台",
        width: 820.0,
        height: 620.0,
        min_width: 820.0,
        min_height: 620.0,
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

pub(crate) struct RuntimeConfig(pub(crate) Mutex<config::AppConfig>);
struct ConfigurationState(AtomicBool);
struct ExitState(AtomicBool);
struct PositionSaveRevision(AtomicU64);
struct PlatformRuntime(Mutex<PlatformCapabilities>);
struct WindowVisibilityRuntime(Mutex<window_policy::VisibilityLeaseMachine>);

const THEME_SESSION_EVENT: &str = "lmm://theme-preview";

#[derive(Clone, Debug)]
struct ThemePreview {
    theme_mode: config::ThemeMode,
    transaction_id: String,
}

#[derive(Clone, Debug)]
struct ThemeSessionState {
    persisted: config::ThemeMode,
    preview: Option<ThemePreview>,
    revision: u64,
}

struct ThemeSession(Mutex<ThemeSessionState>);

#[derive(Clone, Copy, Debug, Deserialize)]
#[serde(rename_all = "snake_case")]
enum ThemeSessionAction {
    Preview,
    Commit,
    Revert,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct ThemeSessionUpdateRequest {
    action: ThemeSessionAction,
    theme_mode: config::ThemeMode,
    transaction_id: String,
    reason: String,
    window_label: String,
}

#[derive(Clone, Debug, Serialize)]
struct ThemeSessionSnapshot {
    theme_mode: config::ThemeMode,
    source: &'static str,
    transaction_id: Option<String>,
    revision: u64,
    reason: String,
}

impl ThemeSessionState {
    fn snapshot(&self, reason: impl Into<String>) -> ThemeSessionSnapshot {
        match &self.preview {
            Some(preview) => ThemeSessionSnapshot {
                theme_mode: preview.theme_mode.clone(),
                source: "preview",
                transaction_id: Some(preview.transaction_id.clone()),
                revision: self.revision,
                reason: reason.into(),
            },
            None => ThemeSessionSnapshot {
                theme_mode: self.persisted.clone(),
                source: "persisted",
                transaction_id: None,
                revision: self.revision,
                reason: reason.into(),
            },
        }
    }

    fn transition(
        &mut self,
        action: ThemeSessionAction,
        requested: config::ThemeMode,
        persisted: config::ThemeMode,
        transaction_id: &str,
        reason: &str,
    ) -> (ThemeSessionSnapshot, bool) {
        self.persisted = persisted;
        let mut applied = true;
        match action {
            ThemeSessionAction::Preview => {
                self.preview = Some(ThemePreview {
                    theme_mode: requested,
                    transaction_id: transaction_id.to_string(),
                });
            }
            ThemeSessionAction::Commit | ThemeSessionAction::Revert => {
                if self
                    .preview
                    .as_ref()
                    .is_some_and(|preview| preview.transaction_id != transaction_id)
                {
                    applied = false;
                } else {
                    self.preview = None;
                }
            }
        }
        self.revision = self.revision.saturating_add(1);
        (self.snapshot(reason), applied)
    }
}

impl ThemeSession {
    fn new(theme_mode: config::ThemeMode) -> Self {
        Self(Mutex::new(ThemeSessionState {
            persisted: theme_mode,
            preview: None,
            revision: 1,
        }))
    }
}

fn theme_mode_label(theme_mode: &config::ThemeMode) -> &'static str {
    match theme_mode {
        config::ThemeMode::Light => "light",
        config::ThemeMode::Dark => "dark",
    }
}

#[cfg(test)]
mod theme_session_tests {
    use super::*;

    #[test]
    fn preview_is_process_local_and_reverts_to_persisted_theme() {
        let mut session = ThemeSessionState {
            persisted: config::ThemeMode::Light,
            preview: None,
            revision: 1,
        };
        let (preview, applied) = session.transition(
            ThemeSessionAction::Preview,
            config::ThemeMode::Dark,
            config::ThemeMode::Light,
            "tx-settings",
            "draft_changed",
        );
        assert!(applied);
        assert_eq!(preview.theme_mode, config::ThemeMode::Dark);
        assert_eq!(preview.source, "preview");

        let (reverted, applied) = session.transition(
            ThemeSessionAction::Revert,
            config::ThemeMode::Light,
            config::ThemeMode::Light,
            "tx-settings",
            "draft_discarded",
        );
        assert!(applied);
        assert_eq!(reverted.theme_mode, config::ThemeMode::Light);
        assert_eq!(reverted.source, "persisted");
        assert!(reverted.transaction_id.is_none());
    }

    #[test]
    fn stale_transaction_cannot_clear_a_newer_preview() {
        let mut session = ThemeSessionState {
            persisted: config::ThemeMode::Light,
            preview: Some(ThemePreview {
                theme_mode: config::ThemeMode::Dark,
                transaction_id: "tx-new".into(),
            }),
            revision: 4,
        };
        let (snapshot, applied) = session.transition(
            ThemeSessionAction::Revert,
            config::ThemeMode::Light,
            config::ThemeMode::Light,
            "tx-old",
            "stale_revert",
        );
        assert!(!applied);
        assert_eq!(snapshot.theme_mode, config::ThemeMode::Dark);
        assert_eq!(snapshot.transaction_id.as_deref(), Some("tx-new"));
    }
}

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
fn read_theme_session(
    app: AppHandle,
    state: tauri::State<'_, ThemeSession>,
    window_label: String,
) -> Result<ThemeSessionSnapshot, String> {
    let snapshot = state
        .0
        .lock()
        .map(|session| session.snapshot("authority_read"))
        .map_err(|_| "theme_session_lock_failed".to_string())?;
    append_log(
        &app,
        "theme.loaded",
        &format!(
            "window={window_label} theme={} source={} revision={}",
            theme_mode_label(&snapshot.theme_mode),
            snapshot.source,
            snapshot.revision
        ),
    );
    Ok(snapshot)
}

#[tauri::command]
fn update_theme_session(
    app: AppHandle,
    session_state: tauri::State<'_, ThemeSession>,
    config_state: tauri::State<'_, RuntimeConfig>,
    request: ThemeSessionUpdateRequest,
) -> Result<ThemeSessionSnapshot, String> {
    let ThemeSessionUpdateRequest {
        action,
        theme_mode,
        transaction_id,
        reason,
        window_label,
    } = request;
    if transaction_id.trim().is_empty() {
        return Err("theme_transaction_id_required".into());
    }
    let persisted = config_state
        .0
        .lock()
        .map(|configuration| configuration.theme_mode.clone())
        .map_err(|_| "config_lock_failed".to_string())?;
    let action_label = match action {
        ThemeSessionAction::Preview => "preview",
        ThemeSessionAction::Commit => "commit",
        ThemeSessionAction::Revert => "revert",
    };
    let mut session = session_state
        .0
        .lock()
        .map_err(|_| "theme_session_lock_failed".to_string())?;
    let (snapshot, applied) =
        session.transition(action, theme_mode, persisted, &transaction_id, &reason);
    drop(session);

    app.emit(THEME_SESSION_EVENT, snapshot.clone())
        .map_err(|error| error.to_string())?;
    let event = match action_label {
        "preview" => "theme.preview_applied",
        "commit" => "theme.saved",
        _ => "theme.preview_reverted",
    };
    append_log(
        &app,
        event,
        &format!(
            "window={window_label} theme={} source={} transaction={} revision={} applied={} reason={}",
            theme_mode_label(&snapshot.theme_mode),
            snapshot.source,
            transaction_id,
            snapshot.revision,
            applied,
            reason.replace(['\r', '\n'], " ")
        ),
    );
    Ok(snapshot)
}

#[derive(Clone, Copy, Debug)]
struct CompanionSwitchStage {
    plan: companion_policy::CompanionSwitchPlan,
    source_before: companion_policy::CompanionPreVisibility,
    lease_rebased_to: Option<companion_policy::CompanionPreVisibility>,
}

fn rollback_companion_switch(app: &AppHandle, stage: CompanionSwitchStage, reason: &str) {
    if let Some(lease_rebased_to) = stage.lease_rebased_to {
        let restore_ok = app
            .state::<WindowVisibilityRuntime>()
            .0
            .lock()
            .map(|mut machine| machine.rebase_companion(lease_rebased_to, stage.source_before))
            .unwrap_or(false);
        append_log(
            app,
            "desktop_companion.switch_rolled_back",
            &format!(
                "source={} target={} source_before={} restore_ok={} workbench_lease=true reason={}",
                stage.plan.source_label,
                stage.plan.target_label,
                stage.source_before.label(),
                restore_ok,
                reason.replace(['\r', '\n'], " ")
            ),
        );
        return;
    }
    if let Some(target) = app.get_webview_window(stage.plan.target_label) {
        if target.is_visible().unwrap_or(false) {
            let _ =
                hide_window_with_source(app, stage.plan.target_label, "companion_switch_rollback");
        }
    }
    let restore = restore_companion_pre_visibility(app, stage.source_before);
    append_log(
        app,
        "desktop_companion.switch_rolled_back",
        &format!(
            "source={} target={} source_before={} restore_ok={} reason={}",
            stage.plan.source_label,
            stage.plan.target_label,
            stage.source_before.label(),
            restore.is_ok(),
            reason.replace(['\r', '\n'], " ")
        ),
    );
}

fn stage_companion_switch(
    app: &AppHandle,
    current: config::DesktopCompanionMode,
    requested: config::DesktopCompanionMode,
) -> Result<Option<CompanionSwitchStage>, String> {
    let plan = companion_policy::companion_switch_plan(current, requested);
    if !plan.changed {
        return Ok(None);
    }
    if requested == config::DesktopCompanionMode::Pet {
        pet_package::preflight().map_err(|error| match error.as_str() {
            "pet_package_not_approved_for_product" => {
                "Classic 桌宠包尚未通过产品回归与再分发门禁".to_string()
            }
            _ => format!("Classic 桌宠包校验失败：{error}"),
        })?;
    }

    let lease = current_visibility_lease(app)?;
    let lease_strategy = window_policy::companion_switch_lease_strategy(lease.phase);
    if lease_strategy == window_policy::CompanionSwitchLeaseStrategy::Retry {
        return Err("今日工作台正在切换，请稍后再试".to_string());
    }
    if lease_strategy == window_policy::CompanionSwitchLeaseStrategy::Rebase {
        let target = ensure_window(app, plan.target_label)?;
        if target.is_visible().map_err(|error| error.to_string())? {
            hide_window_with_source(
                app,
                plan.target_label,
                "companion_switch_workbench_enforce_hidden",
            )?;
        }
        let source_before = lease.companion_before;
        let lease_rebased_to =
            companion_policy::companion_visibility_after_mode_switch(source_before, requested);
        let rebased = app
            .state::<WindowVisibilityRuntime>()
            .0
            .lock()
            .map_err(|_| "window_visibility_lock_failed".to_string())?
            .rebase_companion(source_before, lease_rebased_to);
        if !rebased {
            return Err("桌面陪伴切换状态已变化，请重试".to_string());
        }
        append_log(
            app,
            "desktop_companion.switch_staged",
            &format!(
                "source={} target={} source_before={} target_after={} workbench_lease=true",
                plan.source_label,
                plan.target_label,
                source_before.label(),
                lease_rebased_to.label(),
            ),
        );
        return Ok(Some(CompanionSwitchStage {
            plan,
            source_before,
            lease_rebased_to: Some(lease_rebased_to),
        }));
    }

    let source_before = companion_pre_visibility(app)?;
    if let Some(target) = app.get_webview_window(plan.target_label) {
        if target.is_visible().map_err(|error| error.to_string())? {
            hide_window_with_source(app, plan.target_label, "companion_switch_enforce_exclusive")?;
        }
    }
    let target_after =
        companion_policy::companion_visibility_after_mode_switch(source_before, requested);
    if let Some(source_label) = visible_companion_label(source_before) {
        hide_window_with_source(app, source_label, "companion_switch_source")?;
    }
    if let Some(target_label) = visible_companion_label(target_after) {
        if let Err(error) = show_window_with_options(
            app,
            target_label,
            "companion_switch_target",
            false,
            true,
            true,
        ) {
            let _ = restore_companion_pre_visibility(app, source_before);
            return Err(error);
        }
    }
    append_log(
        app,
        "desktop_companion.switch_staged",
        &format!(
            "source={} target={} source_before={} target_after={}",
            plan.source_label,
            plan.target_label,
            source_before.label(),
            target_after.label(),
        ),
    );
    Ok(Some(CompanionSwitchStage {
        plan,
        source_before,
        lease_rebased_to: None,
    }))
}

async fn stage_companion_switch_async(
    app: &AppHandle,
    current: config::DesktopCompanionMode,
    requested: config::DesktopCompanionMode,
) -> Result<Option<CompanionSwitchStage>, String> {
    let task_app = app.clone();
    tauri::async_runtime::spawn_blocking(move || {
        stage_companion_switch(&task_app, current, requested)
    })
    .await
    .map_err(|error| format!("desktop_companion_switch_dispatch_failed:{error}"))?
}

#[tauri::command]
async fn save_configuration(
    app: AppHandle,
    state: tauri::State<'_, RuntimeConfig>,
    configuration_state: tauri::State<'_, ConfigurationState>,
    mut draft: config::AppConfig,
) -> Result<config::SaveResult, String> {
    if !draft.mini_edge_auto_hide {
        draft.mini_edge_dock = config::MiniEdgeDock::None;
    }
    let requested_edge_auto_hide = draft.mini_edge_auto_hide;
    let previous_mode = state
        .0
        .lock()
        .map_err(|_| "config_lock_failed".to_string())?
        .desktop_companion_mode;
    let switch_stage =
        match stage_companion_switch_async(&app, previous_mode, draft.desktop_companion_mode).await
        {
            Ok(stage) => stage,
            Err(message) => {
                append_log(
                    &app,
                    "desktop_companion.switch_rejected",
                    &format!(
                        "current={previous_mode:?} requested={:?} reason={}",
                        draft.desktop_companion_mode,
                        message.replace(['\r', '\n'], " ")
                    )
                    .to_lowercase(),
                );
                return Ok(config::SaveResult {
                    status: config::SaveStatus::Failed,
                    message,
                    draft_preserved: true,
                });
            }
        };
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
    if result.status == config::SaveStatus::Failed {
        if let Some(stage) = switch_stage {
            rollback_companion_switch(&app, stage, &result.message);
        }
    } else if let Some(stage) = switch_stage {
        append_log(
            &app,
            "desktop_companion.switch_committed",
            &format!(
                "source={} target={} result={:?}",
                stage.plan.source_label, stage.plan.target_label, result.status
            )
            .to_lowercase(),
        );
    }
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
async fn switch_desktop_companion(
    app: AppHandle,
    state: tauri::State<'_, RuntimeConfig>,
    mode: config::DesktopCompanionMode,
) -> Result<config::SaveResult, String> {
    let current = state
        .0
        .lock()
        .map_err(|_| "config_lock_failed".to_string())?
        .clone();
    if current.desktop_companion_mode == mode {
        return Ok(config::SaveResult {
            status: config::SaveStatus::Unchanged,
            message: "桌面陪伴模式没有变化".to_string(),
            draft_preserved: true,
        });
    }
    let stage = match stage_companion_switch_async(&app, current.desktop_companion_mode, mode).await
    {
        Ok(Some(stage)) => stage,
        Ok(None) => unreachable!("changed mode must create a switch stage"),
        Err(message) => {
            return Ok(config::SaveResult {
                status: config::SaveStatus::Failed,
                message,
                draft_preserved: true,
            })
        }
    };
    let mut draft = current;
    draft.desktop_companion_mode = mode;
    let data_dir = app
        .path()
        .app_data_dir()
        .map_err(|error| error.to_string())?;
    let repository = repositories::configuration_repository::FileConfigurationRepository::new(
        data_dir.join("config.json"),
    );
    let outcome = services::configuration_service::save_user_configuration(
        &state.0,
        &repository,
        true,
        draft,
    )?;
    if outcome.result.status == config::SaveStatus::Failed {
        rollback_companion_switch(&app, stage, &outcome.result.message);
    } else {
        append_log(
            &app,
            "desktop_companion.switch_committed",
            &format!(
                "source={} target={} result={:?}",
                stage.plan.source_label, stage.plan.target_label, outcome.result.status
            )
            .to_lowercase(),
        );
    }
    Ok(outcome.result)
}

#[tauri::command]
fn pet_package_status() -> pet_package::ProductPackageStatus {
    pet_package::product_status()
}

#[tauri::command]
fn show_desktop_companion(app: AppHandle) -> Result<(), String> {
    let label = active_companion_label(&app)?;
    show_window_internal(&app, label)
}

fn rebase_failed_pet_visibility_lease(app: &AppHandle) -> Result<bool, String> {
    let runtime = app.state::<WindowVisibilityRuntime>();
    let mut machine = runtime
        .0
        .lock()
        .map_err(|_| "window_visibility_lock_failed".to_string())?;
    Ok(machine.rebase_companion(
        companion_policy::CompanionPreVisibility::PetVisible,
        companion_policy::CompanionPreVisibility::MiniExpanded,
    ))
}

#[tauri::command]
fn pet_runtime_failed(
    app: AppHandle,
    state: tauri::State<'_, RuntimeConfig>,
    runtime: tauri::State<'_, pet_runtime::PetRuntimeState>,
    reason: String,
) -> Result<(), String> {
    let mut reason = reason.replace(['\r', '\n'], " ");
    reason.truncate(512);
    pet_runtime::mark_runtime_failed(&runtime);

    if let Some(pet) = app.get_webview_window("pet") {
        if pet.is_visible().unwrap_or(false) {
            let _ = hide_window_with_source(&app, "pet", "pet_runtime_failure");
        }
    }

    let current = state
        .0
        .lock()
        .map_err(|_| "config_lock_failed".to_string())?
        .clone();
    let mut persisted = true;
    if current.desktop_companion_mode == config::DesktopCompanionMode::Pet {
        let mut draft = current;
        draft.desktop_companion_mode = config::DesktopCompanionMode::Mini;
        let data_dir = app
            .path()
            .app_data_dir()
            .map_err(|error| error.to_string())?;
        let repository = repositories::configuration_repository::FileConfigurationRepository::new(
            data_dir.join("config.json"),
        );
        let outcome = services::configuration_service::save_user_configuration(
            &state.0,
            &repository,
            true,
            draft,
        )?;
        persisted = matches!(
            outcome.result.status,
            config::SaveStatus::Saved | config::SaveStatus::Unchanged
        );
        if !persisted {
            state
                .0
                .lock()
                .map_err(|_| "config_lock_failed".to_string())?
                .desktop_companion_mode = config::DesktopCompanionMode::Mini;
        }
    }

    let lease_rebased = rebase_failed_pet_visibility_lease(&app)?;
    if !lease_rebased {
        show_window_with_options(
            &app,
            "mini",
            "pet_runtime_failure_fallback",
            false,
            true,
            true,
        )?;
    }
    append_log(
        &app,
        "desktop_companion.fallback_to_mini",
        &format!(
            "source=runtime persisted={persisted} lease_rebased={lease_rebased} reason={reason}"
        ),
    );
    Ok(())
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
        .shadow(false)
        .skip_taskbar(spec.skip_taskbar)
        .visible(false)
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
    let (x, y) = if matches!(label, "mini" | "pet") {
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
    if let Err(error) = persist_runtime_companion_position(app, "mini") {
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
    let work_area = platform::work_area_for_rect(window_rect).or_else(|_| {
        let monitor = window
            .primary_monitor()
            .map_err(|error| error.to_string())?
            .ok_or_else(|| "primary_monitor_unavailable".to_string())?;
        let origin = monitor.position();
        let monitor_size = monitor.size();
        Ok::<platform::Rect, String>(platform::Rect {
            x: origin.x,
            y: origin.y,
            width: monitor_size.width,
            height: monitor_size.height,
        })
    })?;
    let scale = window.scale_factor().map_err(|error| error.to_string())?;
    let (grab_width, grab_height) = window_policy::safe_grab_logical_size(window.label());
    let (x, y) = window_policy::recover_to_safe_grab_region(
        window_rect,
        work_area,
        scale,
        grab_width,
        grab_height,
    );
    if x != position.x || y != position.y {
        window
            .set_position(Position::Physical(PhysicalPosition::new(x, y)))
            .map_err(|error| error.to_string())?;
    }
    Ok(())
}

fn apply_window_policy_inner(
    app: &AppHandle,
    window: &WebviewWindow,
    label: &str,
) -> Result<(), String> {
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
        if let Err(error) = window.set_always_on_top(config.mini_window_always_on_top) {
            let reason = format!("always_on_top:{error}");
            append_log(
                app,
                "window.policy.failed",
                &format!("label=mini policy=always_on_top reason={error}"),
            );
            schedule_window_operation_failure(app, "mini", "always_on_top", &reason);
        }
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
    } else if label == "pet" {
        let config = app
            .state::<RuntimeConfig>()
            .0
            .lock()
            .map(|config| config.clone())
            .unwrap_or_default();
        apply_companion_topmost_policy(app, window, label)?;
        if let Some(position) = config.pet_window_position {
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

fn apply_window_policy(app: &AppHandle, window: &WebviewWindow, label: &str) -> Result<(), String> {
    append_log(app, "window.policy.requested", &format!("label={label}"));
    match apply_window_policy_inner(app, window, label) {
        Ok(()) => {
            append_log(app, "window.policy.applied", &format!("label={label}"));
            Ok(())
        }
        Err(error) => {
            append_log(
                app,
                "window.policy.failed",
                &format!("label={label} reason={error}"),
            );
            Err(format!("window_policy_failed:{label}:{error}"))
        }
    }
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

fn dispatch_window_lifecycle_event(
    app: &AppHandle,
    window: &WebviewWindow,
    label: &str,
    event: &str,
    source: &str,
) {
    let event = serde_json::to_string(event).unwrap_or_else(|_| "\"lmm:window-event\"".into());
    let source = serde_json::to_string(source).unwrap_or_else(|_| "\"unknown\"".into());
    let script = format!(
        "window.dispatchEvent(new CustomEvent({event}, {{ detail: {{ source: {source} }} }}))"
    );
    if let Err(error) = window.eval(&script) {
        append_log(
            app,
            "window.lifecycle_event_failed",
            &format!("label={label} event={event} source={source} reason={error}"),
        );
    }
}

fn dispatch_window_operation_failure(app: &AppHandle, label: &str, operation: &str, reason: &str) {
    let Some(window) = app.get_webview_window(label) else {
        return;
    };
    let detail = serde_json::json!({
        "label": label,
        "operation": operation,
        "reason": reason,
    });
    let script = format!(
        "window.dispatchEvent(new CustomEvent('lmm:window-operation-failed', {{ detail: {} }}))",
        detail
    );
    if let Err(error) = window.eval(&script) {
        append_log(
            app,
            "window.operation_feedback_failed",
            &format!("label={label} operation={operation} reason={error}"),
        );
    }
}

fn schedule_window_operation_failure(app: &AppHandle, label: &str, operation: &str, reason: &str) {
    let app = app.clone();
    let label = label.to_string();
    let operation = operation.to_string();
    let reason = reason.to_string();
    thread::spawn(move || {
        thread::sleep(Duration::from_millis(500));
        dispatch_window_operation_failure(&app, &label, &operation, &reason);
    });
}

fn apply_companion_topmost_policy(
    app: &AppHandle,
    window: &WebviewWindow,
    label: &str,
) -> Result<(), String> {
    let always_on_top = app
        .state::<RuntimeConfig>()
        .0
        .lock()
        .map_err(|_| "config_lock_failed".to_string())?
        .mini_window_always_on_top;
    append_log(
        app,
        "window.policy.requested",
        &format!("label={label} policy=always_on_top value={always_on_top}"),
    );
    if let Err(error) = window.set_always_on_top(always_on_top) {
        let reason = format!("always_on_top:{error}");
        append_log(
            app,
            "window.policy.failed",
            &format!("label={label} policy=always_on_top reason={error}"),
        );
        schedule_window_operation_failure(app, label, "always_on_top", &reason);
        return Ok(());
    }
    append_log(
        app,
        "window.policy.applied",
        &format!("label={label} policy=always_on_top value={always_on_top}"),
    );
    Ok(())
}

fn show_window_with_options(
    app: &AppHandle,
    label: &str,
    source: &str,
    focus: bool,
    apply_policy: bool,
    emit_lifecycle: bool,
) -> Result<(), String> {
    if label == "pet" {
        pet_package::preflight()
            .map_err(|error| window_show_error(app, label, "package_preflight", error))?;
    }
    append_log(
        app,
        "window.show_requested",
        &format!("label={label} source={source} focus={focus}"),
    );
    let window = ensure_window(app, label)
        .map_err(|error| window_show_error(app, label, "ensure", error))?;
    append_log(app, "window.ensure_completed", &format!("label={label}"));
    if apply_policy {
        apply_window_policy(app, &window, label)
            .map_err(|error| window_show_error(app, label, "policy", error))?;
    } else if matches!(label, "mini" | "pet") {
        apply_companion_topmost_policy(app, &window, label)
            .map_err(|error| window_show_error(app, label, "policy", error))?;
    }
    resume_webview_internal(app, &window, label);
    window
        .show()
        .map_err(|error| window_show_error(app, label, "show", error.to_string()))?;
    append_log(app, "window.visible", &format!("label={label}"));
    if label == "pet" {
        let runtime = app.state::<pet_runtime::PetRuntimeState>();
        if let Err(error) = pet_runtime::resume_for_window(&window, &runtime) {
            let _ = window.hide();
            append_log(
                app,
                "pet.native_bridge_resume_failed",
                &format!("reason={}", error.replace(['\r', '\n'], " ")),
            );
            return Err(window_show_error(app, label, "native_bridge_resume", error));
        }
    }
    window
        .unminimize()
        .map_err(|error| window_show_error(app, label, "unminimize", error.to_string()))?;
    if focus {
        window.set_focus().map_err(|error| {
            append_log(
                app,
                "window.activation_failed",
                &format!("label={label} reason={error}"),
            );
            window_show_error(app, label, "focus", error.to_string())
        })?;
        append_log(app, "window.focused", &format!("label={label}"));
    }
    if emit_lifecycle {
        dispatch_window_lifecycle_event(app, &window, label, "lmm:window-shown", source);
    }
    append_log(
        app,
        "window.shown",
        &format!("label={label} source={source} focus={focus}"),
    );
    Ok(())
}

fn show_window_internal(app: &AppHandle, label: &str) -> Result<(), String> {
    show_window_with_options(app, label, "user_request", true, true, true)
}

fn hide_window_with_source(app: &AppHandle, label: &str, source: &str) -> Result<(), String> {
    let window = ensure_window(app, label)?;
    if label == "pet" {
        dispatch_window_lifecycle_event(app, &window, label, "lmm:window-hidden", source);
        let runtime = app.state::<pet_runtime::PetRuntimeState>();
        if let Err(error) = pet_runtime::pause_for_window(&window, &runtime) {
            append_log(
                app,
                "pet.native_bridge_pause_failed",
                &format!("reason={}", error.replace(['\r', '\n'], " ")),
            );
        }
    }
    window.hide().map_err(|error| error.to_string())?;
    if label != "pet" {
        dispatch_window_lifecycle_event(app, &window, label, "lmm:window-hidden", source);
    }
    append_log(
        app,
        "window.hidden",
        &format!("label={label} source={source}"),
    );
    suspend_webview_internal(app, &window, label);
    Ok(())
}

fn hide_window_internal(app: &AppHandle, label: &str) -> Result<(), String> {
    hide_window_with_source(app, label, "user_request")
}

fn active_companion_mode(app: &AppHandle) -> Result<config::DesktopCompanionMode, String> {
    app.state::<RuntimeConfig>()
        .0
        .lock()
        .map(|config| config.desktop_companion_mode)
        .map_err(|_| "config_lock_failed".to_string())
}

fn active_companion_label(app: &AppHandle) -> Result<&'static str, String> {
    Ok(companion_policy::companion_window_label(
        active_companion_mode(app)?,
    ))
}

fn toggle_desktop_companion(app: &AppHandle) -> Result<(), String> {
    let label = active_companion_label(app)?;
    let window = ensure_window(app, label)?;
    if window.is_visible().map_err(|error| error.to_string())? {
        if label == "mini" && mini_edge_status_internal(app)?.visibility == "retracted" {
            set_mini_edge_retracted_internal(app, false, "tray_restore", true)?;
            window.set_focus().map_err(|error| error.to_string())?;
            dispatch_window_lifecycle_event(
                app,
                &window,
                label,
                "lmm:window-shown",
                "tray_restore_privacy",
            );
            return Ok(());
        }
        hide_window_internal(app, label)
    } else {
        show_window_internal(app, label)
    }
}

fn companion_pre_visibility(
    app: &AppHandle,
) -> Result<companion_policy::CompanionPreVisibility, String> {
    let mode = active_companion_mode(app)?;
    let label = companion_policy::companion_window_label(mode);
    let Some(window) = app.get_webview_window(label) else {
        return Ok(companion_policy::CompanionPreVisibility::NotPresent);
    };
    if !window.is_visible().map_err(|error| error.to_string())? {
        return Ok(companion_policy::CompanionPreVisibility::HiddenByUser);
    }
    if mode == config::DesktopCompanionMode::Pet {
        return Ok(companion_policy::CompanionPreVisibility::PetVisible);
    }
    let visibility = app
        .state::<MiniEdgeRuntime>()
        .state
        .lock()
        .map_err(|_| "mini_edge_state_lock_failed".to_string())?
        .visibility;
    Ok(if visibility == MiniEdgeVisibility::Retracted {
        companion_policy::CompanionPreVisibility::MiniPrivacyRetracted
    } else {
        companion_policy::CompanionPreVisibility::MiniExpanded
    })
}

fn visible_companion_label(
    visibility: companion_policy::CompanionPreVisibility,
) -> Option<&'static str> {
    match visibility {
        companion_policy::CompanionPreVisibility::MiniExpanded
        | companion_policy::CompanionPreVisibility::MiniPrivacyRetracted => Some("mini"),
        companion_policy::CompanionPreVisibility::PetVisible => Some("pet"),
        companion_policy::CompanionPreVisibility::HiddenByUser
        | companion_policy::CompanionPreVisibility::NotPresent => None,
    }
}

fn transition_visibility_lease(
    app: &AppHandle,
    transaction_id: u64,
    phase: window_policy::VisibilityLeasePhase,
) -> Result<(), String> {
    let runtime = app.state::<WindowVisibilityRuntime>();
    let mut machine = runtime
        .0
        .lock()
        .map_err(|_| "window_visibility_lock_failed".to_string())?;
    let lease = machine
        .transition(transaction_id, phase)
        .ok_or_else(|| "window_visibility_stale_transaction".to_string())?;
    append_log(
        app,
        "window.visibility_lease.transition",
        &format!(
            "transaction_id={} phase={} companion_before={}",
            lease.transaction_id,
            lease.phase.label(),
            lease.companion_before.label()
        ),
    );
    Ok(())
}

fn current_visibility_lease(app: &AppHandle) -> Result<window_policy::VisibilityLease, String> {
    app.state::<WindowVisibilityRuntime>()
        .0
        .lock()
        .map(|machine| machine.current())
        .map_err(|_| "window_visibility_lock_failed".to_string())
}

fn restore_companion_pre_visibility(
    app: &AppHandle,
    companion_before: companion_policy::CompanionPreVisibility,
) -> Result<(), String> {
    match companion_policy::companion_restore_action(companion_before) {
        companion_policy::CompanionRestoreAction::ShowMiniExpanded => {
            show_window_with_options(app, "mini", "workbench_restore_expanded", false, true, true)
        }
        companion_policy::CompanionRestoreAction::ShowMiniPrivacyRetracted => {
            show_window_with_options(app, "mini", "workbench_restore_privacy", false, false, true)
        }
        companion_policy::CompanionRestoreAction::ShowPet => {
            show_window_with_options(app, "pet", "workbench_restore_pet", false, true, true)
        }
        companion_policy::CompanionRestoreAction::KeepHidden => Ok(()),
    }
}

fn schedule_workbench_open_watchdog(app: &AppHandle, transaction_id: u64) {
    let app = app.clone();
    thread::spawn(move || {
        thread::sleep(Duration::from_secs(8));
        let Ok(lease) = current_visibility_lease(&app) else {
            return;
        };
        if lease.transaction_id != transaction_id
            || lease.phase != window_policy::VisibilityLeasePhase::Opening
        {
            return;
        }
        append_log(
            &app,
            "window.visibility_lease.timeout",
            &format!("transaction_id={transaction_id} label=workbench"),
        );
        let _ = hide_window_with_source(&app, "workbench", "workbench_initialization_timeout");
        let _ = transition_visibility_lease(
            &app,
            transaction_id,
            window_policy::VisibilityLeasePhase::Failed,
        );
    });
}

fn open_workbench_transaction(app: &AppHandle, source: &str) -> Result<(), String> {
    let workbench_preexisted = app.get_webview_window("workbench").is_some();
    let companion_before = companion_pre_visibility(app)?;
    let (lease, started) = {
        let runtime = app.state::<WindowVisibilityRuntime>();
        let mut machine = runtime
            .0
            .lock()
            .map_err(|_| "window_visibility_lock_failed".to_string())?;
        machine.begin(companion_before)
    };
    append_log(
        app,
        "window.visibility_lease.requested",
        &format!(
            "transaction_id={} phase={} companion_before={} started={started} source={source}",
            lease.transaction_id,
            lease.phase.label(),
            lease.companion_before.label()
        ),
    );
    show_window_with_options(app, "workbench", source, true, true, true).inspect_err(|_error| {
        let _ = transition_visibility_lease(
            app,
            lease.transaction_id,
            window_policy::VisibilityLeasePhase::Failed,
        );
    })?;
    if started {
        match window_policy::workbench_ready_strategy(workbench_preexisted) {
            window_policy::WorkbenchReadyStrategy::AwaitFrontend => {
                schedule_workbench_open_watchdog(app, lease.transaction_id);
            }
            window_policy::WorkbenchReadyStrategy::ConfirmNatively => {
                confirm_workbench_ready_internal(app, Some(lease.transaction_id))?;
            }
        }
    }
    Ok(())
}

fn confirm_workbench_ready_internal(
    app: &AppHandle,
    expected_transaction_id: Option<u64>,
) -> Result<(), String> {
    let lease = current_visibility_lease(app)?;
    if expected_transaction_id.is_some_and(|expected| expected != lease.transaction_id) {
        return Err("window_visibility_stale_transaction".to_string());
    }
    if lease.phase == window_policy::VisibilityLeasePhase::Open {
        return Ok(());
    }
    if lease.phase != window_policy::VisibilityLeasePhase::Opening {
        return Err(format!(
            "window_visibility_invalid_phase:{}",
            lease.phase.label()
        ));
    }
    let hide_result = visible_companion_label(lease.companion_before).map_or(Ok(()), |label| {
        hide_window_with_source(app, label, "workbench_ready")
    });
    if let Err(error) = hide_result {
        let _ = hide_window_with_source(app, "workbench", "workbench_open_compensation");
        let _ = restore_companion_pre_visibility(app, lease.companion_before);
        let _ = transition_visibility_lease(
            app,
            lease.transaction_id,
            window_policy::VisibilityLeasePhase::Failed,
        );
        return Err(format!("window_visibility_companion_hide_failed:{error}"));
    }
    transition_visibility_lease(
        app,
        lease.transaction_id,
        window_policy::VisibilityLeasePhase::Open,
    )
}

fn close_workbench_transaction(app: &AppHandle, source: &str) -> Result<(), String> {
    let lease = current_visibility_lease(app)?;
    if matches!(
        lease.phase,
        window_policy::VisibilityLeasePhase::Closed | window_policy::VisibilityLeasePhase::Failed
    ) {
        return hide_window_with_source(app, "workbench", source);
    }
    transition_visibility_lease(
        app,
        lease.transaction_id,
        window_policy::VisibilityLeasePhase::Compensating,
    )?;
    if lease.phase == window_policy::VisibilityLeasePhase::Open {
        if let Err(error) = restore_companion_pre_visibility(app, lease.companion_before) {
            let _ = transition_visibility_lease(
                app,
                lease.transaction_id,
                window_policy::VisibilityLeasePhase::Failed,
            );
            return Err(format!(
                "window_visibility_companion_restore_failed:{error}"
            ));
        }
    }
    if let Err(error) = hide_window_with_source(app, "workbench", source) {
        if let Some(label) = visible_companion_label(lease.companion_before) {
            let _ = hide_window_with_source(app, label, "workbench_close_compensation");
        }
        let _ = transition_visibility_lease(
            app,
            lease.transaction_id,
            window_policy::VisibilityLeasePhase::Failed,
        );
        return Err(format!("window_visibility_workbench_hide_failed:{error}"));
    }
    transition_visibility_lease(
        app,
        lease.transaction_id,
        window_policy::VisibilityLeasePhase::Closed,
    )
}

fn compensate_workbench_loss(app: &AppHandle, source: &str) -> Result<(), String> {
    let lease = current_visibility_lease(app)?;
    if matches!(
        lease.phase,
        window_policy::VisibilityLeasePhase::Closed | window_policy::VisibilityLeasePhase::Failed
    ) {
        return Ok(());
    }
    if lease.phase == window_policy::VisibilityLeasePhase::Opening {
        transition_visibility_lease(
            app,
            lease.transaction_id,
            window_policy::VisibilityLeasePhase::Failed,
        )?;
        append_log(
            app,
            "window.visibility_lease.compensated",
            &format!(
                "transaction_id={} source={source} companion_restored=false reason=workbench_lost_during_opening",
                lease.transaction_id
            ),
        );
        return Ok(());
    }
    transition_visibility_lease(
        app,
        lease.transaction_id,
        window_policy::VisibilityLeasePhase::Compensating,
    )?;
    match restore_companion_pre_visibility(app, lease.companion_before) {
        Ok(()) => {
            transition_visibility_lease(
                app,
                lease.transaction_id,
                window_policy::VisibilityLeasePhase::Closed,
            )?;
            append_log(
                app,
                "window.visibility_lease.compensated",
                &format!(
                    "transaction_id={} source={source} companion_restored=true",
                    lease.transaction_id
                ),
            );
            Ok(())
        }
        Err(error) => {
            let _ = transition_visibility_lease(
                app,
                lease.transaction_id,
                window_policy::VisibilityLeasePhase::Failed,
            );
            Err(error)
        }
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
        platform::TRAY_TOGGLE_MINI => toggle_desktop_companion(app),
        platform::TRAY_WORKBENCH => open_workbench_transaction(app, "tray"),
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
        "显示 / 隐藏桌面陪伴",
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
                append_log(app, "tray.left_click", "action=toggle_desktop_companion");
                if let Err(error) = toggle_desktop_companion(app) {
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
async fn show_app_window(app: AppHandle, label: String) -> Result<(), String> {
    let task_app = app.clone();
    let task_label = label.clone();
    tauri::async_runtime::spawn_blocking(move || {
        if task_label == "workbench" {
            open_workbench_transaction(&task_app, "ui")
        } else {
            show_window_internal(&task_app, &task_label)
        }
    })
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
    if label == "workbench" {
        close_workbench_transaction(&app, "ui")
    } else {
        hide_window_internal(&app, &label)
    }
}

#[tauri::command]
fn workbench_ready(app: AppHandle) -> Result<(), String> {
    confirm_workbench_ready_internal(&app, None)
}

#[tauri::command]
fn move_app_window(app: AppHandle, label: String, x: i32, y: i32) -> Result<(), String> {
    let window = ensure_window(&app, &label)?;
    window
        .set_position(Position::Physical(PhysicalPosition::new(x, y)))
        .map_err(|error| error.to_string())
}

#[tauri::command]
fn finalize_window_drag(app: AppHandle, label: String) -> Result<(), String> {
    if label == "mini" {
        return complete_mini_drag_internal(&app, true).map(|_| ());
    }
    let window = ensure_window(&app, &label)?;
    safe_window_position(&window)?;
    append_log(
        &app,
        "window.drag_finalized",
        &format!("label={label} recovery=minimal_safe_grab"),
    );
    Ok(())
}

#[tauri::command]
fn recover_app_window(app: AppHandle, label: String, source: String) -> Result<(), String> {
    let window = ensure_window(&app, &label)?;
    safe_window_position(&window)?;
    append_log(
        &app,
        "window.position_recovered",
        &format!("label={label} source={source} recovery=minimal_safe_grab"),
    );
    Ok(())
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

fn persist_runtime_companion_position(app: &AppHandle, label: &str) -> Result<(), String> {
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
            let has_position = match label {
                "mini" => outcome.mini_window_position.is_some(),
                "pet" => outcome.pet_window_position.is_some(),
                _ => false,
            };
            if has_position {
                append_log(
                    app,
                    "window.position_saved",
                    &format!("label={label} result=success"),
                );
            }
            Ok(())
        }
        config::SaveStatus::Failed => Err(outcome.result.message),
    }
}

fn schedule_companion_position_save(app: &AppHandle, label: &str, position: PhysicalPosition<i32>) {
    if label == "mini" && mini_edge_position_persistence_suppressed(app) {
        return;
    }
    if let Ok(mut config) = app.state::<RuntimeConfig>().0.lock() {
        let next = Some(config::WindowPosition {
            x: position.x as f64,
            y: position.y as f64,
        });
        match label {
            "mini" => config.mini_window_position = next,
            "pet" => config.pet_window_position = next,
            _ => return,
        }
    }
    let revision = app
        .state::<PositionSaveRevision>()
        .0
        .fetch_add(1, Ordering::SeqCst)
        + 1;
    let app = app.clone();
    let label = label.to_string();
    thread::spawn(move || {
        thread::sleep(Duration::from_millis(300));
        if app.state::<PositionSaveRevision>().0.load(Ordering::SeqCst) == revision {
            if label == "mini" && mini_edge_position_persistence_suppressed(&app) {
                return;
            }
            if let Err(error) = persist_runtime_companion_position(&app, &label) {
                append_log(
                    &app,
                    "window.position_save_failed",
                    &format!("label={label} reason={error}"),
                );
            }
        }
    });
}

#[tauri::command]
fn toggle_mini(app: AppHandle) -> Result<(), String> {
    toggle_desktop_companion(&app)
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
        .manage(pet_runtime::PetRuntimeState::default())
        .setup(|app| {
            // The configured Mini window is the only startup WebView. Secondary
            // windows are created by ensure_window when the user opens them.
            let data_dir = app.path().app_data_dir()?;
            match services::date_overtime_transaction::recover_pending(&data_dir) {
                Ok(Some(state)) => append_log(
                    app.handle(),
                    "date_overtime.transaction_recovered",
                    &format!("previous_state={state}"),
                ),
                Ok(None) => {}
                Err(error) => append_log(
                    app.handle(),
                    "date_overtime.transaction_recovery_failed",
                    &format!("reason={}", error.replace(['\r', '\n'], " ")),
                ),
            }
            let config_path = data_dir.join("config.json");
            let previous_config_version = config::stored_config_version(&config_path);
            let theme_fallback_required = config::stored_theme_requires_fallback(&config_path);
            let config_result = config::load_or_migrate(&config_path);
            let configuration_initialized = config_path.is_file() && config_result.is_ok();
            let mut config = config_result.unwrap_or_else(|_| config::AppConfig::default());
            let pet_startup_fallback = if config.desktop_companion_mode
                == config::DesktopCompanionMode::Pet
            {
                pet_package::preflight().err().map(|reason| {
                    let previous = config.clone();
                    config.desktop_companion_mode = config::DesktopCompanionMode::Mini;
                    let result = config::save_transactional(
                        &config_path,
                        &previous,
                        &config,
                        config::SaveFault::None,
                    );
                    (reason, result)
                })
            } else {
                None
            };
            let mini_edge_runtime = MiniEdgeRuntime::new(&config);
            let theme_session = ThemeSession::new(config.theme_mode.clone());
            app.manage(RuntimeConfig(Mutex::new(config)));
            app.manage(theme_session);
            app.manage(mini_edge_runtime);
            app.manage(ConfigurationState(AtomicBool::new(
                configuration_initialized,
            )));
            app.manage(ExitState(AtomicBool::new(false)));
            app.manage(PositionSaveRevision(AtomicU64::new(0)));
            app.manage(WindowVisibilityRuntime(Mutex::new(
                window_policy::VisibilityLeaseMachine::default(),
            )));
            app.manage(services::overtime_service::OvertimeRuntime::default());
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
            if let Some((reason, result)) = pet_startup_fallback {
                append_log(
                    app.handle(),
                    "desktop_companion.fallback_to_mini",
                    &format!(
                        "source=startup reason={} persisted={}",
                        reason.replace(['\r', '\n'], " "),
                        matches!(
                            result.status,
                            config::SaveStatus::Saved | config::SaveStatus::Unchanged
                        )
                    ),
                );
            }
            if matches!(previous_config_version, Some(5..=8)) && configuration_initialized {
                if matches!(previous_config_version, Some(5 | 6)) {
                    append_log(
                        app.handle(),
                        "date_override.migrated",
                        &format!(
                            "from_version={} to_version=9",
                            previous_config_version.unwrap_or_default()
                        ),
                    );
                }
                append_log(
                    app.handle(),
                    "config.migrated",
                    &format!(
                        "from_version={} to_version=9 theme=light desktop_companion=mini",
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
                let companion_label = active_companion_label(app.handle())?;
                show_window_with_options(
                    app.handle(),
                    companion_label,
                    "startup",
                    false,
                    true,
                    true,
                )?;
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
            WindowEvent::Moved(position) if matches!(window.label(), "mini" | "pet") => {
                schedule_companion_position_save(window.app_handle(), window.label(), *position);
            }
            WindowEvent::CloseRequested { api, .. } => {
                let exiting = window
                    .app_handle()
                    .state::<ExitState>()
                    .0
                    .load(Ordering::SeqCst);
                if !exiting {
                    api.prevent_close();
                    if matches!(window.label(), "settings" | "wizard") {
                        if let Some(webview) = window
                            .app_handle()
                            .get_webview_window(window.label())
                        {
                            match webview.eval(
                                "window.dispatchEvent(new CustomEvent('lmm:window-close-requested'))",
                            ) {
                                Ok(()) => append_log(
                                    window.app_handle(),
                                    "window.close_requested",
                                    &format!("label={} route=react", window.label()),
                                ),
                                Err(error) => append_log(
                                    window.app_handle(),
                                    "window.lifecycle_event_failed",
                                    &format!(
                                        "label={} event=close_requested reason={error}",
                                        window.label()
                                    ),
                                ),
                            }
                        } else {
                            append_log(
                                window.app_handle(),
                                "window.lifecycle_event_failed",
                                &format!(
                                    "label={} event=close_requested reason=webview_missing",
                                    window.label()
                                ),
                            )
                        }
                    } else if (if window.label() == "workbench" {
                        close_workbench_transaction(window.app_handle(), "system_close")
                    } else {
                        hide_window_internal(window.app_handle(), window.label())
                    })
                    .is_ok()
                    {
                        append_log(
                            window.app_handle(),
                            "window.close_hidden",
                            &format!("label={}", window.label()),
                        );
                    }
                }
            }
            WindowEvent::Destroyed if window.label() == "workbench" => {
                let exiting = window
                    .app_handle()
                    .state::<ExitState>()
                    .0
                    .load(Ordering::SeqCst);
                if !exiting {
                    if let Err(error) =
                        compensate_workbench_loss(window.app_handle(), "workbench_destroyed")
                    {
                        append_log(
                            window.app_handle(),
                            "window.visibility_lease.compensation_failed",
                            &format!("source=workbench_destroyed reason={error}"),
                        );
                    }
                }
            }
            _ => {}
        })
        .invoke_handler(tauri::generate_handler![
            show_app_window,
            hide_app_window,
            toggle_mini,
            set_mini_window_state,
            move_app_window,
            finalize_window_drag,
            recover_app_window,
            window_drag_origin,
            mini_edge_status,
            complete_mini_drag,
            set_mini_edge_retracted,
            workbench_ready,
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
            commands::overtime::resolve_overtime_boundary,
            commands::overtime::read_overtime_record,
            commands::overtime::read_overtime_month,
            commands::overtime::save_overtime_record,
            commands::overtime::delete_overtime_record,
            commands::overtime::recover_overtime_records,
            commands::overtime::save_date_overtime_transaction,
            read_configuration,
            read_theme_session,
            update_theme_session,
            save_configuration,
            switch_desktop_companion,
            pet_package_status,
            show_desktop_companion,
            pet_runtime::read_pet_package_file,
            pet_runtime::list_pet_package_files,
            pet_runtime::apply_pet_hit_region,
            pet_runtime::probe_pet_hit_region,
            pet_runtime::move_pet_window,
            pet_runtime::pet_runtime_ready,
            pet_runtime::record_pet_event,
            pet_runtime_failed,
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
mod companion_policy;
mod config;
mod domain;
mod models;
mod pet_package;
mod pet_runtime;
mod platform;
mod repositories;
mod services;
mod support;
mod window_policy;
