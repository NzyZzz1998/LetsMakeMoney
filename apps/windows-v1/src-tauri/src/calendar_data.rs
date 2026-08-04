use std::collections::HashSet;

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::domain;

const MANIFEST_JSON: &str = include_str!("../../calendar-data/manifest.json");
include!(concat!(env!("OUT_DIR"), "/calendar_index.rs"));

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct CalendarSource {
    pub publisher: String,
    pub title: String,
    pub document_no: String,
    pub published_at: String,
    pub url: String,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum CalendarCoverageMode {
    Official,
    Estimated,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct CalendarCoverage {
    pub year: i32,
    pub mode: CalendarCoverageMode,
    pub dataset_version: Option<String>,
    pub source: Option<CalendarSource>,
    pub estimate_basis: Option<String>,
    pub stale_reason: Option<String>,
    pub error_code: Option<String>,
    pub official: bool,
    pub can_adjust_date: bool,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct CalendarDatasetResponse {
    pub year: i32,
    pub dataset_version: Option<String>,
    pub source: Option<CalendarSource>,
    pub coverage: CalendarCoverage,
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

pub trait CalendarProvider {
    fn load_year(&self, year: i32) -> Result<CalendarDatasetResponse, String>;
}

pub struct EmbeddedChinaHolidayProvider;

impl CalendarProvider for EmbeddedChinaHolidayProvider {
    fn load_year(&self, year: i32) -> Result<CalendarDatasetResponse, String> {
        let dataset = CALENDAR_DATASETS
            .iter()
            .find(|(dataset_year, _, _)| *dataset_year == year)
            .map(|(_, file, json)| (*file, *json));
        parse_calendar_response(year, MANIFEST_JSON, dataset)
    }
}

pub fn load_calendar_year(year: i32) -> Result<CalendarDatasetResponse, String> {
    EmbeddedChinaHolidayProvider.load_year(year)
}

fn parse_calendar_response(
    year: i32,
    manifest_json: &str,
    dataset: Option<(&str, &str)>,
) -> Result<CalendarDatasetResponse, String> {
    let manifest: CalendarManifest =
        serde_json::from_str(manifest_json).map_err(|_| "calendar_manifest_invalid".to_string())?;
    validate_manifest(&manifest)?;

    let Some(entry) = manifest.datasets.iter().find(|entry| entry.year == year) else {
        return Ok(estimated_response(year));
    };
    let (compiled_file, dataset_json) =
        dataset.ok_or_else(|| format!("calendar_dataset_missing:{year}"))?;
    if compiled_file != entry.file {
        return Err(format!("calendar_dataset_missing:{year}"));
    }

    let actual_sha256 = format!("{:X}", Sha256::digest(dataset_json.as_bytes()));
    if actual_sha256 != entry.sha256.to_ascii_uppercase() {
        return Err(format!("calendar_hash_mismatch:{year}"));
    }

    let raw: RawCalendarDataset = serde_json::from_str(dataset_json)
        .map_err(|_| format!("calendar_dataset_invalid:{year}"))?;
    validate_dataset(&raw, year)?;

    let source = raw.source;
    let dataset_version = manifest.dataset_version;
    Ok(CalendarDatasetResponse {
        year,
        dataset_version: Some(dataset_version.clone()),
        source: Some(source.clone()),
        coverage: CalendarCoverage {
            year,
            mode: CalendarCoverageMode::Official,
            dataset_version: Some(dataset_version),
            source: Some(source),
            estimate_basis: None,
            stale_reason: None,
            error_code: None,
            official: true,
            can_adjust_date: true,
        },
        calendar: domain::CalendarData {
            statutory_holidays: raw.holiday_dates,
            adjusted_workdays: raw.adjusted_workdays,
            date_overrides: Vec::new(),
        },
    })
}

fn estimated_response(year: i32) -> CalendarDatasetResponse {
    CalendarDatasetResponse {
        year,
        dataset_version: None,
        source: None,
        coverage: CalendarCoverage {
            year,
            mode: CalendarCoverageMode::Estimated,
            dataset_version: None,
            source: None,
            estimate_basis: None,
            stale_reason: None,
            error_code: None,
            official: false,
            can_adjust_date: true,
        },
        calendar: domain::CalendarData::default(),
    }
}

fn validate_manifest(manifest: &CalendarManifest) -> Result<(), String> {
    if manifest.schema_version != 1
        || manifest.dataset_version.trim().is_empty()
        || manifest.supported_years.is_empty()
    {
        return Err("calendar_manifest_invalid".into());
    }

    let supported_years: HashSet<i32> = manifest.supported_years.iter().copied().collect();
    let dataset_years: HashSet<i32> = manifest.datasets.iter().map(|entry| entry.year).collect();
    if supported_years.len() != manifest.supported_years.len()
        || dataset_years.len() != manifest.datasets.len()
        || supported_years != dataset_years
    {
        return Err("calendar_manifest_invalid".into());
    }

    let mut files = HashSet::new();
    for entry in &manifest.datasets {
        let expected_file = format!("cn-{}.json", entry.year);
        if entry.file != expected_file
            || !files.insert(entry.file.as_str())
            || entry.sha256.len() != 64
            || !entry.sha256.bytes().all(|byte| byte.is_ascii_hexdigit())
        {
            return Err("calendar_manifest_invalid".into());
        }
    }
    Ok(())
}

fn validate_dataset(raw: &RawCalendarDataset, year: i32) -> Result<(), String> {
    if raw.schema_version != 1
        || raw.year != year
        || raw.dataset_id != format!("cn-{year}")
        || raw.holiday_dates.is_empty()
        || !dates_are_valid_and_unique(&raw.holiday_dates, year)
        || !dates_are_valid_and_unique(&raw.adjusted_workdays, year)
        || raw
            .holiday_dates
            .iter()
            .any(|date| raw.adjusted_workdays.contains(date))
    {
        return Err(format!("calendar_dataset_invalid:{year}"));
    }

    if raw.source.publisher.trim().is_empty()
        || raw.source.title.trim().is_empty()
        || raw.source.document_no.trim().is_empty()
        || raw.source.published_at.trim().is_empty()
        || !raw.source.url.starts_with("https://www.gov.cn/")
    {
        return Err(format!("calendar_source_invalid:{year}"));
    }
    Ok(())
}

fn dates_are_valid_and_unique(dates: &[String], year: i32) -> bool {
    let mut unique = HashSet::new();
    dates.iter().all(|date| {
        date.starts_with(&format!("{year:04}-"))
            && domain::validate_date(date).is_ok()
            && unique.insert(date.as_str())
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    struct EstimatedOnlyProvider;

    impl CalendarProvider for EstimatedOnlyProvider {
        fn load_year(&self, year: i32) -> Result<CalendarDatasetResponse, String> {
            Ok(estimated_response(year))
        }
    }

    #[test]
    fn calendar_provider_contract_is_replaceable_without_domain_changes() {
        let provider = EstimatedOnlyProvider;
        let dataset = provider.load_year(2030).unwrap();

        assert_eq!(dataset.year, 2030);
        assert_eq!(dataset.coverage.mode, CalendarCoverageMode::Estimated);
        assert!(dataset.calendar.statutory_holidays.is_empty());
    }

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
        assert_eq!(dataset.dataset_version.as_deref(), Some("cn-2025-2026-v1"));
        assert_eq!(
            dataset
                .source
                .as_ref()
                .map(|source| source.publisher.as_str()),
            Some("国务院办公厅")
        );
        assert_eq!(dataset.coverage.mode, CalendarCoverageMode::Official);
        assert!(dataset.coverage.official);
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
    fn unsupported_year_returns_explicit_estimate_contract() {
        let dataset = load_calendar_year(2027).expect("unsupported year should estimate");

        assert_eq!(dataset.year, 2027);
        assert_eq!(dataset.dataset_version, None);
        assert_eq!(dataset.source, None);
        assert_eq!(dataset.coverage.mode, CalendarCoverageMode::Estimated);
        assert!(!dataset.coverage.official);
        assert!(dataset.coverage.can_adjust_date);
        assert!(dataset.calendar.statutory_holidays.is_empty());
        assert!(dataset.calendar.adjusted_workdays.is_empty());
    }

    #[test]
    fn rejects_dataset_when_hash_does_not_match_manifest() {
        let (_, file, source) = CALENDAR_DATASETS
            .iter()
            .find(|(year, _, _)| *year == 2026)
            .expect("2026 dataset");
        let tampered = source.replace("\"2026-01-01\"", "\"2026-01-02\"");

        assert_eq!(
            parse_calendar_response(2026, MANIFEST_JSON, Some((file, &tampered))).unwrap_err(),
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
            parse_calendar_response(2026, &manifest, Some(("cn-2026.json", "{}"))).unwrap_err(),
            "calendar_dataset_invalid:2026"
        );
    }

    #[test]
    fn rejects_invalid_calendar_date_even_when_hash_matches() {
        let (_, file, source) = CALENDAR_DATASETS
            .iter()
            .find(|(year, _, _)| *year == 2026)
            .expect("2026 dataset");
        let invalid = source.replace("\"2026-01-01\"", "\"2026-02-30\"");
        let hash = format!("{:X}", Sha256::digest(invalid.as_bytes()));
        let manifest = MANIFEST_JSON.replace(
            "440169EAD0FCDA71C15CBAAE11EC557DC0846EECA103A988D267303D9C306042",
            &hash,
        );

        assert_eq!(
            parse_calendar_response(2026, &manifest, Some((file, &invalid))).unwrap_err(),
            "calendar_dataset_invalid:2026"
        );
    }

    #[test]
    fn rejects_source_that_is_not_an_authoritative_gov_page() {
        let (_, file, source) = CALENDAR_DATASETS
            .iter()
            .find(|(year, _, _)| *year == 2026)
            .expect("2026 dataset");
        let invalid = source.replace("https://www.gov.cn/", "https://example.com/");
        let hash = format!("{:X}", Sha256::digest(invalid.as_bytes()));
        let manifest = MANIFEST_JSON.replace(
            "440169EAD0FCDA71C15CBAAE11EC557DC0846EECA103A988D267303D9C306042",
            &hash,
        );

        assert_eq!(
            parse_calendar_response(2026, &manifest, Some((file, &invalid))).unwrap_err(),
            "calendar_source_invalid:2026"
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
