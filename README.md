# LetsMakeMoney 赚钱模拟器

LetsMakeMoney 是一个 Godot 4.7 开发的 Windows 桌面宠物应用。它用一只橘猫陪伴用户工作，并根据月薪、休息模式、上下班时间实时计算“今天已经赚了多少钱”。

## 当前状态

当前开发版本为 **v0.4 Beta 测试态**，当前分支为 `test`，尚未合并 `main`，尚未打 v0.4 tag。最新事实源请先阅读 `doc\current.md`。

v0.4 当前已形成测试实现：

- Windows x86_64 native bridge
- 真系统托盘图标和托盘菜单
- 透明无边框桌宠窗口
- 透明空白区域点击穿透
- 点击关闭按钮隐藏到托盘
- 可找回优先的纯桌宠模式门禁
- 橘猫 v2 默认素材和基础状态延伸动作
- 暖色金币小票 Panel、右键二级菜单、紧凑 Settings、首次启动向导
- 开机自启、配置持久化、窗口位置保存
- v0.4 自动验证、打包脚本、发布包 manifest/checksum 和手动验证文档

v0.4 仍有手动复测项，不能视为正式发布完成。当前待验证内容以 `doc\releases\v0.4\verification.md` 为准。

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

运行 v0.4 自动验证：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v04.ps1
```

运行设置 / 向导回归验证：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_m4.ps1
```

运行导出包烟测：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_m5.ps1
```

打包 v0.4 Beta 测试包：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_v04.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v04_package.ps1
```

发布或手动复制时，`LetsMakeMoney.exe` 和 `letsmakemoney_native.dll` 必须放在同一目录。

## 文档入口

- 当前入口: `doc\current.md`
- v0.4 文档索引: `doc\releases\v0.4\README.md`
- v0.4 PRD: `doc\releases\v0.4\prd.md`
- v0.4 实施计划: `doc\releases\v0.4\implementation-plan.md`
- v0.4 进度: `doc\releases\v0.4\progress.md`
- v0.4 验证文档: `doc\releases\v0.4\verification.md`
- v0.4 发布前检查: `doc\releases\v0.4\release-checklist.md`
- 跨版本原始文档: `doc\LetsMakeMoneyPRD.md` / `doc\implementation-plan.md` / `doc\progress.md`
- 历史验证文档: `doc\verification\v0.1.md` / `doc\verification\v0.2.md` / `doc\verification\v0.3.md`
- 更新日志: `releases\CHANGELOG.md`
- v0.3 发布说明: `releases\v0.3-beta-notes.md`
- v0.4 发布说明草案: `releases\v0.4-beta-notes.md`

## 版本路线

| 版本 | 状态 | 重点 |
|------|------|------|
| v0.1 Beta | 已归档 | 调试窗口版产品雏形 |
| v0.2 Beta | 已发布 | 紧凑桌宠、橘猫、设置、自启、导出 |
| v0.3 Beta | 已发布 | 真托盘、透明窗口、点击穿透、关闭隐藏、纯桌宠门禁 |
| v0.4 Beta | 测试态 | 动画、交互、窗口、Panel、Settings/Wizard、托盘找回和发布包规范 |
