# 更新日志

## v0.5 Beta - 偏好设置与桌宠边缘体验收敛版（2026-07-09）

### 状态

- 最终验收结论：通过 / 可发布。
- 发布包：`releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip`

### 新增

- 新增 Settings / Wizard 共享 Warm Control 控件系统。
- 新增 v0.5 专属 PRD、实施计划、进度看板、验证文档、发布检查清单和打包脚本。
- 新增稳定语义日志，覆盖 Settings 保存结果、Wizard 步骤 / 完成 / 取消路径、托盘恢复、纯桌宠策略重应用和点击穿透保护。

### 变更

- Settings 和 Wizard 控件迁移到统一的紧凑暖色组件语言。
- 托盘恢复后重新应用窗口策略，使纯桌宠和非纯桌宠的任务栏入口行为更稳定。
- v0.5 范围保持克制：不做主题系统、安装器、自动更新、多平台发布、更多宠物或 ComfyUI 产品化。

### 修复

- 修复 Settings 保存失败时仍显示成功的问题。
- 修复 Settings 无变化保存、保存成功、保存失败反馈不够清晰的问题。
- 补齐 Wizard 下一步、上一步、完成、取消 / 关闭语义日志。
- 补齐托盘左键隐藏 / 恢复后的窗口策略重应用日志。
- 补齐纯桌宠恢复后任务栏入口策略验证。

### 验证

- `scripts\verify_v05.ps1` 通过。
- `scripts\verify_v04.ps1` 通过。
- `scripts\verify_m4.ps1` 通过。
- `scripts\verify_m5.ps1` 通过。
- `scripts\check_docs_status.ps1` 通过。
- `scripts\package_v05.ps1` 已生成发布包。
- `scripts\verify_v05_package.ps1` 通过。
- 实际运行发布包 exe 通过。
- Settings 保存成功 / 无变化 / 保存失败通过。
- Wizard 下一步 / 上一步 / 取消 / 完成日志通过。
- `pure_pet_mode=true` 恢复后主窗口为 `AppWindow=false / ToolWindow=true`。
- `pure_pet_mode=false` 恢复后主窗口为 `AppWindow=true / ToolWindow=false`。

### 已知说明

- Computer Use 无法稳定直接点击 Windows 通知区托盘图标。本轮托盘左键验收使用真实发布包 exe、native 托盘消息同路径、Win32 窗口样式和桌面截图补证。
- `passthrough_suspended` / `passthrough_resumed` 当前是 debug 级日志，默认 `debug_mode=false` 时不会每次写入。建议 v0.6 优化日志口径。
- `verify_v05.ps1` 返回通过，但 Godot headless 输出仍可能出现 parser 文本。建议 v0.6 优化脚本输出质量。

## v0.4 Beta - 大型体验优化版（2026-07-04）

### 新增

- 新增橘猫 v2 动画资源与 fallback 资源。
- 新增 Debug 命中区可视化能力。
- 新增 v0.4 自动验证脚本和发布包烟测脚本。
- 新增正式 Zip beta 打包脚本。

### 变更

- 优化小猫交互优先级与点击、双击、长按、拖拽状态仲裁。
- 优化 Panel 边缘定位。
- 优化设置页信息架构和保存反馈。
- 降低普通模式下高频 debug.log 噪音。

### 验证

- v0.4 自动验证、M4/M5 回归、包验证和稳定性验证已通过。

## v0.3 Beta - 桌宠原生能力修复版（2026-07-03）

### 新增

- 新增 Windows x86_64 native bridge。
- 新增 Win32 真系统托盘。
- 新增透明无边框桌宠窗口支持。
- 新增透明空白区域点击穿透模型。
- 新增关闭隐藏到托盘能力。

### 修复

- 修复设置保存、托盘左键、右键菜单、窗口模式和 native read 访问风险等问题。

## v0.2 Beta - 稳定候选与橘猫接入

- 完成紧凑桌宠窗口、橘猫素材接入、基础交互、设置通用项、开机自启、恢复默认、v0.2 自动验证和导出链路。
- 真系统托盘、透明无边框窗口和点击穿透因 Godot 4.7 Windows 原生限制转入 v0.3。

## v0.1 Beta - 调试窗口版产品雏形

- 完成薪资计算、Pet / Panel 雏形、设置、首次启动向导、基础交互和 Windows 打包链路。
- 实际交付为普通调试窗口版，不是完整透明桌宠版。
