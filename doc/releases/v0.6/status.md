# LetsMakeMoney v0.6 Beta 当前状态

**最后更新**：2026-07-11
**当前分支**：`main`
**验收 HEAD**：`77cef5cf3f8dc39e695f12d03e12598aa7260fee`
**当前阶段**：v0.6 Beta 已发布，进入发布后观察
**当前结论**：最终验收通过，无发布阻塞项；tag 为 `v0.6-beta`，发布类型为 Pre-release

## 版本目标

增强日志、验证、轻量诊断、事务恢复、托盘验收和有证据的桌宠体验，不扩展新的产品方向。

## 当前进度

- PRD、Review、原型、开发承接与 V06-M0 至 V06-M6 已完成。
- V06-M6-014 和 V06-ACC-001 已通过真实发布包验收。
- 候选包：`releases/v0.6/LetsMakeMoney-v0.6-beta-windows-x86_64.zip`。
- Zip SHA256：`CECD3C3ABACFCB5EF594584E2AEB0E25C1824BAE97AB84B224073E7444E72615`。
- 发布阻塞项：无。
- 发布提交、`main` 推送、`v0.6-beta` tag 和 GitHub Pre-release 已完成。

## 已知限制

- 真实 Windows 登录后的开机自启暂不验证，不得写为通过。
- 自动验证只证明注册表命令格式、启停事务和失败补偿，不证明真实登录后一定启动。
- 该能力默认关闭，不影响手动启动、桌宠主流程、配置安全与托盘找回，因此不阻塞本次 Beta；发布后 24 小时重点观察。
- Zip 内 README 与发布说明保留候选包生成时的“待验收”快照；当前事实以本目录和仓库外部发布说明为准。

## 当前入口

- 范围：`prd.md`
- 实施：`dev_plan_v0.6.md`
- 状态：`progress_v0.6.md`
- 验证：`verification.md`
- 发布说明：`release-notes.md`
- 发布清单：`release-checklist.md`
