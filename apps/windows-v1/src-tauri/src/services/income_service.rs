use crate::domain::{self, CalendarData, CalendarDay, MonthSalary, SalarySchedule, TodaySnapshot};
use crate::models::income::TodayIncomeRequest;

pub struct IncomeService;

impl IncomeService {
    pub fn calculate_month(
        month: &str,
        schedule: &SalarySchedule,
        calendar: &CalendarData,
    ) -> Result<MonthSalary, String> {
        domain::calculate_month(month, schedule, calendar)
    }

    pub fn calculate_today(request: &TodayIncomeRequest) -> Result<TodaySnapshot, String> {
        domain::calculate_today(
            &request.owner_date,
            &request.now_date,
            &request.now_time,
            &request.schedule,
            &request.month_salary,
            &request.calendar,
        )
    }

    pub fn resolve_schedule_owner_date(
        now_date: &str,
        now_time: &str,
        schedule: &SalarySchedule,
    ) -> Result<String, String> {
        domain::resolve_schedule_owner_date(now_date, now_time, schedule)
    }

    pub fn resolve_calendar_month(
        month: &str,
        schedule: &SalarySchedule,
        calendar: &CalendarData,
    ) -> Result<Vec<CalendarDay>, String> {
        domain::resolve_month_days(month, schedule, calendar)
    }

    pub fn resolve_next_workday(
        after_date: &str,
        schedule: &SalarySchedule,
        calendar: &CalendarData,
    ) -> Result<Option<String>, String> {
        domain::next_workday(after_date, schedule, calendar)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::AppConfig;
    use crate::domain::CalendarData;
    use crate::models::income::TodayIncomeRequest;

    #[test]
    fn income_service_is_the_application_boundary_for_month_and_today() {
        let schedule = AppConfig::default().salary_schedule();
        let calendar = CalendarData::default();
        let month = IncomeService::calculate_month("2026-07", &schedule, &calendar).unwrap();
        let today = IncomeService::calculate_today(&TodayIncomeRequest {
            owner_date: "2026-07-24".into(),
            now_date: "2026-07-24".into(),
            now_time: "10:00:00".into(),
            schedule,
            month_salary: month,
            calendar,
        })
        .unwrap();

        assert_eq!(today.schedule_owner_date, "2026-07-24");
        assert!(today.earned_minor >= 0);
    }

    #[test]
    fn income_service_preserves_domain_validation_errors() {
        let schedule = AppConfig::default().salary_schedule();
        let result =
            IncomeService::calculate_month("not-a-month", &schedule, &CalendarData::default());

        assert_eq!(result.unwrap_err(), "invalid_date");
    }
}
