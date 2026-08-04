# LetsMakeMoney Windows v1.0.7

> 状态：验收通过，项目所有者已批准发布收口；尚待干净发布身份。

v1.0.7 是 v1.0 系列的收官功能版本，范围由 [PRD](prd.md) 和 [追踪矩阵](traceability.md) 冻结。当前 M0-M6 已完成，真实 Windows 100%/125%/150% DPI 与独立验收均已通过；项目所有者已批准提交、推送、tag 和 GitHub Release，M7 仍需完成干净发布提交与最终候选身份。

## 当前入口

- [开发计划](dev_plan_v1.0.7.md)
- [进度](progress_v1.0.7.md)
- [验证记录](verification.md)
- [手动验收](manual-verification.md)
- [发布检查](release-checklist.md)
- [发布说明](release-notes.md)
- [支持矩阵](support-matrix.md)

## 身份边界

- 当前公开版本仍为 v1.0.6 Stable。
- 当前开发基线为 `main@12b6b03ce91b716d49590e21eb8dd7fe90fa283c`，工作树包含尚未提交的 v1.0.7 有意变更。
- 脏工作树构建只能用于开发验收，必须记录 `source_tree_dirty=true`，不得作为 Release 附件。
- 正式候选必须从项目所有者批准后的干净提交重新构建，并重新锁定全部哈希。

## 唯一验证入口

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_windows_current.ps1
```

候选包生成后，再使用 `scripts\verify_v107.ps1 -Milestone M7 -CandidatePath <Zip>` 复核包体与源码身份。
