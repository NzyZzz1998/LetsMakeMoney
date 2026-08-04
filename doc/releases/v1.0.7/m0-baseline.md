# LetsMakeMoney Windows v1.0.7 M0 基线

## 结论

V107-M0 冻结于 `main@12b6b03ce91b716d49590e21eb8dd7fe90fa283c`。当前业务代码与 v1.0.6 发布后的主线一致；v1.0.7 仅存在已确认的需求、原型、开发承接文档和本批新增的测试/证据产物。

本阶段不改变产品行为。已确认的漂移和缺口必须由后续里程碑关闭，不能在 M0 中通过改写结论、放宽检查或删除历史测试来消失。

## Git 与发布身份

| 字段 | 冻结值 |
| --- | --- |
| 分支 | `main` |
| 开发基线 HEAD | `12b6b03ce91b716d49590e21eb8dd7fe90fa283c` |
| 远端 `origin/main` | `12b6b03ce91b716d49590e21eb8dd7fe90fa283c` |
| 当前公开版本 | v1.0.6 Stable |
| v1.0.6 annotated tag object | `96ffc5b593c965d580d0c5b170348ba7f674dbdf` |
| v1.0.6 Release commit | `51e4c08da5260af9b9f4808c4f6d29591319e655` |
| GitHub Release | `https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.6` |
| 业务代码 | 未修改 |

### v1.0.6 正式附件

| 对象 | 大小 | SHA256 |
| --- | ---: | --- |
| `LetsMakeMoney-v1.0.6-windows-x86_64.zip` | 3,245,194 字节 | `AEE4BC4A41D3839E421138D0B152EA5A8B0FBDC60C5B189EA11790DE4ED8B66A` |
| `SHA256SUMS.txt` | 107 字节 | `6EE4555857B51405365D57086A40025D59A178EE5F813C8BAAF0DA0826361B9B` |
| 包内 `LetsMakeMoney.exe` | 10,140,160 字节 | `21EAC751534F4D0787DEC07545F315326E9C5D773F39D65D9F46AA1879518659` |
| 包内 `WebView2Loader.dll` | 160,320 字节 | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |

包内 `BUILD-INFO.json` 记录 `version=1.0.6`、`source_head=51e4c08...`、`source_tree_dirty=false`。后续 v1.0.7 候选不得复用该身份，也不得把本地同名文件视为 GitHub 正式附件。

## 冻结合同

以下文件的 SHA256 写入 `evidence/m0-baseline.json`：

- `prd.md`
- `traceability.md`
- `dev_plan_v1.0.7.md`
- `doc/prototypes/v1.0/index.html`
- `doc/prototypes/v1.0/app.js`
- `doc/prototypes/v1.0/styles.css`

PRD、追踪矩阵和开发计划是实现事实源。原型只证明交互与视觉合同，不证明 Tauri、Windows、DPI、托盘或文件事务已经通过。

## 当前行为基线

### config v8

- Rust `CURRENT_CONFIG_VERSION`、TypeScript `CURRENT_CONFIG_VERSION` 与 defaults 均为 8。
- Rust 保留 v5、v6、v7 到 v8 的迁移和损坏配置保护。
- defaults 已包含 `mini_edge_auto_hide` 与 `mini_edge_dock`。
- JSON Schema 的 `required` 和 `properties` 尚未包含上述两个字段，属于 **M1 必须关闭的已确认漂移**。
- 历史 schema/defaults 仍在仓库中，当前与历史用途尚无统一索引。

### 首次置顶

- 已配置启动会在 setup 阶段调用 `apply_window_policy`。
- 未配置启动会隐藏 Mini 并显示 Wizard；Wizard 完成后的 Mini 显示路径会再次调用 `apply_window_policy`。
- 源码具备设置置顶的路径，但“清配置首次完成 Wizard 后首个 Mini 帧已置顶”尚无真实 Windows 壳证据，M2 前不得写为通过。

### Mini / Workbench

- 当前公开 command 仅提供独立 `show_app_window` 与 `hide_app_window`，尚无 visibility lease 或 transaction id。
- Mini 的 `expanded`、`privacy_retracted`、`hidden_by_user`、`not_present` 尚未形成统一恢复结果合同。
- `lmm:window-shown` 在 Mini hook 中直接触发 reveal，普通聚焦与显式找回的语义仍需 M2 分离。

### 自动隐藏与拖动

- 当前主行为测试已经证明：贴边拖拽完成后会丢弃拖拽前的 stale pointer/focus，并在无需 `pointerleave` 的情况下安排首次收起。
- 旧 `mini-edge-auto-hide.m2-characterization.behavior.ts` 仍描述修复前结果，且未进入当前 architecture runner；它只作为历史红灯留档。
- menu/modal lock、取消后的 late timer 与 native 晚到结果已有 generation-safe 行为测试。
- `move_app_window` 当前每帧移动后调用 `safe_window_position`，会在拖动期间钳制窗口，属于 M2 必须关闭的已确认缺口。
- release/finalize/recover 尚未拆成独立 command。

### 日期与加班

- 日期调整已有行为状态和保存链路，但“调整今天”与日历入口尚未共享完整事务组件。
- v1.0.6 没有 overtime 领域模型、仓储、IPC 或 UI。
- v1.0.7 的精度、费率快照、跨夜归属、损坏文件保护与跨月统计仅被冻结为测试向量，尚未实现。

## 当前已确认漂移

1. Windows CI 仍恢复 v1.0.3 附件并调用 `verify_v104.ps1`。
2. config v8 defaults 与 JSON Schema 缺少两个 Mini edge 字段的对齐。
3. 应用版本在 package、Cargo、Tauri、About、更新和脚本中多点硬编码。
4. current 与 historical 脚本没有唯一生命周期索引和误用失败保护。
5. Mini/Workbench 无可补偿显示事务。
6. 拖动路径仍逐帧执行安全区钳制。
7. 加班领域尚不存在。

## 证据失效条件

出现以下任一变化，相应自动或 GUI 证据必须重做：

- source HEAD、依赖锁、Rust toolchain、Node/Python 工具解析或构建参数变化；
- config、IPC payload、窗口 command、Tauri capability 或 WebView 生命周期变化；
- 候选 Zip、EXE、DLL、BUILD-INFO 或 SHA256 变化；
- Mini/Workbench/Settings/Wizard 的结构、尺寸、CSS、主题或 DPI 行为变化；
- overtime schema、数据文件、费率公式、owner date 或聚合公式变化。

## M0 判定

M0 通过只表示事实、红灯、测试向量和恢复边界可独立复核，不表示 v1.0.7 功能已实现，也不表示可以构建候选或进入发布验收。
