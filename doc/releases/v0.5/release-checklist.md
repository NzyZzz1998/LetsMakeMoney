# LetsMakeMoney v0.5 Beta 发布前检查清单

**最后更新**: 2026-07-09
**适用版本**: v0.5 Beta
**当前结论**: 未通过 / 发布阻塞

## 1. 文档状态

- [x] `doc/current.md` 指向 v0.5 当前状态。
- [x] `doc/releases/v0.5/README.md` 指向 v0.5 专属文档。
- [x] `doc/releases/v0.5/status.md` 记录当前阶段和阻塞项。
- [x] `doc/releases/v0.5/verification.md` 记录验收结果。
- [x] `doc/releases/v0.5/progress_v0.5.md` 只作为 PM 状态看板，不写 bugfix 流水账。
- [x] `doc/logs/v0.5-bugfix-log.md` 承接 bugfix / 技术排查记录。
- [x] `releases/v0.5-beta-notes.md` 已建立。

## 2. 自动验证

发布前应重新运行：

```powershell
.\scripts\verify_v05.ps1
.\scripts\verify_v04.ps1
.\scripts\verify_m4.ps1
.\scripts\verify_m5.ps1
.\scripts\check_docs_status.ps1
```

当前记录：上述命令已通过。

## 3. 手动验收

- [x] Settings 保存成功反馈。
- [x] Settings 无变化保存反馈。
- [x] Settings 保存失败反馈。
- [x] Wizard 步骤切换和完成日志。
- [x] Settings / Wizard 打开期间点击穿透保护。
- [ ] 纯桌宠模式托盘左键隐藏/恢复后，任务栏入口保持隐藏。

## 4. 打包与包验证

发布前应重新运行：

```powershell
.\scripts\package_v05.ps1
.\scripts\verify_v05_package.ps1
```

当前记录：脚本可生成并验证 `releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip`。

## 5. 发布产物

- [x] zip 包存在。
- [x] manifest 存在。
- [x] checksum 存在。
- [x] 包内 README / release notes 存在。
- [ ] 最终发布签核通过。

## 6. 发布决策

v0.5 Beta 发布前必须满足：

1. 纯桌宠模式下，左键托盘图标可隐藏/恢复桌宠。
2. 纯桌宠模式恢复后不出现任务栏入口。
3. `debug.log` 能看到托盘切换、窗口策略重应用、纯桌宠策略重应用相关事件。
4. `verification.md` 将该路径记录为通过。

Release decision: **未通过 / 发布阻塞**。
