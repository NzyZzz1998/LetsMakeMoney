# LetsMakeMoney Windows v1.0.7

> 状态：已发布。

v1.0.7 是 v1.0 系列的收官功能版本，范围由 [PRD](prd.md) 和 [追踪矩阵](traceability.md) 冻结。M0-M7、独立验收、真实 Windows 100%/125%/150% DPI、最终干净候选和 GitHub 下载包复核均已完成。

## 当前入口

- [开发计划](dev_plan_v1.0.7.md)
- [进度](progress_v1.0.7.md)
- [验证记录](verification.md)
- [手动验收](manual-verification.md)
- [发布检查](release-checklist.md)
- [发布说明](release-notes.md)
- [支持矩阵](support-matrix.md)

## 身份边界

- 当前公开版本为 v1.0.7 Stable。
- 发布源提交为 `f500ed4e7de28ec68b2a848da6fa2340420b91b2`，tag 为 `v1.0.7`。
- 正式便携 Zip SHA256 为 `D656B96973F64632896715ADCBB9CAFEAED4D06D44BA1C098824335AC673E3F2`。
- 发布入口：[GitHub Release v1.0.7](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.7)。
- 脏工作树构建只能用于开发验收，必须记录 `source_tree_dirty=true`，不得作为 Release 附件。
- 正式候选已从干净提交构建并锁定全部哈希；发布后文档更新不改变 tag 指向和附件身份。

## 唯一验证入口

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_windows_current.ps1
```

候选包生成后，再使用 `scripts\verify_v107.ps1 -Milestone M7 -CandidatePath <Zip>` 复核包体与源码身份。
