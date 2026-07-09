# LetsMakeMoney v0.5 Beta 文档索引

**最后更新**：2026-07-09  
**当前阶段**：发布收口  
**当前结论**：通过 / 可发布  
**当前事实源**：[status.md](status.md)、[verification.md](verification.md)、[release-checklist.md](release-checklist.md)

## 1. v0.5 当前状态

v0.5 Beta 定位为“偏好设置与桌宠边缘体验收敛版”。本版本已完成实现、打包、自动验证、定向人工验证和发布前补证验收，可以进入提交、推送和 `v0.5-beta` tag 收口。

本版本不新增主题系统、安装器、自动更新、多平台、更多宠物，也不将 ComfyUI 正式产品化。

## 2. 推荐阅读顺序

1. [status.md](status.md)：判断 v0.5 当前状态和发布结论。
2. [verification.md](verification.md)：查看发布前补证验收结果和关键证据。
3. [release-checklist.md](release-checklist.md)：查看发布检查清单。
4. [progress_v0.5.md](progress_v0.5.md)：查看实现任务完成情况。
5. [dev_plan_v0.5.md](dev_plan_v0.5.md)：查看实施顺序、影响文件、测试命令与风险。
6. [prd.md](prd.md)：查看 v0.5 需求范围和不做项。
7. [idea-pool.md](idea-pool.md)：仅在需要回溯 v0.5 立项来源时阅读。

## 3. v0.5 需求入口

- [idea-pool.md](idea-pool.md)：v0.5 候选需求池。
- [prd.md](prd.md)：v0.5 完整 PRD。
- [../../prototypes/index.html](../../prototypes/index.html)：当前交互原型入口。
- [../../prototypes/prototype-spec.md](../../prototypes/prototype-spec.md)：原型说明。

## 4. v0.5 实施入口

- [dev_plan_v0.5.md](dev_plan_v0.5.md)：开发承接计划。
- [progress_v0.5.md](progress_v0.5.md)：PM 状态看板，只记录任务状态，不写 bugfix 流水账。
- [../../logs/v0.5-bugfix-log.md](../../logs/v0.5-bugfix-log.md)：v0.5 bugfix 与技术排查记录。

## 5. v0.5 验证入口

- [verification.md](verification.md)：发布前补证验收结果。
- [release-checklist.md](release-checklist.md)：发布检查清单。
- `scripts/verify_v05.ps1`：v0.5 自动验证。
- `scripts/verify_v05_package.ps1`：v0.5 发布包验证。

## 6. 发布产物说明

- 文档目录：`doc/releases/v0.5/`
- 产物目录：`releases/v0.5/`
- 产物 zip：`releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip`
- 发布说明：`releases/v0.5-beta-notes.md`
- 打包脚本：`scripts/package_v05.ps1`
- 包验证脚本：`scripts/verify_v05_package.ps1`

## 7. 当前不应扩展的内容

v0.5 不新增主题系统、安装器、自动更新、多平台支持、更多宠物，也不把 ComfyUI 正式产品化。后续新增方向应进入 v0.6 `/idea`，不要继续扩大 v0.5 范围。
