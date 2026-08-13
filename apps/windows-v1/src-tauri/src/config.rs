use crate::calendar_data;
use crate::domain::{
    self, CalendarData, DateOverride, DateOverrideKind, DayKind, RestMode, SalarySchedule, WeekType,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

pub const CURRENT_CONFIG_VERSION: u32 = 9;
pub const MIGRATABLE_CONFIG_VERSIONS: &[u64] = &[5, 6, 7, 8];

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct WindowPosition {
    pub x: f64,
    pub y: f64,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum ThemeMode {
    Light,
    Dark,
}

fn default_true() -> bool {
    true
}

#[derive(Clone, Copy, Debug, Default, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum MiniEdgeDock {
    Left,
    Right,
    #[default]
    #[serde(other)]
    None,
}

#[derive(Clone, Copy, Debug, Default, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum DesktopCompanionMode {
    Pet,
    #[default]
    #[serde(other)]
    Mini,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct AppConfig {
    pub config_version: u32,
    pub theme_mode: ThemeMode,
    pub monthly_salary: f64,
    pub rest_mode: RestMode,
    pub alternating_anchor_date: Option<String>,
    pub alternating_anchor_week_type: Option<WeekType>,
    pub work_hours_per_day: f64,
    pub work_start_time: String,
    pub work_end_time: String,
    pub lunch_start_time: String,
    pub lunch_end_time: String,
    pub calendar_dataset_version: String,
    pub date_overrides: Vec<DateOverride>,
    #[serde(default)]
    pub desktop_companion_mode: DesktopCompanionMode,
    pub mini_window_position: Option<WindowPosition>,
    #[serde(default)]
    pub pet_window_position: Option<WindowPosition>,
    pub mini_window_visible: bool,
    pub mini_window_always_on_top: bool,
    #[serde(default = "default_true")]
    pub mini_edge_auto_hide: bool,
    #[serde(default)]
    pub mini_edge_dock: MiniEdgeDock,
    pub minimize_to_tray: bool,
    pub auto_start: bool,
    pub check_updates_on_start: bool,
    pub update_channel: String,
    pub log_level: String,
}

impl Default for AppConfig {
    fn default() -> Self {
        serde_json::from_str(include_str!("../../contracts/config-v9-defaults.json"))
            .expect("embedded config defaults must remain valid")
    }
}

impl AppConfig {
    pub fn salary_schedule(&self) -> SalarySchedule {
        SalarySchedule {
            monthly_salary_minor: (self.monthly_salary * 100.0).round() as i64,
            rest_mode: self.rest_mode,
            alternating_anchor_date: self.alternating_anchor_date.clone(),
            alternating_anchor_week_type: self.alternating_anchor_week_type.clone(),
            work_hours_per_day: self.work_hours_per_day,
            work_start_time: self.work_start_time.clone(),
            work_end_time: self.work_end_time.clone(),
            lunch_start_time: self.lunch_start_time.clone(),
            lunch_end_time: self.lunch_end_time.clone(),
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum SaveStatus {
    Saved,
    Unchanged,
    Failed,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct SaveResult {
    pub status: SaveStatus,
    pub message: String,
    pub draft_preserved: bool,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum SaveFault {
    None,
    TempWriteDenied,
    SideEffectDenied,
}

pub fn validate(config: &AppConfig) -> Result<(), String> {
    if config.config_version != CURRENT_CONFIG_VERSION {
        return Err("unsupported_config_version".into());
    }
    if !config.monthly_salary.is_finite() || config.monthly_salary < 0.0 {
        return Err("invalid_monthly_salary".into());
    }
    if !(0.0..=24.0).contains(&config.work_hours_per_day) || config.work_hours_per_day == 0.0 {
        return Err("invalid_work_hours".into());
    }
    for value in [
        &config.work_start_time,
        &config.work_end_time,
        &config.lunch_start_time,
        &config.lunch_end_time,
    ] {
        validate_clock(value)?;
    }
    if config.rest_mode == RestMode::Alternating {
        if config.alternating_anchor_date.is_none() {
            return Err("alternating_anchor_date_required".into());
        }
        if config.alternating_anchor_week_type.is_none() {
            return Err("alternating_week_type_required".into());
        }
    }
    if config.update_channel != "stable" {
        return Err("invalid_update_channel".into());
    }
    if !["error", "info", "debug"].contains(&config.log_level.as_str()) {
        return Err("invalid_log_level".into());
    }
    let mut dates = std::collections::HashSet::new();
    for entry in &config.date_overrides {
        domain::validate_date(&entry.date)?;
        if !dates.insert(entry.date.as_str()) {
            return Err("duplicate_date_override".into());
        }
        if entry.note.chars().count() > 120 {
            return Err("date_override_note_too_long".into());
        }
    }
    Ok(())
}

fn validate_clock(value: &str) -> Result<(), String> {
    let parts: Vec<_> = value.split(':').collect();
    if parts.len() != 2 {
        return Err("invalid_time".into());
    }
    let hour: u32 = parts[0].parse().map_err(|_| "invalid_time")?;
    let minute: u32 = parts[1].parse().map_err(|_| "invalid_time")?;
    if hour > 23 || minute > 59 {
        return Err("invalid_time".into());
    }
    Ok(())
}

pub fn migrate_v5(source: &Value) -> Result<AppConfig, String> {
    if source.get("config_version").and_then(Value::as_u64) != Some(5) {
        return Err("unsupported_source_config".into());
    }
    migrate_legacy_to_v8(source)
}

pub fn migrate_v6(source: &Value) -> Result<AppConfig, String> {
    if source.get("config_version").and_then(Value::as_u64) != Some(6) {
        return Err("unsupported_source_config".into());
    }
    migrate_legacy_to_v8(source)
}

pub fn migrate_v7(source: &Value) -> Result<AppConfig, String> {
    if source.get("config_version").and_then(Value::as_u64) != Some(7) {
        return Err("unsupported_source_config".into());
    }
    let mut target = source.as_object().cloned().ok_or("invalid_source_config")?;
    target.insert("config_version".into(), Value::from(CURRENT_CONFIG_VERSION));
    target.insert("theme_mode".into(), Value::from("light"));
    target.insert("desktop_companion_mode".into(), Value::from("mini"));
    target.insert("pet_window_position".into(), Value::Null);
    let config: AppConfig =
        serde_json::from_value(Value::Object(target)).map_err(|error| error.to_string())?;
    validate(&config)?;
    Ok(config)
}

pub fn migrate_v8(source: &Value) -> Result<AppConfig, String> {
    if source.get("config_version").and_then(Value::as_u64) != Some(8) {
        return Err("unsupported_source_config".into());
    }
    let mut target = source.as_object().cloned().ok_or("invalid_source_config")?;
    target.insert("config_version".into(), Value::from(CURRENT_CONFIG_VERSION));
    target
        .entry("theme_mode")
        .or_insert_with(|| Value::from("light"));
    target.insert("desktop_companion_mode".into(), Value::from("mini"));
    target.insert("pet_window_position".into(), Value::Null);
    let config: AppConfig =
        serde_json::from_value(Value::Object(target)).map_err(|error| error.to_string())?;
    validate(&config)?;
    Ok(config)
}

fn migrate_legacy_to_v8(source: &Value) -> Result<AppConfig, String> {
    let defaults = serde_json::to_value(AppConfig::default()).map_err(|error| error.to_string())?;
    let mut target = defaults.as_object().cloned().ok_or("invalid_defaults")?;
    let source_object = source.as_object().ok_or("invalid_source_config")?;
    for key in [
        "monthly_salary",
        "rest_mode",
        "alternating_anchor_date",
        "alternating_anchor_week_type",
        "work_hours_per_day",
        "work_start_time",
        "work_end_time",
        "lunch_start_time",
        "lunch_end_time",
        "mini_window_position",
        "mini_window_visible",
        "mini_window_always_on_top",
        "minimize_to_tray",
        "auto_start",
        "check_updates_on_start",
        "update_channel",
        "log_level",
    ] {
        if let Some(value) = source_object.get(key) {
            target.insert(key.into(), value.clone());
        }
    }
    target.insert("config_version".into(), Value::from(CURRENT_CONFIG_VERSION));
    target.insert("theme_mode".into(), Value::from("light"));
    target.insert(
        "calendar_dataset_version".into(),
        Value::from("cn-2025-2026-v1"),
    );
    target.insert("date_overrides".into(), Value::Array(Vec::new()));
    let mut config: AppConfig =
        serde_json::from_value(Value::Object(target)).map_err(|error| error.to_string())?;
    let legacy_overrides = source_object
        .get("date_overrides")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_default();
    let schedule = config.salary_schedule();
    for value in legacy_overrides {
        let object = value.as_object().ok_or("config.override_invalid")?;
        let date = object
            .get("date")
            .and_then(Value::as_str)
            .ok_or("config.override_invalid")?;
        domain::validate_date(date)?;
        let kind = object
            .get("kind")
            .and_then(Value::as_str)
            .ok_or("config.override_kind_unknown")?;
        let mapped = match kind {
            "workday" => Some(DateOverrideKind::Workday),
            "rest_day" => {
                let calendar = calendar_for_date(date)?;
                if domain::resolve_day_automatic(date, &schedule, &calendar)?.kind
                    == DayKind::Workday
                {
                    Some(DateOverrideKind::PaidRest)
                } else {
                    None
                }
            }
            _ => return Err("config.override_kind_unknown".into()),
        };
        if let Some(kind) = mapped {
            config.date_overrides.push(DateOverride {
                date: date.into(),
                kind,
                note: object
                    .get("note")
                    .and_then(Value::as_str)
                    .unwrap_or_default()
                    .into(),
            });
        }
    }
    config
        .date_overrides
        .sort_by(|left, right| left.date.cmp(&right.date));
    validate(&config)?;
    Ok(config)
}

pub fn migrate_to_current(source: &Value) -> Result<AppConfig, String> {
    match source.get("config_version").and_then(Value::as_u64) {
        Some(5) => migrate_v5(source),
        Some(6) => migrate_v6(source),
        Some(7) => migrate_v7(source),
        Some(8) => migrate_v8(source),
        _ => Err("unsupported_source_config".into()),
    }
}

fn calendar_for_date(date: &str) -> Result<CalendarData, String> {
    let year = date
        .get(0..4)
        .ok_or("invalid_date")?
        .parse::<i32>()
        .map_err(|_| "invalid_date")?;
    match calendar_data::load_calendar_year(year) {
        Ok(dataset) => Ok(dataset.calendar),
        Err(reason) if reason.starts_with("calendar_year_unsupported:") => {
            Ok(CalendarData::default())
        }
        Err(reason) => Err(reason),
    }
}

fn write_and_sync(path: &Path, bytes: &[u8]) -> Result<(), String> {
    let mut file = File::create(path).map_err(|error| format!("temp_write_failed:{error}"))?;
    file.write_all(bytes)
        .map_err(|error| format!("temp_write_failed:{error}"))?;
    file.sync_all()
        .map_err(|error| format!("temp_flush_failed:{error}"))
}

fn unique_backup_path(config_path: &Path) -> PathBuf {
    let stamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    config_path.with_file_name(format!("config.v1.0-compatible-backup.{stamp}.json"))
}

pub fn build_date_override_draft(
    current: &AppConfig,
    date: &str,
    kind: Option<DateOverrideKind>,
) -> Result<AppConfig, String> {
    let calendar = calendar_for_date(date)?;
    let entry = domain::apply_date_override(date, kind, &current.salary_schedule(), &calendar)?;
    let mut draft = current.clone();
    draft.date_overrides.retain(|item| item.date != date);
    if let Some(entry) = entry {
        draft.date_overrides.push(entry);
        draft
            .date_overrides
            .sort_by(|left, right| left.date.cmp(&right.date));
    }
    validate(&draft)?;
    Ok(draft)
}

pub fn save_date_override_transactional(
    config_path: &Path,
    current: &AppConfig,
    date: &str,
    kind: Option<DateOverrideKind>,
    fault: SaveFault,
) -> (SaveResult, AppConfig) {
    let draft = match build_date_override_draft(current, date, kind) {
        Ok(draft) => draft,
        Err(reason) => {
            return (
                SaveResult {
                    status: SaveStatus::Failed,
                    message: format!("日期调整失败：{reason}"),
                    draft_preserved: true,
                },
                current.clone(),
            )
        }
    };
    let result = save_transactional(config_path, current, &draft, fault);
    let runtime = if matches!(result.status, SaveStatus::Saved | SaveStatus::Unchanged) {
        draft
    } else {
        current.clone()
    };
    (result, runtime)
}

pub fn save_transactional(
    config_path: &Path,
    current: &AppConfig,
    draft: &AppConfig,
    fault: SaveFault,
) -> SaveResult {
    save_transactional_inner(config_path, current, draft, fault, false)
}

pub fn save_initial(config_path: &Path, current: &AppConfig, draft: &AppConfig) -> SaveResult {
    save_transactional_inner(config_path, current, draft, SaveFault::None, true)
}

fn save_transactional_inner(
    config_path: &Path,
    current: &AppConfig,
    draft: &AppConfig,
    fault: SaveFault,
    force_write: bool,
) -> SaveResult {
    if current == draft && !force_write {
        return SaveResult {
            status: SaveStatus::Unchanged,
            message: "没有需要保存的更改".into(),
            draft_preserved: true,
        };
    }
    if let Err(reason) = validate(draft) {
        return SaveResult {
            status: SaveStatus::Failed,
            message: format!("保存失败：{reason}"),
            draft_preserved: true,
        };
    }
    let bytes = match serde_json::to_vec_pretty(draft) {
        Ok(bytes) => bytes,
        Err(error) => {
            return SaveResult {
                status: SaveStatus::Failed,
                message: format!("保存失败：{error}"),
                draft_preserved: true,
            }
        }
    };
    let temp_path = config_path.with_extension("json.tmp");
    let previous_path = config_path.with_extension("json.previous");
    if fault == SaveFault::TempWriteDenied {
        return SaveResult {
            status: SaveStatus::Failed,
            message: "保存失败：配置目录不可写".into(),
            draft_preserved: true,
        };
    }
    if let Some(parent) = config_path.parent() {
        if let Err(error) = fs::create_dir_all(parent) {
            return SaveResult {
                status: SaveStatus::Failed,
                message: format!("保存失败：{error}"),
                draft_preserved: true,
            };
        }
    }
    if config_path.exists() {
        if let Err(error) = fs::copy(config_path, &previous_path) {
            return SaveResult {
                status: SaveStatus::Failed,
                message: format!("保存失败：无法建立回滚点：{error}"),
                draft_preserved: true,
            };
        }
    }
    let write_result = write_and_sync(&temp_path, &bytes).and_then(|_| {
        let read_back =
            fs::read(&temp_path).map_err(|error| format!("read_back_failed:{error}"))?;
        let parsed: AppConfig = serde_json::from_slice(&read_back)
            .map_err(|error| format!("read_back_failed:{error}"))?;
        validate(&parsed)?;
        fs::rename(&temp_path, config_path)
            .map_err(|error| format!("atomic_replace_failed:{error}"))
    });
    if let Err(reason) = write_result {
        let _ = fs::remove_file(&temp_path);
        return SaveResult {
            status: SaveStatus::Failed,
            message: format!("保存失败：{reason}"),
            draft_preserved: true,
        };
    }
    if fault == SaveFault::SideEffectDenied {
        if previous_path.exists() {
            let _ = fs::copy(&previous_path, config_path);
        }
        return SaveResult {
            status: SaveStatus::Failed,
            message: "保存失败：开机启动设置未能应用，配置已回滚".into(),
            draft_preserved: true,
        };
    }
    SaveResult {
        status: SaveStatus::Saved,
        message: "设置已保存".into(),
        draft_preserved: false,
    }
}

pub fn load_or_migrate(config_path: &Path) -> Result<AppConfig, String> {
    if !config_path.exists() {
        return Ok(AppConfig::default());
    }
    let bytes = fs::read(config_path).map_err(|error| error.to_string())?;
    let mut value: Value = serde_json::from_slice(&bytes).map_err(|error| error.to_string())?;
    match value.get("config_version").and_then(Value::as_u64) {
        Some(version) if version == u64::from(CURRENT_CONFIG_VERSION) => {
            let theme_valid = matches!(
                value.get("theme_mode").and_then(Value::as_str),
                Some("light" | "dark")
            );
            if !theme_valid {
                let backup = unique_backup_path(config_path);
                fs::copy(config_path, backup).map_err(|error| error.to_string())?;
                value
                    .as_object_mut()
                    .ok_or("invalid_source_config")?
                    .insert("theme_mode".into(), Value::from("light"));
            }
            let config: AppConfig =
                serde_json::from_value(value).map_err(|error| error.to_string())?;
            validate(&config)?;
            if !theme_valid {
                let current = AppConfig::default();
                let result = save_initial(config_path, &current, &config);
                if result.status != SaveStatus::Saved {
                    return Err(result.message);
                }
            }
            Ok(config)
        }
        Some(version) if MIGRATABLE_CONFIG_VERSIONS.contains(&version) => {
            let backup = unique_backup_path(config_path);
            fs::copy(config_path, backup).map_err(|error| error.to_string())?;
            let migrated = migrate_to_current(&value)?;
            let current = AppConfig::default();
            let result = save_initial(config_path, &current, &migrated);
            if result.status != SaveStatus::Saved {
                return Err(result.message);
            }
            Ok(migrated)
        }
        _ => Err("unsupported_config_version".into()),
    }
}

pub fn stored_config_version(config_path: &Path) -> Option<u64> {
    let bytes = fs::read(config_path).ok()?;
    let value: Value = serde_json::from_slice(&bytes).ok()?;
    value.get("config_version").and_then(Value::as_u64)
}

pub fn stored_theme_requires_fallback(config_path: &Path) -> bool {
    let Ok(bytes) = fs::read(config_path) else {
        return false;
    };
    let Ok(value) = serde_json::from_slice::<Value>(&bytes) else {
        return false;
    };
    value.get("config_version").and_then(Value::as_u64) == Some(u64::from(CURRENT_CONFIG_VERSION))
        && !matches!(
            value.get("theme_mode").and_then(Value::as_str),
            Some("light" | "dark")
        )
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde::Deserialize;

    #[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
    struct LegacyV103Config {
        config_version: u32,
        theme_mode: ThemeMode,
        monthly_salary: f64,
        rest_mode: RestMode,
        alternating_anchor_date: Option<String>,
        alternating_anchor_week_type: Option<WeekType>,
        work_hours_per_day: f64,
        work_start_time: String,
        work_end_time: String,
        lunch_start_time: String,
        lunch_end_time: String,
        calendar_dataset_version: String,
        date_overrides: Vec<DateOverride>,
        mini_window_position: Option<WindowPosition>,
        mini_window_visible: bool,
        mini_window_always_on_top: bool,
        minimize_to_tray: bool,
        auto_start: bool,
        check_updates_on_start: bool,
        update_channel: String,
        log_level: String,
    }

    #[test]
    fn configuration_version_contract_has_one_current_target() {
        assert_eq!(CURRENT_CONFIG_VERSION, 9);
        assert_eq!(MIGRATABLE_CONFIG_VERSIONS, &[5, 6, 7, 8]);
        assert_eq!(AppConfig::default().config_version, CURRENT_CONFIG_VERSION);
    }

    #[test]
    fn v8_migrates_to_mini_without_changing_existing_window_preferences() {
        let mut source = serde_json::to_value(AppConfig::default()).unwrap();
        let object = source.as_object_mut().unwrap();
        object.insert("config_version".into(), Value::from(8));
        object.remove("desktop_companion_mode");
        object.remove("pet_window_position");
        object.insert("mini_window_visible".into(), Value::from(false));
        object.insert("mini_window_always_on_top".into(), Value::from(false));
        object.insert(
            "mini_window_position".into(),
            serde_json::json!({"x": 120.0, "y": 240.0}),
        );

        let migrated = migrate_to_current(&source).expect("v8 must migrate to v9");

        assert_eq!(migrated.config_version, 9);
        assert_eq!(migrated.desktop_companion_mode, DesktopCompanionMode::Mini);
        assert_eq!(migrated.pet_window_position, None);
        assert!(!migrated.mini_window_visible);
        assert!(!migrated.mini_window_always_on_top);
        assert_eq!(
            migrated.mini_window_position,
            Some(WindowPosition { x: 120.0, y: 240.0 })
        );
    }

    #[test]
    fn migration_dispatcher_accepts_every_declared_legacy_version() {
        for version in MIGRATABLE_CONFIG_VERSIONS {
            let mut source =
                serde_json::to_value(AppConfig::default()).expect("defaults must serialize");
            source
                .as_object_mut()
                .expect("defaults must be an object")
                .insert("config_version".into(), Value::from(*version));
            source.as_object_mut().unwrap().remove("theme_mode");

            let migrated = migrate_to_current(&source)
                .unwrap_or_else(|error| panic!("version {version} failed: {error}"));
            assert_eq!(migrated.config_version, CURRENT_CONFIG_VERSION);
        }
    }

    fn temp_config(name: &str) -> PathBuf {
        let root = std::env::temp_dir().join(format!(
            "lmm-v10-{name}-{}",
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        fs::create_dir_all(&root).unwrap();
        root.join("config.json")
    }

    #[test]
    fn migration_drops_pet_fields() {
        let source: Value = serde_json::json!({
            "config_version": 5,
            "monthly_salary": 10000,
            "rest_mode": "double",
            "work_hours_per_day": 8,
            "work_start_time": "08:00",
            "work_end_time": "18:00",
            "lunch_start_time": "12:00",
            "lunch_end_time": "14:00",
            "pet_id": "classic_pro",
            "pet_package_id": "classic_pro",
            "pet_package_version": "s5.5",
            "pure_pet_mode": true,
            "pet_scale": 1.25,
            "click_through": true
        });
        let migrated = migrate_v5(&source).unwrap();
        let text = serde_json::to_string(&migrated).unwrap();
        assert_eq!(migrated.config_version, 9);
        assert_eq!(migrated.desktop_companion_mode, DesktopCompanionMode::Mini);
        assert_eq!(migrated.theme_mode, ThemeMode::Light);
        for retired_key in [
            "pet_id",
            "pet_package_id",
            "pet_package_version",
            "pure_pet_mode",
            "pet_scale",
            "click_through",
        ] {
            assert!(!text.contains(retired_key));
        }
    }

    #[test]
    fn failed_writes_preserve_old_config_and_draft() {
        let path = temp_config("save");
        let current = AppConfig::default();
        fs::write(&path, serde_json::to_vec_pretty(&current).unwrap()).unwrap();
        let mut draft = current.clone();
        draft.monthly_salary = 12_000.0;
        let result = save_transactional(&path, &current, &draft, SaveFault::TempWriteDenied);
        assert_eq!(result.status, SaveStatus::Failed);
        assert!(result.draft_preserved);
        assert_eq!(load_or_migrate(&path).unwrap(), current);

        let result = save_transactional(&path, &current, &draft, SaveFault::SideEffectDenied);
        assert_eq!(result.status, SaveStatus::Failed);
        assert_eq!(load_or_migrate(&path).unwrap(), current);
    }

    #[test]
    fn unchanged_and_success_are_distinct() {
        let path = temp_config("unchanged");
        let current = AppConfig::default();
        assert_eq!(
            save_transactional(&path, &current, &current, SaveFault::None).status,
            SaveStatus::Unchanged
        );
        let mut draft = current.clone();
        draft.monthly_salary = 10_000.0;
        assert_eq!(
            save_transactional(&path, &current, &draft, SaveFault::None).status,
            SaveStatus::Saved
        );
        assert_eq!(load_or_migrate(&path).unwrap(), draft);
    }

    #[test]
    fn initial_save_writes_default_configuration() {
        let path = temp_config("initial");
        let current = AppConfig::default();
        let result = save_initial(&path, &current, &current);
        assert_eq!(result.status, SaveStatus::Saved);
        assert!(path.is_file());
        assert_eq!(load_or_migrate(&path).unwrap(), current);
    }

    #[test]
    fn v6_rest_overrides_migrate_by_automatic_day_kind() {
        let source = serde_json::json!({
            "config_version": 6,
            "monthly_salary": 10000,
            "rest_mode": "double",
            "alternating_anchor_date": null,
            "alternating_anchor_week_type": null,
            "work_hours_per_day": 8,
            "work_start_time": "08:00",
            "work_end_time": "18:00",
            "lunch_start_time": "12:00",
            "lunch_end_time": "14:00",
            "calendar_dataset_version": "cn-2026",
            "date_overrides": [
                {"date": "2026-07-24", "kind": "rest_day"},
                {"date": "2026-07-26", "kind": "rest_day"},
                {"date": "2026-07-25", "kind": "workday"}
            ],
            "mini_window_position": null,
            "mini_window_visible": true,
            "mini_window_always_on_top": true,
            "minimize_to_tray": true,
            "auto_start": false,
            "check_updates_on_start": true,
            "update_channel": "stable",
            "log_level": "info"
        });

        let migrated = migrate_v6(&source).expect("v6 config should migrate");
        assert_eq!(migrated.config_version, 9);
        assert_eq!(migrated.date_overrides.len(), 2);
        assert!(migrated.date_overrides.iter().any(|entry| {
            entry.date == "2026-07-24" && entry.kind == crate::domain::DateOverrideKind::PaidRest
        }));
        assert!(migrated.date_overrides.iter().any(|entry| {
            entry.date == "2026-07-25" && entry.kind == crate::domain::DateOverrideKind::Workday
        }));
    }

    #[test]
    fn v6_unknown_override_kind_is_backed_up_and_rejected() {
        let path = temp_config("unknown-override");
        let source = serde_json::json!({
            "config_version": 6,
            "monthly_salary": 10000,
            "rest_mode": "double",
            "alternating_anchor_date": null,
            "alternating_anchor_week_type": null,
            "work_hours_per_day": 8,
            "work_start_time": "08:00",
            "work_end_time": "18:00",
            "lunch_start_time": "12:00",
            "lunch_end_time": "14:00",
            "calendar_dataset_version": "cn-2026",
            "date_overrides": [{"date": "2026-07-24", "kind": "mystery"}],
            "mini_window_position": null,
            "mini_window_visible": true,
            "mini_window_always_on_top": true,
            "minimize_to_tray": true,
            "auto_start": false,
            "check_updates_on_start": true,
            "update_channel": "stable",
            "log_level": "info"
        });
        fs::write(&path, serde_json::to_vec_pretty(&source).unwrap()).unwrap();

        assert_eq!(
            load_or_migrate(&path).unwrap_err(),
            "config.override_kind_unknown"
        );
        assert!(path.parent().unwrap().read_dir().unwrap().any(|entry| {
            entry
                .unwrap()
                .file_name()
                .to_string_lossy()
                .starts_with("config.v1.0-compatible-backup.")
        }));
    }

    #[test]
    fn date_override_transaction_preserves_old_config_on_failure() {
        let path = temp_config("date-override-failure");
        let current = AppConfig::default();
        fs::write(&path, serde_json::to_vec_pretty(&current).unwrap()).unwrap();

        let (result, next) = save_date_override_transactional(
            &path,
            &current,
            "2026-07-24",
            Some(crate::domain::DateOverrideKind::PaidRest),
            SaveFault::TempWriteDenied,
        );

        assert_eq!(result.status, SaveStatus::Failed);
        assert!(result.draft_preserved);
        assert_eq!(next, current);
        assert_eq!(load_or_migrate(&path).unwrap(), current);
    }

    #[test]
    fn v7_migrates_to_light_theme_without_losing_user_data() {
        let source: Value =
            serde_json::from_str(include_str!("../../contracts/config-v101-defaults.json"))
                .unwrap();
        let mut source = source.as_object().unwrap().clone();
        source.insert("monthly_salary".into(), Value::from(12_345.67));
        let migrated = migrate_v7(&Value::Object(source)).unwrap();
        assert_eq!(migrated.config_version, 9);
        assert_eq!(migrated.theme_mode, ThemeMode::Light);
        assert_eq!(migrated.monthly_salary, 12_345.67);
    }

    #[test]
    fn invalid_v8_theme_falls_back_and_is_persisted() {
        let path = temp_config("invalid-theme");
        let mut source = serde_json::to_value(AppConfig::default()).unwrap();
        source
            .as_object_mut()
            .unwrap()
            .insert("theme_mode".into(), Value::from("midnight"));
        fs::write(&path, serde_json::to_vec_pretty(&source).unwrap()).unwrap();

        assert!(stored_theme_requires_fallback(&path));
        let loaded = load_or_migrate(&path).unwrap();
        assert_eq!(loaded.theme_mode, ThemeMode::Light);
        assert!(!stored_theme_requires_fallback(&path));
        let persisted: AppConfig = serde_json::from_slice(&fs::read(path).unwrap()).unwrap();
        assert_eq!(persisted.theme_mode, ThemeMode::Light);
    }

    #[test]
    fn v103_reader_and_writer_safely_drop_v104_optional_window_fields() {
        let fixture: Value = serde_json::from_str(include_str!(
            "../../tests/fixtures/v104-config-compatibility.json"
        ))
        .expect("v1.0.4 compatibility fixture must parse");
        let source = fixture
            .get("config")
            .cloned()
            .expect("fixture config must exist");
        let legacy: LegacyV103Config = serde_json::from_value(source.clone())
            .expect("v1.0.3 reader must accept v1.0.4 fields");

        assert_eq!(legacy.config_version, 8);
        assert_eq!(legacy.theme_mode, ThemeMode::Dark);
        assert_eq!(legacy.monthly_salary, 12_345.67);
        assert_eq!(legacy.work_start_time, "09:00");
        assert_eq!(legacy.work_end_time, "18:00");
        assert_eq!(
            legacy.mini_window_position,
            Some(WindowPosition { x: 640.5, y: 88.25 })
        );

        let saved = serde_json::to_value(&legacy).expect("v1.0.3 writer must serialize");
        assert!(saved.get("mini_edge_auto_hide").is_none());
        assert!(saved.get("mini_edge_dock").is_none());
        for key in [
            "config_version",
            "theme_mode",
            "monthly_salary",
            "work_start_time",
            "work_end_time",
            "mini_window_position",
        ] {
            assert_eq!(saved.get(key), source.get(key), "legacy field drift: {key}");
        }

        let decision = fixture
            .get("decision")
            .expect("fixture decision must exist");
        assert_eq!(
            decision.get("storage").and_then(Value::as_str),
            Some("config_v8_optional_fields")
        );
        assert_eq!(
            decision
                .get("window_state_json_required")
                .and_then(Value::as_bool),
            Some(false)
        );
    }

    #[test]
    fn v104_missing_edge_fields_use_privacy_safe_defaults() {
        let mut source = serde_json::to_value(AppConfig::default()).unwrap();
        let object = source.as_object_mut().unwrap();
        object.remove("mini_edge_auto_hide");
        object.remove("mini_edge_dock");

        let loaded: AppConfig = serde_json::from_value(source).unwrap();
        assert!(loaded.mini_edge_auto_hide);
        assert_eq!(loaded.mini_edge_dock, MiniEdgeDock::None);
    }

    #[test]
    fn v104_unknown_edge_side_falls_back_to_none() {
        let mut source = serde_json::to_value(AppConfig::default()).unwrap();
        source
            .as_object_mut()
            .unwrap()
            .insert("mini_edge_dock".into(), Value::from("top"));

        let loaded: AppConfig = serde_json::from_value(source).unwrap();
        assert_eq!(loaded.mini_edge_dock, MiniEdgeDock::None);
    }
}
