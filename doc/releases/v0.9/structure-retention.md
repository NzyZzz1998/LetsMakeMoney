# v0.9 目录与保留决策

**状态**：冻结候选的结构审计结论
**最后更新**：2026-07-23

## 1. 当前目录职责

| 路径 | 职责 | 结论 |
|---|---|---|
| `src/` | Godot 业务与界面源码 | 必须保留 |
| `native/` | Windows 原生集成源码、依赖缓存和构建输出 | 仅源码与说明进入 Git；缓存和产物保持忽略 |
| `assets/`、`icons/` | 运行时宠物、界面和图标资源 | 必须保留；受素材清单和回退合同约束 |
| `scripts/` | 当前验证、兼容回归、发布与维护者工具 | 继续平铺；由 `script-tiers.json` 逻辑分层 |
| `doc/current.md` | 唯一内部当前状态入口 | 必须保留 |
| `doc/releases/` | 各版本需求、实现、验收和发布事实 | 按版本保留 |
| `doc/archive/` | 历史正文、旧日志和素材探索 | 只读历史参考 |
| `doc/prototypes/` | 当前及历史可交互原型、Figma 本地插件 | 保留，生成缓存不得混入 |
| `build/` | 本机可启动构建 | 本地保留、Git 忽略，可重新生成 |
| `deliverables/` | 演示、交接等非发布交付物 | 本地保留、Git 忽略，不进入 Release |
| `releases/` | 已锁定便携包和少量发布说明 | 二进制本地保留、Git 忽略；公开附件以 GitHub Release 为准 |
| `.tmp_acceptance/` | 本机验收证据 | Git 忽略；只保留截图、日志、配置和身份记录 |
| `.cache/`、`.godot/` | 工具和 Godot 可再生缓存 | Git 忽略，不作为事实源 |

## 2. 文档审计

`doc/LetsMakeMoneyPRD.md`、`doc/implementation-plan.md` 和 `doc/progress.md` 均已缩减为约 0.5 KiB 的兼容入口，原始正文位于 `doc/archive/legacy-core/`。v0.2、v0.4 素材文档和旧验证路径同样只保留轻量跳转页。

因此，`doc/` 根层看起来仍有旧文件名，但没有继续平级堆放历史正文。删除这些入口会破坏旧提交、历史文档和外部链接，节省空间可以忽略，结论是保留。

原本位于 `doc/` 的 Day4 AI 产品方案 DOCX 是未跟踪、被忽略的本地演示交付物，没有源码或文档依赖。项目所有者已于 2026-07-23 确认删除；该文件从未进入 Git 历史或公开候选树。

## 3. 脚本审计

当前 `scripts/` 共 127 个文件、约 0.44 MiB。其中 125 个可执行脚本、Godot UID 和维护工具登记到四个逻辑层，另有 `README.md` 与分层清单自身：

- `active`：85 个当前 CI、v0.7-v0.9、构建、发布和合规入口。
- `compat`：24 个 v0.4-v0.6 与 M4/M5 兼容回归。
- `archive`：8 个 v0.2-v0.3 历史复现入口。
- `maintainer-assets`：8 个维护者素材生成和验证工具。

这些脚本存在 Godot `res://scripts` 引用、PowerShell 相对调用、CI 状态检查和历史文档链接。`.gd.uid` 还必须与 Godot 脚本保持相对位置。物理移动会造成大范围路径改写，却只节省一层目录视觉噪音。

结论：冻结 v0.9 阶段继续使用 `scripts/README.md` 与 `scripts/script-tiers.json` 管理职责，不物理搬动。未来只有在新的主版本先补齐“移动前后同等回归”后，才考虑拆目录。

## 4. 本地空间治理

2026-07-23 已完成两类安全清理：

1. 常规可再生临时目录：160 个文件，约 128 MiB。
2. `.tmp_acceptance/` 中 9 份可由锁定 Zip 重建的运行副本：约 1.04 GiB。

验收目录从约 1.07 GiB 降至约 33 MiB。27 个截图、日志、配置和身份类非运行证据引用仍存在；文档中缺失的 3 条路径仅是已删除的历史解压启动位置。详细边界见 [evidence-retention.md](evidence-retention.md)。

## 5. 不执行的清理

- 不删除 `build/`，避免本机失去直接启动入口。
- 不删除锁定候选 Zip、GitHub Release 对应附件或哈希记录。
- 不删除 v1、占位猫及 Classic 回退资源。
- 不移动兼容文档入口和脚本。
- 不清空整个 `.tmp_acceptance/`。
- 不删除 `native/` 的源码和构建说明。
- 不修改业务代码、配置字段或发布包内容。

## 6. 后续门禁

新增文件或版本结束时应执行：

```powershell
.\scripts\check_script_tiers.ps1
.\scripts\run_ci_verification.ps1 -Suite docs
.\scripts\cleanup_local_generated.ps1
```

清理验收解压副本必须显式使用 `-AcceptanceRuntimeCopies`，且先预览后执行。任何物理归档都必须同步修复本地链接、CI 路径和 Godot 资源引用，并完成当前聚合回归。
