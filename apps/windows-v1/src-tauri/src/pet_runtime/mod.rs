mod hit_region;
mod hit_test_bridge;

use self::hit_region::{prepare_region, run_on_dispatcher, HitRect};
use self::hit_test_bridge::{probe_mask_points, HitTestBridgeState};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::sync::{
    atomic::{AtomicBool, AtomicU64, Ordering},
    Arc, Mutex,
};
use tauri::{AppHandle, Manager, WebviewWindow};

pub(crate) struct PetRuntimeState {
    package_validated: AtomicBool,
    runtime_ready: AtomicBool,
    event_sequence: AtomicU64,
    hit_region_updates: AtomicU64,
    hit_test_bridge: Arc<HitTestBridgeState>,
    hit_test_bridge_installed: Mutex<bool>,
    #[cfg(windows)]
    hit_test_bridge_hwnd: Mutex<Option<isize>>,
}

impl Default for PetRuntimeState {
    fn default() -> Self {
        Self {
            package_validated: AtomicBool::new(false),
            runtime_ready: AtomicBool::new(false),
            event_sequence: AtomicU64::new(0),
            hit_region_updates: AtomicU64::new(0),
            hit_test_bridge: Arc::new(HitTestBridgeState::default()),
            hit_test_bridge_installed: Mutex::new(false),
            #[cfg(windows)]
            hit_test_bridge_hwnd: Mutex::new(None),
        }
    }
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub(crate) struct HitRegionRequest {
    frame_id: String,
    logical_width: i32,
    logical_height: i32,
    scale: f64,
    rects: Vec<HitRect>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub(crate) struct AppliedHitRegion {
    frame_id: String,
    rect_count: usize,
    physical_width: i32,
    physical_height: i32,
    latency_ms: u128,
    dispatch_wait_us: u64,
    native_operation_us: u64,
    prepare_us: u64,
    window_handle_us: u64,
    bridge_update_us: u64,
    subclass_install_us: u64,
    dpi_query_us: u64,
    native_scale_factor: f64,
    native_bridge: &'static str,
}

#[derive(Debug, Deserialize)]
pub(crate) struct ProbePoint {
    x: i32,
    y: i32,
}

fn ensure_pet_window(window: &WebviewWindow) -> Result<(), String> {
    if window.label() == "pet" {
        Ok(())
    } else {
        Err("pet_runtime_window_mismatch".to_string())
    }
}

fn validate_product_package(state: &PetRuntimeState) -> Result<(), String> {
    if state.package_validated.load(Ordering::Acquire) {
        return Ok(());
    }
    crate::pet_package::preflight()?;
    state.package_validated.store(true, Ordering::Release);
    Ok(())
}

#[tauri::command]
pub(crate) async fn read_pet_package_file(
    state: tauri::State<'_, PetRuntimeState>,
    relative_path: String,
) -> Result<Vec<u8>, String> {
    validate_product_package(&state)?;
    crate::pet_package::runtime_file(&relative_path)
        .map(|bytes| bytes.to_vec())
        .ok_or_else(|| "pet_package_file_not_allowlisted".to_string())
}

#[tauri::command]
pub(crate) async fn list_pet_package_files(
    state: tauri::State<'_, PetRuntimeState>,
) -> Result<Vec<String>, String> {
    validate_product_package(&state)?;
    Ok(crate::pet_package::runtime_file_paths()
        .into_iter()
        .map(str::to_string)
        .collect())
}

#[cfg(windows)]
fn cache_hit_test_bridge_hwnd(
    state: &PetRuntimeState,
    hwnd: windows::Win32::Foundation::HWND,
) -> Result<(), String> {
    let mut cached = state
        .hit_test_bridge_hwnd
        .lock()
        .map_err(|_| "pet_hit_test_hwnd_lock_failed".to_string())?;
    *cached = Some(hwnd.0 as isize);
    Ok(())
}

#[cfg(windows)]
fn cached_hit_test_bridge_hwnd(
    state: &PetRuntimeState,
) -> Result<windows::Win32::Foundation::HWND, String> {
    let raw = state
        .hit_test_bridge_hwnd
        .lock()
        .map_err(|_| "pet_hit_test_hwnd_lock_failed".to_string())?
        .ok_or_else(|| "pet_hit_test_hwnd_missing".to_string())?;
    Ok(windows::Win32::Foundation::HWND(
        raw as *mut core::ffi::c_void,
    ))
}

fn operation_latency_ms(prepare_us: u64, native_operation_us: u64) -> u128 {
    u128::from(prepare_us.saturating_add(native_operation_us)) / 1_000
}

#[tauri::command]
pub(crate) async fn apply_pet_hit_region(
    window: WebviewWindow,
    state: tauri::State<'_, PetRuntimeState>,
    request: HitRegionRequest,
) -> Result<AppliedHitRegion, String> {
    ensure_pet_window(&window)?;
    if !state.package_validated.load(Ordering::Acquire) {
        return Err("pet_runtime_package_not_validated".to_string());
    }
    if let Some(error) = state.hit_test_bridge.latched_failure() {
        return Err(format!("pet_hit_test_bridge_failed_closed:{error}"));
    }

    let prepare_started = std::time::Instant::now();
    let plan = prepare_region(
        request.logical_width,
        request.logical_height,
        request.scale,
        request.rects,
    )
    .map_err(|error| error.to_string())?;
    let prepare_us = prepare_started.elapsed().as_micros() as u64;
    let rect_count = plan.rects.len();
    let physical_width = plan.physical_width;
    let physical_height = plan.physical_height;

    let bridge_update_started = std::time::Instant::now();
    state.hit_test_bridge.replace(plan)?;
    let bridge_update_us = bridge_update_started.elapsed().as_micros() as u64;

    #[cfg(windows)]
    let (hwnd, window_handle_us, dispatch_wait_us, subclass_install_us) = {
        let mut installed = state
            .hit_test_bridge_installed
            .lock()
            .map_err(|_| "pet_hit_test_install_lock_failed".to_string())?;
        if *installed {
            let started = std::time::Instant::now();
            let hwnd = cached_hit_test_bridge_hwnd(&state)?;
            (hwnd, started.elapsed().as_micros() as u64, 0, 0)
        } else {
            let dispatch_window = window.clone();
            let operation_window = window.clone();
            let bridge = Arc::clone(&state.hit_test_bridge);
            let dispatched = run_on_dispatcher(
                move |task| {
                    dispatch_window
                        .run_on_main_thread(task)
                        .map_err(|error| error.to_string())
                },
                move || {
                    let hwnd = operation_window.hwnd().map_err(|error| error.to_string())?;
                    hit_test_bridge::install_hit_test_bridge(hwnd, &bridge)?;
                    Ok(hwnd.0 as isize)
                },
            )?;
            let hwnd = windows::Win32::Foundation::HWND(dispatched.value as *mut core::ffi::c_void);
            cache_hit_test_bridge_hwnd(&state, hwnd)?;
            *installed = true;
            (
                hwnd,
                0,
                dispatched.dispatch_wait_us,
                dispatched.operation_us,
            )
        }
    };

    #[cfg(windows)]
    let dpi_query_started = std::time::Instant::now();
    #[cfg(windows)]
    let native_scale_factor =
        hit_region::window_scale_factor(hwnd).map_err(|error| error.to_string())?;
    #[cfg(windows)]
    let dpi_query_us = dpi_query_started.elapsed().as_micros() as u64;

    #[cfg(not(windows))]
    return Err("native_pet_hit_region_requires_windows".to_string());

    let native_operation_us = bridge_update_us
        .saturating_add(subclass_install_us)
        .saturating_add(window_handle_us)
        .saturating_add(dpi_query_us);
    let applied = AppliedHitRegion {
        frame_id: request.frame_id,
        rect_count,
        physical_width,
        physical_height,
        latency_ms: operation_latency_ms(prepare_us, native_operation_us),
        dispatch_wait_us,
        native_operation_us,
        prepare_us,
        window_handle_us,
        bridge_update_us,
        subclass_install_us,
        dpi_query_us,
        native_scale_factor,
        native_bridge: "win32_cursor_ws_ex_transparent",
    };
    let sequence = state.hit_region_updates.fetch_add(1, Ordering::Relaxed) + 1;
    if sequence == 1 || sequence.is_multiple_of(120) {
        crate::append_log(
            window.app_handle(),
            "pet.hitmask_applied",
            &format!(
                "sequence={sequence} frame={} rects={} latency_ms={}",
                applied.frame_id, applied.rect_count, applied.latency_ms
            ),
        );
    }
    Ok(applied)
}

#[tauri::command]
pub(crate) async fn probe_pet_hit_region(
    state: tauri::State<'_, PetRuntimeState>,
    points: Vec<ProbePoint>,
) -> Result<Vec<bool>, String> {
    #[cfg(windows)]
    {
        let snapshot = state.hit_test_bridge.snapshot();
        if snapshot.rect_count == 0 {
            return Err("pet_hit_test_bridge_has_no_mask".to_string());
        }
        let points = points
            .into_iter()
            .map(|point| (point.x, point.y))
            .collect::<Vec<_>>();
        Ok(probe_mask_points(&state.hit_test_bridge, &points))
    }

    #[cfg(not(windows))]
    Err("native_pet_hit_region_requires_windows".to_string())
}

#[tauri::command]
pub(crate) async fn move_pet_window(
    window: WebviewWindow,
    delta_x_css: f64,
    delta_y_css: f64,
) -> Result<(), String> {
    ensure_pet_window(&window)?;
    if !delta_x_css.is_finite()
        || !delta_y_css.is_finite()
        || delta_x_css.abs() > 512.0
        || delta_y_css.abs() > 512.0
    {
        return Err("pet_window_move_delta_invalid".to_string());
    }
    let scale = window.scale_factor().map_err(|error| error.to_string())?;
    let position = window.outer_position().map_err(|error| error.to_string())?;
    window
        .set_position(tauri::PhysicalPosition::new(
            position.x + (delta_x_css * scale).round() as i32,
            position.y + (delta_y_css * scale).round() as i32,
        ))
        .map_err(|error| error.to_string())
}

#[tauri::command]
pub(crate) async fn pet_runtime_ready(
    app: AppHandle,
    state: tauri::State<'_, PetRuntimeState>,
    manifest_sha256: String,
    package_tree_sha256: String,
) -> Result<(), String> {
    let package = crate::pet_package::preflight()?;
    if !manifest_sha256.eq_ignore_ascii_case(&package.manifest_sha256)
        || !package_tree_sha256.eq_ignore_ascii_case(&package.package_tree_sha256)
    {
        return Err("pet_runtime_identity_mismatch".to_string());
    }
    state.package_validated.store(true, Ordering::Release);
    state.runtime_ready.store(true, Ordering::Release);
    crate::append_log(
        &app,
        "pet.runtime_ready",
        &format!(
            "pet_id={} package_version={} manifest_sha256={} package_tree_sha256={}",
            package.pet_id,
            package.package_version,
            package.manifest_sha256,
            package.package_tree_sha256
        ),
    );
    Ok(())
}

#[tauri::command]
pub(crate) async fn record_pet_event(
    app: AppHandle,
    state: tauri::State<'_, PetRuntimeState>,
    event: String,
    payload: Value,
) -> Result<(), String> {
    if event.is_empty()
        || event.len() > 80
        || !event
            .chars()
            .all(|character| character.is_ascii_alphanumeric() || "._-".contains(character))
    {
        return Err("pet_runtime_event_invalid".to_string());
    }
    let sequence = state.event_sequence.fetch_add(1, Ordering::Relaxed) + 1;
    let noisy = matches!(event.as_str(), "hitmask_applied" | "frame_presented");
    if noisy && sequence != 1 && !sequence.is_multiple_of(120) {
        return Ok(());
    }
    let mut detail = payload.to_string().replace(['\r', '\n'], " ");
    detail.truncate(2_048);
    crate::append_log(
        &app,
        "pet.runtime_event",
        &format!("sequence={sequence} event={event} payload={detail}"),
    );
    Ok(())
}

#[cfg(windows)]
fn pause_native_bridge(window: &WebviewWindow, state: &PetRuntimeState) -> Result<(), String> {
    let installed = state
        .hit_test_bridge_installed
        .lock()
        .map_err(|_| "pet_hit_test_install_lock_failed".to_string())?;
    if !*installed {
        return Ok(());
    }
    drop(installed);
    let hwnd = window.hwnd().map_err(|error| error.to_string())?;
    hit_test_bridge::pause_hit_test_bridge(hwnd, &state.hit_test_bridge)
}

#[cfg(windows)]
fn resume_native_bridge(window: &WebviewWindow, state: &PetRuntimeState) -> Result<(), String> {
    let installed = state
        .hit_test_bridge_installed
        .lock()
        .map_err(|_| "pet_hit_test_install_lock_failed".to_string())?;
    if !*installed {
        return Ok(());
    }
    drop(installed);
    let hwnd = window.hwnd().map_err(|error| error.to_string())?;
    hit_test_bridge::resume_hit_test_bridge(hwnd, &state.hit_test_bridge)
}

pub(crate) fn pause_for_window(
    window: &WebviewWindow,
    state: &PetRuntimeState,
) -> Result<(), String> {
    ensure_pet_window(window)?;
    #[cfg(windows)]
    {
        pause_native_bridge(window, state)
    }
    #[cfg(not(windows))]
    {
        Ok(())
    }
}

pub(crate) fn resume_for_window(
    window: &WebviewWindow,
    state: &PetRuntimeState,
) -> Result<(), String> {
    ensure_pet_window(window)?;
    #[cfg(windows)]
    {
        resume_native_bridge(window, state)
    }
    #[cfg(not(windows))]
    {
        Ok(())
    }
}

pub(crate) fn mark_runtime_failed(state: &PetRuntimeState) {
    state.runtime_ready.store(false, Ordering::Release);
}

#[cfg(test)]
mod tests {
    #[test]
    fn event_name_restriction_accepts_runtime_semantics_only() {
        for accepted in ["animation_finished", "pet.runtime-ready", "hitmask_applied"] {
            assert!(accepted
                .chars()
                .all(|character| character.is_ascii_alphanumeric() || "._-".contains(character)));
        }
        assert!(!"line\nbreak"
            .chars()
            .all(|character| { character.is_ascii_alphanumeric() || "._-".contains(character) }));
    }
}
