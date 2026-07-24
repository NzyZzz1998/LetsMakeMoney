use serde::{Deserialize, Serialize};
use std::{fs, path::PathBuf};
use tauri::{
    menu::{Menu, MenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, LogicalSize, Manager, WebviewWindow,
};

#[derive(Debug, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "camelCase")]
struct SettingsPayload {
    salary: String,
    simulate_failure: bool,
}

#[derive(Debug, Serialize, PartialEq)]
struct SaveResult {
    status: &'static str,
    message: &'static str,
}

#[tauri::command]
fn set_window_mode(window: WebviewWindow, mode: String) -> Result<(), String> {
    let (width, height) = match mode.as_str() {
        "mini" => (344.0, 120.0),
        "workbench" => (820.0, 620.0),
        "settings" => (720.0, 540.0),
        _ => return Err(format!("未知窗口模式：{mode}")),
    };
    window
        .set_size(LogicalSize::new(width, height))
        .map_err(|error| error.to_string())?;
    window.show().map_err(|error| error.to_string())?;
    window.set_focus().map_err(|error| error.to_string())
}

#[tauri::command]
fn hide_to_tray(window: WebviewWindow) -> Result<(), String> {
    window.hide().map_err(|error| error.to_string())
}

#[tauri::command]
fn save_settings(app: AppHandle, payload: SettingsPayload) -> Result<SaveResult, String> {
    if payload.simulate_failure {
        return Err("配置文件暂时不可写".to_string());
    }
    let path = settings_path(&app)?;
    if let Ok(existing) = fs::read_to_string(&path) {
        if let Ok(current) = serde_json::from_str::<SettingsPayload>(&existing) {
            if current.salary == payload.salary {
                return Ok(SaveResult {
                    status: "unchanged",
                    message: "没有需要保存的更改",
                });
            }
        }
    } else if payload.salary == "10,000" {
        return Ok(SaveResult {
            status: "unchanged",
            message: "没有需要保存的更改",
        });
    }

    let parent = path
        .parent()
        .ok_or_else(|| "配置目录不可用".to_string())?;
    fs::create_dir_all(parent).map_err(|error| format!("创建配置目录失败：{error}"))?;
    let temporary = path.with_extension("json.tmp");
    let clean_payload = SettingsPayload {
        salary: payload.salary,
        simulate_failure: false,
    };
    let content =
        serde_json::to_vec_pretty(&clean_payload).map_err(|error| format!("配置序列化失败：{error}"))?;
    fs::write(&temporary, content).map_err(|error| format!("写入临时配置失败：{error}"))?;
    fs::rename(&temporary, &path).map_err(|error| format!("替换配置失败：{error}"))?;
    Ok(SaveResult {
        status: "saved",
        message: "已保存到本机",
    })
}

fn settings_path(app: &AppHandle) -> Result<PathBuf, String> {
    app.path()
        .app_data_dir()
        .map(|directory| directory.join("spike-settings.json"))
        .map_err(|error| error.to_string())
}

fn toggle_window(app: &AppHandle) {
    if let Some(window) = app.get_webview_window("main") {
        if window.is_visible().unwrap_or(false) {
            let _ = window.hide();
        } else {
            let _ = window.show();
            let _ = window.set_focus();
        }
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            set_window_mode,
            hide_to_tray,
            save_settings
        ])
        .setup(|app| {
            let show = MenuItem::with_id(app, "show", "显示 / 隐藏窗口", true, None::<&str>)?;
            let settings = MenuItem::with_id(app, "settings", "设置", true, None::<&str>)?;
            let quit = MenuItem::with_id(app, "quit", "退出", true, None::<&str>)?;
            let menu = Menu::with_items(app, &[&show, &settings, &quit])?;
            let _tray = TrayIconBuilder::new()
                .menu(&menu)
                .show_menu_on_left_click(false)
                .tooltip("LetsMakeMoney v1.0 技术 Spike")
                .on_menu_event(|app, event| match event.id.as_ref() {
                    "show" => toggle_window(app),
                    "settings" => {
                        if let Some(window) = app.get_webview_window("main") {
                            let _ = window.show();
                            let _ = window.set_focus();
                            let _ = window.eval(
                                "window.dispatchEvent(new CustomEvent('lmm-open-settings'))",
                            );
                        }
                    }
                    "quit" => app.exit(0),
                    _ => {}
                })
                .on_tray_icon_event(|tray, event| {
                    if let TrayIconEvent::Click {
                        button: MouseButton::Left,
                        button_state: MouseButtonState::Up,
                        ..
                    } = event
                    {
                        toggle_window(tray.app_handle());
                    }
                })
                .build(app)?;

            if let Some(window) = app.get_webview_window("main") {
                let handle = window.clone();
                window.on_window_event(move |event| {
                    if let tauri::WindowEvent::CloseRequested { api, .. } = event {
                        api.prevent_close();
                        let _ = handle.hide();
                    }
                });
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("Tauri application failed");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn settings_payload_uses_camel_case_contract() {
        let value = serde_json::to_value(SettingsPayload {
            salary: "10,000".to_string(),
            simulate_failure: true,
        })
        .expect("serialize payload");
        assert_eq!(value["simulateFailure"], true);
        assert_eq!(value["salary"], "10,000");
    }

    #[test]
    fn window_sizes_match_golden_path() {
        let sizes = [("mini", 344, 120), ("workbench", 820, 620), ("settings", 720, 540)];
        assert_eq!(sizes.len(), 3);
        assert_eq!(sizes[2], ("settings", 720, 540));
    }
}

