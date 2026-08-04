use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use serde::Deserialize;

use crate::models::overtime::{
    validate_store, OvertimeOrigin, OvertimeRecord, OvertimeStore, OvertimeStoreError,
    LEGACY_OVERTIME_SCHEMA_VERSION, OVERTIME_SCHEMA_VERSION,
};

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct LegacyOvertimeRecord {
    business_date: String,
    minutes: u16,
    hourly_rate_fen_snapshot: i64,
    created_at: String,
    updated_at: String,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct LegacyOvertimeStore {
    schema_version: u8,
    records: Vec<LegacyOvertimeRecord>,
}

pub trait OvertimeRepository {
    fn load(&self) -> Result<OvertimeStore, OvertimeStoreError>;
    fn save(&self, store: &OvertimeStore) -> Result<(), OvertimeStoreError>;
    fn recover_corrupt(&self) -> Result<PathBuf, OvertimeStoreError>;
}

pub struct FileOvertimeRepository {
    store_path: PathBuf,
}

impl FileOvertimeRepository {
    pub fn new(store_path: impl Into<PathBuf>) -> Self {
        Self {
            store_path: store_path.into(),
        }
    }

    fn previous_path(&self) -> PathBuf {
        self.store_path.with_extension("json.previous")
    }

    fn temp_path(&self) -> PathBuf {
        self.store_path.with_extension("json.tmp")
    }

    fn swap_path(&self) -> PathBuf {
        self.store_path.with_extension("json.swap")
    }

    fn corrupt_backup_path(&self) -> PathBuf {
        self.store_path.with_extension("json.corrupt-backup")
    }

    fn unique_corrupt_backup_path(&self) -> PathBuf {
        let stamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        self.store_path
            .with_file_name(format!("overtime-records.corrupt-backup.{stamp}.json"))
    }

    fn preserve_corrupt_evidence(&self) {
        let backup = self.corrupt_backup_path();
        if self.store_path.is_file() && !backup.exists() {
            let _ = fs::copy(&self.store_path, backup);
        }
    }

    fn parse_bytes(&self, bytes: &[u8]) -> Result<OvertimeStore, OvertimeStoreError> {
        let schema_version = serde_json::from_slice::<serde_json::Value>(bytes)
            .ok()
            .and_then(|value| value.get("schema_version").and_then(|value| value.as_u64()))
            .and_then(|value| u8::try_from(value).ok())
            .ok_or_else(|| {
                OvertimeStoreError::new("overtime_store_corrupt", "missing schema_version")
            })?;
        let parsed = match schema_version {
            OVERTIME_SCHEMA_VERSION => serde_json::from_slice(bytes).map_err(|error| {
                OvertimeStoreError::new("overtime_store_corrupt", error.to_string())
            })?,
            LEGACY_OVERTIME_SCHEMA_VERSION => {
                let legacy: LegacyOvertimeStore =
                    serde_json::from_slice(bytes).map_err(|error| {
                        OvertimeStoreError::new("overtime_store_corrupt", error.to_string())
                    })?;
                if legacy.schema_version != LEGACY_OVERTIME_SCHEMA_VERSION {
                    return Err(OvertimeStoreError::new(
                        "overtime_store_corrupt",
                        "legacy schema version mismatch",
                    ));
                }
                OvertimeStore {
                    schema_version: OVERTIME_SCHEMA_VERSION,
                    records: legacy
                        .records
                        .into_iter()
                        .map(|record| OvertimeRecord {
                            business_date: record.business_date,
                            minutes: record.minutes,
                            hourly_rate_fen_snapshot: record.hourly_rate_fen_snapshot,
                            origin: OvertimeOrigin::Independent,
                            boundary_snapshot: None,
                            linked_override_date: None,
                            created_at: record.created_at,
                            updated_at: record.updated_at,
                        })
                        .collect(),
                }
            }
            _ => {
                return Err(OvertimeStoreError::new(
                    "overtime_store_corrupt",
                    format!("unsupported overtime schema: {schema_version}"),
                ))
            }
        };
        validate_store(&parsed)
            .map_err(|error| OvertimeStoreError::new("overtime_store_corrupt", error.message))?;
        Ok(parsed)
    }
}

fn write_and_sync(path: &Path, bytes: &[u8]) -> Result<(), OvertimeStoreError> {
    let mut file = File::create(path).map_err(|error| {
        OvertimeStoreError::new("overtime_temp_write_failed", error.to_string())
    })?;
    file.write_all(bytes).map_err(|error| {
        OvertimeStoreError::new("overtime_temp_write_failed", error.to_string())
    })?;
    file.sync_all()
        .map_err(|error| OvertimeStoreError::new("overtime_temp_flush_failed", error.to_string()))
}

impl OvertimeRepository for FileOvertimeRepository {
    fn load(&self) -> Result<OvertimeStore, OvertimeStoreError> {
        if !self.store_path.exists() {
            return Ok(OvertimeStore::default());
        }
        let bytes = fs::read(&self.store_path).map_err(|error| {
            OvertimeStoreError::new("overtime_store_read_failed", error.to_string())
        })?;
        match self.parse_bytes(&bytes) {
            Ok(store) => Ok(store),
            Err(error) => {
                self.preserve_corrupt_evidence();
                Err(error)
            }
        }
    }

    fn save(&self, store: &OvertimeStore) -> Result<(), OvertimeStoreError> {
        validate_store(store)?;
        if self.store_path.exists() {
            self.load()?;
        }
        if let Some(parent) = self.store_path.parent() {
            fs::create_dir_all(parent).map_err(|error| {
                OvertimeStoreError::new("overtime_directory_failed", error.to_string())
            })?;
        }
        let bytes = serde_json::to_vec_pretty(store).map_err(|error| {
            OvertimeStoreError::new("overtime_serialize_failed", error.to_string())
        })?;
        let temp_path = self.temp_path();
        let previous_path = self.previous_path();
        let swap_path = self.swap_path();
        let _ = fs::remove_file(&temp_path);
        let _ = fs::remove_file(&swap_path);
        write_and_sync(&temp_path, &bytes)?;
        let read_back = fs::read(&temp_path).map_err(|error| {
            OvertimeStoreError::new("overtime_read_back_failed", error.to_string())
        })?;
        self.parse_bytes(&read_back).map_err(|_| {
            OvertimeStoreError::new("overtime_read_back_failed", "临时文件校验失败")
        })?;

        if self.store_path.exists() {
            fs::copy(&self.store_path, &previous_path).map_err(|error| {
                OvertimeStoreError::new("overtime_backup_failed", error.to_string())
            })?;
            fs::rename(&self.store_path, &swap_path).map_err(|error| {
                OvertimeStoreError::new("overtime_atomic_replace_failed", error.to_string())
            })?;
        }
        if let Err(error) = fs::rename(&temp_path, &self.store_path) {
            if swap_path.exists() {
                let _ = fs::rename(&swap_path, &self.store_path);
            }
            let _ = fs::remove_file(&temp_path);
            return Err(OvertimeStoreError::new(
                "overtime_atomic_replace_failed",
                error.to_string(),
            ));
        }
        let _ = fs::remove_file(&swap_path);
        Ok(())
    }

    fn recover_corrupt(&self) -> Result<PathBuf, OvertimeStoreError> {
        if !self.store_path.exists() {
            return Err(OvertimeStoreError::new(
                "overtime_recovery_not_required",
                "没有需要恢复的加班数据",
            ));
        }
        if self.load().is_ok() {
            return Err(OvertimeStoreError::new(
                "overtime_recovery_not_required",
                "加班数据无需恢复",
            ));
        }
        let backup = self.unique_corrupt_backup_path();
        fs::rename(&self.store_path, &backup).map_err(|error| {
            OvertimeStoreError::new("overtime_recovery_backup_failed", error.to_string())
        })?;
        if let Err(error) = self.save(&OvertimeStore::default()) {
            let _ = fs::rename(&backup, &self.store_path);
            return Err(error);
        }
        Ok(backup)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::overtime::{
        OvertimeBoundaryBasis, OvertimeBoundarySnapshot, OvertimeCalendarSource, OvertimeRecord,
        OVERTIME_MAX_MINUTES,
    };

    fn temp_store(name: &str) -> PathBuf {
        std::env::temp_dir().join(format!(
            "lmm-overtime-{name}-{}-{}.json",
            std::process::id(),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap_or_default()
                .as_nanos()
        ))
    }

    fn populated() -> OvertimeStore {
        OvertimeStore {
            schema_version: OVERTIME_SCHEMA_VERSION,
            records: vec![OvertimeRecord {
                business_date: "2026-08-03".into(),
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
            }],
        }
    }

    #[test]
    fn save_load_and_previous_backup_are_transactional() {
        let path = temp_store("transaction");
        let repository = FileOvertimeRepository::new(&path);
        repository.save(&OvertimeStore::default()).unwrap();
        repository.save(&populated()).unwrap();
        assert_eq!(repository.load().unwrap(), populated());
        assert!(path.with_extension("json.previous").is_file());
        let _ = fs::remove_file(path);
    }

    #[test]
    fn corrupt_store_is_preserved_and_never_silently_overwritten() {
        let path = temp_store("corrupt");
        fs::write(&path, b"{broken").unwrap();
        let repository = FileOvertimeRepository::new(&path);
        assert!(repository.load().unwrap_err().is_corrupt());
        assert!(path.with_extension("json.corrupt-backup").is_file());
        assert!(repository.save(&populated()).unwrap_err().is_corrupt());
        assert_eq!(fs::read(&path).unwrap(), b"{broken");
        let recovered_backup = repository.recover_corrupt().unwrap();
        assert!(recovered_backup.is_file());
        assert_eq!(repository.load().unwrap(), OvertimeStore::default());
        let _ = fs::remove_file(path);
        let _ = fs::remove_file(recovered_backup);
    }

    #[test]
    fn legacy_v1_records_migrate_in_memory_without_clipping_or_rate_changes() {
        let path = temp_store("legacy-v1");
        fs::write(
            &path,
            br#"{
              "schema_version": 1,
              "records": [{
                "business_date": "2026-08-03",
                "minutes": 1440,
                "hourly_rate_fen_snapshot": 6250,
                "created_at": "2026-08-03T11:30:00Z",
                "updated_at": "2026-08-03T11:30:00Z"
              }]
            }"#,
        )
        .unwrap();
        let repository = FileOvertimeRepository::new(&path);

        let migrated = repository.load().unwrap();
        assert_eq!(migrated.schema_version, OVERTIME_SCHEMA_VERSION);
        assert_eq!(migrated.records[0].minutes, 1_440);
        assert_eq!(migrated.records[0].hourly_rate_fen_snapshot, 6_250);
        assert_eq!(migrated.records[0].origin, OvertimeOrigin::Independent);
        assert!(migrated.records[0].boundary_snapshot.is_none());
        assert!(migrated.records[0].linked_override_date.is_none());

        repository.save(&migrated).unwrap();
        let persisted: serde_json::Value =
            serde_json::from_slice(&fs::read(&path).unwrap()).unwrap();
        assert_eq!(persisted["schema_version"], OVERTIME_SCHEMA_VERSION);
        let _ = fs::remove_file(path);
    }
}
