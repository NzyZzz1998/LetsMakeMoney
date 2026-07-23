# v0.9 本地验收证据保留策略

**状态**：冻结版本的本地证据索引
**最后更新**：2026-07-23

## 1. 证据边界

v0.9 的正式结论以以下文档和锁定产物身份为准：

- `verification.md`：自动验证、Computer Use、缺陷关闭和最终“通过 / 可进入发布收口”结论。
- `manual-verification.md`：人工操作边界和暂不验证项。
- `release-checklist.md`：冻结收口门禁。
- `doc/logs/v0.9-bugfix-log.md`：缺陷证据与关闭事实。
- 候选 Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`。
- 最终发布附件 Zip SHA256：`B10FDE2027D4ABC71C41F0F7AC7BDCE3D93AEB8AFAF4058BA1A592B6A75CC1EC`。
- 最终真实 GUI 验收 Zip SHA256：`DFADCFF7F1DB1F461D4241EFC9F86E286E7C533211785BA7E5C74072FE5144DF`；重打包后 EXE 与 Native DLL 身份未变化。

`.tmp_acceptance/` 是被 `.gitignore` 排除的本地证据目录，不属于源码仓库、公开 Release 或长期事实源。

最终文档快照重打包证据位于 `.tmp_acceptance/v0.9-doc-repack-20260723-205908/evidence/`；旧候选包备份位于 `.tmp_acceptance/v0.9-pre-repack-20260723-205612/`。

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

2026-07-23 审计发现 9 份此类运行副本，约 1.04 GiB。它们不包含唯一验收结论，删除后不改变候选 Zip、EXE、Native DLL 的既有 SHA256，也不改变 v0.9 的“通过 / 可进入发布收口”结论。

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
