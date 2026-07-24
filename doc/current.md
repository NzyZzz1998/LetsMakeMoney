# LetsMakeMoney 当前状态入口

**最后更新**：2026-07-24

本文件是项目当前事实的唯一内部入口。用户与贡献者先读根目录 README；需要实施或验收细节时再进入对应版本目录。

## 当前版本

| 对象 | 当前事实 |
|---|---|
| 当前公开版本 | Windows v0.9 Beta |
| 当前公开 tag | `v0.9-beta` |
| 当前开发版本 | Windows v1.0 Stable 候选 |
| v1 技术主线 | Rust + Tauri + TypeScript/React |
| v1 产品主线 | 无宠物迷你收入视图 + 今日/日历工作台 |
| 当前开发阶段 | M7 自动门禁、定向 GUI、三档真实 DPI、通知区、Explorer 重启与长期运行复验已完成 |
| 发布判断 | v1.0 验收通过，干净提交候选已生成并通过包体验证 |
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
4. 已验收实现已形成干净提交并重新打包；发布动作仍需项目所有者另行批准。

## 当前候选身份

- 源码基线：`88f1e2a8a66dd7b97ffd7d0b6e127b7ac06189a9`，`BUILD-INFO.json` 记录 `source_tree_dirty=false`。
- 便携 Zip：`releases/v1.0/LetsMakeMoney-v1.0-windows-x86_64.zip`
- Zip SHA256：`DA19785290F9163C82F19F4EF320A3C55B28B8E737BD75C74F39EF0B9DA73336`
- EXE SHA256：`49CD4A04442C971F7594178F905C399568536B4E024DE3576612B23D51534F3F`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- 新候选 GUI 复验路径：`releases/v1.0/LetsMakeMoney-v1.0-windows-x86_64/LetsMakeMoney.exe`
- 说明：新候选已完成迷你收入视图、Today、Calendar、Settings 四任务组、无变化保存、100%/125%/150% 真实 Windows DPI、通知区左键双向切换和 Explorer 重启后托盘重注册复验；迷你窗口恢复后重新应用 `skip_taskbar=true`，Settings 关闭后任务栏入口正常消失。首次 Wizard 全链路证据保留在上一候选验收记录中。

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

干净提交与 Stable 候选包已生成。下一步是项目所有者审核最终身份后，另行决定推送、tag 和 GitHub Release。
