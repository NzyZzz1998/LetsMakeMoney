# LetsMakeMoney v0.4 Beta 进度

**拆分日期**: 2026-07-08
**来源文件**: doc/progress.md
**说明**: 本文件复制自原跨版本大文档的 v0.4 章节。原文档暂不删除，后续以本文件作为 v0.4 快速阅读入口；如两者冲突，以 doc/current.md、doc/releases/v0.4/status.md 和最新验证文档为准。

---

## v0.4 Beta

### v0.4 计划 Review 结论

v0.4 Beta 是 v0.3 原生能力完成后的大型体验优化版本。根据 PRD 和 implementation-plan，v0.4 不再把主要风险放在“能否创建托盘/透明窗口/点击穿透”，而是围绕用户长期使用时最容易感知到的细节进行系统打磨。

- **原型先行**：v0.4 先通过现有 `doc/prototypes/index.html` 和 `prototype-spec.md` 确认默认桌宠形态、Panel、设置页、托盘找回和发布包说明，再进入实现。
- **默认温暖陪伴型**：v0.4 统一默认视觉、动效、Panel 和文案方向，但不实现主题系统、多主题切换、主题商店或用户自定义主题。
- **动画是主线之一**：橘猫动画需要从“能显示”升级为“状态可感知、动作自然、帧间稳定”，但按素材管线优先推进，质量达标才替换默认素材。
- **交互手感是主线之一**：单击、双击、长按、拖拽、右键菜单要形成清晰优先级，不能靠偶然命中。
- **窗口体验仍需继续打磨**：v0.3 已实现点击穿透和透明窗口，v0.4 需要加入可观测调试能力，校准边界场景。
- **设置体验需要从工程可用升级到用户可理解**：保存状态、禁用原因、恢复默认、纯桌宠模式说明都要更清楚。
- **发布体验要规范化**：v0.4 发布形态为正式 Zip beta 包，包含 exe、native dll、README、release notes、manifest/checksum，不做安装器和自动更新。

### v0.4 总体进度概览

| 里程碑 | 模块 | 状态 | 完成度 |
|--------|------|------|--------|
| **V04-M0** | 原型与体验规格 | ✅ 完成 | 23/23 |
| **V04-M1** | 橘猫动画与素材管线 | 🚧 进行中 | 30/31 |
| **V04-M2** | 交互手感优化 | ✅ 首轮完成 | 15/15 |
| **V04-M3** | 窗口、点击穿透与 Panel 打磨 | ✅ 首轮完成 | 20/20 |
| **V04-M4** | 设置体验与保存反馈 | ✅ 首轮完成 | 17/17 |
| **V04-M5** | 性能、稳定性与发布包 | ✅ 自动验证完成 | 19/19 |
| **V04-M6** | UI polish 与交互原型完善 | 🚧 Panel、右键二级菜单、紧凑暖色 Settings、图标资源、右键菜单视觉质量、设置工具按钮和 UI polish 验证项已形成测试态；新版单一原型已重置，完整 UI polish 手动复测仍待确认 | 50/52 |
| **V04-DOC** | v0.4 验证文档与发布记录 | 🚧 进行中 | 8/9 |

**v0.4 总进度**: 182/187（约 97%；V04-M0 完成，V04-M1 动画规格、v2 素材目录、素材记录、提示词执行集、asset manifest、Godot 资源构建器、SpriteFrames / PetResource 资源、缺帧门禁、v0.3 资源回退策略、素材生成产能路线文档、ComfyUI 环境验证和橘猫 v2 beta 默认接入完成；V04-M2 交互手感首轮完成；V04-M3 窗口、点击穿透、Panel 边缘定位、可找回兜底和缩放边界验证首轮完成；V04-M4 设置体验首轮完成；V04-M5 日志分层、自动验证覆盖、no-op native 缓存、发布包脚本、checksum 校验、发布包烟测和 60 秒 release 稳定性烟测完成；V04-M6 已完成 Panel 暖色便签、右键菜单二级入口、图标资源、紧凑 Settings 多轮打磨和新版当前状态单一交互原型重置；剩余重点是按新版原型进行完整 UI polish 手动复测和必要修正）。

### v0.4 边界与不可做项

- v0.4 默认体验方向固定为“温暖陪伴型”，不引入主题切换控件。
- 多主题、主题商店、用户自定义主题进入后续独立规划，不进入 v0.4。
- v0.4 仅正式验证 Windows x86_64，不实现 macOS / Linux 原生托盘、穿透和任务栏隐藏。
- v0.4 发布形态为 Zip beta 包，不做安装器和自动更新。
- v0.4 不重写 Godot 架构，不替换主引擎。

### v0.4 V04-M0. 原型与体验规格

#### 模块 V04-M0.1: 默认桌宠体验原型

- [x] V04-M0.1.1 在 `doc/prototypes/index.html` 增加 v0.4 默认桌宠画面，包含透明桌面背景、小猫、折叠态 Panel、托盘入口说明
- [x] V04-M0.1.2 原型默认视觉采用温暖陪伴型，体现柔和、轻量、低压力、长期常驻不打扰
- [x] V04-M0.1.3 原型保留薪资金额、工作状态、进度、设置入口，不能变成纯装饰展示
- [x] V04-M0.1.4 原型中不得出现“选择主题 / 主题商店 / 自定义主题 / 切换主题”等 v0.4 范围外入口
- [x] V04-M0.1.5 在 `doc/prototypes/prototype-spec.md` 记录 v0.4 默认体验方向和主题系统后置边界

#### 模块 V04-M0.2: Panel 折叠、展开和边缘原型

- [x] V04-M0.2.1 补充 Panel 折叠态原型，金额垂直居中，信息密度低，常驻时不遮挡桌面
- [x] V04-M0.2.2 补充 Panel 展开态原型，包含今日已赚、本月累计、时薪、工作进度、当前状态
- [x] V04-M0.2.3 补充靠右时向左展开、靠左时向右展开、靠底时向上展开、靠顶时不超出可见区
- [x] V04-M0.2.4 在 prototype spec 中记录 Panel 与小猫距离原则：不贴脸、不离太远、不遮挡小猫主体
- [x] V04-M0.2.5 在 prototype spec 中记录 Panel 展开/收起动画节奏：轻量、短促、不抢小猫反馈

#### 模块 V04-M0.3: 设置页关键状态原型

- [x] V04-M0.3.1 设置页原型继续保留 Salary / Pet / Display / Panel / General 五类
- [x] V04-M0.3.2 Display 页原型解释窗口模式、透明度、缩放、纯桌宠模式、点击穿透之间的关系
- [x] V04-M0.3.3 General 页原型展示开机自启、关闭隐藏到托盘、Debug 模式、重置窗口位置、恢复默认设置
- [x] V04-M0.3.4 原型补充保存成功、保存失败、平台能力不可用、需要重启或重新显示窗口、无变化保存状态
- [x] V04-M0.3.5 设置页原型避免“窗口套窗口”观感，呈现为单一设置窗口或明确独立对话框

#### 模块 V04-M0.4: 托盘、隐藏与发布包体验原型

- [x] V04-M0.4.1 托盘菜单原型包含显示/隐藏窗口、设置、关于 LetsMakeMoney、退出
- [x] V04-M0.4.2 补充关闭窗口后隐藏到托盘的轻量提示，说明程序仍在运行并可通过托盘找回
- [x] V04-M0.4.3 补充发布包说明页草图，列出 exe、native dll、README、release notes、manifest、checksums
- [x] V04-M0.4.4 明确 v0.4 不提供安装器、不提供自动更新、不修改系统级安装目录

#### 模块 V04-M0.5: 原型验收

- [x] V04-M0.5.1 原型覆盖默认桌宠形态、Panel 折叠/展开、设置关键状态、托盘找回、发布包说明
- [x] V04-M0.5.2 原型说明与 PRD 中 v0.4 默认温暖陪伴方向一致
- [x] V04-M0.5.3 原型没有把主题系统写成 v0.4 必做功能
- [x] V04-M0.5.4 原型确认后再进入 V04-M1 到 V04-M5 的实现

### v0.4 V04-M1. 橘猫动画与素材管线

#### 模块 V04-M1.1: 动画素材规格

- [x] V04-M1.1.1 定义统一画布尺寸、透明边界、角色锚点、脚底基线和视觉中心
- [x] V04-M1.1.2 定义基础状态 `idle` / `working` / `resting` 的行为含义、循环方式和最低帧数
- [x] V04-M1.1.3 定义基础状态延伸动作 `<base>_clicked_single` / `<base>_clicked_double` 与通用 `clicked_hold` 的触发方式、持续时间和恢复规则
- [x] V04-M1.1.4 定义每个动画的推荐 FPS、循环/单次播放规则、状态切换过渡要求和帧间漂移阈值
- [x] V04-M1.1.5 建立素材命名规则和素材来源记录格式
- [x] V04-M1.1.6 建立动画验收标准：不裁切、不漂移、不闪烁、尺寸一致、透明边界干净
- [x] V04-M1.1.7 新增 `doc/v0.4-animation-spec.md` 并写入上述规格

#### 模块 V04-M1.2: 橘猫 v2 动画素材筛选

- [x] V04-M1.2.1 创建或整理 `assets/pets/cat/orange_v2/` 目录及 idle / working / resting / clicked_hold / `<base>_clicked_single` / `<base>_clicked_double` 子目录
- [x] V04-M1.2.2 生成或筛选 idle 动画，要求长期常驻不烦躁、不抢注意力（当前采用 imagegen concept 派生素材，idle 使用用户确认的偏瘦中性帧）
- [x] V04-M1.2.3 生成或筛选 working 动画，要求包含键盘、电脑、金币等工作/金钱道具，能看出正在赚钱或工作（当前采用集成电脑/金币姿态）
- [x] V04-M1.2.4 生成或筛选 resting 动画，要求先探索 sleepy sitting、lying down 和其他低动作休息姿态，再选择与 idle 明显区分的候选（当前采用蜷缩睡眠姿态）
- [x] V04-M1.2.5 生成或筛选 `<base>_clicked_single` 动画，要求 idle / working / resting 下各自短促、明确、轻量（idle 单击经人工多轮修帧后接入，working/resting 使用较稳定的短动作反馈）
- [x] V04-M1.2.6 生成或筛选 `<base>_clicked_double` 动画，要求 idle / working / resting 下均比单击更明显（idle 双击经人工确认后先接入 beta，working/resting 回到较稳定版本）
- [x] V04-M1.2.7 生成或筛选 clicked_hold 动画，要求可持续循环，松开后自然恢复（当前采用 gentle cheek-hold 姿态）
- [x] V04-M1.2.8 新增 `doc/v0.4-animation-assets-log.md`，记录工具、输入图、提示词、输出批次、筛选结论和接入成本

#### 模块 V04-M1.3: SpriteFrames 接入与回退

- [x] V04-M1.3.1 将质量达标的橘猫 v2 动画接入 `cat_orange_v2_sprite_frames.tres`
- [x] V04-M1.3.2 更新默认配置指向 `cat_orange_v2_resource.tres`，并让 PetManager 递归扫描嵌套资源目录
- [x] V04-M1.3.3 保留 v0.3 橘猫素材资源，不删除旧资源路径，确保可快速回退
- [x] V04-M1.3.4 接入前确认所有基础状态、base-specific 单击/双击延伸动作和 `clicked_hold` 都存在，缺失时验证失败而不是硬凑动画名
- [x] V04-M1.3.5 PetManager 状态恢复仍遵守基础状态 + 交互延伸模型，不能把单击、双击、长按重新写成基础状态

#### 模块 V04-M1.4: 动画验证

- [x] V04-M1.4.1 新增 `scripts/verify_v04.gd`，检查 SpriteFrames 包含 v0.4 要求的所有动画名
- [x] V04-M1.4.2 自动检查每个动画帧数不为 0，检查 FPS、loop 配置和资源路径有效性
- [x] V04-M1.4.3 自动检查 PetManager 基础状态与交互叠加状态恢复路径
- [x] V04-M1.4.4 新增 `scripts/verify_v04.ps1` 作为 PowerShell 验证入口
- [x] V04-M1.4.5 手动验证文档增加动画播放预览项，记录裁切、漂移、闪烁、状态不明显等问题

#### 模块 V04-M1.5: 素材生成产能路线 Spike

- [x] V04-M1.5.1 检查本地 SpriteCook / character-sprite 相关 skill，确认 SpriteCook 适合短期快速候选，但当前没有可直接调用的 SpriteCook MCP 工具
- [x] V04-M1.5.2 在 `doc/v0.4-animation-spec.md` 和 `doc/v0.4-animation-assets-log.md` 记录 SpriteCook、ComfyUI、本地编辑工具、Godot cutout 四条素材生产路线
- [x] V04-M1.5.3 记录当前路线决策：SpriteCook 做短期候选，ComfyUI 做中长期本地 Spike，本地编辑器负责修边和对齐，Godot cutout 作为确定性兜底
- [x] V04-M1.5.4 新增 ComfyUI setup / start / collect 辅助脚本，默认不下载模型，不把 ComfyUI 本体、模型、缓存或原始输出放入项目仓库
- [ ] V04-M1.5.5 完成 ComfyUI 本地最小验证，确认能否基于现有橘猫 reference 生成身份稳定的 idle / working / resting 候选（官方 ComfyUI 与秋叶 ComfyUI 运行环境均已验证；仍缺模型选择、权重下载、真实候选图生成和人工评审）
- [x] V04-M1.5.6 在接入默认 v2 前完成生产路线最终决策，明确主路线、备选路线、清理工具、剩余风险和人工确认结论（当前采用 imagegen concept + 用户人工筛选/修帧作为 v0.4 beta 默认；`cat_orange_v1` 保留回退，ComfyUI 继续作为长期产能 Spike）

### v0.4 V04-M2. 交互手感优化

#### 模块 V04-M2.1: 交互优先级

- [x] V04-M2.1.1 固定交互优先级：右键菜单 > 拖拽 > 长按 > 双击 > 单击 > hover > 自动基础状态
- [x] V04-M2.1.2 右键菜单弹出时不触发左键点击、双击或长按状态
- [x] V04-M2.1.3 鼠标移动超过拖拽阈值后，不再进入 `clicked_hold`
- [x] V04-M2.1.4 双击识别等待窗口内，不提前播放两次完整单击反馈
- [x] V04-M2.1.5 hover 只作为轻量提示，不打断正在播放的单击/双击/长按反馈
- [x] V04-M2.1.6 交互结束后恢复进入交互前的 `idle` / `working` / `resting`

#### 模块 V04-M2.2: 单击、双击、长按与拖拽反馈

- [x] V04-M2.2.1 单击反馈短促明确，播放时间不影响用户立刻继续拖拽或右键
- [x] V04-M2.2.2 双击反馈比单击更明显，且能稳定被识别
- [x] V04-M2.2.3 长按反馈约 0.5 秒后稳定出现，松开后自然恢复
- [x] V04-M2.2.4 拖拽移动继续以鼠标屏幕位移为准，不出现窗口移动过快或漂移
- [x] V04-M2.2.5 拖拽开始时暂停或覆盖长按反馈，拖拽结束后不造成动画卡死

#### 模块 V04-M2.3: 小猫 hover 与 Panel hover 协调

- [x] V04-M2.3.1 小猫 hover 只负责小猫轻量反馈，Panel hover 只负责 Panel 展开/收起
- [x] V04-M2.3.2 小猫 hover 和 Panel hover 同时存在时，Panel 展开优先保证信息可读，小猫维持轻量反馈
- [x] V04-M2.3.3 鼠标从小猫移动到 Panel 的过程中不出现面板疯狂展开/收起
- [x] V04-M2.3.4 Panel 收起后小猫能回自动状态

### v0.4 V04-M3. 窗口、点击穿透与 Panel 打磨

#### 模块 V04-M3.1: 点击穿透调试视图

- [x] V04-M3.1.1 Debug 模式增加命中区可视化开关，用户模式默认不显示
- [x] V04-M3.1.2 可视化至少区分 Pet core、Pet context、Panel collapsed、Panel expanded
- [x] V04-M3.1.3 日志输出每个命中区的屏幕坐标、尺寸、缩放倍率、窗口位置和刷新原因
- [x] V04-M3.1.4 设置/向导/关于窗口打开时穿透区域清空或进入安全模式，关闭后恢复
- [x] V04-M3.1.5 原生 hit-test / region 调用失败时写入可读日志，并保留可找回窗口状态

#### 模块 V04-M3.2: 命中区刷新与节流

- [x] V04-M3.2.1 命中区只在窗口移动、缩放变化、Panel 展开/收起、小猫尺寸变化、设置打开/关闭、Debug 模式切换时刷新
- [x] V04-M3.2.2 缩放变化后小猫、Panel 和右键上下文命中区同步刷新
- [x] V04-M3.2.3 Panel 展开/收起后 Panel 命中区同步刷新
- [x] V04-M3.2.4 刷新前比较上一次 rects，无变化时不重复调用 native region
- [x] V04-M3.2.5 高频刷新需要节流，但不能导致 Panel 展开后出现不可点击或不可穿透的旧区域

#### 模块 V04-M3.3: Panel 边缘定位与多缩放表现

- [x] V04-M3.3.1 窗口靠右时 Panel 优先向左展开
- [x] V04-M3.3.2 窗口靠左时 Panel 优先向右展开
- [x] V04-M3.3.3 窗口靠底时 Panel 优先向上展开，靠顶时不超出顶部可见区域
- [x] V04-M3.3.4 四角场景优先保证 Panel 完整可见，再保证距离小猫较近
- [x] V04-M3.3.5 验证 50%、75%、100%、125%、150%、200% 缩放下小猫不裁切、Panel 文字不溢出
- [x] V04-M3.3.6 Panel 折叠态金额继续保持垂直居中

#### 模块 V04-M3.4: 桌宠窗口可找回兜底

- [x] V04-M3.4.1 托盘不可用时保留任务栏入口和 Alt+Tab
- [x] V04-M3.4.2 纯桌宠模式开启前必须确认至少一种找回路径可用
- [x] V04-M3.4.3 native bridge 加载失败时回退普通窗口或 Debug 安全状态
- [x] V04-M3.4.4 配置文件损坏或字段缺失时使用默认值启动，保留窗口可见和设置入口

### v0.4 V04-M4. 设置体验与保存反馈

#### 模块 V04-M4.1: 设置窗口信息架构

- [x] V04-M4.1.1 保留 Salary / Pet / Display / Panel / General 五类，不新增 Theme 作为 v0.4 设置项
- [x] V04-M4.1.2 Display 页集中管理窗口模式、透明度、缩放、纯桌宠模式、点击穿透说明
- [x] V04-M4.1.3 Display 页解释这些设置对窗口是否可见、是否可找回、是否穿透鼠标的影响
- [x] V04-M4.1.4 General 页集中管理开机自启、关闭隐藏到托盘、Debug 模式、重置窗口位置、恢复默认设置
- [x] V04-M4.1.5 平台不可用能力显示禁用原因，不静默失败
- [x] V04-M4.1.6 设置窗口呈现为单一窗口，不再出现“宿主窗口套设置窗口”的观感

#### 模块 V04-M4.2: 保存差异检测与反馈

- [x] V04-M4.2.1 保存前对比当前配置与表单值，无变化时不重复写 config
- [x] V04-M4.2.2 无变化时不重复写注册表、不重复调用 native，并显示“没有需要保存的更改”或轻量成功提示
- [x] V04-M4.2.3 salary / schedule 只写配置并刷新薪资
- [x] V04-M4.2.4 opacity / scale 只在变化时写配置并刷新窗口/Panel
- [x] V04-M4.2.5 window mode / pure pet mode 只在变化时写配置并重新应用窗口策略
- [x] V04-M4.2.6 auto start 只在状态变化时写入或删除注册表
- [x] V04-M4.2.7 保存成功显示轻量状态提示，保存失败显示可读错误并保留用户输入

#### 模块 V04-M4.3: 恢复默认与调试入口

- [x] V04-M4.3.1 增加或明确“重置窗口位置”入口，执行后窗口回到安全可见区域
- [x] V04-M4.3.2 增加或明确“恢复默认设置”入口，执行前给出轻量确认
- [x] V04-M4.3.3 恢复默认不删除薪资等核心用户数据，除非用户明确选择
- [x] V04-M4.3.4 Debug 模式说明写清 `%APPDATA%\LetsMakeMoney\config.json` 配置路径和生效方式

### v0.4 V04-M5. 性能、稳定性与发布包

#### 模块 V04-M5.1: 常驻性能与日志整理

- [x] V04-M5.1.1 普通模式只保留错误、启动/退出、native 初始化结果、托盘创建失败、保存失败等关键日志
- [x] V04-M5.1.2 Debug 模式才输出命中区 rects、native region 刷新原因、Panel 展开/收起原因、托盘轮询命令
- [x] V04-M5.1.3 限制 mouse passthrough region、taskbar / Alt+Tab visibility、window opacity、window topmost 的无变化重复调用
- [x] V04-M5.1.4 确认 Panel 金额刷新仍按节流执行，不因为动画或窗口调试视图变高频
- [x] V04-M5.1.5 长时间运行后托盘、点击穿透、窗口位置、Panel 展开和设置保存仍正常（已补充 `verify_v04_stability.ps1` 覆盖 release 包 60 秒无崩溃烟测；真实托盘、点击穿透、Panel 和设置保存仍需人工按 `doc/verification/v0.4.md` 复测）

#### 模块 V04-M5.2: 自动验证与回归验证

- [x] V04-M5.2.1 `verify_v04.gd` 覆盖动画资源存在、动画帧数不为 0、PetManager 状态接口存在
- [x] V04-M5.2.2 `verify_v04.gd` 覆盖设置场景可加载、Main 场景可加载、关键配置默认值存在
- [x] V04-M5.2.3 `verify_v04.ps1` 能以 PowerShell 入口运行并输出 `v0.4 verification passed`
- [x] V04-M5.2.4 v0.4 发布前继续运行 `verify_v02.ps1`
- [x] V04-M5.2.5 v0.4 发布前继续运行 `verify_v03.ps1`
- [x] V04-M5.2.6 v0.4 发布前运行 v0.4 等价导出验证

#### 模块 V04-M5.3: 正式 Zip beta 发布包

- [x] V04-M5.3.1 新增 `scripts/package_v04.ps1` 或等价发布打包脚本
- [x] V04-M5.3.2 发布包命名为 `LetsMakeMoney-v0.4-beta-windows-x86_64.zip`
- [x] V04-M5.3.3 Zip 内包含 `LetsMakeMoney.exe`
- [x] V04-M5.3.4 Zip 内包含 Windows native DLL，并与 exe 位于可被加载的位置
- [x] V04-M5.3.5 Zip 内包含中文 README 或快速开始说明
- [x] V04-M5.3.6 Zip 内包含 v0.4 beta release notes
- [x] V04-M5.3.7 Zip 内包含 `manifest.json` 与 `checksums.txt`
- [x] V04-M5.3.8 发布包解压到全新目录后 exe 能启动，native dll 能被加载，配置路径仍为 `%APPDATA%\LetsMakeMoney`

### v0.4 V04-M6. UI polish 与交互原型完善

#### 模块 V04-M6.1: UI polish 需求、规格与计划同步

- [x] V04-M6.1.1 在 PRD 中将 UI polish 明确为 v0.4 正式需求，不作为主题系统或后续口头优化
- [x] V04-M6.1.2 在 `doc/v0.4-ui-polish-spec.md` 明确“极简生产力小工具 + 宠物陪伴”的默认体验方向
- [x] V04-M6.1.3 在 `doc/implementation-plan.md` 增加 V04-M6 里程碑，承接 UI polish、原型、Panel、设置和验证任务
- [x] V04-M6.1.4 在 `doc/progress.md` 新增 V04-M6 总览和模块级 checklist
- [x] V04-M6.1.5 将最新 PRD 中的 Win11 设置窗口、右键二级菜单、托盘/窗口图标要求同步补齐到 `doc/implementation-plan.md`
- [x] V04-M6.1.6 将最新 UI polish 交互说明同步补齐到 `doc/prototypes/prototype-spec.md`

#### 模块 V04-M6.2: 可交互原型 UI polish 更新

- [x] V04-M6.2.1 在 `doc/prototypes/index.html` 增加或更新 v0.4 UI polish 屏，展示 Win11 风格设置窗口结构
- [x] V04-M6.2.2 原型设置窗口从顶部小 Tab 过渡为左侧分类导航 + 右侧卡片式内容
- [x] V04-M6.2.3 原型设置窗口增加“查找设置”搜索入口或明确的禁用占位
- [x] V04-M6.2.4 原型展示右键菜单的 `窗口模式 >` 二级菜单，包含 `置顶悬浮` / `融入桌面` 和当前项标记
- [x] V04-M6.2.5 原型展示右键菜单的 `选择宠物 >` 二级菜单，包含当前橘猫项和单宠物状态说明
- [x] V04-M6.2.6 原型展示托盘图标、窗口图标、exe 图标的目标观感或尺寸说明
- [x] V04-M6.2.7 原型保留 Panel `对照 / 折叠 / 展开`、业务状态、设置反馈和设置分类切换交互
- [x] V04-M6.2.8 原型图片资源继续使用项目内真实路径，不能回到失效历史目录

#### 模块 V04-M6.3: Panel UI polish 实现

- [x] V04-M6.3.1 折叠态 Panel 从“单独金额”升级为“金额 + 短状态”
- [x] V04-M6.3.2 折叠态不显示进度条、今日/本月/时薪等明细，保持常驻区轻量
- [x] V04-M6.3.3 展开态信息层级调整为：今日已赚优先，状态辅助，本月累计/时薪/工作进度作为详情
- [x] V04-M6.3.4 Panel 样式对齐 UI polish 规格：暖墨半透明、轻边框、低压迫感、数字稳定
- [x] V04-M6.3.5 Panel 展开/收起动画轻量、可中断，不抢小猫主体反馈
- [x] V04-M6.3.6 Panel 在 100% / 150% / 200% 缩放下文字不溢出，折叠态金额和短状态垂直居中

#### 模块 V04-M6.4: Win11 风格设置窗口实现

- [x] V04-M6.4.1 `settings_dialog.gd` / `settings_dialog.tscn` 改为单一设置窗口内的左侧分类导航 + 右侧内容区结构
- [x] V04-M6.4.2 左侧分类保留 Salary / Pet / Display / Panel / General，不新增 Theme / Appearance / 主题入口
- [x] V04-M6.4.3 右侧内容使用卡片式设置项，标题、说明和控件在同一卡片中保持关联
- [x] V04-M6.4.4 顶部增加“查找设置”搜索入口或禁用占位，当前不实现真实搜索时必须不影响键盘焦点和保存
- [x] V04-M6.4.5 Display 页保持透明度、缩放、窗口模式、纯桌宠、点击穿透说明集中管理
- [x] V04-M6.4.6 General 页保持开机自启、关闭隐藏到托盘、Debug、重置窗口位置、恢复默认设置集中管理
- [x] V04-M6.4.7 保存反馈继续覆盖已保存、无变化、需重显、保存失败，并显示在设置窗口内部
- [x] V04-M6.4.8 设置窗口不出现宿主窗口套设置窗口、宠物装饰化设置页或营销式介绍卡片
- [x] V04-M6.4.9 返回/关闭按钮从通用填充按钮拆为紧凑窗口工具按钮，常态低调、hover 清晰、关闭按钮具备克制危险态
- [x] V04-M6.4.10 设置窗口字体渲染启用中文系统字体、LCD antialias 和正常 hinting，避免靠单纯放大解决清晰度

#### 模块 V04-M6.5: 右键菜单二级入口实现

- [x] V04-M6.5.1 移除右键菜单中“设置窗口模式”和“选择宠物”的平铺快速入口
- [x] V04-M6.5.2 新增 `窗口模式 >` 一级菜单项，鼠标悬停时右侧展开子菜单
- [x] V04-M6.5.3 `窗口模式` 子菜单包含 `置顶悬浮`、`融入桌面`，当前模式有勾选或高亮反馈
- [x] V04-M6.5.4 新增 `选择宠物 >` 一级菜单项，鼠标悬停时右侧展开可用宠物列表
- [x] V04-M6.5.5 当前只有一个宠物时仍显示当前项，但禁用不可用切换或标记为当前，不报错
- [ ] V04-M6.5.6 子菜单靠屏幕右侧时不超出屏幕，必要时向左展开
- [ ] V04-M6.5.7 二级菜单展开不破坏右键命中区、点击穿透、拖拽恢复、托盘降级入口和退出保存流程
- [x] V04-M6.5.8 主菜单和二级菜单使用统一自定义 Theme，不再依赖 Godot 默认 PopupMenu 视觉
- [x] V04-M6.5.9 菜单视觉以“小而清晰”为目标：15px 系统字体、30px 行高、6px 圆角、轻边框、轻阴影和透明圆角背景

#### 模块 V04-M6.6: 托盘图标与窗口图标 polish

- [x] V04-M6.6.1 基于当前橘猫形象确定图标源图，优先保证小尺寸识别度
- [x] V04-M6.6.2 生成或整理 16 / 24 / 32 / 48 / 64 / 128 / 256 尺寸图标资源
- [x] V04-M6.6.3 为托盘准备小尺寸优化版本，必要时使用简化猫头或轮廓，不直接缩小完整身体图
- [x] V04-M6.6.4 更新 Godot export preset 使用最终 `.ico`
- [x] V04-M6.6.5 更新 Windows native 托盘图标加载路径，确保 release exe 使用同源或优化后的图标
- [x] V04-M6.6.6 关于窗口、README 或 release notes 中使用高分辨率应用图标，保持品牌识别统一

#### 模块 V04-M6.7: UI polish 验证与回归

- [x] V04-M6.7.1 `doc/verification/v0.4.md` 增加 UI polish 专项，覆盖 Panel、Win11 设置窗口、右键二级菜单和图标
- [x] V04-M6.7.2 `verify_v04.gd` 或 `verify_v04.ps1` 增加静态检查：不出现 Theme Tab / 主题商店作为 v0.4 设置入口
- [x] V04-M6.7.3 自动或静态验证设置窗口仍保留 Salary / Pet / Display / Panel / General 五类
- [x] V04-M6.7.4 自动或静态验证右键菜单存在 `窗口模式` 与 `选择宠物` 二级入口
- [x] V04-M6.7.5 自动或静态验证图标文件存在，导出预设引用路径有效
- [x] V04-M6.7.6 重新运行 `verify_v04.ps1`、`verify_v03.ps1`、`verify_v02.ps1` 和发布包验证，确认 UI polish 未破坏原生桌宠能力

### v0.4 V04-DOC. 验证文档与发布记录

#### 模块 V04-DOC.1: v0.4 手动验证文档

- [x] V04-DOC.1.1 新增 `doc/verification/v0.4.md`，沿用每个版本只保留一个验证文档的规则
- [x] V04-DOC.1.2 手动验证文档包含环境信息：Windows 版本、Godot 版本、exe 路径、是否清空配置
- [x] V04-DOC.1.3 验证表包含编号、操作步骤、预期行为、结果、备注、优化方案、复测结果
- [x] V04-DOC.1.4 验证范围覆盖原型确认、动画、交互、点击穿透、Panel、设置、托盘、发布包
- [x] V04-DOC.1.5 每个不通过项预留优化方案和复测结果，方便后续按文档修复

#### 模块 V04-DOC.2: Progress、Release Notes 和 Changelog

- [x] V04-DOC.2.1 v0.4 开发启动后，将 V04-M0 到 V04-M6、V04-DOC 状态持续同步到 progress
- [ ] V04-DOC.2.2 v0.4 每轮手动验证后，progress 记录当前通过率、阻塞项和下一步
- [x] V04-DOC.2.3 v0.4 发布前补齐中文 `releases/v0.4-beta-notes.md`
- [x] V04-DOC.2.4 `releases/CHANGELOG.md` 增加 v0.4 条目，保持中文

### v0.4 资源准备清单

| 资源 | 路径 | 负责模块 | 状态 |
|------|------|---------|------|
| v0.4 原型 | `doc/prototypes/index.html` / `doc/prototypes/prototype-spec.md` | V04-M0 | ✅ 已更新 |
| v0.4 UI polish 规格 | `doc/v0.4-ui-polish-spec.md` | V04-M6.1 | 🚧 已创建并补充 Win11 设置窗口、右键二级菜单、图标规格；仍需随实现继续校准 |
| v0.4 动画规格 | `doc/v0.4-animation-spec.md` | V04-M1.1 | ✅ 已创建 |
| v0.4 素材记录 | `doc/v0.4-animation-assets-log.md` | V04-M1.2 | ✅ 已创建 |
| v0.4 素材提示词执行集 | `doc/v0.4-animation-prompt-pack.md` | V04-M1.2 | ✅ 已创建 |
| v0.4 ComfyUI Spike | `doc/v0.4-comfyui-spike.md` / `scripts/check_comfyui_prereqs.ps1` / `scripts/setup_comfyui.ps1` / `scripts/start_comfyui.ps1` / `scripts/collect_comfyui_candidates.ps1` | V04-M1.5 | 🚧 本体、venv、Python 依赖、CUDA PyTorch 和本地 Web 启动已通过；模型/工作流/候选素材尚未完成 |
| 橘猫 v2 素材 | `assets/pets/cat/orange_v2/` / `asset-manifest.json` / `cat_orange_v2_sprite_frames.tres` / `cat_orange_v2_resource.tres` | V04-M1.2/V04-M1.3 | ✅ cutout 批次已拒绝；imagegen concept 派生候选经人工迭代后已作为 v0.4 beta 默认资源接入，`cat_orange_v1` 保留回退 |
| v0.4 自动验证 | `scripts/verify_v04.ps1` / `scripts/verify_v04.gd` | V04-M1/V04-M5 | ✅ 已创建 |
| v0.4 验证文档 | `doc/verification/v0.4.md` | V04-DOC | ✅ 已创建 |
| v0.4 发布说明 | `releases/v0.4-beta-notes.md` | V04-DOC | ✅ 已创建 |
| v0.4 发布包脚本 | `scripts/package_v04.ps1` | V04-M5.3 | ✅ 已创建并可生成 Zip |
| v0.4 发布包验证 | `scripts/verify_v04_package.ps1` / `scripts/verify_v04_stability.ps1` | V04-M5.2/V04-M5.3 | ✅ 已校验 manifest/checksum、发布包短烟测和 60 秒 release 稳定性烟测 |
| v0.4 秋叶 ComfyUI Spike | `scripts/check_comfyui_aki_prereqs.ps1` / `scripts/start_comfyui_aki.ps1` | V04-M1.5 | ✅ 外部秋叶环境、内置 Python/CUDA、关键节点和 Web 启动已验证；模型与真实生成待人工确认 |
| v0.4 UI 图标资源 | `icons/` / export preset / native tray icon path / 关于窗口 | V04-M6.6 | ✅ 多尺寸 PNG、ICO、导出预设、native 托盘路径和关于窗口图标首轮完成 |
| v0.4 发布清单 | `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64/manifest.json` / `checksums.txt` | V04-M5.3 | ✅ 已由打包脚本生成；`releases/v0.4/` 为本地发布产物目录，不入库 |

### v0.4 已知风险（降级方案）

### v0.4 后续优化清单（暂不阻塞当前收尾）

- [ ] `V04-OPT-001` / `V04-MAN-052` Wizard 薪资页控件视觉与 Settings 一致性专项优化。多轮局部修复后用户体感仍无明显变化，暂不继续在 v0.4 收尾阶段反复打补丁；后续应通过共享控件、共享 Theme、截图对比验收来整体解决 Wizard / Settings 控件系统不统一的问题。

| 风险 | 降级方案 |
|------|---------|
| 原型方向与 PRD 冲突 | 先修原型和 prototype spec，不进入实现 |
| 新动画素材质量不稳定 | 当前 v2 为 beta 默认，保留 v0.3 橘猫素材可回退，不让素材质量阻塞已有功能 |
| 部分动画缺失 | 验证失败，不用错误动画名硬凑 |
| ComfyUI 模型选择和工作流成本过高 | 先只做 idle / working / resting 三类最小候选验证；若身份稳定性或清理成本不达标，则回退 SpriteCook / 本地编辑 / Godot cutout 路线 |
| 动画接入导致状态机回退 | 保持基础状态 + 交互叠加状态模型，新增自动验证覆盖状态恢复 |
| 双击被单击吞掉 | 调整双击等待窗口，手动验证阻塞发布 |
| 长按影响拖拽 | 拖拽阈值触发后取消长按 |
| 点击穿透调优破坏右键菜单 | 保留右键专用上下文区域并增加调试视图，按场景逐项验证 |
| 设置体验重构引入保存回归 | 保存逻辑先加差异对比和测试，再调整 UI 布局 |
| 设置保存变慢 | 差异保存，无变化不写配置、不写注册表、不调用 native |
| Win11 风格设置窗口重构引入布局回归 | 先保留 Salary / Pet / Display / Panel / General 五分类和现有保存逻辑，再逐步替换布局；保存反馈和配置写入必须先通过验证 |
| 右键二级菜单破坏点击穿透或右键命中 | 先保持右键专用上下文区和菜单打开时清空/保护穿透区域；子菜单展开后增加真实桌面复测 |
| 图标小尺寸不可读 | 托盘 16/24 尺寸允许使用简化猫头或轮廓版本，不直接缩放完整大图 |
| UI polish 变成主题系统 | 不新增 Theme Tab、不新增主题商店、不新增多主题配置；主题系统继续作为后续独立规划 |
| 托盘不可用 | 保留任务栏 / Alt+Tab，禁止不可找回隐藏 |
| 发布包遗漏 native DLL | package / export 验证阻塞发布，并在 release notes 列出分发文件 |
| Zip 解压后无法运行 | 发布包验证阻塞 tag |

### v0.4 开发启动顺序

1. **V04-M0 原型与体验规格**：先确认默认温暖陪伴方向、Panel、设置、托盘和发布包说明。
2. **V04-M1 动画与素材管线**：先写规格，再筛素材，质量达标后接入并验证。
3. **V04-M2 交互手感优化**：在动画状态模型稳定后修正优先级和反馈。
4. **V04-M3 窗口、点击穿透与 Panel 打磨**：先做可观测调试，再调命中区和边缘定位。
5. **V04-M4 设置体验与保存反馈**：基于原型重整设置页，并修复保存耗时和反馈问题。
6. **V04-M5 性能、稳定性与发布包**：收敛日志、验证脚本、Zip 包和发布说明。
7. **V04-M6 UI polish 与交互原型完善**：以当前单一交互原型为准，继续对齐紧凑暖色 Settings、右键二级菜单、托盘/窗口图标和 Panel 便签体验，再进入完整 Godot UI 手动验证。
8. **V04-DOC 文档闭环**：开发过程中同步验证结果，发布前统一 PRD / Plan / Progress / Verification / Release Notes。

---

