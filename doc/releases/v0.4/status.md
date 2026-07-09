# LetsMakeMoney v0.4 Beta 当前状态

**最后更新**: 2026-07-09  
**分支**: `test`  
**阶段**: Beta 测试态，尚未合并 `main`，尚未打 v0.4 tag  
**验收入口**: [verification.md](verification.md)

## 当前状态

v0.4 Beta 已进入测试收尾阶段。主要功能、UI 方向、橘猫 v2、托盘 / 透明窗口 / 纯桌宠模式、Settings / Wizard 暖色偏好设置、Panel 和右键菜单暖桌面风格均已实现或完成阶段性修复。

当前不能视为正式完成，原因是仍存在待人工复测项和未测试项。`V04-MAN-052` 已按用户最新判断转入后续优化清单，不再作为 v0.4 收尾阶段继续反复修补的阻塞项。

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

## 待复测

以下项已修复，但仍需要人工按 [verification.md](verification.md) 复测后才能改为通过：

- `V04-MAN-061`: 开启纯桌宠模式后，托盘左键隐藏 / 显示不会重新暴露任务栏入口。

## 未测试

- `V04-MAN-072`: 连续单击、双击、右键各 5 次，确认输入事件和视觉反馈稳定。
- `V04-MAN-073`: 检查 `%APPDATA%\LetsMakeMoney\debug.log`，确认没有 parser/runtime/native 异常和重复失效日志。

## 后续优化清单

- `V04-OPT-001` / `V04-MAN-052`: Wizard 薪资页控件视觉与 Settings 一致性。现象是多轮修复后用户体感仍无明显变化；当前判断不是单点 bug，而是 Wizard 与 Settings 控件主题系统没有真正统一。v0.4 暂停继续修补，后续应通过共享控件、共享 Theme 和截图验收专项处理。

## 发布前阻塞项

- `V04-MAN-061` 待复测未通过。
- 未测试项未补齐结果。
- 最新 Wizard / UI 修复后的 release notes 可能仍需同步。
- 若代码、资源或包内文档继续变更，需要重新运行打包和包验证。

## 下一步验收入口

1. 打开 [verification.md](verification.md)。
2. 先复测 `V04-MAN-061`。
3. 再补测 `V04-MAN-072`、`V04-MAN-073`。
4. `V04-MAN-052` 已转为 `V04-OPT-001` 后续优化，不再作为当前修复项。
5. 根据结果更新 [progress.md](progress.md)、[verification.md](verification.md) 和本文件。
6. 全部通过后再决定是否合并 `main`、推 tag 或继续 UI polish。

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
