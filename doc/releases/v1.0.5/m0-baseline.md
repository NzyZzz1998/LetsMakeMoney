# LetsMakeMoney Windows v1.0.5 M0 基线与门禁

## 1. M0 结论

| 项目 | 结论 |
| --- | --- |
| M0 状态 | 通过 |
| 完成任务 | `V105-M0-001` 至 `V105-M0-008`，8/8 |
| 用户可见行为 | 未修改 |
| 业务代码 | 未修改 |
| 构建与打包 | 未执行 |
| v1.0.4 正式对象 | GitHub Release，身份已锁定 |
| 本地同名对象 | dirty candidate，已登记且未删除 |
| 日历“今天” | 冻结为方案 A：左上“今”角标 + 日期数字加粗 |
| FR-004 | 先执行 20 次真实复现；M0 不宣称缺陷已复现或已修复 |
| FR-008 | 真实 Tauri 壳 Spike 通过才采用；失败保留 v1.0.4 表面 |
| 下一批 | `V105-M1`，不得在本批提前修改业务行为 |

本里程碑只建立事实、复现、证据和聚合验证合同。机器可读事实见 `evidence/m0-baseline.json`。

## 2. Git 与发布对象

### 2.1 开发工作树

| 字段 | 值 |
| --- | --- |
| 分支 | `main` |
| 开发 HEAD | `8a63da7836fb24c3b7f8ff12f896ac40571adeb7` |
| 远端 | `origin` / `git@github.com:NzyZzz1998/LetsMakeMoney.git` |
| 远端 main | `8a63da7836fb24c3b7f8ff12f896ac40571adeb7`，分支保护已启用 |
| 工作树 | 包含已确认的 v1.0.5 PRD、原型和开发承接改动 |
| 业务源码差异 | 0 |

工作树不是 v1.0.4 发布树，也不是可发布候选。当前改动不得用于反推或替代既有 Release 身份。

### 2.2 GitHub v1.0.4 正式对象

| 字段 | 值 |
| --- | --- |
| annotated tag | `v1.0.4` |
| tag object | `2e4fec17520524ac1e53a4e1bc993448d9255981` |
| release commit | `4d06dc73dbc5c27d7a97462d8262a553dd97d5b6` |
| Release | `LetsMakeMoney v1.0.4`，非草稿、非预发布 |
| 发布时间 | `2026-07-31T06:56:39Z` |
| Release URL | `https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.4` |
| Zip | 3,228,929 bytes；`C4F28892831891A4266C4D9B12D432CD5C970BB3C9B36A6B8DB21FA2566DE50E` |
| SHA256SUMS.txt | 107 bytes；`62886BD5359ABD12FDF3468447D114FACFEF97AD88FEA8CA1616CA1218F97ED6` |
| BUILD-INFO | `source_head=4d06dc...`；`source_tree_dirty=false` |
| EXE | 10,107,904 bytes；`E0C9C603703FC2632619AFBC84F63B1B1D403273CD01D29AA0A308A95243E107` |
| WebView2Loader.dll | 160,320 bytes；`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |

正式对象由 GitHub API、回下载资产、`SHA256SUMS.txt` 和包内 `BUILD-INFO.json` 交叉核对。SSH `ls-remote` 在本机代理链路中不可用；HTTPS GitHub API 可用，该网络限制不改变发布对象结论。

### 2.3 本地 dirty v1.0.4 candidate

| 字段 | 值 |
| --- | --- |
| 路径 | `releases/v1.0.4/LetsMakeMoney-v1.0.4-windows-x86_64.zip` |
| 处置 | `retained_pending_separate_authorization`；未删除、未移动、未取消跟踪 |
| Zip | 3,228,960 bytes；`C67E730BF81741D03BFAF6D14F3F16EB74FD8591D8B3AB76D45A980E854C249B` |
| SHA256SUMS.txt | 107 bytes；`AF4777F3C2D96315E069F4C1B0B377315D4249D503B5F2EA9E60CB76EC7D24E2` |
| BUILD-INFO | `source_head=09f838d05c67efb5219437ec2208920e441f3f52`；`source_tree_dirty=true` |
| EXE | 10,108,416 bytes；`B2A1831D0F7832C77033582871C12A2148CC8F3279753A5B812C293869ED1C66` |
| WebView2Loader.dll | 160,320 bytes；与正式对象相同 |

该对象虽然文件名和内部版本均为 v1.0.4，但 Zip、源码 HEAD、dirty 状态、构建时间和 EXE 均与 GitHub 正式对象不同。它不得作为发布回滚源、正式附件缓存或历史验收对象。

## 3. FR-001 至 FR-010 当前事实

| FR | 当前实现 | 现有直接证据 | M0 冻结缺口 / 下一步 |
| --- | --- | --- | --- |
| FR-001 | 三个 README 已存在 | v1.0.4 docs gate | 当前版本口径仍需 M1 统一并补负向门禁 |
| FR-002 | v1.0.4 包含 BUILD-INFO 与 SHA256 | 正式与 dirty 包可交叉核对 | 尚无 candidate / published 双模式验证器 |
| FR-003 | Mini 已有三阶段控制器、600ms timer、原生几何 | `mini-edge-auto-hide.behavior.ts`、Rust 几何测试 | 拖动完成未重算真实 pointer intent；无 pointerleave 失败测试缺失 |
| FR-004 | `focus` 与 `lmm:window-shown` 共用 `handleShown`，均触发 reveal | Hook、Rust show/hide 日志 | 异常界面身份未锁定；必须先完成 20 次真实复现 |
| FR-005 | v1.0.4 收起态仅有空白命中按钮 | MiniWindow、10px 原生露出宽度 | 28px 非金额竖条、状态文案、键盘和隐私负向扫描未实现 |
| FR-006 | 日历覆盖状态组件存在 | 日历状态与原型测试 | normal official 常驻来源块仍需在 M4 收敛 |
| FR-007 | 业务/选中/今天存在既有表达 | 日历行为与原型矩阵 | 方案 A 已确认但尚未进入生产实现 |
| FR-008 | `WindowFrame` 与透明 Tauri 壳维持 v1.0.4 表面 | 浏览器原型、现有窗口行为 | 真实壳 Spike 未执行；失败必须完整回退 |
| FR-009 | v1.0.4 聚合、架构和包验门禁存在 | `verify_v104.ps1` 及现有行为测试 | v1.0.5 只建立 M0 骨架，后续逐里程碑扩展 |
| FR-010 | v1.0.4 已有脱敏摘要规则 | v1.0.4 evidence 目录 | candidate、外部原始证据、published cache 所有权仍需 M1 定义 |

全部 FR 均无数据库影响。M0 证据是历史快照；相应源码或合同变化后必须按 `verification.md` 的失效规则重验，不能沿用为实现通过。

## 4. Mini v1.0.4 行为基线

### 4.1 状态与时间

- 呈现阶段：`expanded`、`retract_pending`、`retracted`。
- 交互锁：`dragging`、`focus_inside`、`menu_open`、`modal_open`。
- 收起资格：自动隐藏开启、已停靠、指针不在窗口内、无任何交互锁。
- 收起延迟：600ms；原生几何过渡：180ms。
- timer 只有一个注册点，并使用 generation 防止取消后的晚到 timer 覆盖新状态。
- 原生失败以 `notice=fallback` 回到完整窗口，不允许不可找回。

### 4.2 已确认的缺口

1. `useWindowDrag` 在 pointer capture 结束后只调用 `dragCompleted()`，没有把释放时指针是否仍位于窗口内传入控制器。
2. `dragCompleted()` 应用原生状态后沿用旧 `pointerInside`。用户拖至边缘且没有自然触发 `pointerleave` 时，旧值可继续阻塞首次收起。
3. Hook 把浏览器普通 `focus` 和原生 `lmm:window-shown` 都映射到 `handleShown`；二者都先 `reveal("window_shown")` 再 refresh。
4. `focus_inside=true` 当前会立即调用 `reveal("focus_inside")`。这是 v1.0.4 事实，不是 v1.0.5 目标语义。

### 4.3 原生几何与配置

| 合同 | v1.0.4 值 |
| --- | --- |
| 停靠阈值 | 16 逻辑像素 |
| 收起露出宽度 | 10 逻辑像素 |
| 拖离阈值 | 24 逻辑像素 |
| 显示器失效安全边距 | 12 逻辑像素 |
| 过渡 | 180ms |
| 配置 schema | v8 |
| 配置字段 | `mini_edge_auto_hide`、`mini_edge_dock`，均带默认与非法值回退 |
| 正常位置持久化 | 只保存展开位置 |
| 收起物理位置持久化 | 永不保存 |

v1.0.5 的 28px 竖条是目标需求，不得写回本基线或冒充 v1.0.4 已实现。

## 5. 已冻结决策

1. PRD、traceability 与 dev plan 已确认，范围不在 M0 重开。
2. FR-007 只实现方案 A；方案 B 只保留为原型历史。
3. FR-004 以 `fr004-reproduction-contract.md` 的 20 次真实操作为实现入口：
   - `0/20` 且无异常证据：记录未复现，不进入 Bugfix。
   - 至少一次稳定复现并锁定窗口、事件与 source：只做证据支持的最小修复。
4. FR-008 只有在真实 Tauri 壳、双主题、三档 DPI、拖动、关闭和四角门禁全部通过后才采用；任一关键项失败则保留 v1.0.4 表面。
5. dirty v1.0.4 candidate 的实际删除不是本轮授权内容。

## 6. 证据与验证入口

- FR-004：`fr004-reproduction-contract.md`。
- 主题、DPI、边缘与显示器：`evidence-matrix.md`。
- 聚合状态、继承证据和失效规则：`verification.md`。
- 机器事实：`evidence/m0-baseline.json`。
- M0 聚合入口：`scripts/verify_v105.ps1 -Milestone M0`。

M0 聚合入口只执行静态证据、负向规则、文档状态和 `git diff --check`，不构建、不打包、不启动产品，也不将 v1.0.4 验收结果冒充 v1.0.5 实现证据。
