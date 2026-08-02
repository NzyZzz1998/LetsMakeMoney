# LetsMakeMoney Windows v1.0.6 问题池

> 状态：定向 Bugfix、自动回归、候选构建、真实 Windows 身份冒烟和发布授权均已完成；等待受保护分支合并后重建正式附件。
>
> 基线：v1.0.5 Stable，Release 源提交 `ffc431af3fbf7c3b54bca8aaff44946cc8d6aeaf`。
>
> 外部观察仅作为证据读取；本文件不覆盖或改写 v1.0.5 发布前验收结论。

## 问题总览

| ID | 类型 | 严重度 | 证据状态 | 问题 | 用户影响 | 建议去向 | 当前状态 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| V106-BUG-001 | 主题初始化 | Minor | 已确认 | `config.json` 为浅色时，Mini/Workbench 首帧可能采用旧的深色 `localStorage`；Settings 无变化保存后才收敛 | 首帧主题错误、闪烁、配置可信度下降 | Bugfix | 已关闭；自动与真实 GUI 通过 |
| V106-BUG-002 | 原生关闭事务 | Major | 已确认 | Settings/Wizard 的原生 Alt+F4 曾绕过 React 未保存确认并直接隐藏窗口 | 其他窗口残留未保存 preview 主题，配置与界面事实不一致 | Bugfix | 已关闭；自动与真实 GUI 通过 |
| V106-RISK-001 | 配置初始化 | Major | 高度可能 | Settings/Wizard 在 Rust 权威配置返回前先渲染默认草稿，且没有完整交互门禁 | 慢启动下可能显示或保存默认值，存在覆盖旧配置风险 | Bugfix + characterization | 已关闭；24/24 高风险组合与首帧 GUI 通过 |
| V106-TEST-001 | 测试治理 | Major | 已确认 | 现有主题测试只验证归一化和静态字符串，无法证明首帧、监听重放和四窗口一致性 | CI 可能对同类回归错误报绿 | Bugfix 发布门禁 | 已补 17 项主题行为与 24 项高风险组合门禁 |
| V106-LOG-001 | 可诊断性 | Minor | 已确认 | 缺少 `theme.loaded`、窗口应用来源和代际日志 | 难以定位配置、缓存、预览或生命周期问题 | Bugfix | 已关闭；候选脱敏日志复核通过 |
| V106-DOC-001 | 事实文档 | Minor | 已确认 | README、英文 README、Windows 工程 README 与 current 仍停留在 v1.0.4/v1.0.5 开发口径 | 用户与贡献者看到错误版本状态 | 直接修文档 | 已更新为公开 v1.0.5 / 开发 v1.0.6 |
| V106-ENV-001 | 环境补证 | Suggestion | 待确认 | Windows 10 未复验 | 无法证明目标系统真实冒烟 | 继续验证 | 有环境后补证 |
| V106-ENV-002 | 环境补证 | Suggestion | 待确认 | 真实多显示器未复验 | 不影响主题修复范围；显示器组合证据仍不完整 | 继续验证 | 延续既有边界 |

## V106-BUG-001：主题双持久来源与首帧漂移

### 复现事实

1. v1.0.5 正式发布包保存配置为 `theme_mode=light`。
2. 启动后 Mini 与首次打开的 Workbench/日历显示深色。
3. 打开 Settings 并执行一次“无变化保存”。
4. 日志记录 `theme.preview_applied theme=light reason=unchanged`。
5. Workbench 随后切换为浅色。

### 根因证据

- `apps/windows-v1/index.html` 在 React 之前只读取 `localStorage["lmm.theme"]`。
- `apps/windows-v1/src/theme.ts` 的 `applyTheme()` 每次都写 `localStorage`。
- Mini 与 Workbench 不加载配置草稿，因此没有权威配置纠正自身。
- Settings/Wizard 异步读到配置后会调用 `applyTheme()`，并在所有保存结果上广播主题。
- 主题监听器延迟 3000ms 注册；注册成功后没有读取当前主题快照。
- Rust 窗口 `shown/hidden` 路径只处理生命周期，没有主题 bootstrap 或会话重放。

### 修复验收

- 权威配置为浅色且缓存为深色时，四窗口首帧均为浅色。
- 权威配置为深色且缓存为浅色时，四窗口首帧均为深色。
- 新窗口晚创建、监听晚注册、隐藏恢复均能读取当前会话，不依赖历史广播。
- 无变化保存不再承担初始化纠正。
- 取消、失败和异常退出不会把 preview 变成持久主题。

## V106-RISK-001：配置草稿 hydration 竞态

### 当前事实

- `useConfigDraft()` 先以默认配置创建 `draft/persisted`，再异步读取 Rust 配置。
- Settings 与 Wizard 当前没有在 `loading=true` 时完全阻止写配置交互。
- 尚无真实用户配置被默认值覆盖的证据。

### 必须先补的 characterization

1. 人工延迟 `read_configuration`。
2. 验证加载期间所有保存和重置入口不可提交。
3. 模拟读取失败，确认不会写入默认配置。
4. 模拟加载完成前关闭、取消和重新聚焦。
5. 比对操作前后 `config.json` SHA256。

满足上述门禁后，才可将其标记为关闭；不得把“未稳定复现”直接写成通过。

## V106-DOC-001：当前文档门禁仍验证旧事实

- `scripts/verify_v10_docs.ps1` 本轮检查 94 份文档并返回通过。
- 该脚本的目标仍是证明“v1.0.4 已发布、v1.0.5 开发中”，与当前公开 v1.0.5 Stable 的事实不一致。
- v1.0.6 必须同时更新文档内容与门禁断言，不能只改 README 后继续让旧断言通过。

## 同源但不另立产品需求的风险

| 风险 | 证据状态 | 处理方式 |
| --- | --- | --- |
| 未保存 preview 写入 localStorage，异常退出后可能成为下次首帧 | 高度可能 | 与 V106-BUG-001 一并关闭 |
| 懒创建窗口错过既往 preview 事件 | 高度可能 | 监听注册后读取 ThemeSession 快照 |
| hidden/shown 后重复注册 listener | 待确认 | 增加 listener 代际与唯一性测试 |
| 非法主题配置在四窗口回退不一致 | 待确认 | Rust 与 WebView 共同使用同一解析合同 |

## 最小 Bugfix 范围

| 模块 | 必须完成 | 不得扩展 |
| --- | --- | --- |
| Rust/Tauri | 提供 persisted/preview 权威主题快照；窗口显示前可应用；增加脱敏日志 | 不重写窗口管理或 Dashboard 所有权 |
| WebView bootstrap | 首帧消费权威主题；失败安全回退；不让旧缓存覆盖配置 | 不重做 HTML/CSS 设计 |
| React theme | preview/commit/revert 与长期持久化解耦；支持快照收敛 | 不引入新的全局状态框架 |
| Config draft | hydration 前禁止提交；失败保留旧配置 | 不改变 config schema 和工资/日历字段 |
| Tests | 首帧、四窗口、晚监听、懒创建、事务、异常退出、隐藏恢复 | 不进行全量 UI 自动化 |
| Docs | 当前版本与 Release 事实收口 | 不改写 v1.0.5 历史结论 |

## 回归与发布门禁

### P0：v1.0.6 必须关闭

- `V106-BUG-001` 四窗口首帧一致性。
- `V106-RISK-001` hydration 期间不可误保存。
- `V106-TEST-001` 行为门禁进入正式聚合验证。
- 取消、失败、无变化、异常退出后的配置与主题事务安全。
- 干净提交构建、候选身份与包体验证。

### P1：同批完成

- `V106-LOG-001` 主题初始化与应用日志。
- `V106-DOC-001` 公开事实文档。

### 环境补证

- Windows 10：有受控设备或 VM 后补真实 Zip 冒烟。
- 多显示器：延续既有延期结论，不新增功能范围。

## 决策

- 可直接进入 Bugfix：**是**。
- 需要 `/idea`：**否**。
- 需要完整 `/prd`：**否**。
- 依据：目标行为已由 v1.0.2 PRD 明确定义；当前是实现偏差、同源初始化风险和测试漏检。
- 当前是否具备进入发布收口：**是**。rebase 前干净候选已经通过聚合门禁、包体验证和真实 Windows 最小主题冒烟，项目所有者已授权发布；正式附件必须从 PR 合并后的干净 `main` 重建。
