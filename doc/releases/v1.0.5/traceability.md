# LetsMakeMoney Windows v1.0.5 需求追踪矩阵

## 追踪信息

- 当前状态：V105-M0 至 M6 已完成；唯一 clean 候选已锁定，等待独立 ACC。
- 目标版本：Windows v1.0.5 Stable。
- 当前公开版本：Windows v1.0.4 Stable。
- 候选源码基线：`277b121bbc68958382d06f4b29de3bd7685650f4`。
- 上游来源：`idea-pool.md`、`review.md`、`issue-pool.md`、`slimming-candidates.md`。
- 当前事实源：`prd.md`。
- 最后更新：2026-07-31。

## 1. 追踪规则

- `V105-IDEA-xxx`：Idea 候选需求。
- `V105-CAND/Bug-xxx`：Review 后用户观察。
- `FR-xxx`：v1.0.5 正式需求。
- `V105-ACC-xxx`：可由后续 `/acceptance` 直接执行的验收目标。
- `AUTO`：自动测试或脚本；`CU`：Computer Use；`MAN`：项目所有者或人工补证。
- 条件需求未关闭前只能写“待确认”或“待补证”，不得写成已实现、已修复或已验收。

## 2. IDEA 到 FR

| IDEA | FR | 优先级 | 当前结论 |
| --- | --- | --- | --- |
| V105-IDEA-001 | FR-001 | P0 | 正式范围，开发阶段直接修文档并补门禁 |
| V105-IDEA-002 | FR-002 | P0 | 正式范围，建立候选/正式双层身份 |
| V105-IDEA-003 | FR-003 | P0 | M3 已修复并定向验证；最终候选待 ACC |
| V105-IDEA-004 | FR-004 | P1 条件项 | M2 20/20 复现后进入 M3；已完成最小修复 |
| V105-IDEA-005 | FR-005 | P1 | M3 已实现 28px 无金额隐私竖条 |
| V105-IDEA-006 | FR-006 | P1 | M4 已实现并通过真实 Windows 定向复验 |
| V105-IDEA-007 | FR-007 | P1 | M4 已实现方案 A；方案 B 只保留为原型历史对照 |
| V105-IDEA-008 | FR-008 | P1 Spike | M5 已通过并保留单一表面候选；Windows 10 待环境补证 |
| V105-IDEA-009 | FR-009 | P0/P1 | 横切门禁，随全部正式需求建立 |
| V105-IDEA-010 | FR-010 | P2 | 正式范围，仅建立目录/证据合同，不批量清理 |
| V105-IDEA-011 | 无 | 版本外 | 暂不处理，不进行历史脚本和大模块重构 |

## 3. 上游观察到 FR

| 上游问题 | FR | 处理结论 |
| --- | --- | --- |
| V105-CAND-001 normal official 来源块占首屏 | FR-006 | 确认进入 PRD，风险状态不得隐藏 |
| V105-CAND-002 今天与选中观感接近 | FR-007 | 保留主观判断，先 A/B 高保真选择 |
| V105-BUG-001 首次贴边不及时收起 | FR-003 | M3 已修复，左右边缘真实桌面定向通过 |
| V105-CAND-003 隐私竖条 | FR-005 | 正式需求，禁止收入和工资制度泄露 |
| V105-BUG-002 关闭 Workbench 后异常界面 | FR-004 | M2 20/20 锁定 Mini；M3 已修复并定向通过 |
| V105-CAND-004 窗口“框中框” | FR-008 | 限定三窗，真实壳 Spike 先行 |
| V105-REV-001 README 漂移 | FR-001/009 | 直接事实修正 + 自动门禁 |
| V105-REV-002 同名 Zip 身份不同 | FR-002/009/010 | 双层身份、目录隔离、远端回下载 |

## 4. FR 到实现边界

| FR | 主要实现或计划产物 | React / Hook | Rust / Tauri | CSS / UI | 脚本 / 文档 |
| --- | --- | --- | --- | --- | --- |
| FR-001 | 三个 README、docs gate | 无 | 无 | 无 | 版本、命令、链接一致性 |
| FR-002 | BUILD-INFO 与 identity verifier | 无 | 只读构建身份 | 无 | candidate/publish 双模式、回下载核验 |
| FR-003 | Mini 状态机与 Hook | `miniEdgeAutoHide.ts`、`useMiniEdgeAutoHide.ts`、Mini | work-area、dock/retract command | 状态过渡 | 状态机和几何测试 |
| FR-004 | 窗口事件来源 | focus/shown 映射 | show/hide source | 无 | 20 次复现证据 |
| FR-005 | 隐私竖条 presenter | `MiniWindow.tsx` / presentation | 复用 28px 几何 | 浅/深、DPI、焦点和减少动态 | 隐私文案负向扫描 |
| FR-006 | Coverage Notice | `App.tsx` 日历覆盖呈现 | 无 | official/risk 状态 | 状态行为测试、原型 |
| FR-007 | Calendar cell presenter | `presentation.ts` / 日历 UI | 无 | today A/B、selected、focus | 原型选择、ARIA 测试 |
| FR-008 | WindowFrame 表面职责 | 三个窗口根容器 | 真实透明壳边界 | 单一表面 | Spike 报告与真实壳截图 |
| FR-009 | 高风险门禁 | TS fixture | Rust fixture / 桌面冒烟 | DPI/视觉 | CI、验收和发布 checklist |
| FR-010 | 证据与目录合同 | 无 | 无 | 无 | schema、ignore、处置清单 |

## 5. FR 到数据、配置与日志

| FR | 配置 / 数据 | 日志与证据 | 兼容 |
| --- | --- | --- | --- |
| FR-001 | 无产品配置 | docs gate 结果 | 不改历史文档结论 |
| FR-002 | BUILD-INFO、SHA256SUMS | 构建、发布和回下载摘要 | v1.0.4 tag/Release 不变 |
| FR-003 | 复用 `mini_edge_auto_hide`、`mini_edge_dock` | `mini.edge.*`，不记工资/精确坐标 | 配置 schema v8 向后兼容 |
| FR-004 | 无新增字段 | focus/blur/shown/native/reveal 时间线 | 托盘找回必须保持 |
| FR-005 | 消费 Dashboard 阶段与下一边界 | 不记录竖条收入数据 | 关闭自动隐藏回到完整 Mini |
| FR-006 | 不改日历源、缓存和日期调整 | 沿用 coverage 日志 | 数据口径不变 |
| FR-007 | 不改日期业务状态 | 无新增生产日志 | 只改导航视觉和 ARIA |
| FR-008 | 无 | Spike 与截图身份 | 失败回滚 v1.0.4 表面 |
| FR-009 | 隔离测试 fixture | AUTO/CU/MAN 脱敏摘要 | 回归全部 v1.0.4 主链路 |
| FR-010 | candidate/evidence/cache 元数据 | 永久脱敏摘要 + 外部原始证据索引 | 不删除唯一证据 |

所有 FR 均无数据库影响。

## 6. FR 到验收

| FR | 验收 ID | AUTO | CU | MAN | 发布阻塞 |
| --- | --- | --- | --- | --- | --- |
| FR-001 | V105-ACC-001 | 版本、链接、命令、UTF-8 | 不适用 | 中英文语义 | 是 |
| FR-002 | V105-ACC-002、012 | dirty/HEAD/SHA/tag 负向与回下载 | 新解压启动 | Release 核对 | 是 |
| FR-003 | V105-ACC-003、004 | 首次收起、timer、晚到结果、focus | 左右边缘与找回 | 多显示器补证 | 是 |
| FR-004 | V105-ACC-005 | focus/shown 分离合同 | Workbench 关闭已定向复验 | 通知区显式找回 | 是 |
| FR-005 | V105-ACC-006、007 | 文案/DOM/ARIA 隐私扫描 | 全状态、主题、键盘 | 125/150% DPI | 是 |
| FR-006 | V105-ACC-008 | official/risk 状态矩阵 | 浅/深真实界面 | 可读性 | 是 |
| FR-007 | V105-ACC-009 | class/ARIA 叠加 | A/B 高保真和实装 | 项目所有者选型 | FR-007 自身阻塞 |
| FR-008 | V105-ACC-010 | 结构/主题回归 | 三窗四角与拖动 | Win10/11、DPI | 可回滚，不阻塞其他范围 |
| FR-009 | V105-ACC-011 | 聚合全门禁 | v1.0.4 核心回归 | 系统边界 | 是 |
| FR-010 | V105-ACC-002 | schema、敏感路径、唯一副本保护 | 不适用 | 处置记录 | 是 |

## 7. 条件门禁

### 7.1 FR-004

- `0/20` 且没有异常界面证据：保留日志和待补证，不进入 Bugfix，不得标记修复。
- 可重复且锁定事件链：只实现证据支持的最小修复，并重新执行 FR-003/005 全回归。
- M2 结果：`20/20` 复现，界面确认为 Mini 展开态；普通 focus 被共用 handler 当成 explicit shown。
- M3 结果：普通 focus 仅设置交互锁，显式 `lmm:window-shown` 独立展开；真实关闭 Workbench 后 Mini 保持收起。FR-004 已修复，最终通知区找回仍由 ACC 复核。

### 7.2 FR-007

- 已确认方案 A：左上“今”角标 + 数字加粗。
- 方案 B：底部“今天”短签 + 数字加粗；仅保留为已评审原型对照，不进入实现任务。

### 7.3 FR-008

- 真实 Tauri 壳、浅/深、100/125/150% DPI、拖动、关闭、四角和阴影全部通过才可实施。
- 任一关键条件失败则保留 v1.0.4 表面并记录延期，不影响其他确定需求进入发布。
- M5 结果：Windows 11、三档真实 DPI、三窗拖动/关闭/模态与 Mini 回归通过；Web 负责背景/边框/圆角，原生窗口负责透明壳/阴影。保留单一表面候选进入 M6。
- Windows 10 当前没有可用设备或 VM，准确记录为待环境补证，不以 Windows 11 结果推断通过。

## 8. 依赖与顺序

| 阶段 | 输入 | 输出 |
| --- | --- | --- |
| M0 | FR-001/002/010 | README、身份、目录合同和失败夹具 |
| M1 | 当前 Mini 基线 | characterization tests、FR-004 复现证据 |
| M2 | M1 | FR-003 状态机与安全回退 |
| M3 | M2 | FR-005 隐私竖条 |
| M4 | 原型确认 | FR-006 与条件 FR-007 |
| M5 | 真实壳 Spike | 条件 FR-008 或明确回滚 |
| M6 | 全部完成项 | 自动聚合与唯一 clean 候选已完成 |

## 9. 非目标追踪

| 内容 | 结论 |
| --- | --- |
| V105-IDEA-011 大模块/历史脚本重构 | 暂不处理 |
| 宠物 / PetManager | 独立版本 |
| 全量设计系统和全窗口重绘 | 不进入 v1.0.5 |
| 账号、云同步、安装器、自动更新、多平台 | 不进入 v1.0.5 |
| 修改 v1.0.4 tag、Release、附件或哈希 | 禁止 |
| 删除 dirty candidate | 需 PRD 后单独清理授权，本轮禁止 |

## 10. 下游条件

以下开发承接条件已经关闭：

1. 项目所有者已确认 `prd.md`。
2. 项目所有者已选择日历方案 A。
3. 项目所有者已接受 FR-008 为“Spike 先行、失败可回滚”的条件需求。

当前追踪结论：**业务开发、M6 自动聚合与唯一 clean 候选已完成；下一步只对该对象执行独立 ACC。候选当前不可发布。**
