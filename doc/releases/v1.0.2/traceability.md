# LetsMakeMoney Windows v1.0.2 需求追踪矩阵

## 1. 追踪规则

- 上游需求以 `V102-IDEA-xxx` 为唯一来源。
- 正式需求以 `FR-001` 至 `FR-008` 为开发和验收入口。
- `V102-BUG-001` 只作为已完成启动基线，不进入本轮开发任务。
- `V102-IDEA-008` 与 `V102-IDEA-009` 只按 PRD 治理边界承接，不扩展为正式产品功能。

## 2. IDEA 到 FR

| IDEA | 正式需求 | PRD 章节 | 原型入口 | 主要验收 |
| --- | --- | --- | --- | --- |
| V102-IDEA-001 | FR-001 阶段化业务边界倒计时 | §4 | Mini、今日页、业务状态控制 | 阶段矩阵、边界切换、跨夜 |
| V102-IDEA-002 | FR-002 今日安排三列时间线 | §5 | 今日页 | 日班、零休息、跨夜、三档 DPI |
| V102-IDEA-003 | FR-003 迷你视图尺寸合同 | §6 | Mini | 344×108、长内容、拖动、托盘 |
| V102-IDEA-004 | FR-004 日历复合状态 | §7 | 日历页 | 业务/今天/选择/手动/focus/stale |
| V102-IDEA-005 | FR-005 全局图标 | §8 | Workbench、Settings、状态入口 | 图标、ARIA、许可、包验证 |
| V102-IDEA-006 | FR-006 来源与 owner date | §9 | 今日页、日历页 | 调休、手动、夜班归属、stale |
| V102-IDEA-007 | FR-007 行为与 DPI 门禁 | §10 | 全部窗口 | 自动、Playwright、Computer Use |
| V102-IDEA-010 | FR-008 双主题系统 | §11 | 原型主题控制、Settings 外观 | 预览、保存、取消、失败、重启 |

## 3. FR 到实现边界

| FR | React/TypeScript 目标 | CSS 目标 | Rust/Tauri 目标 | 配置/依赖 |
| --- | --- | --- | --- | --- |
| FR-001 | `DashboardSnapshot.nextBoundarySeconds`、`selectStagePresentation` | 阶段/错误/长倒计时 | 复用权威边界字段 | 无新增配置 |
| FR-002 | Today 三列时间线 | grid、节点、轴线 | 不改领域逻辑 | 保留 `lunch_*` |
| FR-003 | Mini 状态内容、拖动排除 | 344×108 稳定尺寸 | Mini 窗口合同、安全回落 | 位置字段不变 |
| FR-004 | `mapCalendarCellPresentation`、ARIA、键盘 | 复合状态独立层 | 自然日与 owner date 不混用 | 日期覆盖不变 |
| FR-005 | `AppIcon` 白名单 | 图标按钮状态 | 无 | `lucide-react@1.27.0`、ISC |
| FR-006 | 标题、副标题、来源标签 | 长日期和 stale | 复用 owner date/source | 无 |
| FR-007 | 行为测试稳定接口 | 溢出和截图标识 | 迁移/窗口夹具 | 包和许可验证 |
| FR-008 | ThemeProvider、主题事务 | 浅深令牌与全状态 | config v8、ThemeSession、首帧 | `theme_mode` |

## 4. FR 到日志

| FR | 必需事件 |
| --- | --- |
| FR-001 | `presentation.stage.changed`、`presentation.boundary.corrected`、`presentation.boundary.missing`、retry 系列 |
| FR-002 | `presentation.schedule.invalid` |
| FR-003 | `mini.resize.fallback`，复用窗口位置事件 |
| FR-004 | `calendar.presentation.unknown`，复用日期调整事件 |
| FR-005 | `icon.fallback.used` |
| FR-006 | 复用快照/日历来源事件；异常内容映射记录 |
| FR-007 | 验证脚本输出，不新增高频生产日志 |
| FR-008 | `theme.loaded`、preview/revert/save/unchanged/failure/fallback/window 系列 |

## 5. 验收覆盖

| FR | 自动化 | Playwright | Computer Use | 人工 |
| --- | --- | --- | --- | --- |
| FR-001 | 状态与边界表驱动 | Mini/Today DOM | 秒级阶段切换、retry | 夜班语义 |
| FR-002 | 日程结构 | 三班次与 DPI | 真实窗口、调整返回 | 轴线对齐 |
| FR-003 | 尺寸与拖动排除 | 长金额/错误 | 拖动、托盘、位置 | 三档 DPI |
| FR-004 | 18 个复合状态 | 浅深、ARIA、focus | 键盘、日期调整 | 灰度识别 |
| FR-005 | 白名单、许可 | 图标状态 | 入口点击 | 清晰度 |
| FR-006 | 来源与 owner date | 长日期 | 夜班、调休、手动 | 文案歧义 |
| FR-007 | 全门禁汇总 | 全矩阵 | 真实 Tauri | 通知区限制 |
| FR-008 | 迁移与主题事务 | 全窗口浅深 | 首帧、跨窗、失败 | 深色舒适度 |

## 6. v1.0.1 回归映射

| 稳定能力 | 覆盖 FR | 不允许变化 |
| --- | --- | --- |
| 收入与整数分累计 | FR-001、FR-007 | 公式、秒级累计、30 秒权威同步 |
| 官方日历与日期调整 | FR-004、FR-006、FR-007 | 数据、优先级、事务补偿 |
| 跨夜班次 | FR-001、FR-002、FR-006 | owner date 与金额归属 |
| 配置安全写入 | FR-008 | 临时文件、备份、失败不污染 |
| Mini 位置与托盘找回 | FR-003、FR-007 | 隐藏、恢复、安全回落 |
| 更新与诊断 | FR-007 | 现有入口和失败反馈 |

## 7. 治理项

| 项目 | 本版处理 | 门禁 |
| --- | --- | --- |
| V102-IDEA-008 | 只允许阶段选择器、日历映射、主题令牌和直接相关组件拆分 | 先补测试，行为等价 |
| V102-IDEA-009 | 只读测量单/双窗口请求、日志和性能 | 无可见问题不实施共享所有权 |
| V102-BUG-001 | 保留已关闭证据 | 不重复计入完成率 |
