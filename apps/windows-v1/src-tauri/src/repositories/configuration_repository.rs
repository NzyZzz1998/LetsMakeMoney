use std::path::PathBuf;

use crate::config::{self, AppConfig, SaveFault, SaveResult};
use crate::domain::DateOverrideKind;

pub trait ConfigurationRepository {
    fn load(&self) -> Result<AppConfig, String>;

    fn save(&self, current: &AppConfig, draft: &AppConfig, initialized: bool) -> SaveResult;

    fn save_date_override(
        &self,
        current: &AppConfig,
        date: &str,
        kind: Option<DateOverrideKind>,
    ) -> (SaveResult, AppConfig);
}

pub struct FileConfigurationRepository {
    config_path: PathBuf,
}

impl FileConfigurationRepository {
    pub fn new(config_path: impl Into<PathBuf>) -> Self {
        Self {
            config_path: config_path.into(),
        }
    }
}

impl ConfigurationRepository for FileConfigurationRepository {
    fn load(&self) -> Result<AppConfig, String> {
        config::load_or_migrate(&self.config_path)
    }

    fn save(&self, current: &AppConfig, draft: &AppConfig, initialized: bool) -> SaveResult {
        if initialized {
            config::save_transactional(&self.config_path, current, draft, SaveFault::None)
        } else {
            config::save_initial(&self.config_path, current, draft)
        }
    }

    fn save_date_override(
        &self,
        current: &AppConfig,
        date: &str,
        kind: Option<DateOverrideKind>,
    ) -> (SaveResult, AppConfig) {
        config::save_date_override_transactional(
            &self.config_path,
            current,
            date,
            kind,
            SaveFault::None,
        )
    }
}
