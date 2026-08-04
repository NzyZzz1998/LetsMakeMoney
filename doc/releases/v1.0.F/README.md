# LetsMakeMoney Windows v1.0.F
> 内部代号：v1.0.F；公开版本：v1.0.8 Stable；状态：开发实现完成，等待干净候选与独立验收。

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
- 当前工作区包含 v1.0.8 有意实现，但尚未形成干净发布提交。
- 当前 dirty 工作区不得生成正式候选；任何本地 release build 仅是开发证据。
- 正式候选必须通过 `scripts/package_v10f.ps1` 从干净提交生成，并由 `scripts/verify_v10f_package.ps1` 锁定源提交与哈希。

## 唯一自动验证入口

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_windows_current.ps1
```
