use std::collections::HashSet;

use crate::domain::{CalendarData, SalarySchedule};
use serde::{Deserialize, Serialize};
use time::{format_description::well_known::Rfc3339, Date, Month, OffsetDateTime};

pub const OVERTIME_SCHEMA_VERSION: u8 = 2;
pub const LEGACY_OVERTIME_SCHEMA_VERSION: u8 = 1;
pub const OVERTIME_MAX_MINUTES: u16 = 1_440;

#[derive(Clone, Copy, Debug, Default, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum OvertimeOrigin {
    #[default]
    Independent,
    ManualWeekendWork,
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum OvertimeBoundaryBasis {
    PlannedShiftGap,
    RestDayCap,
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum OvertimeCalendarSource {
    Official,
    Estimated,
    Manual,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct OvertimeBoundarySnapshot {
    pub basis: OvertimeBoundaryBasis,
    pub current_shift_end: Option<String>,
    pub next_actual_work_start: Option<String>,
    pub maximum_minutes: u16,
    pub calendar_source: OvertimeCalendarSource,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct OvertimeRecord {
    pub business_date: String,
    pub minutes: u16,
    pub hourly_rate_fen_snapshot: i64,
    #[serde(default)]
    pub origin: OvertimeOrigin,
    #[serde(default)]
    pub boundary_snapshot: Option<OvertimeBoundarySnapshot>,
    #[serde(default)]
    pub linked_override_date: Option<String>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct OvertimeStore {
    pub schema_version: u8,
    pub records: Vec<OvertimeRecord>,
}

impl Default for OvertimeStore {
    fn default() -> Self {
        Self {
            schema_version: OVERTIME_SCHEMA_VERSION,
            records: Vec::new(),
        }
    }
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct SaveOvertimeRequest {
    pub business_date: String,
    pub minutes: u16,
    pub hourly_rate_fen_snapshot: i64,
    #[serde(default)]
    pub origin: OvertimeOrigin,
    #[serde(default)]
    pub boundary_snapshot: Option<OvertimeBoundarySnapshot>,
    #[serde(default)]
    pub linked_override_date: Option<String>,
}

#[derive(Clone, Debug, Deserialize, PartialEq, Serialize)]
pub struct ResolveOvertimeBoundaryRequest {
    pub business_date: String,
    pub schedule: SalarySchedule,
    pub calendar: CalendarData,
    pub calendar_source: OvertimeCalendarSource,
    pub utc_offset_minutes: i16,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct OvertimeBoundaryResolution {
    pub snapshot: OvertimeBoundarySnapshot,
    pub suggested_minutes: Option<u16>,
    pub origin: OvertimeOrigin,
    pub linked_override_date: Option<String>,
    pub day_source: String,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum OvertimeReadStatus {
    Ready,
    Empty,
    Corrupt,
    Failed,
}

impl OvertimeReadStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Ready => "ready",
            Self::Empty => "empty",
            Self::Corrupt => "corrupt",
            Self::Failed => "failed",
        }
    }
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct OvertimeReadResponse {
    pub status: OvertimeReadStatus,
    pub schema_version: u8,
    pub records: Vec<OvertimeRecord>,
    pub error_code: Option<String>,
    pub message: String,
    pub recovery_available: bool,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum OvertimeMutationStatus {
    Saved,
    Unchanged,
    Deleted,
    Recovered,
    Failed,
    Corrupt,
}

impl OvertimeMutationStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Saved => "saved",
            Self::Unchanged => "unchanged",
            Self::Deleted => "deleted",
            Self::Recovered => "recovered",
            Self::Failed => "failed",
            Self::Corrupt => "corrupt",
        }
    }
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct OvertimeMutationResponse {
    pub status: OvertimeMutationStatus,
    pub schema_version: u8,
    pub record: Option<OvertimeRecord>,
    pub error_code: Option<String>,
    pub message: String,
    pub recovery_available: bool,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct OvertimeStoreError {
    pub code: &'static str,
    pub message: String,
}

impl OvertimeStoreError {
    pub fn new(code: &'static str, message: impl Into<String>) -> Self {
        Self {
            code,
            message: message.into(),
        }
    }

    pub fn is_corrupt(&self) -> bool {
        self.code == "overtime_store_corrupt"
    }
}

pub fn now_rfc3339() -> Result<String, OvertimeStoreError> {
    OffsetDateTime::now_utc()
        .format(&Rfc3339)
        .map_err(|error| OvertimeStoreError::new("overtime_clock_failed", error.to_string()))
}

pub fn validate_business_date(value: &str) -> Result<(), OvertimeStoreError> {
    let parts = value.split('-').collect::<Vec<_>>();
    if parts.len() != 3
        || parts[0].len() != 4
        || parts[1].len() != 2
        || parts[2].len() != 2
        || !parts
            .iter()
            .all(|part| part.bytes().all(|byte| byte.is_ascii_digit()))
    {
        return Err(OvertimeStoreError::new(
            "overtime_date_invalid",
            "业务日期格式无效",
        ));
    }
    let year = parts[0].parse::<i32>().ok();
    let month = parts[1]
        .parse::<u8>()
        .ok()
        .and_then(|value| Month::try_from(value).ok());
    let day = parts[2].parse::<u8>().ok();
    let valid = match (year, month, day) {
        (Some(year @ 1900..=9999), Some(month), Some(day)) => {
            Date::from_calendar_date(year, month, day).is_ok()
        }
        _ => false,
    };
    if !valid {
        return Err(OvertimeStoreError::new(
            "overtime_date_invalid",
            "业务日期格式无效",
        ));
    }
    Ok(())
}

fn validate_boundary(snapshot: &OvertimeBoundarySnapshot) -> Result<(), OvertimeStoreError> {
    if snapshot.maximum_minutes == 0 || snapshot.maximum_minutes > OVERTIME_MAX_MINUTES {
        return Err(OvertimeStoreError::new(
            "overtime_boundary_invalid",
            "加班边界必须大于 0 且不超过 24 小时",
        ));
    }
    match snapshot.basis {
        OvertimeBoundaryBasis::PlannedShiftGap => {
            let valid_timestamp = |value: &Option<String>| {
                value
                    .as_deref()
                    .is_some_and(|value| OffsetDateTime::parse(value, &Rfc3339).is_ok())
            };
            if !valid_timestamp(&snapshot.current_shift_end)
                || !valid_timestamp(&snapshot.next_actual_work_start)
            {
                return Err(OvertimeStoreError::new(
                    "overtime_boundary_invalid",
                    "计划班次边界必须包含有效的下班与下一次开工时间",
                ));
            }
        }
        OvertimeBoundaryBasis::RestDayCap => {
            if snapshot.current_shift_end.is_some() || snapshot.next_actual_work_start.is_some() {
                return Err(OvertimeStoreError::new(
                    "overtime_boundary_invalid",
                    "休息日上限不得包含计划班次时间",
                ));
            }
        }
    }
    Ok(())
}

pub fn validate_store(store: &OvertimeStore) -> Result<(), OvertimeStoreError> {
    if store.schema_version != OVERTIME_SCHEMA_VERSION {
        return Err(OvertimeStoreError::new(
            "overtime_schema_unsupported",
            format!("不支持的加班数据版本：{}", store.schema_version),
        ));
    }
    let mut dates = HashSet::new();
    for record in &store.records {
        validate_business_date(&record.business_date)?;
        if record.minutes == 0 || record.minutes > OVERTIME_MAX_MINUTES {
            return Err(OvertimeStoreError::new(
                "overtime_minutes_out_of_range",
                "加班时长必须大于 0 且不超过 24 小时",
            ));
        }
        if record.hourly_rate_fen_snapshot < 0 {
            return Err(OvertimeStoreError::new(
                "overtime_rate_invalid",
                "时薪快照无效",
            ));
        }
        if let Some(snapshot) = &record.boundary_snapshot {
            validate_boundary(snapshot)?;
            if record.minutes > snapshot.maximum_minutes {
                return Err(OvertimeStoreError::new(
                    "overtime_minutes_exceed_boundary",
                    "加班时长超过本次可录入上限",
                ));
            }
        }
        if record.origin == OvertimeOrigin::ManualWeekendWork {
            if record.linked_override_date.as_deref() != Some(record.business_date.as_str())
                || record.boundary_snapshot.is_none()
            {
                return Err(OvertimeStoreError::new(
                    "overtime_link_invalid",
                    "周末联动加班必须绑定同一业务日期及边界快照",
                ));
            }
        } else if record.linked_override_date.is_some() {
            return Err(OvertimeStoreError::new(
                "overtime_link_invalid",
                "独立加班记录不得绑定日期调整",
            ));
        }
        if let Some(date) = &record.linked_override_date {
            validate_business_date(date)?;
        }
        if !dates.insert(record.business_date.as_str()) {
            return Err(OvertimeStoreError::new(
                "overtime_date_conflict",
                "同一业务日期只能有一条加班记录",
            ));
        }
        if OffsetDateTime::parse(&record.created_at, &Rfc3339).is_err()
            || OffsetDateTime::parse(&record.updated_at, &Rfc3339).is_err()
        {
            return Err(OvertimeStoreError::new(
                "overtime_timestamp_invalid",
                "加班记录时间戳无效",
            ));
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn record(date: &str) -> OvertimeRecord {
        OvertimeRecord {
            business_date: date.into(),
            minutes: 90,
            hourly_rate_fen_snapshot: 6_250,
            origin: OvertimeOrigin::Independent,
            boundary_snapshot: Some(OvertimeBoundarySnapshot {
                basis: OvertimeBoundaryBasis::RestDayCap,
                current_shift_end: None,
                next_actual_work_start: None,
                maximum_minutes: OVERTIME_MAX_MINUTES,
                calendar_source: OvertimeCalendarSource::Estimated,
            }),
            linked_override_date: None,
            created_at: "2026-08-03T11:30:00Z".into(),
            updated_at: "2026-08-03T11:30:00Z".into(),
        }
    }

    #[test]
    fn validates_schema_range_timestamp_boundary_and_unique_date() {
        let valid = OvertimeStore {
            schema_version: OVERTIME_SCHEMA_VERSION,
            records: vec![record("2026-08-03")],
        };
        assert!(validate_store(&valid).is_ok());

        let mut duplicate = valid.clone();
        duplicate.records.push(record("2026-08-03"));
        assert_eq!(
            validate_store(&duplicate).unwrap_err().code,
            "overtime_date_conflict"
        );

        let mut invalid_minutes = valid.clone();
        invalid_minutes.records[0].minutes = 1_441;
        assert_eq!(
            validate_store(&invalid_minutes).unwrap_err().code,
            "overtime_minutes_out_of_range"
        );

        let mut exceeds_boundary = valid;
        exceeds_boundary.records[0].minutes = 91;
        exceeds_boundary.records[0]
            .boundary_snapshot
            .as_mut()
            .unwrap()
            .maximum_minutes = 90;
        assert_eq!(
            validate_store(&exceeds_boundary).unwrap_err().code,
            "overtime_minutes_exceed_boundary"
        );

        assert_eq!(
            validate_business_date("2026-02-31").unwrap_err().code,
            "overtime_date_invalid"
        );
        assert!(validate_business_date("2028-02-29").is_ok());
    }

    #[test]
    fn manual_weekend_records_require_a_matching_link() {
        let mut linked = record("2026-08-08");
        linked.origin = OvertimeOrigin::ManualWeekendWork;
        linked.linked_override_date = Some("2026-08-08".into());
        assert!(validate_store(&OvertimeStore {
            schema_version: OVERTIME_SCHEMA_VERSION,
            records: vec![linked.clone()],
        })
        .is_ok());

        linked.linked_override_date = None;
        assert_eq!(
            validate_store(&OvertimeStore {
                schema_version: OVERTIME_SCHEMA_VERSION,
                records: vec![linked],
            })
            .unwrap_err()
            .code,
            "overtime_link_invalid"
        );
    }
}
