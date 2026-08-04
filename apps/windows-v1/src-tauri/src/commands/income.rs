use tauri::AppHandle;

use crate::{append_log, domain, models, services};

#[tauri::command]
pub(crate) fn calculate_month_salary(
    app: AppHandle,
    month: String,
    schedule: domain::SalarySchedule,
    calendar: domain::CalendarData,
) -> Result<domain::MonthSalary, String> {
    let result =
        services::income_service::IncomeService::calculate_month(&month, &schedule, &calendar);
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
pub(crate) fn calculate_today_income(
    app: AppHandle,
    request: models::income::TodayIncomeRequest,
) -> Result<domain::TodaySnapshot, String> {
    let result = services::income_service::IncomeService::calculate_today(&request);
    if let Err(error) = &result {
        append_log(
            &app,
            "salary.calculate.invalid",
            &format!(
                "scope=today owner_date={} reason={error}",
                request.owner_date
            ),
        );
    }
    result
}

#[tauri::command]
pub(crate) fn resolve_schedule_owner_date(
    now_date: String,
    now_time: String,
    schedule: domain::SalarySchedule,
) -> Result<String, String> {
    services::income_service::IncomeService::resolve_schedule_owner_date(
        &now_date, &now_time, &schedule,
    )
}

#[tauri::command]
pub(crate) fn resolve_calendar_month(
    month: String,
    schedule: domain::SalarySchedule,
    calendar: domain::CalendarData,
) -> Result<Vec<domain::CalendarDay>, String> {
    services::income_service::IncomeService::resolve_calendar_month(&month, &schedule, &calendar)
}

#[tauri::command]
pub(crate) fn resolve_next_workday(
    after_date: String,
    schedule: domain::SalarySchedule,
    calendar: domain::CalendarData,
) -> Result<Option<String>, String> {
    services::income_service::IncomeService::resolve_next_workday(&after_date, &schedule, &calendar)
}
