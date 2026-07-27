use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::domain;

const MANIFEST_JSON: &str = include_str!("../../calendar-data/manifest.json");
const DATASET_2025_JSON: &str = include_str!("../../calendar-data/cn-2025.json");
const DATASET_2026_JSON: &str = include_str!("../../calendar-data/cn-2026.json");

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct CalendarSource {
    pub publisher: String,
    pub title: String,
    pub document_no: String,
    pub published_at: String,
    pub url: String,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct CalendarDatasetResponse {
    pub year: i32,
    pub dataset_version: String,
    pub source: CalendarSource,
    pub calendar: domain::CalendarData,
}

#[derive(Debug, Deserialize)]
struct CalendarManifest {
    schema_version: u32,
    dataset_version: String,
    supported_years: Vec<i32>,
    datasets: Vec<CalendarManifestEntry>,
}

#[derive(Debug, Deserialize)]
struct CalendarManifestEntry {
    year: i32,
    file: String,
    sha256: String,
}

#[derive(Debug, Deserialize)]
struct RawCalendarDataset {
    schema_version: u32,
    dataset_id: String,
    year: i32,
    source: CalendarSource,
    holiday_dates: Vec<String>,
    adjusted_workdays: Vec<String>,
}

pub fn load_calendar_year(year: i32) -> Result<CalendarDatasetResponse, String> {
    let dataset_json = match year {
        2025 => DATASET_2025_JSON,
        2026 => DATASET_2026_JSON,
        _ => return Err(format!("calendar_year_unsupported:{year}")),
    };
    parse_calendar_year(year, MANIFEST_JSON, dataset_json)
}

fn parse_calendar_year(
    year: i32,
    manifest_json: &str,
    dataset_json: &str,
) -> Result<CalendarDatasetResponse, String> {
    let manifest: CalendarManifest =
        serde_json::from_str(manifest_json).map_err(|_| "calendar_manifest_invalid".to_string())?;
    if manifest.schema_version != 1
        || !manifest.supported_years.contains(&year)
        || manifest.dataset_version.trim().is_empty()
    {
        return Err("calendar_manifest_invalid".into());
    }

    let entry = manifest
        .datasets
        .iter()
        .find(|entry| entry.year == year)
        .ok_or_else(|| format!("calendar_year_unsupported:{year}"))?;
    let expected_file = format!("cn-{year}.json");
    if entry.file != expected_file || entry.sha256.len() != 64 {
        return Err("calendar_manifest_invalid".into());
    }

    let actual_sha256 = format!("{:X}", Sha256::digest(dataset_json.as_bytes()));
    if actual_sha256 != entry.sha256.to_ascii_uppercase() {
        return Err(format!("calendar_hash_mismatch:{year}"));
    }

    let raw: RawCalendarDataset = serde_json::from_str(dataset_json)
        .map_err(|_| format!("calendar_dataset_invalid:{year}"))?;
    if raw.schema_version != 1
        || raw.year != year
        || raw.dataset_id != format!("cn-{year}")
        || raw.source.publisher.trim().is_empty()
        || raw.source.title.trim().is_empty()
        || raw.source.document_no.trim().is_empty()
        || !raw.source.url.starts_with("https://www.gov.cn/")
        || raw.holiday_dates.is_empty()
        || !dates_match_year(&raw.holiday_dates, year)
        || !dates_match_year(&raw.adjusted_workdays, year)
    {
        return Err(format!("calendar_dataset_invalid:{year}"));
    }

    Ok(CalendarDatasetResponse {
        year,
        dataset_version: manifest.dataset_version,
        source: raw.source,
        calendar: domain::CalendarData {
            statutory_holidays: raw.holiday_dates,
            adjusted_workdays: raw.adjusted_workdays,
            date_overrides: Vec::new(),
        },
    })
}

fn dates_match_year(dates: &[String], year: i32) -> bool {
    let prefix = format!("{year:04}-");
    dates.iter().all(|date| {
        date.len() == 10
            && date.starts_with(&prefix)
            && date.as_bytes()[4] == b'-'
            && date.as_bytes()[7] == b'-'
            && date
                .bytes()
                .enumerate()
                .all(|(index, byte)| index == 4 || index == 7 || byte.is_ascii_digit())
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn double_rest_schedule() -> domain::SalarySchedule {
        domain::SalarySchedule {
            monthly_salary_minor: 1_000_000,
            rest_mode: domain::RestMode::Double,
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
    fn loads_2026_official_calendar_with_source_and_adjusted_days() {
        let dataset = load_calendar_year(2026).expect("2026 dataset should load");

        assert_eq!(dataset.year, 2026);
        assert_eq!(dataset.dataset_version, "cn-2025-2026-v1");
        assert_eq!(dataset.source.publisher, "国务院办公厅");
        assert!(dataset
            .calendar
            .statutory_holidays
            .contains(&"2026-02-17".to_string()));
        assert!(dataset
            .calendar
            .adjusted_workdays
            .contains(&"2026-02-14".to_string()));
    }

    #[test]
    fn rejects_unsupported_year_explicitly() {
        assert_eq!(
            load_calendar_year(2027).unwrap_err(),
            "calendar_year_unsupported:2027"
        );
    }

    #[test]
    fn rejects_dataset_when_hash_does_not_match_manifest() {
        let tampered = DATASET_2026_JSON.replace("\"2026-01-01\"", "\"2026-01-02\"");

        assert_eq!(
            parse_calendar_year(2026, MANIFEST_JSON, &tampered).unwrap_err(),
            "calendar_hash_mismatch:2026"
        );
    }

    #[test]
    fn rejects_invalid_or_empty_dataset() {
        let manifest = MANIFEST_JSON.replace(
            "440169EAD0FCDA71C15CBAAE11EC557DC0846EECA103A988D267303D9C306042",
            &format!("{:X}", Sha256::digest(b"{}")),
        );

        assert_eq!(
            parse_calendar_year(2026, &manifest, "{}").unwrap_err(),
            "calendar_dataset_invalid:2026"
        );
    }

    #[test]
    fn official_holiday_and_adjusted_workday_override_weekend_rules() {
        let dataset = load_calendar_year(2026).expect("2026 dataset should load");
        let schedule = double_rest_schedule();

        let holiday = domain::resolve_day("2026-02-18", &schedule, &dataset.calendar).unwrap();
        assert_eq!(holiday.kind, domain::DayKind::RestDay);
        assert_eq!(holiday.source, "statutory_holiday");

        let adjusted = domain::resolve_day("2026-02-28", &schedule, &dataset.calendar).unwrap();
        assert_eq!(adjusted.kind, domain::DayKind::Workday);
        assert_eq!(adjusted.source, "adjusted_workday");
    }
}
