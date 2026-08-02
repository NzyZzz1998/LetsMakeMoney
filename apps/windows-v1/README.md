# LetsMakeMoney Windows Stable 工程

这是 LetsMakeMoney 当前 Windows Stable 主线工程，技术栈为 Rust、Tauri、TypeScript 与 React。当前公开版本为 v1.0.5 Stable，当前开发目标为 v1.0.6；v1.0.6 尚未完成独立候选验收或发布。

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

v1.0.1 至 v1.0.5 的历史增量验证入口位于仓库根目录。当前 v1.0.6 聚合入口为 `scripts\verify_v106.ps1`，隔离打包入口为 `scripts\package_v106.ps1`；构建命令、依赖和当前发布身份以仓库根目录 `README.md`、`CONTRIBUTING.md` 与 `doc/current.md` 为准。

## 架构行为验证

安装锁定依赖后，可在本目录运行：

```powershell
npm ci
npm test
npm run build:web
```

`npm test` 会执行 Runtime Adapter、配置领域、桌面服务、时间与呈现纯函数测试，并检查前后端责任边界和工具解析。当前完整开发回归以仓库根目录的 `scripts\verify_v106.ps1` 为准；公开版本复核继续使用 v1.0.5 的锁定身份。

## 统一工具链解析

正式验证和打包脚本按固定顺序解析 Node、Python 和 Cargo：

1. 显式环境变量。
2. `PATH`。
3. 仓库根目录 `.toolchains` 缓存。
4. 全部缺失时给出可操作错误并停止。

```powershell
$env:LMM_NODE = "<node.exe 的绝对路径>"
$env:LMM_PYTHON = "<python.exe 的绝对路径>"
$env:LMM_CARGO = "<cargo.exe 的绝对路径>"
$env:LMM_CARGO_HOME = "<Cargo Home>"
$env:LMM_RUSTUP_HOME = "<Rustup Home>"
```

仓库缓存位置分别为 `.toolchains\node\node.exe`、`.toolchains\python\python.exe`
和 `.toolchains\cargo\bin\cargo.exe`。正式入口不依赖 `spikes/`、Codex 私有运行时或某个开发者的用户目录。
