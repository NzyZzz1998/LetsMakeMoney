use std::sync::Mutex;

use crate::models::overtime::{
    now_rfc3339, validate_business_date, OvertimeMutationResponse, OvertimeMutationStatus,
    OvertimeReadResponse, OvertimeReadStatus, OvertimeRecord, OvertimeStoreError,
    SaveOvertimeRequest, OVERTIME_SCHEMA_VERSION,
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
        if request.minutes > 1_440 {
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
            if existing.minutes == request.minutes {
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
            existing.updated_at = now;
            existing.clone()
        } else {
            let record = OvertimeRecord {
                business_date: request.business_date,
                minutes: request.minutes,
                hourly_rate_fen_snapshot: request.hourly_rate_fen_snapshot,
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
    use crate::models::overtime::OvertimeStore;
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
}
