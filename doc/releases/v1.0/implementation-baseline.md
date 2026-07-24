# LetsMakeMoney Windows v1.0 实施基线

## 实施身份

| 项目 | 冻结值 |
|---|---|
| 实施分支 | `agent/v1.0-review` |
| 实施起点 HEAD | `aa7c0b93780d7511a6551624f2eea88595cee51f` |
| 跟踪分支 | `origin/main` |
| 远端 | `git@github.com:NzyZzz1998/LetsMakeMoney.git` |
| 工作区 | v1.0 PRD、原型、Spike 与开发承接文档为有意未提交变更 |
| 技术主线 | Rust + Tauri + TypeScript/React |
| 正式工程 | `apps/windows-v1/` |
| 旧实现边界 | `src/`、`native/`、`assets/` 与 `project.godot` 在 M6 前只作为 v0.9 恢复基线 |

本页记录 M0 的实施起点，不表示当前未提交工作已经进入 `main`。

## v0.9 回退身份

| 项目 | 冻结值 | 证据状态 |
|---|---|---|
| Tag | `v0.9-beta` | 本地 annotated tag 已确认 |
| 发布提交 | `94f46229cd72a6648fa6d027130efd07354215e2` | tag 与发布文档一致 |
| GitHub Release | `https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.9-beta` | 仓库文档已确认 |
| 便携 Zip | `LetsMakeMoney-v0.9-beta-windows-x86_64.zip` | 当前工作树未保留本地副本 |
| Zip 大小 | `51,789,772` 字节 | v0.9 verification 已确认 |
| Zip SHA256 | `B10FDE2027D4ABC71C41F0F7AC7BDCE3D93AEB8AFAF4058BA1A592B6A75CC1EC` | v0.9 verification 与 release checklist 一致 |
| EXE 大小 | `122,252,488` 字节 | v0.9 verification 已确认 |
| EXE SHA256 | `E56AB6F045BF6F9E241AB42719BDF00B925754EC3FF0C9083586EB04DECEFC13` | v0.9 verification 已确认 |
| Native DLL 大小 | `1,577,984` 字节 | v0.9 verification 已确认 |
| Native DLL SHA256 | `91B1BD23CF48A422AACB66A23B8B09CDE90772039D8D2622E1C703EF03AEB2D4` | v0.9 verification 已确认 |

当前只锁定已发布身份，没有使用其他本地构建冒充正式附件。需要执行真实回退时，应从 GitHub Release 重新下载并核对上述 Zip 哈希。

## v1.0 合同事实源

| 合同 | 文件 |
|---|---|
| 配置 schema | `apps/windows-v1/contracts/config-v1.schema.json` |
| 配置默认值 | `apps/windows-v1/contracts/config-defaults.json` |
| 迁移与补偿 | `apps/windows-v1/contracts/migration-contract.json` |
| 窗口与托盘 | `apps/windows-v1/contracts/window-contract.json` |
| 日志与诊断 | `apps/windows-v1/contracts/log-contract.json` |
| 视觉与 DPI | `apps/windows-v1/contracts/visual-contract.json` |
| 工资与作息 fixture | `apps/windows-v1/tests/fixtures/salary-schedule-fixtures.json` |
| 迁移 fixture | `apps/windows-v1/tests/fixtures/migration-fixtures.json` |
| 窗口 fixture | `apps/windows-v1/tests/fixtures/window-fixtures.json` |

## 不可变边界

- 大小周模式必须由用户明确选择本周为大周或小周，默认值为 `null`。
- 默认有效工作时长为 8 小时，午休不计入收益和工作进度。
- 保存失败保留草稿、旧配置和旧运行快照。
- 关闭迷你视图不退出进程，托盘左键负责显示或隐藏迷你视图。
- v1.0 活跃配置、正式运行时和发布包不得包含宠物能力。
- v0.9 tag、Release 与 Git 历史不因 v1.0 开发被改写。
