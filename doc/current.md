# LetsMakeMoney 当前状态入口

**最后更新**: 2026-07-09  
**项目名**: LetsMakeMoney 赚钱模拟器  
**当前版本**: v0.4 Beta  
**当前分支**: `main`
**当前阶段**: v0.4 Beta 已推送至 `main`，统一标签为 `v0.4-beta`；当前处于发布后补验收 / 收尾校准阶段

本文件是后续人工或 agent 接手时的第一入口。先读这里判断当前事实源，再进入 v0.4 专属文档；不要直接从超大的 PRD、实施计划或 progress 从头读起。

## 当前版本目标

v0.4 Beta 是大型体验优化版本。当前重点不是继续扩底层功能，而是把 v0.3 已实现的真托盘、透明窗口、点击穿透、关闭隐藏到托盘、纯桌宠模式、橘猫 v2、Panel、右键菜单、Settings 和 Wizard 打磨成更适合日常使用的桌面小挂件体验。

当前视觉方向以“温暖桌面小挂件 / 橘猫金币小票便签风”为准：橘猫负责陪伴感，Panel 负责轻量薪资反馈，Settings / Wizard 负责清晰、紧凑、可恢复的偏好设置体验。

## 当前必须完成 / 验证

以 [doc/releases/v0.4/verification.md](releases/v0.4/verification.md) 为当前 v0.4 手动验收入口。

- `V04-MAN-061`: 部分通过。发布包正常模式启动日志显示 native / tray / passthrough / taskbar 能力可用；既有日志显示托盘隐藏 / 显示后会重套纯桌宠策略。Computer Use 无法直接点击 Windows 托盘，建议保留一次人工最终确认。
- `V04-MAN-072`: 部分通过。Debug 窗口下连续单击、双击、拖拽、右键菜单均有日志和截图证据；长按因 Computer Use 无精确按住 0.7 秒能力，仍需人工最终确认。
- `V04-MAN-073`: 通过。验收时检查 `debug.log`，未发现 parser/runtime/Invalid call/null instance/native 访问异常。
- `V04-OPT-001` / `V04-MAN-052`: Wizard 薪资页控件视觉与 Settings 一致性多轮修复后体感无明显变化，已暂缓并转入后续优化清单，不再作为当前继续修补项。

自动化或 Computer Use 能覆盖的项已记录为通过 / 部分通过；仍需人工补充的项只保留为最终确认，不再扩展为新需求。

## 当前发布产物状态

v0.4 Beta 发布包已经形成可分发 Beta 产物，代码与发布状态已通过 `v0.4-beta` 标签归档：

- Zip 包: `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64.zip`
- 展开目录: `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64/`
- Manifest: `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64/manifest.json`
- 包内关键文件: `LetsMakeMoney.exe`、`letsmakemoney_native.dll`、`app_icon.ico`、`README.md`、`release-notes.md`、`checksums.txt`

注意区分两个目录：

- `doc/releases/v0.4/`: v0.4 专属文档目录，不包含真实 exe。
- `releases/v0.4/`: 真实发布产物目录，包含 zip、exe、manifest 和 checksum。

当前发布包仍属于 Beta 产物。任何代码、资源或发布说明修复后，都需要重新运行 `scripts/package_v04.ps1` 和 `scripts/verify_v04_package.ps1`。

## 推荐阅读顺序

1. [doc/current.md](current.md)
2. [doc/releases/v0.4/status.md](releases/v0.4/status.md)
3. [doc/releases/v0.4/README.md](releases/v0.4/README.md)
4. [doc/releases/v0.4/verification.md](releases/v0.4/verification.md)
5. [doc/releases/v0.4/progress.md](releases/v0.4/progress.md)
6. [doc/releases/v0.4/prd.md](releases/v0.4/prd.md)
7. [doc/releases/v0.4/implementation-plan.md](releases/v0.4/implementation-plan.md)
8. [doc/releases/v0.4/release-checklist.md](releases/v0.4/release-checklist.md)
9. [doc/prototypes/prototype-spec.md](prototypes/prototype-spec.md)
10. [doc/prototypes/index.html](prototypes/index.html)
11. [doc/v0.4-ui-polish-spec.md](v0.4-ui-polish-spec.md)

## 当前可信文档

| 文件 | 当前用途 | 可信口径 |
|---|---|---|
| [doc/current.md](current.md) | 当前状态入口 | 当前事实源，优先信 |
| [doc/releases/v0.4/status.md](releases/v0.4/status.md) | v0.4 短状态摘要 | 当前事实源，优先信 |
| [doc/releases/v0.4/README.md](releases/v0.4/README.md) | v0.4 文档索引 | 当前事实源，优先信 |
| [doc/releases/v0.4/verification.md](releases/v0.4/verification.md) | v0.4 手动验证 | 当前验收入口，优先信 |
| [doc/releases/v0.4/progress.md](releases/v0.4/progress.md) | v0.4 任务进度 | 当前 v0.4 进度入口 |
| [doc/releases/v0.4/prd.md](releases/v0.4/prd.md) | v0.4 PRD | 当前 v0.4 需求入口 |
| [doc/releases/v0.4/implementation-plan.md](releases/v0.4/implementation-plan.md) | v0.4 实施计划 | 当前 v0.4 实施入口 |
| [doc/releases/v0.4/release-checklist.md](releases/v0.4/release-checklist.md) | v0.4 发布前检查 | 发布前门禁入口 |
| [doc/prototypes/prototype-spec.md](prototypes/prototype-spec.md) | 当前交互原型说明 | 当前原型事实源 |
| [doc/prototypes/index.html](prototypes/index.html) | 当前可交互原型 | 当前原型事实源 |
| [doc/v0.4-ui-polish-spec.md](v0.4-ui-polish-spec.md) | v0.4 UI polish 方向 | 当前 UI 方向参考 |
| `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64/manifest.json` | 当前发布包清单 | 当前包内容事实源 |

## 文档地图

| 文件 / 目录 | 当前用途 | 所属版本 | 当前可信度 | 是否过大 | 建议去向 |
|---|---|---|---|---|---|
| `doc/current.md` | 当前唯一状态入口 | v0.4 | 高 | 否 | 保留原位 |
| `doc/releases/v0.4/` | v0.4 专属文档目录 | v0.4 | 高 | 否 | 当前版本入口 |
| `doc/releases/v0.4/prd.md` | v0.4 PRD 拆分副本 | v0.4 | 高 | 否 | 优先读取 |
| `doc/releases/v0.4/implementation-plan.md` | v0.4 实施计划拆分副本 | v0.4 | 高 | 中 | 优先读取 |
| `doc/releases/v0.4/progress.md` | v0.4 进度拆分副本 | v0.4 | 高 | 中 | 优先读取 |
| `doc/releases/v0.4/verification.md` | v0.4 验证拆分副本 | v0.4 | 高 | 否 | 优先读取 |
| `doc/releases/v0.4/release-checklist.md` | v0.4 发布前检查清单 | v0.4 | 高 | 否 | 发布前读取 |
| `doc/verification/v0.4.md` | v0.4 验证原始文件 | v0.4 | 高 | 否 | 暂保留，后续可迁移/替换为跳转说明 |
| `doc/prototypes/` | 当前可交互原型和说明 | 当前 | 高 | 中 | 保留原位 |
| `doc/v0.4-ui-polish-spec.md` | v0.4 UI 打磨规格 | v0.4 | 高 | 否 | 暂保留原位，后续可迁入 `doc/releases/v0.4/` |
| `doc/v0.4-animation-spec.md` | v0.4 动画规格 | v0.4 | 中高 | 否 | 暂保留原位，索引引用 |
| `doc/v0.4-animation-assets-log.md` | v0.4 动画素材记录 | v0.4 | 中 | 否 | 暂保留原位，索引引用 |
| `doc/v0.4-animation-prompt-pack.md` | v0.4 动画提示词 | v0.4 | 中 | 否 | 暂保留原位，索引引用 |
| `doc/v0.4-comfyui-spike.md` | v0.4 ComfyUI 调研 | v0.4 / Spike | 中 | 否 | 暂保留原位，后续可归入 `archive/spikes` |
| `doc/LetsMakeMoneyPRD.md` | 全版本 PRD 原始大文档 | v0.1-v0.4 | 分章节可信 | 是 | 保留为原始历史源，v0.4 优先读拆分副本 |
| `doc/implementation-plan.md` | 全版本实施计划原始大文档 | v0.1-v0.4 | 分章节可信 | 是 | 保留为原始历史源，v0.4 优先读拆分副本 |
| `doc/progress.md` | 全版本进度原始大文档 | v0.1-v0.4 | 分章节可信 | 是 | 保留为原始历史源，v0.4 优先读拆分副本 |
| `doc/verification/v0.1.md` | v0.1 验证记录 | v0.1 | 历史参考 | 否 | 后续可归档 |
| `doc/verification/v0.2.md` | v0.2 验证记录 | v0.2 | 历史参考 | 否 | 后续可归档 |
| `doc/verification/v0.3.md` | v0.3 验证记录 | v0.3 | 历史参考 | 中 | 后续可归档 |
| `doc/v0.2-asset-spike.md` | v0.2 素材 Spike | v0.2 / Spike | 历史参考 | 否 | 后续可归档到 spikes |
| `doc/v0.2-asset-prompt-pack.md` | v0.2 素材提示词 | v0.2 / Spike | 历史参考 | 否 | 后续可归档到 spikes |
| `doc/temp-pc-work/` | 临时 PC 工作区 | 临时 | 历史参考 | 否 | 暂不移动，后续可归档 |
| `doc/ui-prototype-warm-widget.html` | 早期暖色原型 | 原型历史 | 参考 | 否 | 保留为历史原型参考 |

## 仅供历史参考的文档

- [doc/verification/v0.1.md](verification/v0.1.md)
- [doc/verification/v0.2.md](verification/v0.2.md)
- [doc/verification/v0.3.md](verification/v0.3.md)
- [doc/LetsMakeMoneyPRD.md](LetsMakeMoneyPRD.md) 中 v0.1-v0.3 章节
- [doc/implementation-plan.md](implementation-plan.md) 中 v0.1-v0.3 章节
- [doc/progress.md](progress.md) 中 v0.1-v0.3 章节
- `releases/v0.3-beta-notes.md`
- `releases/CHANGELOG.md` 中 v0.3 及更早条目
- [doc/v0.2-asset-spike.md](v0.2-asset-spike.md)
- [doc/v0.2-asset-prompt-pack.md](v0.2-asset-prompt-pack.md)
- [doc/temp-pc-work/](temp-pc-work/)

## 已知文档不一致项

- v0.4 拆分文件是从原始大文档复制出来的阶段性副本。若原始大文档后续继续被编辑，需要同步更新 `doc/releases/v0.4/` 下对应文件。
- `doc/LetsMakeMoneyPRD.md` 和 `doc/implementation-plan.md` 的 v0.4 章节可能仍保留“草案”或早期计划口径；当前实际状态以本文件、v0.4 status 和 v0.4 verification 为准。
- [doc/releases/v0.4/verification.md](releases/v0.4/verification.md) 仍包含部分通过 / 待人工最终确认项；不要把 v0.4 当作完全关闭态。
- `releases/v0.4-beta-notes.md` 对最新 UI / Wizard 修复可能滞后；正式发布前需要同步。

## 下一步

1. 按 [doc/releases/v0.4/verification.md](releases/v0.4/verification.md) 完成人工最终确认项。
2. 根据最终确认结果更新 [doc/releases/v0.4/status.md](releases/v0.4/status.md) 和 [doc/releases/v0.4/verification.md](releases/v0.4/verification.md)；不要把验收过程流水写入 progress。
3. 如果仍同步维护原始大文档，需要把 v0.4 变更回写到 `doc/progress.md` 和 `doc/verification/v0.4.md`。
4. 正式发布前同步 `releases/v0.4-beta-notes.md` 和包内 README / release notes。
