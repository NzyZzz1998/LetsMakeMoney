# LetsMakeMoney v0.6 Beta 验证文档

**最后更新**：2026-07-11
**当前状态**：最终 Acceptance 通过，可进入发布收口
**结论允许值**：通过 / 部分通过 / 失败 / 待人工补证 / 暂不验证

## 1. 验收对象

- 发布包：`releases/v0.6/LetsMakeMoney-v0.6-beta-windows-x86_64.zip`
- Zip 大小：`42,778,715` 字节
- Zip SHA256：`CECD3C3ABACFCB5EF594584E2AEB0E25C1824BAE97AB84B224073E7444E72615`
- 当前候选 EXE：`releases/v0.6/LetsMakeMoney-v0.6-beta-windows-x86_64/LetsMakeMoney.exe`
- EXE 大小：`113,240,688` 字节
- EXE SHA256：`749F18E35E757A250EDA8D3DE5B712BD554861082E33D607E1D07835AA943E3B`
- 最终独立解压目录：`.tmp_acceptance/v0.6-final-20260710-235245/extracted`
- 最终实际 EXE：`.tmp_acceptance/v0.6-final-20260710-235245/extracted/LetsMakeMoney.exe`
- 定向复验时间：`2026-07-10 20:23 +08:00`
- 分支与 HEAD：`main` / `77cef5cf3f8dc39e695f12d03e12598aa7260fee`
- 验收结束后：旧进程已结束，原 `config.json`、`debug.log` 已按哈希一致恢复，原环境不存在的 `debug.log.1` 未保留。

## 2. 自动验证结果

| 编号 | 验证项 | 命令 / 证据 | 结果 | 备注 |
|---|---|---|---|---|
| V06-AUTO-001 | v0.6 主验证 | `scripts/verify_v06.ps1` | 通过 | 阻塞输出扫描、诊断白名单、Config 安全保存通过 |
| V06-AUTO-002 | 托盘专项 | `scripts/verify_v06_tray.ps1` | 通过 | 对独立解压 EXE 执行 normal/pure 各 10 轮；每种模式均有 20 条请求、20 条结果和 20 条策略重应用日志 |
| V06-AUTO-003 | 配置与自启动专项 | `scripts/verify_v06_config.ps1` | 通过 | 原子替换、失败保旧、损坏备份和事务契约通过；真实登录按当前口径暂不验证 |
| V06-AUTO-004 | v0.5/v0.4/M4/M5 回归 | 对应脚本 | 通过 | 四个入口均为可信退出，M5 导出烟测通过 |
| V06-AUTO-005 | 文档状态 | `scripts/check_docs_status.ps1` | 通过 | 最终 Acceptance 文档更新前后均通过；正式文档为中文 UTF-8 |
| V06-AUTO-006 | 包体验证 | `scripts/verify_v06_package.ps1` | 通过 | 结构、manifest、checksum、版本日志和短启动烟测通过 |

## 3. V06-M6-014 发布包真实桌面复验

| 编号 | 项目 | 结论 | 真实证据 | 备注 |
|---|---|---|---|---|
| V06-ACC-M6-001 | 独立解压包启动与窗口形态 | 通过 | Computer Use 从最终独立解压 EXE 启动；进程路径、开始时间与 EXE 哈希记录在 `.tmp_acceptance/v0.6-final-20260710-235245/evidence/acceptance-object.json` | Debug 宿主、透明桌宠、Panel 折叠/展开和暖色右键菜单均可见；无启动崩溃 |
| V06-ACC-M6-002 | Settings 五页与共享控件 | 通过 | Computer Use 依次检查工资、桌宠、显示、面板、通用页 | 下拉、开关、滑块、SpinBox、按钮风格一致，无深色默认 Popup 或明显裁切 |
| V06-ACC-M6-003 | Settings 保存成功 | 通过 | 月薪 `12000 -> 12345`；`config.json` 持久化；重启后读取同一配置 | 日志：`config_save_success`、`settings_save_success` |
| V06-ACC-M6-004 | Settings 无变化保存 | 通过 | UI 显示“没有需要保存的更改。” | 日志：`settings_save_no_change` |
| V06-ACC-M6-005 | Settings 保存失败与回滚 | 通过 | 人工补证捕获“保存失败：temp_open_failed error=Can't open file”；输入保留，最终有效配置未改变 | `config_save_failed`、`settings_transaction_rollback ... result=success`、`settings_save_failed` 完整 |
| V06-ACC-M6-006 | Wizard 下一步、上一步、取消 | 通过 | Computer Use 完成 1->2->3->2->取消；配置和宠物保持进入前状态 | 日志：`wizard_step_changed`、`wizard_state_restored: reason=cancelled`、`wizard_cancelled`、`wizard_closed` |
| V06-ACC-M6-007 | Wizard 完成 | 通过 | Computer Use 完成四步并提交确认页 | 日志：`wizard_finished`、`wizard_closed: reason=finished`；配置保存成功 |
| V06-ACC-M6-008 | Wizard 关闭 | 通过 | 欢迎页执行 `Alt+F4`，向导关闭但主程序继续运行 | 日志：`wizard_state_restored: reason=closed`、`wizard_closed: reason=closed` |
| V06-ACC-M6-009 | Popup/Modal 点击穿透保护 | 通过 | 右键菜单、Settings、Wizard 的打开与关闭均有成对日志 | `passthrough_suspended` 与 `passthrough_resumed` 成对；关闭后未永久失效 |
| V06-ACC-M6-010 | 托盘原生链路与纯桌宠策略 | 通过 | 第一轮人工补证确认普通模式通过；修复候选包增加 Shell `DeleteTab/AddTab` 同步后，Computer Use 完成纯桌宠通知区显隐，恢复后任务栏无 LetsMakeMoney 入口 | 截图：`.tmp_acceptance/cu-pure-taskbar-20260710/pure-restored-no-taskbar-entry.png`；日志记录 `visible_after=true pure_pet_mode=true` 和任务栏 `visible=false` |
| V06-ACC-M6-011 | 打开应用数据目录 | 通过 | Computer Use 点击后打开 `%APPDATA%/LetsMakeMoney` | 日志：`diagnostics_open_data_directory_success` |
| V06-ACC-M6-012 | 复制脱敏诊断摘要 | 通过 | 从新解压候选包实际点击后，UI 显示“诊断摘要已复制。”；剪贴板得到 251 字符摘要且无用户名、用户目录、薪资、时间、坐标和原始日志 | 日志：`diagnostics_copy_success: verification=verified`；截图：`.tmp_acceptance/v0.6-bugfix-final4/evidence/diagnostics-copy-success-2.png` |
| V06-ACC-M6-013 | 损坏配置恢复 | 通过 | 将 `config.json` 写成非法 JSON 后从实际 EXE 启动；出现首次配置向导并生成 `config.invalid.20260710_160756.json` | 日志：`config_recovered: reason=invalid_json backup=created`；无半成品有效配置 |
| V06-ACC-M6-014 | 日志等级与轮换 | 通过 | 构造 `2,257,200` 字节日志后启动实际 EXE，新 `debug.log` 为约 2 KB，旧日志成为唯一 `debug.log.1` | 日志同时存在 info/debug/error 等级 |
| V06-ACC-M6-015 | 真实登录开机自启 | 暂不验证 | 第一轮注册表值使用 `<LEGACY_PATH>` 正斜杠且登录后未启动；修复候选包改为反斜杠并严格校验存储命令 | 当前决定不在本轮继续注销、重启或补证；不得据此写为“通过” |

## 4. V06-ACC-001 发布前证据收口

| 门禁 | 结论 | 证据 / 缺口 |
|---|---|---|
| 发布包身份唯一且可追溯 | 通过 | Zip、EXE 的路径、大小、SHA256 与启动时间均已记录 |
| Settings 成功、无变化、失败语义事件 | 通过 | `settings_save_success`、`settings_save_no_change`、`settings_save_failed` 和回滚结果完整 |
| Settings 保存失败可见反馈 | 通过 | 人工补证确认可读失败文案、输入保留、旧配置未污染和失败日志均通过 |
| Wizard 打开、步骤、完成、取消、关闭语义事件 | 通过 | `wizard_opened`、`wizard_step_changed`、`wizard_finished`、`wizard_cancelled`、`wizard_closed` 完整 |
| Popup/Modal 穿透保护 | 通过 | `popup_opened/popup_closed`、`modal_opened/modal_closed` 成对 |
| 托盘显隐与任务栏策略 | 通过 | 普通模式人工通过；纯桌宠修复后由 Computer Use 完成显隐并确认恢复后无任务栏入口，normal/pure 自动专项各 10 轮通过 |
| 配置安全写入与损坏恢复 | 通过 | 成功持久化、失败不污染旧配置、损坏文件备份与默认恢复均有真实证据 |
| 轻量诊断 | 通过 | 打开目录通过；诊断复制成功反馈、剪贴板内容、脱敏白名单和成功日志均完成真实复验 |
| v0.4/v0.5 核心体验回归 | 通过 | 收入计算、Panel、菜单、桌宠显示与基础交互、设置关闭、托盘同路径均通过已有回归和本次抽检 |
| 真实登录开机自启 | 暂不验证 | 第一轮真实登录失败；路径格式和旧值识别已修复，但当前决定不继续真实登录复测，结论保持未验证 |

## 5. 关键日志证据

```text
settings_save_success: changed_keys=["monthly_salary", "work_hours_per_day"]
settings_save_no_change
settings_transaction_rollback: reason=temp_open_failed error=Can't open file result=success
settings_save_failed: reason=temp_open_failed error=Can't open file
wizard_step_changed: from=3 to=4
wizard_finished: changed_keys=[] step=4
wizard_state_restored: reason=closed pet_id=cat_orange_v2
wizard_closed: reason=closed step=1
passthrough_suspended: reason=modal_opened
passthrough_resumed: reason=modal_closed
config_recovered: reason=invalid_json backup=created
diagnostics_open_data_directory_success
diagnostics_copy_success: verification=verified
```

托盘专项对 normal/pure 各记录 20 条 `tray_left_toggle_requested`、20 条 `tray_left_toggle_result`、20 条 `window_policy_reapplied`。pure 模式恢复时日志明确出现 `set_taskbar_visible ... visible=false`。

## 6. Computer Use 截图记录

- 已实际截图检查：Debug 桌宠与 Panel、暖色右键菜单、Settings 五页、Wizard 欢迎/薪资/宠物/确认页、向导关闭后主窗口。
- 当前会话保存的本地验收截图：`.tmp_acceptance/v0.6-final/evidence/computer-use-final-1.png`。
- V06-BUG-001 定向复验截图：`.tmp_acceptance/v0.6-bugfix-final4/evidence/diagnostics-copy-success-2.png`。
- Settings 保存失败人工截图：`.tmp_acceptance/v0.6-final-20260710-235245/evidence/settings-save-failed-visible.png`。
- 纯桌宠恢复后无任务栏入口：`.tmp_acceptance/cu-pure-taskbar-20260710/pure-restored-no-taskbar-entry.png`。
- 最终验收的对象身份、配置、日志和自动测试输出：`.tmp_acceptance/v0.6-final-20260710-235245/evidence/`。
- 其余截图作为本次 Computer Use 会话证据；正式发布前如需长期归档，应由人工补证时一并保存到发布证据目录。

## 7. 当前结论

**验收结论：通过，可进入发布收口。**

最终候选包身份、核心桌宠体验、Settings/Wizard 全出口、诊断摘要、配置安全写入与恢复、日志轮换、点击穿透保护、普通/纯桌宠托盘策略和 v0.4/v0.5 回归均有实际证据并通过，当前无发布阻塞项。

真实登录开机自启继续标记为“暂不验证”，不得写成通过。其自动验证只证明注册表命令格式、启停事务和失败补偿契约，不证明真实 Windows 登录后一定会启动。该能力默认关闭，未验证不会影响手动启动、桌宠主流程、配置安全或退出/找回路径，因此作为 v0.6 Beta 已知限制和发布后观察项，不阻塞本次发布；发布说明必须明确披露。
