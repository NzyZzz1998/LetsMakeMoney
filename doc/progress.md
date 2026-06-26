# LetsMakeMoney 赚钱模拟器 — 总体进度

> 本文档作为整个项目的总体进度跟踪，按版本和模块组织 Vibe Coding 最小可执行任务。每个模块对应一组 checklist，完成时勾选。完整实施细节参见 `implementation-plan.md`，需求细节参见 `LetsMakeMoneyPRD.md`。

**最后更新**: 2026-06-26
**当前阶段**: v0.1 Beta 开发期  
**当前里程碑**: M3 自动验证通过，待手动交互验证

---

## 版本总览

| 版本 | 阶段 | 平台 | 状态 |
|------|------|------|------|
| v0.1 | Beta | Windows | ⏳ 开发中（M1+M2 完成） |
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
| **M3** | PanelSystem | 🧪 自动验证通过，待手动验证 | 5/5 |
| **M3** | Panel 场景 | 🧪 自动验证通过，待手动验证 | 6/6 |
| **M3** | DragResizeSystem | 🧪 自动验证通过，待手动验证 | 5/5 |
| **M3** | Main 场景整合 | 🧪 自动验证通过，待手动验证 | 6/6 |
| **M4** | 设置对话框 | ⏳ 未开始 | 0/7 |
| **M4** | 首次启动向导 | ⏳ 未开始 | 0/6 |
| **M5** | 打包发布 | ⏳ 未开始 | 0/3 |

**v0.1 总进度**: 59/75 任务代码完成（79%），M1 + M2 完成，M3 自动验证通过、待手动交互验证

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

- [ ] 4.1.1 在编辑器中创建 `src/scenes/settings/settings_dialog.tscn`（ConfirmationDialog + TabContainer 5 标签页，含取消按钮）
- [ ] 4.1.2 搭建 Salary 标签页 UI（月薪 SpinBox / 休息模式 OptionButton / 时数 / 上下班时间 HBox）
- [ ] 4.1.3 搭建 Pet 标签页 UI（角色 ItemList + 缩放 HSlider 50-200）
- [ ] 4.1.4 搭建 Display 标签页 UI（透明度 HSlider 20-100 + 窗口模式 OptionButton）
- [ ] 4.1.5 搭建 Panel 标签页 UI（5 个 CheckBox 控制展开项可见性）
- [ ] 4.1.6 搭建 General 标签页 UI（开机自启 disabled CheckBox + 语言 OptionButton）
- [ ] 4.1.7 编写 `settings_dialog.gd`，实现 `_load_current_values()` / 确认保存 / 取消放弃，保存后触发 Config.config_changed 信号

#### 模块 4.2: 首次启动向导

- [ ] 4.2.1 在编辑器中创建 `src/scenes/wizard/wizard_dialog.tscn`（ConfirmationDialog + 4 个 Control 页 + NavBar）
- [ ] 4.2.2 搭建 Step 1 欢迎页（标题 + 副标题 + 大尺寸角色 IDLE 预览）
- [ ] 4.2.3 搭建 Step 2 薪资页（复用设置对话框薪资页结构）
- [ ] 4.2.4 搭建 Step 3 选角色页（ItemList + 选中实时调用 PetManager.switch_pet 预览）
- [ ] 4.2.5 搭建 Step 4 完成页（SummaryLabel 摘要 + "开始赚钱！"按钮）
- [ ] 4.2.6 编写 `wizard_dialog.gd`，实现步骤切换 / 上一步 / 下一步 / `_finish()` 保存并通过 `finished` 信号通知 main.gd reload

### v0.1 M5. 打包发布

#### 模块 5.1: Windows 打包

- [ ] 5.1.1 配置 Godot 导出预设（Windows Desktop，设置图标和描述）
- [ ] 5.1.2 下载安装 Windows 导出模板
- [ ] 5.1.3 导出 exe 到 `<PROJECT_ROOT>\build\LetsMakeMoney.exe`，双击运行验证全流程

---

## v0.1 资源准备清单（并行进行）

| 资源 | 路径 | 负责模块 | 状态 |
|------|------|---------|------|
| 小猫 sprite sheet | `assets/pets/cat/raw/` | 2.3 | ⚠ 待下载 |
| 小猫 SpriteFrames | `assets/pets/cat/cat_sprite_frames.tres` | 2.3 | ⚠ 待创建 |
| 小猫 PetResource | `assets/pets/cat/cat_resource.tres` | 1.4 | ⚠ 待创建 |
| 小狗 SpriteFrames | `assets/pets/dog/dog_sprite_frames.tres` | 2.3 | ⚠ v0.1 延后 |
| 仓鼠 SpriteFrames | `assets/pets/hamster/hamster_sprite_frames.tres` | 2.3 | ⚠ v0.1 延后 |
| 应用图标 | `icons/app_icon.ico` | 5.1 | ⚠ 待创建 |

---

## v0.1 已知风险（降级方案）

| 风险 | 降级方案 |
|------|---------|
| Godot 无原生系统托盘 | v0.1 用窗口隐藏 + 右键 PopupMenu 代替，标注为临时方案 |
| "融入桌面"模式需 Windows Progman 父窗口技巧，复杂且不稳定 | v0.1 默认置顶，"融入桌面"选项保留但实现为普通非置顶窗口（不真实嵌入桌面层） |
| WORKING（敲键盘）和 HOVER 动画素材无现成开源包 | v0.1 用兔子素材的 walk_side 代替 working，idle 第 1 帧代替 hover |
| AI 生成 sprite 动画素材效果不理想（见下方困难记录） | v0.1 继续用兔子占位素材推进，v1.0 再解决 |

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
- **2026-06-26**: 新增 `scripts/verify_m3.ps1` 和 `doc/m3-verification.md`；Godot 4.7 headless 项目加载与主场景 30 帧 smoke test 通过
- **2026-06-26**: 修复 M3 手动验证问题——设置桌宠窗口实际尺寸，Pet 输入增加鼠标位置命中兜底，右键菜单改用窗口内坐标
- **2026-06-26**: 通过 Windows 窗口截图确认运行窗口内容过小且面板跑出可见区；放大占位角色、固定 Pet/Panel 到窗口内布局，并为拖拽增加左键 mask 兜底与 `drag started` 日志
- **2026-06-26**: 调试阶段临时放大窗口到 720×360，拉开 Pet/Panel 位置，便于观察薪资数字和交互状态
- **2026-06-26**: 调试阶段临时关闭透明背景并增加可见 DebugInputArea，避免 Windows 透明窗口按像素命中导致点击事件不稳定
- **2026-06-26**: 确认普通窗口模式下输入链路可用：左键单击、右键菜单、窗口拖拽保存均通过；后续再逐步恢复无边框/透明/置顶桌宠模式
- **2026-06-26**: 修复调试交互问题——双击改为 0.3s 点击窗口判定，拖拽改用屏幕绝对鼠标差值避免速度过快，折叠金额栏去掉重复人民币符号

## 下一步计划

**手动验证 M3 UI 与交互**：
1. 用 Godot 4.7 打开项目并运行主场景
2. 按 `doc/m3-verification.md` 验证 Pet/Panel 可见、面板悬停展开/离开收起
3. 验证拖拽保存窗口位置、右键菜单可打开
4. 修复手动交互问题后进入 M4 设置与首次启动向导
