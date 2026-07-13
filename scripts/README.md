# LetsMakeMoney 脚本入口

`scripts/` 同时承载当前构建/验证、历史兼容回归和素材维护工具。为避免破坏 Godot 的 `res://scripts/...` 路径及旧文档，本轮先采用逻辑分层，不移动文件。

机器可读分类见 [script-tiers.json](script-tiers.json)，覆盖检查见 `check_script_tiers.ps1`。

## 当前推荐入口

| 目标 | 命令 |
|---|---|
| 文档与公开合规 | `./scripts/run_ci_verification.ps1 -Suite docs` |
| 当前静态回归 | `./scripts/verify_v07.ps1 -StaticOnly` |
| 当前完整回归 | `./scripts/run_ci_verification.ps1 -Suite main` |
| 构建 native | `./scripts/build_native_windows.ps1 -Target template_release` |
| 打包 v0.7 便携版 | `./scripts/package_v07.ps1` |
| 验证 v0.7 包 | `./scripts/verify_v07_package.ps1` |

## 四层职责

| 层级 | 说明 | 维护规则 |
|---|---|---|
| `active` | 当前 CI、构建、打包、合规和 v0.7 验证 | 修改时必须通过当前 CI contract |
| `compat` | v0.4-v0.6 与 M4/M5 回归；当前 CI 仍直接或间接依赖 | 不得仅因版本旧而删除 |
| `archive` | v0.2-v0.3 历史复现入口，不属于当前 CI | 只修安全/可运行性问题，后续可转由历史 tag 承担 |
| `maintainer-assets` | 橘猫资源生成和素材验证 | 不属于应用运行时；需保留输入来源与许可边界 |

## 重要边界

- `verify_v06.ps1` 是 v0.7 静态合同的直接上游，属于兼容门禁。
- `verify_v04.ps1`、`verify_v05.ps1`、`verify_m4.ps1` 仍被 `run_ci_verification.ps1` 调用。
- v0.2/v0.3 脚本仍被历史发布说明和 native 文档引用，暂不物理搬动。
- `.gd.uid` 与对应 Godot 脚本作为一组管理，不可单独删除。
- 素材生成脚本不是正式用户功能，也不进入发布包。
