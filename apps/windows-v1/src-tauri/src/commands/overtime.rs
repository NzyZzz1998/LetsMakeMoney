use tauri::{AppHandle, Manager};

use crate::append_log;
use crate::models::overtime::{
    OvertimeMutationResponse, OvertimeReadResponse, SaveOvertimeRequest,
};
use crate::repositories::overtime_repository::FileOvertimeRepository;
use crate::services::overtime_service::{OvertimeRuntime, OvertimeService};

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
