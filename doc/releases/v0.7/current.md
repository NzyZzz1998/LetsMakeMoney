# v0.7 Beta 已发布状态

**状态**：最终 Acceptance 通过，已发布 GitHub Pre-release

**发布 tag**：`v0.7-beta`

**发布提交**：`e79149d91e8e0adb3cbf1e53cd8819f072f7154f`

**发布日期**：2026-07-13

**支持平台**：Windows x86_64

## 发布对象

- 公开仓库：<https://github.com/NzyZzz1998/LetsMakeMoney>
- Release：<https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.7-beta>
- 便携 Zip：`LetsMakeMoney-v0.7-beta-windows-x86_64.zip`
- Zip SHA256：`16F47A844EFD78D387E9D08FBCD3DE76C8C8BDD518731C1B0BA022E7F598121F`
- 校验文件：`SHA256SUMS.txt`
- 未签名测试安装器未上传，不属于公开 Release。

## 已完成

- A0-A3：公开边界、MIT/受限素材许可、第三方合规、历史/隐私/资产审计。
- B-E：固定依赖与 native 构建、CI、Main/native 行为治理、安装/更新合同、双语文档、贡献与安全治理。
- `V07-ACC-001`：最终 Acceptance 通过。
- 真实通知区、普通/纯桌宠任务栏策略、DPI、配置安全、更新失败保护与安装/卸载测试链路已有证据。
- `Protect main` 与 Private Vulnerability Reporting 已启用。

## 已知边界

- 多显示器、干净 Windows 用户/VM、Authenticode/SmartScreen、真实登录后的开机自启暂不验证。
- 安装器没有 Authenticode 签名，因此未公开分发。
- v0.7 不实现 iOS、macOS、Android、主题系统或新增宠物；相关内容仅为规划。

## 证据入口

- [最终验证](verification.md)
- [人工验证](manual-verification.md)
- [发布检查](release-checklist.md)
- [发布说明](release-notes.md)
- [公开门禁](public-readiness.md)
- [进度快照](progress_v0.7.md)

v0.7 已冻结为发布事实；后续工程治理以 `doc/current.md` 和 `doc/releases/v0.8/` 为准。
