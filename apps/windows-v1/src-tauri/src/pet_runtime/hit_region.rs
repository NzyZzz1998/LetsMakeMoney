use serde::{Deserialize, Serialize};
use std::{
    fmt,
    sync::mpsc::sync_channel,
    time::{Duration, Instant},
};

pub type DispatchTask = Box<dyn FnOnce() + Send + 'static>;

#[derive(Debug, Eq, PartialEq)]
pub struct DispatchedOperation<T> {
    pub value: T,
    pub dispatch_wait_us: u64,
    pub operation_us: u64,
}

pub fn run_on_dispatcher<T, Dispatch, Operation>(
    dispatch: Dispatch,
    operation: Operation,
) -> Result<DispatchedOperation<T>, String>
where
    T: Send + 'static,
    Dispatch: FnOnce(DispatchTask) -> Result<(), String>,
    Operation: FnOnce() -> Result<T, String> + Send + 'static,
{
    let queued_at = Instant::now();
    let (sender, receiver) = sync_channel(1);
    dispatch(Box::new(move || {
        let operation_started = Instant::now();
        let dispatch_wait_us = duration_us(queued_at.elapsed());
        let value = operation();
        let operation_us = duration_us(operation_started.elapsed());
        let _ = sender.send((dispatch_wait_us, operation_us, value));
    }))?;
    let (dispatch_wait_us, operation_us, value) = receiver
        .recv()
        .map_err(|_| "window_thread_dispatch_cancelled".to_string())?;

    Ok(DispatchedOperation {
        value: value?,
        dispatch_wait_us,
        operation_us,
    })
}

fn duration_us(duration: Duration) -> u64 {
    duration.as_micros().min(u128::from(u64::MAX)) as u64
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct HitRect {
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
}

impl HitRect {
    pub const fn new(x: i32, y: i32, width: i32, height: i32) -> Self {
        Self {
            x,
            y,
            width,
            height,
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum RegionError {
    InvalidDimensions,
    InvalidScale,
    EmptyRegion,
    InvalidRect,
    OutOfBounds,
    PermanentRectangleFallback,
    NativeDpiQueryFailed,
}

pub fn scale_from_dpi(dpi: u32) -> Result<f64, RegionError> {
    if dpi == 0 {
        return Err(RegionError::NativeDpiQueryFailed);
    }
    Ok(f64::from(dpi) / 96.0)
}

impl fmt::Display for RegionError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "{self:?}")
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct RegionPlan {
    pub logical_width: i32,
    pub logical_height: i32,
    pub physical_width: i32,
    pub physical_height: i32,
    pub rects: Vec<HitRect>,
    pub is_full_window: bool,
}

pub fn prepare_region(
    logical_width: i32,
    logical_height: i32,
    scale: f64,
    rects: Vec<HitRect>,
) -> Result<RegionPlan, RegionError> {
    if logical_width <= 0 || logical_height <= 0 {
        return Err(RegionError::InvalidDimensions);
    }
    if !scale.is_finite() || scale <= 0.0 {
        return Err(RegionError::InvalidScale);
    }
    if rects.is_empty() {
        return Err(RegionError::EmptyRegion);
    }

    let mut coverage = vec![false; (logical_width as usize) * (logical_height as usize)];
    for rect in &rects {
        if rect.width <= 0 || rect.height <= 0 || rect.x < 0 || rect.y < 0 {
            return Err(RegionError::InvalidRect);
        }
        let right = rect
            .x
            .checked_add(rect.width)
            .ok_or(RegionError::OutOfBounds)?;
        let bottom = rect
            .y
            .checked_add(rect.height)
            .ok_or(RegionError::OutOfBounds)?;
        if right > logical_width || bottom > logical_height {
            return Err(RegionError::OutOfBounds);
        }
        for y in rect.y..bottom {
            let row = (y * logical_width) as usize;
            coverage[(row + rect.x as usize)..(row + right as usize)].fill(true);
        }
    }

    let is_full_window = coverage.iter().all(|value| *value);
    if is_full_window {
        return Err(RegionError::PermanentRectangleFallback);
    }

    let physical_width = (logical_width as f64 * scale).round() as i32;
    let physical_height = (logical_height as f64 * scale).round() as i32;
    let physical_rects = rects
        .into_iter()
        .map(|rect| {
            let left = (rect.x as f64 * scale).floor() as i32;
            let top = (rect.y as f64 * scale).floor() as i32;
            let right = ((rect.x + rect.width) as f64 * scale).ceil() as i32;
            let bottom = ((rect.y + rect.height) as f64 * scale).ceil() as i32;
            HitRect::new(left, top, right - left, bottom - top)
        })
        .collect();

    Ok(RegionPlan {
        logical_width,
        logical_height,
        physical_width,
        physical_height,
        rects: physical_rects,
        is_full_window,
    })
}

#[cfg(windows)]
pub fn window_scale_factor(hwnd: windows::Win32::Foundation::HWND) -> Result<f64, RegionError> {
    use windows::Win32::UI::HiDpi::GetDpiForWindow;

    scale_from_dpi(unsafe { GetDpiForWindow(hwnd) })
}
