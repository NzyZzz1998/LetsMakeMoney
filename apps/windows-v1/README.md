# LetsMakeMoney Windows v1.0

这是 Windows v1.0 的正式工程，技术栈为 Rust、Tauri、TypeScript 与 React。

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

构建命令与依赖要求见仓库根目录 `README.md` 和 `CONTRIBUTING.md`。
