# 更新日志

## v0.7 Beta - 开源公开与可信分发基础版（2026-07-13）

### 状态

- 最终 Acceptance 通过，可发布 Windows x86_64 便携 Zip。
- 未签名测试安装器不作为 GitHub Release 附件。
- `main` 已启用 PR、必要 CI、禁止 force push/删除的保护规则；Private Vulnerability Reporting 已启用。

### 新增与变更

- 建立 MIT 代码许可、受限素材许可、第三方声明和双语 README。
- 固定 Godot、godot-cpp、Python、SCons、MSYS2/GCC 与 Inno Setup 工具链身份。
- 增加 Windows 文档/合规、native/Godot CI 和维护者手动 Release dry run。
- 完成 Main/native 窗口、托盘、任务栏和点击穿透状态合同治理。
- 增加用户确认的更新检查、下载、SHA256、发布者校验、取消和回退路径。
- 完成安装、覆盖/修复、卸载保留/删除数据和受控安装失败验收。

### 已知边界

- 多显示器、干净 Windows 用户/VM、Authenticode/SmartScreen、真实登录后的开机自启暂不验证，不得写为通过。
- v0.7 Release 只提供便携 Zip；测试安装器保持本地验收用途。

## v0.6 Beta - 发布后体验稳定与验证增强版（2026-07-11）

### 状态

- V06-M0 至 V06-M6、V06-ACC-001 已完成。
- 候选包：`releases/v0.6/LetsMakeMoney-v0.6-beta-windows-x86_64.zip`。
- Zip SHA256：`CECD3C3ABACFCB5EF594584E2AEB0E25C1824BAE97AB84B224073E7444E72615`。
- 最终 Acceptance 通过，无发布阻塞项，可进入发布执行。
- 已通过 `v0.6-beta` tag 发布为 GitHub Pre-release。

### 新增

- 新增统一应用版本事实源、日志分级与 2 MB 单备份轮换。
- 新增 Settings 轻量诊断入口和脱敏摘要。
- 新增 Config 安全替换、损坏配置备份和一次性恢复提示。
- 新增 v0.6 托盘、配置、主验证、打包和包体验证脚本。

### 变更

- 活跃验证入口统一检查进程退出码和 Godot 阻塞错误。
- Settings/Wizard 保存与取消链路增加 Config、宠物、自启动和窗口状态补偿。
- 普通模式停止生成交互截图，Debug/隔离验证仍可启用。
- 右键菜单与原生托盘菜单按既定职责完成复核，不新增测试后门。
- 纯桌宠从托盘恢复后显式同步 Windows Shell 任务栏标签，避免任务栏入口残留。

### 修复

- 修复诊断摘要已经写入剪贴板但 UI 误报失败的问题。
- 修复纯桌宠从托盘恢复后任务栏入口可能残留的问题。
- 修复开机自启路径格式和旧值识别逻辑；真实登录结果仍暂不验证。

### 验证

- v0.6、v0.5、v0.4、M4、M5、文档和包验证通过。
- normal/pure 托盘策略各 10 轮 PostMessage 显隐通过。
- Computer Use 覆盖 Panel、右键二级菜单、Settings 五页和 Wizard 四步。
- Windows 通知区托盘隐藏/恢复、纯桌宠任务栏策略和 Settings 保存失败反馈完成真实补证。
- 诊断摘要复制、脱敏、配置损坏恢复、日志轮换和点击穿透保护通过。

### 已知限制

- 真实 Windows 登录后的开机自启暂不验证，不得写为通过。
- 自动检查只证明注册表命令格式、启停事务和失败补偿，不证明注销、重启或重新登录后一定启动。
- 该能力默认关闭，不影响手动启动和桌宠核心路径，因此不阻塞本次 Beta；发布后继续观察。
- 已验收 Zip 内 README 与发布说明保留候选包生成时的“待验收”快照，外部发布说明和当前版本文档为最终口径。

### 回滚

- 保留 v0.5 Beta 上一稳定包。
- 升级前备份 `%APPDATA%\LetsMakeMoney\config.json`。
- 如需回滚，退出 v0.6、恢复配置备份，再启动 v0.5 Beta。

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
