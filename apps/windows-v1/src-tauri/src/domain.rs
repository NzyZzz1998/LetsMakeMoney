use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
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
    pub kind: DayKind,
    #[serde(default)]
    pub note: String,
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
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct CalendarDay {
    pub date: String,
    pub kind: DayKind,
    pub source: String,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct MonthSalary {
    pub workdays: u32,
    pub daily_salary_minor: i64,
    pub hourly_salary_minor: i64,
    pub working_saturdays: Vec<String>,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct TodaySnapshot {
    pub state: String,
    pub schedule_owner_date: String,
    pub effective_work_seconds: i64,
    pub completed_work_seconds: i64,
    pub earned_minor: i64,
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
    if parts.len() != 2 {
        return Err("invalid_time".into());
    }
    let hour: i64 = parts[0].parse().map_err(|_| "invalid_time")?;
    let minute: i64 = parts[1].parse().map_err(|_| "invalid_time")?;
    if !(0..24).contains(&hour) || !(0..60).contains(&minute) {
        return Err("invalid_time".into());
    }
    Ok(hour * 3600 + minute * 60)
}

fn alternating_big_week(
    date: CivilDate,
    anchor: CivilDate,
    anchor_type: &WeekType,
) -> bool {
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

fn base_rest_mode_day(
    date: CivilDate,
    schedule: &SalarySchedule,
) -> Result<DayKind, String> {
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
    if let Some(entry) = calendar.date_overrides.iter().find(|entry| entry.date == date) {
        return Ok(DayResolution {
            kind: entry.kind.clone(),
            source: "manual_override".into(),
        });
    }
    if calendar.adjusted_workdays.iter().any(|item| item == date) {
        return Ok(DayResolution {
            kind: DayKind::Workday,
            source: "adjusted_workday".into(),
        });
    }
    if calendar.statutory_holidays.iter().any(|item| item == date) {
        return Ok(DayResolution {
            kind: DayKind::RestDay,
            source: "statutory_holiday".into(),
        });
    }
    Ok(DayResolution {
        kind: base_rest_mode_day(CivilDate::parse(date)?, schedule)?,
        source: "rest_mode".into(),
    })
}

pub fn calculate_month(
    month: &str,
    schedule: &SalarySchedule,
    calendar: &CalendarData,
) -> Result<MonthSalary, String> {
    let start = CivilDate::parse(&format!("{month}-01"))?;
    let mut workdays = 0;
    let mut working_saturdays = vec![];
    for day in 1..=days_in_month(start.year, start.month) {
        let date = CivilDate { day, ..start };
        if resolve_day(&date.format(), schedule, calendar)?.kind == DayKind::Workday {
            workdays += 1;
            if date.weekday() == 6 {
                working_saturdays.push(date.format());
            }
        }
    }
    if workdays == 0 || schedule.work_hours_per_day <= 0.0 {
        return Err("invalid_salary_denominator".into());
    }
    let daily = schedule.monthly_salary_minor / i64::from(workdays);
    let hourly = (daily as f64 / schedule.work_hours_per_day).round() as i64;
    Ok(MonthSalary {
        workdays,
        daily_salary_minor: daily,
        hourly_salary_minor: hourly,
        working_saturdays,
    })
}

pub fn resolve_month_days(
    month: &str,
    schedule: &SalarySchedule,
    calendar: &CalendarData,
) -> Result<Vec<CalendarDay>, String> {
    let start = CivilDate::parse(&format!("{month}-01"))?;
    (1..=days_in_month(start.year, start.month))
        .map(|day| {
            let date = CivilDate { day, ..start }.format();
            let resolution = resolve_day(&date, schedule, calendar)?;
            Ok(CalendarDay {
                date,
                kind: resolution.kind,
                source: resolution.source,
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

pub fn calculate_today(
    owner_date: &str,
    now_date: &str,
    now_time: &str,
    schedule: &SalarySchedule,
    daily_salary_minor: i64,
    calendar: &CalendarData,
) -> Result<TodaySnapshot, String> {
    let owner = CivilDate::parse(owner_date)?;
    if resolve_day(owner_date, schedule, calendar)?.kind == DayKind::RestDay {
        return Ok(TodaySnapshot {
            state: "rest_day".into(),
            schedule_owner_date: owner_date.into(),
            effective_work_seconds: (schedule.work_hours_per_day * 3600.0) as i64,
            completed_work_seconds: 0,
            earned_minor: 0,
            progress: 0.0,
        });
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
    let completed = interval_elapsed(now, start, lunch_start)
        + interval_elapsed(now, lunch_end, end);
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
    let progress = completed as f64 / effective as f64;
    Ok(TodaySnapshot {
        state: state.into(),
        schedule_owner_date: owner_date.into(),
        effective_work_seconds: effective,
        completed_work_seconds: completed,
        earned_minor: (daily_salary_minor as f64 * progress).round() as i64,
        progress,
    })
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
        assert_eq!(calculate_month("2026-02", &schedule(RestMode::Double), &calendar).unwrap().workdays, 20);
        assert_eq!(calculate_month("2026-02", &schedule(RestMode::Single), &calendar).unwrap().workdays, 24);
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
        let snapshot = calculate_today(
            "2026-02-02",
            "2026-02-02",
            "13:00",
            &standard,
            50_000,
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
        let snapshot = calculate_today(
            "2026-02-02",
            "2026-02-03",
            "03:00",
            &night,
            50_000,
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

        let snapshot = calculate_today(
            "2026-07-27",
            "2026-07-27",
            "13:30",
            &no_lunch,
            50_000,
            &CalendarData::default(),
        )
        .unwrap();

        assert_eq!(snapshot.state, "working");
        assert_eq!(snapshot.effective_work_seconds, 28_800);
        assert_eq!(snapshot.completed_work_seconds, 14_400);
        assert_eq!(snapshot.earned_minor, 25_000);
    }

    #[test]
    fn calendar_priority_is_stable() {
        let standard = schedule(RestMode::Double);
        let calendar = CalendarData {
            statutory_holidays: vec!["2026-10-01".into()],
            adjusted_workdays: vec![],
            date_overrides: vec![DateOverride {
                date: "2026-10-01".into(),
                kind: DayKind::Workday,
                note: String::new(),
            }],
        };
        assert_eq!(
            resolve_day("2026-10-01", &standard, &calendar).unwrap().source,
            "manual_override"
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
}
