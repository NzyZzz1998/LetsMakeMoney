# LetsMakeMoney 赚钱模拟器

LetsMakeMoney 是一个 Godot 4.7 开发的 Windows 桌面宠物应用。它用一只橘猫陪伴用户工作，并根据月薪、休息模式、上下班时间实时计算“今天已经赚了多少钱”。

## 当前状态

当前主线版本为 **v0.3 Beta**，发布 tag 为 `v0.3beta`，定位是“桌宠原生能力修复版”。

v0.3 已完成：

- Windows x86_64 native bridge
- 真系统托盘图标和托盘菜单
- 透明无边框桌宠窗口
- 透明空白区域点击穿透
- 点击关闭按钮隐藏到托盘
- 可找回优先的纯桌宠模式门禁
- 橘猫素材接入和基础状态模型
- 薪资面板、设置窗口、首次启动向导
- 开机自启、配置持久化、窗口位置保存
- v0.2/v0.3 自动验证、导出烟测和手动验证文档

v0.4 Beta 将作为大型体验优化版本，重点打磨橘猫动画、交互手感、窗口/点击穿透边界、Panel 展示、设置体验、性能稳定性和发布包规范。

## 环境要求

- Windows x86_64
- Godot 4.7 stable
- PowerShell
- MSYS2 UCRT64（仅 native bridge 本地构建需要）

本机 Godot 路径示例：

```powershell
$env:LMM_GODOT_EXE
```

## 运行项目

用 Godot 打开项目目录：

```powershell
& "$env:LMM_GODOT_EXE" --path "<PROJECT_ROOT>"
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
.\scripts\build_native_windows.ps1
```

运行 v0.3 自动验证：

```powershell
.\scripts\verify_v03.ps1
```

运行 v0.2 回归验证：

```powershell
.\scripts\verify_v02.ps1
```

运行导出包烟测：

```powershell
.\scripts\verify_v03_export.ps1
```

发布或手动复制 v0.3 时，`LetsMakeMoney.exe` 和 `letsmakemoney_native.dll` 必须放在同一目录。

## 文档入口

- PRD: `doc\LetsMakeMoneyPRD.md`
- 实施计划: `doc\implementation-plan.md`
- 总体进度: `doc\progress.md`
- 验证文档: `doc\verification\v0.1.md` / `doc\verification\v0.2.md` / `doc\verification\v0.3.md`
- 更新日志: `releases\CHANGELOG.md`
- v0.3 发布说明: `releases\v0.3-beta-notes.md`

## 版本路线

| 版本 | 状态 | 重点 |
|------|------|------|
| v0.1 Beta | 已归档 | 调试窗口版产品雏形 |
| v0.2 Beta | 已发布 | 紧凑桌宠、橘猫、设置、自启、导出 |
| v0.3 Beta | 已发布 | 真托盘、透明窗口、点击穿透、关闭隐藏、纯桌宠门禁 |
| v0.4 Beta | 规划中 | 动画、交互、窗口、Panel、设置体验和发布规范 |
