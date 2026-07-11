# LetsMakeMoney v0.7 Beta 状态

**最后更新**：2026-07-11
**状态**：最终候选 Acceptance 部分通过；存在发布阻塞
**当前里程碑**：A-D 与主要 E 项已完成；剩余真实 Windows、签名和干净环境补证
**发布状态**：仓库公开；`V07-BUG-001` 阻塞发布；安装器未签名；未 tag

## 当前结论

- v0.6 Beta 已通过 `v0.6-beta` tag 发布，是当前回归基线。
- v0.7 PRD、原型、开发承接和主要实现已完成；当前远端 `main` 仍不是已发布 v0.7。
- 便携 Zip 已通过自动包验证；测试安装器未签名，仅供 Acceptance，不得公开分发。
- A0 已定义候选与排除边界；A1 已完成双许可和资产签核；A2 已完成第三方清单、原文和 Release 许可结构。A3 已完成完整历史审计、远端重写和 fresh clone 复验，P0 为 0。

## 当前门禁

| 门禁 | 状态 | 责任模块 |
|---|---|---|
| 当前事实与候选边界 | 已完成 | V07-A0 |
| MIT 与受限素材许可 | 已完成 | V07-A1 |
| 第三方与 Release 合规 | 已完成基础结构；实际 v0.7 包待后续门禁 | V07-A2 / B1 / C1 |
| 完整历史、隐私与资产审计 | 已完成：12/12；方案 3 已签核 | V07-A3 |
| 固定依赖与可复现 native 构建 | 已完成 | V07-B1 |
| CI、Main/native、安装器、更新 | 主要实现完成；真实 GUI/签名待验收 | V07-B2-B5 / C |
| 双语文档、贡献治理 | 主要文件完成；英文与网页设置待人工复核 | V07-E1-E3 |
| 独立 Acceptance | 未开始 | V07-E4 / ACC |

## 证据入口

- `doc/current.md`
- `doc/releases/v0.7/public-candidate-manifest.md`
- `doc/releases/v0.7/public-exclusions.md`
- `doc/releases/v0.7/public-readiness.md`
- `doc/releases/v0.7/verification.md`
- `doc/logs/dev_log_v0.7.md`
