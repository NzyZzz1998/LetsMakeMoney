# LetsMakeMoney 赚钱模拟器 — 总体进度

> 本文档作为整个项目的总体进度跟踪，按版本和模块组织 Vibe Coding 最小可执行任务。每个模块对应一组 checklist，完成时勾选。完整实施细节参见 `implementation-plan.md`，需求细节参见 `LetsMakeMoneyPRD.md`。

**最后更新**: 2026-07-01
**当前阶段**: v0.2 Beta 稳定候选整理中
**当前里程碑**: V02-DOC 文档与用户可见文案整理；下一步为 v0.2 最终手动复测与 GitHub 提交

---

## 版本总览

| 版本 | 阶段 | 平台 | 状态 |
|------|------|------|------|
| v0.1 | Beta | Windows | ✅ Beta 调试窗口版已打包归档 |
| v0.2 | Beta | Windows | 🧪 稳定候选；核心交互/设置/自启/素材/验证已完成，真实托盘与透明穿透暂缓 |
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
- **验证路径明确**：新增 `verify_v02.ps1` / `verify_v02.gd`、`doc/v0.2-manual-verification.md`，并保留 M3/M4/M5 回归验证。

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

- [x] V02-M5.2.1 新增 `doc/v0.2-manual-verification.md`，覆盖桌宠模式、Debug 模式和交互验证
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
| v0.2 手动验证文档 | `doc/v0.2-manual-verification.md` | V02-M5.2 | ✅ 已创建并改为可填写表格 |
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

## 下一步计划

**v0.2 Beta 收尾顺序**：
1. 继续清理 implementation-plan 历史段落中残留的编码乱码，但保留原详细任务颗粒度
2. 用户按 `doc/v0.2-manual-verification.md` 对最新导出 exe 做最终手动复测
3. 若复测无新问题，提交并推送 GitHub
4. 为 v0.2 Beta 打 tag 或整理 release notes

**v0.3 技术预研顺序**：
1. 调研真实系统托盘替代方案：外部 helper、GDExtension、Win32 桥接或其他 Godot 插件
2. 在隔离分支验证透明窗口和鼠标穿透，不直接影响 v0.2 稳定候选
3. 恢复关闭隐藏到托盘验收
4. 继续打磨橘猫正式动画素材
