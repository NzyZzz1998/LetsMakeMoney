# Godot 4.7 路线样板

本目录验证现有 Godot 技术栈在无宠物 v1.0 结构下的视觉与 Windows 生命周期上限。

覆盖：

- 344×120 迷你收入视图；
- 820×620 今日工作台；
- 720×540 Settings 代表页；
- 保存成功、无变化和失败且输入保留；
- 内置 `StatusIndicator` 托盘隐藏与找回；
- Windows 便携 EXE 导出。

运行：

```powershell
.\build.ps1
.\build\LMM-v1.0-Godot-Spike.exe
```

本样板不引用 v0.9 业务代码、宠物代码、native DLL 或本机用户配置。
