# LetsMakeMoney 当前状态入口

**最后更新**：2026-07-17

**项目名**：LetsMakeMoney 赚钱模拟器

**当前发布版本**：v0.7 Beta

**当前发布 tag**：`v0.7-beta`

**发布提交**：`e79149d91e8e0adb3cbf1e53cd8819f072f7154f`

**当前发布分支**：`main`

**当前开发分支**：`feature/v0.8-salary-schedule`

**当前阶段**：v0.7 已发布；v0.8 工程治理 C0-C5 与薪资作息实现已提交到功能分支，项目版本身份已切换为 `0.8-beta`，自动回归、候选包验证和新解压 smoke 已通过，等待候选包真实桌面人工验收；下一版本宠物动作优化仅进入 Review，尚未形成正式需求

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

v0.8 当前包含两条已经执行的工作线：

1. 工程治理 C0-C5：当前事实、生成物、历史文档、脚本职责、Main/native 状态和发布边界已完成治理及对应回归。
2. 薪资与作息规则：按当月实际工作日计算日薪，增加午休扣除和大小周，配置升级至 v4，并保持 v3 配置迁移。

薪资与作息实现当前仍处于开发候选状态，不得写成 v0.8 已发布。2026-07-17 已使用开发 EXE 完成 Settings、Wizard、Panel、大小周持久化和午休冻结的真实界面手动验收；当前必须以新生成的 `0.8-beta` Zip 再执行版本级 Acceptance。

下一版本计划对宠物动作进行较大范围优化。2026-07-17 已开始审查 LetsMakeMoney 内部宠物运行时与仓库外部的独立 PetManager 素材生产项目。当前只确认两者职责和契约缺口，不在 v0.8 分支直接替换素材、重构状态机或接入 PetManager 交付包。

治理基线：

- [v0.8 工程治理 Review](releases/v0.8/engineering-governance-review.md)
- [v0.8 清理执行方案](releases/v0.8/cleanup-plan.md)
- [v0.8 薪资与作息验证](releases/v0.8/salary-schedule-verification.md)
- [v0.8 版本级验证](releases/v0.8/verification.md)
- [v0.8 人工验证](releases/v0.8/manual-verification.md)
- [宠物动作与 PetManager 深度 Review](releases/v0.8/pet-animation-next-version-review.md)

## 4. 推荐阅读顺序

1. [当前状态](current.md)
2. [v0.7 发布状态](releases/v0.7/current.md)
3. [v0.7 验证](releases/v0.7/verification.md)
4. [v0.7 发布说明](releases/v0.7/release-notes.md)
5. [v0.7 公开准备](releases/v0.7/public-readiness.md)
6. [v0.7 PRD](releases/v0.7/prd.md)
7. [v0.8 薪资与作息验证](releases/v0.8/salary-schedule-verification.md)
8. [v0.8 工程治理 Review](releases/v0.8/engineering-governance-review.md)
9. [宠物动作与 PetManager 深度 Review](releases/v0.8/pet-animation-next-version-review.md)

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

当前第一优先级是整理 v0.8 薪资与作息分支的有意变更，执行合并前检查并生成新的候选包。候选包仍需完成版本级回归和发布门禁，不能仅凭本次功能手动验收直接标记为可发布。

宠物动作方向的下一步是进入 `/idea`，先确认下一版本的首要成果究竟是“建立可复用宠物包运行时契约”，还是“替换当前默认橘猫动作”；在范围确认前不并入 v0.8。
