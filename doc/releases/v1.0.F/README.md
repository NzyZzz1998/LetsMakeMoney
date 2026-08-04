# LetsMakeMoney Windows v1.0.F
> 内部代号：v1.0.F；公开版本：v1.0.8 Stable；状态：开发实现完成，本地候选与 GUI 验收完成，等待托盘人工补证和发布授权。

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
- 本地发布源为 `main@81abae364ad577a394c3c9dcda3a1d1c15e83b99`。
- 唯一候选为 `V10F-20260804-final-81abae36`，Zip SHA256 为 `07D9B1766CECE8DA092CE31C234E6018D4820049F3D2A310033478BF5EB69DDA`。
- 自动门禁、核心 GUI 和 Windows 11 单显示器 100%/125%/150% DPI 已通过；托盘真实鼠标流程待人工补证。
- 当前没有发布授权，不得自动执行 push、tag 或 GitHub Release。

## 唯一自动验证入口

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_windows_current.ps1
```
