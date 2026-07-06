# LetsMakeMoney 赚钱模拟器 — 总体进度

> 本文档作为整个项目的总体进度跟踪，按版本和模块组织 Vibe Coding 最小可执行任务。每个模块对应一组 checklist，完成时勾选。完整实施细节参见 `implementation-plan.md`，需求细节参见 `LetsMakeMoneyPRD.md`。

**最后更新**: 2026-07-05
**当前阶段**: v0.3 Beta 已完成并进入 `v0.3beta` 发布状态；v0.4 Beta 已启动，V04-M0 原型与体验规格已完成，V04-M1 动画规格、素材目录、提示词执行集、素材记录、橘猫 v2 beta 默认资源接入和自动/手动验证骨架已完成，V04-M2 交互手感首轮优化已完成，V04-M3 已完成点击穿透调试、刷新日志、Panel 边缘定位、刷新节流和窗口可找回兜底验证，V04-M4 设置体验首轮完成，V04-M5 日志分层、自动验证覆盖、no-op native 缓存、发布包脚本、checksum 校验、发布包烟测和 60 秒稳定性烟测完成；V04-M6 UI polish 已纳入正式范围，已完成 Win11 风格设置窗口、设置项卡片化、设置页非装饰化门禁、右键二级菜单、托盘/窗口图标、关于窗口图标、Panel polish 二轮尺寸/字号提升、设置窗口 borderless 自绘宿主、折叠态布局门禁、UI polish 专项验证文档和发布包刷新验证
**当前里程碑**: Windows native bridge 已可通过 MSYS2 UCRT64 构建，真托盘、透明窗口、点击穿透、右键菜单、关闭隐藏到托盘、设置入口、导出烟测和手动复测均已通过；v0.4 已将当前橘猫 v2 imagegen concept 派生素材接入默认体验并保留 `cat_orange_v1` 回退，下一步优先推进 V04-M6 UI polish 实现与验证，再进入多缩放人工验证、真实桌面长时间体验复测和 ComfyUI 最小候选 Spike

---

## 版本总览

| 版本 | 阶段 | 平台 | 状态 |
|------|------|------|------|
| v0.1 | Beta | Windows | ✅ Beta 调试窗口版已打包归档 |
| v0.2 | Beta | Windows | 🧪 稳定候选；核心交互/设置/自启/素材/验证已完成，真实托盘与透明穿透暂缓 |
| v0.3 | Beta | Windows x86_64 | ✅ 已完成 native bridge、真托盘控制器、透明窗口控制器、点击穿透区域模型、右键菜单修复、纯桌宠门禁、设置修正、构建脚本、导出烟测和手动验证复测；发布 tag 为 `v0.3beta` |
| v0.4 | Beta | Windows x86_64 | 🚧 进行中；大型体验优化版本，V04-M0-M5 首轮完成，V04-M6 UI polish 已新增为正式模块，重点推进 Win11 风格设置窗口、右键二级菜单、Panel 信息层级和托盘/窗口图标优化 |
| v1.0 | 正式版 | Windows | 🗓 未开始 |
| v2.0 | 跨平台 | + macOS | 🗓 未开始 |
| v3.0 | 移动端 | + iOS/Android | 🗓 未开始 |

---

## v0.1 Beta

### v0.1 总体进度概览

| 里程碑 | 模块 | 状态 | 完成度 |
|--------|------|------|--------|
| **M1** | 项目搭建 + Config | ✅ 完成 | 5/5 |
| **M1** | PlatformInterface | ✅ 完成 | 4/4 |
| **M1** | SalaryEngine | ✅ 完成 | 7/7 |
| **M1** | PetResource | ✅ 完成 | 3/3 |
| **M2** | PetManager | ✅ 完成 | 6/6 |
| **M2** | Pet 场景 + 状态机 | ✅ 完成 | 8/8 |
| **M2** | 占位素材准备 | ✅ 完成（用兔子素材占位） | 4/4 |
| **M3** | PanelSystem | ✅ 完成 | 5/5 |
| **M3** | Panel 场景 | ✅ 完成 | 6/6 |
| **M3** | DragResizeSystem | ✅ 完成（托盘为降级方案） | 5/5 |
| **M3** | Main 场景整合 | ✅ 完成（调试窗口版） | 6/6 |
| **M4** | 设置对话框 | ✅ 完成（开机自启禁用占位） | 7/7 |
| **M4** | 首次启动向导 | ✅ 完成 | 6/6 |
| **M5** | 打包发布 | ✅ 完成 | 3/3 |

**v0.1 总进度**: 75/75 任务代码完成（100%），M1-M5 代码完成，M3/M4/M5 自动验证通过并完成手动反馈修复。实际交付为“普通调试窗口版 Beta”：核心业务、设置、向导、交互和打包可用，但默认透明桌宠、真实系统托盘、开机自启仍未实现，统一转入 v0.2 Beta。

### v0.1 实际交付说明

| 主题 | 实际状态 | 后续处理 |
|------|----------|----------|
| 窗口形态 | 普通 900×500 调试窗口，`DebugInputArea` / `DebugStatus` 可见 | v0.2 拆分默认桌宠模式和 Debug 模式 |
| 透明窗口 | v0.1 为输入稳定关闭透明和无边框 | v0.2 重新实现透明无边框桌宠 |
| 交互 | 单击、双击、长按、拖拽、右键菜单可用 | v0.2 回归角色区域直接命中和空白穿透 |
| 系统托盘 | 仅 PopupMenu 降级，非真托盘 | v0.2 必做真实系统托盘 |
| 开机自启 | 设置中禁用占位 | v0.2 必做 Windows 当前用户自启动 |
| 素材 | 单一 cat 资源，兔子 sprite 占位；app icon 已换成小猫图标 | v0.2 仅做素材 Spike，质量达标才接入 |

### v0.1 M1. 基础设施

#### 模块 1.1: 项目搭建 + Config Autoload

- [x] 1.1.1 在 Godot 4.x 中新建项目，路径 `<PROJECT_ROOT>\`，渲染器选 Compatibility
- [x] 1.1.2 创建目录结构：`src/autoload/`、`src/scenes/`、`src/resources/`、`src/platform/`、`assets/pets/`、`icons/`，添加 `.gitignore` 忽略 `.godot/`
- [x] 1.1.3 编写 `src/autoload/config.gd`（含 `_defaults()`、`_load()`、`save()`、`get_value()`、`set_value()`、`has_config()`、`config_changed` 信号）
- [x] 1.1.4 在 project.godot 中注册 `config.gd` 为 Autoload，名称 `Config`
- [x] 1.1.5 运行项目，Console 无报错，Config 初始化完成

#### 模块 1.2: PlatformInterface 跨平台抽象层

- [x] 1.2.1 编写 `src/platform/platform_interface.gd`，用 `class_name PlatformInterface` + 虚函数，作为抽象基类
- [x] 1.2.2 编写 `src/platform/windows_platform.gd`，`class_name WindowsPlatform extends PlatformInterface`，实现 `get_config_path()` 返回 `%APPDATA%/LetsMakeMoney/config.json`
- [x] 1.2.3 实现 `WindowsPlatform.setup_window()`（设置 borderless / transparent_bg / unresizable）
- [x] 1.2.4 编写 `src/autoload/platform.gd` 作为 Autoload `Platform`，在 `_ready()` 中根据 OS 创建对应平台实例并暴露接口

#### 模块 1.3: SalaryEngine 薪资引擎

- [x] 1.3.1 编写 `src/autoload/salary_engine.gd` 骨架，注册为 Autoload `SalaryEngine`
- [x] 1.3.2 实现 `_calc_work_days(year, month, mode)` — 根据日历和休息模式计算当月工作天数
- [x] 1.3.3 实现 `_days_in_month(year, month)` — 含闰年判断
- [x] 1.3.4 实现 `is_working_hours()` — 基于当前时间和上下班时间判定
- [x] 1.3.5 实现 `get_earnings_today()` — 处理上班前/工作中/下班后三时段
- [x] 1.3.6 实现 `get_earnings_this_month()` 和 `get_work_progress()`
- [x] 1.3.7 实现 `get_state_text()` 和 `_process` 中跨日/跨月自动 `_recalculate()`

#### 模块 1.4: PetResource 自定义 Resource

- [x] 1.4.1 编写 `src/resources/pet_resource.gd`，`class_name PetResource`，含 `pet_id`/`display_name`/`sprite_frames`/`thumbnail`/`animation_speeds` 字段
- [x] 1.4.2 在 Godot 编辑器中创建 `assets/pets/cat/cat_resource.tres`（New Resource → PetResource）
- [x] 1.4.3 验证 tres 文件可被编辑器识别，不报错

### v0.1 M2. 角色系统

#### 模块 2.1: PetManager Autoload

- [x] 2.1.1 编写 `src/autoload/pet_manager.gd` 骨架，定义 `PetState` 枚举（IDLE/WORKING/RESTING/HOVER/CLICKED_SINGLE/CLICKED_DOUBLE/CLICKED_HOLD）
- [x] 2.1.2 实现 `_scan_pets()` — 扫描 `assets/pets/` 下所有子目录加载 `*_resource.tres`
- [x] 2.1.3 实现 `switch_pet(pet_id)` — 切换当前角色并写入 Config
- [x] 2.1.4 实现 `request_state(new_state)` — 统一状态入口，带状态变化信号 `state_changed`
- [x] 2.1.5 实现 `_process()` 中根据 SalaryEngine 工作时间自动切换 WORKING/RESTING（仅在非 HOVER/CLICKED 时）
- [x] 2.1.6 注册 PetManager 为 Autoload，验证 `_scan_pets()` 正常加载 cat

#### 模块 2.2: Pet 场景 + 状态机

- [x] 2.2.1 在编辑器中创建 `src/scenes/pet/pet.tscn`（Node2D + AnimatedSprite2D + Area2D + CollisionShape2D）
- [x] 2.2.2 编写 `src/scenes/pet/pet.gd`，`_setup_from_resource()` 从 PetManager.current_pet 加载 sprite_frames
- [x] 2.2.3 连接 PetManager 信号 `state_changed`，由 PetManager 驱动动画播放，pet.gd 不自管状态
- [x] 2.2.4 实现 Area2D 的 `mouse_entered/_exited` → 调用 `PetManager.request_state(HOVER/回退)`
- [x] 2.2.5 实现 `_input()` 中左键单击/双击/长按判定（长按按下立即触发，松开恢复）
- [x] 2.2.6 实现拖拽逻辑：按下且移动超过阈值 → 进入拖拽模式，调用 `DragResizeSystem` 移动窗口
- [x] 2.2.7 实现右键调用 `DragResizeSystem.show_context_menu()`
- [x] 2.2.8 验证所有交互响应正确，无状态卡死

#### 模块 2.3: 占位素材准备

- [x] 2.3.1 下载免费 sprite sheet（兔子素材包，含 idle/walk）到 `assets/pets/cat/raw/`（v0.1 占位用兔子，v1.0 换真猫）
- [x] 2.3.2 在 Godot 编辑器中创建 `cat_sprite_frames.tres`，配置 idle/resting/hover/clicked_single/double/hold 动画帧
- [x] 2.3.3 用 walk_side 当 working 动画（侧面走路代替敲键盘，v1.0 替换）
- [x] 2.3.4 将 sprite_frames 引用填入 `cat_resource.tres`，验证运行时角色可见、动画播放正常

### v0.1 M3. UI 与交互

#### 模块 3.1: PanelSystem Autoload

- [x] 3.1.1 编写 `src/autoload/panel_system.gd`，定义 HOVER_DELAY=0.3 / LEAVE_DELAY=0.5 常量
- [x] 3.1.2 实现 `register_panel(panel)` 接收面板实例，连接整个面板根节点的 mouse_entered/exited
- [x] 3.1.3 实现 `_process()` 悬停计时，达到 HOVER_DELAY 调用 `panel.expand()`
- [x] 3.1.4 实现离开计时 LEAVE_DELAY 后调用 `panel.collapse()`，处理 Collapsed/Expanded 切换的抖动
- [x] 3.1.5 实现 `update_values()` 节流刷新（每 500ms 一次，避免超 PRD 的 CPU <1% 要求）

#### 模块 3.2: Panel 场景

- [x] 3.2.1 在编辑器中创建 `src/scenes/panel/panel.tscn`（Control + Collapsed HBox + Expanded VBox）
- [x] 3.2.2 配置半透明深色圆角背景 StyleBoxFlat
- [x] 3.2.3 编写 `src/scenes/panel/panel.gd`，实现 `expand()` / `collapse()` 用 scale tween 而非 modulate.a
- [x] 3.2.4 实现 `refresh_values()` — 从 SalaryEngine 取数填充 5 项详情
- [x] 3.2.5 实现 `_apply_panel_config()` — 根据 Config.panel_items 控制每行可见性
- [x] 3.2.6 智能定位：贴右边缘时面板出现在左侧，贴底部时出现在上方（在 main.gd 中调用）

#### 模块 3.3: DragResizeSystem Autoload

- [x] 3.3.1 编写 `src/autoload/drag_resize_system.gd`，注册为 Autoload
- [x] 3.3.2 实现 `register_window(window)` + `move_window_to(pos)` + `save_position()`
- [x] 3.3.3 实现 `show_context_menu()` — 构建 PopupMenu（设置/切换角色子菜单/窗口模式子菜单/关于/退出），菜单位置用全局坐标
- [x] 3.3.4 实现 `_on_menu_id(id)` 处理菜单项点击，正确释放 popup（避免重复 queue_free）
- [x] 3.3.5 实现 `show_tray_menu()` — v0.1 风险项，用 PopupMenu 代替托盘，标注为降级方案

#### 模块 3.4: Main 场景整合

- [x] 3.4.1 在编辑器中创建 `src/scenes/main/main.tscn`（Node2D + Pet 实例 + Panel 实例）
- [x] 3.4.2 编写 `src/scenes/main/main.gd`，`_setup_window()` 通过 Platform Autoload 配置窗口
- [x] 3.4.3 实现 `_restore_position()` — 从 Config 读取 x/y，无效则 fallback 屏幕右下角
- [x] 3.4.4 实现 `_apply_scale_opacity()` — 应用缩放和透明度
- [x] 3.4.5 实现 `_position_panel()` 智能定位逻辑（根据窗口位置 vs 屏幕尺寸）
- [x] 3.4.6 设置 main.tscn 为项目主场景，运行验证 Pet/Panel 可见且能拖拽（待 Godot 编辑器实跑确认）

### v0.1 M4. 设置与引导

#### 模块 4.1: 设置对话框

- [x] 4.1.1 在编辑器中创建 `src/scenes/settings/settings_dialog.tscn`（ConfirmationDialog + TabContainer 5 标签页，含取消按钮）
- [x] 4.1.2 搭建 Salary 标签页 UI（月薪 SpinBox / 休息模式 OptionButton / 时数 / 上下班时间 HBox）
- [x] 4.1.3 搭建 Pet 标签页 UI（角色 ItemList + 缩放 HSlider 50-200）
- [x] 4.1.4 搭建 Display 标签页 UI（透明度 HSlider 20-100 + 窗口模式 OptionButton）
- [x] 4.1.5 搭建 Panel 标签页 UI（5 个 CheckBox 控制展开项可见性）
- [x] 4.1.6 搭建 General 标签页 UI（开机自启 disabled CheckBox + 语言 OptionButton）
- [x] 4.1.7 编写 `settings_dialog.gd`，实现 `_load_current_values()` / 确认保存 / 取消放弃，保存后触发 Config.config_changed 信号

#### 模块 4.2: 首次启动向导

- [x] 4.2.1 在编辑器中创建 `src/scenes/wizard/wizard_dialog.tscn`（ConfirmationDialog + 4 个 Control 页 + NavBar）
- [x] 4.2.2 搭建 Step 1 欢迎页（标题 + 副标题 + 大尺寸角色 IDLE 预览）
- [x] 4.2.3 搭建 Step 2 薪资页（复用设置对话框薪资页结构）
- [x] 4.2.4 搭建 Step 3 选角色页（ItemList + 选中实时调用 PetManager.switch_pet 预览）
- [x] 4.2.5 搭建 Step 4 完成页（SummaryLabel 摘要 + "开始赚钱！"按钮）
- [x] 4.2.6 编写 `wizard_dialog.gd`，实现步骤切换 / 上一步 / 下一步 / `_finish()` 保存并通过 `finished` 信号通知 main.gd reload

### v0.1 M5. 打包发布

#### 模块 5.1: Windows 打包

- [x] 5.1.1 配置 Godot 导出预设（Windows Desktop，设置图标和描述）
- [x] 5.1.2 下载安装 Windows 导出模板
- [x] 5.1.3 导出 exe 到 `<PROJECT_ROOT>\build\LetsMakeMoney.exe`，启动冒烟验证通过

---

## v0.1 资源准备清单（并行进行）

| 资源 | 路径 | 负责模块 | 状态 |
|------|------|---------|------|
| 小猫 sprite sheet | `assets/pets/cat/raw/` | 2.3 | ✅ 已准备（兔子素材占位） |
| 小猫 SpriteFrames | `assets/pets/cat/cat_sprite_frames.tres` | 2.3 | ✅ 已创建 |
| 小猫 PetResource | `assets/pets/cat/cat_resource.tres` | 1.4 | ✅ 已创建 |
| 小狗 SpriteFrames | `assets/pets/dog/dog_sprite_frames.tres` | 2.3 | ⚠ v0.1 延后 |
| 仓鼠 SpriteFrames | `assets/pets/hamster/hamster_sprite_frames.tres` | 2.3 | ⚠ v0.1 延后 |
| 应用图标 | `icons/app_icon.ico` / `icons/app_icon.png` | 5.1 | ✅ 已创建并接入导出预设 |

---

## v0.1 已知风险（降级方案）

| 风险 | 降级方案 |
|------|---------|
| Godot 无原生系统托盘 | v0.1 用右键 PopupMenu 代替，标注为临时方案；v0.2 正式解决 |
| "融入桌面"模式需 Windows Progman 父窗口技巧，复杂且不稳定 | v0.1 默认置顶，"融入桌面"选项保留但实现为普通非置顶窗口（不真实嵌入桌面层） |
| WORKING（敲键盘）和 HOVER 动画素材无现成开源包 | v0.1 用兔子素材的 walk_side 代替 working，idle 第 1 帧代替 hover |
| AI 生成 sprite 动画素材效果不理想（见下方困难记录） | v0.1 继续用兔子占位素材推进；v0.2 做非阻塞素材 Spike |
| 透明窗口输入不稳定 | v0.1 临时改为普通调试窗口并显示 DebugInputArea；v0.2 拆分 Debug/桌宠模式 |

---

## v0.1 已知问题 / Bug 跟踪

### 素材生成困难（2026-06-25，已决策延后）

**背景**：M2 Task 2.3 占位素材准备过程中，尝试用 AI 生成扁平卡通猫咪动画素材，多次方案均不理想。

**尝试过的方案及问题**：

1. **方案 1：ChatGPT 逐帧生成**
   - 问题：动作幅度极小（"微缩2像素"对 AI 等于无变化）；resting 帧只画一条腿；帧间角色漂移；拼成动画几乎看不出在动

2. **方案 2：ChatGPT 生成 sprite sheet（横向多帧）**
   - 问题：帧间角色不一致（颜色/比例漂移）；切片不齐；姿态差异不明显

3. **方案 3：AI 生成关键帧 + Python 程序化变换（缩放/平移）**
   - 5 张关键帧（idle/working/resting/hover/clicked）由 ChatGPT 生成，Python 用 Pillow 做缩放平移生成多帧
   - 问题：Python 程序化变换幅度太小，视觉上几乎无变化；且部分关键帧是 1536×1024 三视图布局而非单图，裁剪后内容偏小

4. **方案 4：sprite-animator skill（Gemini API）**
   - 发现 `olafs-world/sprite-animator` 工具可用 Gemini 生成 16 帧 sprite animation
   - 问题：需要 Gemini API Key；skill 安装时因网络问题克隆失败；未实际测试

**当前决策（方案 B）**：
- 继续使用现有的**兔子素材**（`assets/pets/cat/raw/{idle,walk}/`）作为 v0.1 占位
- AI 生成的猫咪尝试素材归档到 `experiments/ai_cat_assets/`（保留供 v1.0 参考）
- 不再阻塞 M3 进度，v1.0 正式版再解决扁平卡通猫咪素材

**v1.0 可探索的方案**：
- 获取 Gemini API Key 试用 sprite-animator 工具
- 雇佣插画师定制（Fiverr/米画师）
- 使用 Live2D 或骨骼动画替代帧动画
- 自己学 Pixelorama/Aseprite 手绘

### Godot 4.7 开发踩坑记录

- `Time.get_weekday_from_datetime_string()` 不存在 → 用 `get_unix_time_from_datetime_string` + `get_date_dict_from_unix_time` 取 weekday
- `Time.get_datetime_dict_from_datetime_string()` 返回的字典无 weekday 字段
- Dictionary 字段访问需 `int()` 显式类型转换（Godot 4.7 严格类型推断）
- `Vector2` 与 `Vector2i` 不能直接相减，需统一类型
- 脚本 `extends Node` 必须与场景根节点类型匹配（Control/Node2D 等）
- Godot 4.7 为每个 .gd 文件生成 .uid 文件，删除脚本时 .uid 也需清理
- 测试场景 `test_*.tscn` 已加入 .gitignore，避免误提交

---

## v0.2 Beta

### v0.2 计划 Review 结论

根据 `doc/LetsMakeMoneyPRD.md` 与 `doc/implementation-plan.md` review，v0.2 Beta 的范围已从“窗口可用性小迭代”扩展为一个完整 Beta 增量版本：

- **主线目标清晰**：默认桌宠模式、Debug 模式、角色区域交互、系统托盘、开机自启、设置打磨和验证打包形成闭环。
- **必须完成项明确**：系统托盘正式集成、开机自启正式支持、关闭隐藏到托盘均为 v0.2 必做项，不再作为降级或 Spike。
- **可降级项明确**：透明空白区域完全穿透可按平台能力降级为紧凑窗口；“融入桌面”仍为实验能力；素材更新仅为非阻塞 Spike。
- **实现边界明确**：Windows 专属能力必须通过 PlatformInterface / WindowsPlatform 封装，Main、Settings、DragResizeSystem 不直接写注册表或平台命令。
- **验证路径明确**：新增 `verify_v02.ps1` / `verify_v02.gd`、`doc/verification/v0.2.md`，并保留 M3/M4/M5 回归验证。

### v0.2 总体进度概览

| 里程碑 | 模块 | 状态 | 完成度 |
|--------|------|------|--------|
| **V02-M1** | Config 兼容与新增字段 | ✅ 完成 | 4/4 |
| **V02-M1** | Debug/桌宠运行模式拆分 | ✅ 完成 | 5/5 |
| **V02-M2** | 紧凑桌宠窗口与交互区域 | ✅ 完成 | 4/4 |
| **V02-M2** | 透明空白区域点击穿透 | ⏸ 暂缓 | 1/4 |
| **V02-M2** | 拖拽/双击/长按手感回归 | ✅ 完成 | 4/4 |
| **V02-M3** | Platform 托盘接口与 Windows 实现 | ⏸ 接口完成，真实托盘暂缓 | 3/5 |
| **V02-M3** | 托盘菜单与窗口显隐 | ✅ 降级路径完成 | 5/5 |
| **V02-M3** | 关闭按钮隐藏到托盘 | ⏸ 暂缓 | 1/3 |
| **V02-M4** | Platform 开机自启接口与 Windows 实现 | ✅ 完成 | 4/4 |
| **V02-M4** | 设置对话框通用项升级 | ✅ 完成 | 5/5 |
| **V02-M4** | 重置位置与恢复默认设置 | ✅ 完成 | 4/4 |
| **V02-M5** | v0.2 自动验证脚本 | ✅ 完成 | 4/4 |
| **V02-M5** | v0.2 手动验证文档 | ✅ 完成 | 3/3 |
| **V02-M5** | v0.2 Windows 打包与冒烟测试 | ✅ 完成 | 3/3 |
| **V02-S1** | 素材 Spike | ✅ 完成当前接入 | 4/4 |
| **V02-DOC** | 文档与用户可见文案整理 | 🔄 进行中 | 5/6 |

**v0.2 总进度**: 54/61 原计划任务完成或稳定降级（约 89%）。核心可用性、设置、自启、素材接入、验证和导出链路已完成；真实系统托盘、透明无边框窗口、空白点击穿透因 Godot 4.7 Windows 原生访问违例暂缓到 v0.3 技术预研。

### v0.2 V02-M1. Debug/桌宠模式拆分

#### 模块 V02-M1.1: Config 兼容与新增字段

- [x] V02-M1.1.1 在 `src/autoload/config.gd` 默认值中新增 `debug_mode=false`
- [x] V02-M1.1.2 在默认值中新增 `auto_start=false` 与 `minimize_to_tray=true`
- [x] V02-M1.1.3 实现配置 defaults 深合并，兼容旧 `config.json` 缺字段场景
- [x] V02-M1.1.4 增加自动验证：缺少 v0.2 字段时读取默认值，保存后补齐字段

#### 模块 V02-M1.2: Debug/桌宠运行模式拆分

- [x] V02-M1.2.1 扩展 `PlatformInterface.setup_window(window, debug_mode)` 并更新 `Platform` 转发
- [x] V02-M1.2.2 在 `WindowsPlatform.setup_window()` 中实现 Debug 模式窗口属性（普通 900×500、不透明、不置顶）
- [x] V02-M1.2.3 在 `WindowsPlatform.setup_window()` 中实现桌宠模式窗口属性（当前稳定候选为紧凑普通窗口；透明无边框通过安全开关暂缓）
- [x] V02-M1.2.4 在 `main.gd` 中读取 `debug_mode` 并控制 `DebugInputArea` / `DebugStatus` 可见性
- [x] V02-M1.2.5 验证默认桌宠模式、`debug_mode=true` Debug 模式、改回 `false` 后恢复桌宠模式

### v0.2 V02-M2. 透明窗口与输入穿透

#### 模块 V02-M2.1: 紧凑桌宠窗口与交互区域

- [x] V02-M2.1.1 在 `main.gd` 定义 Debug / Pet 两套窗口尺寸常量
- [x] V02-M2.1.2 调整桌宠模式 Pet 与 Panel 布局，使窗口不再使用 900×500 调试尺寸
- [x] V02-M2.1.3 校准 `pet.tscn` 中 Area2D / CollisionShape2D，使小猫可见区域稳定命中
- [x] V02-M2.1.4 验证桌宠模式只显示小猫和 Panel，Panel 悬停展开/收起仍可用

#### 模块 V02-M2.2: 透明空白区域点击穿透

- [x] V02-M2.2.1 在 `PlatformInterface` / `Platform` 增加 `set_mouse_passthrough(window, enabled, interactive_rects)` 接口
- [ ] V02-M2.2.2 在 `WindowsPlatform` 中实现或降级鼠标穿透能力，返回明确成功/失败（当前默认关闭，v0.3 继续）
- [ ] V02-M2.2.3 在 `main.gd` 中根据 Pet / Panel 区域计算 interactive rects 并应用穿透（当前默认关闭，v0.3 继续）
- [ ] V02-M2.2.4 验证桌宠模式空白区域尽量穿透，Debug 模式禁用穿透且可稳定点击（当前暂缓）

#### 模块 V02-M2.3: 拖拽/双击/长按手感回归

- [x] V02-M2.3.1 将拖拽逻辑统一为屏幕绝对鼠标位移，避免窗口移动速度异常
- [x] V02-M2.3.2 明确点击与拖拽互斥：超过拖拽阈值后不触发单击/双击
- [x] V02-M2.3.3 保持 0.3s 左右双击识别窗口，第二次点击后立即触发双击反馈
- [x] V02-M2.3.4 手动验证单击、双击、长按、拖拽保存位置均可用

### v0.2 V02-M3. 系统托盘正式集成

#### 模块 V02-M3.1: Platform 托盘接口与 Windows 实现

- [x] V02-M3.1.1 在 `PlatformInterface` / `Platform` 增加 `is_tray_supported()`、`setup_tray()`、`update_tray_menu()`、`shutdown_tray()`
- [x] V02-M3.1.2 在 `Platform` 暴露 `tray_toggle_requested`、`tray_settings_requested`、`tray_about_requested`、`tray_exit_requested` 信号
- [x] V02-M3.1.3 调研并确定 Godot 原生 API / GDExtension / 插件 / 轻量桥接中的托盘实现方案（Godot `StatusIndicator` 路线已验证存在风险，转入 v0.3 替代方案）
- [ ] V02-M3.1.4 在 `WindowsPlatform` 中实现真实系统托盘图标和托盘事件映射（暂缓）
- [ ] V02-M3.1.5 验证托盘图标出现在 Windows 托盘区，初始化失败时应用仍可使用（暂缓）

#### 模块 V02-M3.2: 托盘菜单与窗口显隐

- [x] V02-M3.2.1 实现托盘菜单：显示/隐藏、设置、关于 LetsMakeMoney、退出（接口与降级菜单路径完成）
- [x] V02-M3.2.2 在 `DragResizeSystem` 中新增 `set_window_visible()` 与 `toggle_window_visible()`
- [x] V02-M3.2.3 托盘显示/隐藏菜单项能恢复窗口到上次位置，并同步菜单文案（真实托盘暂缓，降级路径保留）
- [x] V02-M3.2.4 托盘设置/关于入口复用现有设置窗口和关于窗口逻辑
- [x] V02-M3.2.5 统一 `quit_app()`：保存位置、保存配置、关闭托盘资源、结束进程

#### 模块 V02-M3.3: 关闭按钮隐藏到托盘

- [x] V02-M3.3.1 在 `main.gd` 监听窗口 close/request 事件
- [ ] V02-M3.3.2 当 `minimize_to_tray=true` 且托盘可用时，关闭按钮隐藏窗口而不退出进程（真实托盘暂缓）
- [ ] V02-M3.3.3 当 `minimize_to_tray=false` 或托盘不可用时，关闭按钮保存配置并退出或保留可找回入口（待最终手动复测确认）

### v0.2 V02-M4. 开机自启与设置打磨

#### 模块 V02-M4.1: Platform 开机自启接口与 Windows 实现

- [x] V02-M4.1.1 在 `PlatformInterface` / `Platform` 增加 `get_executable_path()`、`is_auto_start_enabled()`、`set_auto_start()`
- [x] V02-M4.1.2 在 `WindowsPlatform` 中实现 HKCU 当前用户自启动写入/查询/移除，键名固定为 `LetsMakeMoney`
- [x] V02-M4.1.3 编辑器运行或 exe 路径非 `LetsMakeMoney.exe` 时返回失败并给出可理解提示
- [x] V02-M4.1.4 手动验证导出 exe 开启/关闭自启动能正确写入/移除注册表项

#### 模块 V02-M4.2: 设置对话框通用项升级

- [x] V02-M4.2.1 将 v0.1 禁用的“开机自启”控件改为可用 CheckButton
- [x] V02-M4.2.2 新增“关闭时隐藏到托盘”开关，默认读取 `minimize_to_tray=true`
- [x] V02-M4.2.3 新增“重置窗口位置”按钮与“恢复默认设置”按钮
- [x] V02-M4.2.4 打开设置时以系统状态加载开机自启开关，保存失败时不显示假成功
- [x] V02-M4.2.5 保存设置后即时应用缩放、透明度、窗口模式、自启动和托盘关闭行为

#### 模块 V02-M4.3: 重置位置与恢复默认设置

- [x] V02-M4.3.1 在 `DragResizeSystem` 实现 `reset_window_position()`，移动到当前主屏右下角并保存
- [x] V02-M4.3.2 在 `Config` 实现 `reset_display_defaults()`，恢复显示/窗口/托盘/自启动配置
- [x] V02-M4.3.3 恢复默认设置前弹出二次确认，且不清空薪资、休息模式、上下班时间和角色选择
- [x] V02-M4.3.4 验证恢复默认会同步关闭开机自启并移除系统自启动配置

### v0.2 V02-M5. 验证与打包

#### 模块 V02-M5.1: v0.2 自动验证脚本

- [x] V02-M5.1.1 新增 `scripts/verify_v02.ps1`，默认使用 Godot 4.7 exe 路径并执行 headless 验证
- [x] V02-M5.1.2 新增 `scripts/verify_v02.gd`，验证 Config 默认字段与旧配置兼容
- [x] V02-M5.1.3 自动验证 Main 场景关键节点、Debug UI 默认隐藏、`debug_mode=true` 可见
- [x] V02-M5.1.4 自动验证 SettingsDialog 控件和 Platform 托盘/自启动/穿透接口存在
- [x] V02-M5.1.5 自动验证设置保存不会在自启动状态未变化时重复调用注册表删除
- [x] V02-M5.1.6 自动验证核心用户可见文案不含常见乱码标记

#### 模块 V02-M5.2: v0.2 手动验证文档

- [x] V02-M5.2.1 新增 `doc/verification/v0.2.md`，覆盖桌宠模式、Debug 模式和交互验证
- [x] V02-M5.2.2 文档覆盖托盘菜单、关闭隐藏到托盘、退出流程和开机自启注册表验证，并明确当前暂缓项
- [x] V02-M5.2.3 文档包含测试后清理步骤：移除自启动、关闭进程、按需删除配置
- [x] V02-M5.2.4 文档改为可填写表格样式，支持标注结果、备注和证据

#### 模块 V02-M5.3: v0.2 Windows 打包与冒烟测试

- [x] V02-M5.3.1 使用 Godot 4.7 导出 `build/LetsMakeMoney.exe`
- [x] V02-M5.3.2 双击 exe 冒烟验证默认桌宠模式、右键菜单、核心交互可用；托盘图标和关闭隐藏到托盘暂缓
- [x] V02-M5.3.3 验证设置中开机自启可写入/移除，`debug_mode=true` 可进入 Debug 模式
- [x] V02-M5.3.4 2026-07-01 重新导出 exe：`<PROJECT_ROOT>\build\LetsMakeMoney.exe`，时间 `2026/7/1 22:03:59`

### v0.2 V02-S1. 素材 Spike（非阻塞）

#### 模块 V02-S1.1: SpriteCook/同类动画生成探索

- [x] V02-S1.1.1 新增/更新素材相关文档，记录输入素材来源、路径、尺寸、目标风格
- [x] V02-S1.1.2 接入 idle / working / resting，并扩展 clicked_single / clicked_double / clicked_hold
- [x] V02-S1.1.3 按帧间一致性、透明背景、SpriteFrames 适配度、风格一致性评估输出
- [x] V02-S1.1.4 质量达标后接入 `cat_orange_v1`，并新增自动验证脚本

### v0.2 V02-DOC. 文档与用户可见文案整理

#### 模块 V02-DOC.1: 核心文档实际状态更新

- [x] V02-DOC.1.1 恢复并保留 PRD、Implementation Plan、Progress 的详细颗粒度，不再压缩为短版总结
- [x] V02-DOC.1.2 在 PRD 中补充 v0.2 当前实际交付状态、稳定候选安全暂缓项和验收调整
- [x] V02-DOC.1.3 在 Implementation Plan 中补充 2026-07-01 执行后状态覆盖层，保留后文详细任务计划
- [x] V02-DOC.1.4 在 Progress 中将 v0.2 总览和各模块 checklist 更新为真实完成/暂缓状态
- [x] V02-DOC.1.5 更新手动验证文档为可填写表格，包含结果、备注、证据列
- [ ] V02-DOC.1.6 继续清理 implementation-plan 中历史段落可能残留的编码乱码，确保整篇在 Typora/GitHub 中均可读

#### 模块 V02-DOC.2: 用户可见中文文案清理

- [x] V02-DOC.2.1 清理设置窗口标题、标签、按钮、提示文案乱码
- [x] V02-DOC.2.2 清理 Panel 金额、时薪、工作进度、状态文案乱码
- [x] V02-DOC.2.3 清理右键菜单、关于弹窗、托盘菜单接口文案乱码
- [x] V02-DOC.2.4 清理 SalaryEngine 状态文案乱码
- [x] V02-DOC.2.5 在 v0.2 自动验证中增加用户可见文案乱码扫描

---

## v0.2 资源准备清单（并行进行）

| 资源 | 路径 | 负责模块 | 状态 |
|------|------|---------|------|
| v0.2 自动验证脚本 | `scripts/verify_v02.ps1` / `scripts/verify_v02.gd` | V02-M5.1 | ✅ 已创建并通过 |
| v0.2 验证文档 | `doc/verification/v0.2.md` | V02-M5.2 | ✅ 已创建并改为可填写表格 |
| v0.2 素材 Spike 记录 | `doc/v0.2-asset-spike.md` 等素材文档 | V02-S1.1 | ✅ 已记录 |
| Windows 托盘实现方案记录 | `doc/LetsMakeMoneyPRD.md` / `doc/implementation-plan.md` / 手动验证文档 | V02-M3.1 | ⏸ Godot `StatusIndicator` 路线暂缓，v0.3 继续 |
| 小猫动画探索输出 | `assets/pets/cat_orange_v1/` | V02-S1.1 | ✅ 已接入当前版本 |
| 用户可见文案乱码扫描 | `scripts/verify_v02.gd` | V02-DOC.2 | ✅ 已加入自动验证 |

---

## v0.2 已知风险（降级方案）

| 风险 | 降级方案 |
|------|---------|
| Godot/插件托盘能力不稳定 | 保留任务栏入口和角色右键菜单；托盘初始化失败时不隐藏窗口到不可找回状态 |
| 透明空白区域穿透不稳定 | 收紧桌宠窗口尺寸，保留 Debug 模式；必要时用 WindowsPlatform 专用实现 |
| 开机自启路径在编辑器运行时不可用 | 仅导出 exe 支持正式写入；编辑器运行显示提示并不保存假成功状态 |
| 关闭隐藏到托盘导致用户找不到窗口 | 仅托盘可用时启用隐藏；托盘不可用时关闭按钮直接退出或保留任务栏入口 |
| 自启动注册表残留旧路径 | 写入前查询，关闭时移除固定键名 `LetsMakeMoney`；手动验证文档提供清理命令 |
| 素材生成质量不可控 | 作为非阻塞 Spike，失败只记录结论，不影响 v0.2 Beta 发布 |
| Godot 4.7 原生托盘/透明窗口访问违例 | 默认关闭 `system_tray_enabled`、`transparent_pet_window_enabled`、`mouse_passthrough_enabled`；v0.3 调研替代实现 |
| 文档历史段落编码不一致 | 优先保留详细内容，再分批清理乱码；不得用短版摘要替代详细计划 |

---

## v0.2 已知问题 / Bug 跟踪

### 待实现前验证项（2026-06-27）

- v0.1 当前仍以较大 debug 窗口和可见 DebugInputArea 保障输入稳定，v0.2 需要拆出默认桌宠模式。
- v0.1 右键菜单中的“融入桌面”仍为实验/降级能力，v0.2 不把真实桌面层作为验收项。
- v0.1 “开机自启”在设置中为禁用占位，v0.2 必须升级为正式可用项。
- v0.1 `show_tray_menu()` 是 PopupMenu 降级方案，v0.2 必须实现真实系统托盘图标。

## v0.3 Beta

### v0.3 计划 Review 结论

根据 `doc/LetsMakeMoneyPRD.md` 与 `doc/implementation-plan.md` review，v0.3 Beta 的范围已经从“技术预研”明确升级为一个完整 Beta 增量版本：目标不是继续增加业务功能，而是把 v0.2 为稳定性暂缓的桌宠原生能力恢复为可交付、可导出、可回退的正式能力。

- **主线目标清晰**：v0.3 聚焦 Windows x86_64 原生桌宠能力，必须完成 GDExtension / native bridge、真系统托盘、透明无边框窗口、点击穿透、关闭隐藏到托盘和可找回优先的纯桌宠模式。
- **必须完成项明确**：真托盘、透明窗口、点击穿透、关闭隐藏到托盘、纯桌宠模式、设置控件修正、v0.3 验证与发布文档均为正式里程碑，不再作为 Spike。
- **安全边界明确**：默认仍保留任务栏 / Alt+Tab；只有托盘健康检查通过后，用户才能手动启用纯桌宠模式；任何原生能力失败都必须回退到 v0.2 紧凑普通窗口或保留可找回入口。
- **技术边界明确**：Win32 能力集中在 GDExtension / 原生插件中；Godot 侧只通过 `PlatformInterface`、`WindowsPlatform` 和 `Platform` Autoload 调用，Main / Settings / DragResizeSystem 不直接写 Win32 细节。
- **版本边界明确**：橘猫动画打磨、更多动作帧、macOS / Linux 原生能力、多角色、云同步、统计报表等不进入 v0.3；动画打磨进入 v0.4。
- **验证路径明确**：v0.3 需要新增 `verify_v03.ps1/gd`、`verify_v03_export.ps1`、`doc/verification/v0.3.md`、`releases/CHANGELOG.md`、`releases/v0.3-beta-notes.md`，并保留 v0.2 回归验证。

### v0.3 总体进度概览

| 里程碑 | 模块 | 状态 | 完成度 |
|--------|------|------|--------|
| **V03-M1** | GDExtension / Native Bridge 骨架 | ✅ 完成 | 8/8 |
| **V03-M1** | Godot 侧 native health 接入 | ✅ 完成 | 7/7 |
| **V03-M2** | 原生系统托盘控制器 | ✅ 完成 | 8/8 |
| **V03-M2** | Main 托盘健康门禁 | ✅ 完成 | 5/5 |
| **V03-M3** | 透明无边框窗口与窗口句柄 | ✅ 完成 | 7/7 |
| **V03-M4** | 点击穿透与交互区域刷新 | ✅ 完成 | 8/8 |
| **V03-M5** | 关闭隐藏到托盘健康门禁 | ✅ 完成 | 4/4 |
| **V03-M5** | 可找回优先的纯桌宠模式 | ✅ 完成 | 7/7 |
| **V03-M6** | 设置控件体验修正 | ✅ 完成 | 8/8 |
| **V03-M6** | 配置迁移与默认值 | ✅ 完成 | 5/5 |
| **V03-M7** | v0.3 验证与发布文档 | ✅ 完成 | 16/16 |
| **V03-DOC** | 文档编码与进度维护 | 🔄 进行中 | 5/6 |

**v0.3 总进度**: 89/89 任务完成或已落地（100%）。已完成 PRD、implementation-plan 和 progress 的 v0.3 规划，并完成 native bridge 骨架、Godot 侧 native health 接口、v0.3 配置默认值迁移、Win32 托盘控制器源码、托盘命令轮询模型、Win32 窗口控制器源码、Godot 窗口句柄入口、点击穿透区域模型、右键菜单命中修复、关闭隐藏到托盘门禁、纯桌宠模式安全门禁、设置控件修正、手动验证文档、发布说明、MSYS2 UCRT64 native 构建脚本、导出 exe、自动验证和 `v0.3beta` 发布收尾。当前 `native/windows/bin/win64/letsmakemoney_native.dll` 已可本地构建，`verify_v02.ps1`、`verify_v03.ps1`、`verify_m4.ps1`、`verify_m5.ps1` 和 `verify_v03_export.ps1` 均已通过。

### v0.3 V03-M1. GDExtension / Native Bridge 骨架

#### 模块 V03-M1.1: 建立 native/windows 插件目录与构建说明

- [x] V03-M1.1.1 创建 `native/windows/`、`native/windows/src/`、`native/windows/bin/win64/` 目录结构
- [x] V03-M1.1.2 新增 `native/windows/README.md`，说明 native bridge 负责托盘、透明窗口、穿透、任务栏/Alt+Tab 控制和健康检查，不承载薪资/动画/UI/配置业务
- [x] V03-M1.1.3 新增 `native/windows/letsmakemoney_native.gdextension`，声明入口 `letsmakemoney_library_init` 和 Windows x86_64 debug/release dll 路径
- [x] V03-M1.1.4 新增 `native/windows/SConstruct`，记录 Godot 4.7 / godot-cpp / Windows x86_64 构建入口
- [x] V03-M1.1.5 新增 `register_types.h/cpp`，注册 `LMMNativeBridge`
- [x] V03-M1.1.6 新增 `lmm_native_bridge.h/cpp` 最小类，暴露 `get_health()`、`setup_tray()`、`setup_pet_window()`、`set_mouse_passthrough()`、`set_taskbar_visible()` 等方法
- [x] V03-M1.1.7 验证 `.gdextension` 与 C++ 源文件路径存在，构建产物路径不误提交或明确放行
- [x] V03-M1.1.8 native bridge scaffold 已纳入 v0.3 整体收尾提交范围

#### 模块 V03-M1.2: Godot 侧接入 native bridge 健康检查

- [x] V03-M1.2.1 在 `Config._defaults()` 新增 `native_integration_enabled=true` 与 `pure_pet_mode=false`
- [x] V03-M1.2.2 将 v0.3 目标默认值设为 `system_tray_enabled=true`、`transparent_pet_window_enabled=true`、`mouse_passthrough_enabled=true`
- [x] V03-M1.2.3 在 `reset_display_defaults()` 同步纳入 v0.3 原生能力字段，但不清空薪资、角色和 Panel 配置
- [x] V03-M1.2.4 在 `PlatformInterface` 增加 `get_native_health()`、`get_native_window_handle()`、`set_taskbar_visible()`、`can_enable_pure_pet_mode()` 安全默认实现
- [x] V03-M1.2.5 在 `WindowsPlatform` 中加载 `LMMNativeBridge`，构造 `_native_health`，插件缺失时返回可读 `last_error`
- [x] V03-M1.2.6 在 `Platform` Autoload 转发 native health、窗口句柄、任务栏显示和纯桌宠可用性接口
- [x] V03-M1.2.7 新增 `scripts/verify_v03.ps1/gd`，验证 v0.3 默认值、平台接口和 health 字段存在

### v0.3 V03-M2. 真系统托盘

#### 模块 V03-M2.1: 原生系统托盘控制器

- [x] V03-M2.1.1 新增 `native/windows/src/tray_controller.h/cpp`，封装 Windows 托盘图标、菜单和命令轮询
- [x] V03-M2.1.2 定义托盘命令 ID：显示/隐藏、设置、关于、退出
- [x] V03-M2.1.3 使用 Win32 托盘能力创建图标，tooltip 至少包含 `LetsMakeMoney`
- [x] V03-M2.1.4 构建托盘菜单：显示/隐藏、设置、关于 LetsMakeMoney、退出
- [x] V03-M2.1.5 将托盘命令映射为 Godot 侧 `1/2/3/4`，供 `Platform` 轮询并发射现有信号
- [x] V03-M2.1.6 在 `LMMNativeBridge` 暴露 `poll_tray_command()`，并实现 `setup_tray()` / `update_tray_menu()` / `shutdown_tray()`
- [x] V03-M2.1.7 在 `WindowsPlatform` 调用 native bridge 托盘接口，Godot `StatusIndicator` 仅作为回退或废弃路径记录
- [x] V03-M2.1.8 手动验证托盘图标、左键显示/隐藏、右键菜单、设置、关于和退出全部可用

#### 模块 V03-M2.2: Main 接入托盘健康门禁

- [x] V03-M2.2.1 在 `main.gd` 中记录 `_native_health`、`_native_ready`、`_tray_ready`（当前已记录 `_native_health` 与 `_tray_ready`，`_native_ready` 暂未单独拆出）
- [x] V03-M2.2.2 `_setup_tray()` 按顺序检查 `debug_mode`、`native_integration_enabled`、`system_tray_enabled`、`tray_supported`
- [x] V03-M2.2.3 托盘初始化成功后连接 `tray_toggle_requested`、`tray_settings_requested`、`tray_about_requested`、`tray_exit_requested`
- [x] V03-M2.2.4 托盘初始化失败时保留任务栏入口和角色右键菜单，不隐藏窗口到不可找回状态
- [x] V03-M2.2.5 在 `verify_v03.gd` 增加托盘健康门禁脚本扫描或场景检查

### v0.3 V03-M3. 透明无边框桌宠窗口

#### 模块 V03-M3.1: 原生窗口控制器与窗口句柄获取

- [x] V03-M3.1.1 新增 `native/windows/src/window_controller.h/cpp`，封装窗口样式、透明、穿透和任务栏/Alt+Tab 控制
- [x] V03-M3.1.2 实现 `setup_pet_window(HWND hwnd, transparent, borderless)`，设置无边框、置顶、透明相关 Win32 样式
- [x] V03-M3.1.3 在 `LMMNativeBridge` 转发 `setup_pet_window()`
- [x] V03-M3.1.4 在 `WindowsPlatform.get_native_window_handle(window)` 中获取 Godot 主窗口 native handle
- [x] V03-M3.1.5 `WindowsPlatform.setup_window()` 先设置 Godot 窗口属性，再调用 native `setup_pet_window()`
- [x] V03-M3.1.6 原生透明窗口初始化失败时自动回退：`borderless=false`、`transparent_bg=false`、紧凑普通窗口继续可用
- [x] V03-M3.1.7 手动验证 `debug_mode=false` 下无边框透明窗口可见，`debug_mode=true` 下仍为 900×500 调试窗口

### v0.3 V03-M4. 点击穿透与交互区域刷新

#### 模块 V03-M4.1: 原生鼠标穿透区域

- [x] V03-M4.1.1 在 `WindowController` 实现 `set_mouse_passthrough(hwnd, interactive_rects)` 和 `clear_mouse_passthrough(hwnd)`
- [x] V03-M4.1.2 明确命中规则：小猫、Panel、菜单和设置窗口可交互；其他透明空白区域尽量穿透到桌面或下层窗口
- [x] V03-M4.1.3 在 `LMMNativeBridge` 转发穿透接口，并返回明确成功/失败
- [x] V03-M4.1.4 在 `WindowsPlatform.set_mouse_passthrough()` 中优先调用 native bridge，失败时清空穿透并返回 `false`
- [x] V03-M4.1.5 在 `main.gd` 增加 `get_interactive_rects()`，统一计算 Pet 和 Panel 区域
- [x] V03-M4.1.6 在缩放、Panel 展开/收起、窗口拖拽、设置保存后刷新穿透区域
- [x] V03-M4.1.7 增加 `_last_passthrough_rects_hash`，避免每帧重复 native 调用导致性能或稳定性问题
- [x] V03-M4.1.8 手动验证空白区域点击穿透，小猫 hover/单击/双击/长按/拖拽、Panel hover 和设置窗口点击均不回退

### v0.3 V03-M5. 关闭隐藏到托盘与纯桌宠模式

#### 模块 V03-M5.1: 关闭按钮隐藏到托盘健康门禁

- [x] V03-M5.1.1 在 `main.gd` 增加 `can_hide_to_tray()`，要求 `minimize_to_tray=true` 且 `_tray_ready=true`
- [x] V03-M5.1.2 改造 `_on_window_close_requested()`：托盘健康时隐藏窗口，否则保存配置并退出或保留可找回入口
- [x] V03-M5.1.3 `DragResizeSystem.set_window_visible(false)` 前保存窗口位置，避免隐藏后丢失坐标
- [x] V03-M5.1.4 手动验证托盘健康时关闭隐藏、托盘恢复；托盘不可用时不隐藏到不可找回状态（脚本门禁已覆盖，真实托盘恢复待 native DLL 构建后手动验证）

#### 模块 V03-M5.2: 可找回优先的纯桌宠模式

- [x] V03-M5.2.1 在 `WindowController` 实现 `set_taskbar_visible(hwnd, visible)`，切换任务栏 / Alt+Tab 相关窗口扩展样式
- [x] V03-M5.2.2 在 `LMMNativeBridge` 转发 `set_taskbar_visible()`
- [x] V03-M5.2.3 在 `WindowsPlatform` 实现 `can_enable_pure_pet_mode(window)`，要求 native bridge 可用、托盘支持、任务栏控制支持、窗口句柄有效
- [x] V03-M5.2.4 在 `main.gd` 增加 `_apply_pure_pet_mode()`，默认保持任务栏 / Alt+Tab 可见
- [x] V03-M5.2.5 托盘健康且用户开启 `pure_pet_mode=true` 时隐藏任务栏 / Alt+Tab
- [x] V03-M5.2.6 原生失败、托盘失败或 Debug 模式下自动 `pure_pet_mode=false` 并恢复任务栏 / Alt+Tab
- [x] V03-M5.2.7 手动验证纯桌宠模式可启用、可通过托盘找回、失败时自动恢复可找回入口

### v0.3 V03-M6. 设置体验与配置迁移

#### 模块 V03-M6.1: 休息模式与窗口模式改为明确选择控件

- [x] V03-M6.1.1 将 `settings_dialog.gd` 中 `rest_mode_toggle: CheckButton` 替换为 `rest_mode_option: OptionButton`
- [x] V03-M6.1.2 休息模式选项明确显示“双休 / 单休”，加载和保存仍写入 `rest_mode=double/single`
- [x] V03-M6.1.3 将 `window_mode_toggle: CheckButton` 替换为 `window_mode_option: OptionButton`
- [x] V03-M6.1.4 窗口模式选项明确显示“置顶悬浮 / 融入桌面（实验）”
- [x] V03-M6.1.5 新增 `pure_pet_mode_toggle`，文案说明“隐藏任务栏 / Alt+Tab，需托盘可用”
- [x] V03-M6.1.6 新增 `native_status_label`，显示托盘、点击穿透、纯桌宠能力可用/不可用状态
- [x] V03-M6.1.7 托盘或 native health 不满足时禁用纯桌宠开关并强制不保存假成功
- [x] V03-M6.1.8 更新 `verify_v03.gd`，确保设置中不再使用含糊的 rest/window CheckButton

#### 模块 V03-M6.2: 配置迁移与恢复默认范围

- [x] V03-M6.2.1 在默认配置中新增 `config_version=3`
- [x] V03-M6.2.2 `merge_with_defaults()` 兼容 v0.2 旧配置，补齐 v0.3 字段但保留薪资、窗口位置、缩放、透明度、自启动和 Panel 项
- [x] V03-M6.2.3 `reset_display_defaults()` 只重置窗口、显示、原生能力、自启动、托盘和纯桌宠字段
- [x] V03-M6.2.4 确认恢复默认不清空 `monthly_salary`、`rest_mode`、`work_start_time`、`work_end_time`、`pet_id`、`panel_items`
- [x] V03-M6.2.5 在 `verify_v03.gd` 增加旧配置迁移测试和恢复默认范围检查

### v0.3 V03-M7. 验证、发布与文档

#### 模块 V03-M7.1: v0.3 手动验证文档

- [x] V03-M7.1.1 新增 `doc/verification/v0.3.md`
- [x] V03-M7.1.2 文档包含基础信息表：验证日期、Windows 版本、Godot 版本、exe 路径、配置路径、是否清空旧配置、验证结论
- [x] V03-M7.1.3 文档覆盖真系统托盘：图标、左键显示/隐藏、右键菜单、设置、关于、退出
- [x] V03-M7.1.4 文档覆盖透明无边框窗口：无普通边框、背景透明、设置窗口不受影响
- [x] V03-M7.1.5 文档覆盖点击穿透：空白区域穿透、小猫交互、Panel hover、设置窗口可点击
- [x] V03-M7.1.6 文档覆盖关闭隐藏到托盘与纯桌宠模式：默认可找回、开启后隐藏任务栏 / Alt+Tab、托盘恢复
- [x] V03-M7.1.7 每个验证项都包含“结果”和“备注”列，便于用户标注
- [x] V03-M7.1.8 文档包含错误记录模板：问题编号、第一条错误、复现步骤、期望行为、实际行为、截图/录屏

#### 模块 V03-M7.2: 自动验证、导出验证与 release notes

- [x] V03-M7.2.1 完善 `scripts/verify_v03.gd`，覆盖配置默认值、迁移、平台接口、Main 门禁、设置控件、穿透模型和纯桌宠模式门禁
- [x] V03-M7.2.2 完善 `scripts/verify_v03.ps1`，默认使用本机 Godot 4.7 路径执行 headless 验证
- [x] V03-M7.2.3 新增 `scripts/verify_v03_export.ps1`，检查 `build/LetsMakeMoney.exe`、`.gdextension` 和 native dll 是否存在
- [x] V03-M7.2.4 导出验证脚本启动 exe 做短时间冒烟测试，确认进程不会立即崩溃（native DLL 缺失时会在启动前阻塞）
- [x] V03-M7.2.5 新增 `releases/CHANGELOG.md`，记录 v0.3 新增、变更、延后内容
- [x] V03-M7.2.6 新增 `releases/v0.3-beta-notes.md`，记录必须验证项和已知边界
- [x] V03-M7.2.7 发布前运行 `verify_v02.ps1`、`verify_v03.ps1`、`verify_v03_export.ps1`
- [x] V03-M7.2.8 用户完成 `doc/verification/v0.3.md` 且无阻塞问题后，允许进入 `v0.3beta` 发布准备

### v0.3 V03-DOC. 文档编码与进度维护

#### 模块 V03-DOC.1: PRD / Plan / Progress 平级维护

- [x] V03-DOC.1.1 在 `doc/LetsMakeMoneyPRD.md` 中新增 v0.3 Beta PRD，与 v0.1 / v0.2 平级维护
- [x] V03-DOC.1.2 在 `doc/implementation-plan.md` 中新增 v0.3 Beta 实施计划，与 v0.1 / v0.2 平级维护
- [x] V03-DOC.1.3 在 `doc/progress.md` 顶部版本总览中新增 v0.3 Beta 状态
- [x] V03-DOC.1.4 在 `doc/progress.md` 中新增 v0.3 Review 结论、总体进度概览和模块级 checklist
- [x] V03-DOC.1.5 清理并标注 `implementation-plan.md` 中历史嵌套 markdown 片段导致的标题层级噪声，保留详细内容并以 v0.4 平级章节继续维护
- [x] V03-DOC.1.6 检查 PRD、Plan、Progress 在 GitHub/Typora 中均无乱码、无错位标题、无过度压缩

### v0.3 资源准备清单（并行进行）

| 资源 | 路径 | 负责模块 | 状态 |
|------|------|---------|------|
| Windows native bridge 目录 | `native/windows/` | V03-M1.1 | ✅ 已创建 |
| GDExtension 描述文件 | `native/windows/letsmakemoney_native.gdextension` | V03-M1.1 | ✅ 已创建 |
| Native bridge C++ 源码 | `native/windows/src/` | V03-M1/V03-M2/V03-M3/V03-M4/V03-M5 | ✅ 已有 `LMMNativeBridge`、`TrayController`、`WindowController`，脚本验证、导出烟测和手动复测均已通过 |
| Native dll 构建产物 | `native/windows/bin/win64/letsmakemoney_native.dll` | V03-M1/V03-M7 | ✅ 已通过 MSYS2 UCRT64 本地构建，产物为本机生成文件，不提交第三方构建输出 |
| v0.3 自动验证脚本 | `scripts/verify_v03.ps1` / `scripts/verify_v03.gd` | V03-M1/V03-M7 | ✅ 已创建并通过验证 |
| v0.3 native 构建脚本 | `scripts/build_native_windows.ps1` | V03-M7.2 | ✅ 已支持本机 MSYS2 UCRT64，并通过构建自测 |
| v0.3 导出验证脚本 | `scripts/verify_v03_export.ps1` | V03-M7.2 | ✅ 已创建并通过导出 exe 冒烟测试 |
| v0.3 验证文档 | `doc/verification/v0.3.md` | V03-M7.1 | ✅ 已创建 |
| v0.3 发布记录 | `releases/CHANGELOG.md` / `releases/v0.3-beta-notes.md` | V03-M7.2 | ✅ 已创建 |

### v0.3 已知风险（降级方案）

| 风险 | 降级方案 |
|------|---------|
| GDExtension 加载失败 | `native_integration_enabled` 视为不可用，回退 v0.2 紧凑普通窗口，保留任务栏入口 |
| Native dll 缺失或未随 exe 分发 | `verify_v03_export.ps1` 阻塞发布；release notes 明确分发文件 |
| 托盘初始化失败 | `_tray_ready=false`，关闭按钮不得隐藏到托盘，纯桌宠模式禁用 |
| 透明无边框初始化失败 | 回退 `borderless=false` / `transparent_bg=false` 的紧凑普通窗口 |
| 点击穿透区域错误 | Debug 模式默认关闭穿透；穿透失败时清空穿透区域，优先保证小猫、Panel、设置可交互 |
| 纯桌宠模式导致窗口不可找回 | 只有托盘健康时才允许开启；失败时自动 `pure_pet_mode=false` 并恢复任务栏 / Alt+Tab |
| 设置控件保存假成功 | 保存前读取 native health，能力不可用时禁用或回写真实状态 |
| 文档整理被误压缩 | 只清理乱码和标题结构，不删除关键设计依据、验收记录和风险说明 |

### v0.3 已关闭问题 / Bug 跟踪

#### v0.3 收尾关闭项（2026-07-03）

- `system_tray_enabled`、`transparent_pet_window_enabled`、`mouse_passthrough_enabled` 已从 v0.2 安全关闭状态恢复为 v0.3 默认能力，并通过 native health 与失败降级保护。
- Godot `StatusIndicator` 旧路线不再作为主路径，真托盘改由 Windows native bridge 负责，避免继续触发 Godot 4.7 Windows 原生访问违例。
- 休息模式和窗口模式已从含糊的 CheckButton 改为 `OptionButton` 下拉选择，保存仍写入 `rest_mode=double/single`、`window_mode=top/embed`。
- 设置进入 Display 页后影响其他选项卡保存的问题已修复，设置打开时会临时清空穿透区域，关闭后恢复。
- 关闭按钮已改为托盘健康时隐藏窗口，托盘左键可显示/隐藏，托盘右键菜单可打开设置、关于和退出。
- 小猫右键菜单偶发不弹的问题已通过右键专用上下文区域修复；普通无按键状态下扩展区仍保持点击穿透。
- `scripts/build_native_windows.ps1` 已支持本机 MSYS2 UCRT64 构建，`native/windows/bin/win64/letsmakemoney_native.dll` 可本地生成。
- `verify_v02.ps1`、`verify_v03.ps1`、`verify_m4.ps1`、`verify_m5.ps1`、`verify_v03_export.ps1` 在收尾阶段均已通过。

### v0.4 已知问题 / Bug 跟踪

#### v0.4 需要承接的问题（2026-07-03）

- 橘猫动画仍偏基础，idle / working / resting / clicked_hold 的动作节奏、帧数、状态差异和角色锚点需要系统打磨。
- 当前点击穿透基于交互矩形和 native hit-test，不是像素级命中；v0.4 需要增加可视化或日志调试，继续校准多缩放、多边缘位置和右键上下文区域。
- Panel 在边缘定位、展开方向、与小猫距离、内容密度方面仍有体验优化空间。
- 设置窗口功能已可用，但信息架构、保存反馈、错误提示、平台能力禁用原因和恢复入口仍偏工程化。
- 纯桌宠模式已经可找回，但用户对任务栏、Alt+Tab、托盘之间关系仍可能困惑，需要更清晰的说明和状态反馈。
- native DLL、exe 和导出脚本已经形成链路，但发布包仍是本地脚本式流程，v0.4 需要整理分发清单、升级说明和 release 产物规范。

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
| **V04-M6** | UI polish 与交互原型完善 | 🚧 Panel、右键二级菜单、Win11 设置窗口结构、设置卡片化、图标资源、右键菜单视觉质量、设置工具按钮和 UI polish 验证项已完成自动门禁；子菜单边缘避让和完整 UI polish 手动复测仍待确认 | 49/51 |
| **V04-DOC** | v0.4 验证文档与发布记录 | 🚧 进行中 | 8/9 |

**v0.4 总进度**: 181/185（97.84%；V04-M0 完成，V04-M1 动画规格、v2 素材目录、素材记录、提示词执行集、asset manifest、cutout 工程候选帧、Godot 资源构建器、SpriteFrames / PetResource 资源、缺帧门禁、v0.3 资源回退策略、素材生成产能路线文档、ComfyUI 环境验证和橘猫 v2 beta 默认接入完成；cutout 批次已被人工拒绝为最终美术候选，当前默认使用 imagegen concept 派生素材并保留 `cat_orange_v1` 回退；V04-M2 交互手感首轮完成，V04-M3 窗口、点击穿透、Panel 边缘定位、折叠态居中、可找回兜底和 50%-200% 缩放边界验证首轮完成，V04-M4 设置体验首轮完成，V04-M5 日志分层、自动验证覆盖、no-op native 缓存、Panel 刷新节流验证、发布包脚本、checksum 校验、发布包烟测和 60 秒 release 稳定性烟测完成；V04-M6 UI polish 已完成 PRD/规格/实施计划/Progress 基础同步，完成 Win11 风格设置窗口、右键二级菜单、多尺寸图标预览和 Panel polish 的交互原型更新，并完成 Godot Panel polish、右键菜单二级入口、Win11 设置窗口结构、设置项卡片化、设置页非装饰化门禁、设置窗口工具按钮精修、右键菜单紧凑清晰主题、多尺寸图标资源、关于窗口图标、折叠态布局门禁、UI polish 专项验证文档和发布包刷新验证；子菜单边缘避让和完整 UI polish 手动验证仍待实现；V04-DOC 手动验证文档骨架、v0.4 release notes、changelog 条目和持续同步完成）。

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
7. **V04-M6 UI polish 与交互原型完善**：先补齐 Win11 风格设置窗口、右键二级菜单、托盘/窗口图标和 Panel polish 的原型/规格，再落到 Godot UI 与验证。
8. **V04-DOC 文档闭环**：开发过程中同步验证结果，发布前统一 PRD / Plan / Progress / Verification / Release Notes。

---

## 开发日志

- **2026-06-24**: 完成 PRD 和 implementation-plan.md，生成 progress.md；review 后重写 plan 修复 30 处问题
- **2026-06-24**: 初始化 git 仓库，提交项目文档（commit b2885a3）
- **2026-06-24**: M1.1 项目搭建 + Config Autoload 完成（commit 1fcded8, 83c0744）
- **2026-06-24**: M1.2 PlatformInterface 跨平台抽象层完成（commit 83c0744）
- **2026-06-24**: M1.3 Config Autoload 完成（commit 83c0744）
- **2026-06-24**: M1.4 SalaryEngine 薪资引擎完成（commit 317e891）—— 修复 Godot 4.7 Time API 和类型推断问题
- **2026-06-24**: M1.5 PetResource 自定义 Resource 完成（commit 5c5c91b）—— M1 全部完成
- **2026-06-25**: M2.1 PetManager 角色状态机中枢完成（commit 50c5802）
- **2026-06-25**: M2.2 Pet 场景 + 状态机完成（commit 5c8a1ce）—— 含 DragResizeSystem 占位
- **2026-06-25**: M2.3 占位素材准备完成（commit 85dda76）—— 使用免费兔子素材包
- **2026-06-25**: 尝试 AI 生成猫咪动画素材，4 种方案均不理想，决策延后到 v1.0
- **2026-06-25**: 整理项目，AI 素材归档到 experiments/，更新 progress.md 记录困难和决策
- **2026-06-26**: M3 UI 与交互代码完成——新增 PanelSystem、薪资面板、Main 场景，完善右键菜单；待 Godot 编辑器运行验证
- **2026-06-26**: 新增 `scripts/verify_m3.ps1` 和 M3 验证清单；Godot 4.7 headless 项目加载与主场景 30 帧 smoke test 通过（后续已并入 `doc/verification/v0.1.md`）
- **2026-06-26**: 修复 M3 手动验证问题——设置桌宠窗口实际尺寸，Pet 输入增加鼠标位置命中兜底，右键菜单改用窗口内坐标
- **2026-06-26**: 通过 Windows 窗口截图确认运行窗口内容过小且面板跑出可见区；放大占位角色、固定 Pet/Panel 到窗口内布局，并为拖拽增加左键 mask 兜底与 `drag started` 日志
- **2026-06-26**: 调试阶段临时放大窗口到 720×360，拉开 Pet/Panel 位置，便于观察薪资数字和交互状态
- **2026-06-26**: 调试阶段临时关闭透明背景并增加可见 DebugInputArea，避免 Windows 透明窗口按像素命中导致点击事件不稳定
- **2026-06-26**: 确认普通窗口模式下输入链路可用：左键单击、右键菜单、窗口拖拽保存均通过；后续再逐步恢复无边框/透明/置顶桌宠模式
- **2026-06-26**: 修复调试交互问题——双击改为 0.3s 点击窗口判定，拖拽改用屏幕绝对鼠标差值避免速度过快，折叠金额栏去掉重复人民币符号
- **2026-06-26**: 完成 M4 设置对话框与首次启动向导；新增 `scripts/verify_m4.ps1` / `scripts/verify_m4.gd` 覆盖设置保存和向导完成保存，M3/M4 自动验证通过
- **2026-06-26**: 根据 M3/M4 手动验证反馈优化——放大调试窗口和菜单字号，工作进度显示百分比/时间段/每日小时数；每日工作小时数改为由上下班时间自动推导，避免薪资计算和工作状态来源冲突
- **2026-06-26**: 继续修复 M4 手动验证反馈——首次向导改为主窗口稳定后延后一帧弹出，并在右键菜单增加 `重新运行向导` 入口；新增自动验证覆盖缺少配置时 Main 场景弹出 WizardDialog；重排展开面板内容宽度和对齐方式
- **2026-06-26**: 修复折叠金额栏垂直居中问题——折叠容器改为占满面板高度，金额 Label 显式设置 vertical center，并将该布局约束加入 `verify_m4.gd`
- **2026-06-26**: 继续优化折叠金额栏观感——折叠容器改为 `CenterContainer`，金额在完整 `150x54` 折叠面板内水平/垂直居中，自动验证同步检查容器尺寸和对齐
- **2026-06-26**: 完成 M5 Windows 打包——安装 Godot 4.7 Windows x86_64 export templates，新增 `export_presets.cfg`、`icons/app_icon.ico` 和 `scripts/verify_m5.ps1`；导出 `build/LetsMakeMoney.exe` 并通过启动冒烟验证
- **2026-06-27**: 重构 `doc/LetsMakeMoneyPRD.md` 为多版本 PRD，`v0.1 Beta` 与 `v0.2 Beta` 平级维护；新增 v0.2 Beta 桌宠窗口、Debug 模式、托盘、自启动、设置打磨、素材 Spike、验收和风险章节
- **2026-06-27**: 重写 `doc/implementation-plan.md` 为多版本实施计划，保留 v0.1 历史计划并新增 v0.2 Beta 详细实施计划；明确系统托盘和开机自启为 v0.2 必须完成项
- **2026-06-27**: 丰富 v0.2 Beta 实施计划颗粒度——补充目标文件结构、Platform/Config/Main/Settings/DragResizeSystem 接口骨架、托盘/自启动实现约束、验证脚本骨架和手动验证模板
- **2026-06-27**: 根据 v0.2 PRD 与实施计划 review 更新 `doc/progress.md`，新增 v0.2 总体进度、模块级最小任务 checklist、资源准备清单、已知风险、待实现前验证项和开发启动顺序
- **2026-06-27**: 根据当前代码实际状态回写 PRD、implementation-plan 和 progress，明确 v0.1 是调试窗口版 Beta；透明桌宠、真实系统托盘、关闭隐藏到托盘、开机自启和正式猫咪动画均未在 v0.1 落地，作为 v0.2 或后续任务继续推进
- **2026-06-30**: 合并临时素材分支 `temp/cat-orange-v1-assets-20260630`，接入橘猫素材并补充素材验证脚本
- **2026-06-30**: 调整宠物动画状态模型：idle / working / resting 作为基础状态，单击、双击、长按作为交互叠加状态
- **2026-07-01**: 完成 v0.2 核心实现：Config v0.2 字段、Debug/普通模式切换、紧凑桌宠窗口、设置通用项、开机自启、重置位置、恢复默认设置、v0.2 自动验证和导出链路
- **2026-07-01**: 发现 Godot 4.7 Windows 原生托盘、透明窗口和鼠标穿透能力存在访问违例风险，默认关闭 `system_tray_enabled`、`transparent_pet_window_enabled`、`mouse_passthrough_enabled`，转入 v0.3 技术预研
- **2026-07-01**: 根据手动验证修复 `debug_mode=false` 后窗口未恢复紧凑模式的问题；设置弹窗关闭后延迟重应用运行模式
- **2026-07-01**: 优化设置保存性能：自启动状态未变化时不再重复调用注册表删除，解决保存设置耗时过长的问题
- **2026-07-01**: 清理设置、Panel、右键菜单、托盘菜单接口、关于弹窗和薪资状态的用户可见中文乱码，并在 `verify_v02.gd` 中加入乱码扫描
- **2026-07-01**: 重新导出 `build\LetsMakeMoney.exe`，导出时间 `2026/7/1 22:03:59`，v0.2/M4/动画状态/橘猫素材自动验证均通过
- **2026-07-01**: 文档整理方向修正：恢复 PRD、Implementation Plan、Progress 的详细颗粒度，在原详细计划上补充当前状态覆盖层，而不是压缩为短版摘要
- **2026-07-02**: 根据 v0.2 暂缓项和当前项目状态补充 v0.3 Beta PRD，明确 v0.3 定位为桌宠原生能力修复版，动画打磨单独放入 v0.4
- **2026-07-02**: 根据 v0.3 PRD 更新 implementation-plan，新增 V03-M1 至 V03-M7 平级实施计划，路线为 Windows x86_64 GDExtension / 原生插件随 exe 发布
- **2026-07-02**: 启动 v0.3 实现并完成 V03-M1 首轮落地：新增 `native/windows/` GDExtension 骨架、`LMMNativeBridge` 最小 C++ 类、v0.3 配置默认值、Godot 侧 native health 接口和 `scripts/verify_v03.ps1/gd`；当前 native DLL 尚未构建，真实托盘和窗口原生能力仍待 V03-M2 之后继续实现
- **2026-07-02**: 推进 V03-M2 真系统托盘：新增 `TrayController` Win32 源码，使用 `Shell_NotifyIconW`、隐藏消息窗口和原生菜单承接托盘点击；`LMMNativeBridge` 暴露 `poll_tray_command()`，`Platform` 每帧轮询并转发为现有托盘信号；`verify_v03` 已覆盖托盘桥接模型，真实托盘显示仍等待 native DLL 构建后手动验证
- **2026-07-02**: 推进 V03-M3 透明无边框窗口：新增 `WindowController` Win32 源码，封装窗口样式、透明 layered window、置顶和任务栏可见性基础能力；`WindowsPlatform.get_native_window_handle()` 增加 Godot 主窗口句柄入口，`setup_window()` 在 native 失败时回退普通紧凑窗口；`verify_v03` 已覆盖窗口桥接模型，透明窗口仍等待 native DLL 构建后手动验证
- **2026-07-02**: 推进 V03-M4 点击穿透：`WindowController` 使用 `SetWindowRgn` 和交互矩形 union 保留小猫/Panel 可点击区域，透明空白区域从窗口区域剔除以穿透到下层；`Main.get_interactive_rects()` 统一计算交互区域并加入 hash 缓存，避免重复 native 调用；`verify_v03` 已覆盖穿透桥接模型，真实点击穿透仍等待 native DLL 构建后手动验证
- **2026-07-02**: 推进 V03-M5 关闭隐藏与纯桌宠安全门禁：`Main.can_hide_to_tray()` 只允许托盘健康时关闭隐藏，隐藏前保存窗口位置；`_apply_pure_pet_mode()` 要求托盘、任务栏控制和窗口句柄均可用；失败、Debug 模式或 native 不健康时自动恢复任务栏入口并写回 `pure_pet_mode=false`；`verify_v03` 已覆盖可找回门禁模型
- **2026-07-02**: 完成 V03-M6 设置体验与配置迁移：休息模式和窗口模式改为明确 `OptionButton`，新增纯桌宠模式开关和原生能力状态说明；`verify_v03` 覆盖旧配置迁移、恢复默认范围、设置控件替换和纯桌宠禁用门禁，`verify_m4` 回归通过
- **2026-07-02**: 推进 V03-M7 验证与发布材料：新增 `doc/verification/v0.3.md`、`scripts/verify_v03_export.ps1`、`releases/CHANGELOG.md` 和 `releases/v0.3-beta-notes.md`；导出验证脚本会在 native DLL 缺失时阻塞发布，符合当前门禁预期
- **2026-07-02**: 补充并调通 native 构建脚本 `scripts/build_native_windows.ps1`，优先使用本机 MSYS2 UCRT64，修复 MSYS2 HOME/TMP 权限问题、`LoadIconW` fallback 类型问题、`WindowController` 缺少 `<cstdint>` 和 `gdi32` 链接问题；`native/windows/bin/win64/letsmakemoney_native.dll` 已成功构建，`verify_v02`、`verify_v03`、`verify_m4` 和 `verify_v03_export` 均通过
- **2026-07-02**: 重新导出 v0.3 Beta Windows 包：`build\LetsMakeMoney.exe` 与 `build\letsmakemoney_native.dll` 更新时间 `2026/7/2 16:02:34`，文件版本 / 产品版本均为 `0.3.0`，`verify_v03_export` 冒烟验证通过；Godot 导出末尾仍提示无法保存编辑器设置 `editor_settings-4.7.tres`，不影响导出产物
- **2026-07-02**: 根据 `doc/verification/v0.3.md` 手动验证反馈修复 v0.3 阻塞问题：`WindowsPlatform.get_native_window_handle()` 改用 `DisplayServer.WINDOW_HANDLE`，避免 Win32 透明窗口/任务栏控制拿到 display handle；打开设置/向导前清空 `SetWindowRgn` 穿透区域，弹窗关闭后恢复穿透，解决设置控件无法更改；主场景设置 `auto_accept_quit=false` 并处理 `NOTIFICATION_WM_CLOSE_REQUEST`，关闭按钮改为托盘隐藏；托盘 native 层补充 `NIN_SELECT` / `NIN_KEYSELECT` 左键事件；新增 per-pixel transparency 项目设置。重新构建 native DLL 并导出 `build\LetsMakeMoney.exe` / `build\letsmakemoney_native.dll`，更新时间 `2026/7/2 16:25:29`，`verify_v02`、`verify_v03`、`verify_m4`、`verify_v03_export` 均通过
- **2026-07-03**: 完成 v0.3 收尾复测：修复小猫右键菜单偶发不弹出问题，保留普通点击穿透小命中框，同时新增右键专用上下文区域；native 层仅在 `VK_RBUTTON` 按下时放宽小猫 hit-test，Godot 主场景用 `get_pet_context_rect()` 兜底弹出右键菜单。已重新构建 native DLL、导出 `build\LetsMakeMoney.exe`、同步 `build\letsmakemoney_native.dll`，并通过 `verify_v02`、`verify_v03`、`verify_m4`、`verify_m5`、`verify_v03_export`。Codex 辅助复测确认猫头右键可弹菜单，无按键状态下猫头扩展区仍返回 `HTTRANSPARENT=-1`，不影响普通点击穿透
- **2026-07-03**: 统一 doc 验证文档结构和命名：每个版本只保留一个验证文档，现为 `doc/verification/v0.1.md`、`doc/verification/v0.2.md`、`doc/verification/v0.3.md`；原 M3/M4 零散验证文档已并入 v0.1，v0.4 后续验证文档路径预留为 `doc/verification/v0.4.md`。
- **2026-07-04**: 根据 v0.4 PRD 与 implementation-plan 更新 `doc/progress.md`：新增 V04-M0 原型与体验规格，将 v0.4 拆分为 V04-M0 至 V04-M5、V04-DOC 共 128 个 Vibe Coding 最小任务；明确默认温暖陪伴型方向、主题系统后置、动画素材管线优先、正式 Zip beta 发布包和文档闭环要求。
- **2026-07-04**: 完成 V04-M0 原型与体验规格：更新 `doc/prototypes/index.html`，新增 v0.4 默认桌宠体验、Panel 边缘状态、设置关键状态、托盘与发布包四个原型屏；更新 `doc/prototypes/prototype-spec.md`，补充 v0.4 默认温暖陪伴方向、Panel/设置/发布包体验原则和主题系统后置边界；同步 `doc/progress.md`，V04-M0 进度更新为 23/23，v0.4 总进度更新为 23/128。
- **2026-07-04**: 推进 V04-M1 橘猫动画与素材管线：新增 `doc/v0.4-animation-spec.md`，明确基础状态 + 交互延伸状态模型、命名规则、画布锚点、帧率/循环/漂移验收标准和回退要求；新增 `doc/v0.4-animation-assets-log.md` 记录当前 `cat_orange_v1` 作为 v0.4 fallback 的基线状态，并准备 `assets/pets/cat/orange_v2/` 的动画目录；新增 `scripts/verify_v04.gd` / `scripts/verify_v04.ps1`，验证当前橘猫资源、动画帧数/FPS/loop、默认 pet 配置和 PetManager 状态模型。
- **2026-07-04**: 根据用户确认更新 V04-M1 动画创意方向：橘猫 v2 可轻微优化但保持角色识别；working 动画加入键盘、电脑、金币等工作/金钱道具；resting 同时探索 sleepy sitting、lying down 和其他低动作姿态；单击/双击定义为 idle / working / resting 的延伸动作，不再要求通用 `clicked_single` / `clicked_double` 作为默认资源必备动画。同步更新 `doc/v0.4-animation-spec.md`、`doc/v0.4-animation-assets-log.md`、`doc/verification/v0.4.md`、`scripts/verify_v04.gd` 和 `assets/pets/cat/orange_v2/` 目录结构。
- **2026-07-04**: 补齐 V04-M1 素材执行链路：以 TDD 方式先让 `verify_v04.gd` 要求 v0.4 素材提示词执行集和 `orange_v2` asset manifest，然后新增 `doc/v0.4-animation-prompt-pack.md` 与 `assets/pets/cat/orange_v2/asset-manifest.json`；提示词执行集覆盖 idle、working、resting 多候选、base-state click extension 和 clicked_hold，manifest 记录 10 个必需动画条目的目录、最低帧数、loop 策略和待筛选状态。
- **2026-07-04**: 补齐 V04-M1 Godot 接入门禁：以 TDD 方式先让 `verify_v04.gd` 要求橘猫 v2 资源构建器，然后新增 `scripts/build_cat_orange_v2_resource.gd`；构建器读取 `asset-manifest.json`，强制检查 idle / working / resting / clicked_hold 以及三种基础状态下的单击、双击延伸动画帧数，并可生成 `cat_orange_v2_sprite_frames.tres` 和 `cat_orange_v2_resource.tres`。当时 v2 帧图尚未生成，因此默认仍保留 `cat_orange_v1`；后续在人工确认后已切换到 v2 beta 默认。
- **2026-07-04**: 补充 V04-M1 素材生成产能路线：根据免费额度有限的风险，在 PRD、implementation-plan、animation spec、assets log 和手动验证文档中新增 SpriteCook / ComfyUI / 本地 sprite 编辑工具 / Godot cutout 四条路线；SpriteCook 作为短期快速候选生成，ComfyUI 作为中长期自托管 Spike，本地编辑器负责透明边界和帧对齐清理，Godot cutout 作为逐帧 AI 不稳定时的确定性兜底。`verify_v04.gd` 已新增文档门禁，防止后续误删产能路线说明。
- **2026-07-04**: 推进 ComfyUI 本地 Spike 前置工作：新增 `scripts/check_comfyui_prereqs.ps1` 检查 Python、Git、NVIDIA GPU、推荐外部安装路径和橘猫 reference；新增 `doc/v0.4-comfyui-spike.md`，明确 ComfyUI 不进入用户功能、不下载模型进仓库、最小验证只需 idle / working / resting 三类候选，并记录 `<LOCAL_SOFTWARE>\ComfyUI` 外部安装建议。当前机器预检显示 RTX 5070 Ti、约 16GB VRAM、Python 3.12.8 和 Git 可用；V04-M1.5.5 仍保持未完成，等待真实候选图生成和人工评审。
- **2026-07-04**: 补齐 ComfyUI 本地 Spike 辅助脚本：新增 `scripts/setup_comfyui.ps1`、`scripts/start_comfyui.ps1` 和 `scripts/collect_comfyui_candidates.ps1`；setup 默认只浅克隆 ComfyUI 并创建 venv，只有显式传入 `-InstallDeps` 才安装 Python 依赖，不下载模型；start 默认监听 `127.0.0.1:8188`；collect 将外部 ComfyUI output 中的 PNG 候选复制到已忽略的 `_incoming/comfyui/<batch>` 目录并生成 batch notes。由于本机到 GitHub 443 连接当前超时，实际 clone/install 暂未执行，保留脚本等待网络可用或手动下载 ComfyUI。
- **2026-07-04**: 补充 ComfyUI 安装备用路径：尝试通过 GitHub connector 读取 `Comfy-Org/ComfyUI` 时插件握手超时，不能替代完整 clone/download；`scripts/setup_comfyui.ps1` 新增 `-ZipPath` 参数，支持先用浏览器、镜像或官方 portable 包把 ComfyUI 下载到本地，再解压安装到 `<LOCAL_SOFTWARE>\ComfyUI`。文档已明确 GitHub 插件只适合读取单文件/仓库信息，不作为完整应用下载器。
- **2026-07-04**: 使用用户网页端下载的 `%USERPROFILE%\Downloads\ComfyUI-master.zip` 完成 ComfyUI 本体安装：`scripts/setup_comfyui.ps1 -ZipPath ...` 已将源码解压到 `<LOCAL_SOFTWARE>\ComfyUI`，并创建 `<LOCAL_SOFTWARE>\ComfyUI\.venv`。当前未安装 Python 依赖、未下载模型、未启动 ComfyUI，符合“不把大体积生成工具和模型放入项目仓库”的边界；下一步需要用户确认后再执行 `-InstallDeps`。
- **2026-07-04**: 完成 ComfyUI 本地 Spike 运行环境验证：在 `<LOCAL_SOFTWARE>\ComfyUI\.venv` 中安装 ComfyUI Python 依赖，并将误装的 CPU PyTorch 替换为官方 CUDA 12.8 组合 `torch 2.11.0+cu128` / `torchvision 0.26.0+cu128` / `torchaudio 2.11.0+cu128`；`torch.cuda.is_available()` 已返回 true，设备为 `NVIDIA GeForce RTX 5070 Ti`，`pip check` 无依赖冲突，`main.py --listen 127.0.0.1 --port 8188` 可启动并打开本地 Web 服务。当前仍未下载模型、未生成候选图，V04-M1.5.5 继续等待真实 idle / working / resting 候选批次和人工评审。
- **2026-07-04**: 完成秋叶 ComfyUI / 绘世启动器外部环境验证：用户下载的 `<LOCAL_SOFTWARE>\ComfyUIaaaki\ComfyUI-aki-v3_password_bilibili-秋葉aaaki.7z` 已解压到 `<LOCAL_SOFTWARE>\ComfyUIaaaki\ComfyUI-aki-v3`，入口为 `绘世启动器.exe`；新增 `scripts/check_comfyui_aki_prereqs.ps1` 和 `scripts/start_comfyui_aki.ps1`，确认内置 Python 3.13.11、`torch 2.9.1+cu130`、CUDA 13.0、RTX 5070 Ti、ComfyUI 0.9.2 和 `127.0.0.1:8190/system_stats` 均可用；预置关键节点包含 ComfyUI-Manager、IPAdapter Plus、ControlNet Aux、RMBG、VideoHelperSuite、WanVideoWrapper 和 LTXVideo。随包协议说明整合包不提供模型权重、工作流和提示词，且启动器免费严禁倒卖；因此后续 skill 只能沉淀我们自己的素材管线，不分发秋叶包、模型或第三方工作流。当前仍未下载模型、未生成候选图，V04-M1.5.5 继续等待模型路线确认和真实候选批次。
- **2026-07-04**: 完成橘猫 v2 cutout 工程候选批次：新增 `scripts/generate_cat_orange_v2_cutout_candidates.py`，从 `cat_orange_v1` 派生 `orange_v2` 的 10 组必需动画帧，working 叠加电脑/键盘/金币，resting 叠加休息符号，单击/双击保持 base-state extension 模型；生成 `cat_orange_v2_sprite_frames.tres` 与 `cat_orange_v2_resource.tres`，修复构建器在 headless 下读取未导入 PNG 失败的问题，并要求资源使用外部 PNG 引用而不是嵌入大体积 ImageTexture。`verify_v04.ps1` 已覆盖 v2 资源加载、帧数、loop 策略和资源大小门禁。人工反馈认为该批视觉质量不达标，因此只保留为管线验证样张，默认角色仍保留 `cat_orange_v1`。
- **2026-07-04**: 生成第二批橘猫 v2 imagegen concept 候选：使用统一橘猫概念图生成 idle、working、resting、single-click、double-click 和 hold 六个 pose，再通过 `scripts/generate_cat_orange_v2_from_concept_sheet.py` 裁切、去白底、规范到 256×256 并派生 10 组动画帧；working 的电脑/金币和 resting 的睡眠姿态已作为构图一部分，不再采用贴片式道具。已重新导入 PNG、重建 `cat_orange_v2_sprite_frames.tres` / `cat_orange_v2_resource.tres`，`verify_v04.ps1` 与 `git diff --check` 均通过。该批次随后经过人工多轮修帧确认，已切换为 v0.4 beta 默认资源。
- **2026-07-04**: 新增 `doc/verification/v0.4.md` 作为 v0.4 唯一手动验证文档，覆盖基础信息、验证前准备、自动验证、原型、动画、交互、窗口/点击穿透、Panel、设置、托盘、性能和发布包；验证表统一包含结果、备注、优化方案和复测结果列，方便后续按手动结果逐项修复。
- **2026-07-04**: 以 TDD 方式推进 V04-M2 首个交互修复：先在 `scripts/verify_v04.gd` 增加拖拽优先级检查并确认失败，再修改 `src/scenes/pet/pet.gd`，使拖拽开始后清除长按语义，拖拽过程中不再请求 `CLICKED_HOLD`，拖拽结束后回到 hover 或自动基础状态；`verify_v04.ps1` 重新通过。
- **2026-07-04**: 继续以 TDD 推进 V04-M2 右键菜单优先级：先在 `verify_v04.gd` 要求右键分支清理 pending 单击/双击/长按/拖拽状态并标记输入已处理，再在 `pet.gd` 增加 `_reset_press_tracking()`，确保右键弹菜单不会触发或遗留左键交互状态；`verify_v04.ps1` 通过。
- **2026-07-04**: 继续以 TDD 推进 V04-M2 hover 门禁：先在 `verify_v04.gd` 要求 `_on_mouse_entered()` 经过 hover 进入条件判断，再在 `pet.gd` 增加 `_can_enter_hover()`，避免鼠标进入事件打断正在播放的单击、双击和长按反馈；`verify_v04.ps1` 通过。
- **2026-07-04**: 继续以 TDD 推进 V04-M2 交互恢复路径：先在 `verify_v04.gd` 要求 PetManager 记录 `_interaction_base_state` 并提供 `return_to_interaction_base_state()`，再在 `pet_manager.gd` 中记录进入交互前基础状态，在 `pet.gd` 的延迟恢复中回到该基础状态；验证脚本同时加入真实行为检查，确认 WORKING 状态双击结束后恢复 WORKING 且清空交互状态。
- **2026-07-04**: 继续以 TDD 推进 V04-M2 双击识别：先在 `verify_v04.gd` 要求点击释放通过 `_register_click_release()` 统一分流，并使用 `_fire_click_interaction()` 触发单击/双击；再在 `pet.gd` 中改为第一次点击等待双击窗口、第二次点击释放立即触发 `CLICKED_DOUBLE`，单击只在窗口超时后触发，避免双击前播放两次单击。
- **2026-07-04**: 继续以 TDD 推进 V04-M2 长按阈值校准：先在 `verify_v04.gd` 要求 `LONG_PRESS_THRESHOLD := 0.5`，再将 `pet.gd` 长按触发从 0.35 秒调整为 0.5 秒，降低长按与拖拽争抢的概率，并与 v0.4 手动验证步骤保持一致。
- **2026-07-04**: 继续推进 V04-M2 单击反馈和拖拽手感：先在 `verify_v04.gd` 增加点击反馈保持时长与拖拽绝对屏幕位移断言，再在 `pet.gd` 中将单击/双击反馈回程时间调整为 0.75 秒；验证同时覆盖拖拽继续使用 `DisplayServer.mouse_get_position() - _drag_start_screen_mouse` 和 `_drag_start_window_pos + delta`，避免窗口移动速度异常。后续根据人工反馈确认 idle 单击/双击 12fps 过快，已将 v2 idle 单击降为 6fps、idle 双击降为 7fps，让 4-5 帧动作能被肉眼读到。
- **2026-07-04**: 完成 V04-M2 小猫 hover 与 Panel hover 协调首轮验证：`verify_v04.gd` 新增 Panel hover 职责边界检查，确认 `PanelSystem` 独立负责 Panel 展开/收起，`pet.gd` 不直接控制 Panel，Panel leave delay 保持 0.5 秒以避免鼠标从小猫移动到 Panel 时快速闪烁；V04-M2 交互手感首轮任务更新为 15/15。
- **2026-07-04**: 继续以 TDD 推进 V04-M3 点击穿透调试能力：先在 `verify_v04.gd` 增加命中区调试、刷新原因日志和 native 失败错误记录检查，再在 `main.gd` 新增 debug-only `HitDebugLayer`，Debug 模式按 `H` 可显示/隐藏 Pet core、Pet context、Panel collapsed/expanded 命中区；同时将穿透刷新统一为 `_request_mouse_passthrough_refresh(reason)`，日志输出刷新原因、窗口位置、缩放倍率、本地 rect 和屏幕 rect。`windows_platform.gd` 在 native `set_mouse_passthrough` / `clear_mouse_passthrough` 失败时写入 `_native_health["last_error"]`，便于复测时定位原生 hit-test 问题。
- **2026-07-04**: 继续以 TDD 推进 V04-M3 Panel 边缘定位：先在 `verify_v04.gd` 增加 `_resolve_panel_position()` 行为断言，覆盖默认位置、靠右、靠底和右下角场景；再在 `main.gd` 中抽出 `_get_panel_target_size()`、`_candidate_panel_positions()`、`_panel_fits_screen()` 和 `_panel_overflow_area()`，根据屏幕边缘选择默认右侧、左侧、上方或左上方候选，全部放不下时记录 `Panel edge fallback` 并选择溢出面积最小的位置。
- **2026-07-04**: 补齐 V04-M3 桌宠窗口可找回兜底验证：`verify_v04.gd` 增加 `can_hide_to_tray()`、`_apply_pure_pet_mode()`、`WindowsPlatform.setup_window()` 和 `Config.merge_with_defaults()` 检查，确认托盘不可用时不隐藏任务栏入口，纯桌宠模式必须通过托盘/native health/窗口句柄门禁，native 透明窗口失败会回退普通窗口，配置缺字段或损坏时使用默认值继续启动。
- **2026-07-04**: 将 Panel 折叠态金额垂直居中纳入 v0.4 回归：`verify_v04.gd` 实例化 `panel.tscn`，等待布局完成后调用 `collapse()`，断言 `Collapsed/EarningsToday` 的视觉中心与折叠容器中心偏差不超过 2px，避免后续样式调整破坏 v0.1-v0.3 已修正的金额栏观感。
- **2026-07-04**: 完成 V04-M3 缩放边界首轮优化：先在 `verify_v04.gd` 增加 50%、75%、100%、125%、150%、200% 缩放下的小猫纹理边界和 Panel 默认边界断言，再在 `main.gd` 新增 `_pet_window_size_for_scale()` 与 `_pet_sprite_bounds_for_scale()`，让桌宠窗口尺寸随缩放预留内容空间，避免 200% 缩放时小猫底部被固定窗口裁切。
- **2026-07-04**: 继续以 TDD 推进 V04-M4 设置页信息架构：先在 `verify_v04.gd` 增加设置页分类检查，要求 v0.4 保留 Salary / Pet / Display / Panel / General 五类且不新增 Theme；再将缩放控件从 Pet 页移动到 Display 页，Display 页集中展示透明度、缩放、窗口模式、点击穿透说明和纯桌宠模式说明，General 页继续管理开机自启、关闭隐藏到托盘、Debug、重置窗口位置和恢复默认设置；native 状态文案增加 `last_error` 不可用原因，避免平台能力失败时静默。
- **2026-07-04**: 继续以 TDD 推进 V04-M4 保存差异检测与反馈：先在 `verify_v04.gd` 增加设置保存反馈检查，再在 `settings_dialog.gd` 新增 `SaveStatusLabel`、`_collect_form_values()`、`_current_settings_snapshot()`、`_has_form_changes()` 和 `_apply_form_values()`；保存前先对比表单与当前配置，无变化时提示“没有需要保存的更改”并保持窗口打开，有变化时只写入变更字段，开机自启继续通过 `desired == actual` 跳过无变化注册表操作，保存成功/失败均显示轻量状态提示并保留用户输入。
- **2026-07-04**: 补齐 V04-M4 恢复默认与 Debug 入口：`settings_dialog.gd` 新增 `RestoreDefaultsConfirmDialog`，点击“恢复默认显示设置”先弹出确认，文案明确只重置显示、窗口、托盘、自启动和 Debug 设置，不清空薪资、工时、角色和 Panel 项；General 页补充 `%APPDATA%\LetsMakeMoney\config.json` 路径和 `debug_mode` 保存后必要时重启生效的说明。`verify_v04.gd` 已覆盖确认弹窗、恢复默认调用和 Debug 配置路径文案。
- **2026-07-04**: 继续以 TDD 推进 V04-M5 日志分层：先在 `verify_v04.gd` 增加日志边界检查，再在 `Platform.write_boot_log()` 增加 `level` 参数与 `write_debug_log()`；普通模式继续保留启动/退出/native 初始化/失败等关键日志，高频的命中区 rect、passthrough region 刷新原因、native passthrough 调用细节和托盘轮询命令改为 debug-only，只有 `debug_mode=true` 时写入，减少常驻运行时 `debug.log` 膨胀。
- **2026-07-04**: 补齐 V04-M5 自动验证覆盖：`verify_v04.gd` 现在除动画资源、PetManager 状态、交互、Panel、设置和窗口兜底外，还显式加载 `main.tscn` 与 `settings_dialog.tscn`，检查 `debug_mode`、透明窗口、点击穿透、托盘、纯桌宠、缩放和透明度等关键默认配置；`verify_v04.ps1` 在 Godot 脚本成功后额外输出 `v0.4 verification passed`，便于 PowerShell 入口和 CI 日志识别通过状态。
- **2026-07-04**: 补齐 V04-M5 正式 Zip beta 包脚本：新增 `scripts/package_v04.ps1`，从 `build/LetsMakeMoney.exe`、`build/letsmakemoney_native.dll`、`README.md` 和 `releases/v0.4-beta-notes.md` 生成 `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64.zip`；脚本同时生成 staging 目录、`manifest.json` 和 `checksums.txt`，manifest 记录版本、平台、配置路径、文件大小和 sha256。已本地执行脚本并确认 Zip 内包含 exe、native dll、README、release-notes、manifest 和 checksums。
- **2026-07-04**: 补齐 V04-M5 发布包烟测：新增 `scripts/verify_v04_package.ps1`，解压 `LetsMakeMoney-v0.4-beta-windows-x86_64.zip` 到 `.tmp_release/verify_v04_package`，检查 exe、native dll、README、release-notes、manifest 和 checksums 均存在，校验 manifest 的包名与 `%APPDATA%\LetsMakeMoney\config.json` 配置路径；随后用临时 APPDATA 启动解压后的 exe，确认 3 秒内未异常退出并关闭进程。同步修正 `verify_v02.gd` 的旧长按阈值断言，使其兼容 v0.4 已校准的 0.5 秒长按规格。`verify_v02.ps1`、`verify_v03.ps1` 和 `verify_v04_package.ps1` 均已通过。
- **2026-07-04**: 同步 v0.4 发布记录：`releases/CHANGELOG.md` 新增 v0.4 Beta 中文条目，记录新增动画素材管线、Debug 命中区、发布包脚本、交互优先级、Panel 边缘定位、设置保存反馈、日志分层、验证脚本和已知边界。
- **2026-07-04**: 补齐 V04-M4 单窗口宿主验证：`verify_v04.gd` 增加 `DragResizeSystem.open_settings()` 结构检查，确认设置页以 `Control` 内容视图挂到现有宿主窗口、使用 `PRESET_FULL_RECT` 占满窗口，不再通过 `popup_centered` 打开嵌套弹窗；progress 同步更新到 V04-DOC 持续同步完成。
- **2026-07-04**: 收束 v0.4 可自动完成的性能与保存分流项：`Config` 新增本次保存变更 key 记录，`Main._on_config_changed()` 改为 `_apply_config_change_scope()` 分流处理，salary / schedule 变更只刷新薪资与 Panel 数值，不再触发完整窗口策略；passthrough 刷新改为 `_queue_mouse_passthrough_refresh()` 合并到下一帧，窗口移动轮询只在实际位置变化后触发；`WindowsPlatform` 为 topmost、embed 和 taskbar visibility 加 no-op 缓存；`verify_v04.gd` 覆盖刷新节流、配置分流、Panel 金额 interval 刷新和 native 重复调用限制。`verify_v04.ps1`、`verify_m4.ps1`、`verify_v03.ps1`、`verify_v02.ps1` 均已通过。
- **2026-07-04**: 接入橘猫 v2 beta 默认资源：根据人工反馈完成 idle 单击/双击帧的筛选和多轮修正后，将 `Config` 默认 `pet_id` 调整为 `cat_orange_v2`；`PetManager` 改为递归扫描 `assets/pets/` 下所有 `*_resource.tres`，支持 `assets/pets/cat/orange_v2/` 这类嵌套资源路径，并保留 `cat_orange_v1` 作为显式 fallback；同步更新 `asset-manifest.json`、`doc/v0.4-animation-assets-log.md`、`doc/verification/v0.4.md` 和 `verify_v04.gd`，将 v2 状态从“等待人工确认”改为“v0.4 beta 默认接入”。
- **2026-07-04**: 重新导出 v0.4 exe 并复打发布包：将 `export_presets.cfg` 版本号更新为 `0.4.0`，修正文件描述编码，排除 `assets/pets/cat/orange_v2/_review/` 与 `_incoming/` 评审/候选目录，避免大体积开发素材进入发布 exe；复制 Godot 4.7 export templates 到项目本地 `.godot_user` 后使用本地 APPDATA 导出，生成 `build/LetsMakeMoney.exe`；运行 `scripts/package_v04.ps1` 生成 `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64.zip`，`scripts/verify_v04_package.ps1` 烟测通过。
- **2026-07-04**: 补强 v0.4 发布与稳定性自动验证：`verify_v04_package.ps1` 增加 manifest 版本检查、manifest 文件 SHA256 校验和 `checksums.txt` 校验；新增 `scripts/verify_v04_stability.ps1`，从 v0.4 zip 解压 release exe，使用临时 `%APPDATA%` 和 `cat_orange_v2` 默认配置启动 60 秒，确认进程不提前退出并写出配置文件。`verify_v04_package.ps1` 与 `verify_v04_stability.ps1 -DurationSeconds 60` 均已通过。
- **2026-07-04**: 完成 v0.4 手动验证文档 Part 3 / Part 4 的 Codex 代验回填：对 `doc/prototypes/index.html`、`doc/prototypes/prototype-spec.md`、`doc/v0.4-animation-spec.md`、`doc/v0.4-animation-assets-log.md`、`doc/v0.4-animation-prompt-pack.md`、`assets/pets/cat/orange_v2/asset-manifest.json`、最终 contact sheet、动画目录、默认资源配置和 PetManager 状态映射进行静态/资源验证；重新运行 `verify_v04.ps1` 与 `check_comfyui_prereqs.ps1`，均通过。已在 `doc/verification/v0.4.md` 将 V04-MAN-001 至 V04-MAN-006、V04-MAN-020 至 V04-MAN-032 标记为通过，并注明这是 Codex 静态/素材检查，真实桌面长时间观感仍留给后续完整复测。
- **2026-07-04**: 修复导出 exe 初始化向导“无动物可选”：用户复测发现首次初始化角色列表为空，`debug.log` 显示导出包运行时 `PetManager._ready: scanned pets=0`，而编辑器环境可扫描到 3 个资源。根因是导出 exe 中依赖 `res://assets/pets` 目录遍历不稳定。`PetManager` 现保留递归目录扫描，同时新增 `BUILTIN_PET_RESOURCE_PATHS` 显式加载 `cat_orange_v2`、`cat_orange_v1` 和旧 `cat` 资源，确保导出包无法枚举目录时仍可提供角色列表；`verify_v04.gd` 增加可用宠物断言，`verify_v04_stability.ps1` 增加导出包日志断言，要求 `scanned pets > 0` 且 `current_pet != null`。已重新导出 exe、重新打包 v0.4 zip，并通过 `verify_v04.ps1`、`verify_v04_package.ps1`、`verify_v04_stability.ps1 -DurationSeconds 60`、`verify_v03.ps1`、`verify_v02.ps1` 和 `verify_m4.ps1`。
- **2026-07-04**: 根据 v0.4 手动验证 Part 5 全部不通过结果修复小猫交互命中链路：根因是 v0.3 时代的 `98x86` 小命中框仍用于 Pet Area2D 碰撞和 Windows 原生点击穿透白名单，无法覆盖 v2 `256x256` 橘猫实际可视区域，导致左键单击、双击、长按、拖拽和右键菜单都容易落在“看得见但点不到”的区域。现改为按当前 SpriteFrames 纹理尺寸动态生成 Pet 交互矩形，同步更新 Area2D 碰撞框，并让 `Main.get_interactive_rects()` / `get_pet_context_rect()` 基于实际小猫位置、缩放和 padding 生成系统级非穿透区域；`verify_v04.gd` 增加运行时 Pet 命中框断言，`verify_v03.gd` 同步升级旧命中框回归断言。已重新导出 exe、重新打包 v0.4 zip，并通过 `verify_v04.ps1`、`verify_v03.ps1`、`verify_v02.ps1`、`verify_m4.ps1`、`verify_v04_package.ps1` 和 `verify_v04_stability.ps1 -DurationSeconds 60`；`doc/verification/v0.4.md` 已将 V04-MAN-040 至 V04-MAN-045 标记为已修复待人工复测。
- **2026-07-05**: 尝试使用 Computer Use 代替人工点击测试 v0.4 桌宠窗口，但当前 Codex 桌面自动化通道连续返回 `Transport closed`，无法可靠执行窗口截图和鼠标点击。为降低后续复测成本，在 `pet.gd` 为 Part 5 关键交互新增低频诊断日志：单击、双击、长按、拖拽开始/结束和右键菜单触发时写入 `debug.log`，记录 interaction、基础状态、指针位置或窗口位置。已重新导出 `build/LetsMakeMoney.exe` 并重新打包 v0.4 zip，通过 `verify_v04.ps1`、`verify_v03.ps1`、`verify_v02.ps1`、`verify_m4.ps1`、`verify_v04_package.ps1` 和 `verify_v04_stability.ps1 -DurationSeconds 60`。
- **2026-07-05**: 根据外部 Computer Use 复测结论继续修复 V04-M2：日志已证明左键单击、双击和右键事件能进入 Godot/Pet，不是整体点击穿透问题；拖拽仍没有 `drag_start` / `drag_end`，且拖拽终点会被误判为 `clicked_single`。本轮将 Pet 输入门禁改为 `_mouse_pressed` 期间继续处理 motion/release，即使指针已经离开当前小猫命中框也不丢事件；拖拽阈值同时比较屏幕位移和 viewport 位移，并新增 `mouse_down`、`mouse_release classified=click`、`drag_threshold` 日志。针对“单击/双击视觉太短、双击只有小幅动作”的反馈，将所有 single 动画放慢到 3fps，将 double 动画放慢到 3.25-3.5fps，并把 `CLICK_RETURN_DELAY` 从 0.75s 提升到 1.55s，非循环动画播放时强制从第 0 帧重启，附加视觉 tween 也延长 out/hold/return 三段。`verify_v04.ps1` 已通过，后续仍需重新导出包并人工复测 V04-MAN-028、V04-MAN-029、V04-MAN-040 至 V04-MAN-045。
- **2026-07-05**: 完成上述交互修复后的发布包刷新：重新导出 `build/LetsMakeMoney.exe`，重新生成 `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64.zip`；通过 `verify_v04.ps1`、`verify_v03.ps1`、`verify_v02.ps1`、`verify_m4.ps1`、`verify_v04_package.ps1` 和 `verify_v04_stability.ps1 -DurationSeconds 60`。下一轮人工复测重点仍是 V04-MAN-028、V04-MAN-029、V04-MAN-040 至 V04-MAN-045，尤其观察单击/双击是否足够可读、拖拽是否出现 `drag_start` / `drag_end`。
- **2026-07-05**: 深查单击/双击“日志触发但视觉几乎不变”的根因：点击事件、PetManager 动画名解析和 v2 SpriteFrames 资源均存在，但 click 序列的首帧/末帧多为基础姿态，非循环动画播完后会停在末尾基础姿态；在 3-4 帧短动画中，真正动作帧占比过低，肉眼容易感觉一直保持原动作。本轮在 `build_cat_orange_v2_resource.gd` 中为点击动画写入帧 duration 权重：首尾中性帧 0.35，动作帧 2.2；同时在 `pet.gd` 中为 single/double 触发新增三段截图诊断，自动保存 0.05s、0.45s、0.90s 的小猫区域截图到 `%APPDATA%\LetsMakeMoney\interaction-screenshots`，并在 `debug.log` 记录 resolved animation、frame、progress 和截图路径。Debug 大窗口点击恢复时间也同步为 1.55s，并回到交互前基础状态。`verify_v04.ps1` 已覆盖点击帧 duration 权重和截图诊断入口。
- **2026-07-05**: 截图诊断进一步确认真正覆盖源头：日志出现 `animation_play resolved=idle_clicked_single/working_clicked_single`，但 50ms 后截图记录仍是 `anim=idle/working`，说明点击动画刚播放就被恢复成基础动画。根因是点击反馈期间鼠标命中矩形随动画/缩放变化触发 `_on_mouse_exited()`，旧逻辑在 mouse exit 时无条件 `return_to_auto_state()`；现已改为只有 `_can_enter_hover()` 为 true 时才允许 mouse exit 回基础状态，因此 single/double/hold 期间不会被 hover/exit 打断。`verify_v04.gd` 新增门禁，要求 `_on_mouse_exited()` 同样经过 `_can_enter_hover()` 保护。
- **2026-07-05**: 修复设置 General 页切换 Debug 模式保存时的窗口混入问题：用户截图显示保存 `debug_mode` 后，宠物和主窗口内容被重新显示到设置宿主内，形成大灰/黑背景叠在设置页上的异常观感。根因是 `Config.set_value("debug_mode")` 会在设置 modal 尚未关闭时触发 `Main._apply_config_change_scope()`，旧逻辑立刻 `_setup_window()` 并调度 runtime reapply，而 `_reapply_runtime_mode_after_popups()` 又自行将 `_modal_open=false` 并显示 pet/panel。现改为 modal 打开期间只记录 `_runtime_mode_reapply_deferred_until_modal_close`，Debug 模式和窗口策略统一延后到 `modal_closed` 后应用；runtime reapply 若发现 modal 仍打开会继续延后，且不再自行清除 modal 状态。`verify_v04.gd` 已新增结构检查，`doc/verification/v0.4.md` 新增 V04-MAN-088 复测项。
- **2026-07-05**: 根据新一轮手动验证结果继续优化 v0.4：V04-MAN-040/041 虽已触发单击/双击，但反馈叠加层使用非等比 `_pulse_visual` 导致小猫第二帧出现明显拉伸，现改为等比轻微放大，避免动作帧被代码压扁；V04-MAN-061 的透明空白区不穿透，根因是穿透白名单使用整张 256px 纹理矩形，现改为 Pet 根据当前帧 alpha 可见区计算命中框，Main 复用该矩形生成 Windows passthrough rect；V04-MAN-063 的 Panel 慢速进入不展开，现改为 `PanelSystem` 每帧轮询 Panel 本地鼠标位置并让 Panel 根节点接收 hover；V04-MAN-064/065 按反馈取消 Panel 靠右/靠底自动换位，固定默认右下锚点；V04-MAN-067 修复 Display 缩放只影响 Pet 不影响 Panel 的问题，Panel 现在随 `scale` 同步缩放，窗口尺寸和穿透 rect 也按缩放后的 Panel 计算。`verify_v04.ps1`、`verify_v03.ps1`、`verify_v02.ps1`、`verify_m4.ps1` 和 `git diff --check` 均已通过。
- **2026-07-05**: 根据最新 v0.4 UI polish 反馈更新 `doc/progress.md`：新增 V04-M6 正式进度模块，将 Win11 风格设置窗口、右键二级菜单、Panel polish、托盘/窗口图标、原型更新和验证门禁拆成 47 个 Vibe Coding 最小任务；v0.4 总进度从 132/134 调整为 136/181，明确 UI polish 进入正式实现范围，而非主题系统或口头优化。
- **2026-07-05**: 根据 UI 风格变化继续优化 v0.4 交互原型：`doc/prototypes/index.html` 的 v0.4 UI polish 屏改为 Win11 风格设置窗口预览，使用左侧 Salary / Pet / Display / Panel / General 分类导航、右侧卡片式设置项和“查找设置”占位；新增右键菜单二级入口预览，展示 `窗口模式 >` 与 `选择宠物 >` 子菜单和当前项标记；新增 16 / 24 / 32 / 48 / 64 / 128 / 256 图标尺寸预览。同步更新 `doc/prototypes/prototype-spec.md` 的交互说明、设计决策和验收标准，并补齐 `doc/implementation-plan.md` 的右键二级菜单、Win11 设置窗口和图标 polish 任务，将 V04-M6 文档/原型相关 checklist 更新为 14/47。
- **2026-07-05**: 开始落地 V04-M6 Panel polish：`panel.tscn` 折叠态从单个金额 Label 调整为 `金额 + 短状态` 的居中 HBox 结构，`panel.gd` 增加短状态映射，折叠宽度从 150 调整到 184 以容纳状态文字；同步更新 `verify_m4.gd` 与 `verify_v04.gd`，不再硬编码旧版 150 宽度，并继续验证折叠内容垂直居中。`verify_v04.gd`、`verify_m4.gd`、`verify_v03.gd`、`verify_v02.gd` 均已通过。
- **2026-07-05**: 继续推进 V04-M6：Panel 展开态重排为今日已赚优先、状态辅助、本月累计/时薪/进度作为详情，并增加暖墨半透明、轻边框、今日金额字号优先和低对比进度条样式；右键菜单将窗口模式和选择宠物从一级平铺项改为 `PopupMenu` 二级入口，保留原 ID 处理和配置保存逻辑，`verify_v04.gd` 新增二级菜单静态门禁，`verify_v02.gd` 更新为兼容新旧菜单结构。`verify_v04.gd`、`verify_v03.gd`、`verify_v02.gd`、`verify_m4.gd` 均已通过。
- **2026-07-05**: 推进 Win11 风格设置窗口结构：`settings_dialog.gd` 从顶部 `TabContainer` 改为 `WinSettingsHeader` + 左侧 `SettingsNav` + 右侧 `SettingsContent`，顶部加入不可编辑的“查找设置”占位，左侧保留 Salary / Pet / Display / Panel / General 五分类；现有 `_build_*_tab()` 页面和保存/恢复默认逻辑继续复用。`verify_v04.gd` 新增静态门禁，要求设置窗口不再使用旧顶部 TabContainer，并验证搜索占位、左侧导航、右侧内容区存在。`verify_v04.gd`、`verify_v02.gd`、`verify_m4.gd` 均已通过。
- **2026-07-05**: 完成 v0.4 图标 polish 首轮：基于 `cat_orange_v2` 默认 idle 素材重新生成 `icons/app_icon.png`、`icons/app_icon.ico` 以及 16 / 24 / 32 / 48 / 64 / 128 / 256 多尺寸 PNG；16/24 托盘尺寸采用猫头聚焦裁切以提高小尺寸识别度，大尺寸保留圆角底图和完整橘猫。`main.gd` 的托盘初始化改为传入 `ProjectSettings.globalize_path("res://icons/app_icon.ico")`，与 Win32 `LoadImageW(... IMAGE_ICON ...)` 对齐。`verify_v04.gd` 新增图标文件、export preset 和 native 托盘路径静态门禁；`verify_v04.gd`、`verify_v03.gd`、`verify_v02.gd`、`verify_m4.gd` 均已通过。
- **2026-07-05**: 继续落地 Win11 风格设置窗口细节：`settings_dialog.gd` 增加 `_add_setting_card()` / `_add_control_card()` / `_add_info_card()`，将 Salary、Pet、Display、Panel、General 各页设置项统一整理为标题、说明和控件同卡片的结构；保留五个既有分类，不新增 Theme / Appearance / 主题入口。`verify_v04.gd` 新增设置卡片结构静态门禁，`verify_v04.gd`、`verify_v03.gd`、`verify_v02.gd`、`verify_m4.gd` 均已通过。
- **2026-07-05**: 将“关于 LetsMakeMoney”从系统 `OS.alert` 替换为应用内 `AcceptDialog`，显示 `icons/app_icon.png` 高分辨率图标、`LetsMakeMoney v0.4 Beta` 版本文案和配置路径说明，去除旧 v0.2 关于弹窗残留；`verify_v04.gd` 新增关于窗口图标与版本文案检查。
- **2026-07-05**: 补充 `doc/verification/v0.4.md` 的 UI polish 专项验证：新增 Panel 信息层级、Win11 风格设置窗口、右键二级菜单和图标统一性的 V04-MAN-140 至 V04-MAN-164 复测项，明确操作步骤、预期行为和当前优化方案，方便后续集中人工复测。
- **2026-07-05**: 收紧 Panel polish 自动验证：`verify_v04.gd` 在原有折叠态垂直居中检查之外，新增折叠内容宽度不得溢出面板的断言，并继续覆盖 50% / 75% / 100% / 125% / 150% / 200% 缩放下窗口和 Panel 边界；`verify_v04.gd` 已通过。
- **2026-07-05**: 收紧 Win11 风格设置窗口门禁：`verify_v04.gd` 在现有单一 `SettingsRoot`、左侧导航、右侧内容区、卡片式设置项检查之外，新增禁止设置页使用 `TextureRect` 装饰图、禁止营销式/主题入口文案的断言，确保设置窗口保持极简工具属性，不退回宠物装饰页或落地页风格。
- **2026-07-05**: 完成 UI polish 后的发布包刷新：先运行 `verify_v04.ps1`、`verify_v03.ps1`、`verify_v02.ps1`、`verify_m4.ps1` 和 `git diff --check`，随后重新导出 `build\LetsMakeMoney.exe`；导出日志发现 `releases/v0.4` 产物会被 `all_resources` 打进 exe，已将 `releases/**` 加入 `export_presets.cfg` 排除规则后重新导出。重新运行 `package_v04.ps1` 生成 v0.4 zip，并通过 `verify_v04_package.ps1` 与 `verify_v04_stability.ps1 -DurationSeconds 60`。
- **2026-07-05**: 根据“Panel 和设置页面仍不够精致、Display 页过长、保存/取消位置不符合预期”的反馈进行 UI polish 第三轮：确认当前可用能力为本地 `ui-ux-pro-max` / `frontend-design` skill，未发现可直接用于 Godot UI 换肤或视觉验收的插件；设置窗口改为 Header 右上角关闭按钮、底部固定 `ActionRow` 放置取消/保存，所有设置分类改为独立 `ScrollContainer`，Display 页内容过长时只滚动右侧内容区；设置卡片从上下堆叠改为左侧标题/说明、右侧控件的 Win11 列表项结构，开关项右侧只保留开关本体；Panel 增加更细的暖黑底、边框、阴影、淡入缩放和更大字号。`verify_v04.ps1` 与 `verify_m4.ps1` 已通过，`doc/verification/v0.4.md` 已同步三轮优化方案。
- **2026-07-05**: 深查并修复 UI 清晰度问题：用户截图显示 Panel 在大缩放下仍然发糊，尤其中文“赚”等字形糊成低清块。根因是 `Main._apply_scale_opacity()` 直接 `panel.scale = Vector2(s, s)` 放大整个 Control，Panel 字体、进度条和背景都被画布变换拉伸；同时设置页未显式指定中文系统字体，Display 的原生能力状态又被作为右侧窄控件压缩成竖排。现改为 `Panel.set_display_scale()` 按缩放重算真实面板尺寸、间距、进度条高度和字号，Panel 自身保持 `scale = Vector2.ONE`；Panel 与 Settings 均使用 `Microsoft YaHei UI / Microsoft YaHei / Segoe UI` 系统字体；设置窗口提升到 `1040x760`，Display 的 `原生能力状态` 与 General 的 `操作反馈` 改为整行状态卡。图标链路同步修复：`project.godot` 运行图标改为 `icons/app_icon.png`，运行时通过 `DisplayServer.set_icon()` 设置任务栏/窗口图标，托盘继续使用 `.ico`。`verify_v04.gd` 新增 Display 状态标签宽度、显式中文字体、运行图标和非画布缩放门禁；`verify_v04.ps1`、`verify_v03.ps1`、`verify_v02.ps1` 和 `verify_m4.ps1` 均已通过。
- **2026-07-05**: 根据“不是做大就好，要小而美、清晰、精致”的反馈继续收紧 UI polish：右键小猫菜单从默认 `PopupMenu` 视觉改为统一自定义 Theme，主菜单和二级菜单共用中文系统字体、LCD antialias、15px 字号、30px 行高、6px 圆角、轻边框和轻阴影，并开启透明 popup 背景以避免圆角黑边；设置窗口左上返回和右上关闭按钮从通用填充按钮拆为紧凑工具按钮，尺寸收敛到 `38x38`，常态透明、hover 轻底色，关闭按钮 hover 使用克制红色反馈。`doc/verification/v0.4.md` 新增 V04-MAN-154 和 V04-MAN-165 复测项，`verify_v04.gd` 增加菜单主题、LCD 字体、紧凑行高、圆角和窗口工具按钮门禁。

---

- **2026-07-05**: 按“温暖桌面小挂件 / 橘猫金币小票便签风”完成 UI 第一阶段修正：Panel 从黑色玻璃风改为奶油纸面、小金币计数器和小票式展开面板；右键菜单改为同一套奶油纸面、深咖啡文字、金币 hover 和二级菜单样式。同步深查清晰度根因，发现项目全局 `window/stretch/mode="canvas_items"` 会在运行时手动调整小窗尺寸时触发画布级缩放，导致 2K 屏幕下文字和菜单像被贴图拉伸；现改为 `window/stretch/mode="disabled"`，Panel 保持真实字号/尺寸重排，纸面透明度提升到接近不透明以避免复杂桌面内容透入。已重新导出 `build\LetsMakeMoney.exe`，本地截图验证保存到 `<PRIVATE_EVIDENCE>\ui-warm-widget-final\`，并通过 `verify_v04.ps1`、`verify_m4.ps1` 和 `git diff --check`。

## 下一步计划

**v0.4 Beta 启动顺序**：
1. V04-M0 原型与体验规格已完成，默认温暖陪伴方向、Panel、设置、托盘找回和发布包说明已进入原型与 prototype spec。
2. V04-M1 动画规格、当前素材基线记录、v2 目录骨架、提示词执行集、asset manifest、cutout 工程候选帧和 Godot 资源构建已完成；cutout 批次已被人工拒绝为最终美术候选，第二批 imagegen concept 候选经人工迭代后已作为 v0.4 beta 默认资源接入。剩余开放项是 ComfyUI 最小候选验证，可作为长期素材产能 Spike 继续推进，不阻塞当前默认 v2。
3. V04-M2 交互手感首轮完成，并已根据 Part 5 “全部无效”反馈修复 v2 小猫交互命中框与原生穿透白名单不匹配问题；下一步需要人工复测 V04-MAN-040 至 V04-MAN-045，确认单击、双击、长按、拖拽和右键菜单在真实桌面窗口中恢复可用。
4. V04-M3 已完成点击穿透调试视图、命中区日志、modal/popup 安全清空、首批刷新节流验证、Panel 边缘定位和桌宠窗口可找回兜底；下一步继续做多缩放表现与最终文档联动。
5. V04-M4 设置页信息架构、保存差异检测、恢复默认确认和 Debug 配置路径说明首轮完成；剩余 salary/schedule 刷新分流与单窗口观感留待后续手动/导出复测确认。
6. V04-M5 日志分层、自动验证覆盖、no-op native 缓存、发布包脚本、checksum 校验、发布包烟测和 60 秒 release 稳定性烟测完成，CHANGELOG 已同步；下一步进入多缩放人工验证、真实桌面长时间体验复测和最终发布确认。
7. V04-M6 UI polish 已纳入正式范围；PRD / implementation-plan / prototype-spec / progress 的 UI polish 文档链路已对齐，Godot Panel 折叠态“金额 + 短状态”已开始落地，下一步继续实现展开态信息层级、Win11 风格设置窗口、右键二级菜单和托盘/窗口图标优化。
