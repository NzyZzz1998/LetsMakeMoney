# Rust + Tauri + React 路线样板

该样板使用 React 还原统一视觉事实源，使用 Rust/Tauri 承担窗口尺寸、托盘、关闭隐藏、配置安全写入和便携构建。

覆盖：

- 344×120 迷你收入视图；
- 820×620 今日/日历工作台；
- 720×540 Settings 代表页；
- 保存成功、无变化、失败且输入保留；
- 托盘左键显隐、菜单找回与关闭隐藏；
- Rust 侧临时文件写入后替换的配置事务。

构建：

```powershell
..\scripts\install-toolchains.ps1 -Toolchain Rust
.\build.ps1
```

当前验证工具链：

- Node.js 22.14.0
- Vite 7.3.6
- Tauri CLI 2.11.4
- Tauri 2.11.5
- Rust MSVC 1.97.1
- Microsoft C++ Build Tools
- Microsoft Edge WebView2

当前 `src-tauri/icons/icon.ico` 只是构建验证素材，不代表 v1.0 无宠物品牌图标。

正式迁移若采用此路线，仍需在 PRD 和开发计划中定义：

- WebView2 检测、缺失提示和分发边界；
- 真实 Windows 125%/150% DPI 验收；
- 真实通知区左键隐藏与找回；
- 包含 WebView2 子进程的内存和稳定性测量；
- 无障碍、自动化 UI 和 Windows 原生边界；
- 构建工具路径参数化与每次发布的产物身份。
