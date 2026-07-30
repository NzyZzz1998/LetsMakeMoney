# LetsMakeMoney 架构优化变更记录

## 1. 基线与边界

- 分支：`main`
- 优化起点：`eb57e0b3af726f552afe68acccaa927345714da9`
- 产品基线：Windows v1.0.3 Stable
- 原则：不重写、不删除能力、不改变收入与日历口径、不无迁移修改用户配置。
- 本轮没有提交、推送、打 tag、创建 Release 或修改 GitHub 设置。

## 2. 已实施切片

### A01 前端运行时适配层

**为什么改**

React 组件和状态模型直接依赖 Tauri API，浏览器预览与桌面运行时分支散落，导致测试替换和错误语义不统一。

**改了什么**

- 新增 `src/runtime/appRuntime.ts`。
- 统一 `invoke`、`emit`、`listen`。
- 浏览器环境使用稳定的 `desktop_runtime_unavailable:<operation>` 错误。
- 主题、配置、Dashboard、窗口和支持能力通过服务消费运行时。

**收益**

- UI 与 Tauri 传输协议解耦。
- 可注入假运行时做行为测试。
- 新增桌面命令时有单一适配入口。

**回滚**

服务层仍保持原命令名和参数，必要时可逐服务恢复直接调用。

### A02 配置领域模型与版本合同

**为什么改**

配置类型、默认值、归一化、校验和 React hook 混在同一文件，难以复用和测试。

**改了什么**

- 新增 `src/domain/configuration.ts` 与 `src/domain/theme.ts`。
- `configModel.ts` 只管理草稿、反馈和 React 生命周期。
- Rust 使用 `CURRENT_CONFIG_VERSION = 8` 与显式迁移版本集合。
- 增加迁移分发测试，保留 v5、v6、v7 到 v8 的兼容路径。

**收益**

- 配置规则成为纯函数。
- UI 不再拥有配置合同。
- 新字段可以先定义迁移，再进入界面。

**回滚**

磁盘格式仍为 v8，既有配置和备份策略不变。

### A03 前端服务边界

**为什么改**

组件同时知道命令名、参数结构、错误处理和 UI 状态，窗口间更新也容易遗漏。

**改了什么**

- 新增 `configurationService`、`dashboardService`、`windowService`、`supportService`。
- `model.ts` 通过 Dashboard 服务访问收入和日历命令。
- 日期调整成功后统一发布 `lmm://configuration-updated`。
- App 与 Mini 使用语义化窗口方法，不再直接调用 Tauri。

**收益**

- 命令协议集中。
- 日期调整可立即驱动其他窗口重新加载权威配置。
- 服务可独立测试成功、失败和浏览器降级。

**回滚**

未改变任何 Rust command 名称或 payload。

### A04 UI 与交互切片

**为什么改**

`App.tsx` 同时包含窗口壳、拖动算法、Mini 视图和所有业务页面，修改任何一处都会扩大回归面。

**改了什么**

- 提取 `components/WindowFrame.tsx`。
- 提取 `features/mini/MiniWindow.tsx`。
- 提取 `hooks/useWindowDrag.ts`。
- 提取 `utils/presentationFormatters.ts`。
- 保留 Workbench、Settings、Wizard 的原结构，等待更多 characterization tests 后再拆。

**收益**

- 拖动只有一份实现。
- Mini 可单独演进和验收。
- `App.tsx` 减少约 390 行内联职责。

**回滚**

组件 props 保留现有窗口行为，未引入新状态库。

### A05 TimeService

**为什么改**

业务组件直接创建系统时间，跨夜、睡眠恢复和固定时间测试难以统一。

**改了什么**

- 新增 `TimeService`、`SystemTimeService`、`FixedTimeService`。
- App 的“今天”和大小周锚点改为消费 `systemTime`。
- 日期、月份和时长格式化集中为纯函数。

**收益**

- 可用固定时钟验证日期边界。
- 业务页面不再直接依赖 `new Date()` 获取当前时间。

**回滚**

默认实现仍使用本机系统时间，不改变用户可见结果。

### A06 Rust 配置 Repository 与 Service

**为什么改**

Tauri command 直接持有锁、读写文件并更新运行时状态，且 Mini 位置延迟写入可能覆盖刚保存的新配置。

**改了什么**

- 新增 `repositories::ConfigurationRepository`。
- 新增 `services::configuration_service`。
- command 仅组装路径、记录日志和转换结果。
- Mini 位置保存使用持锁的最新运行时快照，事务完成前不允许并发配置保存穿越。

**收益**

- 文件持久化可替换、可模拟失败。
- 保存失败保证磁盘和运行时旧值不变。
- 关闭了“延迟位置快照覆盖新设置”的竞态风险。

**回滚**

仍复用原 `config::save_transactional` 和备份语义。

### A07 Rust 收入应用服务与命令模块

**为什么改**

收入、日历 command 与 Windows 生命周期混在 `lib.rs`，传输层和领域调用边界不清晰。

**改了什么**

- 新增 `models::income::TodayIncomeRequest`。
- 新增 `services::IncomeService`。
- 新增 `commands::income`。
- 五个收入和日历 command 从 `lib.rs` 移出，命令名及参数保持不变。

**收益**

- Tauri command 只负责参数和错误日志。
- 现有 Rust Domain 成为唯一计算权威。
- 后续时薪或多收入模式可扩展 Domain，而不是在 UI 叠加条件。

**回滚**

invoke handler 仍注册相同 command，前端无协议迁移。

### A08 Calendar Provider

**为什么改**

中国大陆日历加载与领域入口绑定，未来增加来源或地区会迫使业务层认识数据文件。

**改了什么**

- 新增 `CalendarProvider` trait。
- 新增 `EmbeddedChinaHolidayProvider`。
- 既有 facade 委托 Provider，不增加在线服务或新国家。

**收益**

- 数据来源可替换。
- 现有收入 Domain 不依赖具体日历载体。

**回滚**

默认实现仍加载当前内置、哈希校验的年度数据。

### A09 架构门禁与工具解析

**为什么改**

历史测试依赖代码所在文件而非行为所有者；Cargo 查找依赖单一机器环境。

**改了什么**

- 新增四组前端行为测试、结构门禁和聚合脚本。
- 历史 M1-M6 与 v1.0.1/v1.0.2 门禁改为扫描新的责任边界。
- Rust 生产代码的零宠物扫描改为递归覆盖子模块。
- Cargo 支持 `LMM_CARGO`、`LMM_CARGO_HOME`、`LMM_RUSTUP_HOME`。

**收益**

- 后续提取文件不会无故打断发布门禁。
- 新模块不会成为安全扫描盲区。
- 外部环境可显式提供 Rust 工具链。

## 3. 当前完成状态

| 优先级 | 内容 | 状态 |
| --- | --- | --- |
| P0 | 前后端边界、收入应用服务、配置领域与迁移合同 | 已完成 |
| P1 | Tauri 服务层、TimeService、关键窗口/交互切片 | 已完成 |
| P1 | 跨 WebView 单一全局 Store | 暂缓，现有数据不足以证明收益大于迁移风险 |
| P1 | Windows 生命周期整体拆分 | 暂缓，先保留稳定 composition root |
| P2 | Calendar Provider | 已完成最小合同 |
| P2 | Growth/Achievement | 仅完成设计边界，未实现 |
| P2 | AI Service | 仅完成只读端口设计，未接入 SDK |

## 4. 数据与兼容结论

- 配置版本仍为 v8。
- 现有配置路径、备份文件、日志目录和用户数据格式不变。
- 收入、工作日、日期调整、跨夜、尾差和日历优先级公式不变。
- Tauri command 名称和 payload 不变。
- Windows 窗口标签、托盘命令和关闭隐藏行为不变。

## 5. 后续切片建议

1. 为 Workbench、Settings、Wizard 增加行为刻画测试后再分别提取。
2. 为 Windows lifecycle command 建立通知区、隐藏/恢复和 DPI 行为门禁，再拆 `lib.rs`。
3. 只有多窗口测量再次证明重复同步成本显著时，才评估跨 WebView 共享快照。
4. Growth 先使用领域事件生成只读 Daily Summary，不直接改配置。
5. AI 仅消费脱敏快照；写操作必须经用户确认和现有 Service。

## 6. 最终验证记录

验证日期：2026-07-30。

| 验证项 | 结果 |
| --- | --- |
| `scripts/verify_architecture.ps1` | 通过 |
| 前端运行时行为测试 | 15/15 通过 |
| 配置领域行为测试 | 10/10 通过 |
| Desktop Service 行为测试 | 21/21 通过 |
| 呈现纯函数行为测试 | 18/18 通过 |
| 架构结构门禁 | 22/22 通过 |
| 工具链解析测试 | 2/2 通过 |
| TypeScript strict：`tsc --noEmit` | 通过 |
| Rust 单元测试 | 46/46 通过 |
| `cargo clippy --all-targets -- -D warnings` | 通过 |
| `cargo fmt --check` | 通过 |
| v1.0-v1.0.3 聚合验证 | 通过 |
| v1.0 历史 M0-M6 门禁 | 通过 |
| v1.0.1、v1.0.2、v1.0.3 专项门禁 | 通过 |
| 文档 UTF-8 与乱码扫描 | 通过 |
| `git diff --check` | 通过 |

工作区提供的 Node 运行时没有 `npm` 可执行文件，因此本机使用
`pnpm run test` 执行 `package.json` 中同一条测试入口，结果通过。这是执行
环境差异，不是代码或脚本失败；外部开发说明仍以 `npm ci` 和 `npm test`
作为标准入口。

变更实现阶段没有重新执行真实 Windows GUI、通知区和多 DPI 人工验收；
随后已按 `architecture-acceptance.md` 完成架构范围内的独立 GUI 验收。
通知区、多 DPI、睡眠恢复和长期运行等发布级项目仍未重复执行，下一次发布
候选仍应按既有发布门禁完成系统级验收。

## 7. 提交前代码审查补充

提交前审查额外关闭了三处窄范围稳定性问题：

1. 桌面配置更新只发送一次 Tauri 广播，避免当前窗口同时消费 DOM 事件与
   Tauri 事件而重复执行权威同步；原生广播失败时仅回退当前窗口 DOM 事件。
2. 异步 Tauri 监听器即使在 React effect 已卸载后才完成注册，也会立即执行
  晚到的 unlisten，避免窗口快速关闭时残留订阅。
3. Mini 错误态的“检查设置”和“重试”与主入口统一使用拖动点击抑制，避免
   从交互控件起拖后在 pointer up 时误执行命令。

以上修正保持 Tauri command、配置格式、窗口标签和用户可见文案不变；架构
行为测试、v1.0 M3 拖动门禁以及 v1.0-v1.0.3 聚合回归均已重新通过。
