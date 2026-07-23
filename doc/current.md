# LetsMakeMoney 当前状态入口

**最后更新**：2026-07-23

**项目名**：LetsMakeMoney 赚钱模拟器

**当前发布版本**：v0.8 Beta

**当前发布 tag**：`v0.8-beta`

**发布提交**：`a330d14230add1537b18c35c8ad38c6ae43430a2`

**当前发布分支**：`main`

**当前开发分支**：`agent/v0.9-acceptance-continue`

**当前阶段**：v0.8 Beta 仍是公开发布版本；v0.9 锁定候选已关闭 `V09-BUG-006/007/008` 并完成最终验收，结论为“通过 / 可进入发布收口”，尚未执行提交、推送、tag 或 Release

本文件是人工或 agent 接手时的唯一内部当前事实入口。README 面向用户和贡献者；`doc/releases/v0.8/` 保存当前发布版本证据；v0.1-v0.7 及跨版本大文档按需作为历史参考。

## 1. 当前发布事实

| 对象 | 当前身份 | 说明 |
|---|---|---|
| 公开源码仓库 | `main` / `a330d142...` | PR #3 已通过必需 CI 并 squash 合并 |
| v0.8 Beta tag | `v0.8-beta` | 指向发布提交 `a330d142...` |
| GitHub Release | v0.8 Beta Pre-release | 已发布，只包含便携 Zip 与校验文件 |
| 便携 Zip | `releases/v0.8/LetsMakeMoney-v0.8-beta-windows-x86_64.zip` | SHA256 `A2065B82F7674E5A19AC4FD467E7DEA3E8D665E3C148634C3721B7BD90AE098E` |
| 测试安装器 | 本地未签名验收产物 | `NotSigned`，未上传且不得作为公开附件 |
| v0.7 Beta 基线 | `v0.7-beta` | 历史桌宠体验与配置兼容基线 |

发布地址：<https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.8-beta>

## 2. 已验证边界

- v0.8 最终 Acceptance 已通过，便携 Zip 已公开发布。
- 真实通知区左键、普通/纯桌宠任务栏策略、100%-200% DPI、配置安全写入、更新失败保护和安装/卸载测试链路已有证据。
- 多显示器、干净 Windows 用户/VM、Authenticode/SmartScreen、真实登录后的开机自启明确为“暂不验证”，不得写成通过。
- 未签名安装器不属于 v0.8 Release 附件。
- 2026-07-15，SignPath Foundation 免费签名申请未获批准，原因为项目当前缺少足够的社区采用、外部讨论和持续公开影响力信号；这不是对代码质量或安全性的否定。当前 EXE 与测试安装器继续保持未签名，后续积累公开社区信号后再申请或评估商业证书。
- 当前正式支持平台仍为 Windows x86_64；iOS、macOS、Android 仅有规划。

## 3. 当前工作

v0.8 当前包含两条已经执行的工作线：

1. 工程治理 C0-C5：当前事实、生成物、历史文档、脚本职责、Main/native 状态和发布边界已完成治理及对应回归。
2. 薪资与作息规则：按当月实际工作日计算日薪，增加午休扣除和大小周，配置升级至 v4，并保持 v3 配置迁移。

薪资与作息实现已完成候选验证和发布。2026-07-17 已使用新解压候选 Zip 完成 Settings 五页、Wizard 四步、保存/无变化、重启持久化、工资与作息、右键菜单、托盘、纯桌宠和点击穿透的最终桌面验收。

v0.8 候选包由源码提交 `08f7820bfd95ff56132eb87eb9255078adb9572a` 构建并完成验收，发布文档通过 PR #3 一并收口；最终发布提交为 `a330d14230add1537b18c35c8ad38c6ae43430a2`。发布 Zip 为 `releases/v0.8/LetsMakeMoney-v0.8-beta-windows-x86_64.zip`，SHA256 为 `A2065B82F7674E5A19AC4FD467E7DEA3E8D665E3C148634C3721B7BD90AE098E`。

下一版本计划对宠物动作进行较大范围优化。2026-07-17 已开始审查 LetsMakeMoney 内部宠物运行时与仓库外部的独立 PetManager 素材生产项目。当前只确认两者职责和契约缺口，不在 v0.8 分支直接替换素材、重构状态机或接入 PetManager 交付包。

2026-07-23，v0.9 已完成工资与作息口径、Settings/Wizard 高保真生产级还原、Panel/今日详情、通用宠物包运行时、动画状态机、输入仲裁、业务事件层和配套自动门禁。多多 S5.5 已接入，Classic 保持兼容回退；`V09-BUG-002` 至 `V09-BUG-008` 均已关闭。最终真实 GUI 验收使用 Zip SHA256 `DFADCFF7F1DB1F461D4241EFC9F86E286E7C533211785BA7E5C74072FE5144DF` 的全新解压副本，完成 Panel、今日详情、Settings 五页、Wizard 四步/返回/取消/关闭、菜单、Classic/多多切换与当前状态单击、Popup/Modal 穿透、语义日志和 v0.8 回归。项目所有者随后选择重新打包最终文档快照；最终发布附件 Zip SHA256 为 `B10FDE2027D4ABC71C41F0F7AC7BDCE3D93AEB8AFAF4058BA1A592B6A75CC1EC`，EXE 与 Native DLL 哈希保持不变，包体验证和新解压冒烟通过。最终结论仍为“通过 / 可进入发布收口”。真实通知区鼠标、500ms 长按跑动和两套宠物完整三状态观感仍待人工补证；真实 125%/150% DPI、受控损坏包桌面观感和两小时稳定运行暂不验证。

治理基线：

- [v0.8 工程治理 Review](releases/v0.8/engineering-governance-review.md)
- [v0.8 清理执行方案](releases/v0.8/cleanup-plan.md)
- [v0.8 薪资与作息验证](releases/v0.8/salary-schedule-verification.md)
- [v0.8 版本级验证](releases/v0.8/verification.md)
- [v0.8 人工验证](releases/v0.8/manual-verification.md)
- [宠物动作与 PetManager 深度 Review](releases/v0.8/pet-animation-next-version-review.md)

## 4. 推荐阅读顺序

1. [当前状态](current.md)
2. [v0.9 进度看板](releases/v0.9/progress_v0.9.md)
3. [v0.9 目录与保留决策](releases/v0.9/structure-retention.md)
4. [v0.9 PRD](releases/v0.9/prd.md)
5. [v0.8 版本级验证](releases/v0.8/verification.md)
6. [v0.8 发布说明](releases/v0.8/release-notes.md)
7. [v0.8 人工验证](releases/v0.8/manual-verification.md)
8. [v0.8 薪资与作息验证](releases/v0.8/salary-schedule-verification.md)
9. [宠物动作与 PetManager 深度 Review](releases/v0.8/pet-animation-next-version-review.md)

## 5. 文档可信度

### 当前事实源

- `README.md` / `README.en.md`：外部入口。
- `doc/current.md`：内部唯一当前状态入口。
- `doc/releases/v0.8/verification.md`：当前版本最终验收与发布证据。
- `doc/releases/v0.8/release-notes.md`：当前版本用户可见变化与分发边界。
- `doc/releases/v0.9/progress_v0.9.md`：下一版本开发状态、阻塞关闭情况、验收结论和证据入口。
- `releases/CHANGELOG.md`：版本变化摘要。

### 历史参考

- `doc/releases/v0.4/` 至 `doc/releases/v0.6/`：已分层的版本事实。
- `doc/archive/legacy-core/`：v0.1-v0.4 跨版本大文档原文。
- `doc/archive/v0.1/` 至 `doc/archive/v0.6/`：旧验证、日志和素材探索。
- `doc/LetsMakeMoneyPRD.md`、`doc/implementation-plan.md`、`doc/progress.md` 仅为兼容入口，不承载正文。

历史文档不得覆盖本文件中的当前发布状态。

## 6. 下一步

v0.8 发布收口已完成。未签名安装器不属于公开发布附件；发布后优先观察配置迁移、工资与午休计算、托盘找回和 Windows 未签名提示，不在维护阶段扩入新功能。

v0.9 已完成最终验收，下一步只进行发布文档、提交、分支、tag 和 Release 收口，不再扩功能或修改候选业务代码。发布收口必须继续披露待人工补证、暂不验证和前端质感体验债；在提交、tag 与 Release 实际完成前，不得把 v0.9 写成当前公开发布版本，也不得覆盖 v0.8 的现有发布事实。
