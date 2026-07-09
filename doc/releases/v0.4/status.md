# LetsMakeMoney v0.4 Beta 当前状态

**最后更新**: 2026-07-09  
**分支**: `main`
**阶段**: v0.4 Beta 已推送至 `main`，统一标签为 `v0.4-beta`；当前处于发布后补验收 / 收尾校准阶段
**验收入口**: [verification.md](verification.md)

## 当前状态

v0.4 Beta 已进入测试收尾阶段。主要功能、UI 方向、橘猫 v2、托盘 / 透明窗口 / 纯桌宠模式、Settings / Wizard 暖色偏好设置、Panel 和右键菜单暖桌面风格均已实现或完成阶段性修复。

当前不能视为完全关闭，原因是仍存在部分通过 / 待人工最终确认项。`V04-MAN-052` 已按用户最新判断转入后续优化清单，不再作为 v0.4 收尾阶段继续反复修补的阻塞项。

## 已完成

- 真系统托盘、托盘菜单、托盘左键显示 / 隐藏。
- 透明无边框桌宠窗口、点击穿透、纯桌宠模式、关闭隐藏到托盘。
- 橘猫 v2 默认素材接入，并保留旧素材作为回退。
- Panel 暖色小票 / 便签风格。
- 右键菜单暖色纸面风格。
- Settings 暖色紧凑偏好设置面板。
- Wizard 暖色紧凑向导风格。
- v0.4 发布包测试产物、manifest、checksum、包内 README / release notes。
- v0.4 自动验证、M4/M5 回归、打包和包验证脚本已建立。

## 部分通过 / 待人工确认

- `V04-MAN-061`: 发布包正常模式启动日志显示 native / tray / passthrough / taskbar 能力可用；既有日志显示托盘隐藏 / 显示后会重套纯桌宠策略。Computer Use 无法直接点击 Windows 托盘，建议保留一次人工最终确认。
- `V04-MAN-072`: Debug 窗口下连续单击、双击、拖拽、右键菜单均有日志和截图证据；长按因 Computer Use 无精确按住 0.7 秒能力，仍需人工最终确认。

## 已通过收尾检查

- `V04-MAN-073`: `debug.log` 已检查，未发现 parser/runtime/Invalid call/null instance/native 访问异常。
- 发布包烟测：`scripts/verify_v04_package.ps1` 已通过。
- v0.4 自动验证：`scripts/verify_v04.ps1` 已通过。

## 后续优化清单

- `V04-OPT-001` / `V04-MAN-052`: Wizard 薪资页控件视觉与 Settings 一致性。现象是多轮修复后用户体感仍无明显变化；当前判断不是单点 bug，而是 Wizard 与 Settings 控件主题系统没有真正统一。v0.4 暂停继续修补，后续应通过共享控件、共享 Theme 和截图验收专项处理。

## 发布前阻塞项

- `V04-MAN-061` 仍建议人工最终确认。
- `V04-MAN-072` 中的长按反馈仍建议人工最终确认。
- 最新 Wizard / UI 修复后的 release notes 可能仍需同步。
- 若代码、资源或包内文档继续变更，需要重新运行打包和包验证。

## 下一步验收入口

1. 打开 [verification.md](verification.md)。
2. 人工最终确认 `V04-MAN-061`。
3. 人工最终确认 `V04-MAN-072` 中的长按反馈。
4. `V04-MAN-052` 已转为 `V04-OPT-001` 后续优化，不再作为当前修复项。
5. 根据结果更新 [verification.md](verification.md) 和本文件；不要把验收过程流水写入 progress。
6. 若继续代码、资源或发布包内容变更，重新运行打包和包验证。

## 对应文件

- 当前事实源: [doc/current.md](../../current.md)
- v0.4 文档索引: [doc/releases/v0.4/README.md](README.md)
- 手动验证: [verification.md](verification.md)
- 总体进度: [progress.md](progress.md)
- v0.4 PRD: [prd.md](prd.md)
- v0.4 实施计划: [implementation-plan.md](implementation-plan.md)
- 发布前检查: [release-checklist.md](release-checklist.md)
- 当前原型: [doc/prototypes/index.html](../../prototypes/index.html)
- UI polish spec: [doc/v0.4-ui-polish-spec.md](../../v0.4-ui-polish-spec.md)
- 发布产物: `releases/v0.4/`
