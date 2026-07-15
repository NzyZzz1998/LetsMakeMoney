# LetsMakeMoney iOS v0.1 Beta 进度看板

## 追踪信息

- 当前状态：M3 完成 17/17，M3R 完成 14/14；M4 已完成 5/17，小/中/大组件已实现今日金额、明确工作状态、工作进度及降级态，大组件额外展示今日安排
- 目标版本：`ios-v0.1-beta`
- 目标分支：`ios-main`（独立 worktree；M0 基线已推送至远端 `test`）
- 来源 PRD：`doc/releases/ios-v0.1/prd.md`
- 对应实施计划：`doc/releases/ios-v0.1/dev_plan_ios-v0.1.md`
- 对应开发日志：`doc/logs/dev_log_ios-v0.1.md`
- 高保真原型：`doc/prototypes/ios-v0.1/index.html`
- 下游承接：实际实现、Acceptance、Apple Beta 发布
- 当前事实源：本文
- 最后更新：2026-07-15

## 版本目标

完成 iPhone/iPad App、Widget、Live Activity、Apple Watch 和复杂功能的完整首版，以统一工资计算、午休暂停、真实工作日和可靠本地配置为事实源。

## 进入开发授权

- PRD 与原型：已确认。
- 开发承接文档：已确认。
- 业务实现：M0-M3 与 M3R 已完成；M3 App、Windows 门禁、iPad 真机主路径、Preview 矩阵和 UI 自动化源码入口均已收口。GitHub macOS 已完成导出 App scheme、G3 平台 probe，以及正式 App 与内嵌 Widget Extension 的 Simulator SDK 编译。Widget 现已只读接入 App Group 共享快照；完整 families、签名、XCTest 和真机扩展行为仍按 M4-M7 逐项取得。
- 当前环境：Windows + iPad；GitHub macOS runner 已提供 Xcode 16.4、Swift 6.1.2 的 G3 SDK 编译证据。本地仍无 macOS/Xcode，签名、App Group 与真实系统扩展行为不能由 probe 替代。

## 总体进度概览

| 里程碑 | 模块 | 主要 FR | 状态 | 完成度 |
| --- | --- | --- | --- | --- |
| IOS01-M0 | 基线、分支与可行性 | FR-012～FR-014 | 已完成 | 10/10 |
| IOS01-M1 | Schema、节假日与 SalaryCore | FR-001、002、005、014 | 已完成 | 16/16 |
| IOS01-M2 | 配置、安全写入与共享快照 | FR-002、011、013、014 | 已完成 | 14/14 |
| IOS01-M3 | iPhone/iPad App、引导与日历 | FR-003～005、012 | 已完成 | 17/17 |
| IOS01-M3R | 首次引导输入与作息推算返工 | FR-002、003 | 已完成 | 14/14 |
| IOS01-M4 | Widget、Live Activity 与通知 | FR-006、007、010、012 | 进行中 | 5/17 |
| IOS01-M5 | Watch App 与复杂功能 | FR-008、009、012 | 未开始 | 0/14 |
| IOS01-M6 | 跨 Target 一致性与质量 | FR-001～014 | 未开始 | 0/13 |
| IOS01-M7 | 候选构建、真机验收与 Beta | 全部 | 未开始 | 0/15 |

## IOS01-M0 基线、分支与可行性

- [x] IOS01-M0-001 记录 `main` 当前 HEAD、工作区和 Windows 发布身份，建立 Apple 分支基线说明。
- [x] IOS01-M0-002 经用户授权后创建并切换 `ios-main`，确认不覆盖现有未提交修改。
- [x] IOS01-M0-003 建立 `apple/README.md`，说明 Apple 产品线、运行环境和与 Windows 的边界。
- [x] IOS01-M0-004 建立 `apple/`、`shared/salary-schema/v1/`、`scripts/apple/` 空目录契约与保留文件。
- [x] IOS01-M0-005 定义 Swift/Xcode/SDK 版本策略和最低系统版本，不伪造本机不可验证结果。
- [x] IOS01-M0-006 定义 bundle ID、App Group、Targets、Schemes 和 entitlement 占位规则。
- [x] IOS01-M0-007 在 iPad Swift Playgrounds 验证 App 与 Swift Package 能力，记录实际截图和限制。
- [x] IOS01-M0-008 明确从 Playgrounds 原型迁移到 Xcode workspace 的单一代码事实源方案。
- [x] IOS01-M0-009 建立 Windows 可运行的 schema、文档、UTF-8、秘密与绝对路径只读检查入口。
- [x] IOS01-M0-010 运行 G0 检查并更新 progress/dev log；未获得的 G1-G4 证据保持待补证。

## IOS01-M1 Schema、节假日与 SalaryCore

- [x] IOS01-M1-001 编写 `salary-schema v1` 字段、版本、未知字段和错误契约说明。
- [x] IOS01-M1-002 创建机器可读 JSON Schema。
- [x] IOS01-M1-003 创建最小合法、完整合法、边界合法和非法配置样例。
- [x] IOS01-M1-004 建立跨端测试向量结构和向量身份字段。
- [x] IOS01-M1-005 收集 2025 年官方节假日/调休数据并记录来源。
- [x] IOS01-M1-006 收集 2026 年官方节假日/调休数据并记录来源。
- [x] IOS01-M1-007 收集 2027 年官方节假日/调休数据并记录来源；未发布时不得猜测。
- [x] IOS01-M1-008 为节假日数据建立版本、校验和、范围与越界回退测试。
- [x] IOS01-M1-009 建立 `SalaryCore` Swift Package 骨架与公开 API 契约。
- [x] IOS01-M1-010 实现工作日规则优先级：覆盖 > 法定数据 > 周休规则。
- [x] IOS01-M1-011 实现双休、单休和大小周锚点推导。
- [x] IOS01-M1-012 实现月工作日、日薪和标准小时工资计算。
- [x] IOS01-M1-013 实现午休扣除、今日有效工作秒数、收入、进度和状态。
- [x] IOS01-M1-014 实现本月累计与当前月配置重算策略。
- [x] IOS01-M1-015 完成边界、闰年、时区、无效配置、舍入和覆盖单元测试。
- [x] IOS01-M1-016 运行 Swift 与跨端向量验证，满足 G1 后记录证据。

## IOS01-M2 配置、安全写入与共享快照

- [x] IOS01-M2-001 定义 `AppConfiguration` Codable 模型与默认值。
- [x] IOS01-M2-002 定义 `SalarySnapshot`、`ActivityState` 和 `WatchSnapshot`。
- [x] IOS01-M2-003 实现配置字段级校验与结构化错误。
- [x] IOS01-M2-004 实现配置草稿、取消和关闭不污染有效配置。
- [x] IOS01-M2-005 实现无变化保存判断与反馈状态。
- [x] IOS01-M2-006 实现临时写入、读回校验和原子替换。
- [x] IOS01-M2-007 实现写入失败后保留输入与最后有效配置。
- [x] IOS01-M2-008 实现损坏配置备份、默认恢复和用户提示。
- [x] IOS01-M2-009 实现 schema 版本迁移和未知字段兼容。
- [x] IOS01-M2-010 建立 App Group 容器接口与无 entitlement 降级错误。
- [x] IOS01-M2-011 实现 Widget/Activity 只读快照更新与并发读取保护。
- [x] IOS01-M2-012 建立结构化日志、轮换和隐私脱敏。
- [x] IOS01-M2-013 建立 String Catalog 与用户文案静态扫描。
- [x] IOS01-M2-014 运行保存/损坏/迁移/并发/App Group 测试并记录证据。

## IOS01-M3 iPhone/iPad App、引导与日历

- [x] IOS01-M3-001 建立 App 入口、依赖注入和导航状态。
- [x] IOS01-M3-002 建立暖色浅色/深色设计 Token 和共享控件状态。
- [x] IOS01-M3-003 实现引导步骤一：月薪、币种、休息制度和大小周锚点。
- [x] IOS01-M3-004 实现引导步骤二：上下班、午休和标准有效工时。
- [x] IOS01-M3-005 实现引导步骤三：工作日、日薪和今日示例预览。
- [x] IOS01-M3-006 实现引导下一步、上一步、取消、关闭、失败和重试。
- [x] IOS01-M3-007 实现 iPhone 今日页金额、状态、进度、月累计和今日安排。
- [x] IOS01-M3-008 实现 iPhone 今日/日历底部导航和设置入口。
- [x] IOS01-M3-009 实现日历月份、工作/休息/法定/调休/覆盖状态。
- [x] IOS01-M3-010 实现日期覆盖编辑、确认、保存、删除和取消。
- [x] IOS01-M3-011 实现设置页工资、作息、通知和系统状态。
- [x] IOS01-M3-012 实现 iPad 横屏侧栏与双栏今日页，保留今日安排。
- [x] IOS01-M3-013 实现 iPad 竖屏和窄分屏紧凑布局。
- [x] IOS01-M3-014 实现未配置、错误、越界、休息日和各工作状态页面。
- [x] IOS01-M3-015 接入动态字体、VoiceOver、高对比度与降低动态效果。
- [x] IOS01-M3-016 完成 SwiftUI Preview 与 UI 自动化矩阵。
- [x] IOS01-M3-017 在 iPhone/iPad 真实设备复测主路径并记录差异。

## IOS01-M3R 首次引导输入与作息推算返工

- [x] IOS01-M3R-001 为月薪编辑文本的零值聚焦、整数输入、两位小数和非法输入补失败测试。
- [x] IOS01-M3R-002 为“本周大周/小周”到既有 `alternatingAnchor` 的转换与反推补测试。
- [x] IOS01-M3R-003 为默认作息推算、零午休、跨日拒绝和 30 分钟步进补测试。
- [x] IOS01-M3R-004 为午休开始/结束双向联动与上下班调整后有效工时重算补测试。
- [x] IOS01-M3R-005 实现金额编辑草稿与规范化，不在编辑中污染有效配置。
- [x] IOS01-M3R-006 实现大小周自然语言选择，并移除锚点日期自由文本入口。
- [x] IOS01-M3R-007 实现系统时间选择与午休时长专用组件，拒绝任意文本。
- [x] IOS01-M3R-008 实现默认作息推算摘要和四时间详细调整。
- [x] IOS01-M3R-009 实现午休双向联动、午休时长推算、上下班调整与有效工时即时重算。
- [x] IOS01-M3R-010 固定中文标题、无文字进度和底部操作区，修复横屏键盘上浮重叠。
- [x] IOS01-M3R-011 更新本地化键、辅助功能标签和错误定位，不显示内部键名。
- [x] IOS01-M3R-012 回归上一步、取消、关闭、完成失败、重试及安全写入语义。
- [x] IOS01-M3R-013 运行 Swift/Python/M3/Playgrounds 导出与文档门禁，记录证据与失效条件。
- [x] IOS01-M3R-014 导出新 iPad 包，完成横竖屏、键盘、金额、大小周、时间推算和保存的定向真机复测。

## IOS01-M4 Widget、Live Activity、通知与快捷操作

- [x] IOS01-M4-001 验证 G3 macOS/Xcode 多 Target 环境；GitHub Actions run `29397574782` 已用 iOS/watchOS Simulator SDK 编译 App、Widget/Activity、Watch probe schemes。
- [x] IOS01-M4-002 创建 Widget Extension 并接入共享快照；XcodeGen 生成正式 App/Extension target，GitHub Actions run `29400350747` 已构建、内嵌并验证 `LetsMakeMoneyWidget.appex`。
- [x] IOS01-M4-003 实现小组件金额与状态；`.systemSmall` 已覆盖今日金额、显式中文状态、未配置、快照不可用与占位状态。
- [x] IOS01-M4-004 实现中组件金额、状态和进度；`.systemMedium` 复用三态投影，显示今日金额、显式状态、百分比与进度条。
- [x] IOS01-M4-005 实现大组件金额、进度和今日安排；作息由 App 配置只读投影到可选共享快照，旧快照缺少作息字段时安全降级。
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
| 本地无 macOS/Xcode | M4-M7、完整 Beta | GitHub macOS 已覆盖正式 App 与 Widget Extension 编译；XCTest、签名、App Group 真机读写和系统扩展行为仍须在 M4-M7 关闭 |
| Windows SwiftPM 符号链接警告 | 本地开发便利性 | Swift 6.3.3 编译与测试通过；未启用开发人员模式导致 `.build/debug` 便捷链接创建失败，不影响 G1 |
| Apple Developer Program/Team ID 未确认 | App Group、Activity、Watch 真机与签名 | 不阻塞纯内核；阻塞 G4 和发布 |
| 2027 官方节假日数据可用性待核实 | 完整离线数据集 | 未有官方数据时标记未覆盖，禁止猜测 |

## 最近验证

- 验证时间：2026-07-15
- 验证对象：M0-M3 合同、SalaryCore、配置/快照、App 状态、引导、日历语义、日期覆盖、M3R 金额/大小周/作息纯逻辑、SwiftUI 源码合同、本地化、Widget 三态投影、大小尺寸布局与反例门禁。
- 验证方式：Python 3.12.8 标准库参考验证、PowerShell 5.1 门禁、Swift 6.3.3 Windows 工具链、MSVC 14.44 与 Windows SDK 10.0.22621.0。
- 结果：Apple/Python 既有合同与参考测试通过，Swift 测试 47/47、本地化验证测试 3/3、M3 源码合同 8/8、Widget Extension 合同 8/8、Playgrounds 导出合同 2/2、M3 反例门禁通过；M1、M2、M3、M4 Windows 正向门禁全部通过。GitHub Actions macOS run `29396376249` 在 HEAD `a5e0b0f` 完成 SalaryCore、源码合同、Playgrounds 导出和 `LetsMakeMoneyAppleSDK` iOS Simulator SDK 编译；run `29397574782` 在 HEAD `7952b40` 完成 G3 App、Widget/Activity 与 Watch probe scheme 编译；run `29400350747` 在 HEAD `fe27cb5` 使用 Xcode 16.4（16F6）生成正式工程并验证最小 Widget；run `29402002179` 在 HEAD `42cf60f` 编译 M4-003 三态小组件；run `29403617023` 在 HEAD `1855715` 编译 M4-004 中组件金额、状态和进度；run `29405142288` 在 HEAD `3d98eda` 编译 M4-005 大组件金额、进度、今日安排及旧快照兼容。正式 Widget 构建均将 `LetsMakeMoneyWidget.appex` 复制到 App 的 `PlugIns`，通过 `ValidateEmbeddedBinary` 与 `BUILD SUCCEEDED`，结论为 `success`。SwiftPM 在未启用 Windows 开发者模式时仍报告 `.build/debug` 符号链接警告，但编译与测试成功。
- R10 包：`build/apple-playgrounds/LetsMakeMoneyM3R10-playgrounds.zip`，SHA256 `19327DC3BCA420EA07C8E1CA3DA04169DF11F1299C002580616CD649990D81E2`；使用自定义底部导航阻止 iPadOS 顶部浮动页签，页面背景填满可用区域，今日状态改为固定中文本地化映射，并为无效月薪增加明确错误提示。包内关键实现与中文资源 5/5 检查通过。
- iPad 证据：R9 在 iPad Pro M4、Swift Playgrounds 4.7 完成完整手动验证；R10 对无效月薪提示、今日中文状态、iPad 竖屏底部导航和横竖屏页面边缘完成定向复测，项目所有者确认全部通过。
- Preview/UI 自动化矩阵：`AppRootView.swift` 已覆盖 iPhone 竖屏、iPad 竖屏/横屏、深色、大字、Settings 和 Onboarding 七类 Preview；`M3SmokeUITests.swift` 已覆盖确定配置下的今日/日历/设置关闭和无配置首次引导。源码矩阵完成，但 Xcode `XCTest` 尚未运行，不写成已通过。
- 调试基线：新增可恢复 Debug Hub；GitHub macOS Apple SDK 工作流支持 `ios-main` Apple 路径自动触发及手动触发，已上传 App、G3 probe、正式工程和 Widget 产品路径日志。正式 Widget target 已通过无签名 Simulator 编译，但该证据不替代签名、XCTest、App Group 真机读写和系统桌面展示。
- 证据状态：M0-M3 与 M3R 的 Windows 合同和 iPad 主路径已收口；G3 Apple SDK 环境门禁及 M4 正式 Widget Extension 编译门禁已通过。小/中/大组件金额、显式状态、进度、未配置与快照不可用分支已实现，大组件已增加今日安排；真实 App Group 读写、系统桌面展示与刷新仍未取得设备证据。锁屏 families、Live Activity、通知、Intent 与 M5 Watch 产品能力尚未实现。
- 失效条件：schema、配置/快照模型、App/SwiftUI 源码、本地化资源、测试或 Swift 工具链版本变化时重测。

## 下一步

1. 进入 `IOS01-M4-006`，实现锁屏 accessory families 与窄宽度降级，并继续复用现有快照和三态投影。
2. 按 M4-007 推进时间线、最后更新时间和过期策略，继续以 GitHub macOS 正式 target 编译为门禁。
3. 正式 Xcode 工程具备 UI Test target 后执行 `M3SmokeUITests`；在此之前继续标记为待执行，不影响已取得的 G3 SDK 环境结论。

## 记录边界

本文只记录状态、最小任务、阻塞、最近验证和下一步。开发过程写入 `doc/logs/dev_log_ios-v0.1.md`；缺陷和 Spike 分别进入独立日志，不在本文堆叠排查流水。
