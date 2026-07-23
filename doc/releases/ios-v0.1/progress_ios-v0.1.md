# LetsMakeMoney iOS v0.1 Beta 进度看板

## 追踪信息

- 当前状态：开发承接完成，待确认进入实施
- 目标版本：`ios-v0.1-beta`
- 目标分支：`ios-main`（尚未创建）
- 来源 PRD：`doc/releases/ios-v0.1/prd.md`
- 对应实施计划：`doc/releases/ios-v0.1/dev_plan_ios-v0.1.md`
- 对应开发日志：`doc/logs/dev_log_ios-v0.1.md`
- 高保真原型：`doc/prototypes/ios-v0.1/index.html`
- 下游承接：实际实现、Acceptance、Apple Beta 发布
- 当前事实源：本文
- 最后更新：2026-07-13

## 版本目标

完成 iPhone/iPad App、Widget、Live Activity、Apple Watch 和复杂功能的完整首版，以统一工资计算、午休暂停、真实工作日和可靠本地配置为事实源。

## 进入开发授权

- PRD 与原型：已确认。
- 开发承接文档：待项目所有者确认。
- 业务实现：未授权开始。
- 当前环境：Windows；无本地 macOS/Xcode，Apple 多 Target 与签名存在后置门禁。

## 总体进度概览

| 里程碑 | 模块 | 主要 FR | 状态 | 完成度 |
| --- | --- | --- | --- | --- |
| IOS01-M0 | 基线、分支与可行性 | FR-012～FR-014 | 未开始 | 0/10 |
| IOS01-M1 | Schema、节假日与 SalaryCore | FR-001、002、005、014 | 未开始 | 0/16 |
| IOS01-M2 | 配置、安全写入与共享快照 | FR-002、011、013、014 | 未开始 | 0/14 |
| IOS01-M3 | iPhone/iPad App、引导与日历 | FR-003～005、012 | 未开始 | 0/17 |
| IOS01-M4 | Widget、Live Activity 与通知 | FR-006、007、010、012 | 未开始 | 0/17 |
| IOS01-M5 | Watch App 与复杂功能 | FR-008、009、012 | 未开始 | 0/14 |
| IOS01-M6 | 跨 Target 一致性与质量 | FR-001～014 | 未开始 | 0/13 |
| IOS01-M7 | 候选构建、真机验收与 Beta | 全部 | 未开始 | 0/15 |

## IOS01-M0 基线、分支与可行性

- [ ] IOS01-M0-001 记录 `main` 当前 HEAD、工作区和 Windows 发布身份，建立 Apple 分支基线说明。
- [ ] IOS01-M0-002 经用户授权后创建并切换 `ios-main`，确认不覆盖现有未提交修改。
- [ ] IOS01-M0-003 建立 `apple/README.md`，说明 Apple 产品线、运行环境和与 Windows 的边界。
- [ ] IOS01-M0-004 建立 `apple/`、`shared/salary-schema/v1/`、`scripts/apple/` 空目录契约与保留文件。
- [ ] IOS01-M0-005 定义 Swift/Xcode/SDK 版本策略和最低系统版本，不伪造本机不可验证结果。
- [ ] IOS01-M0-006 定义 bundle ID、App Group、Targets、Schemes 和 entitlement 占位规则。
- [ ] IOS01-M0-007 在 iPad Swift Playgrounds 验证 App 与 Swift Package 能力，记录实际截图和限制。
- [ ] IOS01-M0-008 明确从 Playgrounds 原型迁移到 Xcode workspace 的单一代码事实源方案。
- [ ] IOS01-M0-009 建立 Windows 可运行的 schema、文档、UTF-8、秘密与绝对路径只读检查入口。
- [ ] IOS01-M0-010 运行 G0 检查并更新 progress/dev log；未获得的 G1-G4 证据保持待补证。

## IOS01-M1 Schema、节假日与 SalaryCore

- [ ] IOS01-M1-001 编写 `salary-schema v1` 字段、版本、未知字段和错误契约说明。
- [ ] IOS01-M1-002 创建机器可读 JSON Schema。
- [ ] IOS01-M1-003 创建最小合法、完整合法、边界合法和非法配置样例。
- [ ] IOS01-M1-004 建立跨端测试向量结构和向量身份字段。
- [ ] IOS01-M1-005 收集 2025 年官方节假日/调休数据并记录来源。
- [ ] IOS01-M1-006 收集 2026 年官方节假日/调休数据并记录来源。
- [ ] IOS01-M1-007 收集 2027 年官方节假日/调休数据并记录来源；未发布时不得猜测。
- [ ] IOS01-M1-008 为节假日数据建立版本、校验和、范围与越界回退测试。
- [ ] IOS01-M1-009 建立 `SalaryCore` Swift Package 骨架与公开 API 契约。
- [ ] IOS01-M1-010 实现工作日规则优先级：覆盖 > 法定数据 > 周休规则。
- [ ] IOS01-M1-011 实现双休、单休和大小周锚点推导。
- [ ] IOS01-M1-012 实现月工作日、日薪和标准小时工资计算。
- [ ] IOS01-M1-013 实现午休扣除、今日有效工作秒数、收入、进度和状态。
- [ ] IOS01-M1-014 实现本月累计与当前月配置重算策略。
- [ ] IOS01-M1-015 完成边界、闰年、时区、无效配置、舍入和覆盖单元测试。
- [ ] IOS01-M1-016 运行 Swift 与跨端向量验证，满足 G1 后记录证据。

## IOS01-M2 配置、安全写入与共享快照

- [ ] IOS01-M2-001 定义 `AppConfiguration` Codable 模型与默认值。
- [ ] IOS01-M2-002 定义 `SalarySnapshot`、`ActivityState` 和 `WatchSnapshot`。
- [ ] IOS01-M2-003 实现配置字段级校验与结构化错误。
- [ ] IOS01-M2-004 实现配置草稿、取消和关闭不污染有效配置。
- [ ] IOS01-M2-005 实现无变化保存判断与反馈状态。
- [ ] IOS01-M2-006 实现临时写入、读回校验和原子替换。
- [ ] IOS01-M2-007 实现写入失败后保留输入与最后有效配置。
- [ ] IOS01-M2-008 实现损坏配置备份、默认恢复和用户提示。
- [ ] IOS01-M2-009 实现 schema 版本迁移和未知字段兼容。
- [ ] IOS01-M2-010 建立 App Group 容器接口与无 entitlement 降级错误。
- [ ] IOS01-M2-011 实现 Widget/Activity 只读快照更新与并发读取保护。
- [ ] IOS01-M2-012 建立结构化日志、轮换和隐私脱敏。
- [ ] IOS01-M2-013 建立 String Catalog 与用户文案静态扫描。
- [ ] IOS01-M2-014 运行保存/损坏/迁移/并发/App Group 测试并记录证据。

## IOS01-M3 iPhone/iPad App、引导与日历

- [ ] IOS01-M3-001 建立 App 入口、依赖注入和导航状态。
- [ ] IOS01-M3-002 建立暖色浅色/深色设计 Token 和共享控件状态。
- [ ] IOS01-M3-003 实现引导步骤一：月薪、币种、休息制度和大小周锚点。
- [ ] IOS01-M3-004 实现引导步骤二：上下班、午休和标准有效工时。
- [ ] IOS01-M3-005 实现引导步骤三：工作日、日薪和今日示例预览。
- [ ] IOS01-M3-006 实现引导下一步、上一步、取消、关闭、失败和重试。
- [ ] IOS01-M3-007 实现 iPhone 今日页金额、状态、进度、月累计和今日安排。
- [ ] IOS01-M3-008 实现 iPhone 今日/日历底部导航和设置入口。
- [ ] IOS01-M3-009 实现日历月份、工作/休息/法定/调休/覆盖状态。
- [ ] IOS01-M3-010 实现日期覆盖编辑、确认、保存、删除和取消。
- [ ] IOS01-M3-011 实现设置页工资、作息、通知和系统状态。
- [ ] IOS01-M3-012 实现 iPad 横屏侧栏与双栏今日页，保留今日安排。
- [ ] IOS01-M3-013 实现 iPad 竖屏和窄分屏紧凑布局。
- [ ] IOS01-M3-014 实现未配置、错误、越界、休息日和各工作状态页面。
- [ ] IOS01-M3-015 接入动态字体、VoiceOver、高对比度与降低动态效果。
- [ ] IOS01-M3-016 完成 SwiftUI Preview 与 UI 自动化矩阵。
- [ ] IOS01-M3-017 在 iPhone/iPad 真实设备复测主路径并记录差异。

## IOS01-M4 Widget、Live Activity、通知与快捷操作

- [ ] IOS01-M4-001 验证 G3 macOS/Xcode 多 Target 环境；未通过不得继续标完成。
- [ ] IOS01-M4-002 创建 Widget Extension 并接入共享快照。
- [ ] IOS01-M4-003 实现小组件金额与状态。
- [ ] IOS01-M4-004 实现中组件金额、状态和进度。
- [ ] IOS01-M4-005 实现大组件金额、进度和今日安排。
- [ ] IOS01-M4-006 实现锁屏 accessory families 与窄宽度降级。
- [ ] IOS01-M4-007 实现 Widget 时间线、最后更新时间、过期和未配置状态。
- [ ] IOS01-M4-008 定义 Activity Attributes、ContentState 和版本兼容。
- [ ] IOS01-M4-009 实现工作、午休、完成和提前结束状态机。
- [ ] IOS01-M4-010 实现锁屏 Live Activity 布局。
- [ ] IOS01-M4-011 实现灵动岛最小、紧凑和展开布局。
- [ ] IOS01-M4-012 实现时间锚点/费率推导，禁止依赖后台秒级定时器。
- [ ] IOS01-M4-013 实现通知授权、拒绝、撤销和系统设置跳转。
- [ ] IOS01-M4-014 实现 App/Widget/控制中心/App Intent 手动启停入口。
- [ ] IOS01-M4-015 验证通知拒绝不禁用手动 Live Activity。
- [ ] IOS01-M4-016 完成快照、时间线、状态机、权限和错误测试。
- [ ] IOS01-M4-017 在 iPhone 真机复测锁屏、灵动岛、限流和自动结束。

## IOS01-M5 Apple Watch 与复杂功能

- [ ] IOS01-M5-001 创建 Watch App target 并接入共享模型。
- [ ] IOS01-M5-002 建立 WatchConnectivity 会话和消息版本契约。
- [ ] IOS01-M5-003 实现今日收入、进度、状态、安排和同步时间。
- [ ] IOS01-M5-004 实现剩余时间、收入、进度三种默认指标切换。
- [ ] IOS01-M5-005 实现工作态距离下班和午休态距离复工。
- [ ] IOS01-M5-006 实现启动/结束 Activity 请求与 iPhone 确认。
- [ ] IOS01-M5-007 实现请求超时、失败和取消，不做乐观成功。
- [ ] IOS01-M5-008 实现离线快照、禁用操作和最近同步提示。
- [ ] IOS01-M5-009 实现重连同步、跨日和重启恢复。
- [ ] IOS01-M5-010 创建 watchOS Widget Extension。
- [ ] IOS01-M5-011 实现常用复杂功能 families 与 Smart Stack。
- [ ] IOS01-M5-012 实现指标 App Intent 和打开对应 Watch 页面。
- [ ] IOS01-M5-013 完成连接、编码、重试、离线与跨日自动测试。
- [ ] IOS01-M5-014 在 Series 10 真机复测 App、常亮、复杂功能和 Smart Stack。

## IOS01-M6 跨 Target 一致性、体验与隐私

- [ ] IOS01-M6-001 建立跨 Target 固定配置/时刻快照比较器。
- [ ] IOS01-M6-002 验证 App、Widget、Activity、Watch 金额一致。
- [ ] IOS01-M6-003 验证 App、Widget、Activity、Watch 状态和进度一致。
- [ ] IOS01-M6-004 验证配置版本、节假日版本、快照身份与最近同步时间。
- [ ] IOS01-M6-005 扫描硬编码用户文案、未登记字符串和乱码。
- [ ] IOS01-M6-006 扫描日志、诊断和错误中的用户路径与敏感信息。
- [ ] IOS01-M6-007 完成 App 全页面浅色/深色矩阵。
- [ ] IOS01-M6-008 完成 Widget/Activity/Watch 浅色/深色/常亮矩阵。
- [ ] IOS01-M6-009 完成动态字体、VoiceOver、高对比度和降低动态效果矩阵。
- [ ] IOS01-M6-010 完成时区、跨日、锁屏、重启和低电量回归。
- [ ] IOS01-M6-011 更新隐私、已知限制、构建和人工验证文档。
- [ ] IOS01-M6-012 回归原型关键交互与正式文案一致性。
- [ ] IOS01-M6-013 运行 M6 全量门禁并记录证据失效条件。

## IOS01-M7 候选构建、真机验收与 Beta 收口

- [ ] IOS01-M7-001 确认 Apple Developer Program、Team ID 和 G4 签名门禁。
- [ ] IOS01-M7-002 锁定分支、HEAD、Xcode/SDK、依赖、版本号和构建号。
- [ ] IOS01-M7-003 生成候选 archive、导出包、manifest 和 SHA256。
- [ ] IOS01-M7-004 验证候选包仅包含预期 Target、权限、许可和资源。
- [ ] IOS01-M7-005 在 iPhone 16 Pro Max 完成 App 与设置主路径。
- [ ] IOS01-M7-006 在 iPhone 完成 Widget、通知、Live Activity 与灵动岛。
- [ ] IOS01-M7-007 在 iPad Pro M4 完成横竖屏、分屏与 Widget。
- [ ] IOS01-M7-008 在 Apple Watch Series 10 完成在线、离线、重连和复杂功能。
- [ ] IOS01-M7-009 验证配置保存失败、损坏恢复、迁移和跨 Target 一致性。
- [ ] IOS01-M7-010 验证跨日、时区、锁屏、重启、低电量和系统限流。
- [ ] IOS01-M7-011 完成人工辅助功能与文案验收。
- [ ] IOS01-M7-012 更新 verification、manual verification、release notes 和已知限制。
- [ ] IOS01-M7-013 执行 Acceptance，未执行项保持待补证。
- [ ] IOS01-M7-014 修复发布阻塞缺陷并对受影响证据定向复验。
- [ ] IOS01-M7-015 Acceptance 通过后等待用户授权提交、推送、tag 与 Beta 发布。

## 当前阻塞

| 阻塞/限制 | 影响面 | 当前结论 |
| --- | --- | --- |
| 本地无 macOS/Xcode | M4-M7、完整 Beta | 不阻塞 M0/M1；M4 前必须解决 |
| Apple Developer Program/Team ID 未确认 | App Group、Activity、Watch 真机与签名 | 不阻塞纯内核；阻塞 G4 和发布 |
| `ios-main` 尚未创建 | 实施隔离 | 需在开始 M0 时单独授权创建，当前不擅自切分支 |
| 2027 官方节假日数据可用性待核实 | 完整离线数据集 | 未有官方数据时标记未覆盖，禁止猜测 |

## 最近验证

- 验证时间：2026-07-13
- 验证对象：`doc/prototypes/ios-v0.1/index.html`
- 验证方式：Playwright/Edge，桌面与 390px 移动视口；逐项点击设置、日期调整、iPad 导航、系统状态、Watch 离线与三步引导。
- 结果：交互通过；控制台错误 0；横向溢出 0；今日/日历底部导航位置一致。
- 证据状态：新测。
- 失效条件：原型 DOM、样式或交互脚本变化时重测。

## 下一步

1. 项目所有者确认开发承接文档。
2. 获得明确实施授权后，只执行 `IOS01-M0-001` 至 `IOS01-M0-010`。
3. M0 结束后停下复核环境门禁，再进入 SalaryCore。

## 记录边界

本文只记录状态、最小任务、阻塞、最近验证和下一步。开发过程写入 `doc/logs/dev_log_ios-v0.1.md`；缺陷和 Spike 分别进入独立日志，不在本文堆叠排查流水。
