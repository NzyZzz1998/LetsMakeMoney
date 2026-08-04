use std::collections::HashSet;

use serde::{Deserialize, Serialize};
use time::{format_description::well_known::Rfc3339, Date, Month, OffsetDateTime};

pub const OVERTIME_SCHEMA_VERSION: u8 = 1;

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct OvertimeRecord {
    pub business_date: String,
    pub minutes: u16,
    pub hourly_rate_fen_snapshot: i64,
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
        if record.minutes == 0 || record.minutes > 1_440 {
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
            created_at: "2026-08-03T11:30:00Z".into(),
            updated_at: "2026-08-03T11:30:00Z".into(),
        }
    }

    #[test]
    fn validates_schema_range_timestamp_and_unique_date() {
        let valid = OvertimeStore {
            schema_version: 1,
            records: vec![record("2026-08-03")],
        };
        assert!(validate_store(&valid).is_ok());

        let mut duplicate = valid.clone();
        duplicate.records.push(record("2026-08-03"));
        assert_eq!(
            validate_store(&duplicate).unwrap_err().code,
            "overtime_date_conflict"
        );

        let mut invalid_minutes = valid;
        invalid_minutes.records[0].minutes = 1_441;
        assert_eq!(
            validate_store(&invalid_minutes).unwrap_err().code,
            "overtime_minutes_out_of_range"
        );

        assert_eq!(
            validate_business_date("2026-02-31").unwrap_err().code,
            "overtime_date_invalid"
        );
        assert!(validate_business_date("2028-02-29").is_ok());
    }
}
