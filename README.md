# LetsMakeMoney

[English](README.en.md) | [当前状态](doc/current.md) | [v1.0 文档](doc/releases/v1.0/README.md)

LetsMakeMoney 是一款 Windows 本地收入进度工具。填写月薪与工作安排后，它会在桌面迷你窗口中持续显示今日已赚、工作进度和距离下班时间，并提供今日详情、日历、设置与首次配置向导。

v1.0 使用 Rust、Tauri 与 React 重建，重点是清晰、克制、稳定的 Windows 桌面体验。配置与日志只保存在本机；应用不需要账号，也不会静默安装更新。

## v1.0 当前范围

- 无宠物的迷你收入视图，默认不占用任务栏。
- 今日与日历工作台，展示收入、进度、安排和工作日口径。
- 三步首次配置向导与四组任务化设置。
- 保存成功、无变化、失败保留输入、恢复默认和配置损坏恢复。
- 原生托盘隐藏、找回、设置和退出。
- 本地诊断摘要、数据目录和用户确认式更新检查。
- Windows x86_64 便携 Zip。

v1.0 不包含宠物、透明宠物窗口、点击穿透、纯桌宠模式、账号、云同步、主题系统或安装器。需要旧桌宠体验的用户可继续使用 [v0.9 Beta](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.9-beta)。

## 从源码运行

要求：

- Windows 10/11 x86_64
- Node.js 22+
- Rust stable MSVC toolchain
- Microsoft Edge WebView2 Runtime

```powershell
cd apps\windows-v1
npm install
npm run tauri dev
```

构建：

```powershell
cd apps\windows-v1
npm run build:web
npm run tauri build -- --no-bundle
```

## 验证

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m0.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m1.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m2.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m3.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m4.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m5.ps1 -SkipBuild
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m6.ps1
```

真实托盘、任务栏、DPI 和系统重启后的恢复行为仍需要 Windows 桌面验收，自动测试不能替代这些证据。

## 数据与回退

v1.0 数据目录：

```text
%APPDATA%\io.letsmakemoney.windows\
```

从 v0.9 首次迁移时会保留兼容备份。回退前请退出 v1.0，再按 [v0.9 回退指南](doc/releases/v1.0/v0.9-rollback.md) 恢复旧配置。

## 参与项目

欢迎代码、文档、测试和 Windows 体验贡献。提交前请阅读 [贡献指南](CONTRIBUTING.md)、[行为准则](CODE_OF_CONDUCT.md) 与 [安全策略](SECURITY.md)。

## 许可

项目原创代码与文档采用 [MIT License](LICENSE)。v1.0 当前发布包不包含宠物或其他受限视觉素材；v0.9 历史视觉资产仍按对应版本中的受限素材许可处理。第三方组件见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
