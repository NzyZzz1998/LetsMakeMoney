use serde::Deserialize;

use crate::domain::{CalendarData, MonthSalary, SalarySchedule};

#[derive(Clone, Debug, Deserialize)]
pub struct TodayIncomeRequest {
    pub owner_date: String,
    pub now_date: String,
    pub now_time: String,
    pub schedule: SalarySchedule,
    pub month_salary: MonthSalary,
    pub calendar: CalendarData,
}
