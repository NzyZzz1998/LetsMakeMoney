use std::fs::{self, File};
use std::io::Write;
use std::path::Path;
use std::sync::Mutex;

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::config::{self, AppConfig};
use crate::domain::DateOverrideKind;
use crate::models::overtime::{
    now_rfc3339, validate_store, OvertimeBoundaryBasis, OvertimeBoundarySnapshot,
    OvertimeCalendarSource, OvertimeOrigin, OvertimeRecord, OvertimeStore, SaveOvertimeRequest,
    OVERTIME_MAX_MINUTES,
};
use crate::repositories::overtime_repository::OvertimeRepository;

const JOURNAL_FILE: &str = "date-overtime-transaction.json";

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "snake_case", tag = "action")]
pub enum LinkedOvertimeAction {
    Keep,
    Delete,
    Upsert { request: SaveOvertimeRequest },
}

#[derive(Clone, Debug, Deserialize)]
pub struct DateOvertimeTransactionRequest {
    pub date: String,
    pub kind: Option<DateOverrideKind>,
    pub overtime: LinkedOvertimeAction,
}

#[derive(Clone, Debug, Serialize)]
pub struct DateOvertimeTransactionResponse {
    pub status: &'static str,
    pub message: String,
    pub draft_preserved: bool,
    pub overtime_changed: bool,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct TransactionJournal {
    state: String,
    date: String,
    had_config: bool,
    had_overtime: bool,
    config_sha256: String,
    overtime_sha256: String,
}

pub fn execute(
    data_dir: &Path,
    runtime: &Mutex<AppConfig>,
    overtime_repository: &impl OvertimeRepository,
    request: DateOvertimeTransactionRequest,
) -> Result<DateOvertimeTransactionResponse, String> {
    let mut current = runtime.lock().map_err(|_| "config_lock_failed")?;
    let next_config = config::build_date_override_draft(&current, &request.date, request.kind)?;
    let mut next_overtime = overtime_repository
        .load()
        .map_err(|error| format!("{}:{}", error.code, error.message))?;
    let overtime_changed = apply_overtime_action(&mut next_overtime, &request)?;
    validate_store(&next_overtime).map_err(|error| format!("{}:{}", error.code, error.message))?;

    let config_changed = next_config != *current;
    if !config_changed && !overtime_changed {
        return Ok(DateOvertimeTransactionResponse {
            status: "unchanged",
            message: "日期与关联加班没有变化".into(),
            draft_preserved: true,
            overtime_changed: false,
        });
    }

    fs::create_dir_all(data_dir)
        .map_err(|error| format!("transaction_directory_failed:{error}"))?;
    let config_path = data_dir.join("config.json");
    let overtime_path = data_dir.join("overtime-records.json");
    let config_temp = data_dir.join("config.json.date-overtime.tmp");
    let overtime_temp = data_dir.join("overtime-records.json.date-overtime.tmp");
    let config_swap = data_dir.join("config.json.date-overtime.swap");
    let overtime_swap = data_dir.join("overtime-records.json.date-overtime.swap");
    let journal_path = data_dir.join(JOURNAL_FILE);

    cleanup_path(&config_temp);
    cleanup_path(&overtime_temp);
    cleanup_path(&config_swap);
    cleanup_path(&overtime_swap);

    let config_bytes = serde_json::to_vec_pretty(&next_config)
        .map_err(|error| format!("transaction_config_serialize_failed:{error}"))?;
    let overtime_bytes = serde_json::to_vec_pretty(&next_overtime)
        .map_err(|error| format!("transaction_overtime_serialize_failed:{error}"))?;
    write_synced(&config_temp, &config_bytes)?;
    write_synced(&overtime_temp, &overtime_bytes)?;
    validate_temp_files(&config_temp, &overtime_temp)?;

    let mut journal = TransactionJournal {
        state: "prepared".into(),
        date: request.date.clone(),
        had_config: config_path.is_file(),
        had_overtime: overtime_path.is_file(),
        config_sha256: sha256(&config_bytes),
        overtime_sha256: sha256(&overtime_bytes),
    };
    write_journal(&journal_path, &journal)?;

    if journal.had_config {
        fs::rename(&config_path, &config_swap)
            .map_err(|error| format!("transaction_config_stage_failed:{error}"))?;
    }
    if journal.had_overtime {
        if let Err(error) = fs::rename(&overtime_path, &overtime_swap) {
            rollback_file(&config_path, &config_swap, journal.had_config);
            return Err(format!("transaction_overtime_stage_failed:{error}"));
        }
    }
    if let Err(error) = fs::rename(&config_temp, &config_path) {
        rollback_files(
            &config_path,
            &config_swap,
            journal.had_config,
            &overtime_path,
            &overtime_swap,
            journal.had_overtime,
        );
        return Err(format!("transaction_config_commit_failed:{error}"));
    }
    if let Err(error) = fs::rename(&overtime_temp, &overtime_path) {
        rollback_files(
            &config_path,
            &config_swap,
            journal.had_config,
            &overtime_path,
            &overtime_swap,
            journal.had_overtime,
        );
        return Err(format!("transaction_overtime_commit_failed:{error}"));
    }

    journal.state = "committed".into();
    write_journal(&journal_path, &journal)?;
    cleanup_path(&config_swap);
    cleanup_path(&overtime_swap);
    cleanup_path(&journal_path);
    *current = next_config;

    Ok(DateOvertimeTransactionResponse {
        status: "saved",
        message: "日期与关联加班已保存".into(),
        draft_preserved: false,
        overtime_changed,
    })
}

pub fn recover_pending(data_dir: &Path) -> Result<Option<String>, String> {
    let journal_path = data_dir.join(JOURNAL_FILE);
    if !journal_path.is_file() {
        return Ok(None);
    }
    let journal: TransactionJournal = serde_json::from_slice(
        &fs::read(&journal_path)
            .map_err(|error| format!("transaction_journal_read_failed:{error}"))?,
    )
    .map_err(|error| format!("transaction_journal_invalid:{error}"))?;
    let config_path = data_dir.join("config.json");
    let overtime_path = data_dir.join("overtime-records.json");
    let config_swap = data_dir.join("config.json.date-overtime.swap");
    let overtime_swap = data_dir.join("overtime-records.json.date-overtime.swap");
    if journal.state == "prepared" {
        rollback_files(
            &config_path,
            &config_swap,
            journal.had_config,
            &overtime_path,
            &overtime_swap,
            journal.had_overtime,
        );
    } else {
        cleanup_path(&config_swap);
        cleanup_path(&overtime_swap);
    }
    cleanup_path(&data_dir.join("config.json.date-overtime.tmp"));
    cleanup_path(&data_dir.join("overtime-records.json.date-overtime.tmp"));
    cleanup_path(&journal_path);
    Ok(Some(journal.state))
}

fn apply_overtime_action(
    store: &mut OvertimeStore,
    transaction: &DateOvertimeTransactionRequest,
) -> Result<bool, String> {
    match &transaction.overtime {
        LinkedOvertimeAction::Keep => {
            if transaction.kind == Some(DateOverrideKind::Workday) {
                return Ok(false);
            }
            let Some(existing) = store.records.iter_mut().find(|record| {
                record.business_date == transaction.date
                    && record.linked_override_date.as_deref() == Some(transaction.date.as_str())
            }) else {
                return Ok(false);
            };
            existing.origin = OvertimeOrigin::Independent;
            existing.linked_override_date = None;
            existing.boundary_snapshot = Some(OvertimeBoundarySnapshot {
                basis: OvertimeBoundaryBasis::RestDayCap,
                current_shift_end: None,
                next_actual_work_start: None,
                maximum_minutes: OVERTIME_MAX_MINUTES,
                calendar_source: OvertimeCalendarSource::Manual,
            });
            existing.updated_at =
                now_rfc3339().map_err(|error| format!("{}:{}", error.code, error.message))?;
            Ok(true)
        }
        LinkedOvertimeAction::Delete => {
            let before = store.records.len();
            store.records.retain(|record| {
                !(record.business_date == transaction.date
                    && record.linked_override_date.as_deref() == Some(transaction.date.as_str()))
            });
            Ok(before != store.records.len())
        }
        LinkedOvertimeAction::Upsert { request } => {
            if request.business_date != transaction.date
                || request.origin != OvertimeOrigin::ManualWeekendWork
                || request.linked_override_date.as_deref() != Some(transaction.date.as_str())
                || request.boundary_snapshot.is_none()
                || request.minutes == 0
            {
                return Err("date_overtime_link_invalid".into());
            }
            let now = now_rfc3339().map_err(|error| format!("{}:{}", error.code, error.message))?;
            if let Some(existing) = store
                .records
                .iter_mut()
                .find(|record| record.business_date == transaction.date)
            {
                let changed = existing.minutes != request.minutes
                    || existing.origin != request.origin
                    || existing.boundary_snapshot != request.boundary_snapshot
                    || existing.linked_override_date != request.linked_override_date;
                if changed {
                    existing.minutes = request.minutes;
                    existing.origin = request.origin;
                    existing.boundary_snapshot = request.boundary_snapshot.clone();
                    existing.linked_override_date = request.linked_override_date.clone();
                    existing.updated_at = now;
                }
                return Ok(changed);
            }
            store.records.push(OvertimeRecord {
                business_date: request.business_date.clone(),
                minutes: request.minutes,
                hourly_rate_fen_snapshot: request.hourly_rate_fen_snapshot,
                origin: request.origin,
                boundary_snapshot: request.boundary_snapshot.clone(),
                linked_override_date: request.linked_override_date.clone(),
                created_at: now.clone(),
                updated_at: now,
            });
            store
                .records
                .sort_by(|left, right| left.business_date.cmp(&right.business_date));
            Ok(true)
        }
    }
}

fn validate_temp_files(config_path: &Path, overtime_path: &Path) -> Result<(), String> {
    let config: AppConfig = serde_json::from_slice(
        &fs::read(config_path).map_err(|error| format!("transaction_readback_failed:{error}"))?,
    )
    .map_err(|error| format!("transaction_config_readback_invalid:{error}"))?;
    config::validate(&config)?;
    let overtime: OvertimeStore = serde_json::from_slice(
        &fs::read(overtime_path).map_err(|error| format!("transaction_readback_failed:{error}"))?,
    )
    .map_err(|error| format!("transaction_overtime_readback_invalid:{error}"))?;
    validate_store(&overtime).map_err(|error| format!("{}:{}", error.code, error.message))
}

fn write_journal(path: &Path, journal: &TransactionJournal) -> Result<(), String> {
    let bytes = serde_json::to_vec_pretty(journal)
        .map_err(|error| format!("transaction_journal_serialize_failed:{error}"))?;
    write_synced(path, &bytes)
}

fn write_synced(path: &Path, bytes: &[u8]) -> Result<(), String> {
    let mut file =
        File::create(path).map_err(|error| format!("transaction_write_failed:{error}"))?;
    file.write_all(bytes)
        .map_err(|error| format!("transaction_write_failed:{error}"))?;
    file.sync_all()
        .map_err(|error| format!("transaction_flush_failed:{error}"))
}

fn rollback_files(
    config_path: &Path,
    config_swap: &Path,
    had_config: bool,
    overtime_path: &Path,
    overtime_swap: &Path,
    had_overtime: bool,
) {
    rollback_file(config_path, config_swap, had_config);
    rollback_file(overtime_path, overtime_swap, had_overtime);
}

fn rollback_file(path: &Path, swap: &Path, had_original: bool) {
    cleanup_path(path);
    if had_original && swap.is_file() {
        let _ = fs::rename(swap, path);
    } else {
        cleanup_path(swap);
    }
}

fn cleanup_path(path: &Path) {
    let _ = fs::remove_file(path);
}

fn sha256(bytes: &[u8]) -> String {
    format!("{:X}", Sha256::digest(bytes))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::overtime::{
        OvertimeBoundaryBasis, OvertimeBoundarySnapshot, OvertimeCalendarSource,
    };
    use crate::repositories::overtime_repository::FileOvertimeRepository;
    use std::time::{SystemTime, UNIX_EPOCH};

    fn test_root(label: &str) -> std::path::PathBuf {
        let stamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        std::env::temp_dir().join(format!("lmm-date-overtime-{label}-{stamp}"))
    }

    fn linked_request(date: &str, minutes: u16) -> DateOvertimeTransactionRequest {
        DateOvertimeTransactionRequest {
            date: date.into(),
            kind: Some(DateOverrideKind::Workday),
            overtime: LinkedOvertimeAction::Upsert {
                request: SaveOvertimeRequest {
                    business_date: date.into(),
                    minutes,
                    hourly_rate_fen_snapshot: 6250,
                    origin: OvertimeOrigin::ManualWeekendWork,
                    boundary_snapshot: Some(OvertimeBoundarySnapshot {
                        basis: OvertimeBoundaryBasis::PlannedShiftGap,
                        current_shift_end: Some("2026-08-08T18:00:00+08:00".into()),
                        next_actual_work_start: Some("2026-08-10T09:00:00+08:00".into()),
                        maximum_minutes: 1440,
                        calendar_source: OvertimeCalendarSource::Manual,
                    }),
                    linked_override_date: Some(date.into()),
                },
            },
        }
    }

    #[test]
    fn linked_upsert_preserves_first_rate_snapshot_and_delete_only_removes_linked_record() {
        let mut store = OvertimeStore::default();
        let request = linked_request("2026-08-08", 480);
        assert!(apply_overtime_action(&mut store, &request).unwrap());
        assert_eq!(store.records[0].hourly_rate_fen_snapshot, 6250);

        let mut changed = linked_request("2026-08-08", 300);
        if let LinkedOvertimeAction::Upsert { request } = &mut changed.overtime {
            request.hourly_rate_fen_snapshot = 9999;
        }
        assert!(apply_overtime_action(&mut store, &changed).unwrap());
        assert_eq!(store.records[0].minutes, 300);
        assert_eq!(store.records[0].hourly_rate_fen_snapshot, 6250);

        let delete = DateOvertimeTransactionRequest {
            date: "2026-08-08".into(),
            kind: None,
            overtime: LinkedOvertimeAction::Delete,
        };
        assert!(apply_overtime_action(&mut store, &delete).unwrap());
        assert!(store.records.is_empty());
    }

    #[test]
    fn keeping_linked_overtime_while_restoring_date_detaches_the_record() {
        let mut store = OvertimeStore::default();
        let request = linked_request("2026-08-08", 480);
        assert!(apply_overtime_action(&mut store, &request).unwrap());

        let keep = DateOvertimeTransactionRequest {
            date: "2026-08-08".into(),
            kind: None,
            overtime: LinkedOvertimeAction::Keep,
        };
        assert!(apply_overtime_action(&mut store, &keep).unwrap());
        let record = &store.records[0];
        assert_eq!(record.origin, OvertimeOrigin::Independent);
        assert!(record.linked_override_date.is_none());
        assert_eq!(
            record.boundary_snapshot.as_ref().unwrap().basis,
            OvertimeBoundaryBasis::RestDayCap
        );
    }

    #[test]
    fn transaction_commits_config_and_overtime_then_can_detach_atomically() {
        let root = test_root("commit");
        fs::create_dir_all(&root).unwrap();
        let runtime = Mutex::new(AppConfig::default());
        let repository = FileOvertimeRepository::new(root.join("overtime-records.json"));

        let saved = execute(
            &root,
            &runtime,
            &repository,
            linked_request("2026-08-08", 480),
        )
        .unwrap();
        assert_eq!(saved.status, "saved");
        assert!(saved.overtime_changed);
        let persisted_config = config::load_or_migrate(&root.join("config.json")).unwrap();
        assert!(persisted_config
            .date_overrides
            .iter()
            .any(|entry| entry.date == "2026-08-08"));
        let persisted_overtime = repository.load().unwrap();
        assert_eq!(persisted_overtime.records[0].minutes, 480);
        assert_eq!(
            persisted_overtime.records[0].origin,
            OvertimeOrigin::ManualWeekendWork
        );

        let detached = execute(
            &root,
            &runtime,
            &repository,
            DateOvertimeTransactionRequest {
                date: "2026-08-08".into(),
                kind: None,
                overtime: LinkedOvertimeAction::Keep,
            },
        )
        .unwrap();
        assert_eq!(detached.status, "saved");
        let final_config = config::load_or_migrate(&root.join("config.json")).unwrap();
        assert!(!final_config
            .date_overrides
            .iter()
            .any(|entry| entry.date == "2026-08-08"));
        let final_overtime = repository.load().unwrap();
        assert_eq!(
            final_overtime.records[0].origin,
            OvertimeOrigin::Independent
        );
        assert!(final_overtime.records[0].linked_override_date.is_none());
        assert!(!root.join(JOURNAL_FILE).exists());

        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn prepared_journal_restores_both_original_files() {
        let root = test_root("recovery");
        fs::create_dir_all(&root).unwrap();
        let original_config = b"original-config";
        let original_overtime = b"original-overtime";
        fs::write(root.join("config.json.date-overtime.swap"), original_config).unwrap();
        fs::write(
            root.join("overtime-records.json.date-overtime.swap"),
            original_overtime,
        )
        .unwrap();
        fs::write(root.join("config.json"), b"partial-config").unwrap();
        fs::write(root.join("overtime-records.json"), b"partial-overtime").unwrap();
        write_journal(
            &root.join(JOURNAL_FILE),
            &TransactionJournal {
                state: "prepared".into(),
                date: "2026-08-08".into(),
                had_config: true,
                had_overtime: true,
                config_sha256: "candidate-config".into(),
                overtime_sha256: "candidate-overtime".into(),
            },
        )
        .unwrap();

        assert_eq!(recover_pending(&root).unwrap().as_deref(), Some("prepared"));
        assert_eq!(fs::read(root.join("config.json")).unwrap(), original_config);
        assert_eq!(
            fs::read(root.join("overtime-records.json")).unwrap(),
            original_overtime
        );
        assert!(!root.join(JOURNAL_FILE).exists());

        fs::remove_dir_all(root).unwrap();
    }
}
