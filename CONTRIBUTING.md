# 参与 LetsMakeMoney

LetsMakeMoney v1.0 是一个 Rust + Tauri + React 的 Windows 桌面应用。欢迎范围清晰、带验证证据的代码、文档、测试和体验改进。

## 开发环境

- Windows 11 x86_64 是 v1.0.7 必需的已验证开发环境。
- Windows 10 可能仍可构建，但在取得真实设备或 VM 证据前不属于 v1.0.7 已验证环境。
- Node.js 22+
- Python 3.12
- Rust 1.97.1 MSVC toolchain
- Visual Studio 2022 Build Tools 与 Windows 10/11 SDK
- Microsoft Edge WebView2 Runtime

首次开发前先运行只读环境诊断：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\diagnose_v104_environment.ps1
```

应用代码位于 `apps/windows-v1/`。旧 Godot 桌宠实现不在 v1.0 活跃树中；需要研究历史行为时请查看 `v0.9-beta` tag，不要把旧宠物模块重新复制回主线。

## Pull Request 边界

1. 一个 PR 只解决一个明确问题。
2. 业务改动说明入口、失败路径、配置、日志和回退影响。
3. UI 改动附上 100% DPI 截图；涉及缩放时补 125%/150% 证据。
4. 托盘、任务栏和窗口策略改动必须提供真实 Windows 证据。
5. 不提交构建缓存、用户配置、日志、验收临时目录、凭据或本机绝对路径。
6. 不加入宠物、动画、受限视觉素材或隐藏宠物入口。

## 提交前

提交前运行唯一当前门禁 `scripts/verify_windows_current.ps1`。版本化脚本只用于复核对应历史版本，不得作为当前绿色 CI 的替代入口。安全问题请按 [SECURITY.md](SECURITY.md) 私下报告。

环境与 DPI 边界见 [v1.0.7 支持矩阵](doc/releases/v1.0.7/support-matrix.md)。多显示器不属于本版验收范围。

提交代码和代码文档即表示你有权按 [MIT License](LICENSE) 提供该贡献。
