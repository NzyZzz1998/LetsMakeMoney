# LetsMakeMoney v0.4 Beta 发布前检查清单

**最后更新**: 2026-07-09  
**适用版本**: v0.4 Beta  
**当前状态**: `main` + `v0.4-beta` 已同步，处于 Beta 发布后补验收 / 收尾校准阶段

## 1. 文档状态

- [x] [status.md](status.md) 已更新到最新测试结论。
- [x] [verification.md](verification.md) 中当前验收结果已完成记录。
- [ ] [progress.md](progress.md) 中 v0.4 checklist 与验证结论一致。
- [ ] `releases/v0.4-beta-notes.md` 已同步最新 UI / Wizard / 托盘修复。
- [ ] 包内 `README.md` 和 `release-notes.md` 与实际产物一致。
- [ ] 如原始大文档仍需维护，已同步回写 `doc/progress.md` 和 `doc/verification/v0.4.md`。

## 2. 手动验证

- [ ] `V04-MAN-051` Wizard 欢迎页 / 确认页复测通过。
- [x] `V04-MAN-052` 已记录为 `V04-OPT-001` 后续优化项，不再作为 v0.4 当前修复项。
- [ ] `V04-MAN-061` 托盘左键隐藏 / 显示后纯桌宠模式人工最终确认通过。
- [ ] `V04-MAN-072` 长按反馈人工最终确认通过；单击、双击、拖拽、右键菜单已有日志和截图证据。
- [x] `V04-MAN-073` `debug.log` 稳定性检查完成。
- [ ] Settings、Panel、右键菜单、Wizard 基础路径无明显 UI 崩坏。

## 3. 自动验证

在 PowerShell 中从项目根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v04.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_m4.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_m5.ps1
```

- [x] v0.4 自动验证通过。
- [ ] M4 回归通过。
- [ ] M5 回归通过。

## 4. 打包与包验证

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_v04.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v04_package.ps1
```

- [x] 生成 `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64.zip`。
- [x] 展开目录内包含 `LetsMakeMoney.exe`。
- [x] 展开目录内包含 `letsmakemoney_native.dll`。
- [x] 展开目录内包含 `app_icon.ico`。
- [x] 展开目录内包含 `README.md`。
- [x] 展开目录内包含 `release-notes.md`。
- [x] 展开目录内包含 `manifest.json`。
- [x] 展开目录内包含 `checksums.txt`。
- [x] `manifest.json` 与实际文件一致。
- [x] `checksums.txt` 已重新生成。

## 5. Git / GitHub

- [x] 当前分支确认已为 `main`。
- [x] v0.4 Beta 已推送统一标签 `v0.4-beta`。
- [x] `test` 分支也已同步到 v0.4 Beta 提交。

## 6. 发布决策

当前已经完成 `main` / `v0.4-beta` 同步；后续发布关闭仍需满足：

- [ ] 手动验证全部通过。
- [ ] 自动验证全部通过。
- [ ] 发布包验证通过。
- [ ] 文档和 release notes 与实际产物一致。
- [ ] 当前已知问题已记录到 v0.5 或后续规划，不影响 v0.4 Beta 发布。
