# C# + WinUI 3 路线样板

该样板使用原生 WinUI 3/XAML 实现统一黄金路径，使用 `AppWindow` 管理 DPI 感知窗口尺寸，并以隔离的 `NotifyIcon` 服务验证托盘生命周期。

覆盖：

- 344×120 迷你收入视图；
- 820×620 今日/日历工作台；
- 720×540 Settings 代表页；
- 保存成功、无变化、失败且输入保留；
- 关闭隐藏、托盘左键找回和托盘菜单；
- Per-Monitor V2 DPI 与 DIP 到客户端像素换算；
- unpackaged/self-contained 构建合同。

构建：

```powershell
..\scripts\install-toolchains.ps1 -Toolchain DotNet
.\build.ps1
```

`System.Windows.Forms.NotifyIcon` 只用于暴露 WinUI 3 缺少内置托盘 API 的真实集成成本。正式路线若采用 WinUI 3，应在 PRD 中决定继续隔离该桥接，还是改用纯 Win32 托盘服务。
