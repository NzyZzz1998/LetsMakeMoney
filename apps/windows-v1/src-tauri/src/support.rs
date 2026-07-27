use serde::{Deserialize, Serialize};
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct DiagnosticSummary {
    pub app_version: String,
    pub config_version: u32,
    pub platform: String,
    pub log_level: String,
    pub config_status: String,
    pub native_status: String,
}

impl DiagnosticSummary {
    pub fn render(&self) -> String {
        format!(
            "LetsMakeMoney {}\n平台：{}\n配置版本：{}\n配置状态：{}\n原生能力：{}\n日志级别：{}",
            self.app_version,
            self.platform,
            self.config_version,
            self.config_status,
            self.native_status,
            self.log_level
        )
    }
}

pub struct RotatingLogger {
    path: PathBuf,
    max_bytes: u64,
    backups: usize,
}

impl RotatingLogger {
    pub fn new(path: PathBuf, max_bytes: u64, backups: usize) -> Self {
        Self {
            path,
            max_bytes,
            backups,
        }
    }

    pub fn append(&self, event: &str, detail: &str) -> Result<(), String> {
        self.rotate_if_needed()?;
        if let Some(parent) = self.path.parent() {
            fs::create_dir_all(parent).map_err(|error| error.to_string())?;
        }
        let sanitized = detail.replace('\\', "/");
        let line = format!("event={event} detail={sanitized}\n");
        OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.path)
            .and_then(|mut file| file.write_all(line.as_bytes()))
            .map_err(|error| error.to_string())
    }

    fn rotate_if_needed(&self) -> Result<(), String> {
        if fs::metadata(&self.path).map(|meta| meta.len()).unwrap_or(0) < self.max_bytes {
            return Ok(());
        }
        for index in (1..=self.backups).rev() {
            let source = if index == 1 {
                self.path.clone()
            } else {
                PathBuf::from(format!("{}.{}", self.path.display(), index - 1))
            };
            let destination = PathBuf::from(format!("{}.{}", self.path.display(), index));
            if source.exists() {
                let _ = fs::remove_file(&destination);
                fs::rename(source, destination).map_err(|error| error.to_string())?;
            }
        }
        Ok(())
    }
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum UpdateStatus {
    UpToDate,
    Available,
    Unavailable,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct UpdateResult {
    pub status: UpdateStatus,
    pub version: Option<String>,
    pub message: String,
}

pub fn parse_release_response(current: &str, response: Result<&str, &str>) -> UpdateResult {
    let body = match response {
        Ok(body) => body,
        Err(reason) => {
            return UpdateResult {
                status: UpdateStatus::Unavailable,
                version: None,
                message: format!("暂时无法检查更新：{reason}"),
            }
        }
    };
    let value: serde_json::Value = match serde_json::from_str(body) {
        Ok(value) => value,
        Err(_) => {
            return UpdateResult {
                status: UpdateStatus::Unavailable,
                version: None,
                message: "更新服务返回了无法识别的数据".into(),
            }
        }
    };
    let version = value
        .get("tag_name")
        .and_then(serde_json::Value::as_str)
        .unwrap_or_default()
        .trim_start_matches('v');
    if version.is_empty() {
        return UpdateResult {
            status: UpdateStatus::Unavailable,
            version: None,
            message: "更新信息缺少版本号".into(),
        };
    }
    if version == current.trim_start_matches('v') {
        UpdateResult {
            status: UpdateStatus::UpToDate,
            version: Some(version.into()),
            message: "当前已是最新版本".into(),
        }
    } else {
        UpdateResult {
            status: UpdateStatus::Available,
            version: Some(version.into()),
            message: format!("发现新版本 {version}"),
        }
    }
}

pub fn data_directory(base: &Path) -> PathBuf {
    base.join("LetsMakeMoney")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn update_failures_degrade_without_crashing() {
        let result = parse_release_response("1.0.0", Err("网络不可用"));
        assert_eq!(result.status, UpdateStatus::Unavailable);
        assert!(result.message.contains("网络不可用"));
        let result = parse_release_response("1.0.0", Ok(r#"{"tag_name":"v1.0.0"}"#));
        assert_eq!(result.status, UpdateStatus::UpToDate);
    }

    #[test]
    fn diagnostic_contains_no_user_path() {
        let summary = DiagnosticSummary {
            app_version: "1.0.0".into(),
            config_version: 6,
            platform: "Windows".into(),
            log_level: "info".into(),
            config_status: "正常".into(),
            native_status: "可用".into(),
        }
        .render();
        assert!(!summary.contains("Users"));
        assert!(!summary.contains("AppData"));
    }

    #[test]
    fn logger_rotates() {
        let root = std::env::temp_dir().join("lmm-v10-log-test");
        let _ = fs::remove_dir_all(&root);
        let logger = RotatingLogger::new(root.join("debug.log"), 20, 2);
        logger.append("first", "12345678901234567890").unwrap();
        logger.append("second", "ok").unwrap();
        assert!(root.join("debug.log.1").exists());
    }
}
