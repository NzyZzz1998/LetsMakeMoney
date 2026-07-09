# LetsMakeMoney v0.5 Beta 开发实施计划

> 给后续 agent 的说明：这是 v0.5 Beta 的开发承接计划。计划未确认前，不应开始业务代码实现。

## 1. 范围一致性 Review

### 1.1 已确认输入

- `doc/releases/v0.5/idea-pool.md`
- `doc/releases/v0.5/prd.md`
- `doc/prototypes/index.html`
- `doc/prototypes/prototype-spec.md`
- `doc/current.md`
- `doc/releases/v0.4/status.md`
- `doc/releases/v0.4/verification.md`
- `doc/progress.md`

### 1.2 v0.5 版本定位

v0.5 Beta 是 **偏好设置与桌宠边缘体验收敛版**，与 v0.4 平级，不是 v0.4 附录。

本版本承接 v0.4 的已验证状态和遗留结论：

- `V04-MAN-052`：Wizard 薪资页视觉和控件一致性仍需进入后续优化。
- `V04-MAN-061`：托盘显示/隐藏与纯桌宠恢复链路已可用，但边缘稳定性仍需收敛。
- `V04-MAN-072`：连续交互整体可用，但长按、拖拽、右键、点击穿透组合仍需做稳定性验收。
- `V04-MAN-073`：日志基础可用，v0.5 需要让日志更适合验收和回归定位。

### 1.3 本次范围

v0.5 推荐方案包含：

- 主线 A：Wizard / Settings 共享控件系统。
- 主线 B：托盘 / 点击穿透 / 纯桌宠边缘体验稳定化。
- 支撑项：progress 文档治理和文档口径扫描。
- 有限 polish：只做依赖共享控件系统的一致性修复，不扩展为主题系统。

### 1.4 明确不做

- 不做主题系统。
- 不做安装器。
- 不做自动更新。
- 不做多平台支持。
- 不新增更多宠物。
- 不把 ComfyUI 正式产品化。
- 不改变薪资计算、配置字段语义或桌宠交互业务目标。

## 2. 实施原则

1. 先搭共享控件基础，再迁移 Settings，再迁移 Wizard。
2. 先保证现有功能行为不变，再做视觉一致性。
3. 托盘、点击穿透、纯桌宠只做边缘稳定化，不重新设计整套窗口系统。
4. `progress_v0.5.md` 只记录状态看板，不写开发日志、bugfix 流水账或技术排查过程。
5. 文档治理优先用新增索引和迁出规则，避免删除历史内容。
6. 每个里程碑完成后更新 v0.5 progress checklist，再进入下一模块。

## 3. 影响范围

### 3.1 UI / Godot 场景

预计修改：

- `src/scenes/settings/settings_dialog.gd`
- `src/scenes/settings/settings_dialog.tscn`
- `src/scenes/wizard/wizard_dialog.gd`
- `src/scenes/wizard/wizard_dialog.tscn`

预计新增或抽取：

- `src/ui/warm_control_theme.gd`

该文件仅承载 Settings / Wizard 可复用的轻量控件样式、尺寸 token 和构建 helper，不做主题切换系统。

### 3.2 配置

预计读取现有字段，不新增配置字段：

- `monthly_salary`
- `rest_mode`
- `work_start_hour`
- `work_start_minute`
- `work_end_hour`
- `work_end_minute`
- `current_pet_id`
- `opacity`
- `scale`
- `window_mode`
- `pure_pet_mode`
- `mouse_passthrough_enabled`
- `minimize_to_tray`
- `system_tray_enabled`
- `auto_start`
- `panel_items`
- `debug_mode`

涉及文件：

- `src/autoload/config.gd`

### 3.3 原生窗口 / 托盘 / 点击穿透

预计修改：

- `src/scenes/main/main.gd`
- `src/autoload/drag_resize_system.gd`
- `src/autoload/platform.gd`
- `src/platform/windows_platform.gd`

关注链路：

- 设置页 / Wizard 打开时，点击穿透必须临时保护。
- 设置页 / Wizard 关闭后，恢复桌宠窗口策略。
- 托盘左键隐藏 / 显示后，重新应用纯桌宠、任务栏可见性和点击穿透策略。
- native 不可用时保留可找回路径，不让窗口不可见且无法恢复。

### 3.4 日志

预计增强但不改变用户配置：

- `debug.log` 中增加可验收事件。
- 事件命名应稳定，便于脚本和人工搜索。

重点事件：

- 设置打开、关闭、保存、无变化保存、保存失败。
- 向导打开、步骤切换、完成、取消、关闭。
- 托盘切换请求、原生显示/隐藏结果、窗口策略重新应用。
- 点击穿透暂停、恢复、区域刷新。
- 纯桌宠模式应用与降级。

### 3.5 文档 / 原型 / 验证

预计新增：

- `doc/releases/v0.5/status.md`
- `doc/releases/v0.5/verification.md`
- `doc/releases/v0.5/release-checklist.md`
- `doc/logs/README.md`
- `doc/logs/v0.4-dev-log.md`
- `doc/logs/v0.4-bugfix-log.md`
- `doc/logs/v0.4-spike-log.md`
- `scripts/verify_v05.ps1`
- `scripts/verify_v05.gd`
- `scripts/check_docs_status.ps1`

预计更新：

- `doc/current.md`
- `doc/releases/v0.5/README.md`，如当前不存在则创建。
- `doc/prototypes/index.html`
- `doc/prototypes/prototype-spec.md`
- `README.md`，仅在发布收口时同步版本状态。

## 4. 实施里程碑

### V05-M0：开发基线与文档壳

目标：在动业务代码前建立 v0.5 独立承接结构和文档治理边界。

任务：

1. 创建 `doc/releases/v0.5/status.md`，记录 v0.5 当前阶段、已完成、待开发、待验证和阻塞项。
2. 创建 `doc/releases/v0.5/verification.md`，作为 v0.5 手动验证入口。
3. 创建 `doc/releases/v0.5/release-checklist.md`，列出发布前文档、包体、日志、脚本检查。
4. 创建 `doc/logs/README.md`，定义开发日志、缺陷修复日志、Spike 日志与 progress 的边界。
5. 从 `doc/progress.md` 中识别应迁出的内容类型，但第一步不强行大搬迁。
6. 创建 `scripts/check_docs_status.ps1`，扫描当前入口、状态、发布说明和发布清单中的版本口径冲突。

验证：

```powershell
rg -n "v0\.5|V05|当前阶段|待验证" doc/releases/v0.5 doc/current.md
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_docs_status.ps1
```

回退：

- 若文档拆分造成引用混乱，保留新增索引文件，暂缓迁出历史内容。

### V05-M1：共享暖色控件基础

目标：建立 Settings / Wizard 共用的控件系统，消除两套样式各自复制的问题。

任务：

1. 盘点 `settings_dialog.gd` 与 `wizard_dialog.gd` 中已有 token、StyleBox、控件 helper。
2. 新增轻量 helper：`src/ui/warm_control_theme.gd`。
3. 抽取共享 token：
   - 表面色、纸面色、卡片色、选中色。
   - 主文字、辅助文字、危险提示。
   - 金币黄、橘猫橙、柔和绿色。
   - 暖色边框、暖色阴影。
4. 抽取共享尺寸：
   - 设置行高度。
   - 输入框高度。
   - 按钮高度。
   - 标签高度。
   - 开关尺寸。
   - 滑杆轨道和滑块尺寸。
   - 滚动条宽度。
5. 抽取控件 helper：
   - 主按钮、次按钮、危险按钮。
   - `LineEdit` 输入框。
   - `SpinBox` 数字输入。
   - `OptionButton` 及其下拉弹层。
   - 开关 / `CheckButton`。
   - 滑杆。
   - 紧凑设置行。
   - 分区分割线。
   - 行内状态 / 轻量提示。
6. 保留 Settings / Wizard 各自业务逻辑，不把表单状态放进 helper。

验证：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v05.ps1
```

自动检查应覆盖：

- helper 文件存在。
- 必要 token / helper 方法存在。
- OptionButton popup 暖色样式可被 Settings / Wizard 复用。
- helper 不包含配置保存逻辑。

回退：

- 如果抽取过深导致风险升高，保留 helper 只提供 token 和 StyleBox 构造，暂不抽表单构建。

### V05-M2：Settings 迁移到共享控件

目标：Settings 五页签使用同一套 Warm Fluent Compact 控件，保持 v0.4 的小偏好面板方向。

任务：

1. 将 Settings 外壳、标签和操作栏接入共享 token。
2. 工资页接入共享 row、SpinBox、OptionButton 和只读值。
3. 桌宠页接入共享列表、说明区和宠物选择状态。
4. 显示页接入共享 slider、OptionButton、switch 和状态说明。
5. 面板页接入共享 switch / checkbox row。
6. 通用页接入共享 switch、维护按钮和低权重说明。
7. 保存反馈统一：
   - 已保存
   - 无变化
   - 需重显
   - 保存失败
8. 保持取消、关闭、恢复默认、重置窗口位置的现有语义。
9. 保持五页签中文文案和 v0.5 原型一致。

验证：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v05.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v04.ps1
```

人工截图：

- Settings 工资页。
- Settings 显示页。
- Settings 通用页。
- OptionButton 展开状态。
- 保存成功、无变化、保存失败或模拟失败状态。

回退：

- 如果某页迁移后布局不稳，可以只回退该页到旧构建方式，但继续使用共享 token。

### V05-M3：Wizard 迁移到共享控件

目标：首次向导与重新运行向导不再像另一套 UI，重点修复 v0.4 遗留的薪资页一致性问题。

任务：

1. Wizard shell、按钮、步骤指示器接入共享控件。
2. 欢迎页收敛为紧凑暖色小工具面板。
3. 薪资 / 时间页复用 Settings 的 SpinBox、OptionButton、time row。
4. 宠物页复用统一选择控件，确保初始化有动物可选。
5. 确认页展示配置摘要和完成动作。
6. 下一步、上一步、完成、取消、关闭路径保持原语义。
7. Wizard 打开时暂停点击穿透，关闭后恢复点击穿透。
8. 保存完成后写入现有配置字段，不新增字段。

验证：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v05.ps1
```

人工截图：

- Wizard 欢迎页。
- Wizard 薪资 / 时间页。
- Wizard 宠物页。
- Wizard 确认页。
- Wizard OptionButton 展开状态。

回退：

- 如果 Wizard 全量迁移影响流程，先保留流程代码，仅迁移控件样式和 spacing。

### V05-M4：托盘 / 点击穿透 / 纯桌宠边缘体验稳定化

目标：收敛 v0.4 的边缘体验债，让窗口恢复、找回和输入保护更可验收。

任务：

1. 明确窗口策略重应用顺序：
   - 原生窗口可见性。
   - 任务栏可见性。
   - 纯桌宠模式。
   - 鼠标点击穿透区域。
   - Panel / 菜单可交互区域。
2. 托盘左键隐藏 / 显示后强制重应用策略，不只依赖缓存。
3. 托盘右键菜单保持可用，菜单打开期间保护点击穿透。
4. 关闭隐藏到托盘时保留可找回路径。
5. 设置页 / Wizard 打开期间 suspend passthrough。
6. native 不可用时降级为普通窗口和任务栏入口，不进入不可找回状态。
7. 补充 debug.log 关键事件。

验证：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v05.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v04_stability.ps1
```

人工路径：

- 纯桌宠模式开关开启。
- 托盘左键隐藏，再左键显示。
- 确认恢复后任务栏策略符合配置。
- 右键托盘打开菜单。
- 从托盘打开设置。
- 关闭设置后桌宠恢复点击穿透。

回退：

- 若 native 策略不稳定，优先保留任务栏可见入口，牺牲纯桌宠隐藏效果，不牺牲可找回性。

### V05-M5：验证脚本与人工验收文档

目标：让 v0.5 可以被脚本和人工稳定验收，不依赖口头记忆。

任务：

1. 新增 `scripts/verify_v05.gd`。
2. 新增 `scripts/verify_v05.ps1`。
3. 验证共享控件 helper、Settings 结构、Wizard 结构、关键配置兼容。
4. 验证日志事件命名存在。
5. 更新 `doc/releases/v0.5/verification.md`，包含可填写结果和备注的表格。
6. 保留 v0.4/M4/M5 回归脚本。

验证命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v05.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v04.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_m4.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_m5.ps1
```

回退：

- 若无界面模式无法覆盖原生窗口行为，将原生行为保留为人工验收项，脚本只检查结构和日志入口。

### V05-M6：有限视觉基线与发布文档收口

目标：确认 Settings / Wizard / 托盘恢复路径与 v0.5 原型方向一致，并准备发布文档。

任务：

1. 对照 `doc/prototypes/index.html` 截图检查 Settings / Wizard 方向。
2. 更新 `doc/releases/v0.5/status.md`。
3. 更新 `doc/releases/v0.5/release-checklist.md`。
4. 发布前更新 `doc/current.md`。
5. 发布前新增或更新 v0.5 发布说明。
6. 发布前创建 v0.5 包体脚本或复用现有包体流程后显式改名。
7. 确认文档不再出现 v0.4 测试态、未合并、未打标签等旧口径。

验证：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_docs_status.ps1
rg -n "test|未合并|未 tag|v0\.4 Beta 测试态" doc README.md releases
```

回退：

- 如果 v0.5 发布文档尚未完全准备，保持 v0.5 为开发态，不更新 `current.md` 为已发布。

## 5. 完整测试命令

开发过程中优先运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v05.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v04.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_m4.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_m5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_docs_status.ps1
```

发布前追加：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\package_v05.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v05_package.ps1
```

如果 `package_v05.ps1` 尚未创建，不允许直接把 v0.4 包体重命名为 v0.5 发布包。

## 6. 人工验收路径

### 6.1 Settings

1. 打开桌宠。
2. 右键小猫，打开设置。
3. 依次截图：
   - 工资页
   - 桌宠页
   - 显示页
   - 面板页
   - 通用页
4. 展开休息模式、窗口模式、宠物选择等 OptionButton。
5. 修改一个设置并保存。
6. 不修改设置直接保存。
7. 测试取消和关闭。

### 6.2 Wizard

1. 从设置中重新运行向导。
2. 截图：
   - 欢迎页
   - 薪资 / 时间页
   - 宠物页
   - 确认页
3. 测试下一步、上一步、取消、关闭、完成。
4. 完成后确认配置写入。

### 6.3 Tray / Pure Pet / Passthrough

1. 开启纯桌宠模式。
2. 确认桌宠可见，任务栏策略符合配置。
3. 托盘左键隐藏。
4. 托盘左键显示。
5. 托盘右键打开菜单。
6. 从托盘菜单打开设置。
7. 关闭设置后确认桌宠和点击穿透恢复。
8. 查看 `debug.log` 是否包含对应事件。

### 6.4 回归

1. Panel 折叠 / 展开。
2. 小猫单击 / 双击 / 长按 / 拖拽 / 右键。
3. 设置保存。
4. 首次向导。
5. 导出包启动。

## 7. 风险与回退

| 风险 | 影响 | 回退策略 |
|---|---|---|
| 共享控件抽取过度 | Settings / Wizard 业务逻辑受影响 | helper 只保留 token 和样式构造，业务构建留在各场景 |
| OptionButton popup 样式受 Godot 限制 | 下拉仍有默认控件感 | 优先统一颜色和尺寸，保留行为；必要时记录后续优化 |
| 纯桌宠恢复受 Windows native 差异影响 | 托盘显示后任务栏状态不稳定 | 优先保证可找回，降级为任务栏可见 |
| 点击穿透保护遗漏 | 设置页或向导无法点击 | modal 打开时强制 suspend，关闭后统一 resume |
| 文档治理迁移过猛 | 历史引用断裂 | 本版本只新增索引和规则，不删除历史文档 |
| UI polish 范围蔓延 | v0.5 无法收口 | 只按 v0.5 原型对齐 Settings / Wizard / 恢复路径 |

## 8. 交付门槛

v0.5 进入发布收口前必须满足：

- Settings / Wizard 均使用共享控件系统的核心 token 和控件 helper。
- Wizard 薪资页不再明显落后于 Settings。
- 托盘显示 / 隐藏 / 纯桌宠恢复路径有日志、有人工验收结果。
- 点击穿透在设置页、Wizard、菜单打开期间有保护。
- `progress_v0.5.md` 只保留 checklist 和状态，不混入开发日志。
- v0.5 验证文档、状态文档、release checklist 存在。
- v0.5 原型方向与实现截图没有明显冲突。
