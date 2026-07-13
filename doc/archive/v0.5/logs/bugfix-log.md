# LetsMakeMoney v0.5 缺陷修复日志

本文件记录 v0.5 验收中发现的缺陷、修复结果和后续候选修复项。它用于承接 bugfix 与技术排查细节，避免这些过程性内容进入 `doc/releases/v0.5/progress_v0.5.md`。

## 2026-07-09 验收发现

### V05-BUG-001：Settings 保存失败时可能显示成功，但配置没有更新

- 状态：已修复，定向验收通过。
- 来源：针对 `releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64/` 的 v0.5 Beta 验收。
- 证据：Settings 保存成功和无变化保存路径可见且可用。模拟保存失败时，界面仍显示保存成功，但 `%APPDATA%\LetsMakeMoney\config.json` 仍停留在稍后 Wizard 完成前的旧 `monthly_salary` 值。
- 影响：保存失败反馈不能被视为完全可靠。它不阻塞正常保存和无变化保存路径，但会削弱失败路径验收可信度。
- 建议修复：检查 `Config.save` 的返回值、错误传播和 Settings 反馈刷新时机。增加一个可确定触发保存失败的验证路径，避免依赖修改用户 ACL。
- 修复摘要：`Config.save()` 现在返回 `bool`，记录 `config_save_success` / `config_save_failed`，验证持久化文件内容，并暴露 `get_last_save_error()`。Settings 在应用表单值前会快照配置；保存失败时回滚内存配置，保留用户输入，显示失败反馈，并记录 `settings_save_success`、`settings_save_no_change` 或 `settings_save_failed`。
- 定向验收：2026-07-09 通过。成功路径将 `monthly_salary` 从 `1000` 改为 `1100`，并记录 `config_save_success` / `settings_save_success`；无变化保存记录 `settings_save_no_change`；强制 ACL 拒绝写入时显示失败反馈，保留未保存的 `1200` 输入，配置仍保持 `1100`，并记录带有可读打开文件错误的 `config_save_failed` / `settings_save_failed`。

### V05-BUG-002：debug.log 缺少细粒度 Settings / Wizard 语义事件

- 状态：已修复，定向验收通过。
- 来源：v0.5 Beta 验收中的日志复核。
- 证据：`debug.log` 已记录启动、原生桥健康状态、托盘设置、点击穿透暂停/恢复、模态窗口打开/关闭和窗口设置事件，但缺少清晰稳定的 Settings 保存结果、Wizard 步骤切换和 Wizard 完成事件。
- 影响：核心运行日志可用，但 Settings / Wizard 工作流的 `V05` 日志验收只能算部分通过。
- 建议修复：增加低噪声事件，例如 `settings_save_result`、`wizard_opened`、`wizard_step_changed` 和 `wizard_finished`。
- 修复摘要：已增加 Settings 保存语义事件，以及 Wizard 打开、步骤切换、完成、完成失败、取消和关闭事件。
- 定向验收：2026-07-09 通过。日志包含 `wizard_opened`、`wizard_step_changed: from=1 to=2`、`from=2 to=3`、`from=3 to=4`、`wizard_finished`、`wizard_closed: reason=finished`、`wizard_cancelled` 和 `wizard_closed: reason=cancelled`。

### V05-BUG-003：托盘左键恢复仍需要人工验证任务栏策略

- 状态：代码已修复，但原生发布包仍待复测。
- 来源：使用 Computer Use 进行 v0.5 Beta 验收。
- 证据：应用菜单中的“隐藏到托盘”可以隐藏窗口并让进程保持运行。Computer Use 无法稳定枚举或点击 Windows 通知区域托盘图标，因此该轮验收无法自动完成托盘左键恢复路径。
- 影响：隐藏到托盘和原生托盘设置已有证据支撑，但左键恢复仍是人工验收步骤。
- 建议修复：保留在手动发布清单中，或新增仅用于调试的原生托盘命令入口，以便自动验收。
- 人工复测结果：用户确认了正确产品预期：无论纯桌宠还是非纯桌宠模式，左键托盘图标都应该隐藏/显示窗口。两种模式的差异只在恢复后的任务栏策略：非纯桌宠模式会同时显示桌宠和任务栏入口；纯桌宠模式只恢复桌宠，不显示任务栏入口。
- 修复摘要：原生托盘图标左键现在发出独立的 `COMMAND_LEFT_TOGGLE = 5`，托盘菜单的显示/隐藏项继续使用既有 `COMMAND_TOGGLE = 1`。`Main._on_tray_left_toggle_requested()` 现在会在两种模式下切换可见性，并在显示后重新应用窗口策略，使纯桌宠模式恢复时不暴露任务栏入口。
- 后续发现：人工复测显示纯桌宠模式下窗口可以恢复，但任务栏入口仍出现。根因是 `Main` 使自身任务栏缓存失效后，`WindowsPlatform` 仍按窗口缓存了任务栏可见性，并在原生 `ShowWindow` 后跳过了真正的 `set_taskbar_visible(false)` 调用。后续修复方向是：在 `setup_window` 和原生显示后使 `WindowsPlatform` 任务栏缓存失效，并记录每一次真实的原生 `WindowsPlatform.set_taskbar_visible` 调用。
