# 参与 LetsMakeMoney

LetsMakeMoney v1.0 是一个 Rust + Tauri + React 的 Windows 桌面应用。欢迎范围清晰、带验证证据的代码、文档、测试和体验改进。

## 开发环境

- Windows 10/11 x86_64
- Node.js 22+
- Rust stable MSVC toolchain
- Microsoft Edge WebView2 Runtime

应用代码位于 `apps/windows-v1/`。旧 Godot 桌宠实现不在 v1.0 活跃树中；需要研究历史行为时请查看 `v0.9-beta` tag，不要把旧宠物模块重新复制回主线。

## Pull Request 边界

1. 一个 PR 只解决一个明确问题。
2. 业务改动说明入口、失败路径、配置、日志和回退影响。
3. UI 改动附上 100% DPI 截图；涉及缩放时补 125%/150% 证据。
4. 托盘、任务栏和窗口策略改动必须提供真实 Windows 证据。
5. 不提交构建缓存、用户配置、日志、验收临时目录、凭据或本机绝对路径。
6. 不加入宠物、动画、受限视觉素材或隐藏宠物入口。

## 提交前

至少运行与改动对应的 `scripts/verify_v10_m*.ps1`、前端构建、Rust 测试以及 `git diff --check`。安全问题请按 [SECURITY.md](SECURITY.md) 私下报告。

提交代码和代码文档即表示你有权按 [MIT License](LICENSE) 提供该贡献。
