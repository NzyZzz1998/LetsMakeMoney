# 参与 LetsMakeMoney

仓库目前处于 v0.7 公开开发阶段。欢迎小而清晰、带验证证据的贡献。

## 当前接受

- GDScript、C++ native 和构建/验证脚本代码；
- 中文或英文文档修正；
- UI 交互、可用性和视觉规范建议；
- 不包含第三方视觉文件的原型代码；
- 测试、问题复现和 Windows 兼容性证据。

## 当前不接受

- 猫咪、Logo、图标、动画、音频或其他外部素材文件；
- 来源或授权不明确的 AI 生成输出；
- ComfyUI 模型、工作流包、缓存或大体积生成产物；
- 凭据、用户配置、日志、私有截图或本机绝对路径。

## 许可约定

- 提交代码和代码文档，即表示同意按项目根目录 [MIT License](LICENSE) 提供贡献，并确认自己有权提交。
- 项目视觉素材适用 [ASSETS_LICENSE.md](ASSETS_LICENSE.md)，不能因为代码采用 MIT 就视为可自由复用。
- 不要在 Pull Request 中加入素材文件。需要表达视觉建议时，提供文字说明、线框或不含第三方受限内容的示意。

## 开发环境

- Windows x86_64、Godot 4.7 stable、PowerShell。
- native 贡献还需要 Python 3.12、SCons 4.10.1 和 MSYS2 UCRT64 GCC。
- 先运行 `scripts/bootstrap_native_dependencies.ps1`，再按 `native/windows/README.md` 构建。

## Pull Request 颗粒度

一个 PR 只解决一个明确问题。业务行为改动必须说明入口、失败路径、配置与日志影响；Main/native 改动必须对照 `doc/releases/v0.7/window-native-state-contract.md` 并提供 Windows 实机证据。不要把格式化、素材替换和功能修改混在一起。

## 提交前

1. 不提交构建缓存、本地依赖、验收证据、配置、日志、签名材料或 Release 展开目录。
2. 至少运行 `scripts/check_public_candidate.ps1`、对应版本验证和 `git diff --check`。
3. 说明目的、影响范围、测试结果和回退方式。
4. 安全问题不要放在公开 Issue；按 [SECURITY.md](SECURITY.md) 使用 Private Vulnerability Reporting。
5. 遵守 [参与者行为准则](CODE_OF_CONDUCT.md)。
