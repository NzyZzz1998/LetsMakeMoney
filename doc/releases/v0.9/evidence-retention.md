# v0.9 本地验收证据保留策略

**状态**：冻结版本的本地证据索引
**最后更新**：2026-07-23

## 1. 证据边界

v0.9 的正式结论以以下文档和锁定产物身份为准：

- `verification.md`：自动验证、Computer Use、缺陷关闭和最终“部分通过”结论。
- `manual-verification.md`：人工操作边界和暂不验证项。
- `release-checklist.md`：冻结收口门禁。
- `doc/logs/v0.9-bugfix-log.md`：缺陷证据与关闭事实。
- 候选 Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`。
- 候选 Zip SHA256：`65A04A1BAFF6681FF335DD2966A528E6BD6517A81232BC107EFAF5AF42C9F685`。

`.tmp_acceptance/` 是被 `.gitignore` 排除的本地证据目录，不属于源码仓库、公开 Release 或长期事实源。

## 2. 保留内容

本地继续保留：

- `evidence/` 中的截图、日志、配置差异和身份记录。
- `appdata/` 中用于交互逐帧、稳定性和日志语义证明的文件。
- `backup/`、`user-backup/`、`appdata-backup/` 中仍可用于确认测试前后恢复结果的小型快照。
- 根级 `identity.json`、探针脚本和其他无法由候选 Zip直接重建的记录。

这些内容用于解释 `verification.md` 和 bugfix log 中的本地路径。它们不是公开承诺；迁移电脑或删除本地证据后，文档中的验收结论仍以记录的哈希、日志摘要和最终判定为准。

## 3. 可删除内容

以下目录只是锁定候选 Zip 的重复运行副本，可以由发布包重新解压：

- `extract/`
- `extracted/`
- `unpacked/`
- `package/`

2026-07-23 审计发现 9 份此类运行副本，约 1.04 GiB。它们不包含唯一验收结论，删除后不改变候选 Zip、EXE、Native DLL 的既有 SHA256，也不改变 v0.9 的“部分通过、冻结归档”结论。

## 4. 清理入口

默认仅预览：

```powershell
.\scripts\cleanup_local_generated.ps1 -AcceptanceRuntimeCopies
```

确认后执行：

```powershell
.\scripts\cleanup_local_generated.ps1 -AcceptanceRuntimeCopies -Apply
```

脚本只匹配各验收批次直属的 `extract/`、`extracted/`、`unpacked/` 和 `package/`，不会删除 `evidence/`、`appdata/` 或整个 `.tmp_acceptance/`。
