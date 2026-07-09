# LetsMakeMoney 当前状态入口

**最后更新**：2026-07-09  
**项目名**：LetsMakeMoney 赚钱模拟器  
**当前版本**：v0.5 Beta  
**当前分支**：`main`  
**当前阶段**：发布收口  
**当前结论**：通过 / 可发布

本文件是后续人工或 agent 接手时的第一入口。先读这里判断当前事实源，再进入当前版本专属文档；不要直接从超大 PRD、实施计划或历史 progress 从头读起。

## 1. 当前版本目标

v0.5 Beta 是“偏好设置与桌宠边缘体验收敛版”。本版本不扩展新产品方向，重点收敛：

- Settings / Wizard 共享控件系统。
- Settings 保存成功、无变化、保存失败反馈。
- Wizard 下一步、上一步、完成、取消语义日志。
- 托盘左键隐藏 / 恢复。
- 纯桌宠恢复后的任务栏入口策略。
- 非纯桌宠恢复后的任务栏入口策略。
- Settings / Wizard 打开期间点击穿透保护。
- v0.5 文档、验证脚本、打包脚本和发布包收口。

v0.5 不做主题系统、安装器、自动更新、多平台支持、更多宠物或 ComfyUI 正式产品化。

## 2. 当前必须完成 / 验证的事项

已完成发布前补证验收，结论为“通过 / 可发布”。

关键通过项：

- 实际运行 `releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64/LetsMakeMoney.exe`。
- `verify_v05_package.ps1` 通过。
- Settings 保存成功 / 无变化 / 保存失败均有 UI 反馈和 `debug.log` 事件。
- Wizard 下一步 / 上一步 / 取消 / 完成均有 `debug.log` 事件。
- `pure_pet_mode=true` 恢复后主窗口为 `AppWindow=false / ToolWindow=true`。
- `pure_pet_mode=false` 恢复后主窗口为 `AppWindow=true / ToolWindow=false`。

## 3. 当前发布产物状态

- zip：`releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip`
- 展开目录：`releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64/`
- 发布说明：`releases/v0.5-beta-notes.md`
- changelog：`releases/CHANGELOG.md`
- 打包脚本：`scripts/package_v05.ps1`
- 包验证脚本：`scripts/verify_v05_package.ps1`

注意区分：

- `doc/releases/v0.5/`：v0.5 专属文档目录，不包含真实 exe。
- `releases/v0.5/`：v0.5 真实发布产物目录，包含 zip、exe、manifest 和 checksum。

## 4. 推荐阅读顺序

1. [doc/current.md](current.md)
2. [doc/releases/v0.5/status.md](releases/v0.5/status.md)
3. [doc/releases/v0.5/verification.md](releases/v0.5/verification.md)
4. [doc/releases/v0.5/release-checklist.md](releases/v0.5/release-checklist.md)
5. [doc/releases/v0.5/progress_v0.5.md](releases/v0.5/progress_v0.5.md)
6. [doc/releases/v0.5/dev_plan_v0.5.md](releases/v0.5/dev_plan_v0.5.md)
7. [doc/releases/v0.5/prd.md](releases/v0.5/prd.md)
8. [doc/prototypes/prototype-spec.md](prototypes/prototype-spec.md)
9. [doc/prototypes/index.html](prototypes/index.html)

## 5. 当前可信文档清单

| 文件 | 用途 | 可信口径 |
|---|---|---|
| [doc/current.md](current.md) | 当前状态入口 | 当前事实源 |
| [doc/releases/v0.5/status.md](releases/v0.5/status.md) | v0.5 状态摘要 | 当前事实源 |
| [doc/releases/v0.5/verification.md](releases/v0.5/verification.md) | v0.5 发布前补证验收 | 当前验收事实源 |
| [doc/releases/v0.5/release-checklist.md](releases/v0.5/release-checklist.md) | v0.5 发布检查 | 当前发布门禁 |
| [doc/releases/v0.5/progress_v0.5.md](releases/v0.5/progress_v0.5.md) | v0.5 任务看板 | 当前任务状态 |
| [doc/releases/v0.5/dev_plan_v0.5.md](releases/v0.5/dev_plan_v0.5.md) | v0.5 实施计划 | 当前实施入口 |
| [doc/releases/v0.5/prd.md](releases/v0.5/prd.md) | v0.5 PRD | 当前需求入口 |
| [doc/prototypes/prototype-spec.md](prototypes/prototype-spec.md) | 当前原型说明 | 当前原型事实源 |
| [doc/prototypes/index.html](prototypes/index.html) | 当前可交互原型 | 当前原型事实源 |
| `releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64/manifest.json` | 发布包清单 | 当前包内容事实源 |

## 6. 历史参考文档

以下文档只作为历史参考，不能覆盖 v0.5 当前事实源：

- `doc/releases/v0.4/`
- `doc/verification/v0.1.md`
- `doc/verification/v0.2.md`
- `doc/verification/v0.3.md`
- `doc/verification/v0.4.md`
- `doc/LetsMakeMoneyPRD.md`
- `doc/implementation-plan.md`
- `doc/progress.md`
- `doc/v0.2-asset-spike.md`
- `doc/v0.2-asset-prompt-pack.md`
- `doc/v0.4-animation-spec.md`
- `doc/v0.4-animation-assets-log.md`
- `doc/v0.4-comfyui-spike.md`

## 7. 已知说明

- Computer Use 无法稳定直接点击 Windows 通知区托盘图标。v0.5 托盘左键验收使用真实发布包 exe、native 托盘消息同路径、Win32 窗口样式和桌面截图补证。
- `passthrough_suspended` / `passthrough_resumed` 当前是 debug 级日志，默认 `debug_mode=false` 时不会每次写入。建议 v0.6 优化日志口径。
- `verify_v05.ps1` 返回通过，但 Godot headless 输出仍可能出现 parser 文本。建议 v0.6 优化脚本输出质量。

## 8. 下一步

1. 提交并推送当前 v0.5 收口状态。
2. 打 `v0.5-beta` tag。
3. 后续如继续迭代，进入 v0.6 `/idea`，不要继续扩大 v0.5 范围。
