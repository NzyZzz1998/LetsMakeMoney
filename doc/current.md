# LetsMakeMoney 当前状态入口

**最后更新**：2026-07-27

本文件是项目当前事实的唯一内部入口。用户与贡献者先读根目录 README；需要实施或验收细节时再进入对应版本目录。

## 当前版本

| 对象 | 当前事实 |
|---|---|
| 当前公开版本 | Windows v1.0 Stable |
| 当前公开 tag | `v1.0` |
| 当前开发版本 | Windows v1.0 Stable |
| v1 技术主线 | Rust + Tauri + TypeScript/React |
| v1 产品主线 | 无宠物迷你收入视图 + 今日/日历工作台 |
| 当前开发阶段 | v1.0 已完成实现、验收、发布收口和远端发布 |
| 发布判断 | 已通过并发布；多显示器仍作为非阻塞待补证项 |
| 历史恢复基线 | `v0.9-beta` tag 与 GitHub Release |

当前工作分支与 HEAD 以 `git status --branch` 为准。正式发布包身份由实现提交、`BUILD-INFO.json` 与 SHA256 共同锁定。

当前验收与发布收口均已完成，`main` 和 `v1.0` tag 指向发布提交 `76a480602af9a3429f9919ec9f9ee66a2add089d`。

## v1.0 已完成

- M0：事实冻结、配置/窗口/日志/视觉合同与隔离骨架。
- M1：Tauri 壳、四窗口与设计系统。
- M2：工资作息、配置事务、日志、诊断与更新服务。
- M3：迷你收入视图、今日与日历工作台。
- M4：三步 Wizard 与四组 Settings。
- M5：托盘、窗口生命周期与诊断实现；真实通知区鼠标左键隐藏/找回和 Explorer 重启后重新注册均已通过。
- M6：旧 Godot、native、宠物资源与旧脚本从当前树下线；配置迁移和零宠物门禁通过。

## 发布后观察

1. 多显示器安全回落因当前设备仅有一台显示器，标记为待补证；项目所有者批准其不阻塞本次 Stable。
2. 独立候选约 95 分钟连续运行稳定，项目所有者确认按约 100 分钟门禁通过。
3. v0.9 官方 Release 包桌面回退与 v1 配置隔离已通过。
4. 功能验收与本轮视觉/交互复验通过，干净提交候选已生成并重新打包。
5. 持续确认 GitHub `Protect_main` ruleset 使用 `Windows v1 verification`，避免恢复 v0.9 时代的检查名。

## v1.0 发布身份

- 源码基线：`806bda6503f1b5ac61212d47abaf5e389fa1948a`，`BUILD-INFO.json` 记录 `source_tree_dirty=false`。
- 发布收口提交：`76a480602af9a3429f9919ec9f9ee66a2add089d`；tag：`v1.0`。
- 便携 Zip：`releases/v1.0/LetsMakeMoney-v1.0-windows-x86_64.zip`
- Zip 大小：`3,044,917` 字节
- Zip SHA256：`A5C33B9DB8787536145AE4B9A1AC00213E692C99A2201CC91EB811A0A0F3BBE6`
- EXE SHA256：`BD25B13F084A0F101DD77239F215019C0BB9E246847BBD15B2D0BEE98B381C44`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- 新候选 GUI 复验路径：`releases/v1.0/LetsMakeMoney-v1.0-windows-x86_64/LetsMakeMoney.exe`
- 说明：新候选已完成迷你收入视图、Today、Calendar、Settings 四任务组、无变化保存、100%/125%/150% 真实 Windows DPI、通知区左键双向切换和 Explorer 重启后托盘重注册复验；迷你窗口拖动、位置保存和重启恢复已通过真实 Windows 鼠标复验。迷你窗口恢复后重新应用 `skip_taskbar=true`，Settings 关闭后任务栏入口正常消失。首次 Wizard 全链路证据保留在上一候选验收记录中。
- 远端 CI：`Windows v1 verification` 于 2026-07-26 复核通过。
- 独立视觉抽查：迷你收入视图、Today、Calendar 与 Settings 四任务组未发现裁切、重叠或可读性阻塞；证据位于 `.tmp_acceptance/v1.0-visual-test-20260726/evidence/`。
- 休息日定向复验：迷你收入视图和 Today 不再显示今日收益、日薪、时薪、有效工时、工作进度或预计收入；Calendar 使用真实当前日期，并通过图例和无障碍标签明确描边代表“今天”。真实候选包证据位于 `.tmp_acceptance/v1.0-rest-day-20260726-101249/evidence/`。
- 窗口与导航定向修正：默认位置、今日工作台/Settings/Wizard 拖动权限、日历跨月、日历入口图标、Settings 分隔线与间距、Wizard 重新配置回到第 1 步均已完成。定向包 Zip SHA256 为 `99DB494245F207B420B9B3CCDBA96D8DC65EC4F444926DF4DE03AD021A8911A8`，但其 `BUILD-INFO.json` 记录 `source_tree_dirty=true`，仅用于本轮验收，不替代上方干净 Stable 候选。
- 控制台窗口定向修正：Release 入口已声明 Windows GUI 子系统，新 EXE 的 PE Subsystem 为 `2 (Windows GUI)`，从便携包启动不再附带控制台窗口。定向包 Zip SHA256 为 `A3725C89D7F886FAC8D5B89E92750B719A54D7B2B4345AE76533D57C44236A21`，EXE SHA256 为 `698212B4D9479BA1C674C2118FC04075FFA9C87F10A4DCC8AAFFDCD0E308215C`；该包同样记录 `source_tree_dirty=true`，不替代上方干净 Stable 候选。
- 全窗口拖动与 Wizard 午休单位定向修正：迷你收入视图、今日工作台、Settings 和 Wizard 改为移动超过 `5px` 后进入拖动，不再依赖 `220ms` 长按或 WebView 系统拖动入口；按钮、输入框、选择器、链接和开关继续保留原交互。Computer Use 已确认四类窗口均可从普通文字或空白区域移动，Wizard 的“2 小时”保持单行横排。
- 午休时长小数定向修正：Wizard 允许输入至多两位小数，例如 `0.5`、`1.5`、`2.25`；输入文本不会在键入小数点时被提前取整。真实 GUI 输入 `1.5` 后，午休区间由 `12:00–14:00` 更新为 `12:00–13:30`，推算下班时间由 `18:00` 更新为 `17:30`，有效工时保持 8 小时。
- 最新定向包 Zip SHA256：`91F672A14C2432F232DBE2F90EDF9027C3FB5C02E75BBC12FF2D2325C2A80DB4`；EXE SHA256：`ECFDFAB4BE44EF24EA738CA7821BE3EC6F477CDBA5248A34D0BC5B343ED5F0E0`；WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。该包记录 `source_tree_dirty=true`，用于定向验收，不替代上方干净 Stable 候选。

## 版本边界

- 零午休时长已经纳入 v1.0 正式计算口径：`lunch_start_time == lunch_end_time` 表示无午休，不再触发收入计算失败。
- 最新零午休定向候选 Zip SHA256：`0609FA1F8B508D5CBDFF9061D1D270AE78FB66B5666119839996346D087D1029`；EXE SHA256：`1C909C40DF6A0D10EB58D3C65A418AE618FA89C64F725547E53AA63A79509FC2`。

- v1.0 不包含宠物 UI、运行时、配置、资源、点击穿透或纯桌宠模式。
- v1.0 不提供安装器、静默更新、账号、云同步或主题系统。
- v0.9 的桌宠体验只通过历史 tag 与 Release 恢复，不复制回 v1 主线。
- 配置与日志保存在 `%APPDATA%\io.letsmakemoney.windows\`。

## 推荐阅读顺序

1. [v1.0 进度看板](releases/v1.0/progress_v1.0.md)
2. [v1.0 验证记录](releases/v1.0/verification.md)
3. [v1.0 PRD](releases/v1.0/prd.md)
4. [v1.0 开发计划](releases/v1.0/dev_plan_v1.0.md)
5. [宠物退役审计](releases/v1.0/pet-retirement-audit.md)
6. [v0.9 回退说明](releases/v1.0/v0.9-rollback.md)
7. [v1.0 人工验证](releases/v1.0/manual-verification.md)
8. [v1.0 视觉手动验收](releases/v1.0/visual-acceptance.md)

## 可信度

### 当前事实源

- `doc/current.md`
- `doc/releases/v1.0/progress_v1.0.md`
- `doc/releases/v1.0/verification.md`
- `doc/releases/v1.0/prd.md`
- `apps/windows-v1/`

### 历史参考

- `doc/releases/v0.9/`：最后一个桌宠版本的产品、验收和发布记录。
- `v0.9-beta` tag / Release：桌宠恢复基线。
- v0.1-v0.8 文档：仅用于历史追溯，不覆盖本文件。

## 下一步

更新 `Protect_main` 所需检查名，并在项目所有者明确授权后执行推送、合并 `main`、tag 和 GitHub Release。
