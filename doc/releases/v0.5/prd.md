# LetsMakeMoney v0.5 Beta PRD

**版本定位**: 偏好设置与桌宠边缘体验收敛版
**来源**: [v0.5 idea pool](idea-pool.md)、v0.4 review / acceptance / verification / progress / release docs
**状态**: 已确认并进入实现，当前仅作为 v0.5 范围事实源。

## 1. PRD 类型判断与方案收敛

v0.5 是收敛型 PRD，不是新功能扩张型 PRD。它承接 v0.4 大型体验优化后的遗留问题，目标是把 Settings、Wizard、托盘、点击穿透、纯桌宠恢复、日志和文档事实源整理成稳定闭环。

### 推荐方案

采用 idea-pool 中的推荐方案：

- 主线 A：Wizard / Settings 共享控件系统。
- 主线 B：托盘 / 点击穿透 / 纯桌宠边缘体验稳定化。
- 支撑项：progress 文档治理和文档口径扫描。
- IDEA-005 视觉一致性二阶段 polish 只作为依赖 IDEA-001 的有限范围，不做主题系统。

### 本次不做

不做主题系统、安装器、自动更新、多平台、更多宠物、ComfyUI 正式产品化，也不重写桌宠核心状态机。

## 2. 版本目标

### 用户目标

- 首次配置和后续设置的体验一致、清晰、可靠。
- 托盘隐藏/恢复、纯桌宠模式、点击穿透和可找回路径稳定可验证。
- 遇到保存失败、无变化保存、配置损坏或 native 不可用时有清晰反馈。

### 产品目标

- Settings / Wizard 使用同一套 Warm Control 组件语言。
- 桌宠边缘体验有明确日志和手动验收路径。
- progress 回归 PM 状态看板，开发流水迁出到 logs。
- release 文档、verification 和 current/status 形成一致事实源。

## 3. 功能需求

### FR-001 Settings / Wizard 共享控件系统

共享控件系统覆盖：Button、LineEdit、SpinBox、OptionButton、Switch / CheckButton、Slider、Section Row、Action Bar、Inline Message、Popup Menu / Option Popup、Readonly Row。

每类控件统一：尺寸、字体、颜色、边框、圆角、hover、pressed、disabled、error、focus、selected、expanded。控件风格遵循 v0.4 的暖桌面小挂件方向：奶油纸面、金币黄、橘猫橙、深咖啡文字和轻量暖色边框。

Settings 五页签接入：

| 页签 | 接入控件 | 说明 |
|---|---|---|
| 工资 | SpinBox、OptionButton、Readonly Row、Action Bar | 月薪、休息模式、上下班时间、每日工作小时数统一样式。 |
| 桌宠 | OptionButton / Item List、Readonly Preview、Info Row | 宠物选择可用，当前宠物可识别。 |
| 显示 | Slider、OptionButton、Switch、Info Row | 透明度、缩放、窗口模式、纯桌宠模式统一。 |
| 面板 | Switch、Readonly Preview、Button | 面板显示项和预览统一。 |
| 通用 | Switch、Button、Inline Message | 开机自启、关闭隐藏到托盘、重置/恢复默认等维护操作统一。 |

Wizard 接入：欢迎页、薪资/时间页、宠物页、完成/确认页。Wizard 不改变业务流程，只复用 Settings 的控件和反馈状态。

本次不覆盖：完整主题系统、第三方 UI 框架、复杂动画控件、安装器 UI。

### FR-002 Settings 完整链路

必须覆盖：打开设置、保存、取消、关闭、恢复默认、无变化保存、保存失败。

预期行为：

- 保存成功：显示已保存反馈，写入配置，记录 `settings_save_success`。
- 无变化保存：显示无变化反馈，不误报失败，记录 `settings_save_no_change`。
- 保存失败：显示可读失败原因，用户输入保留，配置不被假装写入成功，记录 `settings_save_failed` 和底层 `config_save_failed`。
- 取消 / 关闭：不保存未确认修改，恢复桌宠点击穿透策略。

### FR-003 Wizard 完整链路

必须覆盖：从 Settings 重新运行向导、下一步、上一步、完成、取消、关闭。

预期行为：

- 步骤切换记录 `wizard_step_changed`。
- 完成记录 `wizard_finished` 与 `wizard_closed: reason=finished`。
- 取消记录 `wizard_cancelled` 与 `wizard_closed: reason=cancelled`。
- 打开和关闭期间保护点击穿透，不让透明区域误穿透到桌面。

### FR-004 托盘 / 纯桌宠 / 点击穿透稳定化

必须覆盖：托盘左键隐藏/显示、托盘右键菜单、关闭隐藏到托盘、纯桌宠模式恢复、点击穿透刷新和 native 降级。

预期行为：

- 非纯桌宠模式：左键托盘图标可隐藏/显示窗口，显示窗口时允许任务栏入口存在。
- 纯桌宠模式：左键托盘图标可隐藏/显示窗口，显示窗口时不应出现任务栏入口。
- Settings / Wizard / 菜单打开时暂停或保护点击穿透；关闭后恢复。
- native 不可用、托盘不可用或配置损坏时降级到可找回普通窗口，不进入不可恢复状态。

### FR-005 文档治理

新增并维护：`doc/logs/README.md`、`doc/logs/v0.5-dev-log.md`、`doc/logs/v0.5-bugfix-log.md`、`doc/logs/v0.5-spike-log.md`、`scripts/check_docs_status.ps1`。

progress 只保留：版本目标、模块状态、最小任务 checklist、验收状态、发布前阻塞项。

迁出到 logs：开发流水、bugfix 根因、技术排查、素材生成 Spike、工具安装过程、临时路径。

## 4. 数据与配置

不新增配置字段。

涉及现有字段：

| 字段 | 用途 | v0.5 说明 |
|---|---|---|
| `monthly_salary` | 月薪 | Settings/Wizard 使用同一 SpinBox。 |
| `rest_mode` | 单休/双休 | Settings/Wizard 使用同一 OptionButton。 |
| `work_start_hour` / `work_start_minute` | 上班时间 | 统一时间输入。 |
| `work_end_hour` / `work_end_minute` | 下班时间 | 统一时间输入。 |
| `selected_pet` | 当前宠物 | 不新增宠物，只统一选择控件。 |
| `opacity` | 透明度 | 使用共享 Slider。 |
| `scale` | 缩放 | 使用共享 Slider。 |
| `window_mode` | 置顶 / 融入桌面 | 使用共享 OptionButton。 |
| `pure_pet_mode` | 纯桌宠模式 | 使用共享 Switch，并影响任务栏策略。 |
| `minimize_to_tray` | 关闭隐藏到托盘 | 使用共享 Switch。 |
| `debug_mode` | Debug 模式 | 保持现有语义。 |
| `auto_start` | 开机自启 | 保持现有语义。 |

旧配置缺字段时继续使用默认值；配置损坏时降级到默认配置并记录日志。

## 5. 原型与线框

高保真原型继续维护在：

- `doc/prototypes/index.html`
- `doc/prototypes/prototype-spec.md`

低保真结构：

```text
Settings
+------------------------------------------------+
| tabs: 工资 桌宠 显示 面板 通用             x |
|------------------------------------------------|
| 当前页标题                                     |
| Section                                        |
|   label                         [control]      |
|   label                         [control]      |
| Inline feedback                                |
|------------------------------------------------|
|                         [取消] [保存]          |
+------------------------------------------------+

Wizard
+------------------------------------------------+
| step title                                  x  |
|------------------------------------------------|
| shared form rows / option popup / feedback     |
|------------------------------------------------|
|                    [上一步] [下一步/完成]      |
+------------------------------------------------+

Tray / pure pet
托盘左键 -> 隐藏窗口 -> 托盘保留
再次左键 -> 恢复桌宠 -> 重新应用 pure_pet_mode / taskbar / passthrough 策略
```

## 6. 影响范围

| 范围 | 是否影响 | 说明 |
|---|---|---|
| UI / Godot 场景 | 是 | `settings_dialog.gd`、`wizard_dialog.gd`、共享 warm control helper。 |
| config | 是 | 不新增字段，但保存失败/无变化/兼容路径需清晰。 |
| native/window | 是 | 纯桌宠、任务栏、恢复策略。 |
| tray | 是 | 左键隐藏/显示、右键菜单、可找回路径。 |
| mouse passthrough | 是 | Settings/Wizard/Menu 打开时保护，关闭后恢复。 |
| logs | 是 | 增加清晰语义事件。 |
| docs | 是 | v0.5 文档事实源和 logs 拆分。 |
| prototypes | 是 | v0.5 视图和说明同步。 |
| verification scripts | 是 | v0.5 专属验证脚本和包验证。 |
| release notes | 是 | v0.5 Beta 发布说明同步。 |

## 7. 开发前验收与指标

### 必须截图

- Settings 工资页、显示页、通用页。
- Settings OptionButton 展开状态。
- Wizard 欢迎页、薪资页、宠物页、确认页。
- 托盘隐藏/恢复路径，尤其纯桌宠恢复后任务栏状态。

### 必须出现的日志事件

- `settings_save_success`
- `settings_save_no_change`
- `settings_save_failed`
- `wizard_opened`
- `wizard_step_changed`
- `wizard_finished`
- `wizard_cancelled`
- `wizard_closed`
- `tray_toggle_requested`
- `window_policy_reapplied`
- `pure_pet_mode_apply`
- `passthrough_suspended`
- `passthrough_resumed`

### 通过标准

- Settings / Wizard 共享控件系统在主要路径中可见且一致。
- 保存成功、无变化、失败三种反馈可区分。
- Wizard 可完成重新配置。
- 非纯桌宠和纯桌宠的托盘左键隐藏/显示逻辑均符合预期。
- 纯桌宠恢复后不出现任务栏入口。
- 点击穿透保护不破坏 Settings / Wizard / 菜单交互。
- 自动验证、包验证和文档口径扫描通过。

### 不通过处理

- 实现 bug 记录到 `doc/logs/v0.5-bugfix-log.md`。
- 验证不足记录到 `verification.md`。
- 不把 v0.5 收尾问题扩展为主题系统、安装器、自动更新、多平台或更多宠物需求。
