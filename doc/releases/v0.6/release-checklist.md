# LetsMakeMoney v0.6 Beta 发布检查清单

**最后更新**：2026-07-11
**当前状态**：v0.6 Beta 已发布
**发布结论**：最终验收通过，GitHub Pre-release 已创建

## 版本与产物

- [x] 版本名统一为 `v0.6 Beta`，应用版本元数据为 `0.6-beta`。
- [x] 当前分支为 `main`。
- [x] 验收 HEAD 为 `77cef5cf3f8dc39e695f12d03e12598aa7260fee`。
- [x] 发布包为 `releases/v0.6/LetsMakeMoney-v0.6-beta-windows-x86_64.zip`。
- [x] Zip 大小为 `42,778,715` 字节。
- [x] Zip SHA256 为 `CECD3C3ABACFCB5EF594584E2AEB0E25C1824BAE97AB84B224073E7444E72615`。
- [x] manifest、包内 checksums、EXE 与 native DLL 身份验证通过。
- [x] 本轮没有重新打包，已验收 Zip 与哈希保持不变。

## 范围与验收

- [x] FR-001 至 FR-009 已按 PRD 和验证优先规则收口。
- [x] Settings、Wizard、Panel、右键菜单和共享控件回归通过。
- [x] Settings 保存成功、无变化、失败反馈和事务回滚通过。
- [x] Wizard 下一步、上一步、完成、取消和关闭通过。
- [x] Popup/Modal 点击穿透暂停与恢复通过。
- [x] 普通模式和纯桌宠模式的托盘隐藏/恢复通过。
- [x] 纯桌宠恢复后任务栏入口策略通过。
- [x] 诊断摘要复制、脱敏、成功反馈和数据目录入口通过。
- [x] 配置损坏恢复、日志等级与 2 MB 单备份轮换通过。
- [x] v0.5、v0.4、M4、M5 回归通过。
- [x] 最终验收结论为“通过”，无发布阻塞项。

## 自动与只读检查

- [x] `scripts/verify_v06.ps1`
- [x] `scripts/verify_v06_tray.ps1`
- [x] `scripts/verify_v06_config.ps1`
- [x] `scripts/verify_v05.ps1`
- [x] `scripts/verify_v04.ps1`
- [x] `scripts/verify_m4.ps1`
- [x] `scripts/verify_m5.ps1`
- [x] `scripts/package_v06.ps1` 已生成当前已验收候选包；本轮未重新打包。
- [x] `scripts/verify_v06_package.ps1`
- [x] `scripts/check_docs_status.ps1`
- [x] `git diff --check`
- [x] 正式发布文档为中文 UTF-8，无已知乱码。
- [x] 发布文档未包含账户、密码、用户目录或敏感配置值。

## 发布清单边界

- [x] GitHub Release 仅建议附加已验收 Zip和可选 SHA256 文本。
- [x] `.tmp_acceptance/`、`.manual-test/`、`build/`、Godot 缓存和用户配置不进入提交或 Release 附件。
- [x] 验收截图和日志保留为本地证据，不加入正式发布包。
- [x] 正式 Zip 内不包含验证脚本、测试后门或用户配置。
- [x] `doc/releases/v0.6/` 是版本文档，`releases/v0.6/` 是发布产物，职责不混用。

## 已知限制

- [x] 真实 Windows 登录后的开机自启明确标记为“暂不验证”，未写成通过。
- [x] 已在发布说明中披露：自动检查不等于真实登录启动验证。
- [x] 该能力默认关闭，当前不构成 Beta 发布阻塞项，并列入发布后 24 小时观察。
- [x] Zip 内 README 与发布说明是候选包生成时的“待验收”快照；因本轮禁止重新打包而保留，外部发布说明和当前版本文档为最终口径。

## 回滚准备

- [x] 保留 v0.5 Beta 上一稳定发布包。
- [x] 发布前建议备份 `%APPDATA%\LetsMakeMoney\config.json`。
- [x] 明确回退时先退出 v0.6，再恢复配置备份并启动 v0.5。
- [x] 明确崩溃、配置污染、托盘无法找回或核心收入计算错误为回滚触发条件。

## 发布动作

- [x] 创建有边界的 v0.6 发布提交。
- [x] 推送 `main`。
- [x] 创建 Beta tag `v0.6-beta`。
- [x] 推送 tag。
- [x] 创建 GitHub Pre-release 并上传已验收 Zip。

发布后进入 24 小时观察；真实 Windows 登录后的开机自启继续保持“暂不验证”。
