# v1.0.7 证据矩阵

## 自动证据

| ID | 领域 | M0 基线 | 后续失效条件 | 最终证据 |
| --- | --- | --- | --- | --- |
| V107-EV-001 | Git/Release 身份 | `evidence/m0-baseline.json` | HEAD、tag 或附件变化 | M7 candidate identity |
| V107-EV-002 | PRD/追踪/原型 | 冻结 SHA256 | 任一冻结文件变化 | M7 文档门禁 |
| V107-EV-003 | current/historical | `script-lifecycle-baseline.md` | CI 或脚本调用变化 | M1/M6 current 自检 |
| V107-EV-004 | config v8 | Rust/TS/defaults=8，Schema 有已知漂移 | 任一字段/默认/迁移变化 | M1 四层交叉门禁 |
| V107-EV-005 | 首次置顶 | 源码路径存在，真实壳待证 | policy/show/setup 变化 | M2 行为测试 + ACC GUI |
| V107-EV-006 | Mini/Workbench | 无 visibility lease | show/hide/close/focus 变化 | M2 fixture + ACC GUI |
| V107-EV-007 | Mini 自动隐藏 | 当前拖拽后无需 pointerleave | controller/native 状态变化 | 10,000 序列 + 30 次真实贴边 |
| V107-EV-008 | 自由拖动 | 当前逐帧钳制 | move/finalize/recover 变化 | M2 测试 + ACC 鼠标拖动 |
| V107-EV-009 | 日期事务 | 已有独立入口，尚未共享组件 | reducer/service/IPC 变化 | M3 事务矩阵 |
| V107-EV-010 | 加班 | 尚未实现 | schema/repository/formula 变化 | M3 fixture + GUI |
| V107-EV-011 | 月度总结 | 尚未实现 | 聚合公式变化 | M4 vectors + GUI |
| V107-EV-012 | 5/6 周与 DPI | fixture 已冻结 | CSS/尺寸/字体变化 | M4 浏览器 + ACC Windows |
| V107-EV-013 | Combobox | 原生 select 基线 | Spike 样件变化 | M5 键盘/ARIA/DPI |
| V107-EV-014 | 窗口表面 | v1.0.6 表面基线 | CSS/Tauri 透明/阴影变化 | M5 4 窗口 × 3 DPI |
| V107-EV-015 | CSP | 未启用 | capability/资源/IPC 变化 | M6 隔离候选 |
| V107-EV-016 | 性能 | 尚未采集 v1.0.7 基线 | 构建或依赖变化 | M6/M7 冷暖启动与 bundle |

## GUI 与人工证据

| 矩阵 | 强制范围 | 说明 |
| --- | --- | --- |
| Windows 11 单显示器 | 必须 | 真实候选、真实鼠标、托盘与窗口层级 |
| DPI 100% / 125% / 150% | 必须 | Mini、Workbench、Settings、Wizard、日历、Combobox |
| 浅色 / 深色 | 必须 | 正常、加载、错误、禁用、焦点、弹层 |
| 5 周 / 6 周月份 | 必须 | 820×620 常用 Workbench 尺寸内整月可见 |
| Windows 10 | 有真实证据才声明支持 | 无环境时收窄支持声明 |
| 多显示器 | 暂不验证 | 不阻塞，但不得写入通过或支持声明 |
| 读屏 | 需要人工补证 | Computer Use 不能代替真实读屏体验 |

## 条件 Spike

| FR | 继续阈值 | 停止/回退 |
| --- | --- | --- |
| FR-006 | 10,000 序列或 30 次真实贴边至少复现一次且定位唯一转移 | 未复现则只保留诊断和观察 |
| FR-010 | 键盘、ARIA、双主题、三 DPI、弹层翻转全部通过 | 任一失败保留原生 select |
| FR-011 | 4 窗口 × 3 DPI 无双弧、黑边、阴影裁切 | 任一失败整体回滚 v1.0.6 表面 |
| FR-017 | 全窗口、IPC、资源、更新链路全部通过 | 保持 CSP 未启用并记录风险 |
| FR-018 | 超阈值且定向优化收益不低于 15% | 未超阈值不优化；收益不足撤销 |

## 证据状态规则

- 自动通过不等于真实 Windows GUI 通过。
- 原型通过不等于 Tauri 壳、DPI、托盘或系统菜单通过。
- 证据必须绑定 source HEAD、候选 SHA256、环境、工具版本和执行时间。
- 原始证据可存外部受控目录；仓库只保存脱敏摘要和索引。
- 候选身份变化后，依赖该候选的截图、日志、性能和 GUI 证据全部失效。
