use serde::{Deserialize, Serialize};

#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum RestMode {
    Single,
    Double,
    Alternating,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum WeekType {
    Big,
    Small,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum DayKind {
    Workday,
    RestDay,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct DateOverride {
    pub date: String,
    pub kind: DateOverrideKind,
    #[serde(default)]
    pub note: String,
}

#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum DateOverrideKind {
    Workday,
    PaidRest,
    UnpaidRest,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq, Default)]
pub struct CalendarData {
    #[serde(default)]
    pub statutory_holidays: Vec<String>,
    #[serde(default)]
    pub adjusted_workdays: Vec<String>,
    #[serde(default)]
    pub date_overrides: Vec<DateOverride>,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct SalarySchedule {
    pub monthly_salary_minor: i64,
    pub rest_mode: RestMode,
    pub alternating_anchor_date: Option<String>,
    pub alternating_anchor_week_type: Option<WeekType>,
    pub work_hours_per_day: f64,
    pub work_start_time: String,
    pub work_end_time: String,
    pub lunch_start_time: String,
    pub lunch_end_time: String,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct DayResolution {
    pub kind: DayKind,
    pub source: String,
    pub override_kind: Option<DateOverrideKind>,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct CalendarDay {
    pub date: String,
    pub kind: DayKind,
    pub source: String,
    pub automatic_kind: DayKind,
    pub automatic_source: String,
    pub override_kind: Option<DateOverrideKind>,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct MonthSalary {
    pub workdays: u32,
    pub salary_slot_count: u32,
    pub daily_salary_minor: i64,
    pub hourly_salary_minor: i64,
    pub payable_salary_minor: i64,
    pub working_saturdays: Vec<String>,
    pub salary_slots: Vec<SalarySlot>,
}

#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum SalarySlotKind {
    Workday,
    PaidRest,
    UnpaidRest,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct SalarySlot {
    pub date: String,
    pub index: u32,
    pub kind: SalarySlotKind,
    pub target_minor: i64,
    pub payable_minor: i64,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct TodaySnapshot {
    pub state: String,
    pub schedule_owner_date: String,
    pub algorithm_version: String,
    pub monthly_salary_minor: i64,
    pub effective_work_seconds: i64,
    pub completed_work_seconds: i64,
    pub earned_minor: i64,
    pub daily_target_minor: i64,
    pub hourly_salary_minor: i64,
    pub month_earned_minor: i64,
    pub payable_salary_minor: i64,
    pub salary_slot_index: Option<u32>,
    pub salary_slot_count: u32,
    pub next_boundary_seconds: Option<i64>,
    pub progress: f64,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
struct CivilDate {
    year: i32,
    month: u32,
    day: u32,
}

impl CivilDate {
    fn parse(value: &str) -> Result<Self, String> {
        let parts: Vec<_> = value.split('-').collect();
        if parts.len() != 3 {
            return Err("invalid_date".into());
        }
        let date = Self {
            year: parts[0].parse().map_err(|_| "invalid_date")?,
            month: parts[1].parse().map_err(|_| "invalid_date")?,
            day: parts[2].parse().map_err(|_| "invalid_date")?,
        };
        if date.month == 0
            || date.month > 12
            || date.day == 0
            || date.day > days_in_month(date.year, date.month)
        {
            return Err("invalid_date".into());
        }
        Ok(date)
    }

    fn format(self) -> String {
        format!("{:04}-{:02}-{:02}", self.year, self.month, self.day)
    }

    fn serial(self) -> i64 {
        days_from_civil(self.year, self.month, self.day)
    }

    fn weekday(self) -> u32 {
        ((self.serial() + 3).rem_euclid(7) + 1) as u32
    }

    fn add_days(self, days: i64) -> Self {
        civil_from_days(self.serial() + days)
    }
}

pub fn validate_date(value: &str) -> Result<(), String> {
    CivilDate::parse(value).map(|_| ())
}

fn days_from_civil(year: i32, month: u32, day: u32) -> i64 {
    let y = year - i32::from(month <= 2);
    let era = if y >= 0 { y } else { y - 399 } / 400;
    let yoe = y - era * 400;
    let mp = month as i32 + if month > 2 { -3 } else { 9 };
    let doy = (153 * mp + 2) / 5 + day as i32 - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    (era * 146097 + doe - 719468) as i64
}

fn civil_from_days(days: i64) -> CivilDate {
    let z = days + 719468;
    let era = if z >= 0 { z } else { z - 146096 } / 146097;
    let doe = z - era * 146097;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let mut year = (yoe + era * 400) as i32;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let day = doy - (153 * mp + 2) / 5 + 1;
    let month = mp + if mp < 10 { 3 } else { -9 };
    year += i32::from(month <= 2);
    CivilDate {
        year,
        month: month as u32,
        day: day as u32,
    }
}

fn days_in_month(year: i32, month: u32) -> u32 {
    match month {
        1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
        4 | 6 | 9 | 11 => 30,
        2 if year % 400 == 0 || (year % 4 == 0 && year % 100 != 0) => 29,
        2 => 28,
        _ => 0,
    }
}

fn parse_clock(value: &str) -> Result<i64, String> {
    let parts: Vec<_> = value.split(':').collect();
    if parts.len() != 2 && parts.len() != 3 {
        return Err("invalid_time".into());
    }
    let hour: i64 = parts[0].parse().map_err(|_| "invalid_time")?;
    let minute: i64 = parts[1].parse().map_err(|_| "invalid_time")?;
    let second: i64 = if parts.len() == 3 {
        parts[2].parse().map_err(|_| "invalid_time")?
    } else {
        0
    };
    if !(0..24).contains(&hour)
        || !(0..60).contains(&minute)
        || !(0..60).contains(&second)
    {
        return Err("invalid_time".into());
    }
    Ok(hour * 3600 + minute * 60 + second)
}

fn alternating_big_week(date: CivilDate, anchor: CivilDate, anchor_type: &WeekType) -> bool {
    let date_monday = date.add_days(-((date.weekday() - 1) as i64));
    let anchor_monday = anchor.add_days(-((anchor.weekday() - 1) as i64));
    let delta_weeks = (date_monday.serial() - anchor_monday.serial()).div_euclid(7);
    let anchor_big = matches!(anchor_type, WeekType::Big);
    if delta_weeks.rem_euclid(2) == 0 {
        anchor_big
    } else {
        !anchor_big
    }
}

fn base_rest_mode_day(date: CivilDate, schedule: &SalarySchedule) -> Result<DayKind, String> {
    let weekday = date.weekday();
    match schedule.rest_mode {
        RestMode::Double => Ok(if weekday <= 5 {
            DayKind::Workday
        } else {
            DayKind::RestDay
        }),
        RestMode::Single => Ok(if weekday <= 6 {
            DayKind::Workday
        } else {
            DayKind::RestDay
        }),
        RestMode::Alternating => {
            let anchor = schedule
                .alternating_anchor_date
                .as_deref()
                .ok_or("alternating_anchor_date_required")?;
            let week_type = schedule
                .alternating_anchor_week_type
                .as_ref()
                .ok_or("alternating_week_type_required")?;
            let is_big = alternating_big_week(date, CivilDate::parse(anchor)?, week_type);
            Ok(if weekday <= 5 || (weekday == 6 && is_big) {
                DayKind::Workday
            } else {
                DayKind::RestDay
            })
        }
    }
}

pub fn resolve_day(
    date: &str,
    schedule: &SalarySchedule,
    calendar: &CalendarData,
) -> Result<DayResolution, String> {
    if let Some(entry) = calendar
        .date_overrides
        .iter()
        .find(|entry| entry.date == date)
    {
        let kind = match entry.kind {
            DateOverrideKind::Workday => DayKind::Workday,
            DateOverrideKind::PaidRest | DateOverrideKind::UnpaidRest => DayKind::RestDay,
        };
        return Ok(DayResolution {
            kind,
            source: match entry.kind {
                DateOverrideKind::Workday => "manual_workday",
                DateOverrideKind::PaidRest => "manual_paid_rest",
                DateOverrideKind::UnpaidRest => "manual_unpaid_rest",
            }
            .into(),
            override_kind: Some(entry.kind.clone()),
        });
    }
    resolve_day_automatic(date, schedule, calendar)
}

pub fn resolve_day_automatic(
    date: &str,
    schedule: &SalarySchedule,
    calendar: &CalendarData,
) -> Result<DayResolution, String> {
    if calendar.adjusted_workdays.iter().any(|item| item == date) {
        return Ok(DayResolution {
            kind: DayKind::Workday,
            source: "adjusted_workday".into(),
            override_kind: None,
        });
    }
    if calendar.statutory_holidays.iter().any(|item| item == date) {
        return Ok(DayResolution {
            kind: DayKind::RestDay,
            source: "statutory_holiday".into(),
            override_kind: None,
        });
    }
    Ok(DayResolution {
        kind: base_rest_mode_day(CivilDate::parse(date)?, schedule)?,
        source: "rest_mode".into(),
        override_kind: None,
    })
}

pub fn apply_date_override(
    date: &str,
    kind: Option<DateOverrideKind>,
    schedule: &SalarySchedule,
    calendar: &CalendarData,
) -> Result<Option<DateOverride>, String> {
    CivilDate::parse(date)?;
    let Some(kind) = kind else {
        return Ok(None);
    };
    if matches!(
        kind,
        DateOverrideKind::PaidRest | DateOverrideKind::UnpaidRest
    ) && resolve_day_automatic(date, schedule, calendar)?.kind == DayKind::RestDay
    {
        return Err("date_override_leave_requires_workday".into());
    }
    Ok(Some(DateOverride {
        date: date.into(),
        kind,
        note: String::new(),
    }))
}

pub fn calculate_month(
    month: &str,
    schedule: &SalarySchedule,
    calendar: &CalendarData,
) -> Result<MonthSalary, String> {
    if schedule.monthly_salary_minor < 0 {
        return Err("invalid_monthly_salary".into());
    }
    if schedule.work_hours_per_day <= 0.0 {
        return Err("invalid_work_hours".into());
    }
    let start = CivilDate::parse(&format!("{month}-01"))?;
    let mut slot_days = Vec::new();
    let mut working_saturdays = vec![];
    for day in 1..=days_in_month(start.year, start.month) {
        let date = CivilDate { day, ..start };
        let date_key = date.format();
        let automatic = resolve_day_automatic(&date_key, schedule, calendar)?;
        let resolved = resolve_day(&date_key, schedule, calendar)?;
        let slot_kind = match resolved.override_kind {
            Some(DateOverrideKind::PaidRest) if automatic.kind == DayKind::Workday => {
                Some(SalarySlotKind::PaidRest)
            }
            Some(DateOverrideKind::UnpaidRest) if automatic.kind == DayKind::Workday => {
                Some(SalarySlotKind::UnpaidRest)
            }
            Some(DateOverrideKind::Workday) => Some(SalarySlotKind::Workday),
            None if automatic.kind == DayKind::Workday => Some(SalarySlotKind::Workday),
            _ => None,
        };
        if let Some(kind) = slot_kind {
            if kind == SalarySlotKind::Workday && date.weekday() == 6 {
                working_saturdays.push(date_key.clone());
            }
            slot_days.push((date_key, kind));
        }
    }
    let salary_slot_count = u32::try_from(slot_days.len()).map_err(|_| "salary.slot_overflow")?;
    if salary_slot_count == 0 {
        return Err("salary.zero_slots".into());
    }

    let mut salary_slots = Vec::with_capacity(slot_days.len());
    let mut workdays = 0_u32;
    let mut payable_salary_minor = 0_i64;
    for (offset, (date, kind)) in slot_days.into_iter().enumerate() {
        let index = u32::try_from(offset + 1).map_err(|_| "salary.slot_overflow")?;
        let target_minor = salary_slot_target(
            schedule.monthly_salary_minor,
            salary_slot_count,
            index,
        )?;
        let payable_minor = if kind == SalarySlotKind::UnpaidRest {
            0
        } else {
            target_minor
        };
        if kind == SalarySlotKind::Workday {
            workdays += 1;
        }
        payable_salary_minor = payable_salary_minor
            .checked_add(payable_minor)
            .ok_or("salary.amount_overflow")?;
        salary_slots.push(SalarySlot {
            date,
            index,
            kind,
            target_minor,
            payable_minor,
        });
    }

    let daily = round_ratio(
        i128::from(schedule.monthly_salary_minor),
        i128::from(salary_slot_count),
    )?;
    let work_seconds = (schedule.work_hours_per_day * 3600.0).round() as i64;
    if work_seconds <= 0 {
        return Err("invalid_work_hours".into());
    }
    let hourly = round_ratio(i128::from(daily) * 3600, i128::from(work_seconds))?;
    Ok(MonthSalary {
        workdays,
        salary_slot_count,
        daily_salary_minor: daily,
        hourly_salary_minor: hourly,
        payable_salary_minor,
        working_saturdays,
        salary_slots,
    })
}

fn round_ratio(numerator: i128, denominator: i128) -> Result<i64, String> {
    if denominator <= 0 || numerator < 0 {
        return Err("salary.invalid_ratio".into());
    }
    let rounded = numerator
        .checked_add(denominator / 2)
        .ok_or("salary.amount_overflow")?
        / denominator;
    i64::try_from(rounded).map_err(|_| "salary.amount_overflow".into())
}

pub fn salary_cumulative(
    monthly_salary_minor: i64,
    salary_slot_count: u32,
    completed_slots: u32,
) -> Result<i64, String> {
    if completed_slots > salary_slot_count {
        return Err("salary.slot_index_out_of_range".into());
    }
    if monthly_salary_minor < 0 {
        return Err("invalid_monthly_salary".into());
    }
    if salary_slot_count == 0 {
        return Err("salary.zero_slots".into());
    }
    round_ratio(
        i128::from(monthly_salary_minor) * i128::from(completed_slots),
        i128::from(salary_slot_count),
    )
}

pub fn salary_slot_target(
    monthly_salary_minor: i64,
    salary_slot_count: u32,
    salary_slot_index: u32,
) -> Result<i64, String> {
    if salary_slot_index == 0 || salary_slot_index > salary_slot_count {
        return Err("salary.slot_index_out_of_range".into());
    }
    Ok(
        salary_cumulative(
            monthly_salary_minor,
            salary_slot_count,
            salary_slot_index,
        )? - salary_cumulative(
            monthly_salary_minor,
            salary_slot_count,
            salary_slot_index - 1,
        )?,
    )
}

pub fn resolve_schedule_owner_date(
    now_date: &str,
    now_time: &str,
    schedule: &SalarySchedule,
) -> Result<String, String> {
    let current_date = CivilDate::parse(now_date)?;
    let now = parse_clock(now_time)?;
    let start = parse_clock(&schedule.work_start_time)?;
    let end = parse_clock(&schedule.work_end_time)?;
    if end <= start && now < end {
        Ok(current_date.add_days(-1).format())
    } else {
        Ok(current_date.format())
    }
}

fn completed_salary_for_previous_slots(
    month_salary: &MonthSalary,
    owner_date: &str,
) -> Result<i64, String> {
    month_salary
        .salary_slots
        .iter()
        .filter(|slot| slot.date.as_str() < owner_date)
        .try_fold(0_i64, |total, slot| {
            total
                .checked_add(slot.payable_minor)
                .ok_or_else(|| "salary.amount_overflow".into())
        })
}

fn current_slot<'a>(
    owner_date: &str,
    month_salary: &'a MonthSalary,
) -> Option<&'a SalarySlot> {
    month_salary
        .salary_slots
        .iter()
        .find(|slot| slot.date == owner_date)
}

fn today_earned_for_work_slot(
    monthly_salary_minor: i64,
    salary_slot_count: u32,
    salary_slot_index: u32,
    completed: i64,
    effective: i64,
) -> Result<i64, String> {
    let previous = salary_cumulative(
        monthly_salary_minor,
        salary_slot_count,
        salary_slot_index - 1,
    )?;
    let progress_numerator = i128::from(salary_slot_index - 1)
        .checked_mul(i128::from(effective))
        .and_then(|value| value.checked_add(i128::from(completed)))
        .ok_or("salary.amount_overflow")?;
    let progress_denominator = i128::from(salary_slot_count)
        .checked_mul(i128::from(effective))
        .ok_or("salary.amount_overflow")?;
    let cumulative = round_ratio(
        i128::from(monthly_salary_minor)
            .checked_mul(progress_numerator)
            .ok_or("salary.amount_overflow")?,
        progress_denominator,
    )?;
    Ok(cumulative - previous)
}

pub fn calculate_today(
    owner_date: &str,
    now_date: &str,
    now_time: &str,
    schedule: &SalarySchedule,
    month_salary: &MonthSalary,
    calendar: &CalendarData,
) -> Result<TodaySnapshot, String> {
    let resolved_owner_date = resolve_schedule_owner_date(now_date, now_time, schedule)?;
    if owner_date != resolved_owner_date {
        return Err("schedule.owner_date_mismatch".into());
    }
    let owner = CivilDate::parse(owner_date)?;
    let resolution = resolve_day(owner_date, schedule, calendar)?;
    let slot = current_slot(owner_date, month_salary);
    let salary_slot_index = slot.map(|item| item.index);
    let daily_target_minor = slot.map(|item| item.target_minor).unwrap_or(0);
    let previous_month_earned = completed_salary_for_previous_slots(month_salary, owner_date)?;

    if let Some(kind) = resolution.override_kind {
        if matches!(kind, DateOverrideKind::PaidRest | DateOverrideKind::UnpaidRest) {
            let paid = kind == DateOverrideKind::PaidRest;
            let earned_minor = if paid { daily_target_minor } else { 0 };
            let month_earned_minor = previous_month_earned
                .checked_add(earned_minor)
                .ok_or("salary.amount_overflow")?;
            return Ok(TodaySnapshot {
                state: if paid { "paid_rest" } else { "unpaid_rest" }.into(),
                schedule_owner_date: owner_date.into(),
                algorithm_version: "salary-v101-cumulative-v1".into(),
                monthly_salary_minor: schedule.monthly_salary_minor,
                effective_work_seconds: 0,
                completed_work_seconds: 0,
                earned_minor,
                daily_target_minor,
                hourly_salary_minor: 0,
                month_earned_minor,
                payable_salary_minor: month_salary.payable_salary_minor,
                salary_slot_index,
                salary_slot_count: month_salary.salary_slot_count,
                next_boundary_seconds: None,
                progress: 0.0,
            });
        }
    }
    if resolution.kind == DayKind::RestDay {
        return Ok(TodaySnapshot {
            state: "rest_day".into(),
            schedule_owner_date: owner_date.into(),
            algorithm_version: "salary-v101-cumulative-v1".into(),
            monthly_salary_minor: schedule.monthly_salary_minor,
            effective_work_seconds: 0,
            completed_work_seconds: 0,
            earned_minor: 0,
            daily_target_minor: 0,
            hourly_salary_minor: 0,
            month_earned_minor: previous_month_earned,
            payable_salary_minor: month_salary.payable_salary_minor,
            salary_slot_index: None,
            salary_slot_count: month_salary.salary_slot_count,
            next_boundary_seconds: None,
            progress: 0.0,
        });
    }
    let slot = slot.ok_or("salary.owner_slot_missing")?;
    if slot.kind != SalarySlotKind::Workday {
        return Err("salary.owner_slot_kind_mismatch".into());
    }

    let current_date = CivilDate::parse(now_date)?;
    let start = parse_clock(&schedule.work_start_time)?;
    let mut end = parse_clock(&schedule.work_end_time)?;
    let mut lunch_start = parse_clock(&schedule.lunch_start_time)?;
    let mut lunch_end = parse_clock(&schedule.lunch_end_time)?;
    let overnight = end <= start;
    if overnight {
        end += 86400;
        if lunch_start < start {
            lunch_start += 86400;
        }
        if lunch_end <= start {
            lunch_end += 86400;
        }
    }
    if lunch_end < lunch_start || lunch_start < start || lunch_end > end {
        return Err("invalid_lunch_interval".into());
    }
    let day_offset = current_date.serial() - owner.serial();
    let now = day_offset * 86400 + parse_clock(now_time)?;
    let effective = (end - start) - (lunch_end - lunch_start);
    if effective <= 0 {
        return Err("invalid_work_interval".into());
    }
    let completed =
        interval_elapsed(now, start, lunch_start) + interval_elapsed(now, lunch_end, end);
    let completed = completed.clamp(0, effective);
    let state = if now < start {
        "before_work"
    } else if now < lunch_start {
        "working"
    } else if now < lunch_end {
        "lunch"
    } else if now < end {
        "working"
    } else {
        "after_work"
    };
    let next_boundary_seconds = match state {
        "before_work" => Some(start - now),
        "working" if lunch_end > lunch_start && now < lunch_start => Some(lunch_start - now),
        "working" => Some(end - now),
        "lunch" => Some(lunch_end - now),
        _ => None,
    }
    .map(|seconds| seconds.max(0));
    let progress = completed as f64 / effective as f64;
    let earned_minor = today_earned_for_work_slot(
        schedule.monthly_salary_minor,
        month_salary.salary_slot_count,
        slot.index,
        completed,
        effective,
    )?;
    let month_earned_minor = previous_month_earned
        .checked_add(earned_minor)
        .ok_or("salary.amount_overflow")?;
    let hourly_salary_minor =
        round_ratio(i128::from(slot.target_minor) * 3600, i128::from(effective))?;
    Ok(TodaySnapshot {
        state: state.into(),
        schedule_owner_date: owner_date.into(),
        algorithm_version: "salary-v101-cumulative-v1".into(),
        monthly_salary_minor: schedule.monthly_salary_minor,
        effective_work_seconds: effective,
        completed_work_seconds: completed,
        earned_minor,
        daily_target_minor: slot.target_minor,
        hourly_salary_minor,
        month_earned_minor,
        payable_salary_minor: month_salary.payable_salary_minor,
        salary_slot_index,
        salary_slot_count: month_salary.salary_slot_count,
        next_boundary_seconds,
        progress,
    })
}

/*
 * Salary calculation before v1.0.1 divided the monthly amount once and multiplied
 * the rounded daily value back across the month. Keep the implementation above
 * as the only path so every slot is derived from adjacent cumulative totals.
 */

pub fn resolve_month_days(
    month: &str,
    schedule: &SalarySchedule,
    calendar: &CalendarData,
) -> Result<Vec<CalendarDay>, String> {
    let start = CivilDate::parse(&format!("{month}-01"))?;
    (1..=days_in_month(start.year, start.month))
        .map(|day| {
            let date = CivilDate { day, ..start }.format();
            let automatic = resolve_day_automatic(&date, schedule, calendar)?;
            let resolution = resolve_day(&date, schedule, calendar)?;
            Ok(CalendarDay {
                date,
                kind: resolution.kind,
                source: resolution.source,
                automatic_kind: automatic.kind,
                automatic_source: automatic.source,
                override_kind: resolution.override_kind,
            })
        })
        .collect()
}

pub fn next_workday(
    after_date: &str,
    schedule: &SalarySchedule,
    calendar: &CalendarData,
) -> Result<Option<String>, String> {
    let start = CivilDate::parse(after_date)?;
    for offset in 1..=62 {
        let date = start.add_days(offset).format();
        if resolve_day(&date, schedule, calendar)?.kind == DayKind::Workday {
            return Ok(Some(date));
        }
    }
    Ok(None)
}

fn interval_elapsed(now: i64, start: i64, end: i64) -> i64 {
    if now <= start {
        0
    } else if now >= end {
        end - start
    } else {
        now - start
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    fn schedule(mode: RestMode) -> SalarySchedule {
        SalarySchedule {
            monthly_salary_minor: 1_000_000,
            rest_mode: mode,
            alternating_anchor_date: None,
            alternating_anchor_week_type: None,
            work_hours_per_day: 8.0,
            work_start_time: "08:00".into(),
            work_end_time: "18:00".into(),
            lunch_start_time: "12:00".into(),
            lunch_end_time: "14:00".into(),
        }
    }

    #[test]
    fn fixture_salary_modes_match() {
        let calendar = CalendarData::default();
        assert_eq!(
            calculate_month("2026-02", &schedule(RestMode::Double), &calendar)
                .unwrap()
                .workdays,
            20
        );
        assert_eq!(
            calculate_month("2026-02", &schedule(RestMode::Single), &calendar)
                .unwrap()
                .workdays,
            24
        );
        let mut alternating = schedule(RestMode::Alternating);
        alternating.alternating_anchor_date = Some("2026-02-02".into());
        alternating.alternating_anchor_week_type = Some(WeekType::Big);
        let result = calculate_month("2026-02", &alternating, &calendar).unwrap();
        assert_eq!(result.workdays, 22);
        assert_eq!(result.working_saturdays, ["2026-02-07", "2026-02-21"]);
    }

    #[test]
    fn july_2026_workday_preview_changes_with_rest_mode() {
        let calendar = CalendarData::default();
        assert_eq!(
            calculate_month("2026-07", &schedule(RestMode::Double), &calendar)
                .unwrap()
                .workdays,
            23
        );
        assert_eq!(
            calculate_month("2026-07", &schedule(RestMode::Single), &calendar)
                .unwrap()
                .workdays,
            27
        );
        let mut alternating = schedule(RestMode::Alternating);
        alternating.alternating_anchor_date = Some("2026-07-26".into());
        alternating.alternating_anchor_week_type = Some(WeekType::Small);
        assert_eq!(
            calculate_month("2026-07", &alternating, &calendar)
                .unwrap()
                .workdays,
            25
        );
    }

    #[test]
    fn alternating_requires_explicit_week_type() {
        let mut alternating = schedule(RestMode::Alternating);
        alternating.alternating_anchor_date = Some("2026-02-02".into());
        assert_eq!(
            calculate_month("2026-02", &alternating, &CalendarData::default()).unwrap_err(),
            "alternating_week_type_required"
        );
    }

    #[test]
    fn lunch_freezes_income_and_night_shift_uses_start_date() {
        let standard = schedule(RestMode::Double);
        let month = calculate_month("2026-02", &standard, &CalendarData::default()).unwrap();
        let snapshot = calculate_today(
            "2026-02-02",
            "2026-02-02",
            "13:00",
            &standard,
            &month,
            &CalendarData::default(),
        )
        .unwrap();
        assert_eq!(snapshot.state, "lunch");
        assert_eq!(snapshot.completed_work_seconds, 14_400);
        assert_eq!(snapshot.earned_minor, 25_000);

        let mut night = standard;
        night.work_start_time = "22:00".into();
        night.work_end_time = "08:00".into();
        night.lunch_start_time = "02:00".into();
        night.lunch_end_time = "04:00".into();
        let month = calculate_month("2026-02", &night, &CalendarData::default()).unwrap();
        let snapshot = calculate_today(
            "2026-02-02",
            "2026-02-03",
            "03:00",
            &night,
            &month,
            &CalendarData::default(),
        )
        .unwrap();
        assert_eq!(snapshot.state, "lunch");
        assert_eq!(snapshot.effective_work_seconds, 28_800);
    }

    #[test]
    fn zero_lunch_duration_is_a_valid_continuous_workday() {
        let mut no_lunch = schedule(RestMode::Double);
        no_lunch.work_start_time = "09:30".into();
        no_lunch.work_end_time = "17:30".into();
        no_lunch.lunch_start_time = "12:00".into();
        no_lunch.lunch_end_time = "12:00".into();
        let month =
            calculate_month("2026-07", &no_lunch, &CalendarData::default()).unwrap();

        let snapshot = calculate_today(
            "2026-07-27",
            "2026-07-27",
            "13:30",
            &no_lunch,
            &month,
            &CalendarData::default(),
        )
        .unwrap();

        assert_eq!(snapshot.state, "working");
        assert_eq!(snapshot.effective_work_seconds, 28_800);
        assert_eq!(snapshot.completed_work_seconds, 14_400);
        assert_eq!(snapshot.progress, 0.5);
    }

    #[test]
    fn calendar_priority_is_stable() {
        let standard = schedule(RestMode::Double);
        let calendar = CalendarData {
            statutory_holidays: vec!["2026-10-01".into()],
            adjusted_workdays: vec![],
            date_overrides: vec![DateOverride {
                date: "2026-10-01".into(),
                kind: DateOverrideKind::Workday,
                note: String::new(),
            }],
        };
        assert_eq!(
            resolve_day("2026-10-01", &standard, &calendar)
                .unwrap()
                .source,
            "manual_workday"
        );
    }

    #[test]
    fn month_days_and_next_workday_share_resolution_rules() {
        let standard = schedule(RestMode::Double);
        let days = resolve_month_days("2026-07", &standard, &CalendarData::default()).unwrap();
        assert_eq!(days.len(), 31);
        assert_eq!(days[23].date, "2026-07-24");
        assert_eq!(days[23].kind, DayKind::Workday);
        assert_eq!(days[25].date, "2026-07-26");
        assert_eq!(days[25].kind, DayKind::RestDay);
        assert_eq!(
            next_workday("2026-07-26", &standard, &CalendarData::default()).unwrap(),
            Some("2026-07-27".into())
        );
    }

    #[test]
    fn paid_and_unpaid_rest_are_distinct_manual_results() {
        let standard = schedule(RestMode::Double);
        let paid = CalendarData {
            date_overrides: vec![DateOverride {
                date: "2026-07-24".into(),
                kind: DateOverrideKind::PaidRest,
                note: String::new(),
            }],
            ..CalendarData::default()
        };
        let unpaid = CalendarData {
            date_overrides: vec![DateOverride {
                date: "2026-07-24".into(),
                kind: DateOverrideKind::UnpaidRest,
                note: String::new(),
            }],
            ..CalendarData::default()
        };

        assert_eq!(
            resolve_day("2026-07-24", &standard, &paid)
                .unwrap()
                .override_kind,
            Some(DateOverrideKind::PaidRest)
        );
        assert_eq!(
            resolve_day("2026-07-24", &standard, &unpaid)
                .unwrap()
                .override_kind,
            Some(DateOverrideKind::UnpaidRest)
        );
    }

    #[test]
    fn leave_options_are_rejected_on_automatic_rest_days() {
        let standard = schedule(RestMode::Double);
        let calendar = CalendarData::default();

        assert_eq!(
            apply_date_override(
                "2026-07-26",
                Some(DateOverrideKind::PaidRest),
                &standard,
                &calendar,
            )
            .unwrap_err(),
            "date_override_leave_requires_workday"
        );
    }

    #[test]
    fn overnight_owner_date_changes_at_shift_end() {
        let mut night = schedule(RestMode::Double);
        night.work_start_time = "22:00".into();
        night.work_end_time = "06:00".into();
        night.lunch_start_time = "02:00".into();
        night.lunch_end_time = "02:00".into();

        assert_eq!(
            resolve_schedule_owner_date("2026-07-28", "01:00:00", &night).unwrap(),
            "2026-07-27"
        );
        assert_eq!(
            resolve_schedule_owner_date("2026-07-28", "05:59:59", &night).unwrap(),
            "2026-07-27"
        );
        assert_eq!(
            resolve_schedule_owner_date("2026-07-28", "06:00:00", &night).unwrap(),
            "2026-07-28"
        );
        assert_eq!(
            resolve_schedule_owner_date("2026-07-28", "21:59:59", &night).unwrap(),
            "2026-07-28"
        );
    }

    #[test]
    fn adjacent_cumulative_slots_conserve_every_cent() {
        for salary in [0, 1, 99, 100, 1_000_001, 99_999_999] {
            for slots in 1..=31 {
                let distributed: i64 = (1..=slots)
                    .map(|index| salary_slot_target(salary, slots, index).unwrap())
                    .sum();
                assert_eq!(distributed, salary);
                assert_eq!(
                    salary_cumulative(salary, slots, slots).unwrap(),
                    salary
                );
            }
        }
    }

    #[test]
    fn paid_and_unpaid_rest_keep_slot_but_change_workdays_and_payable_amount() {
        let mut standard = schedule(RestMode::Double);
        standard.monthly_salary_minor = 1_000_001;
        let baseline = calculate_month("2026-07", &standard, &CalendarData::default()).unwrap();
        let target_date = "2026-07-24";
        let baseline_slot = baseline
            .salary_slots
            .iter()
            .find(|slot| slot.date == target_date)
            .unwrap()
            .clone();

        let paid_calendar = CalendarData {
            date_overrides: vec![DateOverride {
                date: target_date.into(),
                kind: DateOverrideKind::PaidRest,
                note: String::new(),
            }],
            ..CalendarData::default()
        };
        let paid = calculate_month("2026-07", &standard, &paid_calendar).unwrap();
        let paid_slot = paid
            .salary_slots
            .iter()
            .find(|slot| slot.date == target_date)
            .unwrap();
        assert_eq!(paid.salary_slot_count, baseline.salary_slot_count);
        assert_eq!(paid.workdays, baseline.workdays - 1);
        assert_eq!(paid_slot.kind, SalarySlotKind::PaidRest);
        assert_eq!(paid_slot.target_minor, baseline_slot.target_minor);
        assert_eq!(paid.payable_salary_minor, standard.monthly_salary_minor);

        let unpaid_calendar = CalendarData {
            date_overrides: vec![DateOverride {
                date: target_date.into(),
                kind: DateOverrideKind::UnpaidRest,
                note: String::new(),
            }],
            ..CalendarData::default()
        };
        let unpaid = calculate_month("2026-07", &standard, &unpaid_calendar).unwrap();
        let unpaid_slot = unpaid
            .salary_slots
            .iter()
            .find(|slot| slot.date == target_date)
            .unwrap();
        assert_eq!(unpaid.salary_slot_count, baseline.salary_slot_count);
        assert_eq!(unpaid.workdays, baseline.workdays - 1);
        assert_eq!(unpaid_slot.kind, SalarySlotKind::UnpaidRest);
        assert_eq!(unpaid_slot.payable_minor, 0);
        assert_eq!(
            unpaid.payable_salary_minor,
            standard.monthly_salary_minor - baseline_slot.target_minor
        );
    }

    #[test]
    fn manual_workday_on_automatic_rest_adds_a_salary_slot() {
        let mut standard = schedule(RestMode::Double);
        standard.monthly_salary_minor = 1_000_001;
        let baseline = calculate_month("2026-07", &standard, &CalendarData::default()).unwrap();
        let calendar = CalendarData {
            date_overrides: vec![DateOverride {
                date: "2026-07-26".into(),
                kind: DateOverrideKind::Workday,
                note: String::new(),
            }],
            ..CalendarData::default()
        };
        let adjusted = calculate_month("2026-07", &standard, &calendar).unwrap();

        assert_eq!(adjusted.salary_slot_count, baseline.salary_slot_count + 1);
        assert_eq!(adjusted.workdays, baseline.workdays + 1);
        assert_eq!(
            adjusted
                .salary_slots
                .iter()
                .map(|slot| slot.target_minor)
                .sum::<i64>(),
            standard.monthly_salary_minor
        );
    }

    #[test]
    fn paid_and_unpaid_today_states_use_the_salary_slot_contract() {
        let standard = schedule(RestMode::Double);
        let paid_calendar = CalendarData {
            date_overrides: vec![DateOverride {
                date: "2026-07-24".into(),
                kind: DateOverrideKind::PaidRest,
                note: String::new(),
            }],
            ..CalendarData::default()
        };
        let paid_month = calculate_month("2026-07", &standard, &paid_calendar).unwrap();
        let paid = calculate_today(
            "2026-07-24",
            "2026-07-24",
            "12:00:00",
            &standard,
            &paid_month,
            &paid_calendar,
        )
        .unwrap();
        assert_eq!(paid.state, "paid_rest");
        assert_eq!(paid.effective_work_seconds, 0);
        assert_eq!(paid.earned_minor, paid.daily_target_minor);

        let unpaid_calendar = CalendarData {
            date_overrides: vec![DateOverride {
                date: "2026-07-24".into(),
                kind: DateOverrideKind::UnpaidRest,
                note: String::new(),
            }],
            ..CalendarData::default()
        };
        let unpaid_month = calculate_month("2026-07", &standard, &unpaid_calendar).unwrap();
        let unpaid = calculate_today(
            "2026-07-24",
            "2026-07-24",
            "12:00:00",
            &standard,
            &unpaid_month,
            &unpaid_calendar,
        )
        .unwrap();
        assert_eq!(unpaid.state, "unpaid_rest");
        assert_eq!(unpaid.effective_work_seconds, 0);
        assert_eq!(unpaid.earned_minor, 0);
        assert!(unpaid.payable_salary_minor < standard.monthly_salary_minor);
    }

    #[test]
    fn month_without_salary_slots_has_a_readable_error() {
        let standard = schedule(RestMode::Double);
        let mut calendar = CalendarData::default();
        for day in 1..=28 {
            calendar
                .statutory_holidays
                .push(format!("2026-02-{day:02}"));
        }
        assert_eq!(
            calculate_month("2026-02", &standard, &calendar).unwrap_err(),
            "salary.zero_slots"
        );
    }
}
