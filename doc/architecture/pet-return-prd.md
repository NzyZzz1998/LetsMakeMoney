入口判断：/prd

# LetsMakeMoney 桌宠回归沙盒 PRD

> 内部代号：`pet-return`
> 文档类型：正式推进型合同 PRD（沙盒与 Spike 可执行；公开回归范围待确认）
> 形成日期：2026-08-10
> 产品仓库：`E:\codex\LetsMakeMoney`
> 素材与 QA 仓库：`E:\codex\PetManager`
> 动作探索环境：`D:\Work\Software\ComfyUIaaaki\ComfyUI-aki-v3`

## 追踪信息

| 字段 | 内容 |
| --- | --- |
| 当前状态 | PRD 已形成，等待项目所有者确认；只允许进入两条独立 Spike，不允许恢复正式产品入口 |
| 上游来源 | `PET-IDEA-001` 至 `PET-IDEA-016`，详见 `pet-return-idea-pool.md` |
| 下游承接 | `pet-return-runtime-spike.md`、`pet-return-quality-spike.md`；通过后再决定是否生成开发承接文件 |
| 当前事实源 | 本 PRD、`pet-runtime-state-machine.md`、`pet-package-vnext-contract.md`、`pet-return-traceability.md` |
| 现有产品基线 | v1 主线为零宠物；收入、日历、Settings、Wizard、托盘和更新链路不得依赖桌宠 |
| 现有素材基线 | Classic S4.3 与多多 S5.5 均为 `schemaVersion: 1`、`approved/ready`、`published:false` |

## 需求状态

- PRD 类型：**正式推进型合同 PRD**。
- 完整性判断：沙盒边界、状态机、宠物包 vNext 与两条 Spike 已达到可执行合同门禁；**公开回归范围尚未达到完整可开发门禁**。
- 原因：首次公开宠物、默认开关、业务事件总开关、AI 来源披露和首个 MiniMax 探索动作仍待项目所有者确认。
- 进入开发授权：**未获得**。本轮只定义合同，不执行 Spike 或业务开发。

## 已确认事实、推断与决策

### 已确认事实

1. 桌宠此前下线的核心原因不只是素材不够精美，还包括固定时长恢复、输入误判、状态语义重复、长期高重复和透明命中不可靠。
2. 当前 LMM 的 `DashboardSnapshot` 已提供 `phase`、`ownerDate`、业务边界、班次时间和同步状态；桌宠不得重复计算工资、日历或班次。
3. 当前 LMM 仅注册 Mini、Workbench、Settings、Wizard 四类正式窗口；零宠物验证合同仍有效。
4. Classic S4.3 有逐帧时长、锚点和脚底线，但缺少真正的 `run_loop`、多基础循环、低重复调度和逐帧命中合同。
5. 多多 S5.5 可用于相同 schema 的兼容验证，但其包级 `ready` 不等于 LMM 产品通过。
6. 独立 Tauri WebView 是窗口与资源隔离，不是进程级隔离；若沙盒故障能够拖垮 Tauri 主进程，则方案 B 的隔离假设失败。

### 当前推断

1. 方案 B 有机会在不恢复 Godot 的前提下复用 v1 的窗口、生命周期和日志能力，但透明像素命中仍需 Runtime Spike 证明。
2. 分层绑定与人工关键姿态比“直接把 AI 视频切帧”更适合基础循环；AI 更适合运动弧和一次性动作探索。
3. 多动作并不自动带来自然感；动作数量必须服从身份、节奏、循环接缝和 30 分钟编排门禁。

### 已确认决策

1. 内部代号只使用 `pet-return`，不命名正式版本。
2. 使用独立 Tauri 透明 WebView 桌宠沙盒，不恢复 Godot 运行时。
3. PetManager 负责生产、QA 与净化包；LMM 只验证并消费净化运行时包。
4. 桌宠必须可关闭、可卸载、可回滚，且故障不得污染收入主线。
5. `PetManager ready`、`LMM sandbox pass`、`Product return approved` 是三道独立门禁。
6. 任一 P0 失败时，桌宠继续停留在开发沙盒。

## 公开范围待确认

| 决策 ID | 待确认项 | 推荐 | 阻塞范围 |
| --- | --- | --- | --- |
| PET-DEC-001 | 首次公开回归只提供 Classic，还是 Classic 与多多同时开放 | 先只开放 Classic | 阻塞公开宠物清单，不阻塞两条 Spike |
| PET-DEC-002 | 正式回归后对现有用户默认关闭还是默认开启 | 默认关闭，由用户主动启用 | 阻塞生产配置默认值与迁移 |
| PET-DEC-003 | 是否提供“业务事件动作”统一开关 | 提供一个总开关 | 阻塞正式 Settings 合同 |
| PET-DEC-004 | 是否在 provenance 与发布说明中披露 AI 辅助和人工重建来源 | 接受并披露摘要 | 阻塞 AI 路线正式生产与发布 |
| PET-DEC-005 | MiniMax 首个探索动作 | 已取消：`working_pounce` 因不符合安静陪伴语义退役，本轮不执行该子实验 | 已关闭，不阻塞后续手工/绑定动作 |

## 方案收敛与优先级

- 当前目标：证明桌宠能在动画质量、交互可靠性和主线隔离三个维度达到产品资格。
- 优先级策略：质量与隔离优先于动作数量，运行时可证优先于公开入口，失败可回退优先于既有投入。

| 范围 | 优先级 | 进入本 PRD | 说明 |
| --- | --- | --- | --- |
| 沙盒隔离、vNext schema、状态机、透明命中可行性、Classic 黄金样片、产品门禁 | P0 | 是 | 决定是否继续桌宠回归 |
| 三基础状态、低重复调度、状态单击、拖拽全链、业务事件 | P1 | 合同进入；实现受 P0 门禁约束 | 形成完整首轮体验 |
| 多多兼容、MiniMax 探索、`pointer_follow` | P2 | 兼容与探索合同进入；`pointer_follow` 延后 | 不阻塞首轮资格 |
| 宠物市场、在线下载、跨显示器漫游、原生 GPU 重写 | 不排期 | 否 | 扩大范围但不能解决历史核心问题 |

## 背景与问题

v1 主线通过完全下线宠物恢复了收入工具的稳定性。桌宠回归不能以“重新显示一只猫”为目标，而必须重新建立从动作生产、包合同、播放器、状态机、输入、透明命中到长期观看的完整证据链。

本 PRD 只冻结沙盒及 Spike 的可执行合同。它不承诺桌宠公开上线，不修改当前默认产品行为，也不把历史 PetManager 包直接声明为正式资源。

## 目标与成功标准

### 目标

1. 建立不会侵入收入主线的独立透明桌宠沙盒。
2. 建立按真实逐帧时长和真实完成事件驱动的四域状态机。
3. 建立 Classic 与多多共用的宠物包 vNext schema、解析器和回退规则。
4. 用 Classic 五动作黄金样片证明新的质量生产方式，而不是复用粗糙动作扩数量。
5. 用 Runtime Spike 证明透明命中、长按拖拽、隐藏恢复和资源损坏隔离。
6. 建立 30 分钟视觉审查与 2 小时稳定运行门禁。

### 成功标准

- Runtime Spike 和 Quality Spike 分别满足各自继续条件。
- Classic 黄金样片的身份、几何、节奏、语义和循环接缝均达到人工审查 4/5 及以上，且全部硬门禁通过。
- 沙盒窗口、包或动画故障不会阻止收入主线启动、保存配置、使用托盘或检查更新。
- 所有输入和动作最终收敛到最新权威 `BaseState`，不存在固定全局恢复时长。
- 透明区域可穿透，可见区域可点击；若方案 B 无法做到，则停止而不是永久启用矩形命中。

## 范围

### 本次包含

- 沙盒窗口、开发 feature flag、独立沙盒配置和回滚合同。
- 四域状态机、输入仲裁、业务事件去重和低重复调度合同。
- 宠物包 vNext schema、完整性、许可、来源与回退合同。
- Classic 五动作黄金样片规格与 PetManager G0-G8 管线。
- Runtime Spike、Quality Spike 和 ComfyUI + MiniMax 有界实验合同。
- 动作级、编排级与产品级验收门禁。

### 本次不包含

- 用户可见桌宠入口、正式 Settings、正式托盘菜单或生产配置迁移。
- Godot 运行时、宠物市场、下载系统、在线包更新、主题扩展。
- 账号、云同步、支付、AI 助手、多平台或跨显示器漫游。
- 直接把 AI 视频、旧 Classic S4.3 或多多 S5.5 当作正式回归资源。
- 生成新素材、修改 PetManager Skill 或执行任何 Spike。

### 延后项

- `pointer_follow`。
- 正式公开宠物清单、默认启用策略和用户入口。
- 多多专属新动作；首轮只验证相同解析器兼容。

## 影响范围

- 前端 / UI：未来新增独立宠物 WebView 渲染层；本轮不修改 Mini、Workbench、Settings、Wizard。
- 前端状态：新增沙盒内四域状态、动作调度历史、输入锁和窗口状态；不得进入现有收入状态计算。
- Rust / Tauri：未来新增开发限定的窗口工厂、包验证服务、命中桥和生命周期事件；不得修改正式 `WINDOW_SPECS` 的默认行为。
- 数据库：不涉及数据库。
- 配置与环境：Spike 使用独立沙盒数据根目录；不修改当前 config v8，不恢复旧 `pet_*` 字段。
- 日志与指标：新增沙盒、包、动作、输入、命中、事件和故障隔离日志；不得记录 Prompt、API Key 或用户私密配置值。
- 权限与安全：只读消费净化包；所有相对路径必须防遍历；许可与哈希缺失时拒绝加载。
- 文件与存储：LMM 只接收净化运行时包和最小许可摘要；生产源文件、失败尝试和 QA 中间物留在 PetManager。
- 第三方依赖：Tauri 2、WebView2、Windows 原生命中桥；MiniMax 仅为可失败探索支线。
- 既有体验保护：收入、日历、Settings、Wizard、托盘、更新、配置迁移和 v1 零宠物发布门禁保持不变。
- 测试与验收：新增独立沙盒验证入口，不把 Spike 通过并入当前 Stable 通过声明。

## 沙盒产品边界

### 功能门禁

沙盒创建必须同时满足：

1. 构建包含开发 feature `pet-sandbox`。
2. 启动参数或开发设置显式启用沙盒。
3. 独立沙盒配置 `enabled=true` 且枚举合法。
4. 包通过 schema、路径、哈希和许可元数据验证。

任一条件不满足时，不创建宠物窗口；主应用继续按零宠物运行。生产 current gate 在 `Product return approved` 前继续拒绝生产入口和生产配置中的宠物能力。

### 配置与存储

- Spike 数据根目录必须与正式 `%APPDATA%\LetsMakeMoney` 配置隔离，例如由独立应用标识或显式测试目录提供。
- 沙盒配置最小字段：`schemaVersion`、`enabled`、`packagePath`、`businessEventsEnabled`、`qaSeed`。
- 默认 `enabled=false`；非法布尔、未知 schema、不可达路径或未知字段均回退为关闭并记录结构化错误。
- 沙盒关闭时保留配置但销毁窗口、停止 timer、释放输入锁和命中区域。
- 卸载只删除沙盒窗口注册、沙盒配置和沙盒包缓存，不接触收入配置和日志历史。

### 创建、显示、隐藏与销毁

| 操作 | 前置 | 成功结果 | 失败补偿 |
| --- | --- | --- | --- |
| 创建 | 双 feature gate 打开，包有效 | 创建独立透明、无装饰、无阴影的 WebView；先加载安全静态帧，再启动状态机 | 关闭沙盒并写 `pet_window_create_failed`，主应用继续 |
| 显示 | 窗口已创建且状态可用 | 重取权威 Dashboard，重置 wall-clock 样本，恢复命中和调度 | 保持隐藏，给诊断页记录可读错误 |
| 隐藏 | 系统隐藏、用户关闭沙盒或主窗口策略要求 | 立即停止动画调度和命中更新，释放输入锁，保留最后有效状态 | 强制将原生窗口设为不可命中；不得阻塞主线 |
| 销毁 | 沙盒关闭、包禁用或测试结束 | 移除监听器、timer、原生区域和缓存引用 | 幂等重试清理；超时后标记 degraded，不关闭主应用 |
| 异常恢复 | WebView 导航失败、资源损坏、渲染线程异常 | 最多重建一次沙盒窗口；仍失败则本次会话禁用 | 不循环重建，不弹阻塞主窗口的 Modal |

### 故障责任边界

- 包解析、素材缺失和 WebView 导航失败属于沙盒故障，必须局部禁用。
- Tauri 主进程崩溃、全局 WebView2 runtime 崩溃或原生桥破坏主窗口输入属于方案 B 失败，不得标记为“已隔离”。
- 若 Runtime Spike 证明同进程边界不足，应停止方案 B，进入“独立 sidecar 进程或原生小窗口”新一轮 `/idea`；本 PRD不预先批准该替代实现。

## BaseState 投影合同

桌宠只消费 LMM 权威快照并做呈现投影：

| Dashboard 状态 | 节律条件 | BaseState | 规则 |
| --- | --- | --- | --- |
| `ready/working` | 任意 | `working` | 工作状态优先于 23:00-07:30 节律 |
| `ready/lunch` | 任意 | `awake_rest` | 夜班休息仍是清醒休息，不自动睡眠 |
| `ready/before_work`、`after_work`、普通/带薪/不带薪休息日 | 23:00-07:30，且不与用户计划工作区间重叠 | `sleeping` | 仅作为低能耗节律投影 |
| 同上 | 其他时间 | `awake_rest` | 清醒休息 |
| `loading/setup/error` | 有最后可信快照 | 保留最后可信 BaseState，`WindowState=degraded` | 不猜测业务状态 |
| `loading/setup/error` | 无可信快照 | `awake_rest` 静态安全 fallback，`degraded` | 不播放业务事件 |

时间区间使用 LMM 的时区与跨夜班次口径；桌宠不得直接 `new Date()` 推断 owner date 或工资阶段。系统睡眠恢复、时区变化和时间跳变时必须先重新获取权威快照，再恢复动画。

## 功能需求

### PET-FR-001 可卸载沙盒与主线隔离

- 需求类型：前端、Rust/Tauri、配置、测试。
- 入口：仅开发 feature 与显式沙盒启动入口。
- 主流程：验证包 -> 创建窗口 -> 订阅权威快照 -> 显示静态安全帧 -> 启动状态机。
- 取消 / 关闭：关闭 feature 或沙盒配置后立即销毁；操作幂等。
- 失败 / 重试：窗口或包失败最多自动重建一次；再次失败本会话禁用。
- 日志：`pet_sandbox_requested/created/hidden/shown/destroyed/degraded/disabled`。
- 验收：强制关闭沙盒、破坏包、触发导航失败，收入主线仍可启动、保存和找回。

### PET-FR-002 四域状态机与真实完成事件

- 需求类型：前端状态、播放器、测试。
- 合同：BaseState、ActionLayer、InputState、WindowState 独立维护；合法转换详见 `pet-runtime-state-machine.md`。
- 播放器按 `frames[].durationMs` 推进，并在最后一帧真实显示完毕后发送一次 `animation_finished(actionInstanceId)`。
- 每次动作分配递增 `actionInstanceId`；晚到完成事件与当前 ID 不匹配时丢弃并记录。
- `maxRuntimeMs` 只作异常保险；不得代替完成事件，不得定义全局固定恢复时长。
- 结束后重新读取最新 BaseState，不恢复动作开始时的旧状态。

### PET-FR-003 动作目录与候选参数

动作目录、候选帧数、逐帧时长、权重、冷却、中断和回退见本 PRD“动作矩阵”。所有数值是黄金样片前的候选参数；只有 Quality Spike 通过后才能回写为冻结值。

### PET-FR-004 输入仲裁

- 取消双击，不保留双击等待窗口。
- 左键 `pointerdown` 进入 `press_pending`；500ms 内释放且未越位移阈值时派发当前 BaseState 的 ack。
- 位移阈值候选为 6 CSS px，必须在 100%/125%/150% DPI 的 Runtime Spike 中校准后回写；超过阈值立即取消单击资格。
- 只有按住满 500ms 才进入 `run_prepare`；提前移动后释放不派发单击或拖拽动作。
- 拖拽使用 pointer capture；方向只在越过方向死区后变化，优先使用 `mirrorSafe=true` 的镜像。
- 释放后完整播放 `run_stop`，再收敛到最新 BaseState；系统隐藏或销毁可硬取消。
- 右键菜单、Settings 和任意 Modal 打开时进入输入锁；异常关闭也必须成对释放。

### PET-FR-005 业务事件与去重

- 数据源：相邻两份 LMM 权威 `DashboardSnapshot`，不在宠物模块复算日历与班次。
- 事件 ID：`SHA-256("pet-business-v1|" + ownerDate + "|" + eventType + "|" + boundaryLocalTime)`。
- 事件类型：`work_start`、`break_relief`、`break_return`、`work_end_celebrate`。
- 新会话启动时只建立当前状态基线，不补播启动前已跨过的边界。
- 有效窗口由权威同步间隔推导：`2 × syncInterval + 5s`；超时直接丢弃。
- 点击或拖拽期间可保留一个仍有效的业务事件；多个事件竞争时保留最新且与当前 BaseState 一致者。
- 处理过的 event ID 写入沙盒事件账本，保留 48 小时后清理；重复快照、沙盒重启和窗口恢复不得重播。
- 下班庆祝是唯一通用庆祝；上班、休息和复工不得复用庆祝素材。

### PET-FR-006 低重复调度

- `working` 至少两个可轮换基础循环；`awake_rest`、`sleeping` 各有独立基础循环。
- ambient 选择器先排除冷却中、达到 `maxConsecutive`、与当前动作相同或状态不匹配的候选，再按权重选择。
- 没有可选 ambient 时继续基础循环，不强行触发动作。
- QA 支持固定随机种子；生产默认使用不可预测种子，但不持久化行为画像。
- 记录动作选择、候选排除原因、冷却命中、连续次数和中断原因。

### PET-FR-007 动态命中与点击穿透

- 当前帧必须能提供确定性 hit mask；坐标按 `logicalSize`、`anchor`、`visualOffset` 和设备缩放转换。
- 可见头、身体、尾巴和动作伸展区返回命中；透明像素返回穿透。
- 帧变化后命中状态必须在一个帧时长内收敛。
- 菜单或 Modal 打开时暂停穿透并允许菜单交互；关闭后按锁计数归零才恢复。
- 首选原生 `WM_NCHITTEST` 或等价桥按 mask 判定；若只能用窗口 region，必须证明不裁切渲染且无明显更新抖动。
- 若两种方案都只能退化为永久完整矩形可点击，则 Runtime Spike 失败，方案 B 停止。

### PET-FR-008 宠物包 vNext

- PetManager 输出 `schemaVersion: 2` 的候选 vNext 净化包；LMM 只读解析。
- Classic 与多多使用相同 schema、验证器、解析器和 fallback 图；禁止 `petId` 条件分支。
- 详细字段、目录、完整性、升级和回滚见 `pet-package-vnext-contract.md`。
- schema、哈希、许可或路径校验失败时拒绝该包，尝试内置安全静态 fallback；若安全 fallback 也不可用则隐藏宠物窗口。

### PET-FR-009 Classic 黄金样片

- 第一阶段只覆盖 `working_play_loop_a`、`working_ack`、`run_prepare`、`run_loop`、`run_stop`。
- 禁止把电脑、键盘和金币作为表达工作或互动的必需道具。
- `working` 只表示用户工作期间的低干扰陪伴，不要求小猫表演工作；优先使用轻微玩耍、观察和状态感知回应。
- 蓄力与跑动只属于长按拖拽链，不进入 working 基础循环或环境动作。
- 必须产出身份板、关键姿态、完整角色层、独立道具层、可选头部蒙版、运动弧和状态边界证据。
- 任一动作最多三轮生产；三轮仍未通过身份、尺度、语义、节奏或接缝时停止当前路线，转绑定/手工关键帧或停止桌宠回归。

### PET-FR-010 PetManager G0-G8

G0-G8 的输入、输出和失败门禁由 `pet-return-quality-spike.md` 与 `pet-package-vnext-contract.md` 共同定义。自动测试通过不能替代真实时长 GIF、Contact Sheet、状态边界和项目所有者视觉审查。

### PET-FR-011 ComfyUI + MiniMax 有界探索

- 执行前必须重新核对本机节点、模型标识、API、实时价格、服务条款与再分发边界。
- 2026-08-10 核对结果：官方主线已提供 `MiniMax-H3`，按秒计费；本机 ComfyUI 现有内置节点仍只暴露 `MiniMax-Hailuo-02`，通过 Comfy.org API Key 调用，不是离线 H3。
- 不得把“官方有 H3”写成“本机已经可用 H3”；如选择 H3，需先做节点升级或直接 API 的独立预检。
- 只探索 PET-DEC-005 确认的一个动作，最多 3 轮 × 8 候选。
- 输出只作为运动弧和关键姿态参考，禁止直接切帧进入产品。
- API Key 只存在于凭据存储，不进入 workflow JSON、日志、截图、仓库或 QA 证据。

### PET-FR-012 三层验收与停止条件

- `PetManager ready`：包通过素材、schema、哈希、许可与人工视觉门禁。
- `LMM sandbox pass`：透明窗口、状态机、输入、动态命中、DPI、故障隔离和 2 小时运行通过。
- `Product return approved`：30 分钟观感、产品所有者审查、回滚演练和公开范围决策全部通过。
- 下层通过不自动授予上层；任一 P0 失败时保持零宠物主线。

## 动作矩阵

> 帧数、总时长、权重和冷却为候选范围，Quality Spike 后按证据回写。逐帧时长必须逐帧列出，不允许只保存总时长。

| 动作 | 语义 | Source -> Target | 帧数 / 总时长候选 | 播放 / 变体 | 权重与冷却候选 | 中断 / safe exit / max runtime | 镜像与 fallback | 触发与恢复 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `working_play_loop_a` | 用户工作期间的安静陪伴主循环 | working -> working | 16-24 / 2.4-4.0s | loop / `working_base` | 55%；基础循环间切换 | 状态、输入、业务可在 safe exit 中断；max 为两轮循环上限 | 依规格；fallback 安全陪伴静态帧 | working 默认；回 working |
| `working_play_loop_b` | 第二陪伴循环，动作轮廓明显不同 | working -> working | 16-24 / 2.8-4.5s | loop / `working_base` | 45%；不得连续选择同一变体 | 同上 | 同上 | working 轮换；回 working |
| `working_observe` | 短暂停下并观察用户 | working -> working | 8-12 / 1.2-2.0s | oneshot / `working_ambient` | 候选 35%；45-120s | ack、drag、业务可中断；至少末帧 safe exit | 优先镜像；fallback loop_a | ambient；回最新 working |
| `working_ack` | 陪伴状态单击回应 | working -> working | 8-12 / 0.8-1.2s | oneshot / `working_ack` | 用户触发；点击冷却候选 600ms | drag、系统可中断；末帧 safe exit | 可镜像则允许；fallback loop_a | 单击；回最新 BaseState |
| `awake_rest_loop` | 清醒休息、呼吸或坐卧 | awake_rest -> awake_rest | 16-24 / 3.0-5.0s | loop / `rest_base` | 唯一首轮基础循环 | 状态、输入、业务可中断 | 依规格；fallback 休息静态帧 | awake_rest 默认 |
| `rest_groom` | 理毛 | awake_rest -> awake_rest | 16-24 / 2.5-4.0s | oneshot / `rest_ambient` | 候选 55%；45-120s；不连续 | ack、drag、复工可中断 | 镜像需身份审查；fallback rest loop | ambient；回最新状态 |
| `rest_stretch` | 伸展 | awake_rest -> awake_rest | 12-16 / 1.5-2.5s | oneshot / `rest_ambient` | 候选 45%；45-120s；不连续 | 同上 | 同上 | ambient；回最新状态 |
| `rest_ack` | 清醒休息单击回应 | awake_rest -> awake_rest | 8-12 / 0.9-1.4s | oneshot / `rest_ack` | 用户触发；冷却候选 600ms | drag、系统可中断 | fallback rest loop | 单击；回最新状态 |
| `sleeping_loop` | 低振幅睡眠循环 | sleeping -> sleeping | 16-24 / 4.0-6.0s | loop / `sleep_base` | 唯一首轮基础循环 | 状态、轻互动、拖拽唤醒可中断 | 仅身份安全时镜像；fallback 睡眠静态帧 | sleeping 默认 |
| `sleep_twitch` | 耳朵或尾巴轻动 | sleeping -> sleeping | 8-12 / 1.0-1.8s | oneshot / `sleep_ambient` | 90-240s；不连续 | 单击、拖拽、状态可中断 | fallback sleeping loop | ambient；回最新状态 |
| `sleep_ack` | 不完全唤醒的轻反馈 | sleeping -> sleeping | 8-12 / 1.0-1.6s | oneshot / `sleep_ack` | 用户触发；冷却候选 1s | 拖拽、系统可中断 | fallback sleeping loop | 单击；回最新状态 |
| `wake_to_run` | 从睡眠到跑动准备 | sleeping -> dragging | 6-10 / 0.6-1.0s | optional oneshot / `drag_transition` | 每次拖拽至多一次 | 仅系统硬中断；末帧 safe exit | 优先可镜像；fallback `run_prepare` | sleeping 长按；进 run_prepare |
| `run_prepare` | 蓄力起跑 | working/awake_rest/dragging -> dragging | 8-12 / 0.6-0.9s | oneshot / `drag_transition` | 每次拖拽一次 | 系统硬中断；末帧 safe exit；max 候选 1.2s | `mirrorSafe` 必须明确；fallback run_loop 首帧 | 500ms 长按；进 run_loop |
| `run_loop` | 移动期间持续跑动 | dragging -> dragging | 8-12 / 每轮 0.55-0.9s | loop / `drag_loop` | 拖拽期间持续 | 释放在 safe exit 转 run_stop；系统可硬停 | 优先安全镜像；不安全才提供方向变体 | 指针移动；释放进 run_stop |
| `run_stop` | 减速、停稳和收势 | dragging -> latest BaseState | 8-12 / 0.8-1.2s | oneshot / `drag_transition` | 每次释放一次 | 新拖拽或系统可中断；末帧必须 safe exit | 镜像与 run_loop 一致；fallback 最新基础静态帧 | 释放；回最新 BaseState |
| `work_start` | 开始工作，不使用庆祝语义 | awake_rest/sleeping -> working | 8-12 / 0.8-1.4s | oneshot / `business` | 每 event_id 一次 | drag 优先；过期丢弃 | fallback working loop | 权威边界；回 working |
| `break_relief` | 结束当前工作并放松 | working -> awake_rest | 12-16 / 1.2-2.0s | oneshot / `business` | 每 event_id 一次 | drag/菜单短排队；过期丢弃 | fallback awake_rest loop | 休息边界；回 awake_rest |
| `break_return` | 收起休息姿态并恢复工作 | awake_rest -> working | 12-16 / 1.2-2.0s | oneshot / `business` | 每 event_id 一次 | 同上 | fallback working loop | 复工边界；回 working |
| `work_end_celebrate` | 下班一次性庆祝 | working -> awake_rest/sleeping | 16-24 / 1.8-3.0s | oneshot / `business` | 每 event_id 一次；可由总开关禁用 | drag 优先；过期丢弃 | fallback 当前真实 BaseState | 下班边界；回最新状态 |
| `pointer_follow` | 离散方向注视 | working/awake_rest -> same | 后置，3-5 离散姿态 | deferred | 死区 + 节流 | 任意动作立即关闭 | 不阻塞首轮 | 后续验证 |

### 动作级候选参数附表

> 本表是开发前候选合同，不是已验收素材参数。`frames[].durationMs` 必须在 Quality Spike 的 `compiled-profile.json` 中按实际帧数逐项列出，并满足上表总时长；未形成逐帧数组的动作不能进入 `PetManager ready`。safe exit 中的“末帧/循环边界”必须在帧数冻结后替换为实际索引。

| 动作 | maxConsecutive | cooldown / lease | safe exit 候选 | maxRuntimeMs 候选 | mirrorSafe 候选 |
| --- | ---: | --- | --- | ---: | --- |
| `working_play_loop_a` | 1 个调度 lease | 0；每 lease 最多 2 轮 | 循环末帧 + G3 批准的中间姿态 | 8000 | 待身份审查 |
| `working_play_loop_b` | 1 个调度 lease | 0；不得连续重新选择 | 循环末帧 + G3 批准的中间姿态 | 9000 | 待身份审查 |
| `working_observe` | 1 | 45-120s 随机 | 末帧；可补一个观察回收帧 | 2500 | 候选 true，需身份审查 |
| `working_ack` | 1 | 600ms | 末帧 | 1600 | 候选 true，需身份审查 |
| `awake_rest_loop` | 1 个调度 lease | 0；可续租同一基础循环 | 循环末帧 + G3 批准的中间姿态 | 10000 | 待身份审查 |
| `rest_groom` | 1 | 45-120s 随机 | 末帧；前爪归位帧可候选 | 5000 | 默认 false，批准后才能改 true |
| `rest_stretch` | 1 | 45-120s 随机 | 末帧 | 3200 | 待身份审查 |
| `rest_ack` | 1 | 600ms | 末帧 | 1800 | 候选 true，需身份审查 |
| `sleeping_loop` | 1 个调度 lease | 0；可续租同一基础循环 | 循环末帧 + 低振幅中间姿态 | 12000 | 默认 false，批准后才能改 true |
| `sleep_twitch` | 1 | 90-240s 随机 | 末帧 | 2400 | 默认 false，批准后才能改 true |
| `sleep_ack` | 1 | 1000ms | 末帧 | 2200 | 默认 false，批准后才能改 true |
| `wake_to_run` | 1 / 拖拽会话 | 0 | 末帧 | 1400 | 必须与 run 链方向合同一致 |
| `run_prepare` | 1 / 拖拽会话 | 0 | 末帧；关键蓄力帧不可退出 | 1200 | 必须 true 或提供左右变体 |
| `run_loop` | 持续到 pointer release | 0 | 循环末帧 + G3 批准的落脚帧 | 120000，超时强制安全收势 | 必须 true 或提供左右变体 |
| `run_stop` | 1 / 拖拽会话 | 0 | 末帧 | 1600 | 与 run_loop 一致 |
| `work_start` | 1 / eventId | eventId 去重 | 末帧 | 1800 | 待身份审查 |
| `break_relief` | 1 / eventId | eventId 去重 | 末帧 | 2600 | 待身份审查 |
| `break_return` | 1 / eventId | eventId 去重 | 末帧 | 2600 | 待身份审查 |
| `work_end_celebrate` | 1 / eventId | eventId 去重 | 末帧 | 3600 | 待身份审查 |
| `pointer_follow` | 不适用 | 后置；未冻结 | 任意动作请求立即退出 | 未冻结 | 以离散方向姿态代替默认镜像 |

### 动作级测试与人工验收

| 动作 | 自动测试重点 | 人工验收重点 |
| --- | --- | --- |
| `working_play_loop_a` | 逐帧时长、10轮首尾、lease 与 fallback | 安静陪伴、无机械停顿、无道具依赖 |
| `working_play_loop_b` | 与 A 同组权重、不得连续选择 | 轮廓与 A 明显不同但身份一致 |
| `working_observe` | cooldown、safe exit、ack/drag 中断 | 短暂观察自然、低干扰，不像等待指令 |
| `working_ack` | 10 次点击、600ms 冷却、晚到 finished | 短促回应，保持陪伴语境 |
| `awake_rest_loop` | 连续循环、状态切换与 fallback | 清醒休息自然，不等同 sleeping |
| `rest_groom` | 前爪/头部结构、不可默认镜像 | 理毛可辨认，无多肢和遮脸 |
| `rest_stretch` | 尺度峰值、状态边界 | 伸展有舒展与回收，不突变 |
| `rest_ack` | 10 次点击、冷却、回最新状态 | 与 working_ack 明显不同 |
| `sleeping_loop` | 10轮循环、低振幅、隐藏恢复 | 睡眠安静，无高频动作 |
| `sleep_twitch` | 90-240s 调度、不得连续 | 耳尾轻动，不完全唤醒 |
| `sleep_ack` | 10 次点击、拖拽中断 | 轻反馈，不复用庆祝 |
| `wake_to_run` | optional 缺失 fallback、方向连接 | 睡眠唤醒到起跑无瞬切 |
| `run_prepare` | 500ms 触发、关键段中断保护 | 蓄力明确，能自然接 run_loop |
| `run_loop` | 左右方向、循环、120s 超时与 mask | 移动与步态同步，无打滑 |
| `run_stop` | 释放一次、完整完成、最新 BaseState | 有减速和停稳，不瞬切静态帧 |
| `work_start` | eventId 去重、过期丢弃 | 上班语义，不庆祝 |
| `break_relief` | 边界一次、短排队、过期丢弃 | 从工作放松到休息 |
| `break_return` | 边界一次、回 working | 从休息收势并恢复工作 |
| `work_end_celebrate` | eventId 一次、开关、恢复状态 | 唯一通用庆祝，幅度可接受 |
| `pointer_follow` | 后置，不进入首轮通过统计 | 未来只验证自然注视与低干扰 |

## PetManager G0-G8 概览

| Gate | 输入 | 输出 | 硬失败条件 |
| --- | --- | --- | --- |
| G0 身份锁定 | 合法角色源图、许可 | 身份板与哈希 | 身份或授权不清 |
| G1 动作规格 | 本动作矩阵 | Profile 与状态边界 | 语义或状态冲突 |
| G2 分层输入 | `character_rgba`、`prop_rgba`、可选 `head_mask` | 分层证据 | 缺完整角色层、路径污染、颜色反推 |
| G3 关键姿态 | 身份板、动作 Profile | 起始/蓄力/主动作/缓冲/结束姿态 | 三轮仍身份漂移 |
| G4 补间与稳帧 | 已审姿态 | incoming frames | 多肢、缺失、尺度失控、空帧 |
| G5 标准化 | incoming frames | normalized frames | 蓝绿残留、基线超限、无关锁定帧变化 |
| G6 图集与 manifest | normalized + schema vNext | unpublished 净化包 | schema、哈希、许可不通过 |
| G7 素材 QA | 净化包 | GIF、Contact Sheet、边界图、人工 review | 无真实时长审查或人工未批准 |
| G8 LMM 产品 QA | LMM 沙盒 + ready 包 | sandbox evidence | 输入、命中、长期观感或主线隔离失败 |

## ComfyUI + MiniMax 门禁

### 2026-08-10 外部事实快照

- MiniMax 官方当前主推 `MiniMax-H3`，支持 768P/2K、4-15 秒和异步任务；价格为 768P `0.08 美元/秒`、2K `0.13 美元/秒`。
- Hailuo 2.3/02 已列为 Legacy，现行 Pay-as-you-go 仍列出固定视频价格。
- 本机 ComfyUI 的 `MinimaxHailuoVideoNode` 仅声明 `MiniMax-Hailuo-02`，通过 `api_key_comfy_org` 调用 API，不是本地离线模型，也不是 H3 节点。
- 上述价格与模型状态属于易变事实；每次实验提交前必须重新核对官方文档并写入 evidence，不写死为长期合同。

官方来源：

- <https://platform.minimax.io/docs/guides/video-generation>
- <https://platform.minimax.io/docs/guides/pricing-paygo>
- <https://docs.comfy.org/built-in-nodes/MinimaxHailuoVideoNode>
- <https://platform.minimax.io/protocol/terms-of-service>

### AI 四段合同

| 维度 | 合同 |
| --- | --- |
| 安全 | 只上传已获权使用的角色素材；不上传用户配置、日志或私密截图；Prompt 注入不适用业务数据，但工作流不得自动执行下载脚本或外部代码 |
| 韧性 | API 超时、限流、失败或模型下线时停止当前轮次；不自动无限重试，不阻塞绑定/手工路线 |
| 治理 | 每动作有轮次预算、模型与价格快照、任务 ID、人工选择记录；API Key 不落盘到仓库；模型/供应商可整体关闭 |
| 评测 | AI 输出只参与运动弧和关键姿态参考；最终仍走 G2-G8；无合格候选时判定本路线失败，不用投入成本解释质量 |

### 预算与停止条件

- 每动作最多 24 个候选；按选定模型实时价格计算预算，项目所有者在调用前单独批准。
- 若使用 H3，需先证明本机节点或直接 API 工具可用；若使用现有 Hailuo 节点，必须记录其为 Legacy API 路线。
- 24 个候选中至少 1 个同时满足身份、尺度、动作语义、起止姿态和可重建性，且人工重建成本低于从零制作，才允许继续。
- 许可、再分发或 AI 标识义务不清时，不调用并转绑定/手工关键帧。

## 需求表达物

- 状态表达物：`pet-runtime-state-machine.md`。
- 数据与包表达物：`pet-package-vnext-contract.md`。
- 执行表达物：两份 Spike 合同。
- 追踪表达物：`pet-return-traceability.md`。
- 现有架构比较原型：`doc/prototypes/v1.0/animation-rearchitecture-options.html`，本轮只作为已读取证据，不修改、不视为公开回归 UI 原型。

| 原型交付门禁 | 本轮要求 |
| --- | --- |
| 交付文件 | 已核对 `doc/prototypes/v1.0/animation-rearchitecture-options.html`；本轮不以低保真线框替代。公开入口进入开发前，必须在同一 v1.0 原型体系补齐 Settings 开关、宠物窗口、菜单、错误与卸载流程 |
| 状态与出口 | Runtime Spike 覆盖正常、空包、坏包、禁用、加载、错误、隐藏、关闭和销毁；未来公开 UI 还需覆盖保存、取消、关闭与无变化 |
| 模拟边界 | Spike 中的包、Dashboard fixture、命中 mask 和故障注入均为测试能力，不证明正式用户入口或长期采用 |
| 浏览器验证 | 本轮不修改 HTML；执行公开 UI 原型阶段时必须用真实浏览器检查桌面/窄窗口、关键交互、控制台和脚本错误；Runtime Spike 另用真实 Tauri/WebView 验证 |
| 结论回写 | Runtime/Quality 结果分别回写两份 Spike 文档与本 PRD 的候选参数、命中职责和停止结论；必须保护 v1 零宠物主线及现有四窗口体验 |

## 开发前验收与指标

## 验收目标

证明“新的桌宠方案能够自然播放、可靠互动、逐帧命中并与收入主线隔离”，而不是证明“旧素材可以显示”。

## 验收标准

### 动作级

- 脚底线漂移不超过 2px。
- 基础循环相邻头部尺度变化不超过 2%；一次性动作不超过 4%；角色整体相邻尺寸变化不超过 5%。
- 色键残留、未声明空帧和相邻槽位污染均为 0。
- 循环连续播放 20 次无可见接缝积累。
- source/action/target 三段在真实时长下连续，身份与轮廓人工评分均不低于 4/5。

### 编排级

- working、awake_rest、sleeping 各连续观察至少 10 分钟。
- 同一 ambient 不连续；冷却与 `maxConsecutive` 可由固定随机种子复现。
- 业务事件同一 event ID 只播放一次，过期事件和恢复前事件不补播。
- 晚到完成事件不破坏当前动作。

### 产品级

- 每种 BaseState 单击 10 次，全部触发状态对应 ack 或确定性 fallback。
- 长按拖拽 5 次，覆盖左右方向、短/长距离、窗口边缘、拖拽后立即点击。
- 菜单与 Modal 输入锁、穿透锁成对恢复。
- Windows 11 单显示器 100%、125%、150% DPI 的尺寸、脚底线、方向和命中稳定。
- 2 小时无动画卡死、重复 timer、日志刷屏、命中漂移或持续异常资源增长。
- 包损坏、窗口关闭和 WebView 导航失败不影响收入主线。

## 日志 / 埋点 / 人工检查

- 动作：`pet_action_requested/selected/started/frame/finished/interrupted/timed_out/recovered`。
- 调度：`pet_scheduler_candidate_rejected/cooldown_hit/max_consecutive_hit`。
- 输入：`pet_input_press_pending/click/drag_started/drag_direction/drag_released/context_locked/unlocked`。
- 业务：`pet_business_event_created/queued/played/duplicate/expired/dropped`。
- 包：`pet_package_validated/rejected/fallback_loaded/disabled`。
- 命中：`pet_hitmask_applied/passthrough_suspended/restored/update_failed`。
- 隔离：`pet_sandbox_fault/mainline_health_check`。
- 人工证据：真实时长 GIF、Contact Sheet、边界图、30 分钟审查表、2 小时资源曲线和操作录屏。

日志禁止包含 API Key、Prompt 全文、用户薪资、绝对素材源路径或未脱敏个人信息。

## 通过标准

1. 所有 P0 自动门禁通过。
2. Runtime Spike 与 Quality Spike 均满足继续条件且没有命中停止条件。
3. 项目所有者对黄金样片与 30 分钟观感明确批准。
4. 回滚演练能恢复零宠物主线，且 current gate 仍通过。
5. 五项公开范围决策完成后，才可讨论 `Product return approved`。

## 不通过处理

- 动作质量失败：最多三轮；之后转绑定/手工或停止回归。
- 动态命中失败：先评估原生 hit-test 桥；仍需矩形吞点击则停止方案 B。
- 主线隔离失败：停止同进程 WebView 方案，重新进入 `/idea`。
- 长期观感失败：减少动作频率、重做动作节奏，不以增加更多动作解决。
- 包或许可失败：拒绝加载，不降级为忽略校验。

## 关键测试接缝

| 验收标准 | 可观察结果 | 接口 / 状态 / 故障注入点 | 证据 |
| --- | --- | --- | --- |
| 不重复计算业务 | 相同 Dashboard fixture 得到确定 BaseState/event ID | 可替换 DashboardSnapshot source 与时钟 | 状态机测试与事件日志 |
| 动作真实完成 | 最后一帧显示完后仅一次 finished | 可注入帧时钟与 actionInstanceId | 播放器单测、录屏 |
| 晚到事件无害 | 旧 ID finished 被丢弃 | 可延迟/乱序完成事件 | 状态机组合测试 |
| 透明命中同步 | 可见点命中、透明点穿透 | 可替换 hitMask 与 DPI | 原生 hit-test 日志、Computer Use |
| 包损坏隔离 | 沙盒禁用，主线仍健康 | manifest/atlas/hash/license 故障 fixture | 日志与主线冒烟 |
| 低重复可复现 | 相同 seed 得到相同动作序列 | RNG 与调度时钟注入 | 30 分钟序列报告 |

## 验证层级与门禁时点

- L0：文档、schema、状态表与静态检查，阻塞 Spike 开始。
- L1：测试 fixture、播放器模拟与固定 seed 编排，阻塞候选窗口运行。
- L2：真实 Tauri/WebView、Computer Use、三 DPI、30 分钟与 2 小时，阻塞 `LMM sandbox pass`。
- L3：项目所有者视觉审查与回滚确认，阻塞 `Product return approved`。
- L4：公开后数据不在本 PRD；公开版本尚未获批准。
- Agent 模拟不能替代真实桌面命中、长期观感或项目所有者批准。

## 风险与开放问题

1. Tauri 同进程 WebView 可能无法提供所需故障隔离。
2. Windows 透明命中桥在三 DPI 下的性能与稳定性未知。
3. Classic 新动作生产路线尚未证明能稳定超过 S4.3 的观感。
4. 本机 ComfyUI 节点与官方 H3 当前能力不一致，需执行前重新选路。
5. MiniMax 生成内容的正式再分发和披露边界仍需按当期条款确认。
6. PET-DEC-001 至 005 未关闭，公开范围不能冻结。

## 完整 PRD 门禁检查

- [x] 沙盒入口到销毁、失败与回滚链路已写清。
- [x] 包、状态、输入、调度、业务事件与命中合同已写清。
- [x] 前端、Rust/Tauri、配置、日志、文件、第三方和既有体验影响已写清。
- [x] 两条 Spike 的状态、数据和验收表达物已点名。
- [x] 承重假设有继续、停止和回写位置。
- [x] P0/P1/P2、非目标与范围保护已写清。
- [ ] 五项公开范围决策已确认。
- [ ] 公开回归 UI 高保真原型已更新并完成浏览器验证。
- [ ] 已获得执行 Spike 或开发承接授权。

结论：**具备执行两条 Spike 的合同条件，但当前没有执行授权；不具备正式产品回归开发条件。**

## 下一阶段建议

1. 项目所有者可分别授权 Runtime Spike 与不依赖 AI 的 Quality Spike；两条可并行，但证据和工作区必须独立。
2. `PET-DEC-004`、`PET-DEC-005` 关闭前不得执行 MiniMax 子实验；其余未决项不阻塞纯技术/手工样片 Spike。
3. PET-DEC-001 至 005 必须在公开范围冻结前全部关闭。
4. 两条 Spike 都通过后，再回写候选参数、命中职责与正式宠物范围。
5. 任一 P0 失败，保留 v1 零宠物主线并停止本方向，不生成正式版本号。
