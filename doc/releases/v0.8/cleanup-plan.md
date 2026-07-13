# LetsMakeMoney v0.8 清理执行方案（待确认）

**状态**：C0-C5 已完成
**上游证据**：`engineering-governance-review.md`

## 1. 执行原则

- 每一批独立提交、独立回归、可单独回退。
- 先打印清理清单，再由项目所有者确认，最后执行。
- 本地生成物、Git 跟踪文件、历史 tag 分开处理。
- 默认保留当前 `build/`、v0.7 Zip、用户配置和未归档验收原始证据。
- 不在同一批同时移动文档、删除脚本和重构窗口策略。

## 2. 建议批次

### C0：当前事实修正

**执行状态**：已完成（2026-07-13）。

**目标**：让人和 agent 先读到真实 v0.7 已发布状态。

- 更新 `doc/current.md`、`doc/releases/v0.7/current.md`、README 中 v0.6 验证入口和安装器措辞。
- 改造 `check_docs_status.ps1`：校验项目版本、当前 tag、release notes/checksum 口径，不再要求“发布收口中”。
- 明确 `doc/current.md` 是唯一内部当前事实，`status.md` 是版本快照。

**门禁**：docs suite、UTF-8、链接检查、`git diff --check`。

### C1：本地生成物清理

**执行状态**：已完成（2026-07-13）。共清理 8 个 ignored 目录、约 1.54 GB；`build/`、`.godot/`、`deliverables/`、`releases/` 和 `native/` 均未删除。

**目标**：释放约 1.5 GB 以上可再生成空间，不影响启动与已发布包。

默认候选：`.tmp_acceptance/`、`.tmp_release/`、`.tmp_installer/`、`.manual-test/`、`.tmp_appdata/`、`.tmp_ci/`、`_lmm_verify/`、`.godot_user_v05/`。

默认排除：`build/`、`.godot/`、`releases/v0.7/*.zip`、`deliverables/`、`%APPDATA%`。

**执行前**：生成路径、文件数、大小、最后修改时间和 ignore 状态的预览。
**执行后**：启动 `build/LetsMakeMoney.exe`，运行 docs/static suite，确认 v0.7 Zip 哈希不变。

### C2：文档分层迁移

**执行状态**：已完成（2026-07-13）。

**目标**：当前入口不再需要加载 v0.1-v0.6 历史。

1. 创建 `doc/archive/v0.1` 至 `v0.6`、`doc/archive/spikes`、`doc/archive/demos` 索引。
2. 先迁移最独立的 spike、旧日志和 temp-pc 文档。
3. 再冻结三份跨版本大文档，建立短索引，不重写历史。
4. 最后按版本迁移旧 verification/release 文档。

实际采用“正文归档 + 原路径轻量兼容页”：三份跨版本大文档、v0.1-v0.4 验证、v0.2/v0.4 素材与 UI 探索、v0.4-v0.6 旧日志已迁入 `doc/archive/`；`doc/releases/v0.4-v0.7/` 保持原位。

**门禁**：所有 Markdown 本地链接通过；README/current 只指向当前事实；历史链接有索引替代。

### C3：脚本 active/compat/archive 分层

**执行状态**：已完成（2026-07-13）。

**目标**：贡献者能看懂当前应运行什么，同时保留必要历史回归。

- `scripts/active` 逻辑概念：v0.7/v0.8、CI、许可、隐私、native、包验证。
- `scripts/compat`：v0.4-v0.6 与 M4/M5 回归；暂不移动，先在 manifest 标注。
- `scripts/archive`：v0.1-v0.3 和旧导出验证候选。
- 素材脚本拆成 runtime builder 与 maintainer-only generation 工具。

实际采用低风险逻辑分层：新增 `scripts/README.md` 与 `scripts/script-tiers.json`，86 个脚本全部且仅归入 `active`、`compat`、`archive`、`maintainer-assets`；由于 Godot `res://scripts`、当前 CI 和历史文档仍依赖原路径，本批未物理移动脚本。新增自动覆盖检查并接入 docs suite。

**门禁**：CI workflow、`run_ci_verification`、package/verify contract 全通过；历史 tag 仍可复现。

### C4：Main/native 状态治理

**执行状态**：已完成（2026-07-13）。

**目标**：降低重复状态，而不是简单拆文件。

1. 建立 WindowRuntimeState 行为合同：窗口可见、taskbar、pure pet、tray ready、modal、popup、passthrough、debug。
2. 为普通/纯桌宠 × 托盘显隐 × Modal/Popup × native 降级建立矩阵。
3. 将 Panel 布局/交互矩形计算从 Main 提取为纯函数。
4. 将菜单与模态职责从 DragResizeSystem 分离。
5. 最后决定由哪一层唯一缓存任务栏状态，移除另一层前保留回退开关。

**门禁**：v0.4-v0.7 自动回归、真实 Windows 托盘左键、任务栏策略、穿透恢复、DPI；任何失败整批回退。

实际完成：

- 新增 `WindowRuntimeState` 快照和窗口行为矩阵，Main 通过快照计算任务栏与点击穿透意图。
- 新增 `PetWindowGeometry` 纯函数，统一 Pet、Panel、窗口尺寸和交互矩形计算。
- 新增 `OverlayLifecycle` 与 `ContextMenuBuilder`，将 Modal/Popup 生命周期和菜单结构从 `DragResizeSystem` 分离。
- 移除 Main 的任务栏可见性缓存，`WindowsPlatform` 成为唯一缓存所有者，Main 只显式请求失效与策略重放。
- 保留原有菜单 ID、信号、原生降级和托盘恢复跨帧重放行为。

验证结果：v0.4-v0.7、M4、M5、C4 状态合同全部通过；临时导出 EXE 启动通过；普通模式托盘 10/10、纯桌宠托盘 10/10 通过。当前会话没有可调用的 Computer Use 能力，真实鼠标点击和 125%/150% DPI 视觉复核沿用 v0.7 已验收证据，C4 未新增视觉变化。完整证据见 `c4-verification.md`。

### C5：Settings、素材和发布目录收口

- Settings 先拆 UI section builder，再拆事务 controller；保存失败补偿逻辑原样保留。
- 验证 v1/占位猫回退后，再决定是否缩减宠物资源。
- `releases/` 只保留待上传最终附件；smoke 解压统一进入 `.tmp_release/`。
- 历史二进制以 GitHub Release 为事实源，本地只保留项目所有者选择的版本。

实际完成：

- 新增 `SettingsSectionBuilder` 与 `SettingsTransactionController`，设置页保存事务、失败补偿和外部状态回滚由定向测试锁定。
- `settings_dialog.gd` 从 1615 行降至 1445 行；v0.4-v0.7 与 M4 回归通过。
- 宠物回退审计确认 v2、v1 和占位猫均承担运行职责，本批不删除任何运行宠物资源。
- 导出 preset 排除 `deliverables/**`；包验证解压路径统一保持在 `.tmp_release/`；临时导出通过。
- GitHub Release 只存在 v0.6/v0.7；本地 v0.6 与远端哈希不同，因此历史二进制不能整体自动删除。详见 `release-retention-audit.md`。
- 项目所有者选择方案 A：删除四个版本的展开目录和 v0.7 未签名安装器，保留四个 Zip；释放 469.50 MiB，所有 Zip 重新通过包体验证。

## 3. 建议确认清单

执行前需要项目所有者逐项确认：

- [x] C0 当前事实修正已执行并通过文档/合规门禁。
- [x] C1 默认候选本地目录已清理；保留 `build/`、v0.7 Zip 和 deliverables。
- [x] C2 历史文档已分层迁移，旧路径保留兼容入口。
- [x] C3/C5 脚本逻辑分层持续生效，91 个脚本（含 Godot UID）覆盖检查和当前/兼容回归通过。
- [ ] Day4 DOCX/截图迁到仓库外 deliverables，还是归档进 Git。
- [ ] v0.1-v0.3 脚本只保留在历史 tag，还是继续留在 main 的 archive。
- [ ] 当前 main 是否必须继续复现 v0.4/v0.5 打包。
- [x] v1 和占位猫经代码、资源与回退合同审计，确认仍是公开版必须回退资源。
- [x] C4 深度治理已作为 v0.8 主开发里程碑执行并通过门禁。

## 4. 推荐执行顺序

`C0 -> C1 -> C2 -> C3 -> C4 -> C5`

C0-C3 是信息与仓库治理；C4 已作为独立运行行为切片完成；C5 仍需单独确认和验证，不应与 C4 混成一次无边界清理。
