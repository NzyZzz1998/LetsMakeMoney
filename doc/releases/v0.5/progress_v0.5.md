# LetsMakeMoney v0.5 Beta 进度看板

## 1. 当前状态

| 项目 | 状态 |
|---|---|
| 当前版本 | v0.5 Beta |
| 当前阶段 | `/acceptance` 未通过 / 发布阻塞 |
| 当前分支 | main |
| 版本定位 | 偏好设置与桌宠边缘体验收敛版 |
| 开发状态 | 实现完成 |
| 发布状态 | 未发布，托盘纯桌宠恢复人工复测阻塞 |

## 2. Progress 使用规则

本文件只记录 v0.5 状态看板和最小可执行任务 checklist。

不写入本文件的内容：

- 开发日志
- bugfix 流水账
- 技术排查过程
- 根因分析长文
- 素材生成实验记录
- 临时截图评价

这些内容应进入独立开发日志、缺陷修复日志、Spike 日志或验证文档。

## 3. 范围确认

### 已确认输入

- [x] `doc/releases/v0.5/idea-pool.md`
- [x] `doc/releases/v0.5/prd.md`
- [x] `doc/prototypes/index.html`
- [x] `doc/prototypes/prototype-spec.md`
- [x] `doc/current.md`
- [x] `doc/releases/v0.4/status.md`
- [x] `doc/releases/v0.4/verification.md`

### v0.5 范围

- [x] 主线 A：Wizard / Settings 共享控件系统。
- [x] 主线 B：托盘 / 点击穿透 / 纯桌宠边缘体验稳定化。
- [x] 支撑项：progress 文档治理和文档口径扫描。
- [x] 有限 polish：只做依赖共享控件系统的 Settings / Wizard 一致性修复。

### 不进入 v0.5

- [x] 主题系统。
- [x] 安装器。
- [x] 自动更新。
- [x] 多平台支持。
- [x] 更多宠物。
- [x] ComfyUI 正式产品化。

## 4. 总体进度

| 模块 | 名称 | 状态 | 说明 |
|---|---|---|---|
| V05-PRE | PRD 与原型确认 | 完成 | 用户已确认 v0.5 完整 PRD 和高保真原型 |
| V05-M0 | 开发基线与文档壳 | 完成 | v0.5 状态、验证、日志治理入口已建立 |
| V05-M1 | 共享 Warm Control 基础 | 完成 | 已建立共享 token 和控件 helper |
| V05-M2 | Settings 迁移到共享控件 | 实现完成 / 待截图验收 | 五页签已接入共享控件系统 |
| V05-M3 | Wizard 迁移到共享控件 | 实现完成 / 待截图验收 | Wizard 已接入共享控件系统 |
| V05-M4 | 托盘 / 点击穿透 / 纯桌宠稳定化 | 实现完成 / 待人工托盘验收 | 已补恢复策略稳定日志和穿透保护日志 |
| V05-M5 | 验证脚本与人工验收文档 | 完成 | v0.5 验证入口与回归命令已可用 |
| V05-M6 | 有限视觉基线与发布文档收口 | 实现完成 / 待 acceptance | 已完成截图基线和发布文档准备，托盘路径等待真实验收 |

## 5. V05-PRE：PRD 与原型确认

- [x] V05-PRE-001：完成 v0.5 idea pool。
- [x] V05-PRE-002：完成 v0.5 完整 PRD。
- [x] V05-PRE-003：完成 v0.5 高保真交互原型更新。
- [x] V05-PRE-004：确认 v0.5 不扩展主题系统、安装器、自动更新、多平台、更多宠物、ComfyUI 正式产品化。
- [x] V05-PRE-005：用户确认 `dev_plan_v0.5.md` 和 `progress_v0.5.md` 后进入实现。

## 6. V05-M0：开发基线与文档壳

目标：建立 v0.5 独立状态入口和 progress 文档治理边界。

- [x] V05-M0-001：创建 `doc/releases/v0.5/status.md`。
- [x] V05-M0-002：创建 `doc/releases/v0.5/verification.md`。
- [x] V05-M0-003：创建 `doc/releases/v0.5/release-checklist.md`。
- [x] V05-M0-004：创建 `doc/logs/README.md`，定义 progress 与 `dev-log`（开发日志）、`bugfix-log`（缺陷修复日志）、`spike-log`（Spike 日志）的边界。
- [x] V05-M0-005：识别 `doc/progress.md` 中应迁出的开发日志、bugfix、技术排查、spike 内容类型。
- [x] V05-M0-006：创建 `scripts/check_docs_status.ps1`。
- [x] V05-M0-007：检查 `doc/current.md` 与 v0.5 文档入口的推荐阅读顺序。
- [x] V05-M0-008：运行文档口径扫描，确认没有 v0.4/test/tag 旧状态误导。

验收：

- [x] V05-M0-VAL-001：`doc/releases/v0.5/status.md` 可作为 v0.5 当前状态摘要。
- [x] V05-M0-VAL-002：`doc/releases/v0.5/verification.md` 可直接用于人工填写。
- [x] V05-M0-VAL-003：`progress_v0.5.md` 不包含开发日志和 bugfix 流水内容。

## 7. V05-M1：共享 Warm Control 基础

目标：提供 Settings / Wizard 共用的轻量控件系统。

- [x] V05-M1-001：盘点 `settings_dialog.gd` 中现有 token 和 style helper。
- [x] V05-M1-002：盘点 `wizard_dialog.gd` 中现有 token 和 style helper。
- [x] V05-M1-003：确定共享 helper 文件位置，优先使用 `src/ui/warm_control_theme.gd`。
- [x] V05-M1-004：抽取颜色 token。
- [x] V05-M1-005：抽取尺寸 token。
- [x] V05-M1-006：实现 StyleBox 构造 helper。
- [x] V05-M1-007：实现 button helper。
- [x] V05-M1-008：实现 LineEdit / SpinBox helper。
- [x] V05-M1-009：实现 OptionButton / popup helper。
- [x] V05-M1-010：实现 switch / CheckButton helper。
- [x] V05-M1-011：实现 slider helper。
- [x] V05-M1-012：实现 scrollbar helper。
- [x] V05-M1-013：实现 compact row / section divider helper。
- [x] V05-M1-014：实现行内状态 / 轻提示 helper。
- [x] V05-M1-015：确认 helper 不包含配置保存、薪资计算或窗口策略业务逻辑。

验收：

- [x] V05-M1-VAL-001：脚本能检查共享 helper 文件和关键方法存在。
- [x] V05-M1-VAL-002：Settings 和 Wizard 均可引用共享 helper。
- [x] V05-M1-VAL-003：OptionButton popup 暖色样式有统一入口。

## 8. V05-M2：Settings 迁移到共享控件

目标：Settings 五页签统一接入共享控件系统。

- [x] V05-M2-001：Settings shell 接入共享背景、圆角、边框。
- [x] V05-M2-002：Settings tabs 接入共享 segmented tabs。
- [x] V05-M2-003：Settings action bar 接入共享 button。
- [x] V05-M2-004：工资页迁移月薪 SpinBox。
- [x] V05-M2-005：工资页迁移休息模式 OptionButton。
- [x] V05-M2-006：工资页迁移上班 / 下班时间输入。
- [x] V05-M2-007：工资页迁移每日工作小时数只读展示。
- [x] V05-M2-008：桌宠页迁移宠物选择列表和说明区。
- [x] V05-M2-009：显示页迁移透明度 slider。
- [x] V05-M2-010：显示页迁移缩放 slider。
- [x] V05-M2-011：显示页迁移窗口模式 OptionButton。
- [x] V05-M2-012：显示页迁移纯桌宠模式 switch。
- [x] V05-M2-013：显示页降级点击穿透和原生能力为低权重说明。
- [x] V05-M2-014：面板页迁移面板项目开关。
- [x] V05-M2-015：通用页迁移开机自启、隐藏到托盘、维护按钮。
- [x] V05-M2-016：统一保存成功反馈。
- [x] V05-M2-017：统一无变化保存反馈。
- [x] V05-M2-018：统一保存失败反馈。
- [x] V05-M2-019：确认取消、关闭、重置窗口位置、恢复默认显示设置行为不变。

验收：

- [x] V05-M2-VAL-001：Settings 工资页截图与 v0.5 原型方向一致。
- [x] V05-M2-VAL-002：Settings 显示页截图与 v0.5 原型方向一致。
- [x] V05-M2-VAL-003：Settings 通用页截图与 v0.5 原型方向一致。
- [x] V05-M2-VAL-004：OptionButton 展开后不出现深色系统菜单风格。
- [ ] V05-M2-VAL-005：保存、无变化、保存失败状态可区分。

## 9. V05-M3：Wizard 迁移到共享控件

目标：Wizard 使用与 Settings 一致的控件系统，重点修复 v0.4 薪资页差异。

- [x] V05-M3-001：Wizard shell 接入共享背景、圆角、边框。
- [x] V05-M3-002：Wizard step indicator 接入共享样式。
- [x] V05-M3-003：Wizard 上一步 / 下一步 / 完成 / 取消按钮接入共享 button。
- [x] V05-M3-004：欢迎页收敛为紧凑小工具配置面板。
- [x] V05-M3-005：薪资页月薪 SpinBox 复用 Settings 控件。
- [x] V05-M3-006：薪资页休息模式 OptionButton 复用 Settings 控件。
- [x] V05-M3-007：薪资页时间输入复用 Settings 控件。
- [x] V05-M3-008：宠物页保证初始化时至少有当前可选宠物。
- [x] V05-M3-009：宠物页选择控件接入共享样式。
- [x] V05-M3-010：确认页展示配置摘要和完成按钮。
- [x] V05-M3-011：下一步、上一步、完成、取消、关闭路径保持可用。
- [x] V05-M3-012：Wizard 打开时保护点击穿透，关闭后恢复。

验收：

- [x] V05-M3-VAL-001：Wizard 欢迎页截图通过。
- [x] V05-M3-VAL-002：Wizard 薪资 / 时间页截图通过。
- [x] V05-M3-VAL-003：Wizard 宠物页截图通过。
- [x] V05-M3-VAL-004：Wizard 确认页截图通过。
- [ ] V05-M3-VAL-005：Wizard 可以完成重新配置。

## 10. V05-M4：托盘 / 点击穿透 / 纯桌宠稳定化

目标：收敛托盘恢复、点击穿透保护和纯桌宠找回路径。

- [x] V05-M4-001：梳理现有托盘左键隐藏 / 显示流程。
- [x] V05-M4-002：梳理现有托盘右键菜单流程。
- [x] V05-M4-003：梳理 pure pet mode 应用流程。
- [x] V05-M4-004：定义恢复窗口后的策略重应用顺序。
- [x] V05-M4-005：托盘左键显示后重新应用 taskbar visibility。
- [x] V05-M4-006：托盘左键显示后重新应用 pure pet mode。
- [x] V05-M4-007：托盘左键显示后重新应用 mouse passthrough rect。
- [x] V05-M4-008：设置页打开时 suspend passthrough。
- [x] V05-M4-009：Wizard 打开时 suspend passthrough。
- [x] V05-M4-010：右键菜单打开期间保护交互区域。
- [x] V05-M4-011：native 不可用时降级为可找回普通窗口。
- [x] V05-M4-012：补充 tray / pure pet / passthrough 关键日志事件。

验收：

- [ ] V05-M4-VAL-001：托盘左键隐藏后可再次显示。
- [ ] V05-M4-VAL-002：纯桌宠模式恢复后任务栏策略符合配置。
- [ ] V05-M4-VAL-003：设置页打开期间不会被点击穿透破坏。
- [ ] V05-M4-VAL-004：Wizard 打开期间不会被点击穿透破坏。
- [ ] V05-M4-VAL-005：native 不可用时仍有可找回路径。
- [x] V05-M4-VAL-006：debug.log 中可搜索到关键事件。

## 11. V05-M5：验证脚本与人工验收文档

目标：建立 v0.5 独立验证入口，并保留 v0.4 回归。

- [x] V05-M5-001：创建 `scripts/verify_v05.gd`。
- [x] V05-M5-002：创建 `scripts/verify_v05.ps1`。
- [x] V05-M5-003：验证共享 helper 和关键方法存在。
- [x] V05-M5-004：验证 Settings 五页签关键节点存在。
- [x] V05-M5-005：验证 Wizard 四步骤关键节点存在。
- [x] V05-M5-006：验证关键配置字段没有新增语义变化。
- [x] V05-M5-007：验证日志事件入口存在。
- [x] V05-M5-008：更新 `doc/releases/v0.5/verification.md` 为可填写格式。
- [x] V05-M5-009：保留 v0.4 / M4 / M5 回归命令。

验收：

- [x] V05-M5-VAL-001：`verify_v05.ps1` 可运行。
- [x] V05-M5-VAL-002：`verify_v04.ps1` 回归通过或记录明确差异。
- [x] V05-M5-VAL-003：`verify_m4.ps1` 回归通过或记录明确差异。
- [x] V05-M5-VAL-004：`verify_m5.ps1` 回归通过或记录明确差异。
- [x] V05-M5-VAL-005：人工验证文档可直接填写结果和备注。

## 12. V05-M6：有限视觉基线与发布文档收口

目标：基于 v0.5 原型做有限视觉一致性验收，并准备发布文档。

- [x] V05-M6-001：截取 Settings 工资页并对照原型。
- [x] V05-M6-002：截取 Settings 显示页并对照原型。
- [x] V05-M6-003：截取 Wizard 薪资页并对照原型。
- [x] V05-M6-004：截取 Wizard 确认页并对照原型。
- [ ] V05-M6-005：截取托盘 / 纯桌宠恢复路径示意。
- [x] V05-M6-006：更新 `doc/releases/v0.5/status.md`。
- [x] V05-M6-007：更新 `doc/releases/v0.5/release-checklist.md`。
- [x] V05-M6-008：准备 v0.5 release notes。
- [x] V05-M6-009：准备 v0.5 package / package verification 脚本。
- [x] V05-M6-010：发布前同步 `doc/current.md`。

验收：

- [ ] V05-M6-VAL-001：实现截图与 v0.5 原型方向一致。
- [ ] V05-M6-VAL-002：release checklist 无阻塞项。
- [x] V05-M6-VAL-003：当前入口、状态文档和发布说明不存在旧版本事实冲突。
- [x] V05-M6-VAL-004：发布包命名、manifest、checksum、README 与 v0.5 一致。

## 13. 当前阻塞与待确认

当前没有实现前阻塞。

进入实现前确认：

- [x] 用户确认 `dev_plan_v0.5.md`。
- [x] 用户确认 `progress_v0.5.md`。

实现过程中预计需要人工协助：

- [ ] Windows 托盘左键 / 右键路径复测。
- [ ] 纯桌宠模式恢复路径复测。
- [x] Settings / Wizard 视觉截图确认。
- [x] 导出包启动验证。

## 14. 下一步

进入 `/acceptance`，按 `doc/releases/v0.5/verification.md` 做真实托盘、纯桌宠、点击穿透、保存反馈和发布包验收。不在本 progress 中记录开发流水或 bugfix 过程。
## 15. 最终验收签核 - 2026-07-09

progress 仍然只作为实现清单，不作为缺陷修复日志。最终 `/acceptance` 结果仅在这里作为发布状态摘要记录：

- v0.5 实现清单：已完成。
- 自动验证和包验证：已完成。
- Settings / Wizard 定向验收：已完成。
- 托盘左键纯桌宠恢复：仍是发布阻塞项，直到记录通过的人工复测证据。
- 发布状态：暂不可发布。

发布阻塞项必须复测：

- [ ] 使用 `releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip`。
- [ ] 开启纯桌宠模式。
- [ ] 左键点击托盘图标隐藏桌宠。
- [ ] 再次左键点击托盘图标恢复桌宠。
- [ ] 确认桌宠恢复后没有任务栏入口。
- [ ] 将相关 `debug.log` 尾部日志粘贴到 `verification.md`。
