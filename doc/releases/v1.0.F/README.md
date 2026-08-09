# LetsMakeMoney Windows v1.0.F
> 内部代号：v1.0.F；版本号：v1.0.8 Stable；状态：开发实现完成，v1.0 系列已完成本地收官，annotated tag 已建立，远端发布尚未授权。

v1.0.8 是 v1.0 系列的收官质量版本。需求范围由 [PRD](prd.md) 和 [追踪矩阵](traceability.md) 冻结，开发实施由 [开发计划](dev_plan_v1.0.F.md) 与 [进度](progress_v1.0.F.md) 记录。

## 当前入口

- [验证记录](verification.md)
- [手动验收](manual-verification.md)
- [发布检查](release-checklist.md)
- [发布说明草案](release-notes.md)
- [支持矩阵](support-matrix.md)
- [冷启动 Spike](cold-start-spike.md)
- [脱敏证据索引](evidence/README.md)

## 身份边界

- 当前公开版本仍为 v1.0.7 Stable。
- 本地 v1.0 系列收官身份为 annotated tag `v1.0.8`，指向本次收官提交。
- 历史候选 `V10F-20260804-final-81abae36` 的 Zip SHA256 为 `07D9B1766CECE8DA092CE31C234E6018D4820049F3D2A310033478BF5EB69DDA`，只保留为验收历史，不代表本次收官提交的正式发布附件。
- 自动门禁、核心 GUI、Windows 11 单显示器 100%/125%/150% DPI 和托盘真实鼠标流程均已通过。
- 最终隐私竖条与日历布局修正已通过完整 current gate。
- 当前仅获授权创建本地 tag；不得推送 `main` 或 tag，也不得创建 GitHub Release。
- 如后续决定公开发布，必须从 tag 对应的干净提交重新构建候选、更新哈希并完成包体验证。

## 唯一自动验证入口

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_windows_current.ps1
```
