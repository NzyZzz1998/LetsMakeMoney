use tauri::{AppHandle, Emitter, Manager};

use crate::append_log;
use crate::calendar_data::{self, CalendarCoverageMode};
use crate::domain::DateOverrideKind;
use crate::models::overtime::{
    OvertimeBoundaryResolution, OvertimeCalendarSource, OvertimeMutationResponse,
    OvertimeReadResponse, ResolveOvertimeBoundaryRequest, SaveOvertimeRequest,
};
use crate::repositories::overtime_repository::FileOvertimeRepository;
use crate::services::date_overtime_transaction::{
    self, DateOvertimeTransactionRequest, DateOvertimeTransactionResponse,
};
use crate::services::overtime_service::{OvertimeRuntime, OvertimeService};
use crate::RuntimeConfig;

fn repository(app: &AppHandle) -> Result<FileOvertimeRepository, String> {
    let data_dir = app
        .path()
        .app_data_dir()
        .map_err(|error| error.to_string())?;
    Ok(FileOvertimeRepository::new(
        data_dir.join("overtime-records.json"),
    ))
}

#[tauri::command]
pub(crate) fn resolve_overtime_boundary(
    app: AppHandle,
    config_state: tauri::State<'_, RuntimeConfig>,
    business_date: String,
    utc_offset_minutes: i16,
    override_kind: Option<DateOverrideKind>,
) -> Result<OvertimeBoundaryResolution, String> {
    let config = config_state
        .0
        .lock()
        .map_err(|_| "config_lock_failed".to_string())?
        .clone();
    let year = business_date
        .get(0..4)
        .and_then(|value| value.parse::<i32>().ok())
        .ok_or_else(|| "overtime_date_invalid".to_string())?;
    let dataset = calendar_data::load_calendar_year(year)?;
    let calendar_source = match dataset.coverage.mode {
        CalendarCoverageMode::Official => OvertimeCalendarSource::Official,
        CalendarCoverageMode::Estimated => OvertimeCalendarSource::Estimated,
    };
    let mut calendar = dataset.calendar;
    calendar.date_overrides = config.date_overrides.clone();
    if let Some(kind) = override_kind {
        calendar
            .date_overrides
            .retain(|entry| entry.date != business_date);
        calendar.date_overrides.push(crate::domain::DateOverride {
            date: business_date.clone(),
            kind,
            note: "date_overtime_draft".into(),
        });
    }
    let request = ResolveOvertimeBoundaryRequest {
        business_date: business_date.clone(),
        schedule: config.salary_schedule(),
        calendar,
        calendar_source,
        utc_offset_minutes,
    };
    let date = business_date;
    match OvertimeService::resolve_boundary(&request) {
        Ok(result) => {
            append_log(
                &app,
                "overtime.boundary_resolved",
                &format!(
                    "date={date} source={} origin={:?} maximum_minutes={} suggested_minutes={}",
                    result.day_source,
                    result.origin,
                    result.snapshot.maximum_minutes,
                    result
                        .suggested_minutes
                        .map(|value| value.to_string())
                        .unwrap_or_else(|| "none".into())
                ),
            );
            Ok(result)
        }
        Err(error) => {
            append_log(
                &app,
                "overtime.boundary_failed",
                &format!("date={date} code={} message={}", error.code, error.message),
            );
            Err(format!("{}:{}", error.code, error.message))
        }
    }
}

#[tauri::command]
pub(crate) fn read_overtime_record(
    app: AppHandle,
    state: tauri::State<'_, OvertimeRuntime>,
    business_date: String,
) -> Result<OvertimeReadResponse, String> {
    let _guard = state.0.lock().map_err(|_| "overtime_lock_failed")?;
    let result = OvertimeService::read_record(&repository(&app)?, &business_date);
    append_log(
        &app,
        "overtime.read",
        &format!(
            "date={business_date} status={} schema={}",
            result.status.as_str(),
            result.schema_version
        ),
    );
    Ok(result)
}

#[tauri::command]
pub(crate) fn read_overtime_month(
    app: AppHandle,
    state: tauri::State<'_, OvertimeRuntime>,
    month: String,
) -> Result<OvertimeReadResponse, String> {
    let _guard = state.0.lock().map_err(|_| "overtime_lock_failed")?;
    let result = OvertimeService::read_month(&repository(&app)?, &month);
    append_log(
        &app,
        "overtime.month_read",
        &format!(
            "month={month} status={} count={} schema={}",
            result.status.as_str(),
            result.records.len(),
            result.schema_version
        ),
    );
    Ok(result)
}

#[tauri::command]
pub(crate) fn save_overtime_record(
    app: AppHandle,
    state: tauri::State<'_, OvertimeRuntime>,
    request: SaveOvertimeRequest,
) -> Result<OvertimeMutationResponse, String> {
    let _guard = state.0.lock().map_err(|_| "overtime_lock_failed")?;
    let date = request.business_date.clone();
    let minutes = request.minutes;
    let result = OvertimeService::save_record(&repository(&app)?, request);
    append_log(
        &app,
        "overtime.mutation",
        &format!(
            "date={date} minutes={minutes} action={} schema={} error={}",
            result.status.as_str(),
            result.schema_version,
            result.error_code.as_deref().unwrap_or("none")
        ),
    );
    Ok(result)
}

#[tauri::command]
pub(crate) fn delete_overtime_record(
    app: AppHandle,
    state: tauri::State<'_, OvertimeRuntime>,
    business_date: String,
) -> Result<OvertimeMutationResponse, String> {
    let _guard = state.0.lock().map_err(|_| "overtime_lock_failed")?;
    let result = OvertimeService::delete_record(&repository(&app)?, &business_date);
    append_log(
        &app,
        "overtime.mutation",
        &format!(
            "date={business_date} minutes=0 action={} schema={} error={}",
            result.status.as_str(),
            result.schema_version,
            result.error_code.as_deref().unwrap_or("none")
        ),
    );
    Ok(result)
}

#[tauri::command]
pub(crate) fn recover_overtime_records(
    app: AppHandle,
    state: tauri::State<'_, OvertimeRuntime>,
) -> Result<OvertimeMutationResponse, String> {
    let _guard = state.0.lock().map_err(|_| "overtime_lock_failed")?;
    let result = OvertimeService::recover(&repository(&app)?);
    append_log(
        &app,
        "overtime.recovery",
        &format!(
            "action={} schema={} error={}",
            result.status.as_str(),
            result.schema_version,
            result.error_code.as_deref().unwrap_or("none")
        ),
    );
    Ok(result)
}

#[tauri::command]
pub(crate) fn save_date_overtime_transaction(
    app: AppHandle,
    config_state: tauri::State<'_, RuntimeConfig>,
    overtime_state: tauri::State<'_, OvertimeRuntime>,
    request: DateOvertimeTransactionRequest,
) -> Result<DateOvertimeTransactionResponse, String> {
    let _overtime_guard = overtime_state
        .0
        .lock()
        .map_err(|_| "overtime_lock_failed".to_string())?;
    let data_dir = app
        .path()
        .app_data_dir()
        .map_err(|error| error.to_string())?;
    let date = request.date.clone();
    let result = date_overtime_transaction::execute(
        &data_dir,
        &config_state.0,
        &FileOvertimeRepository::new(data_dir.join("overtime-records.json")),
        request,
    );
    match result {
        Ok(response) => {
            append_log(
                &app,
                "date_overtime.transaction_committed",
                &format!(
                    "date={date} status={} overtime_changed={}",
                    response.status, response.overtime_changed
                ),
            );
            if response.status == "saved" {
                let _ = app.emit(
                    "lmm://configuration-updated",
                    serde_json::json!({ "source": "date_overtime_transaction" }),
                );
                if response.overtime_changed {
                    let _ = app.emit(
                        "lmm://overtime-updated",
                        serde_json::json!({ "status": "saved" }),
                    );
                }
            }
            Ok(response)
        }
        Err(error) => {
            append_log(
                &app,
                "date_overtime.transaction_failed",
                &format!("date={date} reason={}", error.replace(['\r', '\n'], " ")),
            );
            Err(error)
        }
    }
}
