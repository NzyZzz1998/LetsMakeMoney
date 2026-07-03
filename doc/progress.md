# LetsMakeMoney 赚钱模拟器 — 总体进度

> 本文档作为整个项目的总体进度跟踪，按版本和模块组织 Vibe Coding 最小可执行任务。每个模块对应一组 checklist，完成时勾选。完整实施细节参见 `implementation-plan.md`，需求细节参见 `LetsMakeMoneyPRD.md`。

**最后更新**: 2026-07-03
**当前阶段**: v0.3 Beta 已完成导出 exe 手动验证与 Codex 辅助复测，进入 `v0.3beta` 发布状态；v0.4 Beta 已建立大型体验优化规划
**当前里程碑**: Windows native bridge 已可通过 MSYS2 UCRT64 构建，真托盘、透明窗口、点击穿透、右键菜单、关闭隐藏到托盘、设置入口、导出烟测和手动复测均已通过；v0.4 下一步从橘猫动画规格与体验优化启动

---

## 版本总览

| 版本 | 阶段 | 平台 | 状态 |
|------|------|------|------|
| v0.1 | Beta | Windows | ✅ Beta 调试窗口版已打包归档 |
| v0.2 | Beta | Windows | 🧪 稳定候选；核心交互/设置/自启/素材/验证已完成，真实托盘与透明穿透暂缓 |
| v0.3 | Beta | Windows x86_64 | ✅ 已完成 native bridge、真托盘控制器、透明窗口控制器、点击穿透区域模型、右键菜单修复、纯桌宠门禁、设置修正、构建脚本、导出烟测和手动验证复测；发布 tag 为 `v0.3beta` |
| v0.4 | Beta | Windows x86_64 | 🧭 规划草案；大型体验优化版本，聚焦橘猫动画、交互手感、窗口/点击穿透、Panel、设置体验、性能和发布包 |
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

- **动画是主线之一**：橘猫动画需要从“能显示”升级为“状态可感知、动作自然、帧间稳定”。
- **交互手感是主线之一**：单击、双击、长按、拖拽、右键菜单要形成清晰优先级，不能靠偶然命中。
- **窗口体验仍需继续打磨**：v0.3 已实现点击穿透和透明窗口，v0.4 需要加入可观测调试能力，校准边界场景。
- **设置体验需要从工程可用升级到用户可理解**：保存状态、禁用原因、恢复默认、纯桌宠模式说明都要更清楚。
- **发布体验要规范化**：native DLL、exe、版本号、验证脚本、手动验证和 release notes 需要形成稳定流程。

### v0.4 总体进度概览

| 里程碑 | 模块 | 状态 | 完成度 |
|--------|------|------|--------|
| **V04-M1** | 橘猫动画与素材管线 | 🗓 规划中 | 0/18 |
| **V04-M2** | 交互手感优化 | 🗓 规划中 | 0/10 |
| **V04-M3** | 窗口、点击穿透与 Panel 打磨 | 🗓 规划中 | 0/10 |
| **V04-M4** | 设置体验与保存反馈 | 🗓 规划中 | 0/10 |
| **V04-M5** | 性能、稳定性与发布包 | 🗓 规划中 | 0/10 |
| **V04-DOC** | v0.4 验证文档与发布记录 | 🗓 规划中 | 0/6 |

**v0.4 总进度**: 0/64（规划草案已建立，尚未进入实现）。

### v0.4 V04-M1. 橘猫动画与素材管线

#### 模块 V04-M1.1: 动画素材规格

- [ ] V04-M1.1.1 定义统一画布尺寸、透明边界、角色锚点、脚底基线和视觉中心
- [ ] V04-M1.1.2 定义基础状态 `idle` / `working` / `resting`
- [ ] V04-M1.1.3 定义交互叠加状态 `clicked_single` / `clicked_double` / `clicked_hold`
- [ ] V04-M1.1.4 定义每个动画的帧数、FPS、循环/单次播放规则和恢复规则
- [ ] V04-M1.1.5 建立素材命名规则和素材来源记录格式
- [ ] V04-M1.1.6 建立动画验收标准：不裁切、不漂移、不闪烁、尺寸一致、透明边界干净

#### 模块 V04-M1.2: 橘猫 v2 动画素材接入

- [ ] V04-M1.2.1 生成或筛选 idle 动画
- [ ] V04-M1.2.2 生成或筛选 working 动画
- [ ] V04-M1.2.3 生成或筛选 resting 动画
- [ ] V04-M1.2.4 生成或筛选 clicked_hold 动画
- [ ] V04-M1.2.5 生成或筛选 clicked_single / clicked_double 短反馈动画
- [ ] V04-M1.2.6 接入 SpriteFrames 并保留旧素材可回退

#### 模块 V04-M1.3: 动画验证

- [ ] V04-M1.3.1 新增 v0.4 动画自动验证脚本
- [ ] V04-M1.3.2 自动检查动画名称、帧数、FPS 和 loop 配置
- [ ] V04-M1.3.3 手动验证文档增加动画预览和状态切换项
- [ ] V04-M1.3.4 记录素材工具、输入提示词、筛选结论和接入成本

### v0.4 V04-M2. 交互手感优化

- [ ] V04-M2.1.1 梳理 hover、单击、双击、长按、拖拽、右键菜单优先级
- [ ] V04-M2.1.2 拖拽阈值触发后不进入 clicked_hold
- [ ] V04-M2.1.3 双击识别不被两次单击反馈提前吞掉
- [ ] V04-M2.1.4 右键菜单弹出不触发左键交互状态
- [ ] V04-M2.1.5 交互结束后恢复进入交互前的基础状态
- [ ] V04-M2.2.1 单击反馈短促明确
- [ ] V04-M2.2.2 双击反馈更明显
- [ ] V04-M2.2.3 长按反馈稳定出现并可自然恢复
- [ ] V04-M2.2.4 拖拽开始和结束不造成动画卡死
- [ ] V04-M2.2.5 Panel hover 展开与小猫 hover 不互相抢状态

### v0.4 V04-M3. 窗口、点击穿透与 Panel 打磨

- [ ] V04-M3.1.1 Debug 模式增加交互矩形可视化或详细日志
- [ ] V04-M3.1.2 日志输出小猫核心区、右键上下文区、Panel 折叠区、Panel 展开区
- [ ] V04-M3.1.3 缩放变化后交互矩形同步刷新
- [ ] V04-M3.1.4 Panel 展开/收起后交互矩形同步刷新
- [ ] V04-M3.1.5 设置/向导打开时穿透区域清空，关闭后恢复
- [ ] V04-M3.2.1 优化窗口靠右时 Panel 左侧展开阈值
- [ ] V04-M3.2.2 优化窗口靠底时 Panel 上方展开阈值
- [ ] V04-M3.2.3 验证 50%-200% 缩放下小猫不裁切
- [ ] V04-M3.2.4 验证不同缩放下 Panel 文字不溢出
- [ ] V04-M3.2.5 验证不同缩放下点击穿透区域接近视觉区域

### v0.4 V04-M4. 设置体验与保存反馈

- [ ] V04-M4.1.1 保留 Salary / Pet / Display / Panel / General 大类并优化内容布局
- [ ] V04-M4.1.2 Display 页解释透明度、窗口模式、纯桌宠模式、点击穿透关系
- [ ] V04-M4.1.3 General 页解释开机自启、关闭隐藏到托盘、Debug 模式和恢复默认
- [ ] V04-M4.1.4 平台不可用能力显示禁用原因
- [ ] V04-M4.1.5 设置窗口不再出现窗口套窗口的观感
- [ ] V04-M4.2.1 保存前对比配置差异，避免重复写入
- [ ] V04-M4.2.2 自启动注册表只在状态变化时写入或删除
- [ ] V04-M4.2.3 native 能力只在相关配置变化时重新应用
- [ ] V04-M4.2.4 保存成功后显示轻量状态提示
- [ ] V04-M4.2.5 保存失败时显示可读错误并保留用户输入

### v0.4 V04-M5. 性能、稳定性与发布包

- [ ] V04-M5.1.1 减少高频日志，只保留错误和关键状态变化
- [ ] V04-M5.1.2 限制 native region 更新频率，避免无变化重复调用
- [ ] V04-M5.1.3 确认 Panel 刷新仍按节流执行
- [ ] V04-M5.1.4 长时间运行后托盘、穿透、窗口位置和设置保存仍正常
- [ ] V04-M5.2.1 v0.4 发布前继续运行 v0.2/v0.3 回归验证
- [ ] V04-M5.2.2 新增 v0.4 动画、交互、窗口、设置体验验证脚本
- [ ] V04-M5.2.3 发布包清单明确 exe、native dll、版本号和配置路径
- [ ] V04-M5.2.4 Release Notes 说明 v0.4 体验变化、已知限制和升级建议
- [ ] V04-M5.2.5 手动验证文档保留可标注结果和备注列

### v0.4 资源准备清单

| 资源 | 路径 | 负责模块 | 状态 |
|------|------|---------|------|
| v0.4 动画规格 | `doc/v0.4-animation-spec.md` | V04-M1.1 | 🗓 待创建 |
| 橘猫 v2 素材 | `assets/pets/cat/orange_v2/` | V04-M1.2 | 🗓 待准备 |
| v0.4 自动验证 | `scripts/verify_v04.ps1` / `scripts/verify_v04.gd` | V04-M1/V04-M5 | 🗓 待创建 |
| v0.4 验证文档 | `doc/verification/v0.4.md` | V04-DOC | 🗓 待创建 |
| v0.4 发布说明 | `releases/v0.4-beta-notes.md` | V04-DOC | 🗓 待创建 |

### v0.4 已知风险（降级方案）

| 风险 | 降级方案 |
|------|---------|
| 新动画素材质量不稳定 | 保留 v0.3 橘猫素材可回退，不让素材质量阻塞已有功能 |
| 动画接入导致状态机回退 | 保持基础状态 + 交互叠加状态模型，新增自动验证覆盖状态恢复 |
| 点击穿透调优破坏右键菜单 | 保留右键专用上下文区域并增加调试视图，按场景逐项验证 |
| 设置体验重构引入保存回归 | 保存逻辑先加差异对比和测试，再调整 UI 布局 |
| 发布包遗漏 native DLL | 继续用导出验证脚本阻塞发布，并在 release notes 列出分发文件 |

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

---

## 下一步计划

**v0.4 Beta 启动顺序**：
1. 先做橘猫动画规格和素材验收文档，避免直接把新素材接进主场景导致状态机回归。
2. 再做交互优先级和点击穿透调试视图，让后续窗口/Panel 优化有可观测依据。
3. 最后进入设置体验、保存反馈、发布包清单和 v0.4 手动验证文档。
