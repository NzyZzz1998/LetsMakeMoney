<p align="center">
  <img src="assets/readme/hero.png" alt="LetsMakeMoney：橘猫陪伴的 Windows 实时收入进度桌面挂件" width="100%">
</p>

<p align="center">
  <a href="README.en.md">English</a>
  ·
  <a href="https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.8-beta">下载 v0.8 Beta</a>
  ·
  <a href="CONTRIBUTING.md">参与贡献</a>
</p>

## 它是什么

LetsMakeMoney 是一款用 Godot 4.7 开发的 Windows 桌面宠物应用。你提供月薪与工作安排，它会在桌面持续估算今日已赚、工作进度与下班时间；一只橘猫负责陪你把这一天过完。

项目只在本地保存配置与日志，不需要账户，也不会静默更新。

| 收入进度 | 桌面陪伴 | Windows 原生体验 | 本地可控 |
|---|---|---|---|
| 按实际工作日、午休和作息估算今日收入 | 橘猫状态随工作与休息变化 | 托盘、透明窗口、点击穿透、纯桌宠模式 | 配置、日志和更新确认均由用户掌控 |

## 当前版本

当前公开版本是 **v0.8 Beta**，仅支持 **Windows x86_64**，通过 GitHub Release 提供便携 Zip。

- 新增按当月实际工作日计薪、午休扣除，以及单休、双休、大小周配置。
- 保留桌宠、收入 Panel、首次配置、Settings、托盘找回和纯桌宠模式。
- 已完成自动回归与真实 Windows 桌面验收。
- 多显示器、干净 Windows 用户/VM、Authenticode/SmartScreen 和真实登录后的开机自启仍是明确的 Beta 未验证边界。
- v0.9 是冻结的开发候选，不是当前稳定发布版本；其完成范围与未验证边界见 [v0.9 版本入口](doc/releases/v0.9/README.md)。

完整事实见 [当前状态](doc/current.md)、[v0.8 验证记录](doc/releases/v0.8/verification.md) 与 [v0.8 发布说明](doc/releases/v0.8/release-notes.md)。

## 快速开始

1. 从 [v0.8 Beta Release](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.8-beta) 下载 Windows x86_64 便携 Zip。
2. 解压到独立目录。
3. 运行 `LetsMakeMoney.exe`，按首次配置向导填写月薪与工作安排。
4. 右键桌宠可打开今日详情、设置和重新配置；关闭主窗口后可从系统托盘找回。

> Windows 可能提示未知发布者。v0.8 没有公开安装器，当前 EXE 未进行 Authenticode 签名。请只从本仓库 Release 下载，并核对 Release 中提供的 SHA-256。

配置与日志位于：

```text
%APPDATA%\LetsMakeMoney\config.json
%APPDATA%\LetsMakeMoney\debug.log
```

升级前请退出应用并备份 `config.json`。便携版与测试安装版共享上述数据目录，不应同时运行。

## 主要体验

- **实时收入小票**：展示今日已赚、时薪、工作进度和今日安排。
- **桌面橘猫**：透明无边框窗口，支持拖拽、右键菜单和基础互动。
- **点击穿透**：透明区域不阻挡桌面；菜单、Settings 与 Wizard 打开时自动保护交互。
- **纯桌宠模式**：隐藏任务栏入口，同时保留托盘找回路径。
- **作息配置**：支持午休、单休、双休和大小周，并安全迁移旧配置。
- **本地诊断**：日志轮换、配置损坏恢复和脱敏诊断摘要帮助定位问题。

## 从源码运行

要求：

- Windows x86_64
- Godot 4.7 stable
- PowerShell
- MSYS2 UCRT64、Python 3.12 与 SCons 4.10.1（仅 native bridge 本地构建需要）

```powershell
$env:LMM_GODOT_EXE = "<Godot 4.7 console executable>"
& $env:LMM_GODOT_EXE --path (Resolve-Path .).Path
```

构建 Windows native bridge：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_native_dependencies.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -ValidateOnly
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -Target template_debug
```

固定依赖、离线缓存与故障处理见 [Windows native 构建说明](native/windows/README.md)。

## 验证

```powershell
# 文档与公开合规
powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_verification.ps1 -Suite docs

# 当前主验证套件
powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_verification.ps1 -Suite main

# v0.8 发布回归
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v08.ps1

# v0.8 便携包与包体验证
powershell -ExecutionPolicy Bypass -File .\scripts\package_v08.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v08_package.ps1
```

脚本分层与维护边界见 [scripts/README.md](scripts/README.md)。自动测试用于守住合同，托盘、任务栏、DPI 和点击穿透等 Windows 行为仍需要真实桌面验收。

## 参与项目

欢迎代码、文档、测试、UI 说明和 Windows native integration 贡献。提交前请阅读：

- [贡献指南](CONTRIBUTING.md)
- [行为准则](CODE_OF_CONDUCT.md)
- [安全策略](SECURITY.md)
- [当前项目状态](doc/current.md)

安全漏洞请按 `SECURITY.md` 私下报告，不要公开提交包含敏感信息的 Issue。

## 许可

- 项目原创代码、构建脚本、纯文本配置和代码文档采用 [MIT License](LICENSE)。
- 橘猫、占位猫、动画帧、Logo 和应用图标不适用 MIT，采用 [视觉素材受限许可](ASSETS_LICENSE.md)；详见 [视觉资产清单](ASSETS_MANIFEST.md)。
- 第三方依赖保留各自许可；详见 [第三方声明](THIRD_PARTY_NOTICES.md) 与 `LICENSES/`。

未经书面许可，不得提取受限视觉素材用于其他项目，也不得分发包含这些素材的非官方二进制。
