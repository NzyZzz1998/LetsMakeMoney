# LetsMakeMoney v0.5 Beta 当前状态

**最后更新**: 2026-07-09
**分支**: `main`
**阶段**: `/acceptance` 未通过 / 发布阻塞
**验收入口**: [verification.md](verification.md)

## 当前状态

v0.5 Beta 是“偏好设置与桌宠边缘体验收敛版”。本版本不扩展新的产品方向，重点把 Settings、Wizard、托盘恢复、点击穿透保护和验证入口收束到可维护、可验证、可回归的状态。

当前实现已经完成 `V05-M0` 到 `V05-M6` 的代码与文档准备项。`/acceptance` 已完成收口判断，结论为未通过 / 发布阻塞。阻塞项仅限真实 Windows 托盘左键在纯桌宠模式下恢复后仍需人工确认任务栏入口保持隐藏。

## 已完成

- v0.5 idea pool、PRD、高保真原型、实施计划和 progress 看板已完成并确认通过。
- `doc/releases/v0.5/status.md`、`verification.md`、`release-checklist.md` 已建立。
- `doc/logs/` 与 `scripts/check_docs_status.ps1` 已建立，用于区分 progress、dev-log、bugfix-log 和 spike-log。
- Settings / Wizard 已接入共享 Warm Control helper。
- v0.5 稳定日志入口已补充：`tray_toggle_requested`、`window_policy_reapplied`、`pure_pet_mode_apply`、`pure_pet_mode_fallback`、`passthrough_suspended`、`passthrough_resumed`。
- v0.5 专属验证脚本已建立：`scripts/verify_v05.ps1` / `scripts/verify_v05.gd`。
- v0.5 专属发布包脚本已建立：`scripts/package_v05.ps1` / `scripts/verify_v05_package.ps1`。
- v0.5 Beta 发布说明已建立：`releases/v0.5-beta-notes.md`。

## 已验证

- `verify_v05.ps1` 通过。
- `verify_v04.ps1` 通过。
- `verify_m4.ps1` 通过。
- `verify_m5.ps1` 通过，并重新导出 `build/LetsMakeMoney.exe`。
- `check_docs_status.ps1` 通过。
- `package_v05.ps1` 可生成 v0.5 专属 zip。
- `verify_v05_package.ps1` 可完成包结构、manifest、checksum 和短启动冒烟检查。
- Computer Use 已截图确认 Settings 工资页、显示页、通用页、OptionButton popup、Wizard 欢迎页、薪资页、宠物页和确认页。

## 发布前阻塞项

- 真实 Windows 托盘与纯桌宠恢复路径尚需 `/acceptance` 通过。
- 最新用户证据显示：纯桌宠模式下左键托盘隐藏后再恢复，桌宠可恢复，但任务栏入口依旧存在。
- 预期：非纯桌宠模式恢复后允许任务栏入口存在；纯桌宠模式恢复后只显示桌宠，不显示任务栏入口。
- v0.5 tag 与 GitHub release 尚未处理。

## 不进入 v0.5

- 主题系统。
- 安装器。
- 自动更新。
- 多平台支持。
- 更多宠物。
- ComfyUI 正式产品化。

## 下一步验收入口

1. 仅围绕托盘左键隐藏/恢复路径做最终复测。
2. 使用 [verification.md](verification.md) 填写人工结果。
3. 复核 `%APPDATA%\LetsMakeMoney\debug.log` 中 Settings / Wizard / tray / passthrough / pure pet 关键事件。
4. 验收通过后再决定是否打 tag、推 GitHub release 或发布 v0.5 Beta。

## 对应文件

- v0.5 idea pool: [idea-pool.md](idea-pool.md)
- v0.5 PRD: [prd.md](prd.md)
- v0.5 实施计划: [dev_plan_v0.5.md](dev_plan_v0.5.md)
- v0.5 progress: [progress_v0.5.md](progress_v0.5.md)
- v0.5 验证入口: [verification.md](verification.md)
- v0.5 发布前清单: [release-checklist.md](release-checklist.md)
- 当前原型: [../../prototypes/index.html](../../prototypes/index.html)
- 原型说明: [../../prototypes/prototype-spec.md](../../prototypes/prototype-spec.md)

## Final acceptance sign-off - 2026-07-09

**Acceptance result**: 未通过 / 发布阻塞。

The implementation and package are ready for final verification, but v0.5 cannot be marked `通过 / 可发布` yet. The remaining blocker is the real Windows tray left-click restore path in pure-pet mode.

Evidence status:

- Automated verification passed: `verify_v05.ps1`, `verify_v04.ps1`, `verify_m4.ps1`, `verify_m5.ps1`, `check_docs_status.ps1`, `package_v05.ps1`, `verify_v05_package.ps1`.
- Settings / Wizard targeted acceptance passed based on Computer Use screenshots and debug logs.
- Latest user-provided tray evidence before sign-off showed pure-pet restore exposing a taskbar entry.
- A regenerated v0.5 package exists, but no passing manual retest evidence has been recorded yet.

Release decision:

- Do not publish or tag v0.5 Beta yet.
- Do not open new feature scope.
- Only retest the release blocker: pure-pet tray left-click hide/show should restore the desktop pet without a taskbar entry.
