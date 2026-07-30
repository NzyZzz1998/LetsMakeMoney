# LetsMakeMoney Windows Stable 工程

这是 LetsMakeMoney 当前 Windows Stable 主线工程，技术栈为 Rust、Tauri、TypeScript 与 React。当前公开版本为 v1.0.2；v1.0.3 已进入开发验证阶段，尚未发布。

## 产品边界

- 无宠物迷你收入视图。
- 今日与日历工作台。
- 三步首次配置向导。
- 收入与作息、日历、窗口与启动、数据与支持四组设置。
- Windows 原生托盘、关闭隐藏、窗口找回、诊断与用户确认更新。
- 不包含宠物 UI、运行时、配置、资源、点击穿透或纯桌宠模式。

旧桌宠版本保留在 `v0.9-beta` tag 和对应 GitHub Release，不在 v1.0 活跃源码中维护。

## 本地验证

从仓库根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m0.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m1.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m2.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m3.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m4.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m5.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m6.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_docs.ps1
```

也可以运行 `scripts\verify_v10.ps1` 执行聚合验证。

v1.0.1、v1.0.2 与 v1.0.3 的增量验证入口位于仓库根目录 `scripts\verify_v101.ps1`、`scripts\verify_v102.ps1` 和 `scripts\verify_v103.ps1`。构建命令、依赖和当前发布身份以仓库根目录 `README.md`、`CONTRIBUTING.md` 与 `doc/current.md` 为准。
