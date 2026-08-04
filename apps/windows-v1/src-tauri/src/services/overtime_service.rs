use std::sync::Mutex;

use time::{
    format_description, format_description::well_known::Rfc3339, Date, Duration, OffsetDateTime,
};

use crate::domain::{self, DayKind};
use crate::models::overtime::{
    now_rfc3339, validate_business_date, OvertimeBoundaryBasis, OvertimeBoundaryResolution,
    OvertimeBoundarySnapshot, OvertimeMutationResponse, OvertimeMutationStatus, OvertimeOrigin,
    OvertimeReadResponse, OvertimeReadStatus, OvertimeRecord, OvertimeStoreError,
    ResolveOvertimeBoundaryRequest, SaveOvertimeRequest, OVERTIME_MAX_MINUTES,
    OVERTIME_SCHEMA_VERSION,
};
use crate::repositories::overtime_repository::OvertimeRepository;

pub struct OvertimeRuntime(pub Mutex<()>);

impl Default for OvertimeRuntime {
    fn default() -> Self {
        Self(Mutex::new(()))
    }
}

pub struct OvertimeService;

impl OvertimeService {
    pub fn resolve_boundary(
        request: &ResolveOvertimeBoundaryRequest,
    ) -> Result<OvertimeBoundaryResolution, OvertimeStoreError> {
        validate_business_date(&request.business_date)?;
        if !(-840..=840).contains(&request.utc_offset_minutes) {
            return Err(OvertimeStoreError::new(
                "overtime_timezone_invalid",
                "时区偏移无效",
            ));
        }
        let resolved =
            domain::resolve_day(&request.business_date, &request.schedule, &request.calendar)
                .map_err(|error| OvertimeStoreError::new("overtime_boundary_failed", error))?;
        if resolved.kind == DayKind::RestDay {
            return Ok(OvertimeBoundaryResolution {
                snapshot: OvertimeBoundarySnapshot {
                    basis: OvertimeBoundaryBasis::RestDayCap,
                    current_shift_end: None,
                    next_actual_work_start: None,
                    maximum_minutes: OVERTIME_MAX_MINUTES,
                    calendar_source: request.calendar_source,
                },
                suggested_minutes: None,
                origin: OvertimeOrigin::Independent,
                linked_override_date: None,
                day_source: resolved.source,
            });
        }

        let shift_crosses_midnight =
            request.schedule.work_end_time <= request.schedule.work_start_time;
        let shift_end_date = if shift_crosses_midnight {
            add_days(&request.business_date, 1)?
        } else {
            request.business_date.clone()
        };
        let next_work_date =
            domain::next_workday(&request.business_date, &request.schedule, &request.calendar)
                .map_err(|error| OvertimeStoreError::new("overtime_boundary_failed", error))?
                .ok_or_else(|| {
                    OvertimeStoreError::new(
                        "overtime_next_workday_unavailable",
                        "无法解析下一次真实开工日期",
                    )
                })?;
        let current_shift_end = timestamp(
            &shift_end_date,
            &request.schedule.work_end_time,
            request.utc_offset_minutes,
        )?;
        let next_actual_work_start = timestamp(
            &next_work_date,
            &request.schedule.work_start_time,
            request.utc_offset_minutes,
        )?;
        let gap_minutes = (next_actual_work_start - current_shift_end).whole_minutes();
        if gap_minutes <= 0 {
            return Err(OvertimeStoreError::new(
                "overtime_boundary_non_positive",
                "本次下班到下一次开工之间没有可录入时长",
            ));
        }
        let maximum_minutes = gap_minutes.min(i64::from(OVERTIME_MAX_MINUTES)) as u16;
        let automatic = domain::resolve_day_automatic(
            &request.business_date,
            &request.schedule,
            &request.calendar,
        )
        .map_err(|error| OvertimeStoreError::new("overtime_boundary_failed", error))?;
        let manual_weekend = resolved.source == "manual_workday"
            && automatic.kind == DayKind::RestDay
            && is_weekend(&request.business_date)?;
        let origin = if manual_weekend {
            OvertimeOrigin::ManualWeekendWork
        } else {
            OvertimeOrigin::Independent
        };

        Ok(OvertimeBoundaryResolution {
            snapshot: OvertimeBoundarySnapshot {
                basis: OvertimeBoundaryBasis::PlannedShiftGap,
                current_shift_end: Some(current_shift_end.format(&Rfc3339).map_err(|error| {
                    OvertimeStoreError::new("overtime_boundary_failed", error.to_string())
                })?),
                next_actual_work_start: Some(next_actual_work_start.format(&Rfc3339).map_err(
                    |error| OvertimeStoreError::new("overtime_boundary_failed", error.to_string()),
                )?),
                maximum_minutes,
                calendar_source: request.calendar_source,
            },
            suggested_minutes: manual_weekend.then_some(480.min(maximum_minutes)),
            origin,
            linked_override_date: manual_weekend.then(|| request.business_date.clone()),
            day_source: resolved.source,
        })
    }

    pub fn read_record(
        repository: &impl OvertimeRepository,
        business_date: &str,
    ) -> OvertimeReadResponse {
        if let Err(error) = validate_business_date(business_date) {
            return read_failure(error);
        }
        match repository.load() {
            Ok(store) => {
                let records = store
                    .records
                    .into_iter()
                    .filter(|record| record.business_date == business_date)
                    .collect::<Vec<_>>();
                let status = if records.is_empty() {
                    OvertimeReadStatus::Empty
                } else {
                    OvertimeReadStatus::Ready
                };
                OvertimeReadResponse {
                    status,
                    schema_version: OVERTIME_SCHEMA_VERSION,
                    records,
                    error_code: None,
                    message: "加班记录已读取".into(),
                    recovery_available: false,
                }
            }
            Err(error) => read_failure(error),
        }
    }

    pub fn read_month(repository: &impl OvertimeRepository, month: &str) -> OvertimeReadResponse {
        if !valid_month(month) {
            return read_failure(OvertimeStoreError::new(
                "overtime_month_invalid",
                "月份格式无效",
            ));
        }
        match repository.load() {
            Ok(store) => {
                let mut records = store
                    .records
                    .into_iter()
                    .filter(|record| record.business_date.starts_with(month))
                    .collect::<Vec<_>>();
                records.sort_by(|left, right| left.business_date.cmp(&right.business_date));
                let status = if records.is_empty() {
                    OvertimeReadStatus::Empty
                } else {
                    OvertimeReadStatus::Ready
                };
                OvertimeReadResponse {
                    status,
                    schema_version: OVERTIME_SCHEMA_VERSION,
                    records,
                    error_code: None,
                    message: "月度加班记录已读取".into(),
                    recovery_available: false,
                }
            }
            Err(error) => read_failure(error),
        }
    }

    pub fn save_record(
        repository: &impl OvertimeRepository,
        request: SaveOvertimeRequest,
    ) -> OvertimeMutationResponse {
        if let Err(error) = validate_business_date(&request.business_date) {
            return mutation_failure(error);
        }
        if request.minutes > OVERTIME_MAX_MINUTES {
            return mutation_failure(OvertimeStoreError::new(
                "overtime_minutes_out_of_range",
                "加班时长不能超过 24 小时",
            ));
        }
        if request.hourly_rate_fen_snapshot < 0 {
            return mutation_failure(OvertimeStoreError::new(
                "overtime_rate_invalid",
                "当前时薪快照无效",
            ));
        }
        if request.minutes == 0 {
            return Self::delete_record(repository, &request.business_date);
        }
        let boundary = match request.boundary_snapshot.as_ref() {
            Some(boundary) => boundary,
            None => {
                return mutation_failure(OvertimeStoreError::new(
                    "overtime_boundary_required",
                    "保存前必须重新计算本次加班上限",
                ))
            }
        };
        if request.minutes > boundary.maximum_minutes {
            return mutation_failure(OvertimeStoreError::new(
                "overtime_minutes_exceed_boundary",
                format!("加班时长不能超过本次上限 {} 分钟", boundary.maximum_minutes),
            ));
        }
        let mut store = match repository.load() {
            Ok(store) => store,
            Err(error) => return mutation_failure(error),
        };
        let now = match now_rfc3339() {
            Ok(now) => now,
            Err(error) => return mutation_failure(error),
        };
        let record = if let Some(existing) = store
            .records
            .iter_mut()
            .find(|record| record.business_date == request.business_date)
        {
            if existing.minutes == request.minutes
                && existing.origin == request.origin
                && existing.boundary_snapshot == request.boundary_snapshot
                && existing.linked_override_date == request.linked_override_date
            {
                return OvertimeMutationResponse {
                    status: OvertimeMutationStatus::Unchanged,
                    schema_version: OVERTIME_SCHEMA_VERSION,
                    record: Some(existing.clone()),
                    error_code: None,
                    message: "加班记录没有变化".into(),
                    recovery_available: false,
                };
            }
            existing.minutes = request.minutes;
            existing.origin = request.origin;
            existing.boundary_snapshot = request.boundary_snapshot;
            existing.linked_override_date = request.linked_override_date;
            existing.updated_at = now;
            existing.clone()
        } else {
            let record = OvertimeRecord {
                business_date: request.business_date,
                minutes: request.minutes,
                hourly_rate_fen_snapshot: request.hourly_rate_fen_snapshot,
                origin: request.origin,
                boundary_snapshot: request.boundary_snapshot,
                linked_override_date: request.linked_override_date,
                created_at: now.clone(),
                updated_at: now,
            };
            store.records.push(record.clone());
            record
        };
        store
            .records
            .sort_by(|left, right| left.business_date.cmp(&right.business_date));
        match repository.save(&store) {
            Ok(()) => OvertimeMutationResponse {
                status: OvertimeMutationStatus::Saved,
                schema_version: OVERTIME_SCHEMA_VERSION,
                record: Some(record),
                error_code: None,
                message: "加班记录已保存".into(),
                recovery_available: false,
            },
            Err(error) => mutation_failure(error),
        }
    }

    pub fn delete_record(
        repository: &impl OvertimeRepository,
        business_date: &str,
    ) -> OvertimeMutationResponse {
        if let Err(error) = validate_business_date(business_date) {
            return mutation_failure(error);
        }
        let mut store = match repository.load() {
            Ok(store) => store,
            Err(error) => return mutation_failure(error),
        };
        let before = store.records.len();
        store
            .records
            .retain(|record| record.business_date != business_date);
        if store.records.len() == before {
            return OvertimeMutationResponse {
                status: OvertimeMutationStatus::Unchanged,
                schema_version: OVERTIME_SCHEMA_VERSION,
                record: None,
                error_code: None,
                message: "该日期没有加班记录".into(),
                recovery_available: false,
            };
        }
        match repository.save(&store) {
            Ok(()) => OvertimeMutationResponse {
                status: OvertimeMutationStatus::Deleted,
                schema_version: OVERTIME_SCHEMA_VERSION,
                record: None,
                error_code: None,
                message: "加班记录已删除".into(),
                recovery_available: false,
            },
            Err(error) => mutation_failure(error),
        }
    }

    pub fn recover(repository: &impl OvertimeRepository) -> OvertimeMutationResponse {
        match repository.recover_corrupt() {
            Ok(_) => OvertimeMutationResponse {
                status: OvertimeMutationStatus::Recovered,
                schema_version: OVERTIME_SCHEMA_VERSION,
                record: None,
                error_code: None,
                message: "损坏的加班数据已备份，并建立空白记录".into(),
                recovery_available: false,
            },
            Err(error) => mutation_failure(error),
        }
    }
}

fn date_format() -> Result<Vec<format_description::BorrowedFormatItem<'static>>, OvertimeStoreError>
{
    format_description::parse_borrowed::<2>("[year]-[month]-[day]")
        .map_err(|error| OvertimeStoreError::new("overtime_boundary_failed", error.to_string()))
}

fn parse_date(value: &str) -> Result<Date, OvertimeStoreError> {
    Date::parse(value, &date_format()?)
        .map_err(|error| OvertimeStoreError::new("overtime_date_invalid", error.to_string()))
}

fn add_days(value: &str, days: i64) -> Result<String, OvertimeStoreError> {
    parse_date(value)?
        .checked_add(Duration::days(days))
        .ok_or_else(|| OvertimeStoreError::new("overtime_date_invalid", "date overflow"))?
        .format(&date_format()?)
        .map_err(|error| OvertimeStoreError::new("overtime_date_invalid", error.to_string()))
}

fn is_weekend(value: &str) -> Result<bool, OvertimeStoreError> {
    Ok(matches!(
        parse_date(value)?.weekday(),
        time::Weekday::Saturday | time::Weekday::Sunday
    ))
}

fn timestamp(
    date: &str,
    hhmm: &str,
    utc_offset_minutes: i16,
) -> Result<OffsetDateTime, OvertimeStoreError> {
    let sign = if utc_offset_minutes < 0 { '-' } else { '+' };
    let absolute = i32::from(utc_offset_minutes).abs();
    let value = format!(
        "{date}T{hhmm}:00{sign}{:02}:{:02}",
        absolute / 60,
        absolute % 60
    );
    OffsetDateTime::parse(&value, &Rfc3339)
        .map_err(|error| OvertimeStoreError::new("overtime_boundary_failed", error.to_string()))
}

fn valid_month(month: &str) -> bool {
    let bytes = month.as_bytes();
    bytes.len() == 7
        && bytes[4] == b'-'
        && month[0..4].parse::<u16>().is_ok()
        && matches!(month[5..7].parse::<u8>(), Ok(1..=12))
}

fn read_failure(error: OvertimeStoreError) -> OvertimeReadResponse {
    let corrupt = error.is_corrupt();
    OvertimeReadResponse {
        status: if corrupt {
            OvertimeReadStatus::Corrupt
        } else {
            OvertimeReadStatus::Failed
        },
        schema_version: OVERTIME_SCHEMA_VERSION,
        records: Vec::new(),
        error_code: Some(error.code.into()),
        message: if corrupt {
            "加班数据已损坏，旧文件已保留；请先执行恢复。".into()
        } else {
            error.message
        },
        recovery_available: corrupt,
    }
}

fn mutation_failure(error: OvertimeStoreError) -> OvertimeMutationResponse {
    let corrupt = error.is_corrupt();
    OvertimeMutationResponse {
        status: if corrupt {
            OvertimeMutationStatus::Corrupt
        } else {
            OvertimeMutationStatus::Failed
        },
        schema_version: OVERTIME_SCHEMA_VERSION,
        record: None,
        error_code: Some(error.code.into()),
        message: if corrupt {
            "加班数据已损坏，未写入任何更改；请先执行恢复。".into()
        } else {
            error.message
        },
        recovery_available: corrupt,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{CalendarData, DateOverride, DateOverrideKind, RestMode, SalarySchedule};
    use crate::models::overtime::{
        OvertimeBoundaryBasis, OvertimeBoundarySnapshot, OvertimeCalendarSource, OvertimeOrigin,
        OvertimeStore,
    };
    use std::sync::Mutex;

    struct MemoryRepository {
        store: Mutex<Result<OvertimeStore, OvertimeStoreError>>,
        writes: Mutex<usize>,
    }

    impl MemoryRepository {
        fn empty() -> Self {
            Self {
                store: Mutex::new(Ok(OvertimeStore::default())),
                writes: Mutex::new(0),
            }
        }

        fn corrupt() -> Self {
            Self {
                store: Mutex::new(Err(OvertimeStoreError::new(
                    "overtime_store_corrupt",
                    "broken",
                ))),
                writes: Mutex::new(0),
            }
        }

        fn writes(&self) -> usize {
            *self.writes.lock().unwrap()
        }
    }

    impl OvertimeRepository for MemoryRepository {
        fn load(&self) -> Result<OvertimeStore, OvertimeStoreError> {
            self.store.lock().unwrap().clone()
        }

        fn save(&self, store: &OvertimeStore) -> Result<(), OvertimeStoreError> {
            *self.writes.lock().unwrap() += 1;
            *self.store.lock().unwrap() = Ok(store.clone());
            Ok(())
        }

        fn recover_corrupt(&self) -> Result<std::path::PathBuf, OvertimeStoreError> {
            *self.store.lock().unwrap() = Ok(OvertimeStore::default());
            Ok("backup.json".into())
        }
    }

    fn request(date: &str, minutes: u16, rate: i64) -> SaveOvertimeRequest {
        SaveOvertimeRequest {
            business_date: date.into(),
            minutes,
            hourly_rate_fen_snapshot: rate,
            origin: OvertimeOrigin::Independent,
            boundary_snapshot: Some(OvertimeBoundarySnapshot {
                basis: OvertimeBoundaryBasis::RestDayCap,
                current_shift_end: None,
                next_actual_work_start: None,
                maximum_minutes: OVERTIME_MAX_MINUTES,
                calendar_source: OvertimeCalendarSource::Estimated,
            }),
            linked_override_date: None,
        }
    }

    fn schedule() -> SalarySchedule {
        SalarySchedule {
            monthly_salary_minor: 1_000_000,
            rest_mode: RestMode::Double,
            alternating_anchor_date: None,
            alternating_anchor_week_type: None,
            work_hours_per_day: 8.0,
            work_start_time: "09:00".into(),
            work_end_time: "18:00".into(),
            lunch_start_time: "12:00".into(),
            lunch_end_time: "13:00".into(),
        }
    }

    #[test]
    fn create_edit_delete_preserve_rate_snapshot_and_avoid_unchanged_writes() {
        let repository = MemoryRepository::empty();
        let created = OvertimeService::save_record(&repository, request("2026-08-03", 90, 6_250));
        assert_eq!(created.status, OvertimeMutationStatus::Saved);
        assert_eq!(
            created.record.as_ref().unwrap().hourly_rate_fen_snapshot,
            6_250
        );

        let edited = OvertimeService::save_record(&repository, request("2026-08-03", 120, 9_999));
        assert_eq!(edited.record.unwrap().hourly_rate_fen_snapshot, 6_250);

        let unchanged = OvertimeService::save_record(&repository, request("2026-08-03", 120, 1));
        assert_eq!(unchanged.status, OvertimeMutationStatus::Unchanged);
        assert_eq!(repository.writes(), 2);

        let deleted = OvertimeService::save_record(&repository, request("2026-08-03", 0, 6_250));
        assert_eq!(deleted.status, OvertimeMutationStatus::Deleted);
    }

    #[test]
    fn delete_then_recreate_captures_new_rate_and_cross_month_reads_are_isolated() {
        let repository = MemoryRepository::empty();
        OvertimeService::save_record(&repository, request("2026-08-31", 60, 5_000));
        OvertimeService::delete_record(&repository, "2026-08-31");
        let recreated = OvertimeService::save_record(&repository, request("2026-08-31", 30, 7_500));
        assert_eq!(recreated.record.unwrap().hourly_rate_fen_snapshot, 7_500);
        OvertimeService::save_record(&repository, request("2026-09-01", 45, 7_500));
        assert_eq!(
            OvertimeService::read_month(&repository, "2026-08")
                .records
                .len(),
            1
        );
    }

    #[test]
    fn corrupt_state_never_looks_like_zero_and_requires_recovery() {
        let repository = MemoryRepository::corrupt();
        let read = OvertimeService::read_month(&repository, "2026-08");
        assert_eq!(read.status, OvertimeReadStatus::Corrupt);
        assert!(read.recovery_available);
        let save = OvertimeService::save_record(&repository, request("2026-08-03", 30, 6_250));
        assert_eq!(save.status, OvertimeMutationStatus::Corrupt);
        assert_eq!(repository.writes(), 0);
    }

    #[test]
    fn new_writes_require_and_enforce_a_boundary_snapshot() {
        let repository = MemoryRepository::empty();
        let mut missing = request("2026-08-03", 30, 6_250);
        missing.boundary_snapshot = None;
        assert_eq!(
            OvertimeService::save_record(&repository, missing)
                .error_code
                .as_deref(),
            Some("overtime_boundary_required")
        );

        let mut exceeds = request("2026-08-03", 31, 6_250);
        exceeds.boundary_snapshot.as_mut().unwrap().maximum_minutes = 30;
        assert_eq!(
            OvertimeService::save_record(&repository, exceeds)
                .error_code
                .as_deref(),
            Some("overtime_minutes_exceed_boundary")
        );
        assert_eq!(repository.writes(), 0);
    }

    #[test]
    fn manual_weekend_work_suggests_eight_hours_but_official_adjustment_does_not() {
        let manual_calendar = CalendarData {
            date_overrides: vec![DateOverride {
                date: "2026-08-08".into(),
                kind: DateOverrideKind::Workday,
                note: String::new(),
            }],
            ..CalendarData::default()
        };
        let manual = OvertimeService::resolve_boundary(&ResolveOvertimeBoundaryRequest {
            business_date: "2026-08-08".into(),
            schedule: schedule(),
            calendar: manual_calendar,
            calendar_source: OvertimeCalendarSource::Official,
            utc_offset_minutes: 480,
        })
        .unwrap();
        assert_eq!(manual.origin, OvertimeOrigin::ManualWeekendWork);
        assert_eq!(manual.suggested_minutes, Some(480));
        assert_eq!(manual.snapshot.maximum_minutes, 1_440);
        assert_eq!(manual.linked_override_date.as_deref(), Some("2026-08-08"));

        let official = OvertimeService::resolve_boundary(&ResolveOvertimeBoundaryRequest {
            business_date: "2026-08-08".into(),
            schedule: schedule(),
            calendar: CalendarData {
                adjusted_workdays: vec!["2026-08-08".into()],
                ..CalendarData::default()
            },
            calendar_source: OvertimeCalendarSource::Official,
            utc_offset_minutes: 480,
        })
        .unwrap();
        assert_eq!(official.origin, OvertimeOrigin::Independent);
        assert_eq!(official.suggested_minutes, None);
        assert_eq!(official.linked_override_date, None);
    }

    #[test]
    fn dynamic_cap_can_be_less_than_eight_hours_and_rest_days_keep_the_24_hour_cap() {
        let mut short_gap_schedule = schedule();
        short_gap_schedule.work_start_time = "01:00".into();
        short_gap_schedule.work_end_time = "23:00".into();
        let calendar = CalendarData {
            date_overrides: vec![
                DateOverride {
                    date: "2026-08-08".into(),
                    kind: DateOverrideKind::Workday,
                    note: String::new(),
                },
                DateOverride {
                    date: "2026-08-09".into(),
                    kind: DateOverrideKind::Workday,
                    note: String::new(),
                },
            ],
            ..CalendarData::default()
        };
        let short = OvertimeService::resolve_boundary(&ResolveOvertimeBoundaryRequest {
            business_date: "2026-08-08".into(),
            schedule: short_gap_schedule,
            calendar,
            calendar_source: OvertimeCalendarSource::Manual,
            utc_offset_minutes: 480,
        })
        .unwrap();
        assert_eq!(short.snapshot.maximum_minutes, 120);
        assert_eq!(short.suggested_minutes, Some(120));

        let rest = OvertimeService::resolve_boundary(&ResolveOvertimeBoundaryRequest {
            business_date: "2026-08-09".into(),
            schedule: schedule(),
            calendar: CalendarData::default(),
            calendar_source: OvertimeCalendarSource::Estimated,
            utc_offset_minutes: 480,
        })
        .unwrap();
        assert_eq!(rest.snapshot.basis, OvertimeBoundaryBasis::RestDayCap);
        assert_eq!(rest.snapshot.maximum_minutes, OVERTIME_MAX_MINUTES);
        assert_eq!(rest.suggested_minutes, None);
    }
}
