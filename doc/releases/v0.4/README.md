# LetsMakeMoney v0.4 Beta 文档索引

本目录是 **v0.4 Beta 专属文档目录**，不是发布包目录。

- 文档目录: `doc/releases/v0.4/`
- 真实发布产物: `releases/v0.4/`

当前 v0.4 已推送至 `main`，统一标签为 `v0.4-beta`，处于 Beta 发布后补验收 / 收尾校准阶段。

## 优先阅读

1. [doc/current.md](../../current.md) - 当前项目事实源入口。
2. [status.md](status.md) - v0.4 当前短状态。
3. [verification.md](verification.md) - v0.4 专属验证文档副本。
4. [progress.md](progress.md) - v0.4 专属进度副本。
5. [prd.md](prd.md) - v0.4 专属 PRD 副本。
6. [implementation-plan.md](implementation-plan.md) - v0.4 专属实施计划副本。
7. [release-checklist.md](release-checklist.md) - v0.4 发布前检查清单。
8. [doc/prototypes/prototype-spec.md](../../prototypes/prototype-spec.md) - 当前交互原型说明。
9. [doc/prototypes/index.html](../../prototypes/index.html) - 当前可交互原型。
10. [doc/v0.4-ui-polish-spec.md](../../v0.4-ui-polish-spec.md) - 当前 UI polish 口径。

不要从 `doc/implementation-plan.md`、`doc/progress.md`、`doc/LetsMakeMoneyPRD.md` 的开头盲读。它们现在保留为跨版本原始大文档；v0.4 快速接手优先读本目录中的拆分副本。

## 本目录文件

| 文件 | 来源 | 当前用途 |
|---|---|---|
| [README.md](README.md) | 新增 | v0.4 文档导航 |
| [status.md](status.md) | 新增 | v0.4 当前短状态 |
| [prd.md](prd.md) | 复制自 `doc/LetsMakeMoneyPRD.md` v0.4 章节 | v0.4 需求入口 |
| [implementation-plan.md](implementation-plan.md) | 复制自 `doc/implementation-plan.md` v0.4 章节 | v0.4 实施入口 |
| [progress.md](progress.md) | 复制自 `doc/progress.md` v0.4 章节 | v0.4 进度入口 |
| [verification.md](verification.md) | 复制自 `doc/verification/v0.4.md` | v0.4 验证入口 |
| [release-checklist.md](release-checklist.md) | 新增 | v0.4 发布前检查入口 |

拆分策略是“复制章节，不删除原文”。如果拆分副本与原大文档冲突，先看 [doc/current.md](../../current.md) 和 [status.md](status.md)，再人工确认最新修改发生在哪一份。

## v0.4 当前状态

详见 [status.md](status.md)。

当前口径摘要：

- v0.4 是大型体验优化版本。
- 默认体验方向是“温暖桌面小挂件 / 橘猫金币小票便签风”。
- 当前发布包已有可分发 Beta 产物，但仍需关闭少量人工最终确认项。
- `main` 和 `v0.4-beta` 标签已同步；后续仅在代码、资源或包内文档变更时重新打包。

## v0.4 需求入口

- 当前优先读: [prd.md](prd.md)
- 原始大文档: [doc/LetsMakeMoneyPRD.md](../../LetsMakeMoneyPRD.md)
- 原始章节: `## 6. v0.4 Beta PRD`

阅读建议：

- 日常接手优先读 [prd.md](prd.md)。
- 原始大文档只在需要追溯上下文时读取。
- v0.1-v0.3 章节只用于理解历史演进，不作为当前验收口径。

## v0.4 实施入口

- 当前优先读: [implementation-plan.md](implementation-plan.md)
- 原始大文档: [doc/implementation-plan.md](../../implementation-plan.md)
- 原始章节: `## 4. v0.4 Beta 实施计划`

进度入口：

- 当前优先读: [progress.md](progress.md)
- 原始大文档: [doc/progress.md](../../progress.md)
- 原始章节: `## v0.4 Beta`

阅读建议：

- [implementation-plan.md](implementation-plan.md) 用于理解计划和模块边界。
- [progress.md](progress.md) 用于判断哪些任务已完成、哪些仍待复测。
- 不要把 v0.1-v0.3 历史 checklist 当作当前待办。

## v0.4 验证入口

- 当前优先读: [verification.md](verification.md)
- 发布前检查: [release-checklist.md](release-checklist.md)
- 原始验证文档: [doc/verification/v0.4.md](../../verification/v0.4.md)
- v0.4 自动验证脚本: `scripts/verify_v04.ps1`
- M4 回归: `scripts/verify_m4.ps1`
- M5 回归: `scripts/verify_m5.ps1`
- v0.4 打包: `scripts/package_v04.ps1`
- v0.4 包验证: `scripts/verify_v04_package.ps1`

发布收尾必须确认：

- `V04-MAN-061` 已有日志证据支持托盘恢复和纯桌宠策略重套，仍建议人工最终确认 Windows 托盘左键路径。
- `V04-MAN-052` 已记录为 `V04-OPT-001` 后续优化项，不再作为 v0.4 当前修复项。
- `V04-MAN-072` 单击、双击、拖拽、右键菜单已有日志和截图证据；长按仍建议人工最终确认。
- `V04-MAN-073` 已完成 `debug.log` 检查并记录结果。
- v0.4 自动验证和包验证已重新运行。
- release notes、包内 README、manifest 与最终包一致。

## v0.4 UI / 原型 / 动画资料

- 当前原型: [doc/prototypes/index.html](../../prototypes/index.html)
- 原型说明: [doc/prototypes/prototype-spec.md](../../prototypes/prototype-spec.md)
- UI polish spec: [doc/v0.4-ui-polish-spec.md](../../v0.4-ui-polish-spec.md)
- 动画规格: [doc/v0.4-animation-spec.md](../../v0.4-animation-spec.md)
- 动画素材记录: [doc/v0.4-animation-assets-log.md](../../v0.4-animation-assets-log.md)
- 动画提示词包: [doc/v0.4-animation-prompt-pack.md](../../v0.4-animation-prompt-pack.md)
- ComfyUI Spike: [doc/v0.4-comfyui-spike.md](../../v0.4-comfyui-spike.md)

说明：

- UI / 原型资料代表当前设计方向，但具体实现以当前 Godot 代码和 v0.4 验证结果为准。
- 动画和 ComfyUI 文档包含探索记录，不等于全部已接入产品。

## v0.4 发布产物

真实发布产物不在本目录，而在项目根目录下：

- Zip 包: `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64.zip`
- 展开目录: `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64/`
- Manifest: `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64/manifest.json`
- Checksums: `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64/checksums.txt`

`doc/releases/v0.4/` 负责解释、索引和记录状态；不要把它当作可分发产物。

## 不应优先读取的历史文档

以下内容只作为历史参考，不作为当前 v0.4 事实源：

- [doc/verification/v0.1.md](../../verification/v0.1.md)
- [doc/verification/v0.2.md](../../verification/v0.2.md)
- [doc/verification/v0.3.md](../../verification/v0.3.md)
- `doc/LetsMakeMoneyPRD.md` 中 v0.1-v0.3 章节
- `doc/implementation-plan.md` 中 v0.1-v0.3 章节
- `doc/progress.md` 中 v0.1-v0.3 章节
- [doc/v0.2-asset-spike.md](../../v0.2-asset-spike.md)
- [doc/v0.2-asset-prompt-pack.md](../../v0.2-asset-prompt-pack.md)
- [doc/temp-pc-work/](../../temp-pc-work/)
