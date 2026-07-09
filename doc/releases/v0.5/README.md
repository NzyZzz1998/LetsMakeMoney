# LetsMakeMoney v0.5 Beta 文档索引

**最后更新**: 2026-07-09
**当前阶段**: `/acceptance` 未通过 / 发布阻塞
**当前事实源**: [status.md](status.md)、[verification.md](verification.md)、[release-checklist.md](release-checklist.md)

## v0.5 当前状态

v0.5 Beta 定位为“偏好设置与桌宠边缘体验收敛版”。本版本已经完成实现、打包和大部分自动/人工验证，但最终发布签核仍未通过。

当前唯一发布阻塞项是：真实 Windows 托盘左键隐藏/恢复路径在纯桌宠模式下仍缺少通过证据。预期是无论是否纯桌宠模式，左键托盘图标都可以隐藏/显示窗口；纯桌宠模式恢复后不应出现任务栏入口。

## 推荐阅读顺序

1. [status.md](status.md)：先判断 v0.5 当前状态和阻塞项。
2. [verification.md](verification.md)：查看验收结果、待补证路径和发布阻塞说明。
3. [release-checklist.md](release-checklist.md)：发布前检查清单。
4. [progress_v0.5.md](progress_v0.5.md)：查看实现任务完成情况。
5. [dev_plan_v0.5.md](dev_plan_v0.5.md)：查看实施顺序、影响文件、测试命令与风险。
6. [prd.md](prd.md)：查看 v0.5 需求范围和不做项。
7. [idea-pool.md](idea-pool.md)：只在需要回溯 v0.5 立项来源时阅读。

## v0.5 需求入口

- [idea-pool.md](idea-pool.md)：v0.5 候选需求池，说明为什么 v0.5 选择“偏好设置与桌宠边缘体验收敛”。
- [prd.md](prd.md)：v0.5 完整 PRD。
- [../../prototypes/index.html](../../prototypes/index.html)：当前交互原型入口。
- [../../prototypes/prototype-spec.md](../../prototypes/prototype-spec.md)：原型说明。

## v0.5 实施入口

- [dev_plan_v0.5.md](dev_plan_v0.5.md)：开发承接计划。
- [progress_v0.5.md](progress_v0.5.md)：PM 状态看板，只记录任务状态，不写 bugfix 流水账。
- [../../logs/v0.5-bugfix-log.md](../../logs/v0.5-bugfix-log.md)：v0.5 bugfix 与技术排查记录。

## v0.5 验证入口

- [verification.md](verification.md)：人工验收清单和验收结果。
- [release-checklist.md](release-checklist.md)：发布前自动验证、手动验证和打包检查。

## 发布产物说明

- 文档目录：`doc/releases/v0.5/`
- 产物目录：`releases/v0.5/`
- 产物 zip：`releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip`
- 发布说明：`releases/v0.5-beta-notes.md`
- 打包脚本：`scripts/package_v05.ps1`
- 包验证脚本：`scripts/verify_v05_package.ps1`

## 当前不应扩展的内容

v0.5 不新增主题系统、安装器、自动更新、多平台支持、更多宠物，也不把 ComfyUI 正式产品化。若托盘阻塞项未通过，只记录为发布阻塞，不扩大为新需求。
