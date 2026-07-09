# LetsMakeMoney v0.5 Beta 进度看板

**最后更新**：2026-07-09  
**当前阶段**：发布收口  
**当前结论**：通过 / 可发布  
**当前分支**：`main`

## 1. 使用规则

本文件只记录 v0.5 的任务状态、最小可执行 checklist 和发布结论摘要。  
开发日志、bugfix 流水、技术排查、截图评价和 Spike 记录不写入本文件，应放入 `doc/logs/` 或对应验证文档。

## 2. 范围确认

### 已确认输入

- [x] `doc/releases/v0.5/idea-pool.md`
- [x] `doc/releases/v0.5/prd.md`
- [x] `doc/releases/v0.5/dev_plan_v0.5.md`
- [x] `doc/prototypes/index.html`
- [x] `doc/prototypes/prototype-spec.md`

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

## 3. 总体进度

| 模块 | 名称 | 状态 | 说明 |
|---|---|---|---|
| V05-PRE | PRD 与原型确认 | 完成 | 用户已确认 v0.5 完整 PRD 和高保真原型 |
| V05-M0 | 开发基线与文档壳 | 完成 | v0.5 状态、验证、日志治理入口已建立 |
| V05-M1 | 共享 Warm Control 基础 | 完成 | 已建立共享 token 和控件 helper |
| V05-M2 | Settings 迁移到共享控件 | 完成 | 五页签已接入共享控件系统 |
| V05-M3 | Wizard 迁移到共享控件 | 完成 | Wizard 四步流程已接入共享控件系统 |
| V05-M4 | 托盘 / 点击穿透 / 纯桌宠稳定化 | 完成 | 托盘恢复、任务栏策略和点击穿透保护已补证通过 |
| V05-M5 | 验证脚本与人工验收文档 | 完成 | v0.5 验证入口和回归命令可用 |
| V05-M6 | 视觉基线与发布文档收口 | 完成 | 发布说明、检查清单、状态文档已同步 |
| V05-ACC | 发布前补证验收 | 通过 | 实际运行发布包 exe 并完成关键路径补证 |

## 4. 模块 checklist

### V05-M0：开发基线与文档壳

- [x] 创建 `doc/releases/v0.5/status.md`。
- [x] 创建 `doc/releases/v0.5/verification.md`。
- [x] 创建 `doc/releases/v0.5/release-checklist.md`。
- [x] 创建 `doc/logs/README.md`，明确 progress 与 dev-log / bugfix-log / spike-log 边界。
- [x] 创建 `scripts/check_docs_status.ps1`。
- [x] 确认 `doc/current.md` 中 v0.5 文档入口可读。

### V05-M1：共享 Warm Control 基础

- [x] 盘点 `settings_dialog.gd` 中现有 token 和 style helper。
- [x] 盘点 `wizard_dialog.gd` 中现有 token 和 style helper。
- [x] 建立共享 helper：`src/ui/warm_control_theme.gd`。
- [x] 抽取颜色 token。
- [x] 抽取尺寸 token。
- [x] 实现 button、LineEdit、SpinBox、OptionButton、popup、switch、slider、scrollbar、row、section helper。
- [x] 确认 helper 不包含配置保存、薪资计算或窗口策略业务逻辑。

### V05-M2：Settings 迁移到共享控件

- [x] Settings shell 接入共享背景、圆角、边框。
- [x] Settings tabs 接入共享 segmented tabs。
- [x] Settings action bar 接入共享 button。
- [x] 工资页控件接入共享 SpinBox / OptionButton / time input。
- [x] 桌宠页宠物选择控件接入共享样式。
- [x] 显示页透明度、缩放、窗口模式、纯桌宠模式控件接入共享样式。
- [x] 面板页开关接入共享样式。
- [x] 通用页开机自启、隐藏到托盘、维护按钮接入共享样式。
- [x] 保存成功、无变化、保存失败反馈可区分。

### V05-M3：Wizard 迁移到共享控件

- [x] Wizard shell 接入共享背景、圆角、边框。
- [x] Wizard step indicator 接入共享样式。
- [x] 上一步、下一步、完成、取消按钮接入共享 button。
- [x] 欢迎页收敛为紧凑小工具配置面板。
- [x] 薪资页月薪、休息模式、时间输入复用 Settings 控件。
- [x] 宠物页初始化时至少有当前可选宠物。
- [x] 确认页展示配置摘要和完成按钮。
- [x] 下一步、上一步、完成、取消、关闭路径可用。

### V05-M4：托盘 / 点击穿透 / 纯桌宠稳定化

- [x] 梳理托盘左键隐藏 / 显示流程。
- [x] 梳理托盘右键菜单流程。
- [x] 梳理 pure pet mode 应用流程。
- [x] 定义恢复窗口后的策略重应用顺序。
- [x] 托盘左键显示后重新应用 taskbar visibility。
- [x] 托盘左键显示后重新应用 pure pet mode。
- [x] 托盘左键显示后重新应用 mouse passthrough rect。
- [x] Settings 打开时 suspend passthrough。
- [x] Wizard 打开时 suspend passthrough。
- [x] 右键菜单打开期间保护交互区域。
- [x] native 不可用时降级为可找回普通窗口。
- [x] 补齐 tray / pure pet / passthrough 关键日志事件。

### V05-M5：验证脚本与人工验收文档

- [x] 创建 `scripts/verify_v05.gd`。
- [x] 创建 `scripts/verify_v05.ps1`。
- [x] 验证共享 helper 和关键方法存在。
- [x] 验证 Settings 五页签关键节点存在。
- [x] 验证 Wizard 四步关键节点存在。
- [x] 验证关键配置字段没有新增语义变化。
- [x] 验证日志事件入口存在。
- [x] 保留 v0.4 / M4 / M5 回归命令。

### V05-M6：视觉基线与发布文档收口

- [x] 截取 Settings 工资页并对照原型。
- [x] 截取 Settings 显示页并对照原型。
- [x] 截取 Wizard 薪资页并对照原型。
- [x] 截取 Wizard 确认页并对照原型。
- [x] 更新 `doc/releases/v0.5/status.md`。
- [x] 更新 `doc/releases/v0.5/release-checklist.md`。
- [x] 更新 v0.5 release notes。
- [x] 生成 v0.5 package。
- [x] 运行 v0.5 package verification。

## 5. 发布前补证验收结果

- [x] 实际运行 `releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64/LetsMakeMoney.exe`。
- [x] 读取 `%APPDATA%\LetsMakeMoney\debug.log`。
- [x] 托盘左键隐藏 / 恢复链路补证通过。
- [x] `pure_pet_mode=true` 恢复后任务栏入口策略通过。
- [x] `pure_pet_mode=false` 恢复后任务栏入口策略通过。
- [x] Settings 保存成功通过。
- [x] Settings 无变化保存通过。
- [x] Settings 保存失败通过。
- [x] Wizard 下一步 / 上一步日志通过。
- [x] Wizard 完成日志通过。
- [x] Wizard 取消 / 关闭日志通过。
- [x] Settings / Wizard 打开期间点击穿透保护通过。
- [x] v0.5 zip 包验证通过。

## 6. 已知说明

- Computer Use 无法稳定直接点击 Windows 通知区托盘图标。本轮托盘左键验收使用真实发布包 exe、native 托盘消息同路径、Win32 窗口样式和桌面截图补证。
- `passthrough_suspended` / `passthrough_resumed` 当前是 debug 级日志，默认 `debug_mode=false` 时不会每次写入。建议 v0.6 优化日志口径。
- `verify_v05.ps1` 返回通过，但 Godot headless 输出仍可能出现 parser 文本。建议 v0.6 优化脚本输出质量。

## 7. 下一步

v0.5 Beta 已通过发布前补证验收，可以进入提交、推送和 `v0.5-beta` tag 收口。后续若继续迭代，应进入 v0.6 `/idea`，不要继续扩大 v0.5 范围。
