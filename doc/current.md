# LetsMakeMoney 当前状态入口

**最后更新**：2026-07-26

本文件是项目当前事实的唯一内部入口。用户与贡献者先读根目录 README；需要实施或验收细节时再进入对应版本目录。

## 当前版本

| 对象 | 当前事实 |
|---|---|
| 当前公开版本 | Windows v0.9 Beta |
| 当前公开 tag | `v0.9-beta` |
| 当前开发版本 | Windows v1.0 Stable 候选 |
| v1 技术主线 | Rust + Tauri + TypeScript/React |
| v1 产品主线 | 无宠物迷你收入视图 + 今日/日历工作台 |
| 当前开发阶段 | v1.0 Stable 候选已推送 `test`，自动门禁与独立视觉抽查通过，项目所有者视觉复验进行中 |
| 发布判断 | 候选无已知业务阻塞；待项目所有者完成视觉签字并更新 `main` 分支保护检查名后进入发布收口 |
| 历史恢复基线 | `v0.9-beta` tag 与 GitHub Release |

当前工作分支与 HEAD 以 `git status --branch` 为准。正式候选包身份由实现提交、`BUILD-INFO.json` 与 SHA256 共同锁定。

## v1.0 已完成

- M0：事实冻结、配置/窗口/日志/视觉合同与隔离骨架。
- M1：Tauri 壳、四窗口与设计系统。
- M2：工资作息、配置事务、日志、诊断与更新服务。
- M3：迷你收入视图、今日与日历工作台。
- M4：三步 Wizard 与四组 Settings。
- M5：托盘、窗口生命周期与诊断实现；真实通知区鼠标左键隐藏/找回和 Explorer 重启后重新注册均已通过。
- M6：旧 Godot、native、宠物资源与旧脚本从当前树下线；配置迁移和零宠物门禁通过。

## 当前必须完成

1. 多显示器安全回落因当前设备仅有一台显示器，标记为待补证；项目所有者批准其不阻塞本次 Stable。
2. 独立候选约 95 分钟连续运行稳定，项目所有者确认按约 100 分钟门禁通过。
3. v0.9 官方 Release 包桌面回退与 v1 配置隔离已通过。
4. 功能验收通过，干净提交候选已生成并重新打包；项目所有者需按 `visual-acceptance.md` 完成最终视觉签字。
5. GitHub `Protect_main` ruleset 仍引用 v0.9 时代的两个检查名，发布前需改为 `Windows v1 verification`。

## 当前候选身份

- 源码基线：`88f1e2a8a66dd7b97ffd7d0b6e127b7ac06189a9`，`BUILD-INFO.json` 记录 `source_tree_dirty=false`。
- `test` 最近一次完整 CI 通过 HEAD：`c8618e4509a0ef416a177c7d45a8324a267a3c4e`；后续仅文档收口提交不改变下列已锁定候选包身份。
- 便携 Zip：`releases/v1.0/LetsMakeMoney-v1.0-windows-x86_64.zip`
- Zip SHA256：`3652A31D416B1B9CDDA2876EA2743586B8EC698C63DCC57078A116F8AFEA92D4`
- EXE SHA256：`73C41A3295C137F467A5B669A72EAD6A9BA37EC83F30545051680CDF9D1FD4F2`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- 新候选 GUI 复验路径：`releases/v1.0/LetsMakeMoney-v1.0-windows-x86_64/LetsMakeMoney.exe`
- 说明：新候选已完成迷你收入视图、Today、Calendar、Settings 四任务组、无变化保存、100%/125%/150% 真实 Windows DPI、通知区左键双向切换和 Explorer 重启后托盘重注册复验；迷你窗口拖动、位置保存和重启恢复已通过真实 Windows 鼠标复验。迷你窗口恢复后重新应用 `skip_taskbar=true`，Settings 关闭后任务栏入口正常消失。首次 Wizard 全链路证据保留在上一候选验收记录中。
- 远端 CI：`Windows v1 verification` 于 2026-07-26 通过，run `30168115925`。
- 独立视觉抽查：迷你收入视图、Today、Calendar 与 Settings 四任务组未发现裁切、重叠或可读性阻塞；证据位于 `.tmp_acceptance/v1.0-visual-test-20260726/evidence/`，项目所有者完整视觉复验尚未签字。

## 版本边界

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

完成项目所有者视觉复验，更新 `Protect_main` 所需检查名，再审核最终身份并决定合并 `main`、tag 和 GitHub Release。
