use std::sync::Mutex;

use crate::config::{AppConfig, SaveResult, SaveStatus, ThemeMode, WindowPosition};
use crate::domain::DateOverrideKind;
use crate::repositories::configuration_repository::ConfigurationRepository;

pub struct ConfigurationSaveOutcome {
    pub result: SaveResult,
    pub previous_theme: ThemeMode,
    pub requested_theme: ThemeMode,
}

pub struct RuntimeSnapshotOutcome {
    pub result: SaveResult,
    pub mini_window_position: Option<WindowPosition>,
    pub pet_window_position: Option<WindowPosition>,
}

pub fn save_user_configuration(
    runtime: &Mutex<AppConfig>,
    repository: &impl ConfigurationRepository,
    initialized: bool,
    draft: AppConfig,
) -> Result<ConfigurationSaveOutcome, String> {
    let mut current = runtime.lock().map_err(|_| "config_lock_failed")?;
    let previous_theme = current.theme_mode.clone();
    let requested_theme = draft.theme_mode.clone();
    let result = repository.save(&current, &draft, initialized);
    if result.status == SaveStatus::Saved {
        *current = draft;
    }
    Ok(ConfigurationSaveOutcome {
        result,
        previous_theme,
        requested_theme,
    })
}

pub fn save_date_override(
    runtime: &Mutex<AppConfig>,
    repository: &impl ConfigurationRepository,
    date: &str,
    kind: Option<DateOverrideKind>,
) -> Result<SaveResult, String> {
    let mut current = runtime.lock().map_err(|_| "config_lock_failed")?;
    let (result, next) = repository.save_date_override(&current, date, kind);
    if matches!(result.status, SaveStatus::Saved | SaveStatus::Unchanged) {
        *current = next;
    }
    Ok(result)
}

pub fn persist_runtime_snapshot(
    runtime: &Mutex<AppConfig>,
    repository: &impl ConfigurationRepository,
) -> Result<RuntimeSnapshotOutcome, String> {
    // Keep the runtime lock through load and save so delayed window-position writes
    // cannot overwrite a newer Settings transaction with a stale snapshot.
    let current = runtime.lock().map_err(|_| "config_lock_failed")?;
    let persisted = repository.load()?;
    let result = repository.save(&persisted, &current, true);
    Ok(RuntimeSnapshotOutcome {
        result,
        mini_window_position: current.mini_window_position.clone(),
        pet_window_position: current.pet_window_position.clone(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{AppConfig, SaveResult, SaveStatus, ThemeMode, WindowPosition};
    use crate::domain::DateOverrideKind;
    use crate::repositories::configuration_repository::ConfigurationRepository;
    use std::sync::Mutex;

    struct MemoryConfigurationRepository {
        persisted: Mutex<AppConfig>,
        fail_saves: bool,
    }

    impl MemoryConfigurationRepository {
        fn new(config: AppConfig) -> Self {
            Self {
                persisted: Mutex::new(config),
                fail_saves: false,
            }
        }

        fn failing(config: AppConfig) -> Self {
            Self {
                persisted: Mutex::new(config),
                fail_saves: true,
            }
        }

        fn persisted(&self) -> AppConfig {
            self.persisted.lock().unwrap().clone()
        }
    }

    impl ConfigurationRepository for MemoryConfigurationRepository {
        fn load(&self) -> Result<AppConfig, String> {
            Ok(self.persisted())
        }

        fn save(&self, current: &AppConfig, draft: &AppConfig, _initialized: bool) -> SaveResult {
            if self.fail_saves {
                return SaveResult {
                    status: SaveStatus::Failed,
                    message: "test_save_failed".into(),
                    draft_preserved: true,
                };
            }
            if current == draft {
                return SaveResult {
                    status: SaveStatus::Unchanged,
                    message: "unchanged".into(),
                    draft_preserved: true,
                };
            }
            *self.persisted.lock().unwrap() = draft.clone();
            SaveResult {
                status: SaveStatus::Saved,
                message: "saved".into(),
                draft_preserved: false,
            }
        }

        fn save_date_override(
            &self,
            current: &AppConfig,
            _date: &str,
            _kind: Option<DateOverrideKind>,
        ) -> (SaveResult, AppConfig) {
            (
                SaveResult {
                    status: SaveStatus::Unchanged,
                    message: "unchanged".into(),
                    draft_preserved: true,
                },
                current.clone(),
            )
        }
    }

    #[test]
    fn successful_user_save_updates_repository_and_runtime_atomically() {
        let current = AppConfig::default();
        let runtime = Mutex::new(current.clone());
        let repository = MemoryConfigurationRepository::new(current);
        let draft = AppConfig {
            monthly_salary: 12_345.67,
            theme_mode: ThemeMode::Dark,
            ..AppConfig::default()
        };

        let outcome = save_user_configuration(&runtime, &repository, true, draft.clone()).unwrap();

        assert_eq!(outcome.result.status, SaveStatus::Saved);
        assert_eq!(*runtime.lock().unwrap(), draft);
        assert_eq!(repository.persisted(), draft);
    }

    #[test]
    fn failed_user_save_preserves_runtime_and_repository() {
        let current = AppConfig::default();
        let runtime = Mutex::new(current.clone());
        let repository = MemoryConfigurationRepository::failing(current.clone());
        let mut draft = current.clone();
        draft.monthly_salary = 20_000.0;

        let outcome = save_user_configuration(&runtime, &repository, true, draft).unwrap();

        assert_eq!(outcome.result.status, SaveStatus::Failed);
        assert_eq!(*runtime.lock().unwrap(), current);
        assert_eq!(repository.persisted(), current);
    }

    #[test]
    fn mini_position_snapshot_preserves_newer_runtime_settings() {
        let persisted = AppConfig {
            monthly_salary: 8_000.0,
            ..AppConfig::default()
        };
        let repository = MemoryConfigurationRepository::new(persisted);

        let runtime_config = AppConfig {
            monthly_salary: 15_000.0,
            mini_window_position: Some(WindowPosition { x: 320.0, y: 180.0 }),
            ..AppConfig::default()
        };
        let runtime = Mutex::new(runtime_config.clone());

        let outcome = persist_runtime_snapshot(&runtime, &repository).unwrap();

        assert_eq!(outcome.result.status, SaveStatus::Saved);
        assert_eq!(repository.persisted(), runtime_config);
        assert_eq!(
            outcome.mini_window_position,
            Some(WindowPosition { x: 320.0, y: 180.0 })
        );
        assert_eq!(outcome.pet_window_position, None);
    }
}
