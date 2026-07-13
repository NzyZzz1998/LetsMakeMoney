# LetsMakeMoney 当前状态入口

**最后更新**：2026-07-13

**项目名**：LetsMakeMoney 赚钱模拟器

**当前发布版本**：v0.7 Beta

**当前发布 tag**：`v0.7-beta`

**发布提交**：`e79149d91e8e0adb3cbf1e53cd8819f072f7154f`

**当前分支**：`main`

**当前阶段**：v0.7 已发布；v0.8 工程治理 C0-C3 已完成，C4 运行时状态治理尚未授权实施

本文件是人工或 agent 接手时的唯一内部当前事实入口。README 面向用户和贡献者；`doc/releases/v0.7/` 保存已发布版本证据；v0.1-v0.6 及跨版本大文档只作为历史参考。

## 1. 当前发布事实

| 对象 | 当前身份 | 说明 |
|---|---|---|
| 公开源码仓库 | `main` / `e79149d...` | GitHub 仓库已公开 |
| v0.7 Beta tag | `v0.7-beta` | 指向发布提交 `e79149d...` |
| GitHub Release | v0.7 Beta Pre-release | 已发布，只包含便携 Zip 与校验文件 |
| 便携 Zip | `releases/v0.7/LetsMakeMoney-v0.7-beta-windows-x86_64.zip` | SHA256 `16F47A844EFD78D387E9D08FBCD3DE76C8C8BDD518731C1B0BA022E7F598121F` |
| 测试安装器 | 本地未签名验收产物 | `NotSigned`，未上传且不得作为公开附件 |
| v0.6 Beta 基线 | `v0.6-beta` | 历史回归与配置兼容基线 |

发布地址：<https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.7-beta>

## 2. 已验证边界

- v0.7 最终 Acceptance 已通过，便携 Zip 可公开使用。
- 真实通知区左键、普通/纯桌宠任务栏策略、100%-200% DPI、配置安全写入、更新失败保护和安装/卸载测试链路已有证据。
- 多显示器、干净 Windows 用户/VM、Authenticode/SmartScreen、真实登录后的开机自启明确为“暂不验证”，不得写成通过。
- 未签名安装器不属于 v0.7 Release 附件。
- 当前正式支持平台仍为 Windows x86_64；iOS、macOS、Android 仅有规划。

## 3. 当前工作

v0.8 当前只进入工程治理准备，不代表产品功能 PRD 已确认：

1. 修复当前事实与文档检查合同。
2. 清理可再生成的本地验收/解压缓存，同时保留本地启动 build 和 v0.7 发布 Zip。
3. 历史文档和脚本职责已完成分层；发布目录与素材生成边界留给 C5。
4. Main/native/托盘/窗口策略只能在补齐行为矩阵后重构。

治理基线：

- [v0.8 工程治理 Review](releases/v0.8/engineering-governance-review.md)
- [v0.8 清理执行方案](releases/v0.8/cleanup-plan.md)

## 4. 推荐阅读顺序

1. [当前状态](current.md)
2. [v0.7 发布状态](releases/v0.7/current.md)
3. [v0.7 验证](releases/v0.7/verification.md)
4. [v0.7 发布说明](releases/v0.7/release-notes.md)
5. [v0.7 公开准备](releases/v0.7/public-readiness.md)
6. [v0.7 PRD](releases/v0.7/prd.md)
7. [v0.8 工程治理 Review](releases/v0.8/engineering-governance-review.md)

## 5. 文档可信度

### 当前事实源

- `README.md` / `README.en.md`：外部入口。
- `doc/current.md`：内部唯一当前状态入口。
- `doc/releases/v0.7/current.md`：v0.7 已发布快照。
- `doc/releases/v0.7/verification.md`：最终验收证据。
- `releases/CHANGELOG.md`：版本变化摘要。

### 历史参考

- `doc/releases/v0.4/` 至 `doc/releases/v0.6/`：已分层的版本事实。
- `doc/archive/legacy-core/`：v0.1-v0.4 跨版本大文档原文。
- `doc/archive/v0.1/` 至 `doc/archive/v0.6/`：旧验证、日志和素材探索。
- `doc/LetsMakeMoneyPRD.md`、`doc/implementation-plan.md`、`doc/progress.md` 仅为兼容入口，不承载正文。

历史文档不得覆盖本文件中的当前发布状态。

## 6. 下一步

下一批为 C4 Main/native 状态治理。该批涉及窗口、托盘、任务栏和点击穿透运行行为，必须先形成正式行为合同并由项目所有者单独授权；不得把 C0-C3 的仓库治理结果视为重构授权。
