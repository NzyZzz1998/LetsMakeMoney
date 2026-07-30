# LetsMakeMoney Windows v1.0.4 开发日志

> 本文记录实施过程、关键决策、异常处理和验证结果。它不替代 `progress_v1.0.4.md`；progress 只保留状态、阻塞、证据入口和最小任务 checklist。

## 基本信息

- 版本：Windows v1.0.4 Stable
- PRD：`doc/releases/v1.0.4/prd.md`
- 开发计划：`doc/releases/v1.0.4/dev_plan_v1.0.4.md`
- 进度：`doc/releases/v1.0.4/progress_v1.0.4.md`
- 原型：`doc/prototypes/v1.0/index.html`
- 开发基线：`09f838d05c67efb5219437ec2208920e441f3f52`
- 当前阶段：M0 事实冻结与实现门禁

## 开发记录

### 2026-07-31 开发承接

- 目标：将已确认的 PRD 转换为可执行开发计划、状态看板和验证入口。
- 范围：只建立版本文档、追踪状态和原型验证记录，没有修改产品业务代码。
- 关键结论：Mini 贴边隐私状态不能只由 CSS 表达；当前 Rust 位置安全夹取会阻止窗口移出工作区，正常位置与收起位置也必须分离。
- 处理：将 work-area 几何、v1.0.3 配置兼容和正常/收起位置合同列为 M0 前置门禁。
- 验证：PRD、追踪矩阵、74 个任务 ID、文档链接、UTF-8、原型 JavaScript、三档 device scale 与 `git diff --check` 通过。

### 2026-07-31 M0 事实冻结与方案门禁

- 目标：完成 `V104-M0-001` 至 `V104-M0-010`，不改变用户可见行为。
- Git 与发布身份：
  - 开发基线为 `main` / `09f838d05c67efb5219437ec2208920e441f3f52`。
  - v1.0.3 tag 指向 `87f6766a33fd6ff284f0fb3a42dc18c5a7292bf4`。
  - v1.0.3 Zip SHA256 为 `259CAE23D785FC7712CAC0EFD42991C8EE210C0BCEA1EB5C07FC171DFB993B28`。
- 工具链：
  - Node.js `v24.14.0`。
  - Python `3.12.13`。
  - Rust stable 与精确 `1.97.1` 实际指向同一编译器身份，test 和 release build 均通过；M3 将固定精确版本并清理工具解析入口。
  - Visual Studio Build Tools `17.14.35`、MSVC `14.44.35207`、Windows SDK `10.0.22621.0`、WebView2 `150.0.4078.105`。
- 配置决策：
  - 使用 config v8 的可选字段 `mini_edge_auto_hide` 与 `mini_edge_dock`。
  - v1.0.3 可安全读取新字段，并在旧版保存时丢弃未知字段而不损坏旧配置。
  - 不引入 `window-state.json`。
- 几何决策：
  - 所有阈值先按逻辑像素定义，再按 monitor scale 转换为物理像素。
  - 正常位置只保存展开态位置；收起位置永不持久化。
  - 原显示器丢失时回落到主显示器 work area，并保留 12 逻辑像素安全边距。
- 测试驱动记录：
  - 先加入 100%/125%/150% DPI、负坐标显示器、任务栏 work area、显示器丢失和 24px 拖离阈值夹具。
  - 首次 Rust 定向测试因缺少几何类型与函数按预期失败。
  - 实现纯几何函数后，4 项 v1.0.4 几何/兼容测试全部通过。
- 异常与处理：
  - 一次未使用项目工具解析入口的 Cargo 调用触发了重复下载；该现象作为 M3 工具链单一入口的真实证据保留。
  - 初始开发日志以错误编码写入，已在继续实施前重建为 UTF-8，不保留乱码正文。
- 证据：
  - `doc/releases/v1.0.4/m0-baseline.md`
  - `doc/releases/v1.0.4/evidence/m0-baseline.json`
  - `apps/windows-v1/tests/fixtures/v104-mini-edge-geometry.json`
  - `apps/windows-v1/tests/fixtures/v104-config-compatibility.json`
  - `scripts/verify_v104.ps1`

### 2026-07-31 M1 包 README 与发布身份

- 建立 `apps/windows-v1/release-docs/`，将发布包中英文说明与仓库首页分离；模板明确版本、平台、渠道、EXE 入口、用户数据目录、升级回退、许可和在线支持。
- 新增 `portable_readme.py`，发布包说明由模板确定性渲染，并拒绝旧版本、未解析占位符、本机绝对路径、非 HTTPS 在线链接、缺失本地许可和图片嵌入。
- 新增 8 类行为场景：有效包通过；旧版本、空说明、未知相对链接、占位符、缺失许可、错误平台和错误 EXE 均按预期失败。
- 新增 `package_v104.ps1` 与 `verify_v104_package.ps1`：
  - Tauri 版本是发布版本权威源，npm 与 Cargo 必须一致。
  - `BUILD-INFO.json` 记录双语 README SHA256。
  - 候选 Zip 在隔离目录完成语义、二进制、许可、日历和边界验证后才进入事务式替换；替换失败恢复旧 Zip 与校验表。
- v1.0.3 Release README 快照差异已形成脱敏披露草案并记录既有 tag、Zip 和校验表身份。远端正文未获授权，因此没有执行任何远端写操作。
- M1 定向验证：
  - Python 编译通过。
  - 包说明合同 8/8 通过。
  - 三个 PowerShell 脚本语法解析通过。
  - `scripts/verify_v104.ps1 -SkipRust -SkipRegression` 通过。
- v1.0.4 应用仍为 1.0.3 开发身份；真实 v1.0.4 包构建与 ProductVersion 核对留到 ACC 统一升版后执行。

## 关键决策

| 决策 | 背景 | 取舍 | 影响范围 | 后续观察 |
| --- | --- | --- | --- | --- |
| Mini 隐私贴边是唯一新增产品能力 | 工资信息存在旁观隐私风险 | 只支持左右边缘，不扩展为通用停靠 | React、Tauri、配置、窗口几何、验收 | 多显示器、DPI 和找回可靠性 |
| 贴边状态写入 config v8 | v1.0.3 是直接回滚版本 | 旧版保存会丢弃新字段，但不会损坏旧字段 | 配置与回滚 | M6 验证真实运行持久化 |
| 只持久化展开态位置 | 收起位置不是用户选择的正常窗口位置 | 运行时收起移动不得覆盖 `mini_window_position` | Rust 窗口事件与配置 | M6 增加抑制与恢复测试 |
| Rust 固定为 1.97.1 | stable 与 fixed 已证明身份一致 | M3 再正式加入 pin 和统一解析 | 构建、CI、贡献者环境 | 升级策略和缓存 |
| FR-007、FR-009 作为继承门禁 | PR #19 已完成首轮架构治理 | 避免重复开发和范围膨胀 | 测试与聚合门禁 | 相关文件变化时证据失效 |
| 远端 Release 披露单独授权 | 修改远端正文属于外部写操作 | 本地先准备，未授权不执行 | FR-002 | 授权状态 |

## Bugfix 摘要

当前没有 v1.0.4 产品缺陷记录。M0 只修正开发证据检查和文档编码。

## 2026-07-31 V104-M2 两层证据与桌面冒烟合同

- 建立仓库内脱敏验收摘要与外部原始证据索引 schema。
- 增加生成器和 8 类隐私、路径、哈希、失效状态负向测试。
- 增加只接受锁定 v1.0.4 Zip 的新解压桌面冒烟脚本：
  - 拒绝已有 LetsMakeMoney 进程；
  - 枚举候选进程全部可见顶层窗口；
  - 备份并按目录内容摘要精确恢复用户数据；
  - 检查正常退出、强制清理和残留进程；
  - 证据只保留文件身份、阶段结论和脱敏环境结果。
- 当前完成 5/8。真实候选身份摘要、通知区鼠标找回和新鲜 clone 冒烟必须等待最终候选，不能由脚本存在性替代。
- 验证：
  - 桌面冒烟 PowerShell 语法通过；
  - 桌面冒烟合同 13/13 通过；
  - 证据生成器 Python 编译通过；
  - 证据正向与负向测试通过。

## 2026-07-31 V104-M3 工具解析与 spike 解耦

- 使用测试驱动方式重建 Node、Python、Cargo 统一解析入口，顺序固定为显式环境变量、PATH、仓库 `.toolchains` 缓存、可操作失败。
- 正式脚本不再读取 `spikes/v1.0-ui/`、Codex 私有运行时或某个用户目录；显式变量只作为调用方主动提供的入口。
- 新增只读环境诊断，默认隐藏工具绝对路径，并实际识别 Node 22.14.0、Python 3.12.8、Cargo 1.97.1、MSVC、Windows SDK 10.0.22621.0 和 WebView2 150.0.4078.105。
- 根目录新增 `rust-toolchain.toml`，CI 固定 Node 22、Python 3.12、Rust 1.97.1，并在聚合验证前执行环境诊断。
- v1.0.2、v1.0.3 正式继承脚本移除裸 `python` 和浮动 `stable`，统一消费解析器和固定 Rust 工具链。
- 环境合同 17/17、工具解析合同 5/5、聚合 M0-M3 和 Rust 定向 4/4 通过。
- 当前完成 7/8。无 spike 新鲜 clone 的完整打包必须等待 ACC 统一升版至 1.0.4，避免用版本不匹配的候选伪造通过。

## 2026-07-31 V104-M4 高风险行为补测

- 在 Dashboard 生命周期中增加 `mounted` 与 `generation`，窗口隐藏、再次显示和卸载会切换请求代际；异步权威同步在写入成功或失败状态前同时核对可见性、挂载状态、代际与请求序列。
- 修复一个已确认竞态：可见时发出的请求若在窗口隐藏后晚到，旧实现仍可能覆盖隐藏时保留的可信快照；新实现会记录 ignored 语义并拒绝写入。
- 抽出配置保存事务：
  - 无变化不调用原生存储；
  - 业务失败与 invoke 异常均保留用户草稿和旧权威配置；
  - 可读错误保留；
  - 同一草稿重试成功后更新权威配置并请求一次跨窗口广播。
- 抽出 Dashboard 投影与失败状态转换：
  - 权威同步失败保留最近可信金额；
  - 跨边界重复失败进入 blocked，但不销毁可信数据；
  - 初次无快照失败显示错误；
  - browser 与 Tauri 等价 fixture 通过同一领域合同得到一致结果。
- 新增 `high-risk-combinations.behavior.ts` 24/24，并将全部 11 个行为测试文件接入唯一 `verify_architecture.ps1` 聚合入口。
- 聚合结果：
  - Runtime 15/15；
  - 权威同步 25/25；
  - 日历 11/11；
  - 配置领域 10/10；
  - 生命周期 14/14；
  - 日期调整 4/4；
  - Desktop Service 21/21；
  - 高风险组合 24/24；
  - Presentation 29/29；
  - 主题 5/5；
  - Structure 22/22。
- 完整聚合连续执行 10 次全部通过；TypeScript/Vite 生产构建通过。
- 真实通知区、系统 DPI、多显示器与 Mini 贴边仍按 `manual-evidence-plan.md` 留给候选阶段，不以自动化证据冒充。

## 2026-07-31 V104-M5 历史资产所有权矩阵

- 盘点 `spikes/v1.0-ui/`、v0.9 精修原型与 Figma 插件、iOS 原型与过程文档、v1.0 用户手册、历史 release、bugfix 日志和宠物动画合同。
- 当前跟踪规模：
  - Spike 46 个文件；
  - v0.9 精修原型 51 个文件；
  - Windows 仓库 iOS v0.1 原型 2 个文件；
  - v1.0 用户手册 49 个文件；
  - 历史 release 159 个文件；
  - 开发与缺陷日志 20 个文件。
- `spikes/v1.0-ui/` 已退出 v1.0.4 正式链路，但 v1.0-v1.0.2 历史脚本仍直接引用，当前归类为必须保留，不能因新链路解耦就直接归档。
- 独立 iOS 仓库 `E:\codex\LetsMakeMoney-ios` 存在并维护 `ios-main`，但 Windows 仓库中的 2 份同名原型和 5 份核心过程文档均与独立仓库内容不同；名称相同不足以证明完整接管。
- v0.9 Figma 插件的资产 manifest 记录 Classic/多多 6 张静态关键帧及哈希。它们属于产品历史素材，继续受受限素材许可约束，不能按 MIT 代码许可重新分发。
- 建立十项未来迁移门禁：目标仓库、全引用扫描、路径级哈希与语义 diff、唯一内容归零、许可与隐私、链接更新、恢复演练、静态检查、所有者签核和独立可回滚提交。
- `git diff --name-status --diff-filter=DR` 为 0；本版未移动、删除、取消跟踪或重新许可任何历史资产。
- 证据入口：`doc/releases/v1.0.4/historical-assets.md`。

## 2026-07-31 V104-M6 Mini 隐私贴边自动隐藏

- 在 config v8 中增加可选的 `mini_edge_auto_hide` 与 `mini_edge_dock`，旧配置默认启用自动隐藏且保持浮动；非法停靠值和关闭状态下的残留停靠值会安全回退。
- Rust/Tauri 增加 Mini 停靠检测、收起、展开、拖离与显示器安全回落接口：
  - 拖动结束距左右 work area 边缘 16 个逻辑像素内进入停靠；
  - 收起后只保留 10 个逻辑像素的隐私唤回条；
  - 向屏幕内拖动 24 个逻辑像素解除停靠；
  - 物理收起坐标不写入正常展开位置；
  - 显示器丢失或读取失败时清除停靠，并回到主显示器安全可见区域。
- 前端增加类型化 Window Service、单 timer 状态机与 Hook，统一处理 600ms 延迟、180ms 过渡、减少动态效果和 hover/focus/drag/menu/modal 交互锁。
- Mini 收起分支只渲染无收入信息的隐私唤回条；loading、error 和正常内容高度变化时会重新计算收起位置。
- Settings 的“窗口”任务中增加“贴边自动隐藏”开关：
  - 关闭并保存会立即展开、清除停靠并持久化；
  - 开启并保存不会主动移动窗口，下一次靠边拖动后才进入停靠。
- 托盘找回、窗口恢复和启动恢复会先展开停靠 Mini；边缘收起是窗口内隐私状态，不发送 `lmm:window-hidden`，也不暂停 Dashboard tick 或权威同步。
- 增加脱敏语义日志：`mini.edge_dock.detected`、`retracted`、`revealed`、`canceled`、`restore_fallback`、`failed`。日志不包含工资、时间、用户路径或精确窗口坐标。
- 自动验证结果：
  - 前端行为测试全部通过，其中 Mini edge 19/19、Desktop Service 27/27、Configuration 16/16；
  - M6 专项合同 6/6 通过；
  - Rust 53/53 通过；
  - `cargo fmt --check` 通过；
  - `cargo clippy --lib -- -D warnings` 通过；
  - TypeScript/Vite 生产构建通过。
- 当前完成 13/14。真实 Windows 左右边缘、浅色/深色、减少动态效果与 100%/125%/150% DPI 必须在锁定候选包上完成，不能用纯几何测试替代。

## Spike / 技术探索摘要

| 主题 | 结论 | 是否进入本版 | 后续动作 |
| --- | --- | --- | --- |
| work-area 与 DPI 几何 | 已建立纯函数和夹具；真实 Windows 行为留给 M6 | 是 | 接入原生窗口移动并做桌面验收 |
| config v8 兼容 | v1.0.3 读写安全，采用可选字段 | 是 | M6 实现字段与迁移默认值 |
| Rust 工具链固定 | stable/fixed 结果一致，可固定 1.97.1 | 是 | M3 建立 pin、解析器和 CI 门禁 |
| FR-004 组合行为缺口 | 单项能力已有证据，跨生命周期组合仍有缺口 | 是 | M4 补 characterization tests |

## 验证摘要

- M0 定向 Rust：4/4 通过。
- 继承门禁：Runtime 15/15、Desktop services 21/21、Presentation 18/18、Structure 22/22。
- 前端 TypeScript/Vite、Rust test/release build 均在事实冻结时通过。
- 聚合验证结果以 `doc/releases/v1.0.4/verification.md` 为最终入口。

## 收尾事项

- M0 完成后更新 progress、current、traceability 和验证文档。
- 下一阶段按开发计划进入 M1 包 README 与发布身份，不提前执行远端 Release 修改。

## 2026-07-31 V104-M6 开发验收与跨窗口配置刷新修复

### 验收对象

- 构建基线：`09f838d05c67efb5219437ec2208920e441f3f52`。
- Zip SHA256：`C67E730BF81741D03BFAF6D14F3F16EB74FD8591D8B3AB76D45A980E854C249B`。
- EXE SHA256：`B2A1831D0F7832C77033582871C12A2148CC8F3279753A5B812C293869ED1C66`。
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 候选边界：工作树有未提交变更，只用于开发验收，不作为正式发布候选。

### 已确认缺陷

真实 GUI 验收发现：Mini 已处于隐私收起态时，在 Settings 关闭“贴边自动隐藏”并保存，Rust 原生窗口恢复完整尺寸，但 Mini WebView 没有消费另一窗口发出的配置更新，仍渲染隐私标签分支，形成空白的全尺寸窗口。

修复保持既有配置事务和窗口几何不变：

1. `ConfigurationService` 增加 `configuration-updated` listener 与 disposer。
2. `useMiniEdgeAutoHide` 订阅跨窗口配置更新并重新读取权威配置。
3. Hook 卸载时可靠清理 listener，避免重复订阅。
4. 增加跨窗口关闭设置、listener 分发和清理行为测试。

### 定向复验

- 收起 Mini 从 Settings 关闭自动隐藏后立即恢复完整内容。
- 指针移开后保持完整，不再自动收起。
- 重启后 `mini_edge_auto_hide=false`，停靠状态为 floating。
- 左右边缘均形成 detected、retracted、revealed 日志序列。
- 关闭设置形成 `mini.edge_dock.canceled reason=settings_disabled`。

行为测试结果：

- `mini-edge-auto-hide.behavior.ts`：22/22。
- `desktop-services.behavior.ts`：27/27。
- M6 专项静态合同：通过。
- `scripts/verify_v104.ps1`：通过。
- 打包与包体验证：通过。

### 真实桌面边界

- 100% DPI 左右边缘、隐私收起、唤回和设置持久化：通过。
- 125%/150% DPI：待人工补证。
- 深色主题与减少动态效果：待人工补证。
- 多显示器、负坐标与显示器移除回落：待人工补证。

### 证据与环境恢复

- 生成 `doc/releases/v1.0.4/evidence/acceptance-summary.json` 与 `.md`，结论为 `partial`。
- 仓库摘要只保留候选身份、环境、结论和脱敏语义计数。
- Computer Use 原始截图没有建立持久外部归档，状态保持 `not_collected`。
- 普通用户数据目录恢复后与验收前备份逐文件比较 `7/7` 一致。
- 全部 LetsMakeMoney 进程已停止，进程数为 `0`。

### 收口判断

M6 开发实现完成，真实桌面验收部分通过。当前包不是干净提交候选；必须从干净提交重新构建，并针对新哈希补齐剩余系统级证据后，才可进入发布收口。
