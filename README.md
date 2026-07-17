# LetsMakeMoney 赚钱模拟器

LetsMakeMoney 是一个 Godot 4.7 开发的 Windows 桌面宠物应用。它用一只橘猫陪伴用户工作，并根据月薪、休息模式、上下班时间实时计算“今天已经赚了多少钱”。

[English](README.en.md)

## 当前状态

当前发布版本为 **v0.7 Beta**。源码仓库、便携 Zip、许可与公开治理门禁已完成验收；未签名测试安装器不作为公开附件。最新事实源请先阅读 `doc/current.md` 和 `doc/releases/v0.7/current.md`。

`feature/v0.8-salary-schedule` 当前为 **v0.8 Beta 候选开发线**，新增按实际工作日计薪、午休扣除和大小周配置。它尚未完成最终 Acceptance，不应替代已发布的 v0.7 下载口径。

v0.6 以 v0.5 已发布基线为基础，已经完成：

- Windows x86_64 原生桥接能力
- 真系统托盘图标和托盘菜单
- 透明无边框桌宠窗口
- 透明空白区域点击穿透
- 点击关闭按钮隐藏到托盘
- 纯桌宠模式和可找回路径
- 橘猫 v2 默认素材和基础状态延伸动作
- 暖色金币小票 Panel、右键二级菜单、紧凑 Settings、首次启动向导
- Settings / Wizard 共享暖色控件体系
- 开机自启、配置持久化、窗口位置保存
- 统一版本事实源、可信验证脚本与轻量诊断能力
- 托盘、点击穿透、纯桌宠与配置恢复等高信任路径
- 有证据约束的 Panel、小猫、菜单、Settings 与 Wizard 精修

v0.6 最终验收结论为“通过”。v0.7 的真实通知区左键、普通/纯桌宠任务栏策略和 100%-200% DPI 已通过 Windows 桌面验收；多显示器、干净 Windows 用户/VM、Authenticode/SmartScreen 和真实登录后的开机自启明确暂不验证，不得写为通过。未签名测试安装器不作为公开 Release 附件。

## 环境要求

- Windows x86_64
- Godot 4.7 stable
- PowerShell
- MSYS2 UCRT64（仅 native bridge 本地构建需要）

## 下载与安装

- **便携 Zip**：从 [GitHub Releases](https://github.com/NzyZzz1998/LetsMakeMoney/releases) 下载已发布的 Windows x86_64 Zip，解压到独立目录后运行。升级前退出应用并备份 `%APPDATA%\LetsMakeMoney\config.json`。
- **安装版**：v0.7 未公开安装器。现有测试安装器未通过 Authenticode 签名，因此不作为 Release 附件；当前请使用便携 Zip。
- 安装版与便携版共享 `%APPDATA%\LetsMakeMoney`，请勿同时运行。Beta 不静默更新，检查、下载和安装都由用户确认。

设置 Godot 可执行文件：

```powershell
$env:LMM_GODOT_EXE = "<Godot 4.7 console executable>"
```

## 运行项目

用 Godot 打开项目目录：

```powershell
& $env:LMM_GODOT_EXE --path (Resolve-Path .).Path
```

配置文件路径：

```text
%APPDATA%\LetsMakeMoney\config.json
```

调试日志路径：

```text
%APPDATA%\LetsMakeMoney\debug.log
```

## 构建与验证

构建 Windows native DLL：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_native_dependencies.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -ValidateOnly
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -Target template_debug
```

固定依赖、离线缓存、Release 构建和故障处理见 [Windows native 构建说明](native/windows/README.md)。

运行 v0.7 自动验证：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v07.ps1
```

运行公开文档/合规与主验证套件：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_verification.ps1 -Suite docs
powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_verification.ps1 -Suite main
```

运行历史回归验证：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v04.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_m4.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_m5.ps1
```

生成或刷新 v0.7 便携候选包：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_v07.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v07_package.ps1
```

在 v0.8 候选分支运行完整回归并生成便携候选包：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v08.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\package_v08.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v08_package.ps1
```

发布或手动复制时，`LetsMakeMoney.exe` 和 `letsmakemoney_native.dll` 必须放在同一目录。

## 许可与贡献

- 项目原创代码、构建脚本、纯文本配置和代码文档采用 [MIT License](LICENSE)。
- 橘猫、占位猫、动画帧、Logo 和应用图标不适用 MIT，采用 [视觉素材受限许可](ASSETS_LICENSE.md)，详细范围见 [视觉资产清单](ASSETS_MANIFEST.md)。
- 第三方依赖保留各自许可；见 [第三方声明](THIRD_PARTY_NOTICES.md)。v0.7 的许可、历史、隐私与资产公开门禁已经通过；B-E 工程与分发能力仍在持续建设。
- v0.7 接受代码、文档、UI 设计说明和 native 贡献，暂不接受外部素材文件。参见 [CONTRIBUTING.md](CONTRIBUTING.md)。
- 行为规范见 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)，安全问题请按 [SECURITY.md](SECURITY.md) 私下报告。
- 未经书面许可，不得提取项目视觉素材用于其他项目，也不得分发包含受限素材的非官方二进制。

## 文档入口

- 当前入口: `doc\current.md`
- v0.7 当前状态: `doc\releases\v0.7\current.md`
- v0.7 PRD 与进度: `doc\releases\v0.7\prd.md` / `doc\releases\v0.7\progress_v0.7.md`
- 当前脚本入口与兼容分层: `scripts\README.md`
- v0.6 文档索引: `doc\releases\v0.6\README.md`
- v0.6 PRD: `doc\releases\v0.6\prd.md`
- v0.6 实施计划: `doc\releases\v0.6\dev_plan_v0.6.md`
- v0.6 进度: `doc\releases\v0.6\progress_v0.6.md`
- v0.6 验证文档: `doc\releases\v0.6\verification.md`
- v0.6 发布前检查: `doc\releases\v0.6\release-checklist.md`
- v0.6 发布说明: `doc\releases\v0.6\release-notes.md`
- 跨版本原始文档: `doc\LetsMakeMoneyPRD.md` / `doc\implementation-plan.md` / `doc\progress.md`
- 历史验证文档: `doc\verification\v0.1.md` / `doc\verification\v0.2.md` / `doc\verification\v0.3.md`
- 更新日志: `releases\CHANGELOG.md`
- v0.3 发布说明: `releases\v0.3-beta-notes.md`
- v0.4 发布说明: `releases\v0.4-beta-notes.md`
- v0.5 发布说明（稳定基线）: `releases\v0.5-beta-notes.md`
- v0.6 发布说明: `releases\v0.6-beta-notes.md`

## 版本路线

| 版本 | 状态 | 重点 |
|------|------|------|
| v0.1 Beta | 已归档 | 调试窗口版产品雏形 |
| v0.2 Beta | 已发布 | 紧凑桌宠、橘猫、设置、自启、导出 |
| v0.3 Beta | 已发布 | 真托盘、透明窗口、点击穿透、关闭隐藏、纯桌宠门禁 |
| v0.4 Beta | 已收口 | 动画、交互、窗口、Panel、Settings/Wizard、托盘找回和发布包规范 |
| v0.5 Beta | 已发布基线 | Settings/Wizard 共享控件、托盘恢复、点击穿透保护、文档治理和发布包验证 |
| v0.6 Beta | 已发布（Pre-release） | 诊断与验证能力、边缘体验稳定、配置恢复和有限体验精修 |
