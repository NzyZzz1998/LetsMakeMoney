<p align="center">
  <img src="assets/readme/hero.png" alt="LetsMakeMoney Windows v0.9 Beta：桌面宠物与实时收入进度" width="100%">
</p>

<p align="center">
  <a href="README.en.md">English</a>
  ·
  <a href="doc/releases/v0.9/README.md">v0.9 候选说明</a>
  ·
  <a href="https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.8-beta">下载稳定版 v0.8 Beta</a>
  ·
  <a href="CONTRIBUTING.md">参与贡献</a>
</p>

## 它是什么

LetsMakeMoney 是一款用 Godot 4.7 开发的 Windows 桌面宠物应用。你提供月薪与工作安排，它会在桌面持续估算今日已赚、工作进度与下班时间；桌宠则根据工作、清醒休息和睡眠状态陪伴你。

项目只在本地保存配置与日志，不需要账户，也不会静默更新。

| 收入进度 | 桌面陪伴 | Windows 原生体验 | 本地可控 |
|---|---|---|---|
| 按实际工作日、午休和作息估算今日收入 | Classic 与多多状态随工作节律变化 | 托盘、透明窗口、点击穿透、纯桌宠模式 | 配置、日志和更新确认均由用户掌控 |

## v0.9 Beta 候选

这个分支记录 **Windows v0.9 Beta 冻结候选**。它完成了计薪、配置流程、窗口界面和宠物运行时的大范围重构，但独立验收结论是 **部分通过**，因此没有创建 v0.9 GitHub Release，也不作为当前稳定版本分发。

| 事实 | 当前口径 |
|---|---|
| 开发线 | `test` / Windows v0.9 Beta |
| 状态 | 部分通过，已冻结归档 |
| 公开下载 | 暂无 v0.9 Release |
| 当前稳定版 | [v0.8 Beta](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.8-beta) |
| 稳定回退 | v0.8 Beta |

完整事实见 [v0.9 版本入口](doc/releases/v0.9/README.md)、[验证记录](doc/releases/v0.9/verification.md) 与 [人工验收边界](doc/releases/v0.9/manual-verification.md)。

## v0.9 做了什么

- **统一工资与作息口径**：支持单休、双休、大小周、每日 8 小时、午休、节假日和调休。
- **重做配置链路**：Wizard 与 Settings 共用配置草稿、默认推算、校验、保存和失败恢复。
- **重组桌面信息**：调整收入 Panel，并加入单实例今日详情窗口、位置记忆和安全回落。
- **升级宠物运行时**：建立通用宠物包校验与损坏回退合同，保留 Classic 稳定链路并接入多多。
- **改进交互状态**：引入事件驱动动画、状态感知单击、长按拖动和动态命中区。
- **保护 Windows 特色**：继续支持托盘找回、透明窗口、点击穿透、右键菜单和纯桌宠模式。

## 验证边界

已通过自动回归、候选包启动、100% DPI 主要窗口复验，以及 Classic、多多、Panel、今日详情和模态点击穿透的定向检查。

以下项目**没有被写成通过**：

- 真实 Windows 125% 与 150% DPI 全窗口复验。
- Windows 通知区真实鼠标左键显隐与任务栏入口。
- 500ms 长按进入方向跑动及释放收势。
- Classic 与多多全部状态和事件动作的完整视觉质量。
- 损坏宠物包在真实桌面上的回退观感。
- 连续两小时 GUI 稳定运行。

因此 v0.9 适合作为可追溯的开发与产品基线，不适合作为面向普通用户的稳定下载。

## 如何体验

### 稳定使用

1. 从 [v0.8 Beta GitHub Release](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.8-beta) 下载 **Windows x86_64** 便携 Zip。
2. 解压到独立目录。
3. 运行 `LetsMakeMoney.exe`，按首次配置向导填写月薪与工作安排。
4. 右键桌宠可打开今日详情、设置和重新配置；关闭主窗口后可从系统托盘找回。

### 审阅 v0.9

v0.9 没有公开二进制 Release。开发者可检出 `test` 分支后从源码运行，并以 [v0.9 验证文档](doc/releases/v0.9/verification.md) 为准，不要把本地 `build/` 或旧 Zip 当作锁定候选。

> Windows 可能提示未知发布者。当前公开 EXE 未进行 Authenticode 签名。请只从本仓库 GitHub Releases 下载稳定包，并核对 Release 提供的 SHA-256。

配置与日志位于：

```text
%APPDATA%\LetsMakeMoney\config.json
%APPDATA%\LetsMakeMoney\debug.log
```

升级前请退出应用并备份 `config.json`。便携版与测试安装版共享上述数据目录，不应同时运行。

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

# v0.9 聚合验证
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v09.ps1

# v0.9 候选打包与包体验证
powershell -ExecutionPolicy Bypass -File .\scripts\package_v09.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v09_package.ps1

# 稳定回退基线仍由 v0.8 验证保护
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v08.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\package_v08.ps1
```

脚本分层与维护边界见 [scripts/README.md](scripts/README.md)。自动测试用于守住合同，托盘、任务栏、DPI 和点击穿透等 Windows 行为仍需要真实桌面验收。

## 版本脉络

- **v0.6 Beta**：共享控件、诊断与 Windows 边缘链路收敛。
- **v0.7 Beta**：开源治理、可复现构建和便携发布基线。
- **v0.8 Beta**：工资日历、午休和作息计算的当前公开稳定版。
- **v0.9 Beta**：界面、配置与宠物运行时重塑的冻结候选。

## 参与项目

欢迎代码、文档、测试、UI 说明和 Windows native integration 贡献。提交前请阅读：

- [贡献指南](CONTRIBUTING.md)
- [行为准则](CODE_OF_CONDUCT.md)
- [安全策略](SECURITY.md)
- [当前项目状态](doc/current.md)

安全漏洞请按 `SECURITY.md` 私下报告，不要公开提交包含敏感信息的 Issue。

## 许可

- 项目原创代码、构建脚本、纯文本配置和代码文档采用 [MIT License](LICENSE)。
- 猫咪、动画帧、Logo 和应用图标不适用 MIT，采用 [视觉素材受限许可](ASSETS_LICENSE.md)；详见 [视觉资产清单](ASSETS_MANIFEST.md)。
- 第三方依赖保留各自许可；详见 [第三方声明](THIRD_PARTY_NOTICES.md) 与 `LICENSES/`。

未经书面许可，不得提取受限视觉素材用于其他项目，也不得分发包含这些素材的非官方二进制。
