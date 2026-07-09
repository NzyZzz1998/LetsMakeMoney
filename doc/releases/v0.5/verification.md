# LetsMakeMoney v0.5 Beta 验证文档

**最后更新**：2026-07-09  
**适用版本**：v0.5 Beta  
**当前结论**：通过 / 可发布  
**验收对象**：`releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip`

## 1. 验收范围

本轮只做 v0.5 发布前补证验收，不扩展新功能。重点覆盖：

- 托盘左键隐藏 / 恢复。
- `pure_pet_mode=true` 时，恢复后不出现任务栏入口。
- `pure_pet_mode=false` 时，恢复后任务栏入口正常出现。
- Settings 保存成功 / 无变化 / 保存失败反馈。
- Wizard 下一步 / 上一步 / 完成 / 取消日志。
- Settings / Wizard 打开期间点击穿透保护。
- `debug.log` 中 tray、window_policy、taskbar、settings、wizard 语义事件。

## 2. 使用工具与证据来源

- 实际运行 exe：`<PROJECT_ROOT>\releases\v0.5\LetsMakeMoney-v0.5-beta-windows-x86_64\LetsMakeMoney.exe`
- 发布包：`<PROJECT_ROOT>\releases\v0.5\LetsMakeMoney-v0.5-beta-windows-x86_64.zip`
- 配置文件：`%APPDATA%\LetsMakeMoney\config.json`
- 日志文件：`%APPDATA%\LetsMakeMoney\debug.log`
- 桌面截图：`<PROJECT_ROOT>\_lmm_verify\v05_acceptance_desktop_after_pure_tray_restore.png`
- 自动验证：`.\scripts\verify_v05.ps1`
- 包验证：`.\scripts\verify_v05_package.ps1`

说明：Computer Use 无法稳定直接点击 Windows 通知区托盘图标。本轮托盘左键补证使用真实发布包 exe、native 托盘消息窗口同一路径触发、Win32 窗口样式检查和桌面截图共同验证。该路径进入应用实际的 `tray_left_toggle_requested` 处理分支。

## 3. 最终验收结果

| 编号 | 验收项 | 预期 | 实际结果 | 结论 |
|---|---|---|---|---|
| V05-MAN-040 | 托盘左键隐藏 / 恢复 | 左键可隐藏，再次左键可恢复 | native 托盘左键分支触发后，主窗口 `Visible=true -> false -> true` | 通过 |
| V05-MAN-041 | 非纯桌宠恢复策略 | 恢复后任务栏入口存在 | `pure_pet_mode=false` 时主窗口 `AppWindow=true / ToolWindow=false` | 通过 |
| V05-MAN-042 | 纯桌宠恢复策略 | 恢复后不出现任务栏入口 | `pure_pet_mode=true` 时恢复后主窗口 `AppWindow=false / ToolWindow=true`，桌面截图未见 LetsMakeMoney 任务栏入口 | 通过 |
| V05-MAN-045 | 点击穿透保护 | Settings / Wizard 打开期间可正常点击，不被穿透破坏 | Settings / Wizard 均可实际打开、点击、保存、取消和完成 | 通过 |
| V05-MAN-060 | Settings 保存成功 | 显示成功，配置写入，日志可查 | UI 显示“保存成功”，日志有 `settings_save_success: changed_keys=["monthly_salary"]` | 通过 |
| V05-MAN-061 | Settings 无变化保存 | 显示无变化，不误报失败 | UI 显示“没有需要保存的更改”，日志有 `settings_save_no_change` | 通过 |
| V05-MAN-062 | Settings 保存失败 | 显示失败，不显示成功，输入保留，日志记录原因 | 临时阻塞配置文件后，UI 显示“保存失败”，日志有 `config_save_failed` / `settings_save_failed` | 通过 |
| V05-MAN-063 | Wizard 步骤切换 | 下一步 / 上一步日志完整 | 日志有 `wizard_step_changed: from=1 to=2` 和 `from=2 to=1` | 通过 |
| V05-MAN-064 | Wizard 取消 / 关闭 | 取消后日志完整并恢复主窗口 | 日志有 `wizard_cancelled` / `wizard_closed: reason=cancelled` | 通过 |
| V05-MAN-065 | Wizard 完成 | 完成后保存并关闭，日志完整 | 日志有 `wizard_finished` / `wizard_closed: reason=finished` | 通过 |
| V05-PKG-001 | v0.5 zip 包可用 | 包结构、manifest、checksum、短启动烟测通过 | `verify_v05_package.ps1` 输出 `v0.5 package smoke passed` | 通过 |

## 4. 关键日志证据

托盘与纯桌宠恢复：

```text
tray_left_toggle_requested: visible_before=true pure_pet_mode=true
tray_left_toggle_result: visible_after=false pure_pet_mode=true
tray_left_toggle_requested: visible_before=false pure_pet_mode=true
WindowsPlatform.set_taskbar_visible: hwnd=... visible=false
WindowsPlatform.set_taskbar_visible: ok=true
window_policy_reapplied: phase=tray_restore pure_pet_mode=true
tray_left_toggle_result: visible_after=true pure_pet_mode=true
```

非纯桌宠恢复：

```text
tray_left_toggle_requested: visible_before=false pure_pet_mode=false
WindowsPlatform.set_taskbar_visible: hwnd=... visible=true
WindowsPlatform.set_taskbar_visible: ok=true
window_policy_reapplied: phase=tray_restore pure_pet_mode=false
```

Settings 保存反馈：

```text
settings_save_no_change
settings_save_success: changed_keys=["monthly_salary"]
config_save_failed: open_failed ...
settings_save_failed: reason=open_failed ...
```

Wizard 语义事件：

```text
wizard_opened: step=1
wizard_step_changed: from=1 to=2
wizard_step_changed: from=2 to=1
wizard_cancelled: step=1
wizard_closed: reason=cancelled step=1
wizard_step_changed: from=1 to=2
wizard_step_changed: from=2 to=3
wizard_step_changed: from=3 to=4
wizard_finished: changed_keys=[] step=4
wizard_closed: reason=finished step=4
```

## 5. 已知说明

- `passthrough_suspended` / `passthrough_resumed` 当前是 debug 级日志，默认 `debug_mode=false` 时不会每次写入。本轮通过 Settings / Wizard 实际可操作性、代码合同和历史 debug 日志确认点击穿透保护未回归。建议 v0.6 优化该日志口径。
- `verify_v05.ps1` 返回通过，但 Godot headless 过程仍可能输出与脚本加载顺序相关的 parser 文本。该项不影响发布包烟测和真实 exe 验收，但建议 v0.6 优化脚本输出质量。

## 6. 最终结论

v0.5 Beta 发布前补证验收通过。当前可进入发布收口：

- 更新 `status.md`、`progress_v0.5.md`、`release-checklist.md`、release notes 和 changelog 为“通过 / 可发布”。
- 可以准备提交、推送并打 `v0.5-beta` tag。
- 不需要把主题系统、安装器、自动更新、多平台、更多宠物或 ComfyUI 正式化纳入 v0.5。
