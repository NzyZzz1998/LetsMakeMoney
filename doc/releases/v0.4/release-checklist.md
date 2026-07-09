# LetsMakeMoney v0.4 Beta 发布前检查清单

**最后更新**: 2026-07-09  
**适用版本**: v0.4 Beta  
**当前状态**: 测试态，尚未合并 `main`，尚未打 tag

## 1. 文档状态

- [ ] [status.md](status.md) 已更新到最新测试结论。
- [ ] [verification.md](verification.md) 中所有待复测项已完成记录。
- [ ] [progress.md](progress.md) 中 v0.4 checklist 与验证结论一致。
- [ ] `releases/v0.4-beta-notes.md` 已同步最新 UI / Wizard / 托盘修复。
- [ ] 包内 `README.md` 和 `release-notes.md` 与实际产物一致。
- [ ] 如原始大文档仍需维护，已同步回写 `doc/progress.md` 和 `doc/verification/v0.4.md`。

## 2. 手动验证

- [ ] `V04-MAN-051` Wizard 欢迎页 / 确认页复测通过。
- [x] `V04-MAN-052` 已记录为 `V04-OPT-001` 后续优化项，不再作为 v0.4 当前修复项。
- [ ] `V04-MAN-061` 托盘左键隐藏 / 显示后纯桌宠模式复测通过。
- [ ] `V04-MAN-072` 连续单击、双击、右键各 5 次完成。
- [ ] `V04-MAN-073` `debug.log` 稳定性检查完成。
- [ ] Settings、Panel、右键菜单、Wizard 基础路径无明显 UI 崩坏。

## 3. 自动验证

在 PowerShell 中从项目根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v04.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_m4.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_m5.ps1
```

- [ ] v0.4 自动验证通过。
- [ ] M4 回归通过。
- [ ] M5 回归通过。

## 4. 打包与包验证

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_v04.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v04_package.ps1
```

- [ ] 生成 `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64.zip`。
- [ ] 展开目录内包含 `LetsMakeMoney.exe`。
- [ ] 展开目录内包含 `letsmakemoney_native.dll`。
- [ ] 展开目录内包含 `app_icon.ico`。
- [ ] 展开目录内包含 `README.md`。
- [ ] 展开目录内包含 `release-notes.md`。
- [ ] 展开目录内包含 `manifest.json`。
- [ ] 展开目录内包含 `checksums.txt`。
- [ ] `manifest.json` 与实际文件一致。
- [ ] `checksums.txt` 已重新生成。

## 5. Git / GitHub

- [ ] 当前分支确认仍为 `test`。
- [ ] v0.4 未完全通过前不合并 `main`。
- [ ] v0.4 未完全通过前不推正式 tag。
- [ ] 若需要临时备份，推送 `test` 分支即可。

## 6. 发布决策

只有以下条件全部满足，才进入合并 / tag 讨论：

- [ ] 手动验证全部通过。
- [ ] 自动验证全部通过。
- [ ] 发布包验证通过。
- [ ] 文档和 release notes 与实际产物一致。
- [ ] 当前已知问题已记录到 v0.5 或后续规划，不影响 v0.4 Beta 发布。
