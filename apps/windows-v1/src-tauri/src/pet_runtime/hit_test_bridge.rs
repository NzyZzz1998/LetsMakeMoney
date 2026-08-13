use super::hit_region::RegionPlan;
use serde::Serialize;
use std::sync::{
    atomic::{AtomicBool, AtomicU64, Ordering},
    Arc, RwLock,
};

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum HitTestDisposition {
    Client,
    Transparent,
}

#[derive(Clone, Debug, Default, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct HitTestBridgeSnapshot {
    pub physical_width: i32,
    pub physical_height: i32,
    pub rect_count: usize,
    pub click_through: bool,
    pub initialized: bool,
    pub transitions: u64,
    pub polling_active: bool,
    pub failed_closed: bool,
    pub transient_refresh_failures: u64,
    pub last_error: Option<String>,
}

#[derive(Debug, Default)]
pub struct HitTestBridgeState {
    plan: RwLock<Option<RegionPlan>>,
    click_through: AtomicBool,
    initialized: AtomicBool,
    transitions: AtomicU64,
    polling_active: AtomicBool,
    failed_closed: AtomicBool,
    transient_refresh_failures: AtomicU64,
    last_error: RwLock<Option<String>>,
}

impl HitTestBridgeState {
    pub fn replace(&self, plan: RegionPlan) -> Result<(), String> {
        let mut current = self
            .plan
            .write()
            .map_err(|_| "hit_test_bridge_lock_poisoned".to_string())?;
        *current = Some(plan);
        Ok(())
    }

    pub fn classify(&self, x: i32, y: i32) -> HitTestDisposition {
        let Ok(current) = self.plan.read() else {
            return HitTestDisposition::Transparent;
        };
        let Some(plan) = current.as_ref() else {
            return HitTestDisposition::Transparent;
        };
        if x < 0 || y < 0 || x >= plan.physical_width || y >= plan.physical_height {
            return HitTestDisposition::Transparent;
        }
        if plan.rects.iter().any(|rect| {
            x >= rect.x && x < rect.x + rect.width && y >= rect.y && y < rect.y + rect.height
        }) {
            HitTestDisposition::Client
        } else {
            HitTestDisposition::Transparent
        }
    }

    pub fn snapshot(&self) -> HitTestBridgeSnapshot {
        let mut snapshot = self
            .plan
            .read()
            .ok()
            .and_then(|current| {
                current.as_ref().map(|plan| HitTestBridgeSnapshot {
                    physical_width: plan.physical_width,
                    physical_height: plan.physical_height,
                    rect_count: plan.rects.len(),
                    ..HitTestBridgeSnapshot::default()
                })
            })
            .unwrap_or_default();
        snapshot.click_through = self.click_through.load(Ordering::Acquire);
        snapshot.initialized = self.initialized.load(Ordering::Acquire);
        snapshot.transitions = self.transitions.load(Ordering::Relaxed);
        snapshot.polling_active = self.polling_active.load(Ordering::Acquire);
        snapshot.failed_closed = self.failed_closed.load(Ordering::Acquire);
        snapshot.transient_refresh_failures =
            self.transient_refresh_failures.load(Ordering::Relaxed);
        snapshot.last_error = self.last_error.read().ok().and_then(|error| error.clone());
        snapshot
    }

    pub fn record_polling_started(&self) -> bool {
        if self.failed_closed.load(Ordering::Acquire) {
            return false;
        }
        !self.polling_active.swap(true, Ordering::AcqRel)
    }

    pub fn record_polling_paused(&self) -> bool {
        self.polling_active.swap(false, Ordering::AcqRel)
    }

    pub fn record_refresh_failure(&self, error: impl Into<String>) {
        if let Ok(mut current) = self.last_error.write() {
            if current.is_none() {
                *current = Some(error.into());
            }
        }
        self.polling_active.store(false, Ordering::Release);
        self.failed_closed.store(true, Ordering::Release);
    }

    pub fn record_transient_refresh_failure(&self) {
        self.transient_refresh_failures
            .fetch_add(1, Ordering::Relaxed);
    }

    pub fn latched_failure(&self) -> Option<String> {
        if !self.failed_closed.load(Ordering::Acquire) {
            return None;
        }
        Some(
            self.last_error
                .read()
                .ok()
                .and_then(|error| error.clone())
                .unwrap_or_else(|| {
                    "hit_test_bridge_failed_closed_diagnostic_unavailable".to_string()
                }),
        )
    }

    fn record_click_through(&self, click_through: bool) {
        let initialized = self.initialized.swap(true, Ordering::AcqRel);
        let previous = self.click_through.swap(click_through, Ordering::AcqRel);
        if !initialized || previous != click_through {
            self.transitions.fetch_add(1, Ordering::Relaxed);
        }
    }
}

pub const fn next_click_through_state(
    disposition: HitTestDisposition,
    pointer_button_down: bool,
    current_click_through: bool,
) -> bool {
    if pointer_button_down {
        current_click_through
    } else {
        matches!(disposition, HitTestDisposition::Transparent)
    }
}

pub fn probe_mask_points(state: &HitTestBridgeState, points: &[(i32, i32)]) -> Vec<bool> {
    points
        .iter()
        .map(|(x, y)| state.classify(*x, *y) == HitTestDisposition::Client)
        .collect()
}

#[cfg(windows)]
const HIT_TEST_SUBCLASS_ID: usize = 0x4C4D_4D48;
#[cfg(windows)]
const PASSTHROUGH_TIMER_ID: usize = 0x4C4D_4D54;
#[cfg(windows)]
const PASSTHROUGH_POLL_MS: u32 = 8;

const E_ACCESSDENIED_HRESULT: i32 = 0x8007_0005_u32 as i32;

pub const fn is_transient_pointer_query_hresult(code: i32) -> bool {
    code == E_ACCESSDENIED_HRESULT
}

#[cfg(windows)]
#[derive(Debug)]
enum PointerRefreshFailure {
    DesktopTemporarilyUnavailable,
    Fatal(String),
}

#[cfg(windows)]
pub fn install_hit_test_bridge(
    hwnd: windows::Win32::Foundation::HWND,
    state: &Arc<HitTestBridgeState>,
) -> Result<(), String> {
    use windows::Win32::UI::{
        Shell::{RemoveWindowSubclass, SetWindowSubclass},
        WindowsAndMessaging::KillTimer,
    };

    let installed = unsafe {
        SetWindowSubclass(
            hwnd,
            Some(hit_test_subclass_proc),
            HIT_TEST_SUBCLASS_ID,
            Arc::as_ptr(state) as usize,
        )
    };
    if !installed.as_bool() {
        return Err("hit_test_bridge_install_failed".to_string());
    }

    if let Err(error) = resume_hit_test_bridge(hwnd, state) {
        unsafe {
            let _ = KillTimer(Some(hwnd), PASSTHROUGH_TIMER_ID);
            let _ = RemoveWindowSubclass(hwnd, Some(hit_test_subclass_proc), HIT_TEST_SUBCLASS_ID);
        }
        return Err(error);
    }

    Ok(())
}

#[cfg(windows)]
pub fn pause_hit_test_bridge(
    hwnd: windows::Win32::Foundation::HWND,
    state: &HitTestBridgeState,
) -> Result<(), String> {
    use windows::Win32::UI::WindowsAndMessaging::KillTimer;

    if state.snapshot().polling_active {
        if let Err(error) = unsafe { KillTimer(Some(hwnd), PASSTHROUGH_TIMER_ID) } {
            let fail_closed_error = force_click_through(hwnd, state).err();
            let diagnostic = match fail_closed_error {
                Some(fail_closed) => {
                    format!("hit_test_bridge_timer_pause_failed:{error}|fail_closed:{fail_closed}")
                }
                None => format!("hit_test_bridge_timer_pause_failed:{error}"),
            };
            state.record_refresh_failure(diagnostic.clone());
            return Err(diagnostic);
        }
        state.record_polling_paused();
    }
    force_click_through(hwnd, state).map_err(|error| {
        let diagnostic = format!("hit_test_bridge_pause_fail_closed_failed:{error}");
        state.record_refresh_failure(diagnostic.clone());
        diagnostic
    })
}

#[cfg(windows)]
pub fn resume_hit_test_bridge(
    hwnd: windows::Win32::Foundation::HWND,
    state: &HitTestBridgeState,
) -> Result<(), String> {
    use windows::Win32::UI::WindowsAndMessaging::{KillTimer, SetTimer};

    if let Some(error) = state.latched_failure() {
        return Err(format!("hit_test_bridge_failed_closed:{error}"));
    }
    if state.snapshot().polling_active {
        return Ok(());
    }

    let timer_id = unsafe { SetTimer(Some(hwnd), PASSTHROUGH_TIMER_ID, PASSTHROUGH_POLL_MS, None) };
    if timer_id == 0 {
        let error = "hit_test_bridge_timer_install_failed".to_string();
        state.record_refresh_failure(error.clone());
        return Err(error);
    }

    match refresh_pointer_passthrough(hwnd, state) {
        Ok(()) => {}
        Err(PointerRefreshFailure::DesktopTemporarilyUnavailable) => {
            force_click_through(hwnd, state).map_err(|error| {
                let diagnostic = format!("hit_test_desktop_transition_fail_open_failed:{error}");
                state.record_refresh_failure(diagnostic.clone());
                diagnostic
            })?;
            state.record_transient_refresh_failure();
        }
        Err(PointerRefreshFailure::Fatal(error)) => {
            unsafe {
                let _ = KillTimer(Some(hwnd), PASSTHROUGH_TIMER_ID);
            }
            let fail_closed_error = force_click_through(hwnd, state).err();
            let diagnostic = match fail_closed_error {
                Some(fail_closed) => format!("{error}|fail_closed:{fail_closed}"),
                None => error,
            };
            state.record_refresh_failure(diagnostic.clone());
            return Err(diagnostic);
        }
    }

    state.record_polling_started();
    Ok(())
}

#[cfg(windows)]
unsafe extern "system" fn hit_test_subclass_proc(
    hwnd: windows::Win32::Foundation::HWND,
    message: u32,
    wparam: windows::Win32::Foundation::WPARAM,
    lparam: windows::Win32::Foundation::LPARAM,
    _subclass_id: usize,
    reference_data: usize,
) -> windows::Win32::Foundation::LRESULT {
    use windows::Win32::UI::{
        Shell::{DefSubclassProc, RemoveWindowSubclass},
        WindowsAndMessaging::{KillTimer, WM_NCDESTROY, WM_TIMER},
    };

    if message == WM_TIMER && wparam.0 == PASSTHROUGH_TIMER_ID && reference_data != 0 {
        let state = &*(reference_data as *const HitTestBridgeState);
        match refresh_pointer_passthrough(hwnd, state) {
            Ok(()) => {}
            Err(PointerRefreshFailure::DesktopTemporarilyUnavailable) => {
                handle_transient_desktop_unavailable(hwnd, state);
            }
            Err(PointerRefreshFailure::Fatal(error)) => {
                handle_refresh_failure(hwnd, state, error);
            }
        }
        return windows::Win32::Foundation::LRESULT(0);
    }

    if message == WM_NCDESTROY {
        let _ = KillTimer(Some(hwnd), PASSTHROUGH_TIMER_ID);
        let _ = RemoveWindowSubclass(hwnd, Some(hit_test_subclass_proc), HIT_TEST_SUBCLASS_ID);
    }

    DefSubclassProc(hwnd, message, wparam, lparam)
}

#[cfg(windows)]
fn handle_transient_desktop_unavailable(
    hwnd: windows::Win32::Foundation::HWND,
    state: &HitTestBridgeState,
) {
    if let Err(error) = force_click_through(hwnd, state) {
        handle_refresh_failure(
            hwnd,
            state,
            format!("hit_test_desktop_transition_fail_open_failed:{error}"),
        );
        return;
    }
    state.record_transient_refresh_failure();
}

#[cfg(windows)]
fn handle_refresh_failure(
    hwnd: windows::Win32::Foundation::HWND,
    state: &HitTestBridgeState,
    error: String,
) {
    use windows::Win32::UI::WindowsAndMessaging::KillTimer;

    let timer_error = unsafe { KillTimer(Some(hwnd), PASSTHROUGH_TIMER_ID) }
        .err()
        .map(|failure| format!("timer_stop:{failure}"));
    let fail_closed_error = force_click_through(hwnd, state)
        .err()
        .map(|failure| format!("fail_closed:{failure}"));
    let diagnostic = [Some(error), timer_error, fail_closed_error]
        .into_iter()
        .flatten()
        .collect::<Vec<_>>()
        .join("|");
    state.record_refresh_failure(diagnostic);
}

#[cfg(windows)]
fn refresh_pointer_passthrough(
    hwnd: windows::Win32::Foundation::HWND,
    state: &HitTestBridgeState,
) -> Result<(), PointerRefreshFailure> {
    use windows::Win32::{
        Foundation::POINT,
        Graphics::Gdi::ScreenToClient,
        UI::{
            Input::KeyboardAndMouse::{GetAsyncKeyState, VK_LBUTTON, VK_MBUTTON, VK_RBUTTON},
            WindowsAndMessaging::{
                GetCursorPos, GetWindowLongPtrW, GWL_EXSTYLE, WS_EX_TRANSPARENT,
            },
        },
    };

    let mut point = POINT::default();
    unsafe { GetCursorPos(&mut point) }.map_err(|error| {
        if is_transient_pointer_query_hresult(error.code().0) {
            PointerRefreshFailure::DesktopTemporarilyUnavailable
        } else {
            PointerRefreshFailure::Fatal(format!("hit_test_cursor_query_failed:{error}"))
        }
    })?;
    if !unsafe { ScreenToClient(hwnd, &mut point) }.as_bool() {
        return Err(PointerRefreshFailure::Fatal(
            "hit_test_cursor_coordinate_conversion_failed".to_string(),
        ));
    }

    let current_style = unsafe { GetWindowLongPtrW(hwnd, GWL_EXSTYLE) } as u32;
    let current_click_through = current_style & WS_EX_TRANSPARENT.0 != 0;
    let pointer_button_down = [VK_LBUTTON, VK_RBUTTON, VK_MBUTTON].iter().any(|key| {
        let state = unsafe { GetAsyncKeyState(i32::from(key.0)) } as u16;
        state & 0x8000 != 0
    });
    let desired_click_through = next_click_through_state(
        state.classify(point.x, point.y),
        pointer_button_down,
        current_click_through,
    );

    set_click_through(hwnd, state, desired_click_through).map_err(PointerRefreshFailure::Fatal)
}

#[cfg(windows)]
fn force_click_through(
    hwnd: windows::Win32::Foundation::HWND,
    state: &HitTestBridgeState,
) -> Result<(), String> {
    set_click_through(hwnd, state, true)
}

#[cfg(windows)]
fn set_click_through(
    hwnd: windows::Win32::Foundation::HWND,
    state: &HitTestBridgeState,
    desired_click_through: bool,
) -> Result<(), String> {
    use windows::Win32::UI::WindowsAndMessaging::{
        GetWindowLongPtrW, SetWindowLongPtrW, SetWindowPos, GWL_EXSTYLE, SWP_FRAMECHANGED,
        SWP_NOACTIVATE, SWP_NOMOVE, SWP_NOSIZE, SWP_NOZORDER, WS_EX_LAYERED, WS_EX_TRANSPARENT,
    };

    let current_style = unsafe { GetWindowLongPtrW(hwnd, GWL_EXSTYLE) } as u32;
    let layered_style = current_style | WS_EX_LAYERED.0;
    let next_style = if desired_click_through {
        layered_style | WS_EX_TRANSPARENT.0
    } else {
        layered_style & !WS_EX_TRANSPARENT.0
    };

    if next_style != current_style {
        unsafe {
            SetWindowLongPtrW(hwnd, GWL_EXSTYLE, next_style as isize);
            SetWindowPos(
                hwnd,
                None,
                0,
                0,
                0,
                0,
                SWP_FRAMECHANGED | SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER,
            )
        }
        .map_err(|error| format!("hit_test_passthrough_style_apply_failed:{error}"))?;

        let verified_style = unsafe { GetWindowLongPtrW(hwnd, GWL_EXSTYLE) } as u32;
        if verified_style & WS_EX_LAYERED.0 == 0 {
            return Err("hit_test_layered_style_verification_failed".to_string());
        }
        if (verified_style & WS_EX_TRANSPARENT.0 != 0) != desired_click_through {
            return Err("hit_test_passthrough_style_verification_failed".to_string());
        }
    } else if current_style & WS_EX_LAYERED.0 == 0 {
        return Err("hit_test_layered_style_missing".to_string());
    }

    state.record_click_through(desired_click_through);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::{is_transient_pointer_query_hresult, HitTestBridgeState};
    use std::sync::Arc;

    #[test]
    fn failed_closed_remains_latched_when_the_diagnostic_lock_is_poisoned() {
        let state = Arc::new(HitTestBridgeState::default());
        let poison_target = Arc::clone(&state);
        let _ = std::thread::spawn(move || {
            let _guard = poison_target
                .last_error
                .write()
                .expect("the diagnostic lock should begin healthy");
            panic!("intentional diagnostic lock poison");
        })
        .join();

        state.record_refresh_failure("unrecordable_native_failure");

        assert_eq!(
            state.latched_failure().as_deref(),
            Some("hit_test_bridge_failed_closed_diagnostic_unavailable")
        );
        assert!(!state.record_polling_started());
    }

    #[test]
    fn access_denied_during_a_desktop_transition_is_recoverable() {
        assert!(is_transient_pointer_query_hresult(0x8007_0005_u32 as i32));
        assert!(!is_transient_pointer_query_hresult(0x8007_0006_u32 as i32));
    }

    #[test]
    fn a_transient_desktop_transition_does_not_latch_the_bridge() {
        let state = HitTestBridgeState::default();
        assert!(state.record_polling_started());

        state.record_transient_refresh_failure();

        let snapshot = state.snapshot();
        assert!(snapshot.polling_active);
        assert!(!snapshot.failed_closed);
        assert_eq!(snapshot.transient_refresh_failures, 1);
        assert_eq!(state.latched_failure(), None);
    }
}
