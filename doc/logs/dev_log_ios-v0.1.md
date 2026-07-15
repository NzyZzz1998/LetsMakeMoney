# LetsMakeMoney iOS v0.1 Beta 开发日志

> 本文记录开发过程、关键决策、异常处理和验证结果。它不替代 `progress_ios-v0.1.md`；progress 只保留状态看板和最小任务 checklist。

## 基本信息

- 版本：`ios-v0.1-beta`
- 目标分支：`ios-main`（独立 worktree；M0 基线曾推送至远端 `test`，M1-M3 由本批 `ios-main` 收口提交承载）
- 对应 PRD：`doc/releases/ios-v0.1/prd.md`
- 对应 dev plan：`doc/releases/ios-v0.1/dev_plan_ios-v0.1.md`
- 对应 progress：`doc/releases/ios-v0.1/progress_ios-v0.1.md`
- 对应原型：`doc/prototypes/ios-v0.1/index.html`
- 当前阶段：M3 完成 17/17、M3R 完成 14/14；M4 完成 13/17，Widget families、Live Activity 数据合同、阶段状态机、锁屏/灵动岛布局、时间费率投影及通知权限链路已建立

## 开发记录

### 2026-07-15 M4-013 通知权限事实源与系统设置跳转

- 测试先行增加 `NotificationPermissionPolicyTests` 与通知权限源码合同；RED 阶段分别因缺少权限动作策略、系统控制器、前台刷新、设置入口和本地化键按预期失败。
- 新增纯 Swift `NotificationPermissionPolicy`：未请求时允许发起授权，拒绝后仅跳转系统通知设置，已允许时不重复请求。系统权限由 `UNUserNotificationCenter` 读取，不把配置快照中的通知偏好当作授权事实。
- `SystemNotificationPermissionController` 负责读取系统状态、申请 alert/sound/badge 权限及打开 App 通知设置；`AppModel` 在加载和 App 回到前台时刷新状态，并记录状态刷新、请求成功/失败和系统设置跳转结果。
- Settings 仅按系统事实展示动作：未请求显示“允许通知”，拒绝显示“前往系统设置”，已允许不显示多余按钮。权限申请失败与设置跳转失败保留可读反馈，不影响配置保存。
- 首次 macOS run `29419573876` 暴露 Swift 6 严格并发下 `UNNotificationSettings` 非 `Sendable` 跨异步边界。新增回归合同后，使用 `@preconcurrency import UserNotifications` 对 Apple SDK 旧并发标注做最小桥接，没有关闭 Swift 6 严格检查或伪造成功。
- 实现提交为 `c8a7ba8`，并发兼容修复提交为 `5643cf8`。本地 M4 门禁通过：SalaryCore 70/70、Widget Extension 合同 14/14、通知权限源码合同 5/5，M1-M4、M3、Playgrounds 导出和本地化回归全部通过；`git diff --check` 无错误。
- GitHub macOS run `29420537949` 在 HEAD `5643cf8`、Xcode 16.4 下成功编译 G3 probes、正式 App 与内嵌 Widget/Activity Extension，结论为 `success`。
- 当前证据证明权限决策、系统 API 接线、前台刷新和 Apple SDK 编译成立；不证明真机系统授权弹窗、拒绝、撤销、系统设置往返或通知送达。上述行为继续由 M4-015、M4-017 和 M7 真机验收承担。

### 2026-07-15 M4-012 Live Activity 时间锚点与费率推导

- 测试先行新增 `SalaryActivityProjectionTests`；RED 阶段因投影器与错误类型尚不存在而按预期编译失败，随后以纯 Swift 时间投影实现转绿。溢出保护也先通过失败用例确认，再补充安全初始化校验。
- 投影器按上班、午休开始、午休结束和下班四个锚点计算有效工作秒数、今日金额和基点进度：上班前归零、午休期间冻结、复工后排除午休时长、下班及之后封顶为完整日薪与 100%。零时长午休保持连续计算。
- 金额继续复用 `SalaryCalculator` 的整数半入舍入规则，并在构造阶段拒绝非法锚点、负日薪、非正标准工时和可能溢出的输入，避免 Live Activity 与 App 主计算口径漂移。
- `SalaryActivityStateMachine` 在初始化、时钟推进和确认提前结束时重新消费投影结果，不再携带陈旧快照金额；完成与提前结束终态仍保持不可逆和稳定。
- Widget 源码合同新增禁止 `Timer`、`DispatchSourceTimer`、`Task.sleep` 等后台秒级循环的检查。系统倒计时仍由 `Text(timerInterval:countsDown:)` 渲染；金额和进度只在系统或业务状态刷新时重算，不承诺后台逐秒重绘。
- 本地 M4 门禁通过：SalaryCore 67/67、Widget Extension 合同 14/14，M1-M4、M3、Playgrounds 导出和本地化回归全部通过；`git diff --check` 无错误。
- 实现提交为 `754451b`。GitHub macOS run `29416653484` 在 Xcode 16.4 下成功运行测试并编译正式 App 与内嵌 Widget/Activity Extension，结论为 `success`。
- 当前证据证明时间/费率投影合同、状态机集成与 Apple SDK 编译成立，不证明 ActivityKit 真机启动、系统刷新频率、锁屏/灵动岛实时重绘或自动结束；这些继续由 M4-014 至 M4-017 与 M7 真机验收承担。

### 2026-07-15 M4-011 灵动岛最小、紧凑与展开布局

- 测试先行扩展 Widget Extension 源码合同；RED 阶段因正式灵动岛仅有占位布局而按预期失败，随后实现最小、紧凑、展开和窄宽度降级层级。
- 展开态左侧显示阶段及金额，午休阶段改为金额隐藏提示；右侧显示距离下班或复工倒计时，底部显示工作进度。紧凑态优先显示金额或午休倒计时，空间不足时通过 `ViewThatFits` 降级为进度；最小态只保留阶段图标。
- 所有倒计时继续使用系统 `Text(timerInterval:countsDown:)` 和静态时间锚点，不新增后台秒级定时器；金额、进度和阶段均消费 M4-008/M4-009 的版本化合同，不在视图层重新推导工资。
- 首次 GitHub macOS run `29413340412` 暴露正式 `dynamicIsland` 闭包在局部变量之后缺少显式 `return`，而 G3 probe 未覆盖这一语法分支。补充回归合同后以独立提交 `a36e959` 修复，没有放宽正式构建门禁。
- 本地 M4 门禁通过：SalaryCore 62/62、Widget Extension 合同 13/13，M1-M4、M3、Playgrounds 导出和本地化回归全部通过；`git diff --check` 无错误。GitHub macOS run `29414089375` 在 Xcode 16.4 下成功编译 G3 probes、正式 App 与内嵌 Widget/Activity Extension，结论为 `success`。
- 当前证据证明灵动岛产品源码合同与 Apple SDK 编译成立，不证明 iPhone 16 Pro Max 真机的最小/紧凑/展开视觉、系统限流、触控或自动结束行为；这些继续由 M4-017 与 M7 真机验收承担。

### 2026-07-15 M4-010 锁屏 Live Activity 布局

- 测试先行扩展 Widget Extension 源码合同；RED 阶段因缺少 `SalaryLiveActivity.swift` 按预期失败，随后接入正式 `ActivityConfiguration` 和 Widget Bundle 转绿。
- 锁屏布局按 M4-009 阶段语义展示：工作态显示今日金额、进度和距离下班；午休态隐藏金额，显示暂停说明与距离复工；正常完成和提前结束使用稳定终态文案，不继续显示倒计时。
- 倒计时使用 SwiftUI `Text(timerInterval:countsDown:)` 与作息时间锚点，不增加后台秒级定时器。金额使用静态上下文中的币种格式化，进度统一限制在 0%-100%。
- Activity Configuration 的灵动岛闭包仅提供编译所需的最小兼容占位，不作为 M4-011 的正式灵动岛产品布局；紧凑、最小和展开信息层级仍在下一任务实现。
- 本地 M4 门禁通过：SalaryCore 62/62、Widget Extension 合同 12/12，M1-M4、M3、Playgrounds 导出和本地化回归全部通过；`git diff --check` 无错误。
- 实现提交为 `aa02dac`。GitHub macOS run `29412597489` 在 Xcode 16.4 下成功编译 G3 probes、正式 App 与内嵌 Widget/Activity Extension，结论为 `success`。
- 当前证据证明锁屏 Live Activity 源码合同与 Apple SDK 编译成立，不证明真机锁屏渲染、系统限流、系统自动清除或触控行为；这些继续由 M4 后续任务和 M7 真机验收承担。

### 2026-07-15 M4-009 Live Activity 阶段状态机

- 测试先行新增 `SalaryActivityStateMachineTests`；RED 阶段因缺少状态机、事件和错误类型而按预期编译失败，随后以最小纯 Swift 实现转绿。
- 状态机按上班、午休开始、午休结束和下班四个静态锚点推导工作/午休/完成阶段及 `nextTransitionAt`；零时长午休会直接跳过午休态，不产生伪切换。
- 用户确认提前结束会进入不可逆 `endedEarly` 终态；到达下班锚点自动进入不可逆 `finished` 终态，已结束状态不会被后续时钟事件重新激活。确认发生在计划下班时刻或之后时仍归类为正常完成。
- 非法作息、上班前初始化和早于当前状态时间戳的倒序事件均返回结构化错误；午休阶段明确隐藏金额。状态转换只携带现有快照金额和进度，不在本任务实现时间费率推导或后台秒级定时器，后者保留给 M4-012。
- 本地 M4 门禁通过：SalaryCore 62/62、Widget Extension 合同 11/11，M1-M4、M3、Playgrounds 导出和本地化回归全部通过；`git diff --check` 无错误。
- 实现提交为 `318466f`。GitHub macOS run `29411454091` 在 Xcode 16.4 下成功运行 SalaryCore 测试，并编译 G3 App/Widget/Activity/Watch probe、正式 App 与内嵌 Widget Extension，结论为 `success`。
- 当前证据证明纯状态机合同和 Apple SDK 编译成立，不证明 ActivityKit 真机启动、恢复、系统自动清除、锁屏或灵动岛展示；这些仍由 M4-010 至 M4-017 与 M7 真机验收承担。

### 2026-07-15 M4-008 Activity Attributes、ContentState 与版本兼容

- 测试先行新增 `SalaryActivityContractTests` 和正式 Widget Extension 源码合同；RED 阶段分别因缺少版本化内容模型和 `SalaryActivityAttributes.swift` 而按预期失败。
- `SalaryCore` 新增 schema v1 的静态上下文与动态 ContentState：静态数据记录币种、工作日、四个作息时间锚点、日薪和标准有效工时；动态数据记录快照身份、生成时间、工作阶段、锚点金额、进度和下一次状态切换时间。
- Activity phase 明确限制为工作、午休、完成和提前结束；新构造对象只能写入当前 schema v1。历史数据缺少 `schemaVersion` 时按 v1 解码，未来版本明确以 `DecodingError` 拒绝，避免静默误读。
- 正式 Widget Extension 使用 `SalaryActivityAttributes: ActivityAttributes`，并以 `SalaryActivityContentState` 作为 ActivityKit `ContentState`；本任务没有实现 Activity 启动、更新、结束、锁屏布局或持续后台定时器。
- 本地 M4 门禁通过：SalaryCore 55/55、Widget Extension 合同 11/11，M1-M4、M3、Playgrounds 导出和本地化回归全部通过；`git diff --check` 无错误。
- 实现提交为 `b43875d`。GitHub macOS run `29410130942` 在 Xcode 16.4 下成功编译 SalaryCore、G3 Widget/Activity probe、正式 App 与内嵌 Widget Extension，结论为 `success`。
- 当前证据只证明版本合同和 Apple SDK 编译成立，不证明 ActivityKit 真机授权、启动/恢复、锁屏或灵动岛行为；这些由 M4-009 至 M4-017 与 M7 验收承担。

### 2026-07-15 M4-007 Widget 时间线、最后更新时间与过期态

- 测试先行为共享快照刷新策略和 Widget 时间线源码合同增加失败用例；RED 阶段因缺少 `SharedSnapshotRefreshPolicy`、过期内容状态、过期时间线 entry 与更新时间文案而按预期失败。
- 新增独立刷新策略：默认每 15 分钟请求一次 WidgetKit 刷新，快照生成 30 分钟后判定过期；未来时间戳不会推迟周期刷新，已过期快照继续保留最后有效值并按周期重试。
- 时间线在快照过期边界加入过期 entry，即使系统延后实际刷新也能切换到明确过期展示；桌面与锁屏 families 显示更新时间或紧凑过期提示，不承诺系统按秒刷新。
- 本地 M4 门禁通过：SalaryCore 51/51、Widget Extension 合同 10/10，M1-M4、M3、Playgrounds 导出和本地化回归全部通过；本地化 JSON 与 `git diff --check` 无错误。
- 实现提交为 `b45d457`。GitHub macOS run `29408598821` 在 Xcode 16.4 下成功编译正式 App 与内嵌 Widget Extension，并通过全部 Apple SDK 编译步骤。
- 当前证据不包含签名、App Group 真机读写、WidgetKit 系统预算下的真实刷新时刻、桌面/锁屏添加或视觉验收；这些由 M7 真机矩阵承担，不以 Simulator 编译替代。

### 2026-07-15 M4-006 锁屏 accessory families 与窄宽度降级

- 测试先行增加锁屏 family、专用紧凑视图、`ViewThatFits` 和短错误态合同；RED 阶段因缺少 `.accessoryInline`、`.accessoryCircular`、`.accessoryRectangular` 和 family 路由而按预期失败。
- 内联组件优先显示“状态 · 金额”，宽度不足时退化为状态；圆形组件只显示工作进度；矩形组件显示金额、状态、百分比与进度条，避免把桌面大组件布局硬塞进锁屏。
- 未配置和快照不可用沿用既有内容状态，但锁屏仅显示图标与短标题，不展示多行解释；三种锁屏 family 使用系统强调色并保持桌面组件行为不变。
- 本地 M4 门禁通过：SalaryCore 47/47、Widget Extension 合同 9/9，M1-M4、M3、Playgrounds 导出和本地化回归全部通过；`git diff --check` 无错误。
- 实现提交为 `a872d2c`。GitHub macOS run `29406926128` 在 Xcode 16.4 下成功编译正式 App 与内嵌 Widget Extension，并通过全部 Apple SDK 编译步骤。
- 当前证据不包含签名、App Group 真机读写、锁屏添加与不同壁纸/系统渲染模式的视觉验收；这些由 M7 真机矩阵承担，不以 Simulator 编译替代。

### 2026-07-15 M4-005 大组件金额、进度与今日安排

- 测试先行为共享作息投影、旧快照兼容和大尺寸 Widget 源码合同补充失败用例；RED 阶段分别因缺少 `SharedScheduleSnapshot`、`schedule` 字段和 `.systemLarge` 布局而按预期失败。
- `SharedSnapshotBundle` 增加可选的只读作息投影，包含上班、午休起止和下班时间；字段保持可选，旧 JSON 快照缺失该字段时仍可解码，不触发数据迁移或伪造安排。
- `.systemLarge` 复用既有金额、状态和进度投影，并增加“今日安排”三行；旧快照无作息数据时显示明确不可用提示，小/中组件行为不变。
- 本地 `check_ios_m4.ps1 -RequireSwift` 通过：SalaryCore 47/47、Widget Extension 合同 8/8，M1-M4、M3、Playgrounds 导出和本地化回归全部通过；`git diff --check` 无错误。
- 实现提交为 `3d98eda`。GitHub macOS run `29405142288` 在 Xcode 16.4 下成功生成正式工程、编译 App 与内嵌 Widget Extension，并通过 `ValidateEmbeddedBinary` 与 `BUILD SUCCEEDED`。
- 当前证据仍不包含真实签名、App Group 容器、系统桌面添加与大组件视觉验收；锁屏 families 和时间线过期策略继续由 M4-006/M4-007 承接。

### 2026-07-15 M4-004 中组件金额、状态与工作进度

- 测试先行新增中尺寸 Widget 契约；RED 阶段因缺少 `.systemMedium`、family 分流、中组件视图和进度展示而按预期失败。
- `SalaryWidgetView` 使用 `widgetFamily` 在同一 `SalaryWidgetContentState` 上选择小/中布局，没有复制共享快照读取或错误状态机。
- `.systemMedium` 就绪态展示今日金额、显式中文工作状态、工作进度百分比和进度条；进度限制在 `0...10_000` 基点范围，金额与状态复用小组件规则。
- 中尺寸占位态同步提供金额、状态和进度骨架；未配置与快照不可用继续复用已有降级界面，未提前引入大组件、时间线刷新或 Live Activity。
- 本地 M4 门禁通过：Widget Extension 合同 7/7、SalaryCore 46/46，M1-M4、M3、Playgrounds 导出和本地化回归全部通过；`git diff --check` 无错误。
- 实现提交为 `1855715`。GitHub macOS run `29403617023` 在 Xcode 16.4 下成功编译正式 App 与 Widget Extension，将 `LetsMakeMoneyWidget.appex` 复制到 App 的 `PlugIns`，并通过 `ValidateEmbeddedBinary` 与 `BUILD SUCCEEDED`。
- 当前证据仍不包含真实签名、App Group 容器、系统桌面添加与中组件视觉验收；这些边界继续由 M4 后续任务与 M7 真机验收承担。

### 2026-07-15 M4-003 小组件金额、状态与降级态

- 测试先行扩展共享快照与 Widget 源码合同；RED 阶段分别因缺少结构化快照读取错误、三态投影、金额/状态文案和降级界面而按预期失败。
- `SharedSnapshotStore.read()` 现在明确区分“尚无快照”和“快照损坏/不可读”，Widget 将其投影为 `unconfigured` 与 `unavailable`，不再把所有失败混成空白界面。
- `.systemSmall` 就绪态显示今日已赚金额、暖色金币标识和显式中文工作状态；同时提供占位、未配置提示和数据暂不可用提示。
- 状态文案使用 `SalaryStatus` 的穷举映射，不依赖运行时拼接本地化键；金额使用人民币货币格式和稳定数字观感。
- 本地 M4 门禁通过：Widget Extension 合同 6/6、SalaryCore 46/46，M1-M4、M3、Playgrounds 导出和本地化回归全部通过；`git diff --check` 无错误。
- 实现提交为 `42cf60f`。GitHub macOS run `29402002179` 在 Xcode 16.4 下成功编译正式 App 与 Widget Extension，将 `LetsMakeMoneyWidget.appex` 复制到 App 的 `PlugIns`，并通过 `ValidateEmbeddedBinary` 与 `BUILD SUCCEEDED`。
- 当前证据仍不包含真实签名、App Group 容器、系统桌面添加与时间线刷新；这些边界没有因 Simulator 编译通过而提前关闭。

### 2026-07-15 M4-002 正式 Widget Extension 与共享快照

- 测试先行新增 `test_widget_extension_target.py`；RED 阶段因正式工程声明、entitlement、Widget 源码、XcodeGen 引导和远端构建步骤均不存在而按预期失败。
- 新增 `apple/project.yml`，使用固定 XcodeGen `2.45.4` 生成 `LetsMakeMoneyApp` 与 `LetsMakeMoneyWidget` 正式 target；不提交手工维护的 `.xcodeproj`。
- App 与 Widget 共用 App Group 标识合同。App 在加载或保存配置并成功计算后写入 `SharedSnapshotBundle`；Widget 只依赖 `SharedSnapshotReading`，不具备主配置写权限。
- 本地 M4 门禁通过：Widget 目标合同 4/4，SalaryCore 44/44，既有 M3、导出和本地化回归保持通过。
- GitHub run `29399501853` 首次暴露 shell 可执行位问题；run `29399812855` 暴露 XcodeGen 输出目录参数问题；run `29400009214` 进入正式 Swift 编译后暴露 Swift 6 completion closure 并发边界。三项均按日志做最小修复，没有放宽编译门禁。
- GitHub Actions run `29400350747` 在 HEAD `fe27cb5`、Xcode 16.4（16F6）、iOS Simulator 18.5 下成功生成正式工程、构建 App/Widget、复制 `LetsMakeMoneyWidget.appex` 到 App 的 `PlugIns`，并通过 `ValidateEmbeddedBinary` 与 `BUILD SUCCEEDED`。
- `IOS01-M4-002` 关闭。当前证据不包含签名、真机 App Group 容器、桌面添加 Widget 或时间线刷新；这些仍由 M4 后续任务和 M7 真机验收承担。

### 2026-07-15 M4-001 G3 Apple SDK 环境门禁

- 先新增 `test_apple_platform_gate.py` 并执行 RED；测试因 ApplePlatformGate、三个 probe 与 M4 门禁脚本不存在而按预期失败。
- 建立 `ApplePlatformGate` Swift Package，将 App、Widget/Activity、Watch 的 Apple Framework 边界拆成三个独立 target/scheme；它们只验证 SDK 可编译，不承载产品功能。
- 扩展 GitHub macOS 工作流，在现有 Playgrounds App iOS Simulator 编译后，分别编译 G3 App、Widget/Activity 与 Watch probe。
- 本地 `check_ios_m4.ps1 -RequireSwift` 通过，包含 SalaryCore 44/44、M3 源码/导出/本地化回归和 G3 合同 4/4。
- GitHub Actions run `29397574782` 在 HEAD `7952b40` 使用 Xcode 16.4（16F6）、Apple Swift 6.1.2 完成全部四条 App/平台编译，耗时 2 分 44 秒，结论 `success`。
- `IOS01-M4-001` 关闭；正式 Widget Extension、Activity entitlement、Watch App、XCTest、签名与真机行为保持后续门禁，未因 probe 通过而提前声明完成。

### 2026-07-15 GitHub macOS Apple SDK App 编译门禁通过

- 将 `.github/workflows/apple-sdk-experimental.yml` 约束为 `ios-main` Apple 相关路径自动触发，同时保留手动触发；本地 M3 门禁同步纳入工作流合同和 AppRoot Playgrounds 兼容合同。
- 首次 run `29395751872` 暴露旧导航合同仍断言原生 `TabView`；第二次 run `29396154419` 暴露导出 scheme 名称误用。两项均先在本地补充/修正合同，再提交最小 CI 修复。
- run `29396376249` 在 HEAD `a5e0b0f` 全部通过：SalaryCore、源码合同、Playgrounds 导出、scheme 枚举和 `LetsMakeMoneyAppleSDK` iOS Simulator SDK 编译成功。
- 当前证据仅关闭“导出 App 可在 Apple SDK 编译”的第一阶段门禁；`IOS01-M4-001` 仍保持未完成，Widget、Activity、Watch 多 Target 与 `M3SmokeUITests` 必须在后续 G3 中单独验证。
- GitHub Actions 提示 `checkout@v4` 与 `upload-artifact@v4` 的 Node 20 运行时将迁移到 Node 24；当前由 GitHub 强制 Node 24 后执行成功，记录为非阻塞维护项。

### 2026-07-15 M3 Preview 与 UI 自动化矩阵收口

- 修正 `M3SmokeUITests` 对旧原生 `TabView` 的依赖，改用自定义底部页签和侧栏共用的稳定无障碍标识；补充设置关闭断言。
- 增加 `-ui-test-configured` 测试启动参数，与 `-ui-test-reset-configuration` 组合后可在干净模拟器确定性进入已配置主路径；首次引导测试继续只使用重置参数。
- Preview 矩阵扩展为 iPhone 竖屏、iPad 竖屏、iPad 横屏、深色、大字、Settings 和 Onboarding 七类场景。
- 测试先行新增矩阵源码合同，确认旧代码失败后完成实现；完整 M3 门禁通过：Swift 44/44、本地化 3/3、M3 源码合同 8/8、Playgrounds 导出合同 2/2。
- `IOS01-M3-016` 关闭，M3 达到 17/17。Windows 不能运行 Xcode UI Test，实际 `XCTest` 执行明确转交 M4 前置 G3，不伪造为已运行通过。

### 2026-07-15 R10 真机定向复测通过

- 项目所有者确认 R10 原有主路径无异常；定向复测中的无效月薪提示、今日中文状态、iPad 竖屏底部导航和横竖屏页面边缘均通过。
- `IOS01-M3R-014` 关闭，M3R 达到 14/14；R9 的其余手动通过证据继续继承。
- `IOS01-M3-017` 关闭。M3 当前只剩 Preview/UI 自动化矩阵收口，不把真机通过结果替代尚未执行的 Apple SDK UI 自动化。

### 2026-07-15 R9 设备反馈、iPad 导航根因与 R10 候选

- R9 手动验证除无效月薪错误提示外均通过。设备截图补充暴露两项显示问题：今日金额下方状态出现英文/内部键，以及 iPad 横竖屏暖色内容之外出现白色边缘。
- 根因一是今日状态使用运行时拼接的动态本地化键，Playgrounds 的旧式 `.strings` 资源不能稳定解析；改为 `SalaryStatus` 到固定 `LocalizedStringKey` 的完整映射。
- 根因二是 iPadOS 会将原生 `TabView` 自适应为顶部浮动页签，与已确认的底部导航原型冲突；紧凑布局改用应用内自定义底部页签，横屏 regular 宽度继续保留侧栏/双栏。根视图、今日页和日历页同时显式铺满暖色安全区，消除内容外白边。
- 无效月薪改用明确的 `LocalizedStringKey`：提示“请输入大于 0 的月薪，最多保留两位小数”，输入与配置安全写入逻辑未改变。
- 测试先行补充自适应导航、固定状态本地化、全屏背景和错误提示合同；定向测试 2/2、M3 源码合同 7/7、Swift 44/44、本地化 3/3、Playgrounds 导出合同 2/2 及完整 M3 Windows 门禁通过。
- 导出 `LetsMakeMoneyM3R10-playgrounds.zip`，SHA256 `19327DC3BCA420EA07C8E1CA3DA04169DF11F1299C002580616CD649990D81E2`；包内关键实现与中文资源 5/5 检查通过，等待 iPad 对错误提示、中文状态、竖屏底部导航和横竖屏边缘进行定向复测。

### 2026-07-15 iPad 竖屏导航与 R9 候选

- 按已确认原型 A 调整自适应导航：仅 iPad 横屏 regular 宽度使用侧栏与双栏；iPad 竖屏、窄分屏和 iPhone 统一使用底部“今日/日历”页签，不再提供拥挤的竖屏侧栏。
- 在紧凑布局的今日页和日历页增加可见设置按钮，避免 iPhone 无导航容器时外层 toolbar 不显示。
- 首次引导改为三步特定中文标题；确认页使用固定枚举到本地化键的映射，休息模式只显示“单休”“双休”或“大小周”。
- 新增自适应导航与引导本地化源码合同；Swift 44/44、本地化 3/3、M3 源码合同 6/6 及完整 M3 Windows 门禁通过。
- 导出 `LetsMakeMoneyM3R9-playgrounds.zip`，SHA256 `D95AFC8F6C5999F726C06651651418497475940A55FA25126625A00C7703AA36`；等待 iPad Swift Playgrounds 4.7 对横竖屏、手机设置入口和引导标题进行定向复测。

### 2026-07-15 M3R 固定八小时推算与 R8 候选

- 新增初次上班时间专用推算：用户选择上班时间后，始终按净工作 8 小时与当前午休时长计算下班时间；确认页仍允许用户手动微调边界并重新计算工时。
- 双休、单休、大小周改为分段选择，选择时主动结束月薪输入焦点，避免休息制度操作继续占用数字键盘。
- 午休阶段改为完整语义行：左侧显示“午休时长”，右侧使用菜单选择 `0` 至 `3` 小时，不再孤立显示时间或暴露英文内部键。
- 新增初次上班时间推算单元测试和 SwiftUI 源码合同；Swift 44/44、M1/M2/M3、本地化及 Playgrounds 导出合同全部通过。
- 导出 `LetsMakeMoneyM3R8-playgrounds.zip`，SHA256 `DFBF59C50443C6ACC811443684090C7C1656AFD5E70FAFC65512C01056CF0EA9`；等待 iPad Swift Playgrounds 4.7 定向复测。

### 2026-07-15 M3R 作息页渐进填写与 R7 候选

- 第二步改为三层渐进填写：先确认上班时间，再选择午休时长，最后展示午休起止、下班时间和有效工时供用户微调。
- “上一步”同步支持逐层返回，避免从推算结果直接跳回工资页；进入摘要后返回时恢复完整推算层。
- 午休选项统一为 `0 / 0.5 / 1 / 1.5 / 2 / 2.5 / 3 小时`，不再通过动态键展示内部英文名称。
- 新增源码合同覆盖渐进阶段、前后导航和静态午休文案；Swift 语法解析、43 项 Swift 测试、M1/M2/M3 与本地化门禁全部通过。
- 导出 `LetsMakeMoneyM3R7-playgrounds.zip`，SHA256 `295A1E51C5AF57E74718206B7D8AF0605834C96E0BB8B566BD9877136DE4765A`；R7 尚未在 iPad 编译运行，`M3R-014` 保持未完成。

### 2026-07-14 M3R 首次引导 UI 接入与 R6 候选

- `OnboardingView` 已接入金额编辑草稿、自然语言大小周、系统时间选择和午休时长选择；移除锚点日期与时间自由文本输入。
- 引导页改为固定无文字进度条、可滚动内容和底部安全区操作栏，避免横屏键盘压缩时步骤标题与进度重叠。
- 作息草稿新增午休时长联动：调整时长同步推算午休结束和下班时间，并保持有效工时不变；调整午休起止继续双向保持时长。
- 新增中文本地化键和进度辅助功能标签；金额非法文本继续保留，但会阻止进入下一步。
- Swift 测试 43/43、M3 源码合同 4/4、M3 正向/反例门禁及 Playgrounds 导出合同通过。
- 导出 `LetsMakeMoneyM3R6-playgrounds.zip`，SHA256 `0A706CC0D69F37C14578035E0102D0EFCB6A138E2210634FC7DF795FA9BC39BB`。本批次仅关闭 `IOS01-M3R-005` 至 `013`，R6 尚未在 iPad 编译运行，`M3R-014` 保持未完成。

### 2026-07-14 M3R 金额、大小周与作息纯逻辑

- 按测试先行新增 `OnboardingInputTests`，先确认金额草稿、大小周语义和作息推算类型缺失导致红灯，再补最小实现转绿。
- 新增 `SalaryAmountDraft`：零值初始显示 `0.00`、首次聚焦清空；非零值保持；整数和最多两位小数可转换为最小货币单位，非法文本原样保留且不给出有效金额。
- 新增 `AlternatingWeekResolver`：小周映射到本周休息周六，大周映射到下周休息周六；可从既有锚点反推本周类型，并覆盖周六、周日自然周边界。
- 新增 `WorkScheduleDraft`：默认从 08:00 上班、12:00 午休、2 小时午休和 8 小时有效工时推算 14:00/18:00；拒绝跨日、非 30 分钟步进及超过 3 小时午休。
- 午休开始和结束的双向调整保持午休总时长；上下班边界调整即时重算有效工时，非法调整抛错并保留最后一组有效安排。
- 按 PRD 放开 `lunchStart == lunchEnd` 的零午休配置，仍要求 `上班 < 午休开始 <= 午休结束 <= 下班`，没有放宽跨日和越界规则。
- `swift test` 42/42 通过；M1、M2、M3 Windows 门禁通过。SwiftPM 的 `.build/debug` 符号链接警告源于 Windows 开发者模式未启用，不影响本轮编译和测试结论。
- 本批次仅关闭 `IOS01-M3R-001` 至 `004`；金额、大小周和时间控件尚未接入 SwiftUI，iPad 引导相关证据继续保持失效。

### 2026-07-14 M3R 首次引导增量开发承接

- 项目所有者确认 2026-07-14 增量 PRD 与高保真原型，开发授权继续有效。
- 需求变化限定在首次引导：金额编辑、大小周自然语言选择、系统时间组件、午休与下班推算、横屏键盘布局；Settings、schema v1 和工资公式不在本轮重做范围。
- 既有 M3-003/M3-004 保留为首版实现历史，不回退完成记录；新增 `IOS01-M3R` 独立返工批次承接替换逻辑和定向复验。
- M0-M2 证据继续继承；引导输入、作息和相关布局证据失效，M3R 完成后必须重新导出 iPad 包验证。
- 本轮仅更新 PRD、dev plan、progress 与 dev log，没有修改 Swift 业务代码。

### 2026-07-14 M3 静默崩溃根因与分层调试基线

- 针对 Swift Playgrounds 仅显示 `Build failed`、重启后静默退出且没有可见日志的问题，按 Core、资源、AppModel、单页面、导航和完整根视图逐层二分。
- Core、主 Bundle 资源、AppModel、Today、Calendar、Settings/Onboarding 均可独立运行；最小导航首次仍静默退出，排除了工资内核、资源、配置加载和页面主体。
- 单变量实验确认 `Binding(get:set:)` 直接接收 `@MainActor` 实例方法引用 `set: model.select` 会在 Swift Playgrounds 4.7 真机运行时静默崩溃；改为显式闭包 `set: { model.select($0) }` 后相同探针运行成功。
- 在 `AppRootView` 应用最小修复，并新增 `test_app_root_playgrounds_compatibility.py` 防止方法引用回归；Windows 回归 24 项、SalaryCore 33/33 与 M3 门禁通过。
- 生成 R5 完整包 `build/apple-playgrounds-m3-r5/LetsMakeMoneyM3R5-playgrounds.zip`，SHA256 为 `4D90D4048D3115B9CEC1D2F3A2F4B6A46C8F716C5979D9845BC831590361253C`；用户在 iPad Pro M4、Swift Playgrounds 4.7 确认完整 App 可启动。
- 新增单一 `LMMDebugHub` 导出器。Hub 默认进入安全首页，页面按层单独打开；打开前和显示后将阶段写入 `UserDefaults`，静默退出后重新启动即可查看最后边界。
- 新增 `apple-sdk-experimental.yml`，支持手动触发，并仅在 `ios-main` 的 Apple 相关路径发生变更时自动运行；计划在 GitHub macOS runner 上执行 SalaryCore、源码合同和 iOS Simulator SDK 编译。首次远端结果完成前只记录为实验性能力，不作为 Apple SDK 已通过证据。
- M3-016/M3-017 保持未完成；完整 App 启动只关闭 `M3-MAN-001/002`，不替代引导、布局、动态字体、VoiceOver 和主路径验收。

### 2026-07-14 M3 iPhone/iPad App 源码与 Windows 门禁

- 以测试先行建立 App 导航、三步引导会话、取消恢复、步骤校验、完成失败重试、页面呈现状态、日期覆盖编辑、日历状态语义和有效工时计算；Swift Testing 累计 33/33 通过。
- 新增 SwiftUI App 入口、依赖注入、暖色自适应设计 Token、iPhone Tab、iPad `NavigationSplitView`、今日页、日历、日期覆盖、设置和三步引导。
- 今日页覆盖未配置、配置错误、年份越界和正常工资快照；日历区分手动工作/休息、法定节假日、调休工作日和常规工作/休息日。
- 设置与引导共享可靠配置草稿，作息变化自动重算有效工时；完成摘要显示月工作日、日薪和今日收入示例。
- 接入深浅色、动态字体、VoiceOver 标识、提高对比度和降低动态效果；补充 iPhone/iPad、深色和辅助字号 Preview 及 UI 测试源码骨架。
- 建立 M3 SwiftUI 源码合同、String Catalog 覆盖和缺失页面变异门禁；11 个 App Swift 文件通过 Windows Swift 前端语法解析。该结果不替代 Apple SDK 类型检查与真机运行。
- 新增 `export_playgrounds_m3.ps1`，导出可交给 iPad Swift Playgrounds 的 `.swiftpm` 与 Zip；最新 Zip SHA256 为 `5B31BAA2AC242BED274EF17A07F670209F0F1107BF8394563A00DE593CF5C4E2`。
- 首次 iPad 编译暴露 Swift Playgrounds 4.7 缺少 `/xcstringstool`。根因是 Playgrounds 包直接处理 `.xcstrings`；导出器现将 String Catalog 转为 `zh-Hans.lproj/Localizable.strings`，正式 App 资源不变，并增加导出合同测试防止回归。
- 第二次 iPad 编译暴露 Windows 语法解析无法发现的 Apple SDK 类型兼容问题。已将 iPad 侧栏选择改为显式按钮、动态颜色改为明确 UIKit provider、只读步骤改为值访问，并移除当前 SDK 不支持的 Live Region modifier；新增 Playgrounds SwiftUI API 兼容合同。
- M3-016/M3-017 保持未完成，等待 iPad 对编译、Preview、横竖屏、分屏、动态字体和 VoiceOver 的真实补证。

### 2026-07-14 M2 配置、安全写入与共享快照

- 采用测试先行方式建立 `AppConfiguration` 默认值、字段级结构化校验、配置草稿和无变化判断；取消或关闭恢复原值，不改变最后有效配置。
- 建立 `ConfigurationCodec` 与 actor 隔离的 `ConfigurationStore`，覆盖临时写入、读回校验、原子替换、提交失败保护、损坏文件备份、schema 0 到 1 迁移、未来版本与未知字段严格拒绝。
- Windows 首轮测试暴露两个真实问题：并行测试临时目录的 UUID 被写成普通文本，以及损坏 JSON 的 Foundation 错误未映射到恢复分支。修复测试隔离和 `malformedDocument` 映射后，配置持久化测试通过。
- 建立统一身份的 `SalarySnapshot`、`ActivityState`、`WatchSnapshot` 投影及 actor 隔离的共享快照存储；并发读写测试确认读取结果始终是完整 JSON 且三种投影身份一致。
- 建立 App Group 容器抽象和 entitlement 不可用的结构化降级错误。Windows 仅验证接口与降级分支；真实 Apple 容器仍保留 G3/G4 后置门禁。
- 建立 JSON Lines 本地日志、有限轮换和路径、工资、账号、令牌类字段脱敏测试。
- 将核心错误中文迁入 `Localizable.xcstrings`，核心层只暴露稳定本地化键；新增 Python 静态扫描、单元测试和硬编码中文变异门禁。
- `test_check_ios_m2.ps1` 通过：Python 合同测试 6/6、Swift Testing 21/21、本地化测试 3/3，M2 正向与变异门禁均成功。
- 未创建 Xcode Target，未修改 Widget、Activity、Watch 或 Windows 业务实现；未提交、推送或打 tag。

### 2026-07-14 M1 Windows Swift 工具链与 G1 收口

- 在 `D:\Work\Software\swift-windows` 建立专用环境：Swift 6.3.3、Python 3.10.11、Visual Studio Build Tools MSVC 14.44 和 Windows SDK 10.0.22621.0；Swift 默认安装路径通过目录联接落到 D 盘。
- `swift --version` 真实输出目标 `x86_64-unknown-windows-msvc`。Windows SwiftPM 需要 VS x64 开发环境，并通过 `SDKROOT` 指向 Swift 自带 `Windows.sdk` 才能解析 Package Manifest。
- 项目参考验证继续使用原有 Python 3.12.8；专用 Python 3.10 保留给 Swift 官方依赖。原因是 Windows Python 3.10 默认缺少 IANA 时区数据，直接运行参考测试会把 `Asia/Shanghai` 判为无效。
- `check_ios_m1.ps1 -RequireSwift` 通过：Python 参考测试 6/6、Swift Testing 7/7、共享 JSON 向量一致性和变异测试全部成功，`IOS01-M1-016` 与 G1 关闭。
- SwiftPM 报告无法创建 `.build/debug` 符号链接，因为 Windows 开发人员模式未启用；实际 build/test 均成功，该警告不阻塞 M2。
- 本次环境验证只证明纯 Swift Windows Target 可执行，不替代 macOS/Xcode、App Group、Widget、Activity、Watch 或签名证据。

### 2026-07-14 M1 Schema、节假日与 SalaryCore

- 先编写跨端契约测试并执行 RED：校验器不存在时 4 组测试按预期失败；随后补标准库参考实现并转为 GREEN。
- 固定 `salary-schema v1` 字段、严格写入、未来版本拒绝覆盖、整数金额、本地时间、日期覆盖和结构化错误契约；明确不包含口令 UI 与加班字段。
- 收录国务院办公厅 2025、2026 年节假日/调休数据及官方文件身份；截至 2026-07-14 未发现 2027 官方安排，因此记录为不可用并回退周规则，没有使用预测数据。
- 建立 7 个跨端向量，覆盖普通工作日上午、午休冻结、官方调休、手动覆盖、大小周、2027 越界回退及闰年单休。
- 建立纯 Swift Package、公开计算 API、不可变快照、配置校验、节假日日历、规则优先级、整数舍入、日薪/时薪/今日收入/本月累计实现，以及 Swift 单元测试与共享向量测试。
- 新增 PowerShell 5.1 可运行的 M1 门禁。初版中文 PowerShell 源码在旧宿主按本地代码页解析失败，改为纯 ASCII 可执行脚本，中文说明保留在 Markdown。
- Windows 参考验证 6/6 通过，节假日 SHA256 变异与非法时区反例均被拒绝；Swift 6.3.3 后续实测 7/7 通过，`IOS01-M1-016` 与 G1 已关闭。
- 未修改 App UI、Widget、Activity、Watch 或 Windows 业务实现；未提交、推送或打 tag。

### 2026-07-13 M0 基线、分支与可行性

- 从 `main` 的 `5c302efcc2edb868231c4c4d9f002e8355e03001` 创建 `ios-main`，使用独立工作区 `E:\codex\LetsMakeMoney-ios`；原工作区及其未跟踪内容未被覆盖或删除。
- 锁定 Windows v0.7 便携 Zip 身份：44,157,654 字节，SHA256 为 `16F47A844EFD78D387E9D08FBCD3DE76C8C8BDD518731C1B0BA022E7F598121F`；Apple 开发不得修改或重新包装该产物。
- 建立 `apple/`、`shared/salary-schema/v1/` 与 `scripts/apple/` 的目录职责、Target 边界和迁移合同。
- 建立无秘密的标识符模板；真实 Team ID、证书、描述文件和本地标识配置不得提交。
- 冻结最低系统版本与工具链策略，但没有伪造本机不可取得的 Xcode、SDK 或 Swift build version。
- 明确 Playgrounds 只作为 App 与纯 Swift 模块的早期验证入口；未来 Xcode workspace 直接引用同一份 `SalaryCore` 源码，不维护第二套业务实现。
- 新增 Windows PowerShell 5.1 可运行的 M0 检查器及反例测试。初版因乱码字面量和旧 .NET 缺少 `Path.GetRelativePath` 失败，改为 Unicode 码点标记和根路径前缀截取后通过。
- Windows v0.7 基线与文档状态检查通过；M0 检查器真实项目、干净夹具、绝对路径反例及缺失文件反例均符合预期。
- 当前结论：G0 通过；G2 等待 iPad 真机补证；G1、G3、G4 尚未取得，不写为通过。M0 完成度 9/10。

### 2026-07-14 M0 iPad 真机补证

- 验证设备：iPad Pro M4；Swift Playgrounds 4.7。
- App Playground 创建、`CapabilityModel.swift` 跨文件引用、SwiftUI Preview 与全屏运行通过，页面正确显示 `1,200,000`。
- 添加菜单存在“Swift 软件包”入口；共享面板将项目识别为 Swift Package，并可“保存到文件”。
- 导出文件名为“我的app”；iPadOS 界面未展示扩展名，因此只记录可见事实，不猜测扩展名。
- G2 通过，`IOS01-M0-007` 关闭；M0 总计 10/10。G1、G3、G4 仍未取得，不受本次证据影响。

### 2026-07-13 开发承接

- 本轮目标：把已确认 PRD 和交互原型拆解为可执行实施计划与最小任务。
- 改动模块：仅文档、原型状态和追踪关系；未修改 Windows 或 Apple 业务代码。
- 关键处理：
  - 建立 M0-M7 八个里程碑和 G0-G5 环境/发布门禁。
  - 明确 M0/M1 可在当前环境先推进，M4-M7 受 macOS/Xcode、签名和真机门禁约束。
  - 约定 Apple 实现位于 `apple/`，跨端共享仅限 schema、测试向量和算法契约。
  - 将 14 条 FR 映射到实施里程碑与验收入口。
- 已验证：交互原型桌面/移动视口无溢出和控制台错误，核心按钮均可操作。
- 未验证/待补证：iPad Swift Playgrounds 能力、Swift 编译、Xcode 多 Target、App Group、Activity、Watch 与真实设备。
- 关联 bugfix/spike：后续 M0 需要 iPad Playgrounds 与 macOS/Xcode 环境 Spike。

## 关键决策

| 决策 | 背景 | 取舍 | 影响范围 | 后续观察 |
| --- | --- | --- | --- | --- |
| 使用独立 `ios-main` 分支 | 避免 Apple 与 Windows 版本混淆 | 保留同仓库历史与共享契约，分支隔离实现 | Git、文档、发布 tag | M0 创建前确认脏工作区处理 |
| Apple 实现统一放入 `apple/` | 降低跨产品线理解成本 | 不复用 Godot UI/native，只共享数据契约 | 目录、构建、贡献文档 | M0 固定 workspace 结构 |
| 完整首版分阶段实现 | App、Widget、Activity、Watch 均为版本门禁 | 先内核/App，再系统扩展和 Watch | 全版本 | 不因环境不足缩写为“已完成” |
| 无 Mac 时不伪造构建证据 | 当前只有 Windows、iPad/iPhone/Watch | 可先做契约和纯模块，后续取得 Xcode 环境 | M0-M7 | G3/G4 继续保持阻塞或待补证 |
| 不预埋加班字段 | 加班已延后 iOS v0.2 | 依靠 schema 版本扩展，而非提前污染配置 | FR-014、配置模型 | v0.2 重新进入 PRD |

## Bugfix 摘要

暂无。明确缺陷出现后记录到 `doc/logs/bugfix_log_ios-v0.1.md`。

## Spike / 技术探索摘要

| 主题 | 当前结论 | 是否进入本版本 | 后续动作 |
| --- | --- | --- | --- |
| iPad Swift Playgrounds | App、跨文件引用、Preview、运行、Package 入口与导出均已验证 | 是，G2 已通过 | M1 后续可尝试导入 SalaryCore，正式编译证据仍以 Swift/Xcode 为准 |
| macOS/Xcode 获取方式 | 当前无本地环境 | 是，属于完整 Beta 前置 | M0 比较云 Mac、借用或后续购置，不提前付费 |

## 验证摘要

- 自动化验证：M0 合同、M1 schema/节假日/跨端向量、变异测试与 Windows Swift 6.3.3 测试通过；尚无 Xcode/Apple Target 执行证据。
- 手动验证：原型由项目所有者确认整体方向和底部导航位置。
- 打包验证：尚未开始。
- 未覆盖项：所有 Apple 原生实现、签名、系统扩展和真实设备行为。

## 收尾事项

- 文档同步：PRD 状态、追踪矩阵、dev plan、progress 与本日志已建立关联。
- 发布说明：尚未开始。
- 回滚方式：开发承接仅修改文档；若计划需调整，回退对应文档，不影响 Windows 业务代码。
- 下一阶段建议：进入 M2，先实现纯 Swift 配置、安全写入与共享快照；Apple entitlement 相关能力保留 G3/G4 门禁。
