use crate::domain::{DateOverride, RestMode, WeekType};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct WindowPosition {
    pub x: f64,
    pub y: f64,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct AppConfig {
    pub config_version: u32,
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
    pub mini_window_position: Option<WindowPosition>,
    pub mini_window_visible: bool,
    pub mini_window_always_on_top: bool,
    pub minimize_to_tray: bool,
    pub auto_start: bool,
    pub check_updates_on_start: bool,
    pub update_channel: String,
    pub log_level: String,
}

impl Default for AppConfig {
    fn default() -> Self {
        serde_json::from_str(include_str!("../../contracts/config-defaults.json"))
            .expect("embedded config defaults must remain valid")
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
    if config.config_version != 6 {
        return Err("unsupported_config_version".into());
    }
    if !config.monthly_salary.is_finite() || config.monthly_salary < 0.0 {
        return Err("invalid_monthly_salary".into());
    }
    if !(0.0..=24.0).contains(&config.work_hours_per_day)
        || config.work_hours_per_day == 0.0
    {
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
        "date_overrides",
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
    target.insert("config_version".into(), Value::from(6));
    let config: AppConfig =
        serde_json::from_value(Value::Object(target)).map_err(|error| error.to_string())?;
    validate(&config)?;
    Ok(config)
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
    config_path.with_file_name(format!("config.v0.9-compatible-backup.{stamp}.json"))
}

pub fn save_transactional(
    config_path: &Path,
    current: &AppConfig,
    draft: &AppConfig,
    fault: SaveFault,
) -> SaveResult {
    save_transactional_inner(config_path, current, draft, fault, false)
}

pub fn save_initial(
    config_path: &Path,
    current: &AppConfig,
    draft: &AppConfig,
) -> SaveResult {
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
        let read_back = fs::read(&temp_path).map_err(|error| format!("read_back_failed:{error}"))?;
        let parsed: AppConfig =
            serde_json::from_slice(&read_back).map_err(|error| format!("read_back_failed:{error}"))?;
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
    let value: Value = serde_json::from_slice(&bytes).map_err(|error| error.to_string())?;
    match value.get("config_version").and_then(Value::as_u64) {
        Some(6) => {
            let config: AppConfig = serde_json::from_value(value).map_err(|error| error.to_string())?;
            validate(&config)?;
            Ok(config)
        }
        Some(5) => {
            let migrated = migrate_v5(&value)?;
            let backup = unique_backup_path(config_path);
            fs::copy(config_path, backup).map_err(|error| error.to_string())?;
            let current = AppConfig::default();
            let result = save_transactional(config_path, &current, &migrated, SaveFault::None);
            if result.status != SaveStatus::Saved {
                return Err(result.message);
            }
            Ok(migrated)
        }
        _ => Err("unsupported_config_version".into()),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

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
        assert_eq!(migrated.config_version, 6);
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
}
