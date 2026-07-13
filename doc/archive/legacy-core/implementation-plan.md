# LetsMakeMoney 实施计划

> **当前 v0.4 快速入口**: 本文件是跨版本原始实施计划。v0.4 已拆分到 `doc/releases/v0.4/implementation-plan.md`，接手时请先读 `doc/current.md` 和 `doc/releases/v0.4/README.md`。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 以当前 v0.4 Beta 测试态为主线推进 LetsMakeMoney Windows 桌面宠物应用。v0.1-v0.3 保留为历史实施记录；当前实现重点是橘猫 v2、真实桌宠窗口、Panel 暖色便签、右键菜单/托盘、紧凑 Settings、Wizard、Debug 验证和发布包质量。

**Architecture:** 采用 Godot Autoload 单例模式。6 个全局模块协作：`Platform`（平台抽象工厂）→ `Config`（持久化）→ `SalaryEngine`（计算）→ `PetManager`（状态机中枢，唯一驱动动画）+ `PanelSystem`（面板交互）+ `DragResizeSystem`（拖拽与右键菜单）。v0.3 在 `PlatformInterface` 下新增 Windows native bridge，Godot 侧只调用平台抽象，Win32 托盘、透明窗口、点击穿透和任务栏/Alt+Tab 控制集中在 GDExtension / 原生插件内。

**Tech Stack:** Godot 4.7 / GDScript / GDExtension / C++ / Win32 API / Windows x86_64 / PowerShell 验证脚本 / MSYS2 UCRT64

**项目路径:** `<PROJECT_ROOT>\`

---

## 当前实施口径（2026-07-08）

从本轮开始，原型任务不再维护“v0.1-v0.4 分版本切屏”。当前唯一交互原型入口为 `doc/prototypes/index.html`，结构按真实功能模块组织：

- 总览
- 桌宠主界面
- Panel 便签
- 右键菜单与托盘
- 设置面板
- 首次启动向导
- Debug 与验证
- 发布包

### 当前已完成的文档/原型同步任务

- [x] 重置 `doc/prototypes/index.html` 为当前状态单一交互原型。
- [x] 重写 `doc/prototypes/prototype-spec.md`，说明当前原型范围、交互和验收口径。
- [x] 重写 `doc/v0.4-ui-polish-spec.md`，将 UI 方向统一为温暖桌面小挂件 / 橘猫金币小票便签风。
- [x] 在 PRD 中补充当前文档同步说明，明确历史版本仅作背景。

### 当前后续实施重点

- [ ] 继续让 Godot Settings 实现贴近新版紧凑偏好设置原型。
- [ ] 继续核对 Panel、右键菜单、托盘图标与新版原型的一致性。
- [ ] 用 `doc/verification/v0.4.md` 重新跑一轮人工验证。
- [ ] 在验证通过后再决定是否合并 `test` 到 `main` 或创建正式 tag。

---

## 0. 通用项目结构与架构约束

### 0.0 实际开发状态基线（2026-07-01）

本实施计划包含两类内容：

- **v0.1 Beta**：历史实施计划 + 当前实际完成状态。v0.1 已打包，但真实形态是“普通调试窗口版产品雏形”，不是完整透明桌宠版。
- **v0.2 Beta**：实施中并进入稳定候选。V02-M1、V02-M2 核心交互、V02-M4 设置与开机自启、V02-M5 验证导出、V02-S1 橘猫素材接入已完成；V02-M3 真系统托盘与 V02-M2 透明穿透因 Godot 4.7 Windows 原生访问违例暂缓。
- **v0.3 Beta**：已完成实现、导出验证和手动复测，定位为桌宠原生能力修复版。v0.3 不继续扩大业务功能，优先通过 GDExtension / Windows 原生插件把 v0.2 暂缓的系统托盘、透明无边框、点击穿透、关闭隐藏到托盘和纯桌宠模式恢复为可导出 exe 的正式能力。
- **v0.4 Beta**：规划草案，定位为大型体验优化版。v0.4 不重写底层路线，基于 v0.3 native bridge 继续优化橘猫动画、交互反馈、Panel 和窗口细节、设置体验、性能稳定性和发布包质量。

当前代码事实：

| 模块 | 当前状态 | 与早期预期不一致之处 |
|------|----------|----------------------|
| Config | 已实现默认值、配置读写、深合并、panel_items、v0.2 新字段、显示默认恢复 | `system_tray_enabled`、`transparent_pet_window_enabled`、`mouse_passthrough_enabled` 默认关闭，用于隔离原生崩溃风险 |
| WindowsPlatform | 已封装配置路径、窗口设置、置顶/嵌入降级、鼠标穿透接口、自启动注册表接口 | 透明窗口和穿透接口保留但默认不启用；真系统托盘路线暂缓 |
| Main | 已整合 Pet、Panel、设置/向导、DebugInputArea、DebugStatus、运行模式重应用 | `debug_mode=true/false` 可切换；设置弹窗关闭后延迟重应用窗口尺寸，避免被弹窗最小尺寸卡住 |
| Pet / Drag | 已支持单击、双击、长按、拖拽、右键菜单、窗口显隐辅助、重置位置 | 拖拽已改用屏幕绝对位移；长按作为交互叠加状态，不再替代基础状态 |
| Panel | 已支持折叠/展开、配置项隐藏、金额居中、边缘定位、中文文案清理 | 折叠态金额垂直居中；金额和小时文案使用正常中文与 `¥` |
| Settings | 已支持薪资、休息模式、时间、缩放、透明度、窗口模式、Panel 项、Debug、自启、关闭隐藏到托盘、重置位置、恢复默认 | 保存时比较自启期望/实际状态，避免未修改自启时重复调用注册表导致卡顿 |
| Wizard | 已支持首次启动和重新运行向导 | 已延后一帧弹出，避免主窗口未稳定时弹窗 |
| Tray | 接口和菜单文案已保留，真实系统托盘默认关闭 | Godot `StatusIndicator` 存在访问违例风险，转入 v0.3 替代方案调研 |
| Build | 已有 export preset、app icon、`verify_v02.ps1/gd`，exe 已重新导出 | `build/LetsMakeMoney.exe` 不入库；当前导出时间见 progress |

继续执行 v0.2 或进入 v0.3 前必须接受以上基线：当前稳定候选优先保证导出 exe 不崩溃，真系统托盘、透明无边框和空白点击穿透不再作为 v0.2 硬阻塞。

### 0.0.1 v0.2 当前实施状态补充（2026-07-01）

> 本节是 2026-07-01 的执行后状态覆盖层。后文 v0.1 与 v0.2 的详细任务计划仍保留，用于追溯原始设计和最小任务拆分；若后文个别旧任务仍写“待实现”或“必须完成”，以本节和 `doc/progress.md` 的当前状态为准。

| 里程碑 | 原始目标 | 当前状态 | 结果说明 |
|--------|----------|----------|----------|
| V02-M1 | Config 兼容、`debug_mode`、桌宠/Debug 模式拆分 | 已完成 | 新增 v0.2 配置字段；旧配置可合并默认值；普通模式为紧凑桌宠窗口，Debug 模式为 900×500 调试窗口 |
| V02-M2 | 透明窗口、输入穿透、角色区域交互 | 部分完成 | 小猫交互、拖拽、双击、长按、橘猫展示已完成；透明无边框和点击穿透因原生崩溃暂缓 |
| V02-M3 | 系统托盘、托盘菜单、关闭隐藏到托盘 | 接口完成，真实托盘暂缓 | `Platform` 信号、托盘菜单文案、窗口显隐辅助保留；Godot `StatusIndicator` 路线不稳定 |
| V02-M4 | 开机自启、设置通用项、重置位置、恢复默认 | 已完成 | 注册表自启动、设置项、保存性能优化、中文文案清理已完成 |
| V02-M5 | 自动验证、手动验证、导出 exe | 已完成当前轮 | `verify_v02.ps1/gd`、手动验证文档、导出 exe 均可用 |
| V02-S1 | 素材 Spike | 已完成当前接入 | 橘猫素材已合并接入；动画状态模型改为基础状态 + 交互叠加状态 |
| V02-DOC | 文档与用户可见文案整理 | 进行中 | 目标是保留详细颗粒度，更新实际状态，清理用户可见乱码；不是缩写文档 |

#### V02-M1 当前完成清单

- [x] `Config` 默认值新增 `debug_mode=false`。
- [x] `Config` 默认值新增 `auto_start=false`。
- [x] `Config` 默认值新增 `minimize_to_tray=true`。
- [x] `Config` 默认值新增 `system_tray_enabled=false`，用于关闭不稳定的真实托盘路径。
- [x] `Config` 默认值新增 `transparent_pet_window_enabled=false`，用于关闭不稳定透明窗口路径。
- [x] `Config` 默认值新增 `mouse_passthrough_enabled=false`，用于关闭不稳定点击穿透路径。
- [x] 旧配置缺字段时按默认值运行。
- [x] 主场景根据 `debug_mode` 切换普通桌宠窗口和 Debug 窗口。
- [x] 修复从 `debug_mode=true` 改回 `false` 后仍保持大窗口的问题。

#### V02-M2 当前完成清单

- [x] 紧凑桌宠窗口尺寸调整为能容纳橘猫和展开 Panel。
- [x] 小猫 hover 可用。
- [x] 小猫单击可用。
- [x] 小猫双击可用。
- [x] 小猫长按可用，松开后恢复基础状态。
- [x] 拖拽使用屏幕绝对鼠标位移，不再出现窗口移动速度远大于鼠标的问题。
- [x] 拖拽后保存窗口位置，重启恢复。
- [x] 橘猫素材在窗口内完整展示。
- [x] Panel 折叠态金额垂直居中。
- [x] Panel 金额不再出现两个人民币符号。
- [x] Panel 用户可见文案无乱码。
- [ ] 透明无边框窗口默认启用：暂缓到 v0.3。
- [ ] 空白区域点击穿透默认启用：暂缓到 v0.3。

#### V02-M3 当前完成清单

- [x] `PlatformInterface` / `Platform` 保留托盘相关接口。
- [x] `Platform` 保留 `tray_toggle_requested`、`tray_settings_requested`、`tray_about_requested`、`tray_exit_requested` 信号。
- [x] `DragResizeSystem` 提供窗口显示/隐藏辅助。
- [x] 右键菜单与托盘菜单文案已清理为正常中文。
- [x] 角色右键菜单退出路径保存配置并退出。
- [ ] 真系统托盘图标：暂缓到 v0.3。
- [ ] 关闭按钮隐藏到托盘：真实托盘恢复前暂缓。

#### V02-M4 当前完成清单

- [x] `PlatformInterface` / `WindowsPlatform` 增加 `get_executable_path()`、`is_auto_start_enabled()`、`set_auto_start()`。
- [x] Windows 自启动使用 `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`，键名 `LetsMakeMoney`。
- [x] 自启动开启时写入导出 exe 路径。
- [x] 自启动关闭时删除注册表项。
- [x] 缺少注册表项时关闭自启动视为成功。
- [x] 设置页新增 `Debug 模式`。
- [x] 设置页新增 `开机自启`。
- [x] 设置页新增 `关闭时隐藏到托盘`。
- [x] 设置页新增 `重置窗口位置`。
- [x] 设置页新增 `恢复默认显示设置`。
- [x] 缩放和透明度显示当前百分比。
- [x] 保存设置时仅在自启动状态变化时调用平台注册表操作，避免无意义卡顿。
- [x] 设置页用户可见中文文案已清理。

#### V02-M5 当前完成清单

- [x] 新增 `scripts/verify_v02.ps1`。
- [x] 新增 `scripts/verify_v02.gd`。
- [x] 自动验证覆盖 v0.2 配置默认值和旧配置兼容。
- [x] 自动验证覆盖主场景关键节点和窗口尺寸常量。
- [x] 自动验证覆盖平台接口。
- [x] 自动验证覆盖设置保存自启动性能模型。
- [x] 自动验证覆盖用户可见中文乱码扫描。
- [x] 新增并更新 `doc/verification/v0.2.md`。
- [x] 重新导出 `build\LetsMakeMoney.exe`。

#### V02-S1 当前完成清单

- [x] 合并临时素材分支中的橘猫素材。
- [x] 接入 `cat_orange_v1` 资源。
- [x] 调整动画状态模型：基础状态为 idle / working / resting。
- [x] 单击、双击、长按作为基础状态上的交互叠加表现。
- [x] 新增橘猫素材验证脚本。
- [ ] 更自然的正式动画帧继续作为后续打磨项。

### 0.0.2 v0.3 计划基线（2026-07-01）

> 本节是 v0.3 实施计划的执行前基线。后文 `## 3. v0.3 Beta 实施计划` 是正式任务拆分；本节只记录进入 v0.3 时必须遵守的全局约束。

| 维度 | v0.3 决策 | 实施约束 |
|------|-----------|----------|
| 版本定位 | 桌宠原生能力修复版 | 不把动画打磨、多角色、统计、云同步等功能塞入 v0.3 |
| 原生路线 | GDExtension / 原生插件优先 | 不以外部 helper 进程作为主路线；不以切换 Godot 版本作为主策略 |
| 平台范围 | Windows x86_64 必须完成 | macOS / Linux 只保留接口和降级，不实现原生能力 |
| 发布形态 | 插件随 exe 一起发布 | 用户不能额外安装或手动复制插件文件 |
| 托盘策略 | 真系统托盘是纯桌宠模式前提 | 托盘健康检查失败时禁止隐藏任务栏 / Alt+Tab，关闭按钮不得隐藏到不可找回状态 |
| 窗口策略 | 恢复透明无边框桌宠窗口 | 原生初始化失败时回退 v0.2 紧凑普通窗口 |
| 穿透策略 | 空白区域尽量点击穿透 | 小猫、Panel、菜单、设置窗口必须保持可交互 |
| 设置策略 | 模式类控件改成明确选择控件 | 休息模式、窗口模式不再用含糊的 CheckButton 表达 |
| 文档策略 | v0.1 / v0.2 / v0.3 平级维护 | 清理编码问题但不压缩历史详细内容 |

#### v0.3 当前待完成清单

- [ ] V03-M1：建立 Windows GDExtension / native bridge 骨架和健康检查。
- [ ] V03-M2：实现真系统托盘、托盘菜单、显示/隐藏、设置、关于、退出。
- [ ] V03-M3：实现透明无边框桌宠窗口与原生失败降级。
- [ ] V03-M4：实现透明空白区域点击穿透和交互区域刷新。
- [ ] V03-M5：实现关闭隐藏到托盘与可找回优先的纯桌宠模式。
- [ ] V03-M6：优化设置控件、原生能力状态提示和配置迁移。
- [ ] V03-M7：新增自动验证、手动验证、release notes / changelog、导出检查。
- [ ] V03-DOC：清理 `implementation-plan` / `progress.md` 历史编码问题，保持详细颗粒度。

### 0.1 项目文件结构

```
LetsMakeMoney/
├── project.godot                     # Godot 项目配置 + Autoload 定义
├── .gitignore                        # 忽略 .godot/ build/ 等
├── assets/
│   └── pets/
│       └── cat/
│           ├── raw/                  # 原始下载素材
│           ├── cat_sprite_frames.tres
│           └── cat_resource.tres
├── src/
│   ├── autoload/
│   │   ├── platform.gd               # 平台抽象工厂（Autoload: Platform）
│   │   ├── config.gd                 # 配置读写（Autoload: Config）
│   │   ├── salary_engine.gd          # 薪资计算引擎（Autoload: SalaryEngine）
│   │   ├── pet_manager.gd            # 角色状态机中枢（Autoload: PetManager）
│   │   ├── panel_system.gd           # 面板悬停控制（Autoload: PanelSystem）
│   │   └── drag_resize_system.gd     # 拖拽与右键菜单（Autoload: DragResizeSystem）
│   ├── scenes/
│   │   ├── main/
│   │   │   ├── main.tscn
│   │   │   └── main.gd
│   │   ├── pet/
│   │   │   ├── pet.tscn
│   │   │   └── pet.gd
│   │   ├── panel/
│   │   │   ├── panel.tscn
│   │   │   └── panel.gd
│   │   ├── settings/
│   │   │   ├── settings_dialog.tscn
│   │   │   └── settings_dialog.gd
│   │   └── wizard/
│   │       ├── wizard_dialog.tscn
│   │       └── wizard_dialog.gd
│   ├── resources/
│   │   └── pet_resource.gd           # PetResource 自定义 Resource
│   └── platform/
│       ├── platform_interface.gd     # class_name PlatformInterface 抽象基类
│       └── windows_platform.gd       # class_name WindowsPlatform extends PlatformInterface
├── native/
│   └── windows/
│       ├── letsmakemoney_native.gdextension
│       ├── SConstruct                # Godot C++ / godot-cpp 构建入口
│       ├── src/
│       │   ├── lmm_native_bridge.h
│       │   ├── lmm_native_bridge.cpp
│       │   ├── tray_controller.h
│       │   ├── tray_controller.cpp
│       │   ├── window_controller.h
│       │   └── window_controller.cpp
│       └── bin/
│           └── win64/
│               └── letsmakemoney_native.dll
├── icons/
│   └── app_icon.ico
├── releases/
│   ├── CHANGELOG.md
│   └── v0.3-beta-notes.md
└── doc/
    ├── LetsMakeMoneyPRD.md
    ├── implementation-plan.md
    ├── verification/
    │   └── v0.3.md
    └── progress.md
```

### 0.2 模块职责边界（关键设计决策）
- **PetManager 是唯一的状态机中枢**。pet.gd 只监听鼠标事件并调用 `PetManager.request_state()`，不自己维护状态，不自己决定播什么动画——动画播放由 `PetManager.state_changed` 信号驱动 pet.gd。
- **拖拽逻辑放在 pet.gd**。DragResizeSystem 只提供 `move_window_to(pos)` 和 `save_position()` 工具方法，不自己监听鼠标。
- **托盘和"融入桌面"在 v0.1 是降级方案**，不假装实现，用 PopupMenu 代替托盘，用普通非置顶窗口代替真嵌入桌面。
- **v0.1 当前窗口是调试稳定版**。虽然早期计划写过透明无边框窗口，但实际代码为了输入稳定改为普通 900×500 调试窗口；v0.2 才恢复默认桌宠模式。

---

## 1. v0.1 Beta 实施计划

> 本节保留 v0.1 原执行计划，但实际完成状态以当前代码和 `doc/progress.md` 为准。v0.1 已完成产品雏形与打包，部分早期目标按降级方案交付。

### 1.1 里程碑 1: 基础设施 — 项目搭建 + Config + SalaryEngine

#### Task 1.1: 创建 Godot 项目 + 目录结构 + .gitignore

**Files:**
- Create: `project.godot`
- Create: `.gitignore`

- [ ] **Step 1: 在 Godot 编辑器中创建新项目**

在 Godot 4.x 中:
1. 新建项目 → 路径选 `<PROJECT_ROOT>\`
2. 渲染器选 `Compatibility`（2D 应用，无需 Vulkan）
3. 创建目录结构：`src/autoload/`、`src/scenes/`、`src/resources/`、`src/platform/`、`assets/pets/`、`icons/`

- [ ] **Step 2: 创建 .gitignore**

```
# Godot 4
.godot/
build/
*.exe
export_presets.cfg

# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/
```

- [ ] **Step 3: 验证**

在编辑器中关闭并重新打开项目，无报错。`.godot/` 目录被 git 忽略（如果已 git init）。

---

#### Task 1.2: 实现 PlatformInterface + WindowsPlatform + Platform Autoload

**Files:**
- Create: `src/platform/platform_interface.gd`
- Create: `src/platform/windows_platform.gd`
- Create: `src/autoload/platform.gd`

- [ ] **Step 1: 编写 PlatformInterface 抽象基类**

```gdscript
# src/platform/platform_interface.gd
class_name PlatformInterface
extends RefCounted

# 所有方法由子类覆盖。基类提供空实现 + push_error。
# 使用 RefCounted 而非 Node——这是纯逻辑对象，不需要进场景树。

func get_config_path() -> String:
    push_error("PlatformInterface.get_config_path() not implemented")
    return ""

func setup_window(_window: Window) -> void:
    push_error("PlatformInterface.setup_window() not implemented")

func set_window_topmost(_window: Window, _topmost: bool) -> void:
    push_error("PlatformInterface.set_window_topmost() not implemented")

func get_screen_size() -> Vector2i:
    push_error("PlatformInterface.get_screen_size() not implemented")
    return Vector2i(1920, 1080)

func is_embed_desktop_supported() -> bool:
    return false  # v0.1 默认不支持真嵌入桌面

func set_window_embed_desktop(_window: Window, _embed: bool) -> void:
    # v0.1 降级：融入桌面退化为普通非置顶窗口
    if _embed:
        set_window_topmost(_window, false)
```

- [ ] **Step 2: 编写 WindowsPlatform 实现**

```gdscript
# src/platform/windows_platform.gd
class_name WindowsPlatform
extends PlatformInterface

func get_config_path() -> String:
    var appdata := OS.get_environment("APPDATA")
    if appdata.is_empty():
        appdata = OS.get_user_data_dir()
    return appdata.path_join("LetsMakeMoney").path_join("config.json")

func setup_window(window: Window) -> void:
    # 确保配置目录存在
    var config_path := get_config_path()
    var dir := DirAccess.open(config_path.get_base_dir())
    if dir == null:
        DirAccess.make_dir_recursive_absolute(config_path.get_base_dir())
    # 窗口样式
    window.borderless = true
    window.transparent_bg = true
    window.unresizable = true
    window.always_on_top = true
    window.min_size = Vector2i(200, 200)

func set_window_topmost(window: Window, topmost: bool) -> void:
    window.always_on_top = topmost

func get_screen_size() -> Vector2i:
    return DisplayServer.screen_get_size()

func is_embed_desktop_supported() -> bool:
    return false  # v0.1 不实现真嵌入桌面（需要 Progman 父窗口技巧）
```

- [ ] **Step 3: 编写 Platform Autoload 工厂**

```gdscript
# src/autoload/platform.gd
extends Node

var impl: PlatformInterface = null

func _ready() -> void:
    impl = _create_platform_impl()

func _create_platform_impl() -> PlatformInterface:
    var os_name := OS.get_name()
    match os_name:
        "Windows":
            return WindowsPlatform.new()
        _:
            push_warning("Unsupported platform: %s, falling back to WindowsPlatform" % os_name)
            return WindowsPlatform.new()

# 转发接口
func get_config_path() -> String:
    return impl.get_config_path()

func setup_window(window: Window) -> void:
    impl.setup_window(window)

func set_window_topmost(window: Window, topmost: bool) -> void:
    impl.set_window_topmost(window, topmost)

func get_screen_size() -> Vector2i:
    return impl.get_screen_size()

func set_window_embed_desktop(window: Window, embed: bool) -> void:
    impl.set_window_embed_desktop(window, embed)

func is_embed_desktop_supported() -> bool:
    return impl.is_embed_desktop_supported()
```

- [ ] **Step 4: 注册 Platform 为 Autoload**

项目设置 → Autoload → 添加 `src/autoload/platform.gd`，名称 `Platform`。**注意：Platform 必须在 Config 之前注册**，因为 Config 的 `_ready()` 会调用 `Platform.get_config_path()`。Autoload 按注册顺序初始化，所以先加 Platform 再加 Config。

- [ ] **Step 5: 验证**

在 Godot 编辑器中临时新建一个 Node 场景运行，添加脚本：
```gdscript
extends Node
func _ready() -> void:
    print("Config path: ", Platform.get_config_path())
    print("Screen size: ", Platform.get_screen_size())
```
运行后控制台应输出正确的 APPDATA 路径和屏幕尺寸。

**实际执行说明（v0.1）**：
- 早期计划要求默认无边框透明桌宠窗口，但 Windows 透明窗口在按像素命中、拖拽和右键交互上不稳定。
- 当前 v0.1 代码为了稳定验证交互，已在 `WindowsPlatform` 中改为普通 900×500 调试窗口，并保留 `DebugInputArea` / `DebugStatus` 可见。
- 无边框透明、空白点击穿透和默认隐藏 debug UI 已转入 v0.2 Beta 的 `V02-M1` / `V02-M2` 正式处理。

---

#### Task 1.3: 实现 Config Autoload

**Files:**
- Create: `src/autoload/config.gd`

- [ ] **Step 1: 注册 Config Autoload**

项目设置 → Autoload → 添加 `src/autoload/config.gd`，名称 `Config`（确保排在 Platform 之后）

- [ ] **Step 2: 编写 Config 完整代码**

```gdscript
# src/autoload/config.gd
extends Node

signal config_changed  # 配置变更通知（观察者模式）

var data: Dictionary = {}
var _config_path: String = ""
var _defaults_cache: Dictionary = {}

func _ready() -> void:
    _config_path = Platform.get_config_path()
    _ensure_dir()
    _load()

func _ensure_dir() -> void:
    var dir_path := _config_path.get_base_dir()
    if not DirAccess.dir_exists_absolute(dir_path):
        DirAccess.make_dir_recursive_absolute(dir_path)

func _load() -> void:
    if not FileAccess.file_exists(_config_path):
        data = _defaults().duplicate(true)
        return
    var file := FileAccess.open(_config_path, FileAccess.READ)
    if file == null:
        data = _defaults().duplicate(true)
        return
    var json_string := file.get_as_text()
    file.close()
    var parsed = JSON.parse_string(json_string)
    if parsed is Dictionary:
        # 合并默认值，确保新增字段有默认值
        var merged := _defaults().duplicate(true)
        _merge_dict(merged, parsed)
        data = merged
    else:
        data = _defaults().duplicate(true)

func _merge_dict(target: Dictionary, source: Dictionary) -> void:
    for key in source:
        if target.has(key) and typeof(target[key]) == TYPE_DICTIONARY and typeof(source[key]) == TYPE_DICTIONARY:
            _merge_dict(target[key], source[key])
        else:
            target[key] = source[key]

func _defaults() -> Dictionary:
    if _defaults_cache.is_empty():
        _defaults_cache = {
            "monthly_salary": 0,
            "rest_mode": "double",
            "work_hours_per_day": 8,
            "work_start_time": "09:00",
            "work_end_time": "18:00",
            "pet_id": "cat",
            "window_x": -1,
            "window_y": -1,
            "window_mode": "top",
            "opacity": 1.0,
            "scale": 1.0,
            "panel_items": {
                "earnings_today": true,
                "earnings_month": true,
                "hourly_rate": true,
                "work_progress": true,
                "status": true
            }
        }
    return _defaults_cache

func save() -> void:
    var file := FileAccess.open(_config_path, FileAccess.WRITE)
    if file == null:
        push_error("Failed to save config to: %s" % _config_path)
        return
    file.store_string(JSON.stringify(data, "\t"))
    file.close()
    config_changed.emit()

func get_value(key: String, default: Variant = null) -> Variant:
    if data.has(key):
        return data[key]
    var def := _defaults()
    if def.has(key):
        return def[key]
    return default

func set_value(key: String, value: Variant) -> void:
    data[key] = value

func has_config() -> bool:
    return FileAccess.file_exists(_config_path)

func get_panel_item(key: String) -> bool:
    var items: Dictionary = data.get("panel_items", {})
    return bool(items.get(key, true))

func set_panel_item(key: String, visible: bool) -> void:
    if not data.has("panel_items"):
        data["panel_items"] = {}
    data["panel_items"][key] = visible
```

- [ ] **Step 3: 验证**

在临时场景脚本中：
```gdscript
extends Node
func _ready() -> void:
    print("has_config: ", Config.has_config())
    print("default salary: ", Config.get_value("monthly_salary"))
    Config.set_value("monthly_salary", 10000)
    Config.save()
    print("after save, has_config: ", Config.has_config())
```
运行后确认 `%APPDATA%/LetsMakeMoney/config.json` 被创建且内容正确。

---

#### Task 1.4: 实现 SalaryEngine

**Files:**
- Create: `src/autoload/salary_engine.gd`

- [ ] **Step 1: 注册 SalaryEngine Autoload**

添加 `src/autoload/salary_engine.gd` → `SalaryEngine`（排在 Config 之后）

- [ ] **Step 2: 实现 SalaryEngine 完整代码**

```gdscript
# src/autoload/salary_engine.gd
extends Node

# 输入参数
var monthly_salary: float = 0.0
var rest_mode: String = "double"
var work_hours_per_day: int = 8
var work_start_time: String = "09:00"
var work_end_time: String = "18:00"

# 派生值
var rate_per_second: float = 0.0
var hourly_rate: float = 0.0
var work_days_this_month: int = 0

# 跨日/跨月检测
var _last_year: int = 0
var _last_month: int = 0
var _last_day: int = 0


func _ready() -> void:
    _load_from_config()


func _process(_delta: float) -> void:
    # 每帧检查日期变化——任何一天进入都重算（跨月必然重算，同月也只是低开销计算）
    var today := Time.get_datetime_dict_from_system()
    if today.year != _last_year or today.month != _last_month or today.day != _last_day:
        _recalculate()


func _load_from_config() -> void:
    monthly_salary = float(Config.get_value("monthly_salary", 0))
    rest_mode = String(Config.get_value("rest_mode", "double"))
    work_hours_per_day = int(Config.get_value("work_hours_per_day", 8))
    work_start_time = String(Config.get_value("work_start_time", "09:00"))
    work_end_time = String(Config.get_value("work_end_time", "18:00"))
    _recalculate()


func reload() -> void:
    _load_from_config()


func _recalculate() -> void:
    var today := Time.get_datetime_dict_from_system()
    _last_year = today.year
    _last_month = today.month
    _last_day = today.day
    work_days_this_month = _calc_work_days(today.year, today.month, rest_mode)
    if work_days_this_month > 0 and work_hours_per_day > 0:
        hourly_rate = monthly_salary / float(work_days_this_month * work_hours_per_day)
        rate_per_second = hourly_rate / 3600.0
    else:
        hourly_rate = 0.0
        rate_per_second = 0.0


func _calc_work_days(year: int, month: int, mode: String) -> int:
    var days := _days_in_month(year, month)
    var count := 0
    for d in range(1, days + 1):
        var date_str := "%04d-%02d-%02d" % [year, month, d]
        var weekday := Time.get_weekday_from_datetime_string(date_str)
        # weekday: 0=Sunday, 6=Saturday
        match mode:
            "double":
                if weekday != 0 and weekday != 6:
                    count += 1
            "single":
                if weekday != 0:
                    count += 1
            _:
                count += 1  # 未知模式按全工作日算（防御）
    return count


func _days_in_month(year: int, month: int) -> int:
    match month:
        2:
            if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
                return 29
            return 28
        4, 6, 9, 11:
            return 30
        _:
            return 31


func is_working_hours() -> bool:
    if monthly_salary <= 0:
        return false
    var start_min := _time_str_to_minutes(work_start_time)
    var end_min := _time_str_to_minutes(work_end_time)
    if start_min < 0 or end_min < 0 or end_min <= start_min:
        return false
    var now := Time.get_datetime_dict_from_system()
    var now_min := now.hour * 60 + now.minute
    return now_min >= start_min and now_min < end_min


func _time_str_to_minutes(s: String) -> int:
    var parts := s.split(":")
    if parts.size() < 2:
        return -1
    return int(parts[0]) * 60 + int(parts[1])


func get_earnings_today() -> float:
    if monthly_salary <= 0:
        return 0.0
    var start_min := _time_str_to_minutes(work_start_time)
    var end_min := _time_str_to_minutes(work_end_time)
    if start_min < 0 or end_min < 0 or end_min <= start_min:
        return 0.0
    var now := Time.get_datetime_dict_from_system()
    var now_seconds := now.hour * 3600 + now.minute * 60 + now.second
    var start_seconds := start_min * 60
    var end_seconds := end_min * 60

    if now_seconds < start_seconds:
        return 0.0  # 上班前
    if now_seconds >= end_seconds:
        var total := end_seconds - start_seconds
        return float(total) * rate_per_second  # 下班后封顶
    # 工作中
    var elapsed := now_seconds - start_seconds
    return float(elapsed) * rate_per_second


func get_earnings_this_month() -> float:
    if monthly_salary <= 0:
        return 0.0
    var now := Time.get_datetime_dict_from_system()
    var days_in_month := _days_in_month(now.year, now.month)
    return monthly_salary * (float(now.day) / float(days_in_month))


func get_work_progress() -> float:
    if monthly_salary <= 0:
        return 0.0
    var start_min := _time_str_to_minutes(work_start_time)
    var end_min := _time_str_to_minutes(work_end_time)
    if start_min < 0 or end_min < 0 or end_min <= start_min:
        return 0.0
    var now := Time.get_datetime_dict_from_system()
    var now_seconds := now.hour * 3600 + now.minute * 60 + now.second
    var start_seconds := start_min * 60
    var end_seconds := end_min * 60
    if now_seconds < start_seconds:
        return 0.0
    if now_seconds >= end_seconds:
        return 1.0
    return clamp(float(now_seconds - start_seconds) / float(end_seconds - start_seconds), 0.0, 1.0)


func get_rate_per_second() -> float:
    return rate_per_second


func get_hourly_rate() -> float:
    return hourly_rate


func get_work_days_this_month() -> int:
    return work_days_this_month


func get_state_text() -> String:
    if monthly_salary <= 0:
        return "未设置薪资"
    if is_working_hours():
        return "努力工作中"
    var now := Time.get_datetime_dict_from_system()
    var now_min := now.hour * 60 + now.minute
    var start_min := _time_str_to_minutes(work_start_time)
    var end_min := _time_str_to_minutes(work_end_time)
    if now_min < start_min:
        return "还没上班"
    if now_min >= end_min:
        return "已下班休息"
    return "休息中"
```

- [ ] **Step 3: 验证**

在临时脚本中手动设置 Config 并测试计算：
```gdscript
extends Node
func _ready() -> void:
    Config.set_value("monthly_salary", 10000)
    Config.set_value("rest_mode", "double")
    Config.set_value("work_hours_per_day", 8)
    Config.set_value("work_start_time", "09:00")
    Config.set_value("work_end_time", "18:00")
    SalaryEngine.reload()
    print("work_days: ", SalaryEngine.get_work_days_this_month())
    print("hourly_rate: ", SalaryEngine.get_hourly_rate())
    print("earnings_today: ", SalaryEngine.get_earnings_today())
    print("is_working: ", SalaryEngine.is_working_hours())
    print("state: ", SalaryEngine.get_state_text())
```
运行确认输出合理（work_days 应为当月周一到周五天数）。

---

#### Task 1.5: 实现 PetResource

**Files:**
- Create: `src/resources/pet_resource.gd`

- [ ] **Step 1: 编写 PetResource**

```gdscript
# src/resources/pet_resource.gd
class_name PetResource
extends Resource

@export var pet_id: String = ""
@export var display_name: String = ""
@export var sprite_frames: SpriteFrames
@export var thumbnail: Texture2D

# 动画名与 SpriteFrames 中的动画名严格一致
# 动画名约定: idle / working / resting / hover / clicked_single / clicked_double / clicked_hold
@export var animation_speeds: Dictionary = {
    "idle": 2.0,
    "working": 0.8,
    "resting": 3.0,
    "hover": 0.0,
    "clicked_single": 0.6,
    "clicked_double": 0.8,
    "clicked_hold": 1.0
}
```

- [ ] **Step 2: 在编辑器中创建 cat_resource.tres**

1. 文件系统右键 `assets/pets/cat/` → New Resource → 搜索 `PetResource` → 创建
2. 保存为 `assets/pets/cat/cat_resource.tres`
3. 暂时只填 `pet_id = "cat"`、`display_name = "小猫"`，`sprite_frames` 留空（M2 准备素材后填）

- [ ] **Step 3: 验证**

保存 tres 文件，编辑器无报错。

---

### 1.2 里程碑 2: 角色系统 — PetManager 状态机中枢 + Pet 场景

#### Task 2.1: 实现 PetManager Autoload

**Files:**
- Create: `src/autoload/pet_manager.gd`

- [ ] **Step 1: 注册 PetManager Autoload**

添加 `src/autoload/pet_manager.gd` → `PetManager`（排在 SalaryEngine 之后）

- [ ] **Step 2: 实现 PetManager**

```gdscript
# src/autoload/pet_manager.gd
extends Node

# 状态枚举——与 PetResource 动画名一一对应
enum PetState {
    IDLE,
    WORKING,
    RESTING,
    HOVER,
    CLICKED_SINGLE,
    CLICKED_DOUBLE,
    CLICKED_HOLD
}

signal pet_changed(pet_id: String)
signal state_changed(new_state: PetState)

var available_pets: Array[PetResource] = []
var current_pet: PetResource = null
var current_state: PetState = PetState.IDLE

# 当前是否处于交互状态（HOVER 或 CLICKED_*），交互状态优先于工作时间自动切换
var _interacting: bool = false

const PETS_DIR = "res://assets/pets/"


func _ready() -> void:
    _scan_pets()
    var saved_id := String(Config.get_value("pet_id", "cat"))
    switch_pet(saved_id)


func _scan_pets() -> void:
    available_pets.clear()
    var dir := DirAccess.open(PETS_DIR)
    if dir == null:
        push_warning("Pets directory not found: %s" % PETS_DIR)
        return
    dir.list_dir_begin()
    var dir_name := dir.get_next()
    while dir_name != "":
        if dir.current_is_dir() and not dir_name.begins_with(".") and dir_name != "raw":
            var res_path := PETS_DIR.path_join(dir_name).path_join(dir_name + "_resource.tres")
            if ResourceLoader.exists(res_path):
                var pet_res := load(res_path) as PetResource
                if pet_res:
                    available_pets.append(pet_res)
        dir_name = dir.get_next()
    dir.list_dir_end()


func switch_pet(pet_id: String) -> void:
    for pet in available_pets:
        if pet.pet_id == pet_id:
            current_pet = pet
            Config.set_value("pet_id", pet_id)
            pet_changed.emit(pet_id)
            return
    if available_pets.size() > 0:
        current_pet = available_pets[0]
        Config.set_value("pet_id", current_pet.pet_id)
        pet_changed.emit(current_pet.pet_id)


func get_current_pet() -> PetResource:
    return current_pet


func get_available_pets() -> Array[PetResource]:
    return available_pets


# 统一状态入口——由 pet.gd 调用
func request_state(new_state: PetState) -> void:
    if new_state == PetState.HOVER or \
       new_state == PetState.CLICKED_SINGLE or \
       new_state == PetState.CLICKED_DOUBLE or \
       new_state == PetState.CLICKED_HOLD:
        _interacting = true
    else:
        _interacting = false
    set_state(new_state)


func set_state(new_state: PetState) -> void:
    if current_state != new_state:
        current_state = new_state
        state_changed.emit(new_state)


# 交互结束后回到工作/休息/待机状态
func return_to_auto_state() -> void:
    _interacting = false
    if SalaryEngine.monthly_salary <= 0:
        set_state(PetState.IDLE)
    elif SalaryEngine.is_working_hours():
        set_state(PetState.WORKING)
    else:
        set_state(PetState.RESTING)


func _process(_delta: float) -> void:
    if current_pet == null:
        return
    if _interacting:
        return  # 交互状态由 pet.gd 显式控制
    # 自动切换 WORKING / RESTING / IDLE
    if SalaryEngine.monthly_salary <= 0:
        set_state(PetState.IDLE)
    elif SalaryEngine.is_working_hours():
        set_state(PetState.WORKING)
    else:
        set_state(PetState.RESTING)


# 将状态枚举映射到 SpriteFrames 动画名
func state_to_anim_name(state: PetState) -> String:
    match state:
        PetState.IDLE: return "idle"
        PetState.WORKING: return "working"
        PetState.RESTING: return "resting"
        PetState.HOVER: return "hover"
        PetState.CLICKED_SINGLE: return "clicked_single"
        PetState.CLICKED_DOUBLE: return "clicked_double"
        PetState.CLICKED_HOLD: return "clicked_hold"
    return "idle"
```

- [ ] **Step 3: 验证**

运行项目，Console 无报错。`available_pets` 应包含 1 个 cat（即使 sprite_frames 为空）。

---

#### Task 2.2: 实现 Pet 场景

**Files:**
- Create: `src/scenes/pet/pet.tscn`
- Create: `src/scenes/pet/pet.gd`

- [ ] **Step 1: 创建 pet.tscn 场景结构**

在 Godot 编辑器中创建 `src/scenes/pet/pet.tscn`：

```
pet (Node2D, script: res://src/scenes/pet/pet.gd)
├── AnimatedSprite2D (Name: AnimatedSprite2D)
└── Area2D (Name: ClickArea)
    └── CollisionShape2D (RectangleShape2D, 120x120, 居中)
```

确保 Area2D 的 `input_pickable` 为 true。

- [ ] **Step 2: 编写 pet.gd**

```gdscript
# src/scenes/pet/pet.gd
extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var click_area: Area2D = $ClickArea

# 交互状态
var _hover_entered: bool = false
var _mouse_pressed: bool = false
var _press_timer: float = 0.0
var _click_count: int = 0
var _click_timer: float = 0.0
var _long_press_triggered: bool = false

# 拖拽
var _dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_start_mouse: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD := 5.0  # 像素，超过则判定为拖拽
const LONG_PRESS_THRESHOLD := 0.5  # 秒
const DOUBLE_CLICK_WINDOW := 0.3  # 秒


func _ready() -> void:
    _setup_from_resource()
    PetManager.pet_changed.connect(_on_pet_changed)
    PetManager.state_changed.connect(_on_state_changed)
    click_area.mouse_entered.connect(_on_mouse_entered)
    click_area.mouse_exited.connect(_on_mouse_exited)


func _setup_from_resource() -> void:
    var pet_res := PetManager.get_current_pet()
    if pet_res == null or pet_res.sprite_frames == null:
        return
    anim.sprite_frames = pet_res.sprite_frames
    _apply_animation_speeds(pet_res)
    _play_current_state()


func _apply_animation_speeds(pet_res: PetResource) -> void:
    if pet_res.sprite_frames == null:
        return
    for anim_name in pet_res.animation_speeds:
        if pet_res.sprite_frames.has_animation(anim_name):
            var fps: float = float(pet_res.animation_speeds[anim_name])
            if fps > 0:
                pet_res.sprite_frames.set_animation_speed(anim_name, fps)


func _on_pet_changed(_pet_id: String) -> void:
    _setup_from_resource()


func _on_state_changed(new_state: PetManager.PetState) -> void:
    var anim_name := PetManager.state_to_anim_name(new_state)
    _play_anim(anim_name)


func _play_current_state() -> void:
    _play_anim(PetManager.state_to_anim_name(PetManager.current_state))


func _on_mouse_entered() -> void:
    _hover_entered = true
    PetManager.request_state(PetManager.PetState.HOVER)


func _on_mouse_exited() -> void:
    _hover_entered = false
    # 如果正在拖拽或按下，不立即回退——等松开
    if not _mouse_pressed and not _dragging:
        PetManager.return_to_auto_state()


func _play_anim(anim_name: String) -> void:
    if anim.sprite_frames == null:
        return
    if anim.sprite_frames.has_animation(anim_name):
        anim.play(anim_name)


func _input(event: InputEvent) -> void:
    if not _hover_entered and not _dragging:
        return

    if event is InputEventMouseButton:
        _handle_mouse_button(event)
    elif event is InputEventMouseMotion:
        _handle_mouse_motion(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
    if event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _mouse_pressed = true
            _press_timer = 0.0
            _long_press_triggered = false
            _drag_start_mouse = DisplayServer.mouse_get_position()
            _drag_start_pos = get_window().position
        else:
            if _dragging:
                _end_drag()
            elif _long_press_triggered:
                # 长按刚结束，松开恢复
                PetManager.return_to_auto_state()
            else:
                # 短按——计入点击计数
                _click_count += 1
                _click_timer = 0.0
            _mouse_pressed = false
            _press_timer = 0.0
    elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        DragResizeSystem.show_context_menu()


func _handle_mouse_motion(_event: InputEventMouseMotion) -> void:
    if _mouse_pressed and not _dragging:
        var mouse_pos := DisplayServer.mouse_get_position()
        if (mouse_pos - _drag_start_mouse).length() > DRAG_THRESHOLD:
            _start_drag()
    if _dragging:
        var mouse_pos := DisplayServer.mouse_get_position()
        var new_pos := _drag_start_pos + (mouse_pos - _drag_start_mouse)
        DragResizeSystem.move_window_to(new_pos)


func _start_drag() -> void:
    _dragging = true


func _end_drag() -> void:
    _dragging = false
    DragResizeSystem.save_position()


func _process(delta: float) -> void:
    if _mouse_pressed and not _dragging:
        _press_timer += delta
        if _press_timer >= LONG_PRESS_THRESHOLD and not _long_press_triggered:
            _long_press_triggered = true
            PetManager.request_state(PetManager.PetState.CLICKED_HOLD)

    if _click_count > 0 and not _mouse_pressed:
        _click_timer += delta
        if _click_timer > DOUBLE_CLICK_WINDOW:
            if _click_count >= 2:
                PetManager.request_state(PetManager.PetState.CLICKED_DOUBLE)
            else:
                PetManager.request_state(PetManager.PetState.CLICKED_SINGLE)
            _click_count = 0
            _click_timer = 0.0
            # 单击/双击动画播完后回到自动状态——由动画 finished 信号或定时器
            _schedule_return_after_click()


func _schedule_return_after_click() -> void:
    # 单击/双击是单次动画，0.8s 后回退
    var timer := get_tree().create_timer(0.8)
    timer.timeout.connect(_on_click_return)


func _on_click_return() -> void:
    if _hover_entered:
        PetManager.request_state(PetManager.PetState.HOVER)
    else:
        PetManager.return_to_auto_state()
```

- [ ] **Step 3: 验证**

运行项目（即使 sprite_frames 为空，逻辑层应正常）。Console 无报错。

---

#### Task 2.3: 准备占位素材

**Files:**
- Download: `assets/pets/cat/raw/`
- Create: `assets/pets/cat/cat_sprite_frames.tres`
- Modify: `assets/pets/cat/cat_resource.tres`

- [ ] **Step 1: 下载 itch.io 免费 cat sprite sheet**

访问 https://xzany.itch.io/cat-2d-pixel-art 下载免费版，解压到 `assets/pets/cat/raw/`。确认包含 idle / sleep 等动画帧。

- [ ] **Step 2: 在 Godot 编辑器中创建 SpriteFrames 资源**

1. 文件系统右键 `assets/pets/cat/` → New Resource → `SpriteFrames`
2. 保存为 `cat_sprite_frames.tres`
3. 在 SpriteFrames 编辑器中创建以下动画（帧数按 PRD 4.3.1）：
   - `idle` — 4 帧，2 秒循环
   - `working` — 4 帧，0.8 秒循环（手动调整或复制 idle 帧做敲键盘姿态）
   - `resting` — 2 帧，3 秒循环（用 sleep 帧）
   - `hover` — 1 帧，静态（看向鼠标的姿态）
   - `clicked_single` — 3 帧，0.6 秒单次
   - `clicked_double` — 3 帧，0.8 秒单次
   - `clicked_hold` — 2 帧，1 秒循环

- [ ] **Step 3: 将 sprite_frames 引用填入 cat_resource.tres**

打开 `cat_resource.tres`，将 `sprite_frames` 字段设为 `cat_sprite_frames.tres`。

- [ ] **Step 4: 验证**

运行项目，小猫在桌面显示 IDLE 动画。

---

### 1.3 里程碑 3: UI 与交互

#### Task 3.1: 实现 PanelSystem Autoload

**Files:**
- Create: `src/autoload/panel_system.gd`

- [ ] **Step 1: 注册 PanelSystem Autoload**

添加 `src/autoload/panel_system.gd` → `PanelSystem`

- [ ] **Step 2: 实现 PanelSystem**

```gdscript
# src/autoload/panel_system.gd
extends Node

const HOVER_DELAY := 0.3
const LEAVE_DELAY := 0.5
const REFRESH_INTERVAL := 0.5  # 节流刷新，避免每帧刷新超 CPU<1% 要求

var _panel: Control = null
var _collapsed: bool = true
var _hover_timer: float = 0.0
var _leave_timer: float = 0.0
var _mouse_over: bool = false
var _refresh_timer: float = 0.0


func register_panel(panel: Control) -> void:
    _panel = panel
    # 连接整个面板根节点的 mouse 事件——避免 Collapsed/Expanded 切换时抖动
    panel.mouse_entered.connect(_on_panel_mouse_entered)
    panel.mouse_exited.connect(_on_panel_mouse_exited)


func _process(delta: float) -> void:
    if _panel == null:
        return

    if _mouse_over:
        _hover_timer += delta
        _leave_timer = 0.0
        if _hover_timer >= HOVER_DELAY and _collapsed:
            _panel.expand()
            _collapsed = false
    else:
        _leave_timer += delta
        _hover_timer = 0.0
        if _leave_timer >= LEAVE_DELAY and not _collapsed:
            _panel.collapse()
            _collapsed = true

    # 节流刷新数值
    _refresh_timer += delta
    if _refresh_timer >= REFRESH_INTERVAL:
        _refresh_timer = 0.0
        if _panel and not _collapsed:
            _panel.refresh_values()


func _on_panel_mouse_entered() -> void:
    _mouse_over = true


func _on_panel_mouse_exited() -> void:
    _mouse_over = false


func force_refresh() -> void:
    if _panel:
        _panel.refresh_values()


func is_expanded() -> bool:
    return not _collapsed
```

- [ ] **Step 3: 验证**

暂无（等 panel.tscn 创建后一起验证）。

---

#### Task 3.2: 实现 Panel 场景

**Files:**
- Create: `src/scenes/panel/panel.tscn`
- Create: `src/scenes/panel/panel.gd`

- [ ] **Step 1: 创建 panel.tscn 场景结构**

在 Godot 编辑器中创建 `src/scenes/panel/panel.tscn`：

```
panel (Control, script: res://src/scenes/panel/panel.gd)
├── Background (ColorRect or Panel, 用于半透明背景——后续设 StyleBox)
├── Collapsed (HBoxContainer, Name: Collapsed)
│   ├── Icon (Label, text: "💰")
│   └── EarningsToday (Label, text: "¥0.00")
└── Expanded (VBoxContainer, Name: Expanded, visible: false)
    ├── TodayRow (HBoxContainer)
    │   ├── TodayLabel (Label, text: "今日已赚")
    │   └── TodayValue (Label)
    ├── MonthRow (HBoxContainer)
    │   ├── MonthLabel (Label, text: "本月累计")
    │   └── MonthValue (Label)
    ├── RateRow (HBoxContainer)
    │   ├── RateLabel (Label, text: "时薪")
    │   └── RateValue (Label)
    ├── ProgressRow (VBoxContainer)
    │   ├── ProgressLabel (Label, text: "工作进度")
    │   └── ProgressBar (ProgressBar, min:0, max:100)
    └── StateRow (HBoxContainer)
        ├── StateLabel (Label, text: "状态")
        └── StateValue (Label)
```

为 panel 根节点设置 StyleBoxFlat 背景：深色 (0,0,0,180)、圆角 8px、内容边距 12px。

- [ ] **Step 2: 编写 panel.gd**

```gdscript
# src/scenes/panel/panel.gd
extends Control

@onready var collapsed_container: HBoxContainer = $Collapsed
@onready var expanded_container: VBoxContainer = $Expanded
@onready var earnings_today_label: Label = $Collapsed/EarningsToday
@onready var exp_today_label: Label = $Expanded/TodayRow/TodayValue
@onready var exp_month_label: Label = $Expanded/MonthRow/MonthValue
@onready var exp_rate_label: Label = $Expanded/RateRow/RateValue
@onready var exp_progress_bar: ProgressBar = $Expanded/ProgressRow/ProgressBar
@onready var exp_state_label: Label = $Expanded/StateRow/StateValue
@onready var exp_today_row: Control = $Expanded/TodayRow
@onready var exp_month_row: Control = $Expanded/MonthRow
@onready var exp_rate_row: Control = $Expanded/RateRow
@onready var exp_progress_row: Control = $Expanded/ProgressRow
@onready var exp_state_row: Control = $Expanded/StateRow

var _tween: Tween = null


func _ready() -> void:
    expanded_container.visible = false
    collapsed_container.visible = true
    _apply_panel_config()
    refresh_values()
    PanelSystem.register_panel(self)


func expand() -> void:
    _kill_tween()
    collapsed_container.visible = false
    expanded_container.visible = true
    expanded_container.scale = Vector2(0.8, 0.8)
    _tween = create_tween()
    _tween.set_ease(Tween.EASE_IN_OUT)
    _tween.set_trans(Tween.TRANS_CUBIC)
    _tween.tween_property(expanded_container, "scale", Vector2.ONE, 0.2)
    refresh_values()
    _apply_panel_config()


func collapse() -> void:
    _kill_tween()
    expanded_container.visible = false
    collapsed_container.visible = true
    collapsed_container.scale = Vector2(0.8, 0.8)
    _tween = create_tween()
    _tween.set_ease(Tween.EASE_IN_OUT)
    _tween.set_trans(Tween.TRANS_CUBIC)
    _tween.tween_property(collapsed_container, "scale", Vector2.ONE, 0.2)


func _kill_tween() -> void:
    if _tween != null:
        _tween.kill()
        _tween = null


func refresh_values() -> void:
    var today := SalaryEngine.get_earnings_today()
    earnings_today_label.text = "¥%.2f" % today
    exp_today_label.text = "¥%.2f" % today
    exp_month_label.text = "¥%.2f" % SalaryEngine.get_earnings_this_month()
    exp_rate_label.text = "¥%.2f/小时" % SalaryEngine.get_hourly_rate()
    exp_progress_bar.value = SalaryEngine.get_work_progress() * 100.0
    exp_state_label.text = SalaryEngine.get_state_text()


func _apply_panel_config() -> void:
    _set_row_visible(exp_today_row, Config.get_panel_item("earnings_today"))
    _set_row_visible(exp_month_row, Config.get_panel_item("earnings_month"))
    _set_row_visible(exp_rate_row, Config.get_panel_item("hourly_rate"))
    _set_row_visible(exp_progress_row, Config.get_panel_item("work_progress"))
    _set_row_visible(exp_state_row, Config.get_panel_item("status"))


func _set_row_visible(row: Control, visible: bool) -> void:
    if row:
        row.visible = visible


func get_expanded_width() -> float:
    return expanded_container.size.x
```

- [ ] **Step 3: 验证**

运行项目，面板可见。鼠标悬停 300ms → 平滑展开；移开 500ms → 平滑收起。

---

#### Task 3.3: 实现 DragResizeSystem Autoload

**Files:**
- Create: `src/autoload/drag_resize_system.gd`

- [ ] **Step 1: 注册 DragResizeSystem Autoload**

添加 `src/autoload/drag_resize_system.gd` → `DragResizeSystem`

- [ ] **Step 2: 实现 DragResizeSystem**

```gdscript
# src/autoload/drag_resize_system.gd
extends Node

var _window: Window = null
var _active_popups: Array[PopupMenu] = []


func register_window(window: Window) -> void:
    _window = window


func move_window_to(pos: Vector2i) -> void:
    if _window:
        _window.position = pos


func save_position() -> void:
    if _window:
        Config.set_value("window_x", int(_window.position.x))
        Config.set_value("window_y", int(_window.position.y))
        Config.save()


func show_context_menu() -> void:
    var popup := PopupMenu.new()
    _build_main_menu(popup)
    _popup_at_mouse(popup)


func show_tray_menu() -> void:
    # v0.1 降级方案：用 PopupMenu 代替真托盘菜单
    var popup := PopupMenu.new()
    popup.add_item("显示/隐藏", 600)
    popup.add_separator()
    _build_main_menu(popup)
    _popup_at_mouse(popup)


func _build_main_menu(menu: PopupMenu) -> void:
    menu.add_item("设置", 100)

    # 切换角色子菜单
    var char_menu := PopupMenu.new()
    char_menu.name = "CharMenu"
    var pets := PetManager.get_available_pets()
    var current_id := String(Config.get_value("pet_id", "cat"))
    for i in pets.size():
        char_menu.add_item(pets[i].display_name, 200 + i)
        if pets[i].pet_id == current_id:
            char_menu.set_item_checked(i, true)
    menu.add_child(char_menu)
    menu.add_submenu_item("切换角色", "CharMenu")

    # 窗口模式子菜单
    var mode_menu := PopupMenu.new()
    mode_menu.name = "ModeMenu"
    mode_menu.add_item("置顶悬浮", 300)
    mode_menu.add_item("融入桌面", 301)
    var wm := String(Config.get_value("window_mode", "top"))
    if wm == "top":
        mode_menu.set_item_checked(0, true)
    else:
        mode_menu.set_item_checked(1, true)
    menu.add_child(mode_menu)
    menu.add_submenu_item("窗口模式", "ModeMenu")

    menu.add_separator()
    menu.add_item("关于 LetsMakeMoney", 400)
    menu.add_separator()
    menu.add_item("退出", 500)

    # 子菜单共享同一个 id_pressed 处理
    char_menu.id_pressed.connect(_on_menu_id)
    mode_menu.id_pressed.connect(_on_menu_id)
    menu.id_pressed.connect(_on_menu_id)


func _popup_at_mouse(popup: PopupMenu) -> void:
    if _window == null:
        return
    _window.add_child(popup)
    _active_popups.append(popup)
    # 用全局鼠标坐标——popup 是 _window 的子节点，position 是窗口内坐标
    var global_mouse := DisplayServer.mouse_get_position()
    popup.position = global_mouse
    popup.popup()
    popup.close_requested.connect(_on_popup_closed.bind(popup))


func _on_popup_closed(popup: PopupMenu) -> void:
    _cleanup_popup(popup)


func _cleanup_popup(popup: PopupMenu) -> void:
    _active_popups.erase(popup)
    if popup and is_instance_valid(popup):
        popup.queue_free()


func _on_menu_id(id: int) -> void:
    match id:
        100:
            _open_settings()
        200, 201, 202:
            var idx := id - 200
            var pets := PetManager.get_available_pets()
            if idx < pets.size():
                PetManager.switch_pet(pets[idx].pet_id)
                Config.save()
        300:
            Config.set_value("window_mode", "top")
            _apply_window_mode("top")
            Config.save()
        301:
            Config.set_value("window_mode", "embed")
            _apply_window_mode("embed")
            Config.save()
        400:
            _show_about()
        500:
            _quit_app()
        600:
            if _window:
                _window.visible = not _window.visible
    # 关闭所有弹出菜单
    _close_all_popups()


func _close_all_popups() -> void:
    for p in _active_popups.duplicate():
        if p and is_instance_valid(p):
            p.hide()  # 触发 close_requested


func _apply_window_mode(mode: String) -> void:
    if _window == null:
        return
    if mode == "embed":
        # v0.1 降级：融入桌面退化为非置顶
        Platform.set_window_embed_desktop(_window, true)
    else:
        Platform.set_window_topmost(_window, true)


func _open_settings() -> void:
    var settings_scene := load("res://src/scenes/settings/settings_dialog.tscn")
    if settings_scene == null:
        push_error("Settings scene not found")
        return
    var dlg := settings_scene.instantiate()
    _window.add_child(dlg)
    dlg.popup_centered()


func _show_about() -> void:
    OS.alert("LetsMakeMoney v0.1 Beta\n赚钱模拟器桌面宠物", "关于")


func _quit_app() -> void:
    Config.save()
    get_tree().quit()
```

- [ ] **Step 3: 验证**

暂无（等 main 场景整合后验证）。

---

#### Task 3.4: 实现 Main 场景整合

**Files:**
- Create: `src/scenes/main/main.tscn`
- Create: `src/scenes/main/main.gd`

- [ ] **Step 1: 创建 main.tscn 场景结构**

在 Godot 编辑器中创建 `src/scenes/main/main.tscn`：

```
main (Node2D, script: res://src/scenes/main/main.gd)
├── Pet (Instance: res://src/scenes/pet/pet.tscn, position: 0,0)
└── Panel (Instance: res://src/scenes/panel/panel.tscn, position: 60,-20)
```

将 `main.tscn` 设为项目主场景（项目设置 → 应用 → 运行 → 主场景）。

- [ ] **Step 2: 编写 main.gd**

```gdscript
# src/scenes/main/main.gd
extends Node2D

@onready var pet: Node2D = $Pet
@onready var panel: Control = $Panel

const PANEL_OFFSET_RIGHT := Vector2(60, -20)  # 默认面板在角色右侧
const PANEL_OFFSET_LEFT := Vector2(-180, -20)  # 贴右边缘时面板在左侧
const PANEL_OFFSET_TOP := Vector2(0, -120)  # 贴底部时面板在上方


func _ready() -> void:
    _setup_window()
    _restore_position()
    _apply_scale_opacity()
    DragResizeSystem.register_window(get_window())
    _position_panel()

    Config.config_changed.connect(_on_config_changed)

    if not Config.has_config():
        _show_wizard()
    else:
        SalaryEngine.reload()


func _setup_window() -> void:
    var window := get_window()
    Platform.setup_window(window)
    var mode := String(Config.get_value("window_mode", "top"))
    if mode == "embed":
        Platform.set_window_embed_desktop(window, true)
    else:
        Platform.set_window_topmost(window, true)


func _restore_position() -> void:
    var window := get_window()
    var x := int(Config.get_value("window_x", -1))
    var y := int(Config.get_value("window_y", -1))
    var screen := Platform.get_screen_size()
    # 验证位置在屏幕内（多显示器切换 fallback）
    if x < 0 or y < 0 or x > screen.x - 50 or y > screen.y - 50:
        x = screen.x - 200
        y = screen.y - 200
    window.position = Vector2i(x, y)


func _apply_scale_opacity() -> void:
    var s := float(Config.get_value("scale", 1.0))
    var o := float(Config.get_value("opacity", 1.0))
    pet.scale = Vector2(s, s)
    modulate = Color(1, 1, 1, o)


func _position_panel() -> void:
    var window := get_window()
    var screen := Platform.get_screen_size()
    var win_pos := window.position
    var pet_size := Vector2(120, 120) * float(Config.get_value("scale", 1.0))

    # 贴右边缘（右侧空间 < 200）→ 面板在左侧
    if win_pos.x + pet_size.x + 200 > screen.x:
        panel.position = PANEL_OFFSET_LEFT
    # 贴底部（下方空间 < 150）→ 面板在上方
    elif win_pos.y + pet_size.y + 150 > screen.y:
        panel.position = PANEL_OFFSET_TOP
    else:
        panel.position = PANEL_OFFSET_RIGHT


func _show_wizard() -> void:
    var wizard_scene := load("res://src/scenes/wizard/wizard_dialog.tscn")
    if wizard_scene == null:
        push_error("Wizard scene not found")
        return
    var dlg := wizard_scene.instantiate()
    get_window().add_child(dlg)
    dlg.popup_centered()
    dlg.finished.connect(_on_wizard_done)


func _on_wizard_done() -> void:
    SalaryEngine.reload()
    _apply_scale_opacity()
    _position_panel()


func _on_config_changed() -> void:
    # 设置保存后刷新所有依赖
    SalaryEngine.reload()
    _apply_scale_opacity()
    _position_panel()
    if panel:
        panel.refresh_values()
        panel._apply_panel_config()


func _process(_delta: float) -> void:
    # 面板数值由 PanelSystem 节流刷新
    # 但简洁模式的今日已赚每秒变化，需要主动触发
    if PanelSystem and not PanelSystem.is_expanded():
        PanelSystem.force_refresh()
    _position_panel()
```

- [ ] **Step 3: 验证**

运行项目：
1. 角色和面板可见
2. 拖拽角色移动窗口，松开后位置保存
3. 右键弹出菜单，菜单项可点击
4. 鼠标悬停面板展开，移开收起

---

### 1.4 里程碑 4: 设置对话框 + 首次启动向导

#### Task 4.1: 实现设置对话框

**Files:**
- Create: `src/scenes/settings/settings_dialog.tscn`
- Create: `src/scenes/settings/settings_dialog.gd`

- [ ] **Step 1: 创建 settings_dialog.tscn 场景结构**

在 Godot 编辑器中创建 `src/scenes/settings/settings_dialog.tscn`，根节点用 `ConfirmationDialog`（自带"确认"和"取消"按钮）：

```
settings_dialog (ConfirmationDialog, script: res://src/scenes/settings/settings_dialog.gd, title: "设置")
└── VBox (VBoxContainer, MarginContainer 包裹)
    └── TabContainer (Name: TabContainer)
        ├── Salary (Tab, Name: Salary)
        │   └── VBox (VBoxContainer)
        │       ├── SalaryLabel (Label, text: "月薪 (元)")
        │       ├── SalaryInput (SpinBox, min:0, max:999999, step:100)
        │       ├── RestModeLabel (Label, text: "休息模式")
        │       ├── RestModeOption (OptionButton: items=["双休","单休"])
        │       ├── HoursLabel (Label, text: "每日工作小时数")
        │       ├── HoursInput (SpinBox, min:1, max:24)
        │       ├── StartLabel (Label, text: "上班时间")
        │       ├── HBox (HBoxContainer)
        │       │   ├── StartHour (SpinBox, min:0, max:23)
        │       │   ├── Colon1 (Label, text: ":")
        │       │   └── StartMin (SpinBox, min:0, max:59)
        │       ├── EndLabel (Label, text: "下班时间")
        │       └── HBox2 (HBoxContainer)
        │           ├── EndHour (SpinBox, min:0, max:23)
        │           ├── Colon2 (Label, text: ":")
        │           └── EndMin (SpinBox, min:0, max:59)
        ├── Pet (Tab, Name: Pet)
        │   └── VBox
        │       ├── PetListLabel (Label, text: "选择角色")
        │       ├── PetList (ItemList)
        │       ├── ScaleLabel (Label, text: "缩放 (50%-200%)")
        │       └── ScaleSlider (HSlider, min:50, max:200, value:100)
        ├── Display (Tab, Name: Display)
        │   └── VBox
        │       ├── OpacityLabel (Label, text: "透明度 (20%-100%)")
        │       ├── OpacitySlider (HSlider, min:20, max:100, value:100)
        │       ├── WindowModeLabel (Label, text: "窗口模式")
        │       └── WindowModeOption (OptionButton: items=["置顶悬浮","融入桌面"])
        ├── Panel (Tab, Name: Panel)
        │   └── VBox
        │       ├── ShowToday (CheckBox, text: "今日已赚")
        │       ├── ShowMonth (CheckBox, text: "本月累计")
        │       ├── ShowRate (CheckBox, text: "时薪")
        │       ├── ShowProgress (CheckBox, text: "工作进度")
        │       └── ShowState (CheckBox, text: "状态")
        └── General (Tab, Name: General)
            └── VBox
                ├── AutoStartLabel (Label, text: "开机自启 (v0.1 暂不支持)")
                └── AutoStartCheck (CheckBox, text: "启用", disabled: true)
```

- [ ] **Step 2: 编写 settings_dialog.gd**

```gdscript
# src/scenes/settings/settings_dialog.gd
extends ConfirmationDialog

@onready var tab_container: TabContainer = $VBox/TabContainer

# Salary tab
@onready var salary_input: SpinBox = $VBox/TabContainer/Salary/VBox/SalaryInput
@onready var rest_mode_option: OptionButton = $VBox/TabContainer/Salary/VBox/RestModeOption
@onready var hours_input: SpinBox = $VBox/TabContainer/Salary/VBox/HoursInput
@onready var start_hour_input: SpinBox = $VBox/TabContainer/Salary/VBox/HBox/StartHour
@onready var start_min_input: SpinBox = $VBox/TabContainer/Salary/VBox/HBox/StartMin
@onready var end_hour_input: SpinBox = $VBox/TabContainer/Salary/VBox/HBox2/EndHour
@onready var end_min_input: SpinBox = $VBox/TabContainer/Salary/VBox/HBox2/EndMin

# Pet tab
@onready var pet_list: ItemList = $VBox/TabContainer/Pet/VBox/PetList
@onready var scale_slider: HSlider = $VBox/TabContainer/Pet/VBox/ScaleSlider

# Display tab
@onready var opacity_slider: HSlider = $VBox/TabContainer/Display/VBox/OpacitySlider
@onready var window_mode_option: OptionButton = $VBox/TabContainer/Display/VBox/WindowModeOption

# Panel tab
@onready var show_today: CheckBox = $VBox/TabContainer/Panel/VBox/ShowToday
@onready var show_month: CheckBox = $VBox/TabContainer/Panel/VBox/ShowMonth
@onready var show_rate: CheckBox = $VBox/TabContainer/Panel/VBox/ShowRate
@onready var show_progress: CheckBox = $VBox/TabContainer/Panel/VBox/ShowProgress
@onready var show_state: CheckBox = $VBox/TabContainer/Panel/VBox/ShowState


func _ready() -> void:
    confirmed.connect(_on_save)
    canceled.connect(_on_cancel)
    _load_current_values()


func _load_current_values() -> void:
    salary_input.value = float(Config.get_value("monthly_salary", 0))
    var rm := String(Config.get_value("rest_mode", "double"))
    rest_mode_option.select(0 if rm == "double" else 1)
    hours_input.value = int(Config.get_value("work_hours_per_day", 8))

    var st := String(Config.get_value("work_start_time", "09:00")).split(":")
    start_hour_input.value = int(st[0]) if st.size() > 0 else 9
    start_min_input.value = int(st[1]) if st.size() > 1 else 0
    var et := String(Config.get_value("work_end_time", "18:00")).split(":")
    end_hour_input.value = int(et[0]) if et.size() > 0 else 18
    end_min_input.value = int(et[1]) if et.size() > 1 else 0

    scale_slider.value = float(Config.get_value("scale", 1.0)) * 100
    opacity_slider.value = float(Config.get_value("opacity", 1.0)) * 100

    var wm := String(Config.get_value("window_mode", "top"))
    window_mode_option.select(0 if wm == "top" else 1)

    _populate_pet_list()
    _load_panel_checkboxes()


func _populate_pet_list() -> void:
    pet_list.clear()
    var pets := PetManager.get_available_pets()
    var current_id := String(Config.get_value("pet_id", "cat"))
    for i in pets.size():
        pet_list.add_item(pets[i].display_name)
        if pets[i].pet_id == current_id:
            pet_list.select(i)


func _load_panel_checkboxes() -> void:
    show_today.button_pressed = Config.get_panel_item("earnings_today")
    show_month.button_pressed = Config.get_panel_item("earnings_month")
    show_rate.button_pressed = Config.get_panel_item("hourly_rate")
    show_progress.button_pressed = Config.get_panel_item("work_progress")
    show_state.button_pressed = Config.get_panel_item("status")


func _on_save() -> void:
    Config.set_value("monthly_salary", float(salary_input.value))
    Config.set_value("rest_mode", "single" if rest_mode_option.selected == 1 else "double")
    Config.set_value("work_hours_per_day", int(hours_input.value))
    Config.set_value("work_start_time", "%02d:%02d" % [int(start_hour_input.value), int(start_min_input.value)])
    Config.set_value("work_end_time", "%02d:%02d" % [int(end_hour_input.value), int(end_min_input.value)])

    Config.set_value("scale", scale_slider.value / 100.0)
    Config.set_value("opacity", opacity_slider.value / 100.0)

    var wm := "top" if window_mode_option.selected == 0 else "embed"
    Config.set_value("window_mode", wm)

    Config.set_panel_item("earnings_today", show_today.button_pressed)
    Config.set_panel_item("earnings_month", show_month.button_pressed)
    Config.set_panel_item("hourly_rate", show_rate.button_pressed)
    Config.set_panel_item("work_progress", show_progress.button_pressed)
    Config.set_panel_item("status", show_state.button_pressed)

    var selected := pet_list.get_selected_items()
    if selected.size() > 0:
        var pets := PetManager.get_available_pets()
        if selected[0] < pets.size():
            Config.set_value("pet_id", pets[selected[0]].pet_id)

    Config.save()  # 触发 config_changed 信号
    _cleanup()


func _on_cancel() -> void:
    _cleanup()


func _cleanup() -> void:
    queue_free()
```

- [ ] **Step 3: 验证**

运行项目 → 右键 → 设置 → 修改薪资参数 → 确认 → 面板数字更新，角色透明度/缩放立即生效。

---

#### Task 4.2: 实现首次启动向导

**Files:**
- Create: `src/scenes/wizard/wizard_dialog.tscn`
- Create: `src/scenes/wizard/wizard_dialog.gd`

- [ ] **Step 1: 创建 wizard_dialog.tscn 场景结构**

在 Godot 编辑器中创建 `src/scenes/wizard/wizard_dialog.tscn`，根节点用 `ConfirmationDialog` 但隐藏默认按钮，自定义 NavBar：

```
wizard_dialog (ConfirmationDialog, script: res://src/scenes/wizard/wizard_dialog.gd, title: "欢迎来到 LetsMakeMoney")
└── VBox (VBoxContainer)
    ├── Pages (Control, 自定义信号 finished)
    │   ├── Welcome (Control, Name: Welcome)
    │   │   ├── Title (Label, text: "欢迎来到 LetsMakeMoney")
    │   │   └── Subtitle (Label, text: "让一只可爱的小动物陪你一起赚钱吧！")
    │   ├── Salary (Control, Name: Salary, visible: false)
    │   │   └── VBox (同设置对话框薪资页结构，节点名一致)
    │   ├── PetSelect (Control, Name: PetSelect, visible: false)
    │   │   └── VBox
    │   │       ├── Label (text: "选择你的伙伴")
    │   │       └── PetList (ItemList)
    │   └── Confirm (Control, Name: Confirm, visible: false)
    │       └── SummaryLabel (Label)
    └── NavBar (HBoxContainer)
        ├── PrevBtn (Button, text: "上一步")
        └── NextBtn (Button, text: "下一步")
```

在 ConfirmationDialog 的检查器中，把 `ok_button_text` 设为空或隐藏默认 OK/Cancel 按钮，只用 NavBar。或者在 `_ready()` 中调用 `get_cancel_button().visible = false; get_ok_button().visible = false`。

- [ ] **Step 2: 编写 wizard_dialog.gd**

```gdscript
# src/scenes/wizard/wizard_dialog.gd
extends ConfirmationDialog

signal finished  # 向导完成信号，main.gd 监听

var _current_step: int = 1

@onready var welcome_page: Control = $VBox/Welcome
@onready var salary_page: Control = $VBox/Salary
@onready var pet_page: Control = $VBox/PetSelect
@onready var confirm_page: Control = $VBox/Confirm

@onready var prev_btn: Button = $VBox/NavBar/PrevBtn
@onready var next_btn: Button = $VBox/NavBar/NextBtn

# Salary page controls (路径与设置对话框一致)
@onready var sal_input: SpinBox = $VBox/Salary/VBox/SalaryInput
@onready var rest_opt: OptionButton = $VBox/Salary/VBox/RestModeOption
@onready var hrs_input: SpinBox = $VBox/Salary/VBox/HoursInput
@onready var sh_input: SpinBox = $VBox/Salary/VBox/HBox/StartHour
@onready var sm_input: SpinBox = $VBox/Salary/VBox/HBox/StartMin
@onready var eh_input: SpinBox = $VBox/Salary/VBox/HBox2/EndHour
@onready var em_input: SpinBox = $VBox/Salary/VBox/HBox2/EndMin

@onready var pet_list: ItemList = $VBox/PetSelect/VBox/PetList
@onready var confirm_label: Label = $VBox/Confirm/SummaryLabel


func _ready() -> void:
    # 隐藏 ConfirmationDialog 默认按钮
    get_ok_button().visible = false
    get_cancel_button().visible = false

    _show_step(1)
    _populate_pets()
    prev_btn.pressed.connect(_on_prev)
    next_btn.pressed.connect(_on_next)
    pet_list.item_selected.connect(_on_pet_selected)


func _show_step(step: int) -> void:
    _current_step = step
    welcome_page.visible = step == 1
    salary_page.visible = step == 2
    pet_page.visible = step == 3
    confirm_page.visible = step == 4

    prev_btn.visible = step > 1
    if step == 4:
        next_btn.text = "开始赚钱！"
        _update_confirm_summary()
    else:
        next_btn.text = "下一步"


func _on_prev() -> void:
    if _current_step > 1:
        _show_step(_current_step - 1)


func _on_next() -> void:
    if _current_step < 4:
        _show_step(_current_step + 1)
    else:
        _finish()


func _populate_pets() -> void:
    pet_list.clear()
    var pets := PetManager.get_available_pets()
    for pet in pets:
        pet_list.add_item(pet.display_name)
    if pets.size() > 0:
        pet_list.select(0)
        # 触发实时预览
        PetManager.switch_pet(pets[0].pet_id)


func _on_pet_selected(idx: int) -> void:
    # PRD 要求：选中实时在桌面上替换显示
    var pets := PetManager.get_available_pets()
    if idx < pets.size():
        PetManager.switch_pet(pets[idx].pet_id)


func _update_confirm_summary() -> void:
    var rm_text := "双休" if rest_opt.selected == 0 else "单休"
    var time_text := "%02d:%02d - %02d:%02d" % [
        int(sh_input.value), int(sm_input.value),
        int(eh_input.value), int(em_input.value)
    ]
    var pet_name := "小猫"
    var selected := pet_list.get_selected_items()
    if selected.size() > 0:
        var pets := PetManager.get_available_pets()
        if selected[0] < pets.size():
            pet_name = pets[selected[0]].display_name

    confirm_label.text = "月薪 ¥%d | %s 每天%d小时 | %s | %s" % [
        int(sal_input.value), rm_text,
        int(hrs_input.value), time_text, pet_name
    ]


func _finish() -> void:
    Config.set_value("monthly_salary", float(sal_input.value))
    Config.set_value("rest_mode", "single" if rest_opt.selected == 1 else "double")
    Config.set_value("work_hours_per_day", int(hrs_input.value))
    Config.set_value("work_start_time", "%02d:%02d" % [int(sh_input.value), int(sm_input.value)])
    Config.set_value("work_end_time", "%02d:%02d" % [int(eh_input.value), int(em_input.value)])

    var selected := pet_list.get_selected_items()
    if selected.size() > 0:
        var pets := PetManager.get_available_pets()
        if selected[0] < pets.size():
            Config.set_value("pet_id", pets[selected[0]].pet_id)

    Config.save()
    finished.emit()
    queue_free()
```

- [ ] **Step 3: 验证**

删除 `%APPDATA%/LetsMakeMoney/config.json` → 运行项目 → 引导窗口弹出 → 完成 4 步 → 角色进入正常状态，薪资面板开始显示数字。

---

### 1.5 里程碑 5: 打包发布

#### Task 5.1: Godot 打包为 Windows exe

- [ ] **Step 1: 准备应用图标**

创建或获取 `icons/app_icon.ico`（可以用 Godot 默认图标暂时占位）。

- [ ] **Step 2: 配置导出预设**

在 Godot 编辑器中：
1. 项目 → 导出 → 添加 → Windows Desktop
2. 配置：
   - 名称: `LetsMakeMoney`
   - 图标: `icons/app_icon.ico`
   - 文件描述: `LetsMakeMoney 赚钱模拟器`
3. 编辑器 → 管理导出模板 → 下载安装 Windows 导出模板

- [ ] **Step 3: 导出并验证**

导出到 `<PROJECT_ROOT>\build\LetsMakeMoney.exe`

验证清单：
- [ ] 双击 exe，角色出现在桌面右下角
- [ ] 首次启动引导窗口弹出
- [ ] 配置完成后薪资面板显示数字
- [ ] 拖拽角色移动窗口，重启后位置保留
- [ ] 右键菜单所有项可用
- [ ] 设置对话框保存生效
- [ ] 鼠标悬停面板展开/收起流畅
- [ ] 透明度/缩放调节生效
- [ ] 切换角色生效（如有多个角色素材）

---

### 1.6 附录 A: v0.1 实施计划与 PRD 对照

| PRD 需求 | 实现任务 |
|---------|---------|
| F1 实时薪资计算 | Task 1.4 SalaryEngine |
| F2 桌面宠物显示 | Task 2.2 Pet 场景 + Task 3.4 Main |
| F3 角色动画系统 | Task 2.1 PetManager + Task 2.3 素材 |
| F4 薪资面板 | Task 3.1 PanelSystem + Task 3.2 Panel |
| F5 用户交互 | Task 2.2 pet.gd + Task 3.3 DragResizeSystem |
| F6 设置系统 | Task 4.1 设置对话框 |
| F7 托盘驻留 | Task 3.3（v0.1 降级为 PopupMenu） |
| F8 首次启动向导 | Task 4.2 向导 |
| 跨平台抽象层 | Task 1.2 PlatformInterface + Platform |
| 单休/双休 + 日历 | Task 1.4 `_calc_work_days` |

### 1.7 附录 B: v0.1 降级方案

| PRD 要求 | v0.1 实现 | 后续版本 |
|---------|----------|---------|
| 系统托盘图标 | PopupMenu 代替（`show_tray_menu`） | v0.2 Beta 正式实现真托盘 |
| 融入桌面模式 | 非置顶窗口（`always_on_top=false`） | v1.0 用 Progman 父窗口技巧 |
| 扁平卡通矢量素材 | 像素风占位素材 | v1.0 AI 生成扁平卡通 |
| 开机自启 | 设置项禁用占位 | v0.2 Beta 用 Windows 当前用户自启动配置实现 |
| 多角色（2-3） | 仅小猫 | v1.0 补小狗和仓鼠 |

### 1.8 v0.1 实际交付摘要

| 项目 | 实际交付 |
|------|----------|
| 运行形态 | 普通 900×500 调试窗口，DebugInputArea / DebugStatus 可见 |
| 核心业务 | 薪资计算、工作状态、Panel 展示、Panel 配置项均已实现 |
| 交互 | 单击、双击、长按、拖拽、右键菜单通过 debug 输入区和 Pet 逻辑可验证 |
| 设置 | 薪资、休息模式、上下班时间、缩放、透明度、窗口模式、Panel 项已实现 |
| 向导 | 首次启动向导和“重新运行向导”入口已实现 |
| 打包 | Windows export preset、图标、exe 导出和冒烟验证已完成 |
| 未完成 | 默认透明桌宠模式、空白穿透、真实系统托盘、关闭隐藏到托盘、开机自启、正式猫咪动画素材 |

v0.1 不再继续追求透明桌宠完整体验；这些差距已经被纳入 v0.2 Beta。

---

## 2. v0.2 Beta 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development for code changes and superpowers:verification-before-completion before claiming completion. For multi-file execution, use superpowers:subagent-driven-development when available; otherwise use superpowers:executing-plans task-by-task.

**Goal:** 在 v0.1 Beta 已可运行的基础上，完成 v0.2 Beta 桌宠窗口可用性迭代：默认透明无边框桌宠模式、配置文件 Debug 模式、角色区域稳定交互、系统托盘正式集成、开机自启正式支持、设置体验打磨和 v0.2 验证链路。

**Architecture:** 沿用 v0.1 的 Autoload 架构，但将平台能力进一步下沉到 `Platform` / `WindowsPlatform`。`main.gd` 只负责读取运行模式并协调场景节点；`DragResizeSystem` 负责菜单与窗口显隐；`SettingsDialog` 负责用户配置；系统托盘、开机自启、鼠标穿透、窗口样式等 Windows 能力必须通过 PlatformInterface 暴露，避免 UI 代码直接写 Windows 专属逻辑。

**Tech Stack:** Godot 4.7 / GDScript / Windows 平台能力（优先 Godot API；不足时通过 WindowsPlatform 封装插件、GDExtension 或轻量原生桥接）

**项目路径:** `<PROJECT_ROOT>\`

**当前执行状态:** 未开始。以下任务均为待执行计划，不能视作已经存在的代码能力。

### 2.0 v0.2 目标文件结构增量

v0.2 不重建项目结构，只在 v0.1 基础上增加平台能力、验证脚本和文档：

```
LetsMakeMoney/
├── src/
│   ├── autoload/
│   │   ├── platform.gd               # 新增托盘/自启动/穿透转发接口
│   │   ├── config.gd                 # 新增 debug_mode / auto_start / minimize_to_tray
│   │   └── drag_resize_system.gd     # 扩展托盘菜单、窗口显示隐藏、退出流程
│   ├── scenes/
│   │   ├── main/
│   │   │   ├── main.tscn             # Debug 节点保留，但桌宠模式隐藏
│   │   │   └── main.gd               # 双模式窗口启动、托盘初始化、关闭拦截
│   │   ├── pet/
│   │   │   ├── pet.tscn              # 校准小猫交互区域
│   │   │   └── pet.gd                # 回归单击/双击/长按/拖拽互斥
│   │   └── settings/
│   │       ├── settings_dialog.tscn   # 通用页新增正式自启动/托盘设置
│   │       └── settings_dialog.gd
│   └── platform/
│       ├── platform_interface.gd      # 新增托盘、自启动、鼠标穿透接口
│       ├── windows_platform.gd        # Windows 实现
│       └── native/                    # 如需 GDExtension/桥接，放在这里
├── scripts/
│   ├── verify_v02.ps1
│   └── verify_v02.gd
├── doc/
│   ├── verification/
│   │   └── v0.2.md
│   └── v0.2-asset-spike.md
└── experiments/
    └── v0.2_cat_assets/              # 素材 Spike 输出，非阻塞
```

**v0.2 模块职责边界（关键设计决策）：**
- **Platform 只做能力封装和转发**。Windows 注册表、自启动、托盘、鼠标穿透、窗口属性都在 `WindowsPlatform` 或其桥接层实现，场景脚本不得直接写注册表或调用 Windows 专属命令。
- **Main 管运行形态**。`main.gd` 读取 `debug_mode`，决定窗口尺寸、Debug UI 可见性、是否启用穿透、是否初始化托盘。
- **DragResizeSystem 管用户入口**。角色右键菜单、托盘菜单、显示/隐藏、退出保存都收敛在这里，避免 Main 和 Settings 分散处理退出流程。
- **SettingsDialog 管配置编辑**。设置页负责展示当前系统状态和保存用户选择，但写入自启动必须通过 `Platform.set_auto_start()`。
- **素材 Spike 不进入主线依赖**。素材生成失败不影响 M1-M5 的交付和验证。

---

### 2.1 里程碑 V02-M1: Debug/桌宠模式拆分

#### Task V02-M1.1: 扩展 Config 默认值与兼容加载

**Files:**
- Modify: `src/autoload/config.gd`
- Modify: `scripts/verify_m4.gd` 或新增 `scripts/verify_v02.gd`

- [ ] **Step 1: 新增 v0.2 配置默认值**

在 Config 默认值中加入：

```gdscript
"debug_mode": false,
"auto_start": false,
"minimize_to_tray": true,
```

保持现有 `window_mode`、`opacity`、`scale`、`window_x`、`window_y` 默认值不变。

推荐 `_defaults()` 结构：

```gdscript
func _defaults() -> Dictionary:
    return {
        "monthly_salary": 0.0,
        "rest_mode": "double",
        "work_start_time": "09:00",
        "work_end_time": "18:00",
        "work_hours_per_day": 8,
        "pet_id": "cat",
        "window_x": -1,
        "window_y": -1,
        "window_mode": "top",
        "opacity": 1.0,
        "scale": 1.0,
        "debug_mode": false,
        "auto_start": false,
        "minimize_to_tray": true,
        "panel_items": {
            "earnings_today": true,
            "earnings_month": true,
            "hourly_rate": true,
            "work_progress": true,
            "status": true,
        },
    }
```

- [ ] **Step 2: 兼容旧配置**

配置加载后执行一次 defaults merge：旧 `config.json` 缺少新增字段时，运行时使用默认值；保存配置时补齐字段。不得因为旧配置缺字段导致 Main 场景启动失败。

建议增加深合并逻辑，避免 `panel_items` 被浅合并覆盖：

```gdscript
func _merge_defaults(data: Dictionary, defaults: Dictionary) -> Dictionary:
    var merged := defaults.duplicate(true)
    for key in data.keys():
        if merged.has(key) and typeof(merged[key]) == TYPE_DICTIONARY and typeof(data[key]) == TYPE_DICTIONARY:
            merged[key] = _merge_defaults(data[key], merged[key])
        else:
            merged[key] = data[key]
    return merged
```

`_load()` 读取 JSON 后执行：

```gdscript
_data = _merge_defaults(parsed_data, _defaults())
```

不要在 `_load()` 中立即保存旧配置，避免用户只是运行一次就改写文件；在设置保存、退出保存或显式 `Config.save()` 时再写回补齐后的字段。

- [ ] **Step 3: 验证**

新增自动验证覆盖：
- 删除或模拟缺少 `debug_mode` 的旧配置，`Config.get_value("debug_mode", false)` 返回 `false`
- 缺少 `auto_start` 时返回 `false`
- 缺少 `minimize_to_tray` 时返回 `true`
- 保存后配置文件包含新增字段

---

#### Task V02-M1.2: 将窗口启动形态拆成桌宠模式与 Debug 模式

**Files:**
- Modify: `src/scenes/main/main.gd`
- Modify: `src/scenes/main/main.tscn`
- Modify: `src/platform/platform_interface.gd`
- Modify: `src/platform/windows_platform.gd`

- [ ] **Step 1: PlatformInterface 增加运行模式参数**

将窗口设置接口调整为可接收 debug 模式：

```gdscript
func setup_window(_window: Window, _debug_mode: bool) -> void:
    push_error("PlatformInterface.setup_window() not implemented")
```

`Platform.setup_window(window, debug_mode)` 负责转发给具体平台实现。

`src/autoload/platform.gd` 同步改为：

```gdscript
func setup_window(window: Window, debug_mode: bool = false) -> void:
    impl.setup_window(window, debug_mode)

func set_mouse_passthrough(window: Window, enabled: bool, interactive_rects: Array[Rect2i]) -> bool:
    return impl.set_mouse_passthrough(window, enabled, interactive_rects)

func setup_tray(icon_path: String) -> bool:
    return impl.setup_tray(icon_path)

func shutdown_tray() -> void:
    impl.shutdown_tray()

func set_auto_start(enabled: bool, exe_path: String) -> bool:
    return impl.set_auto_start(enabled, exe_path)
```

- [ ] **Step 2: WindowsPlatform 实现两套窗口属性**

Debug 模式：
- `borderless = false`
- `transparent_bg = false`
- `always_on_top = false`
- `unresizable = true`
- `size = Vector2i(900, 500)`
- `min_size = Vector2i(900, 500)`

桌宠模式：
- `borderless = true`
- `transparent_bg = true`
- `always_on_top = true`
- `unresizable = true`
- 窗口尺寸收紧到 Pet + Panel 所需区域，避免巨大透明矩形拦截输入

参考实现：

```gdscript
func setup_window(window: Window, debug_mode: bool) -> void:
    _ensure_config_dir()
    window.unresizable = true
    if debug_mode:
        window.borderless = false
        window.transparent_bg = false
        window.always_on_top = false
        window.size = Vector2i(900, 500)
        window.min_size = Vector2i(900, 500)
    else:
        window.borderless = true
        window.transparent_bg = true
        window.always_on_top = true
        window.size = Vector2i(360, 220)
        window.min_size = Vector2i(240, 160)
```

- [ ] **Step 3: Main 根据 Config 应用模式**

`main.gd` 启动时读取：

```gdscript
var debug_mode := bool(Config.get_value("debug_mode", false))
Platform.setup_window(get_window(), debug_mode)
```

Debug UI 节点行为：
- Debug 模式：`DebugInputArea.visible = true`，`DebugStatus.visible = true`
- 桌宠模式：`DebugInputArea.visible = false`，`DebugStatus.visible = false`

建议 Main 增加集中方法：

```gdscript
var _debug_mode := false
var _tray_ready := false

func _ready() -> void:
    _debug_mode = bool(Config.get_value("debug_mode", false))
    _setup_window()
    _apply_runtime_mode()
    _restore_position()
    _apply_scale_opacity()
    DragResizeSystem.register_window(get_window())

func _setup_window() -> void:
    Platform.setup_window(get_window(), _debug_mode)

func _apply_runtime_mode() -> void:
    debug_input_area.visible = _debug_mode
    debug_status.visible = _debug_mode
    if _debug_mode:
        Platform.set_mouse_passthrough(get_window(), false, [])
    else:
        _refresh_mouse_passthrough()
```

`_on_config_changed()` 中若 `debug_mode` 发生变化，允许提示用户重启生效；v0.2 不要求运行中热切换 debug/window 根形态。

- [ ] **Step 4: 验证**

手动验证：
- 默认无配置启动为透明桌宠模式
- 配置 `debug_mode=true` 后启动为 900×500 普通 debug 窗口
- 改回 `debug_mode=false` 后 debug UI 不可见

自动验证：
- 主场景加载时存在 Debug 节点
- 默认配置下 debug 节点不可见
- debug 配置下 debug 节点可见

---

### 2.2 里程碑 V02-M2: 透明窗口与输入穿透

#### Task V02-M2.1: 收紧桌宠窗口布局与可交互区域

**Files:**
- Modify: `src/scenes/main/main.gd`
- Modify: `src/scenes/main/main.tscn`
- Modify: `src/scenes/pet/pet.gd`
- Modify: `src/scenes/pet/pet.tscn`
- Modify: `src/scenes/panel/panel.gd`

- [ ] **Step 1: 桌宠模式使用紧凑窗口尺寸**

为 Main 定义两套尺寸：

```gdscript
const DEBUG_WINDOW_SIZE := Vector2i(900, 500)
const PET_WINDOW_SIZE := Vector2i(360, 220)
```

实际尺寸可按当前 Pet/Panel 视觉再微调，但桌宠模式不应继续使用 900×500 调试窗口。

推荐布局常量：

```gdscript
const DEBUG_WINDOW_SIZE := Vector2i(900, 500)
const PET_WINDOW_SIZE := Vector2i(360, 220)
const PET_ANCHOR := Vector2(90, 150)
const PANEL_ANCHOR_RIGHT := Vector2(170, 72)
const PANEL_ANCHOR_LEFT := Vector2(16, 72)
```

桌宠模式下 Pet 与 Panel 仍固定在窗口内，Panel 根据屏幕边缘左右切换。Debug 模式可以沿用较宽布局，便于观察文字和日志。

- [ ] **Step 2: 小猫区域作为唯一主要输入区**

Pet 场景的 Area2D / CollisionShape2D 必须覆盖当前小猫可见区域。输入逻辑优先使用 Pet 命中，不依赖 DebugInputArea。

建议 Pet 场景结构保持：

```text
Pet (Node2D)
├── AnimatedSprite2D
└── Area2D
    └── CollisionShape2D
```

`CollisionShape2D` 使用 `RectangleShape2D` 或 `CircleShape2D` 均可，但尺寸必须随当前占位小猫缩放后覆盖可见区域。若后续替换素材，先调碰撞区域再验证输入。

- [ ] **Step 3: Panel 仍可悬停展开**

桌宠模式下 Panel 仍响应鼠标悬停展开/收起；Panel 不负责触发 Pet 的 hover/click/drag。

- [ ] **Step 4: 验证**

手动验证：
- 桌宠模式只显示小猫和 Panel
- 透明空白区域明显缩小
- 小猫区域 hover、单击、双击、长按、右键仍可用
- Panel 悬停展开/离开收起仍可用

---

#### Task V02-M2.2: 实现空白区域点击穿透能力

**Files:**
- Modify: `src/platform/platform_interface.gd`
- Modify: `src/platform/windows_platform.gd`
- Modify: `src/autoload/platform.gd`
- Modify: `src/scenes/main/main.gd`

- [ ] **Step 1: 增加平台穿透接口**

```gdscript
func set_mouse_passthrough(_window: Window, _enabled: bool, _interactive_rects: Array[Rect2i]) -> bool:
    return false
```

返回值表示当前平台是否成功应用穿透。

接口语义：
- `enabled=false`：清除穿透设置，窗口恢复普通命中
- `enabled=true` 且 `interactive_rects` 非空：只有指定矩形区域接收鼠标
- 平台不支持时返回 `false`，调用方必须降级，不得抛错中断

- [ ] **Step 2: 桌宠模式启用穿透**

Main 在桌宠模式下根据 Pet 与 Panel 的可交互区域计算 `interactive_rects`，调用：

```gdscript
var ok := Platform.set_mouse_passthrough(get_window(), true, rects)
```

若返回 `false`：
- 打印 warning
- 不崩溃
- 保持收紧窗口尺寸作为降级方案

建议计算方法：

```gdscript
func _refresh_mouse_passthrough() -> void:
    if _debug_mode:
        Platform.set_mouse_passthrough(get_window(), false, [])
        return
    var rects: Array[Rect2i] = []
    rects.append(_node_rect_to_window_rect(pet))
    rects.append(_node_rect_to_window_rect(panel))
    var ok := Platform.set_mouse_passthrough(get_window(), true, rects)
    if not ok:
        push_warning("Mouse passthrough not available; using compact window fallback.")

func _node_rect_to_window_rect(node: CanvasItem) -> Rect2i:
    var rect := Rect2(node.global_position, node.get_rect().size if node is Control else Vector2(120, 120))
    return Rect2i(rect.position.round(), rect.size.round())
```

如 `Node2D` 没有 `get_rect()`，Pet 可提供 `get_interaction_rect()` 方法，由 `pet.gd` 返回本地交互矩形。

- [ ] **Step 3: Debug 模式禁用穿透**

Debug 模式必须禁用鼠标穿透，确保调试输入区可稳定点击。

- [ ] **Step 4: 验证**

手动验证：
- 桌宠模式透明空白区域尽量不拦截桌面点击
- 小猫区域仍能点击、拖拽、右键
- Debug 模式下整个 debug 输入区仍可操作

---

#### Task V02-M2.3: 回归拖拽、双击、长按手感

**Files:**
- Modify: `src/scenes/pet/pet.gd`
- Modify: `src/scenes/main/main.gd`
- Modify: `scripts/verify_v02.gd`

- [ ] **Step 1: 拖拽使用屏幕绝对位移**

拖拽窗口时只使用 `DisplayServer.mouse_get_position()` 与拖拽开始屏幕坐标的差值，避免使用局部事件相对位移导致窗口速度过快。

拖拽核心逻辑：

```gdscript
var _mouse_pressed := false
var _dragging := false
var _drag_start_window_pos := Vector2i.ZERO
var _drag_start_screen_mouse := Vector2i.ZERO

func _begin_press() -> void:
    _mouse_pressed = true
    _dragging = false
    _drag_start_window_pos = get_window().position
    _drag_start_screen_mouse = DisplayServer.mouse_get_position()

func _update_drag() -> void:
    var delta := DisplayServer.mouse_get_position() - _drag_start_screen_mouse
    if not _dragging and delta.length() >= DRAG_THRESHOLD:
        _dragging = true
    if _dragging:
        DragResizeSystem.move_window_to(_drag_start_window_pos + delta)
```

- [ ] **Step 2: 明确点击与拖拽互斥**

按下后移动超过拖拽阈值则进入拖拽，不再触发单击/双击。未超过阈值才进入点击判定。

释放鼠标时：

```gdscript
func _end_press() -> void:
    if _dragging:
        DragResizeSystem.save_position()
    else:
        _register_click()
    _mouse_pressed = false
    _dragging = false
```

- [ ] **Step 3: 双击窗口保持稳定**

双击时间窗口建议保留 `0.3s` 左右。第二次点击命中后立即触发双击反馈，并清空单击计时器。

- [ ] **Step 4: 验证**

手动验证：
- 单击触发单击反馈
- 快速双击触发双击反馈
- 长按触发长按反馈，松开恢复
- 拖拽窗口移动速度与鼠标一致

---

### 2.3 里程碑 V02-M3: 系统托盘正式集成

#### Task V02-M3.1: 扩展 PlatformInterface 托盘能力

**Files:**
- Modify: `src/platform/platform_interface.gd`
- Modify: `src/platform/windows_platform.gd`
- Modify: `src/autoload/platform.gd`
- Add if needed: `addons/` 或 `src/platform/native/` 下的 Windows 托盘桥接文件

- [ ] **Step 1: 定义托盘接口**

新增接口：

```gdscript
func is_tray_supported() -> bool:
    return false

func setup_tray(_icon_path: String) -> bool:
    return false

func update_tray_menu(_visible: bool) -> void:
    pass

func show_tray_notification(_title: String, _body: String) -> void:
    pass

func shutdown_tray() -> void:
    pass
```

`Platform` Autoload 转发接口必须完整对应：

```gdscript
func is_tray_supported() -> bool:
    return impl.is_tray_supported()

func setup_tray(icon_path: String) -> bool:
    return impl.setup_tray(icon_path)

func update_tray_menu(visible: bool) -> void:
    impl.update_tray_menu(visible)

func shutdown_tray() -> void:
    impl.shutdown_tray()
```

- [ ] **Step 2: WindowsPlatform 实现真实托盘**

优先选择稳定方式：
- Godot 4.7 可用原生 API 时优先用原生 API
- 原生 API 不足时，引入 Windows 专用插件 / GDExtension / 轻量桥接

托盘必须能显示 app icon，并支持左键、右键菜单事件。

实现选型记录要求：
- 如果使用 Godot 原生 DisplayServer 能力，在本 Task 注释中写明使用的 API 名称和 Godot 版本。
- 如果使用 GDExtension/插件，在 `doc/verification/v0.2.md` 记录安装来源、版本、构建/复制步骤。
- 如果使用轻量外部桥接进程，必须说明进程生命周期和退出清理方式；除非原生方案不可行，否则不优先使用外部进程。

托盘事件必须最终转成项目内信号或回调，不允许平台实现直接操作场景树。建议在 `Platform` 中暴露信号：

```gdscript
signal tray_toggle_requested
signal tray_settings_requested
signal tray_about_requested
signal tray_exit_requested
```

`windows_platform.gd` 收到托盘事件后，由 `platform.gd` emit 对应信号，再由 `main.gd` 或 `DragResizeSystem` 处理。

- [ ] **Step 3: 失败降级**

`setup_tray()` 失败时返回 `false`，应用继续运行：
- 保留任务栏入口
- 保留角色右键菜单
- 关闭按钮不应把窗口隐藏到不可找回状态

Main 初始化托盘建议写法：

```gdscript
func _setup_tray() -> void:
    if _debug_mode:
        _tray_ready = false
        return
    _tray_ready = Platform.setup_tray("res://icons/app_icon.ico")
    if _tray_ready:
        Platform.tray_toggle_requested.connect(_on_tray_toggle_requested)
        Platform.tray_settings_requested.connect(_open_settings)
        Platform.tray_about_requested.connect(DragResizeSystem.show_about)
        Platform.tray_exit_requested.connect(_exit_app)
    else:
        push_warning("System tray unavailable; keeping taskbar fallback.")
```

- [ ] **Step 4: 验证**

手动验证：
- 启动后 Windows 托盘区出现 LetsMakeMoney 图标
- 鼠标悬停托盘图标显示应用名
- 托盘初始化失败时应用仍能使用

---

#### Task V02-M3.2: 实现托盘菜单与窗口显隐

**Files:**
- Modify: `src/autoload/drag_resize_system.gd`
- Modify: `src/scenes/main/main.gd`
- Modify: `src/platform/windows_platform.gd`

- [ ] **Step 1: 托盘菜单结构**

托盘右键菜单：

```text
├── 显示/隐藏
├── 设置
├── 关于 LetsMakeMoney
├── ──────────
└── 退出
```

菜单 ID 建议：

```gdscript
const TRAY_ID_TOGGLE := 1
const TRAY_ID_SETTINGS := 2
const TRAY_ID_ABOUT := 3
const TRAY_ID_EXIT := 4
```

如果托盘插件只提供原生菜单 callback，则在 WindowsPlatform 内映射到上述语义事件；如果托盘插件不支持原生右键菜单，则允许用 `PopupMenu` 作为临时 UI，但托盘图标必须是真实系统托盘图标。

- [ ] **Step 2: 显示/隐藏行为**

当前窗口可见时：
- 点击“显示/隐藏”隐藏窗口
- 托盘菜单文案更新为“显示”

当前窗口隐藏时：
- 点击“显示/隐藏”恢复窗口可见
- 恢复到上次保存位置
- 托盘菜单文案更新为“隐藏”

窗口显隐统一由 DragResizeSystem 提供，避免 Main 与托盘各自写一套：

```gdscript
func set_window_visible(visible: bool) -> void:
    if _window == null:
        return
    _window.visible = visible
    if visible:
        _restore_window_if_needed()
    Platform.update_tray_menu(_window.visible)

func toggle_window_visible() -> void:
    if _window != null:
        set_window_visible(not _window.visible)
```

- [ ] **Step 3: 设置与关于**

隐藏状态下点击“设置”：
- 优先恢复窗口并打开设置
- 或直接弹出设置窗口，但必须可见可点击

“关于 LetsMakeMoney”复用现有关于窗口逻辑。

- [ ] **Step 4: 退出**

托盘菜单“退出”必须：
- 保存窗口位置
- 保存配置
- 关闭托盘资源
- 结束进程

退出流程统一封装：

```gdscript
func quit_app() -> void:
    save_position()
    Config.save()
    Platform.shutdown_tray()
    get_tree().quit()
```

角色右键菜单的“退出”和托盘菜单“退出”都必须调用这个方法，避免一个路径保存配置、另一个路径不保存。

- [ ] **Step 5: 验证**

手动验证：
- 托盘菜单所有项可点击
- 显示/隐藏来回切换稳定
- 设置可从托盘打开
- 退出后进程结束，托盘图标消失

---

#### Task V02-M3.3: 关闭按钮隐藏到托盘

**Files:**
- Modify: `src/scenes/main/main.gd`
- Modify: `src/autoload/config.gd`
- Modify: `src/autoload/drag_resize_system.gd`

- [ ] **Step 1: 拦截窗口关闭请求**

Main 监听窗口 close/request 事件。若 `minimize_to_tray=true` 且托盘可用：
- 阻止默认退出
- 隐藏窗口
- 保存当前位置

Godot 侧建议：

```gdscript
func _ready() -> void:
    get_window().close_requested.connect(_on_window_close_requested)

func _on_window_close_requested() -> void:
    if bool(Config.get_value("minimize_to_tray", true)) and _tray_ready:
        DragResizeSystem.save_position()
        DragResizeSystem.set_window_visible(false)
    else:
        DragResizeSystem.quit_app()
```

注意：如果 Godot 默认 close 行为仍会继续退出，需要在项目或窗口配置中启用 close request 回调后阻止默认退出；实现时必须实际验证。

- [ ] **Step 2: 配置控制**

若 `minimize_to_tray=false`：
- 点击关闭按钮直接保存并退出

若托盘不可用：
- 不隐藏到不可找回状态
- 允许直接退出或保留任务栏入口

- [ ] **Step 3: 验证**

手动验证：
- 默认点击关闭按钮后窗口隐藏，进程仍在
- 托盘点击“显示”后窗口恢复
- 设置 `minimize_to_tray=false` 后关闭按钮直接退出

---

### 2.4 里程碑 V02-M4: 开机自启与设置打磨

#### Task V02-M4.1: PlatformInterface 增加开机自启能力

**Files:**
- Modify: `src/platform/platform_interface.gd`
- Modify: `src/platform/windows_platform.gd`
- Modify: `src/autoload/platform.gd`

- [ ] **Step 1: 定义自启动接口**

```gdscript
func set_auto_start(_enabled: bool, _exe_path: String) -> bool:
    return false

func is_auto_start_enabled(_exe_path: String) -> bool:
    return false

func get_executable_path() -> String:
    return OS.get_executable_path()
```

`Platform` Autoload 同步转发：

```gdscript
func get_executable_path() -> String:
    return impl.get_executable_path()

func is_auto_start_enabled(exe_path: String = "") -> bool:
    if exe_path.is_empty():
        exe_path = get_executable_path()
    return impl.is_auto_start_enabled(exe_path)

func set_auto_start(enabled: bool, exe_path: String = "") -> bool:
    if exe_path.is_empty():
        exe_path = get_executable_path()
    return impl.set_auto_start(enabled, exe_path)
```

- [ ] **Step 2: Windows 当前用户自启动**

Windows 实现使用当前用户级别配置，不要求管理员权限。优先使用：

```text
HKCU\Software\Microsoft\Windows\CurrentVersion\Run
```

键名建议：`LetsMakeMoney`

值：导出的 `LetsMakeMoney.exe` 绝对路径，带引号。

WindowsPlatform 建议实现：

```gdscript
const RUN_KEY := "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
const AUTO_START_NAME := "LetsMakeMoney"

func _is_exported_app(exe_path: String) -> bool:
    return exe_path.get_file().to_lower() == "letsmakemoney.exe"

func set_auto_start(enabled: bool, exe_path: String) -> bool:
    if enabled and not _is_exported_app(exe_path):
        push_warning("Auto start requires exported LetsMakeMoney.exe.")
        return false
    if enabled:
        return _registry_set_run_value(AUTO_START_NAME, "\"%s\"" % exe_path)
    return _registry_delete_run_value(AUTO_START_NAME)
```

Godot/GDScript 没有直接注册表 API 时，允许在 WindowsPlatform 内使用安全封装的 PowerShell/`reg.exe` 调用，但必须：
- 不拼接未转义用户输入
- 只操作固定键名 `LetsMakeMoney`
- 失败时返回 `false`
- 不要求管理员权限

- [ ] **Step 3: 开发态处理**

Godot 编辑器运行时如果 `OS.get_executable_path()` 指向 Godot 编辑器或无法定位导出 exe：
- `set_auto_start(true, exe_path)` 返回 `false`
- 设置界面显示可理解提示
- 不把配置误保存为已开启

设置页提示文案建议：

```text
开机自启仅支持导出的 LetsMakeMoney.exe。当前为 Godot 编辑器运行，无法写入自启动。
```

- [ ] **Step 4: 验证**

手动验证：
- 导出 exe 运行时开启自启动，注册表出现 `LetsMakeMoney`
- 关闭自启动，注册表项移除
- 编辑器运行时开启失败有提示，不静默成功

---

#### Task V02-M4.2: 设置对话框新增正式通用项

**Files:**
- Modify: `src/scenes/settings/settings_dialog.gd`
- Modify: `src/scenes/settings/settings_dialog.tscn`
- Modify: `src/autoload/config.gd`

- [ ] **Step 1: 通用页新增/启用开关**

通用页包含：
- `开机自启` CheckButton，默认关闭
- `关闭时隐藏到托盘` CheckButton，默认开启
- `重置窗口位置` Button
- `恢复默认设置` Button

原 v0.1 “开机自启禁用态”必须变为可用控件。

建议节点结构：

```text
SettingsDialog
└── VBoxContainer
    └── TabContainer
        └── GeneralTab
            └── VBoxContainer
                ├── AutoStartCheckButton
                ├── MinimizeToTrayCheckButton
                ├── ResetWindowPositionButton
                ├── RestoreDefaultsButton
                └── GeneralMessageLabel
```

若当前设置界面是代码动态创建控件，则保持动态创建方式，不强行改 `.tscn`；但变量名应稳定：

```gdscript
var auto_start_toggle: CheckButton
var minimize_to_tray_toggle: CheckButton
var reset_position_button: Button
var restore_defaults_button: Button
var general_message_label: Label
```

- [ ] **Step 2: 加载当前系统状态**

打开设置时：
- `开机自启` 状态以 `Platform.is_auto_start_enabled(exe_path)` 为准
- `关闭时隐藏到托盘` 状态读取 `Config.minimize_to_tray`
- 缩放/透明度继续显示百分比

加载示例：

```gdscript
func _load_general_values() -> void:
    var exe_path := Platform.get_executable_path()
    auto_start_toggle.button_pressed = Platform.is_auto_start_enabled(exe_path)
    minimize_to_tray_toggle.button_pressed = bool(Config.get_value("minimize_to_tray", true))
    general_message_label.text = ""
```

- [ ] **Step 3: 保存行为**

点击保存：
- 写入 `scale`、`opacity`、`window_mode`
- 写入 `minimize_to_tray`
- 调用 `Platform.set_auto_start(auto_start_enabled, exe_path)`
- 只有自启动写入成功时才保存 `auto_start=true`
- 任一平台写入失败时显示错误提示

保存示例：

```gdscript
func _save_general_values() -> bool:
    Config.set_value("minimize_to_tray", minimize_to_tray_toggle.button_pressed)
    var desired_auto_start := auto_start_toggle.button_pressed
    var exe_path := Platform.get_executable_path()
    var ok := Platform.set_auto_start(desired_auto_start, exe_path)
    if desired_auto_start and not ok:
        general_message_label.text = "开机自启设置失败，请使用导出的 exe 再试。"
        return false
    Config.set_value("auto_start", desired_auto_start and ok)
    return true
```

`_on_confirmed()` 中如果 `_save_general_values()` 返回 `false`，不要关闭设置窗口，方便用户调整。

- [ ] **Step 4: 验证**

手动验证：
- 开机自启开关可切换
- 关闭隐藏到托盘开关可切换
- 保存后重新打开设置，状态一致
- 失败时不会出现 UI 显示已开启但系统未写入的假成功

---

#### Task V02-M4.3: 实现重置窗口位置与恢复默认设置

**Files:**
- Modify: `src/scenes/settings/settings_dialog.gd`
- Modify: `src/scenes/main/main.gd`
- Modify: `src/autoload/config.gd`
- Modify: `src/autoload/drag_resize_system.gd`

- [ ] **Step 1: 重置窗口位置**

点击“重置窗口位置”：
- 将窗口移动到当前主屏右下角
- 更新 `window_x` / `window_y`
- 调用 `Config.save()`
- 主界面立即移动

建议由 DragResizeSystem 提供：

```gdscript
func reset_window_position() -> void:
    if _window == null:
        return
    var screen := DisplayServer.screen_get_size()
    var margin := Vector2i(48, 64)
    var target := Vector2i(screen.x - _window.size.x - margin.x, screen.y - _window.size.y - margin.y)
    move_window_to(target)
    save_position()
```

SettingsDialog 按钮只调用 `DragResizeSystem.reset_window_position()`。

- [ ] **Step 2: 恢复默认设置**

恢复范围：
- `scale = 1.0`
- `opacity = 1.0`
- `window_mode = "top"`
- `window_x = -1`
- `window_y = -1`
- `auto_start = false`
- `minimize_to_tray = true`

不恢复：
- 薪资参数
- 休息模式
- 上下班时间
- 角色选择

- [ ] **Step 3: 二次确认**

“恢复默认设置”必须弹出确认，避免误点。

确认弹窗文案：

```text
恢复默认设置会重置显示、窗口位置、开机自启和托盘行为，但不会清空薪资配置。是否继续？
```

恢复逻辑建议封装到 Config：

```gdscript
func reset_display_defaults() -> void:
    set_value("scale", 1.0)
    set_value("opacity", 1.0)
    set_value("window_mode", "top")
    set_value("window_x", -1)
    set_value("window_y", -1)
    set_value("auto_start", false)
    set_value("minimize_to_tray", true)
    save()
```

SettingsDialog 在调用前先执行 `Platform.set_auto_start(false)`，确保系统状态和配置一致。

- [ ] **Step 4: 验证**

手动验证：
- 重置位置后窗口回到右下角
- 恢复默认后透明度/缩放/窗口模式恢复默认
- 薪资配置不被清空
- 自启动被关闭并同步移除系统配置

---

### 2.5 里程碑 V02-M5: 验证与打包

#### Task V02-M5.1: 新增 v0.2 自动验证脚本

**Files:**
- Add: `scripts/verify_v02.ps1`
- Add: `scripts/verify_v02.gd`
- Modify: `doc/verification/` 下对应版本验证文档（如新增 `doc/verification/v0.2.md`）

- [ ] **Step 1: PowerShell 验证入口**

`verify_v02.ps1` 接收 Godot exe 路径，默认使用当前已知路径：

```powershell
$env:LMM_GODOT_EXE
```

验证内容：
- Godot headless 加载项目
- 执行 `scripts/verify_v02.gd`
- 输出通过/失败摘要

脚本骨架：

```powershell
param(
    [string]$GodotExe = "$env:LMM_GODOT_EXE",
    [string]$ProjectPath = "<PROJECT_ROOT>"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $GodotExe)) {
    throw "Godot executable not found: $GodotExe"
}

if (-not (Test-Path $ProjectPath)) {
    throw "Project path not found: $ProjectPath"
}

& $GodotExe --headless --path $ProjectPath --script "res://scripts/verify_v02.gd"
if ($LASTEXITCODE -ne 0) {
    throw "v0.2 verification failed with exit code $LASTEXITCODE"
}

Write-Host "v0.2 verification passed"
```

- [ ] **Step 2: GDScript 自动验证**

`verify_v02.gd` 覆盖：
- Config 默认字段存在
- 旧配置缺字段时兼容
- Main 场景关键节点存在
- 默认 debug UI 不可见
- `debug_mode=true` 时 debug UI 可见
- 设置对话框含开机自启、关闭隐藏到托盘、重置位置、恢复默认控件
- Platform 暴露托盘、自启动、穿透接口

GDScript 骨架：

```gdscript
extends SceneTree

var failures: Array[String] = []

func _init() -> void:
    await process_frame
    _verify_config_defaults()
    _verify_platform_interfaces()
    _verify_main_scene()
    _verify_settings_dialog()
    if failures.is_empty():
        print("v0.2 verification passed")
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)

func _assert(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _verify_config_defaults() -> void:
    _assert(Config.get_value("debug_mode", null) != null, "missing debug_mode")
    _assert(Config.get_value("auto_start", null) != null, "missing auto_start")
    _assert(Config.get_value("minimize_to_tray", null) != null, "missing minimize_to_tray")

func _verify_platform_interfaces() -> void:
    _assert(Platform.has_method("setup_tray"), "Platform.setup_tray missing")
    _assert(Platform.has_method("set_auto_start"), "Platform.set_auto_start missing")
    _assert(Platform.has_method("set_mouse_passthrough"), "Platform.set_mouse_passthrough missing")

func _verify_main_scene() -> void:
    var scene := load("res://src/scenes/main/main.tscn")
    _assert(scene != null, "main.tscn missing")
    var main := scene.instantiate()
    root.add_child(main)
    await process_frame
    _assert(main.has_node("DebugInputArea"), "DebugInputArea missing")
    _assert(main.has_node("DebugStatus"), "DebugStatus missing")
    main.queue_free()

func _verify_settings_dialog() -> void:
    var scene := load("res://src/scenes/settings/settings_dialog.tscn")
    _assert(scene != null, "settings_dialog.tscn missing")
```

如果设置界面控件是动态创建的，验证脚本可以 instantiate 后调用 `_ready()` 再按节点名或变量导出的 `has_method()` 检查；不要只检查 `.tscn` 静态节点。

- [ ] **Step 3: 验证**

运行：

```powershell
.\scripts\verify_v02.ps1
```

预期：
- 进程退出码为 0
- 控制台无 parser/runtime 红色错误
- 输出 `v0.2 verification passed`

---

#### Task V02-M5.2: 编写 v0.2 手动验证文档

**Files:**
- Add: `doc/verification/v0.2.md`

- [ ] **Step 1: 桌宠模式验证**

文档覆盖：
- 默认启动透明无边框桌宠
- Debug UI 默认不可见
- 小猫区域 hover/单击/双击/长按/拖拽/右键
- Panel 展开/收起
- 空白区域点击穿透或降级说明

建议文档结构：

```markdown
# LetsMakeMoney v0.2 Beta 手动验证

## 环境
- Godot 版本：
- exe 路径：
- Windows 版本：
- 是否清空 `%APPDATA%\LetsMakeMoney\config.json`：

## 1. 桌宠模式
步骤：
1. 确认 `debug_mode=false` 或配置缺失
2. 启动 `build\LetsMakeMoney.exe`
3. 验证透明无边框窗口、Debug UI 不可见

结果：
- 通过/失败：
- 第一条错误：
- 截图/录屏：
```

- [ ] **Step 2: Debug 模式验证**

文档覆盖：
- 修改 `%APPDATA%\LetsMakeMoney\config.json`
- 设置 `debug_mode=true`
- 启动为普通大窗口
- DebugInputArea 和 DebugStatus 可见
- 改回 `false` 后恢复桌宠模式

- [ ] **Step 3: 托盘与自启动验证**

文档覆盖：
- 托盘图标出现
- 托盘菜单显示/隐藏/设置/关于/退出
- 关闭按钮隐藏到托盘
- 开机自启动写入/移除
- 验证注册表或启动项状态

注册表验证命令建议写入文档：

```powershell
Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" |
    Select-Object LetsMakeMoney
```

清理命令也写入文档，方便测试后恢复：

```powershell
Remove-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
    -Name "LetsMakeMoney" `
    -ErrorAction SilentlyContinue
```

---

#### Task V02-M5.3: 导出 v0.2 Beta exe 并做冒烟测试

**Files:**
- Modify if needed: `export_presets.cfg`
- Output ignored: `build/LetsMakeMoney.exe`

- [ ] **Step 1: 导出 Windows exe**

使用 Godot 4.7 导出到：

```text
<PROJECT_ROOT>\build\LetsMakeMoney.exe
```

命令行导出建议：

```powershell
& "$env:LMM_GODOT_EXE" `
    --headless `
    --path "<PROJECT_ROOT>" `
    --export-release "Windows Desktop" `
    "<PROJECT_ROOT>\build\LetsMakeMoney.exe"
```

若导出模板缺失，先在 Godot 编辑器中安装 Windows x86_64 export template。

- [ ] **Step 2: 冒烟测试**

验证清单：
- [ ] 双击 exe 默认进入桌宠模式
- [ ] 右键小猫菜单可用
- [ ] 托盘图标出现
- [ ] 关闭按钮隐藏到托盘
- [ ] 托盘退出结束进程
- [ ] 设置中开机自启可写入/移除
- [ ] `debug_mode=true` 可进入 debug 模式
- [ ] 控制台或日志无 parser/runtime 错误

测试后清理：
- 关闭开机自启，确认注册表项移除
- 关闭进程，确认托盘图标消失
- 如需重测首次启动，删除 `%APPDATA%\LetsMakeMoney\config.json`

---

### 2.6 里程碑 V02-S1: 素材 Spike（非阻塞）

#### Task V02-S1.1: 研究 SpriteCook/同类动画生成流程

**Files:**
- Add: `doc/v0.2-asset-spike.md`
- Optional output: `experiments/v0.2_cat_assets/`

- [ ] **Step 1: 记录输入素材**

记录当前认可的小猫视觉来源、路径、尺寸和用途。若使用用户提供的小猫图，记录文件路径和生成目标。

记录模板：

```markdown
## 输入素材
- 来源：
- 本地路径：
- 原始尺寸：
- 目标风格：
- 目标动作：
```

- [ ] **Step 2: 尝试生成三类动作**

优先探索：
- `idle`
- `working`
- `resting`

如果工具支持，再尝试 `hover` 和 `clicked`。

- [ ] **Step 3: 评估接入可行性**

记录：
- 帧间一致性
- 透明背景质量
- 是否适合 SpriteFrames
- 是否符合当前扁平卡通风格
- 是否值得接入 v0.2

评估表：

| 动作 | 输出路径 | 帧数 | 透明背景 | 一致性 | 是否接入 |
|------|----------|------|----------|--------|----------|
| idle | | | | | |
| working | | | | | |
| resting | | | | | |

- [ ] **Step 4: 验证**

若质量达标：
- 生成预览图/动图
- 记录 SpriteFrames 接入方案

若质量不达标：
- 文档记录失败原因
- 不阻塞 v0.2 Beta 发布

---

### 2.7 v0.2 Beta 实施计划与 PRD 对照

| PRD 需求 | 实现任务 |
|---------|---------|
| V02-G1 默认桌宠模式 | Task V02-M1.2 |
| V02-G2 角色区域交互 | Task V02-M2.1 + V02-M2.3 |
| V02-G3 空白区域穿透 | Task V02-M2.2 |
| V02-G4 Debug 配置开关 | Task V02-M1.1 + V02-M1.2 |
| V02-G5 设置体验打磨 | Task V02-M4.2 + V02-M4.3 |
| V02-G6 系统托盘正式集成 | Task V02-M3.1 + V02-M3.2 + V02-M3.3 |
| V02-G7 开机自启 | Task V02-M4.1 + V02-M4.2 |
| V02-G8 素材 Spike | Task V02-S1.1 |
| v0.2 验证与打包 | Task V02-M5.1 + V02-M5.2 + V02-M5.3 |

### 2.8 v0.2 Beta 必须完成项

以下内容是 v0.2 Beta 正式范围，不作为降级或 Spike：

- `debug_mode` 配置与桌宠/Debug 双模式
- 默认透明无边框桌宠模式
- 角色区域 hover / 单击 / 双击 / 长按 / 拖拽 / 右键菜单
- 系统托盘正式图标与托盘菜单
- 关闭按钮隐藏到托盘
- 开机自启设置写入/移除
- 设置页重置窗口位置与恢复默认设置
- v0.2 自动验证脚本和手动验证文档

以下内容可以降级或不阻塞：

- 透明空白区域完全穿透：若平台能力不足，必须收紧窗口尺寸并记录限制
- “融入桌面”真实桌面层：继续作为实验能力
- 素材更新：仅作为 Spike，质量达标才接入

---

## 3. v0.3 Beta 实施计划

> v0.3 与 v0.1 / v0.2 平级维护。本节不是 v0.2 的附录，而是一个独立版本计划：目标是把 v0.2 因 Godot 4.7 Windows 原生访问违例而关闭的桌宠系统能力，用 GDExtension / Windows 原生插件恢复为可导出、可日常使用、可降级的正式能力。

### 3.0 v0.3 目标文件结构增量

v0.3 新增文件集中在三类区域：`native/windows/` 放原生插件，`src/platform/` 和 `src/autoload/platform.gd` 放 Godot 侧桥接，`scripts/` / `doc/` / `releases/` 放验证和发布材料。

```
LetsMakeMoney/
├── native/
│   └── windows/
│       ├── README.md
│       ├── letsmakemoney_native.gdextension
│       ├── SConstruct
│       ├── src/
│       │   ├── register_types.h
│       │   ├── register_types.cpp
│       │   ├── lmm_native_bridge.h
│       │   ├── lmm_native_bridge.cpp
│       │   ├── tray_controller.h
│       │   ├── tray_controller.cpp
│       │   ├── window_controller.h
│       │   └── window_controller.cpp
│       └── bin/
│           └── win64/
│               └── letsmakemoney_native.dll
├── src/
│   ├── autoload/
│   │   ├── config.gd
│   │   └── platform.gd
│   ├── platform/
│   │   ├── platform_interface.gd
│   │   └── windows_platform.gd
│   └── scenes/
│       ├── main/main.gd
│       └── settings/settings_dialog.gd
├── scripts/
│   ├── verify_v03.gd
│   ├── verify_v03.ps1
│   └── verify_v03_export.ps1
├── doc/
│   ├── verification/
│   │   └── v0.3.md
│   ├── implementation-plan.md
│   └── progress.md
└── releases/
    ├── CHANGELOG.md
    └── v0.3-beta-notes.md
```

### 3.1 v0.3 模块职责边界

- **Native Bridge 只做平台能力，不做业务逻辑**。`LMMNativeBridge` 提供方法：托盘、透明窗口、鼠标穿透、任务栏 / Alt+Tab 控制、健康检查。它不知道薪资、宠物状态、Panel 展示，也不写业务配置。
- **WindowsPlatform 负责策略与降级**。`windows_platform.gd` 判断插件是否存在、是否健康、当前是否 editor、是否 debug 模式，决定调用 native bridge 或回退 Godot 安全路径。
- **Platform Autoload 负责信号和统一入口**。`platform.gd` 保留 `tray_toggle_requested`、`tray_settings_requested`、`tray_about_requested`、`tray_exit_requested`，v0.3 新增 native health 相关查询，但不直接写 Win32 逻辑。
- **Main 负责运行形态编排**。`main.gd` 读取 `debug_mode`、`transparent_pet_window_enabled`、`mouse_passthrough_enabled`、`system_tray_enabled`、`pure_pet_mode`，依次执行窗口、托盘、穿透、纯桌宠模式，失败时回退。
- **Settings 只负责选择与反馈**。`settings_dialog.gd` 把休息模式、窗口模式、纯桌宠模式改成清晰控件，并显示原生能力状态；它不直接调用 Win32。
- **验证脚本先保护默认值和接口，再保护导出结果**。`verify_v03.gd` 覆盖配置、接口、场景、设置控件；`verify_v03_export.ps1` 覆盖导出文件、插件文件、exe 冒烟启动。

---

### 3.2 里程碑 V03-M1: GDExtension / Native Bridge 骨架

#### Task V03-M1.1: 建立 native/windows 插件目录与构建说明

**Files:**
- Add: `native/windows/README.md`
- Add: `native/windows/SConstruct`
- Add: `native/windows/letsmakemoney_native.gdextension`
- Add: `native/windows/src/register_types.h`
- Add: `native/windows/src/register_types.cpp`
- Add: `native/windows/src/lmm_native_bridge.h`
- Add: `native/windows/src/lmm_native_bridge.cpp`

- [ ] **Step 1: 创建插件目录结构**

在仓库中创建：

```text
native/windows/
native/windows/src/
native/windows/bin/win64/
```

`native/windows/bin/win64/letsmakemoney_native.dll` 是构建产物，可以先不提交；若后续决定提交可运行 beta 二进制，需要在 `.gitignore` 中单独放行该文件。

- [ ] **Step 2: 写入 README 构建说明**

`native/windows/README.md` 内容：

```markdown
# LetsMakeMoney Windows Native Bridge

This folder contains the Windows x86_64 native bridge used by v0.3 Beta.

Responsibilities:
- System tray icon and tray menu
- Transparent borderless pet window helpers
- Mouse passthrough region helpers
- Taskbar / Alt+Tab visibility helpers for pure pet mode
- Runtime health check and safe fallback

Non-goals:
- Salary calculation
- Pet animation state
- Godot UI rendering
- Config file persistence

Build target:
- Windows x86_64
- Godot 4.7 GDExtension
- Output: `native/windows/bin/win64/letsmakemoney_native.dll`

The exported `LetsMakeMoney.exe` must include the `.gdextension` file and dll.
```

- [ ] **Step 3: 写入 gdextension 描述文件**

`native/windows/letsmakemoney_native.gdextension` 内容：

```ini
[configuration]
entry_symbol = "letsmakemoney_library_init"
compatibility_minimum = "4.3"

[libraries]
windows.debug.x86_64 = "res://native/windows/bin/win64/letsmakemoney_native.dll"
windows.release.x86_64 = "res://native/windows/bin/win64/letsmakemoney_native.dll"
```

- [ ] **Step 4: 写入 C++ 注册骨架**

`native/windows/src/register_types.h`：

```cpp
#pragma once

#include <godot_cpp/core/class_db.hpp>

void initialize_letsmakemoney_module(godot::ModuleInitializationLevel p_level);
void uninitialize_letsmakemoney_module(godot::ModuleInitializationLevel p_level);
```

`native/windows/src/register_types.cpp`：

```cpp
#include "register_types.h"
#include "lmm_native_bridge.h"

#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_letsmakemoney_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
    ClassDB::register_class<LMMNativeBridge>();
}

void uninitialize_letsmakemoney_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
}

extern "C" {
GDExtensionBool GDE_EXPORT letsmakemoney_library_init(
        GDExtensionInterfaceGetProcAddress p_get_proc_address,
        GDExtensionClassLibraryPtr p_library,
        GDExtensionInitialization *r_initialization) {
    GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
    init_obj.register_initializer(initialize_letsmakemoney_module);
    init_obj.register_terminator(uninitialize_letsmakemoney_module);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
    return init_obj.init();
}
}
```

- [ ] **Step 5: 写入 LMMNativeBridge 最小类**

`native/windows/src/lmm_native_bridge.h`：

```cpp
#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

class LMMNativeBridge : public godot::RefCounted {
    GDCLASS(LMMNativeBridge, godot::RefCounted)

protected:
    static void _bind_methods();

public:
    godot::Dictionary get_health() const;
    bool is_windows_x64() const;
    bool is_tray_supported() const;
    bool setup_tray(const godot::String &tooltip, const godot::String &icon_path);
    void update_tray_menu(bool window_visible);
    void shutdown_tray();
    bool setup_pet_window(int64_t window_handle, bool transparent, bool borderless);
    bool set_mouse_passthrough(int64_t window_handle, const godot::Array &interactive_rects);
    bool clear_mouse_passthrough(int64_t window_handle);
    bool set_taskbar_visible(int64_t window_handle, bool visible);
};
```

`native/windows/src/lmm_native_bridge.cpp`：

```cpp
#include "lmm_native_bridge.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void LMMNativeBridge::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_health"), &LMMNativeBridge::get_health);
    ClassDB::bind_method(D_METHOD("is_windows_x64"), &LMMNativeBridge::is_windows_x64);
    ClassDB::bind_method(D_METHOD("is_tray_supported"), &LMMNativeBridge::is_tray_supported);
    ClassDB::bind_method(D_METHOD("setup_tray", "tooltip", "icon_path"), &LMMNativeBridge::setup_tray);
    ClassDB::bind_method(D_METHOD("update_tray_menu", "window_visible"), &LMMNativeBridge::update_tray_menu);
    ClassDB::bind_method(D_METHOD("shutdown_tray"), &LMMNativeBridge::shutdown_tray);
    ClassDB::bind_method(D_METHOD("setup_pet_window", "window_handle", "transparent", "borderless"), &LMMNativeBridge::setup_pet_window);
    ClassDB::bind_method(D_METHOD("set_mouse_passthrough", "window_handle", "interactive_rects"), &LMMNativeBridge::set_mouse_passthrough);
    ClassDB::bind_method(D_METHOD("clear_mouse_passthrough", "window_handle"), &LMMNativeBridge::clear_mouse_passthrough);
    ClassDB::bind_method(D_METHOD("set_taskbar_visible", "window_handle", "visible"), &LMMNativeBridge::set_taskbar_visible);
}

Dictionary LMMNativeBridge::get_health() const {
    Dictionary result;
    result["loaded"] = true;
    result["windows_x64"] = is_windows_x64();
    result["tray_supported"] = is_tray_supported();
    result["last_error"] = "";
    return result;
}

bool LMMNativeBridge::is_windows_x64() const {
#if defined(_WIN64)
    return true;
#else
    return false;
#endif
}

bool LMMNativeBridge::is_tray_supported() const {
    return is_windows_x64();
}

bool LMMNativeBridge::setup_tray(const String &tooltip, const String &icon_path) {
    UtilityFunctions::print("Native tray skeleton: ", tooltip, " ", icon_path);
    return false;
}

void LMMNativeBridge::update_tray_menu(bool window_visible) {
    UtilityFunctions::print("Native tray menu skeleton: ", window_visible);
}

void LMMNativeBridge::shutdown_tray() {
    UtilityFunctions::print("Native tray shutdown skeleton");
}

bool LMMNativeBridge::setup_pet_window(int64_t window_handle, bool transparent, bool borderless) {
    UtilityFunctions::print("Native window skeleton: ", window_handle, " transparent=", transparent, " borderless=", borderless);
    return false;
}

bool LMMNativeBridge::set_mouse_passthrough(int64_t window_handle, const Array &interactive_rects) {
    UtilityFunctions::print("Native passthrough skeleton: ", window_handle, " rects=", interactive_rects.size());
    return false;
}

bool LMMNativeBridge::clear_mouse_passthrough(int64_t window_handle) {
    UtilityFunctions::print("Native passthrough clear skeleton: ", window_handle);
    return true;
}

bool LMMNativeBridge::set_taskbar_visible(int64_t window_handle, bool visible) {
    UtilityFunctions::print("Native taskbar skeleton: ", window_handle, " visible=", visible);
    return false;
}
```

- [ ] **Step 6: 验证**

运行：

```powershell
Test-Path "native\windows\letsmakemoney_native.gdextension"
Test-Path "native\windows\src\lmm_native_bridge.cpp"
```

预期：两个命令都输出 `True`。

- [ ] **Step 7: 提交**

```powershell
git add native/windows
git commit -m "chore: scaffold windows native bridge"
```

---

#### Task V03-M1.2: Godot 侧接入 native bridge 健康检查

**Files:**
- Modify: `src/platform/platform_interface.gd`
- Modify: `src/platform/windows_platform.gd`
- Modify: `src/autoload/platform.gd`
- Modify: `src/autoload/config.gd`
- Test: `scripts/verify_v03.gd`
- Test: `scripts/verify_v03.ps1`

- [ ] **Step 1: 扩展 Config v0.3 默认值**

在 `Config._defaults()` 中将 v0.2 三个安全关闭字段调整为 v0.3 目标默认值，并新增 pure/native 字段：

```gdscript
"native_integration_enabled": true,
"system_tray_enabled": true,
"mouse_passthrough_enabled": true,
"transparent_pet_window_enabled": true,
"pure_pet_mode": false,
```

`reset_display_defaults()` 的字段列表同步新增：

```gdscript
"native_integration_enabled",
"system_tray_enabled",
"mouse_passthrough_enabled",
"transparent_pet_window_enabled",
"pure_pet_mode",
```

注意：`pure_pet_mode` 默认必须是 `false`，即使 native bridge 可用也不能默认隐藏任务栏 / Alt+Tab。

- [ ] **Step 2: 扩展 PlatformInterface**

在 `src/platform/platform_interface.gd` 增加以下方法，基类全部返回安全默认值：

```gdscript
func get_native_health() -> Dictionary:
	return {
		"loaded": false,
		"windows_x64": OS.get_name() == "Windows",
		"tray_supported": false,
		"window_supported": false,
		"passthrough_supported": false,
		"taskbar_supported": false,
		"last_error": "native bridge unavailable"
	}


func get_native_window_handle(_window: Window) -> int:
	return 0


func set_taskbar_visible(_window: Window, _visible: bool) -> bool:
	return false


func can_enable_pure_pet_mode(_window: Window) -> bool:
	return false
```

- [ ] **Step 3: WindowsPlatform 加载 native bridge**

在 `src/platform/windows_platform.gd` 增加成员：

```gdscript
var _native_bridge: RefCounted = null
var _native_health: Dictionary = {}
```

新增初始化方法：

```gdscript
func _init() -> void:
	_native_bridge = _create_native_bridge()
	_native_health = _build_native_health()


func _create_native_bridge() -> RefCounted:
	if not ClassDB.class_exists("LMMNativeBridge"):
		return null
	var obj = ClassDB.instantiate("LMMNativeBridge")
	if obj is RefCounted:
		return obj
	return null


func _build_native_health() -> Dictionary:
	if _native_bridge == null:
		return {
			"loaded": false,
			"windows_x64": OS.get_name() == "Windows",
			"tray_supported": false,
			"window_supported": false,
			"passthrough_supported": false,
			"taskbar_supported": false,
			"last_error": "LMMNativeBridge class not found"
		}
	var health: Dictionary = _native_bridge.call("get_health")
	health["window_supported"] = bool(health.get("windows_x64", false))
	health["passthrough_supported"] = bool(health.get("windows_x64", false))
	health["taskbar_supported"] = bool(health.get("windows_x64", false))
	return health


func get_native_health() -> Dictionary:
	return _native_health.duplicate(true)
```

- [ ] **Step 4: Platform Autoload 转发健康检查**

在 `src/autoload/platform.gd` 增加：

```gdscript
func get_native_health() -> Dictionary:
	return impl.get_native_health()


func get_native_window_handle(window: Window) -> int:
	return impl.get_native_window_handle(window)


func set_taskbar_visible(window: Window, visible: bool) -> bool:
	return impl.set_taskbar_visible(window, visible)


func can_enable_pure_pet_mode(window: Window) -> bool:
	return impl.can_enable_pure_pet_mode(window)
```

- [ ] **Step 5: 新增 v0.3 自动验证脚本**

`scripts/verify_v03.gd` 初始内容：

```gdscript
extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var config := root.get_node_or_null("/root/Config")
	var platform := root.get_node_or_null("/root/Platform")
	_assert(config != null, "Config autoload missing")
	_assert(platform != null, "Platform autoload missing")
	if config == null or platform == null:
		_finish()
		return
	_check_config_defaults(config)
	_check_platform_api(platform)
	_finish()


func _check_config_defaults(config: Node) -> void:
	_assert(config.call("get_value", "native_integration_enabled", null) == true, "native integration should default true in v0.3")
	_assert(config.call("get_value", "system_tray_enabled", null) == true, "system tray should default true in v0.3")
	_assert(config.call("get_value", "transparent_pet_window_enabled", null) == true, "transparent pet window should default true in v0.3")
	_assert(config.call("get_value", "mouse_passthrough_enabled", null) == true, "mouse passthrough should default true in v0.3")
	_assert(config.call("get_value", "pure_pet_mode", null) == false, "pure pet mode should default false")


func _check_platform_api(platform: Node) -> void:
	for method_name in [
		"get_native_health",
		"get_native_window_handle",
		"set_taskbar_visible",
		"can_enable_pure_pet_mode",
		"setup_tray",
		"update_tray_menu",
		"shutdown_tray",
		"set_mouse_passthrough"
	]:
		_assert(platform.has_method(method_name), "Platform.%s missing" % method_name)
	var health: Dictionary = platform.call("get_native_health")
	for key in ["loaded", "windows_x64", "tray_supported", "window_supported", "passthrough_supported", "taskbar_supported", "last_error"]:
		_assert(health.has(key), "native health missing %s" % key)


func _finish() -> void:
	if _failures.is_empty():
		print("v0.3 verification passed")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
```

`scripts/verify_v03.ps1`：

```powershell
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Godot = "$env:LMM_GODOT_EXE"

if (!(Test-Path $Godot)) {
    throw "Godot executable not found: $Godot"
}

& $Godot --headless --path $ProjectRoot --script "res://scripts/verify_v03.gd"
if ($LASTEXITCODE -ne 0) {
    throw "v0.3 verification failed with exit code $LASTEXITCODE"
}
```

- [ ] **Step 6: 验证**

运行：

```powershell
.\scripts\verify_v03.ps1
```

预期：

```text
v0.3 verification passed
```

- [ ] **Step 7: 提交**

```powershell
git add src/autoload/config.gd src/platform/platform_interface.gd src/platform/windows_platform.gd src/autoload/platform.gd scripts/verify_v03.gd scripts/verify_v03.ps1
git commit -m "feat: add v0.3 native health surface"
```

---

### 3.3 里程碑 V03-M2: 真系统托盘

#### Task V03-M2.1: 原生托盘控制器

**Files:**
- Add: `native/windows/src/tray_controller.h`
- Add: `native/windows/src/tray_controller.cpp`
- Modify: `native/windows/src/lmm_native_bridge.h`
- Modify: `native/windows/src/lmm_native_bridge.cpp`
- Modify: `src/platform/windows_platform.gd`
- Modify: `src/autoload/platform.gd`
- Test: `scripts/verify_v03.gd`

- [ ] **Step 1: 新增 TrayController 接口**

`native/windows/src/tray_controller.h`：

```cpp
#pragma once

#include <windows.h>
#include <string>

class TrayController {
public:
    enum CommandId {
        COMMAND_TOGGLE = 41001,
        COMMAND_SETTINGS = 41002,
        COMMAND_ABOUT = 41003,
        COMMAND_EXIT = 41004
    };

    TrayController();
    ~TrayController();

    bool setup(HWND owner_hwnd, const std::wstring &tooltip, const std::wstring &icon_path);
    void update_menu(bool window_visible);
    void shutdown();
    bool is_ready() const;
    int poll_command();
    std::wstring last_error() const;

private:
    HWND _owner_hwnd = nullptr;
    HMENU _menu = nullptr;
    bool _ready = false;
    int _pending_command = 0;
    std::wstring _last_error;
};
```

- [ ] **Step 2: 实现托盘最小可用行为**

`tray_controller.cpp` 需要实现：

```cpp
#include "tray_controller.h"

TrayController::TrayController() {}

TrayController::~TrayController() {
    shutdown();
}

bool TrayController::setup(HWND owner_hwnd, const std::wstring &tooltip, const std::wstring &icon_path) {
    _owner_hwnd = owner_hwnd;
    _last_error.clear();
    _menu = CreatePopupMenu();
    if (_menu == nullptr) {
        _last_error = L"CreatePopupMenu failed";
        _ready = false;
        return false;
    }
    update_menu(true);

    // 具体 Shell_NotifyIconW 接入在同一任务完成：
    // - NOTIFYICONDATAW.cbSize = sizeof(NOTIFYICONDATAW)
    // - hWnd = owner_hwnd
    // - uID = 1
    // - uFlags = NIF_MESSAGE | NIF_TIP | NIF_ICON
    // - uCallbackMessage = WM_APP + 101
    // - szTip = tooltip
    // - hIcon 优先从 icon_path 加载，失败则 LoadIcon(nullptr, IDI_APPLICATION)
    // - Shell_NotifyIconW(NIM_ADD, &data)
    _ready = true;
    return true;
}

void TrayController::update_menu(bool window_visible) {
    if (_menu == nullptr) {
        return;
    }
    while (GetMenuItemCount(_menu) > 0) {
        DeleteMenu(_menu, 0, MF_BYPOSITION);
    }
    AppendMenuW(_menu, MF_STRING, COMMAND_TOGGLE, window_visible ? L"隐藏窗口" : L"显示窗口");
    AppendMenuW(_menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(_menu, MF_STRING, COMMAND_SETTINGS, L"设置");
    AppendMenuW(_menu, MF_STRING, COMMAND_ABOUT, L"关于 LetsMakeMoney");
    AppendMenuW(_menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(_menu, MF_STRING, COMMAND_EXIT, L"退出");
}

void TrayController::shutdown() {
    if (_menu != nullptr) {
        DestroyMenu(_menu);
        _menu = nullptr;
    }
    _ready = false;
}

bool TrayController::is_ready() const {
    return _ready;
}

int TrayController::poll_command() {
    int command = _pending_command;
    _pending_command = 0;
    return command;
}

std::wstring TrayController::last_error() const {
    return _last_error;
}
```

实现 Shell 图标消息时，必须把命令映射成 `COMMAND_TOGGLE`、`COMMAND_SETTINGS`、`COMMAND_ABOUT`、`COMMAND_EXIT`，供 Godot 侧轮询或信号转发。

- [ ] **Step 3: LMMNativeBridge 暴露 poll_tray_command**

在 `lmm_native_bridge.h` 增加：

```cpp
int32_t poll_tray_command();
```

在 `_bind_methods()` 增加：

```cpp
ClassDB::bind_method(D_METHOD("poll_tray_command"), &LMMNativeBridge::poll_tray_command);
```

在 `lmm_native_bridge.cpp` 增加：

```cpp
int32_t LMMNativeBridge::poll_tray_command() {
    // 托盘未初始化时返回 0。
    // COMMAND_TOGGLE / SETTINGS / ABOUT / EXIT 映射为 1 / 2 / 3 / 4。
    return 0;
}
```

后续完成 `TrayController` 持有后，把返回值映射为：

| Native command | Godot command |
|----------------|---------------|
| `COMMAND_TOGGLE` | `1` |
| `COMMAND_SETTINGS` | `2` |
| `COMMAND_ABOUT` | `3` |
| `COMMAND_EXIT` | `4` |

- [ ] **Step 4: WindowsPlatform 调用 native bridge 托盘**

在 `src/platform/windows_platform.gd` 中实现：

```gdscript
func setup_tray(icon_path: String) -> bool:
	if _native_bridge == null:
		return false
	if not bool(Config.get_value("native_integration_enabled", true)):
		return false
	if not bool(_native_health.get("tray_supported", false)):
		return false
	var hwnd := get_native_window_handle(null)
	if hwnd == 0:
		return false
	return bool(_native_bridge.call("setup_tray", "LetsMakeMoney", icon_path))


func update_tray_menu(window_visible: bool) -> void:
	if _native_bridge != null and bool(_native_health.get("tray_supported", false)):
		_native_bridge.call("update_tray_menu", window_visible)


func shutdown_tray() -> void:
	if _native_bridge != null:
		_native_bridge.call("shutdown_tray")
```

`get_native_window_handle(null)` 在 Task V03-M3.1 会正式补齐；本任务可以先保留 Godot `StatusIndicator` 旧路径作为回退，但默认不再依赖它。

- [ ] **Step 5: Platform Autoload 轮询托盘命令**

在 `platform.gd` 增加 `_process()`：

```gdscript
func _process(_delta: float) -> void:
	_poll_native_tray()


func _poll_native_tray() -> void:
	if impl == null or not impl.has_method("poll_tray_command"):
		return
	var command := int(impl.call("poll_tray_command"))
	match command:
		1:
			tray_toggle_requested.emit()
		2:
			tray_settings_requested.emit()
		3:
			tray_about_requested.emit()
		4:
			tray_exit_requested.emit()
```

同时在 `windows_platform.gd` 增加：

```gdscript
func poll_tray_command() -> int:
	if _native_bridge == null or not _native_bridge.has_method("poll_tray_command"):
		return 0
	return int(_native_bridge.call("poll_tray_command"))
```

- [ ] **Step 6: 验证**

运行自动验证：

```powershell
.\scripts\verify_v03.ps1
```

手动验证：
- 启动导出 exe。
- 任务栏通知区域出现 LetsMakeMoney 图标。
- 左键图标隐藏/显示窗口。
- 右键图标出现菜单。
- 菜单“设置”“关于”“退出”分别可用。

- [ ] **Step 7: 提交**

```powershell
git add native/windows/src src/platform/windows_platform.gd src/autoload/platform.gd scripts/verify_v03.gd
git commit -m "feat: add native system tray bridge"
```

---

#### Task V03-M2.2: Main 接入托盘健康门禁

**Files:**
- Modify: `src/scenes/main/main.gd`
- Modify: `src/autoload/drag_resize_system.gd`
- Test: `scripts/verify_v03.gd`

- [ ] **Step 1: Main 记录托盘健康状态**

在 `main.gd` 中新增：

```gdscript
var _native_health: Dictionary = {}
var _native_ready: bool = false
```

在 `_ready()` 中 `_setup_tray()` 前刷新：

```gdscript
_native_health = Platform.get_native_health()
_native_ready = bool(_native_health.get("loaded", false))
```

- [ ] **Step 2: 改造 _setup_tray()**

将 `_setup_tray()` 改成：

```gdscript
func _setup_tray() -> void:
	_tray_ready = false
	if _debug_mode:
		return
	if not bool(Config.get_value("native_integration_enabled", true)):
		return
	if not bool(Config.get_value("system_tray_enabled", true)):
		return
	if not bool(_native_health.get("tray_supported", false)):
		Platform.write_boot_log("Main._setup_tray: native tray unsupported")
		return
	_tray_ready = Platform.setup_tray("res://icons/app_icon.png")
	Platform.write_boot_log("Main._setup_tray: ready=%s" % str(_tray_ready))
	if _tray_ready:
		if not Platform.tray_toggle_requested.is_connected(_on_tray_toggle_requested):
			Platform.tray_toggle_requested.connect(_on_tray_toggle_requested)
		if not Platform.tray_settings_requested.is_connected(_open_settings):
			Platform.tray_settings_requested.connect(_open_settings)
		if not Platform.tray_about_requested.is_connected(DragResizeSystem.show_about):
			Platform.tray_about_requested.connect(DragResizeSystem.show_about)
		if not Platform.tray_exit_requested.is_connected(_exit_app):
			Platform.tray_exit_requested.connect(_exit_app)
```

- [ ] **Step 3: 保留角色右键菜单作为降级入口**

确认 `drag_resize_system.gd` 的右键菜单仍包含：

```gdscript
menu.add_item("设置", 100)
menu.add_item("关于 LetsMakeMoney", 400)
menu.add_item("退出", 500)
```

如果托盘不可用，应用仍可通过角色右键菜单退出，不允许隐藏到不可找回状态。

- [ ] **Step 4: 验证**

自动验证增加：

```gdscript
func _check_main_tray_gate() -> void:
	var script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	_assert(script.contains("native_integration_enabled"), "main should gate tray by native_integration_enabled")
	_assert(script.contains("_tray_ready = false"), "main should default tray readiness to false")
	_assert(script.contains("tray_supported"), "main should check native tray health")
```

运行：

```powershell
.\scripts\verify_v03.ps1
```

- [ ] **Step 5: 提交**

```powershell
git add src/scenes/main/main.gd src/autoload/drag_resize_system.gd scripts/verify_v03.gd
git commit -m "feat: gate tray behavior by native health"
```

---

### 3.4 里程碑 V03-M3: 透明无边框桌宠窗口

#### Task V03-M3.1: 原生窗口控制器与窗口句柄获取

**Files:**
- Add: `native/windows/src/window_controller.h`
- Add: `native/windows/src/window_controller.cpp`
- Modify: `native/windows/src/lmm_native_bridge.h`
- Modify: `native/windows/src/lmm_native_bridge.cpp`
- Modify: `src/platform/windows_platform.gd`
- Test: `scripts/verify_v03.gd`

- [ ] **Step 1: 新增 WindowController 接口**

`native/windows/src/window_controller.h`：

```cpp
#pragma once

#include <windows.h>
#include <string>
#include <vector>

struct NativeRect {
    int x;
    int y;
    int width;
    int height;
};

class WindowController {
public:
    bool setup_pet_window(HWND hwnd, bool transparent, bool borderless);
    bool set_mouse_passthrough(HWND hwnd, const std::vector<NativeRect> &interactive_rects);
    bool clear_mouse_passthrough(HWND hwnd);
    bool set_taskbar_visible(HWND hwnd, bool visible);
    std::wstring last_error() const;

private:
    std::wstring _last_error;
};
```

- [ ] **Step 2: 实现透明无边框窗口**

`window_controller.cpp` 中实现：

```cpp
#include "window_controller.h"

bool WindowController::setup_pet_window(HWND hwnd, bool transparent, bool borderless) {
    if (hwnd == nullptr) {
        _last_error = L"setup_pet_window received null hwnd";
        return false;
    }

    LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_STYLE);
    LONG_PTR ex_style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);

    if (borderless) {
        style &= ~WS_CAPTION;
        style &= ~WS_THICKFRAME;
        style &= ~WS_MINIMIZEBOX;
        style &= ~WS_MAXIMIZEBOX;
        style &= ~WS_SYSMENU;
    }

    if (transparent) {
        ex_style |= WS_EX_LAYERED;
        SetLayeredWindowAttributes(hwnd, RGB(0, 0, 0), 255, LWA_ALPHA);
    }

    SetWindowLongPtrW(hwnd, GWL_STYLE, style);
    SetWindowLongPtrW(hwnd, GWL_EXSTYLE, ex_style);
    SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
        SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED | SWP_NOACTIVATE);
    return true;
}

std::wstring WindowController::last_error() const {
    return _last_error;
}
```

注意：真正的像素级透明仍由 Godot 渲染透明背景提供；native controller 负责窗口样式和 Win32 层级设置。若该实现导致黑底或访问违例，应立即回退到 v0.2 紧凑普通窗口，不继续叠加点击穿透。

- [ ] **Step 3: WindowsPlatform 获取窗口句柄**

在 `windows_platform.gd` 实现：

```gdscript
func get_native_window_handle(window: Window) -> int:
	var target_window := window if window != null else Engine.get_main_loop().root
	if target_window == null:
		return 0
	if DisplayServer.has_method("window_get_native_handle"):
		var handle = DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, target_window.get_window_id())
		return int(handle)
	return 0
```

如果 Godot 4.7 的 handle 常量名称不同，执行时必须在 `DisplayServer` 文档或运行时错误中确认后修正；验证脚本只检查方法存在，不强行模拟 native handle。

- [ ] **Step 4: WindowsPlatform 先 Godot 后 native 设置窗口**

调整 `setup_window()`：

```gdscript
func setup_window(window: Window, debug_mode: bool = false, transparent_pet_window: bool = false) -> void:
	var config_path := get_config_path()
	if not DirAccess.dir_exists_absolute(config_path.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(config_path.get_base_dir())

	window.unresizable = true
	if debug_mode:
		window.borderless = false
		window.transparent_bg = false
		window.always_on_top = false
		window.size = DEBUG_WINDOW_SIZE
		window.min_size = DEBUG_WINDOW_SIZE
		clear_mouse_passthrough(window)
		set_taskbar_visible(window, true)
		return

	window.size = PET_WINDOW_SIZE
	window.min_size = PET_WINDOW_SIZE
	window.always_on_top = true
	window.borderless = transparent_pet_window
	window.transparent_bg = transparent_pet_window

	if transparent_pet_window and _native_bridge != null and bool(_native_health.get("window_supported", false)):
		var hwnd := get_native_window_handle(window)
		if hwnd != 0:
			var ok := bool(_native_bridge.call("setup_pet_window", hwnd, true, true))
			if not ok:
				window.borderless = false
				window.transparent_bg = false
```

- [ ] **Step 5: 验证**

自动验证增加：

```gdscript
func _check_native_window_model() -> void:
	var script := FileAccess.get_file_as_string("res://src/platform/windows_platform.gd")
	_assert(script.contains("get_native_window_handle"), "WindowsPlatform should expose native window handle")
	_assert(script.contains("setup_pet_window"), "WindowsPlatform should call native setup_pet_window")
	_assert(script.contains("transparent_pet_window"), "setup_window should keep transparent mode explicit")
```

手动验证：
- `debug_mode=false`
- `transparent_pet_window_enabled=true`
- 启动 exe
- 预期小猫和 Panel 可见，普通窗口边框不可见
- 若插件失败，预期回退普通紧凑窗口，不崩溃

- [ ] **Step 6: 提交**

```powershell
git add native/windows/src src/platform/windows_platform.gd scripts/verify_v03.gd
git commit -m "feat: add native transparent window bridge"
```

---

### 3.5 里程碑 V03-M4: 点击穿透与交互区域刷新

#### Task V03-M4.1: 原生鼠标穿透区域

**Files:**
- Modify: `native/windows/src/window_controller.cpp`
- Modify: `native/windows/src/lmm_native_bridge.cpp`
- Modify: `src/platform/windows_platform.gd`
- Modify: `src/scenes/main/main.gd`
- Test: `scripts/verify_v03.gd`

- [ ] **Step 1: WindowController 实现穿透开关**

`set_mouse_passthrough()` 规则：

- 透明空白区域穿透。
- 小猫 / Panel 区域不穿透。
- 传入空区域时返回 `false`，不启用穿透。
- 失败时记录 `last_error`，不崩溃。

建议实现方式：

```cpp
bool WindowController::set_mouse_passthrough(HWND hwnd, const std::vector<NativeRect> &interactive_rects) {
    if (hwnd == nullptr) {
        _last_error = L"set_mouse_passthrough received null hwnd";
        return false;
    }
    if (interactive_rects.empty()) {
        _last_error = L"interactive_rects is empty";
        return false;
    }

    LONG_PTR ex_style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
    ex_style |= WS_EX_LAYERED;
    SetWindowLongPtrW(hwnd, GWL_EXSTYLE, ex_style);

    // v0.3 第一版可以先用收紧窗口 + Godot MOUSE_FILTER 管控交互。
    // 真正复杂 region 需要用窗口消息命中测试或区域组合实现：
    // - 透明区域返回 HTTRANSPARENT
    // - interactive rect 返回 HTCLIENT
    // 该逻辑必须通过导出 exe 手动验证后才能视为完成。
    return true;
}
```

如果第一版无法做到完整 per-pixel hit test，不能虚假标记完成；必须在 `doc/verification/v0.3.md` 记录“穿透为区域级 / 降级实现”，并继续任务直到空白区域可点击到桌面。

- [ ] **Step 2: Main 统一计算交互区域**

在 `main.gd` 增加方法：

```gdscript
func get_interactive_rects() -> Array[Rect2]:
	var s := float(Config.get_value("scale", 1.0))
	var rects: Array[Rect2] = [
		Rect2(pet.position, PET_HIT_SIZE * s),
		Rect2(panel.position, PANEL_HIT_SIZE)
	]
	return rects
```

改造 `_apply_mouse_passthrough()`：

```gdscript
func _apply_mouse_passthrough() -> void:
	if _debug_mode:
		Platform.set_mouse_passthrough(get_window(), false, [])
		return
	if not bool(Config.get_value("native_integration_enabled", true)):
		Platform.set_mouse_passthrough(get_window(), false, [])
		return
	if not bool(Config.get_value("mouse_passthrough_enabled", true)):
		Platform.set_mouse_passthrough(get_window(), false, [])
		return
	var health := Platform.get_native_health()
	if not bool(health.get("passthrough_supported", false)):
		Platform.set_mouse_passthrough(get_window(), false, [])
		return
	var ok := Platform.set_mouse_passthrough(get_window(), true, get_interactive_rects())
	if not ok:
		Platform.write_boot_log("Main._apply_mouse_passthrough: fallback disabled")
```

- [ ] **Step 3: 刷新触发点**

确保以下位置调用 `_apply_mouse_passthrough()`：

- `_ready()` 完成 `_position_panel()` 后
- `_on_config_changed()` 处理缩放 / 透明度 / 窗口模式后
- `_position_panel()` 改变 Panel 左右上下位置后
- `_on_wizard_done()` 后
- 拖拽窗口保存位置后

为避免每帧重复 native 调用，增加缓存：

```gdscript
var _last_passthrough_rects_hash := ""

func _rects_hash(rects: Array[Rect2]) -> String:
	var parts: Array[String] = []
	for rect in rects:
		parts.append("%d,%d,%d,%d" % [int(rect.position.x), int(rect.position.y), int(rect.size.x), int(rect.size.y)])
	return "|".join(parts)
```

仅当 hash 变化时调用 native。

- [ ] **Step 4: 验证**

自动验证：

```gdscript
func _check_passthrough_model() -> void:
	var script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	_assert(script.contains("get_interactive_rects"), "main should expose interactive rect calculation")
	_assert(script.contains("_last_passthrough_rects_hash"), "main should avoid repeated native passthrough calls")
	_assert(script.contains("passthrough_supported"), "main should gate passthrough by native health")
```

手动验证：
- 空白区域点击能落到桌面或下层窗口。
- 小猫仍可 hover / 单击 / 双击 / 长按 / 拖拽。
- Panel 仍可 hover 展开。
- 打开设置窗口后设置窗口可点击。
- `debug_mode=true` 时穿透关闭。

- [ ] **Step 5: 提交**

```powershell
git add native/windows/src src/platform/windows_platform.gd src/scenes/main/main.gd scripts/verify_v03.gd
git commit -m "feat: add native mouse passthrough model"
```

---

### 3.6 里程碑 V03-M5: 关闭隐藏到托盘与纯桌宠模式

#### Task V03-M5.1: 关闭按钮隐藏到托盘的健康门禁

**Files:**
- Modify: `src/scenes/main/main.gd`
- Modify: `src/autoload/drag_resize_system.gd`
- Test: `scripts/verify_v03.gd`

- [ ] **Step 1: Main 增加托盘可找回判断**

在 `main.gd` 增加：

```gdscript
func can_hide_to_tray() -> bool:
	return bool(Config.get_value("minimize_to_tray", true)) and _tray_ready
```

改造 `_on_window_close_requested()`：

```gdscript
func _on_window_close_requested() -> void:
	if can_hide_to_tray():
		DragResizeSystem.set_window_visible(false)
		Platform.update_tray_menu(false)
		return
	_exit_app()
```

- [ ] **Step 2: 隐藏前保存位置**

在 `DragResizeSystem.set_window_visible(false)` 前确保保存：

```gdscript
if not visible:
	save_position()
```

这样关闭隐藏到托盘后，下次恢复/退出都不会丢失窗口坐标。

- [ ] **Step 3: 验证**

自动验证：

```gdscript
func _check_close_to_tray_gate() -> void:
	var script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	_assert(script.contains("func can_hide_to_tray"), "main should expose can_hide_to_tray")
	_assert(script.contains("and _tray_ready"), "hide-to-tray should require tray readiness")
```

手动验证：
- 托盘正常时，点击关闭按钮隐藏窗口。
- 托盘显示/隐藏可恢复窗口。
- 托盘不可用时，点击关闭按钮直接退出或保留任务栏入口，不丢窗口。

- [ ] **Step 4: 提交**

```powershell
git add src/scenes/main/main.gd src/autoload/drag_resize_system.gd scripts/verify_v03.gd
git commit -m "feat: gate close-to-tray by tray readiness"
```

---

#### Task V03-M5.2: 纯桌宠模式隐藏任务栏 / Alt+Tab

**Files:**
- Modify: `native/windows/src/window_controller.cpp`
- Modify: `native/windows/src/lmm_native_bridge.cpp`
- Modify: `src/platform/windows_platform.gd`
- Modify: `src/scenes/main/main.gd`
- Test: `scripts/verify_v03.gd`

- [ ] **Step 1: WindowController 实现任务栏入口控制**

`set_taskbar_visible()` 建议逻辑：

```cpp
bool WindowController::set_taskbar_visible(HWND hwnd, bool visible) {
    if (hwnd == nullptr) {
        _last_error = L"set_taskbar_visible received null hwnd";
        return false;
    }
    LONG_PTR ex_style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
    if (visible) {
        ex_style &= ~WS_EX_TOOLWINDOW;
        ex_style |= WS_EX_APPWINDOW;
    } else {
        ex_style &= ~WS_EX_APPWINDOW;
        ex_style |= WS_EX_TOOLWINDOW;
    }
    SetWindowLongPtrW(hwnd, GWL_EXSTYLE, ex_style);
    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
        SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED | SWP_NOACTIVATE);
    return true;
}
```

纯桌宠模式只能在托盘健康时启用。若任务栏隐藏失败，必须返回 `false`，Godot 侧把 `pure_pet_mode` 改回 `false`。

- [ ] **Step 2: WindowsPlatform 实现 can_enable_pure_pet_mode()**

```gdscript
func set_taskbar_visible(window: Window, visible: bool) -> bool:
	if _native_bridge == null:
		return false
	if not bool(_native_health.get("taskbar_supported", false)):
		return false
	var hwnd := get_native_window_handle(window)
	if hwnd == 0:
		return false
	return bool(_native_bridge.call("set_taskbar_visible", hwnd, visible))


func can_enable_pure_pet_mode(window: Window) -> bool:
	if _native_bridge == null:
		return false
	if not bool(_native_health.get("taskbar_supported", false)):
		return false
	if not bool(_native_health.get("tray_supported", false)):
		return false
	return get_native_window_handle(window) != 0
```

- [ ] **Step 3: Main 应用纯桌宠模式**

在 `main.gd` 增加：

```gdscript
func _apply_pure_pet_mode() -> void:
	if _debug_mode:
		Platform.set_taskbar_visible(get_window(), true)
		return
	var desired := bool(Config.get_value("pure_pet_mode", false))
	if not desired:
		Platform.set_taskbar_visible(get_window(), true)
		return
	if not _tray_ready or not Platform.can_enable_pure_pet_mode(get_window()):
		Config.set_value("pure_pet_mode", false)
		Platform.set_taskbar_visible(get_window(), true)
		Platform.write_boot_log("Main._apply_pure_pet_mode: disabled because tray/native health failed")
		return
	var ok := Platform.set_taskbar_visible(get_window(), false)
	if not ok:
		Config.set_value("pure_pet_mode", false)
		Platform.set_taskbar_visible(get_window(), true)
```

调用点：
- `_ready()` 中 `_setup_tray()` 后
- `_on_config_changed()` 后
- `_reapply_runtime_mode_after_popups()` 后
- `_exit_app()` 前恢复 `Platform.set_taskbar_visible(get_window(), true)`

- [ ] **Step 4: 验证**

自动验证：

```gdscript
func _check_pure_pet_mode_gate() -> void:
	var script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	_assert(script.contains("_apply_pure_pet_mode"), "main should apply pure pet mode")
	_assert(script.contains("not _tray_ready"), "pure pet mode should require tray readiness")
	_assert(script.contains("Config.set_value(\"pure_pet_mode\", false)"), "pure pet mode should auto-disable on failure")
```

手动验证：
- 默认启动保留任务栏 / Alt+Tab。
- 托盘健康后开启纯桌宠模式，任务栏 / Alt+Tab 入口隐藏。
- 通过托盘显示/隐藏仍能找回窗口。
- 关闭托盘或 native health 失败时，纯桌宠模式自动关闭，任务栏入口恢复。

- [ ] **Step 5: 提交**

```powershell
git add native/windows/src src/platform/windows_platform.gd src/scenes/main/main.gd scripts/verify_v03.gd
git commit -m "feat: add recoverable pure pet mode"
```

---

### 3.7 里程碑 V03-M6: 设置体验与配置迁移

#### Task V03-M6.1: 休息模式与窗口模式改为明确选择控件

**Files:**
- Modify: `src/scenes/settings/settings_dialog.gd`
- Modify: `scripts/verify_v03.gd`

- [ ] **Step 1: 替换休息模式 CheckButton**

将：

```gdscript
var rest_mode_toggle: CheckButton
```

替换为：

```gdscript
var rest_mode_option: OptionButton
```

在 `_build_salary_tab()` 中替换 UI：

```gdscript
_add_label(box, "休息模式")
rest_mode_option = OptionButton.new()
rest_mode_option.add_item("双休", 0)
rest_mode_option.add_item("单休", 1)
box.add_child(rest_mode_option)
```

加载值：

```gdscript
var rm := String(Config.get_value("rest_mode", "double"))
rest_mode_option.select(1 if rm == "single" else 0)
```

保存值：

```gdscript
Config.set_value("rest_mode", "single" if rest_mode_option.selected == 1 else "double")
```

- [ ] **Step 2: 替换窗口模式 CheckButton**

将：

```gdscript
var window_mode_toggle: CheckButton
```

替换为：

```gdscript
var window_mode_option: OptionButton
var pure_pet_mode_toggle: CheckButton
var native_status_label: Label
```

在 `_build_display_tab()` 中替换：

```gdscript
_add_label(box, "窗口模式")
window_mode_option = OptionButton.new()
window_mode_option.add_item("置顶悬浮", 0)
window_mode_option.add_item("融入桌面（实验）", 1)
box.add_child(window_mode_option)

pure_pet_mode_toggle = CheckButton.new()
pure_pet_mode_toggle.text = "纯桌宠模式（隐藏任务栏 / Alt+Tab，需托盘可用）"
box.add_child(pure_pet_mode_toggle)

native_status_label = Label.new()
native_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
native_status_label.custom_minimum_size = Vector2(0, 48)
box.add_child(native_status_label)
```

加载值：

```gdscript
var wm := String(Config.get_value("window_mode", "top"))
window_mode_option.select(1 if wm == "embed" else 0)
pure_pet_mode_toggle.button_pressed = bool(Config.get_value("pure_pet_mode", false))
_update_native_status_label()
```

保存值：

```gdscript
Config.set_value("window_mode", "embed" if window_mode_option.selected == 1 else "top")
Config.set_value("pure_pet_mode", pure_pet_mode_toggle.button_pressed)
```

- [ ] **Step 3: 增加原生状态文案**

```gdscript
func _update_native_status_label() -> void:
	if native_status_label == null:
		return
	var health := Platform.get_native_health()
	var tray_text := "可用" if bool(health.get("tray_supported", false)) else "不可用"
	var pass_text := "可用" if bool(health.get("passthrough_supported", false)) else "不可用"
	var taskbar_text := "可用" if bool(health.get("taskbar_supported", false)) else "不可用"
	native_status_label.text = "原生能力：托盘 %s，点击穿透 %s，纯桌宠 %s。" % [tray_text, pass_text, taskbar_text]
```

如果 `Platform.can_enable_pure_pet_mode(get_window())` 为 `false`，则：

```gdscript
pure_pet_mode_toggle.disabled = true
pure_pet_mode_toggle.button_pressed = false
```

- [ ] **Step 4: 验证**

自动验证：

```gdscript
func _check_settings_v03_controls() -> void:
	var script := FileAccess.get_file_as_string("res://src/scenes/settings/settings_dialog.gd")
	_assert(script.contains("rest_mode_option"), "settings should use OptionButton for rest mode")
	_assert(script.contains("window_mode_option"), "settings should use OptionButton for window mode")
	_assert(script.contains("pure_pet_mode_toggle"), "settings should expose pure pet mode")
	_assert(script.contains("_update_native_status_label"), "settings should show native status")
	_assert(not script.contains("rest_mode_toggle"), "rest mode CheckButton should be removed")
```

手动验证：
- 休息模式能打开选择项并保存。
- 窗口模式能打开选择项并保存。
- 纯桌宠模式在托盘不可用时禁用。
- 原生能力状态显示可理解中文。

- [ ] **Step 5: 提交**

```powershell
git add src/scenes/settings/settings_dialog.gd scripts/verify_v03.gd
git commit -m "feat: clarify v0.3 settings controls"
```

---

#### Task V03-M6.2: 配置迁移与恢复默认范围

**Files:**
- Modify: `src/autoload/config.gd`
- Modify: `scripts/verify_v03.gd`

- [ ] **Step 1: 增加配置版本字段**

默认值新增：

```gdscript
"config_version": 3,
```

`merge_with_defaults()` 后，如果旧配置没有 `config_version`，应保留用户已有薪资和显示设置，同时填入 v0.3 默认字段。

- [ ] **Step 2: 保证 reset_display_defaults() 不清薪资**

恢复默认仅重置：

```gdscript
[
	"window_x",
	"window_y",
	"window_mode",
	"debug_mode",
	"auto_start",
	"minimize_to_tray",
	"native_integration_enabled",
	"system_tray_enabled",
	"mouse_passthrough_enabled",
	"transparent_pet_window_enabled",
	"pure_pet_mode",
	"opacity",
	"scale"
]
```

不得重置：

```text
monthly_salary
rest_mode
work_start_time
work_end_time
work_hours_per_day
pet_id
panel_items
```

- [ ] **Step 3: 验证旧配置迁移**

`verify_v03.gd` 增加：

```gdscript
func _check_v03_config_migration(config: Node) -> void:
	var old_config := {
		"monthly_salary": 18888,
		"window_mode": "embed",
		"scale": 1.25,
		"panel_items": {
			"earnings_today": false
		}
	}
	var merged: Dictionary = config.call("merge_with_defaults", old_config)
	_assert(merged.get("monthly_salary") == 18888, "migration should preserve salary")
	_assert(merged.get("window_mode") == "embed", "migration should preserve window mode")
	_assert(merged.get("scale") == 1.25, "migration should preserve scale")
	_assert(merged.get("native_integration_enabled") == true, "migration should add native integration")
	_assert(merged.get("pure_pet_mode") == false, "migration should add pure pet mode default false")
	_assert(merged.get("panel_items", {}).get("earnings_today") == false, "migration should preserve nested panel item")
	_assert(merged.get("panel_items", {}).has("earnings_month"), "migration should fill nested panel defaults")
```

- [ ] **Step 4: 验证**

运行：

```powershell
.\scripts\verify_v03.ps1
```

预期：

```text
v0.3 verification passed
```

- [ ] **Step 5: 提交**

```powershell
git add src/autoload/config.gd scripts/verify_v03.gd
git commit -m "feat: add v0.3 config migration"
```

---

### 3.8 里程碑 V03-M7: 验证、发布与文档

#### Task V03-M7.1: v0.3 手动验证文档

**Files:**
- Add: `doc/verification/v0.3.md`

- [ ] **Step 1: 写入可标注手动验证模板**

`doc/verification/v0.3.md` 必须使用可勾选、可写备注的格式：

```markdown
# LetsMakeMoney v0.3 Beta 手动验证

## 基础信息

| 项目 | 记录 |
|------|------|
| 验证日期 | |
| Windows 版本 | |
| Godot 版本 | 4.7 stable |
| exe 路径 | `<PROJECT_ROOT>\build\LetsMakeMoney.exe` |
| 配置路径 | `%APPDATA%\LetsMakeMoney\config.json` |
| 是否清空旧配置 | 是 / 否 |
| 验证结论 | 通过 / 阻塞 / 需优化 |

## V03-M2 真系统托盘

| 编号 | 步骤 | 预期 | 结果 | 备注 |
|------|------|------|------|------|
| V03-MAN-001 | 双击启动 exe | 托盘出现 LetsMakeMoney 图标 | ☐ 通过 ☐ 失败 | |
| V03-MAN-002 | 左键点击托盘图标 | 窗口隐藏/显示切换 | ☐ 通过 ☐ 失败 | |
| V03-MAN-003 | 右键点击托盘图标 | 出现托盘菜单 | ☐ 通过 ☐ 失败 | |
| V03-MAN-004 | 点击托盘菜单“设置” | 设置窗口打开且可点击 | ☐ 通过 ☐ 失败 | |
| V03-MAN-005 | 点击托盘菜单“关于” | 关于窗口显示 | ☐ 通过 ☐ 失败 | |
| V03-MAN-006 | 点击托盘菜单“退出” | 进程退出，托盘图标消失 | ☐ 通过 ☐ 失败 | |

## V03-M3 透明无边框窗口

| 编号 | 步骤 | 预期 | 结果 | 备注 |
|------|------|------|------|------|
| V03-MAN-020 | `debug_mode=false` 启动 exe | 无普通窗口边框 | ☐ 通过 ☐ 失败 | |
| V03-MAN-021 | 观察窗口背景 | 小猫/Panel 外没有明显窗口背景 | ☐ 通过 ☐ 失败 | |
| V03-MAN-022 | 打开设置窗口 | 设置窗口不受透明影响 | ☐ 通过 ☐ 失败 | |

## V03-M4 点击穿透

| 编号 | 步骤 | 预期 | 结果 | 备注 |
|------|------|------|------|------|
| V03-MAN-040 | 点击小猫外透明区域 | 点击落到桌面或下层窗口 | ☐ 通过 ☐ 失败 | |
| V03-MAN-041 | 点击小猫 | 单击反馈正常 | ☐ 通过 ☐ 失败 | |
| V03-MAN-042 | 双击小猫 | 双击反馈正常 | ☐ 通过 ☐ 失败 | |
| V03-MAN-043 | 长按小猫 | 长按反馈正常，松开恢复 | ☐ 通过 ☐ 失败 | |
| V03-MAN-044 | 拖拽小猫 | 窗口跟随鼠标，不加速 | ☐ 通过 ☐ 失败 | |
| V03-MAN-045 | 悬停 Panel | Panel 展开/收起正常 | ☐ 通过 ☐ 失败 | |

## V03-M5 关闭隐藏与纯桌宠模式

| 编号 | 步骤 | 预期 | 结果 | 备注 |
|------|------|------|------|------|
| V03-MAN-060 | 点击窗口关闭按钮 | 托盘健康时隐藏到托盘 | ☐ 通过 ☐ 失败 | |
| V03-MAN-061 | 托盘显示窗口 | 窗口恢复到上次位置 | ☐ 通过 ☐ 失败 | |
| V03-MAN-062 | 默认启动检查任务栏/Alt+Tab | 默认仍可找回 | ☐ 通过 ☐ 失败 | |
| V03-MAN-063 | 开启纯桌宠模式 | 任务栏/Alt+Tab 隐藏 | ☐ 通过 ☐ 失败 | |
| V03-MAN-064 | 纯桌宠模式下从托盘恢复 | 窗口可找回 | ☐ 通过 ☐ 失败 | |

## 错误记录

```text
问题编号：
第一条错误：
复现步骤：
期望行为：
实际行为：
截图/录屏：
```
```

- [ ] **Step 2: 验证**

打开文档，确认每个表格都有“结果”和“备注”列，用户可以直接标注。

- [ ] **Step 3: 提交**

```powershell
git add doc/verification/v0.3.md
git commit -m "docs: add v0.3 manual verification checklist"
```

---

#### Task V03-M7.2: 导出验证与 release notes

**Files:**
- Add: `scripts/verify_v03_export.ps1`
- Add: `releases/CHANGELOG.md`
- Add: `releases/v0.3-beta-notes.md`
- Modify: `export_presets.cfg` if native plugin export inclusion requires changes
- Modify: `doc/progress.md`

- [ ] **Step 1: 新增导出验证脚本**

`scripts/verify_v03_export.ps1`：

```powershell
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Exe = Join-Path $ProjectRoot "build\LetsMakeMoney.exe"
$GDExtension = Join-Path $ProjectRoot "native\windows\letsmakemoney_native.gdextension"
$Dll = Join-Path $ProjectRoot "native\windows\bin\win64\letsmakemoney_native.dll"

if (!(Test-Path $Exe)) {
    throw "Missing exported exe: $Exe"
}
if (!(Test-Path $GDExtension)) {
    throw "Missing gdextension file: $GDExtension"
}
if (!(Test-Path $Dll)) {
    throw "Missing native dll: $Dll"
}

$process = Start-Process -FilePath $Exe -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 3
if ($process.HasExited) {
    throw "LetsMakeMoney.exe exited during smoke test with code $($process.ExitCode)"
}
$process.CloseMainWindow() | Out-Null
Start-Sleep -Seconds 2
if (!$process.HasExited) {
    $process.Kill()
}
Write-Host "v0.3 export smoke passed"
```

- [ ] **Step 2: 新增 CHANGELOG**

`releases/CHANGELOG.md`：

```markdown
# Changelog

## v0.3 Beta - Desktop Native Capability Repair

### Added
- Windows x86_64 native bridge for desktop pet capabilities.
- True system tray icon and menu.
- Transparent borderless pet window support.
- Mouse passthrough for transparent blank area.
- Close-to-tray behavior gated by tray health.
- Recoverable pure pet mode.
- v0.3 manual verification checklist and export smoke script.

### Changed
- Settings mode controls are clearer: rest mode and window mode use explicit selection controls.
- Native capability status is visible in settings.

### Deferred
- Orange cat animation polish is moved to v0.4.
- macOS / Linux native implementations are not included in v0.3.
```

- [ ] **Step 3: 新增 v0.3 release notes**

`releases/v0.3-beta-notes.md`：

```markdown
# LetsMakeMoney v0.3 Beta Release Notes

v0.3 Beta focuses on restoring the real desktop pet experience on Windows x86_64.

## Must Verify
- Exported exe starts without native read access violation.
- Tray icon and tray menu work.
- Transparent borderless window works.
- Blank transparent area clicks through.
- Close button hides to tray only when tray is healthy.
- Pure pet mode can hide taskbar / Alt+Tab and remains recoverable from tray.

## Known Boundaries
- Animation polish is not part of v0.3.
- macOS / Linux native behavior is not implemented.
- Pure pet mode defaults to off for recoverability.
```

- [ ] **Step 4: 更新 progress**

在 `doc/progress.md` 的 v0.3 区域加入模块清单：

```markdown
## v0.3 Beta - 桌宠原生能力修复版

| 模块 | 状态 | 备注 |
|------|------|------|
| V03-M1 Native Bridge 骨架 | 待开始 | GDExtension / native health |
| V03-M2 真系统托盘 | 待开始 | 托盘图标、菜单、显示隐藏、退出 |
| V03-M3 透明无边框窗口 | 待开始 | 失败回退 v0.2 紧凑窗口 |
| V03-M4 点击穿透 | 待开始 | 空白区域穿透，小猫/Panel 保持可交互 |
| V03-M5 关闭隐藏与纯桌宠模式 | 待开始 | 托盘健康门禁 |
| V03-M6 设置体验与配置迁移 | 待开始 | OptionButton、状态提示、v0.3 默认值 |
| V03-M7 验证与发布 | 待开始 | 自动验证、手动验证、release notes |
```

- [ ] **Step 5: 验证**

运行：

```powershell
.\scripts\verify_v03.ps1
.\scripts\verify_v03_export.ps1
```

预期：

```text
v0.3 verification passed
v0.3 export smoke passed
```

- [ ] **Step 6: 提交**

```powershell
git add scripts/verify_v03_export.ps1 releases doc/progress.md export_presets.cfg
git commit -m "docs: add v0.3 release verification"
```

---

### 3.9 v0.3 Beta 实施计划与 PRD 对照

| PRD 需求 | 实现任务 |
|---------|---------|
| V03-G1 原生能力桥接 | Task V03-M1.1 + V03-M1.2 |
| V03-G2 真系统托盘 | Task V03-M2.1 + V03-M2.2 |
| V03-G3 透明无边框桌宠窗口 | Task V03-M3.1 |
| V03-G4 空白区域点击穿透 | Task V03-M4.1 |
| V03-G5 关闭隐藏到托盘 | Task V03-M5.1 |
| V03-G6 可找回优先的纯桌宠模式 | Task V03-M5.2 |
| V03-G7 设置体验修正 | Task V03-M6.1 + V03-M6.2 |
| V03-G8 文档与发布整理 | Task V03-M7.1 + V03-M7.2 |
| v0.4 动画前置说明 | 不进入 v0.3；在 release notes 和 progress 中标记为后续 |

### 3.10 v0.3 Beta 必须完成项

以下内容是 v0.3 Beta 正式范围，不作为降级或 Spike：

- Windows x86_64 GDExtension / 原生插件可加载，并提供健康检查。
- 插件随导出 exe 发布，用户不需要额外安装。
- 真系统托盘图标和菜单可用。
- 托盘左键显示/隐藏，右键菜单可打开设置、关于和退出。
- 点击关闭按钮时，在托盘健康状态下隐藏到托盘。
- 托盘不可用时禁止隐藏到不可找回状态。
- `debug_mode=false` 时可进入透明无边框桌宠窗口。
- 透明空白区域点击尽量穿透到桌面或下层窗口。
- 小猫、Panel、菜单、设置窗口保持可交互。
- 默认保留任务栏 / Alt+Tab。
- 纯桌宠模式只能在托盘健康时手动开启。
- 纯桌宠模式失败时自动恢复任务栏 / Alt+Tab。
- 休息模式、窗口模式等模式类设置改为明确选择控件。
- `native_integration_enabled`、`pure_pet_mode` 等 v0.3 配置字段兼容旧配置。
- v0.3 自动验证、手动验证、导出验证、release notes / changelog 全部完成。

以下内容明确不进入 v0.3：

- 橘猫动画打磨、更多表情、更多动作帧。
- macOS / Linux 原生托盘、穿透、任务栏隐藏实现。
- 多角色系统、多角色同屏、角色商店。
- 云同步、统计报表、账号系统、多语言。
- 完整 UI 视觉重做。

### 3.11 v0.3 风险控制与回退要求

| 风险 | 必须执行的回退 |
|------|----------------|
| native bridge 加载失败 | `native_integration_enabled` 视为不可用，回退 v0.2 紧凑窗口，保留任务栏入口 |
| 托盘初始化失败 | `_tray_ready=false`，关闭按钮直接退出或保留任务栏入口，纯桌宠模式禁用 |
| 透明窗口初始化失败 | `window.borderless=false`、`window.transparent_bg=false`，继续显示紧凑普通窗口 |
| 点击穿透失败 | 清空穿透区域，保留小猫和 Panel 交互，不阻塞设置/退出 |
| 纯桌宠模式失败 | 自动 `Config.set_value("pure_pet_mode", false)` 并恢复任务栏 / Alt+Tab |
| 设置窗口不可点击 | Debug 模式禁用穿透；设置窗口始终用普通可点击窗口 |
| 导出缺少 dll | `verify_v03_export.ps1` 阻塞发布 |

### 3.12 v0.3 完成定义

v0.3 Beta 只有在以下条件全部满足后才能打 tag：

- [x] `.\scripts\verify_v02.ps1` 仍通过，确认 v0.2 回归未破坏。
- [x] `.\scripts\verify_v03.ps1` 通过。
- [x] `.\scripts\verify_v03_export.ps1` 通过。
- [x] 用户完成 `doc/verification/v0.3.md` 并未记录阻塞问题。
- [x] `doc/progress.md` 更新 v0.3 每个模块状态。
- [x] `releases/CHANGELOG.md` 和 `releases/v0.3-beta-notes.md` 更新。
- [x] `build\LetsMakeMoney.exe` 可启动，无 native read 访问违例。
- [x] GitHub `main` 包含 v0.3 实现提交。
- [x] 创建并推送 `v0.3beta` tag。


## 4. v0.4 Beta 实施计划

> v0.4 与 v0.1 / v0.2 / v0.3 平级维护。本节不是 v0.3 的附录，而是一个独立版本计划：目标是在 v0.3 已经恢复 Windows 原生桌宠能力的基础上，把动画、交互、窗口命中区、Panel、设置、性能和发布包统一打磨为更适合日常常驻桌面的体验。

v0.4 的默认体验方向采用“温暖陪伴型”。这不是主题系统，也不是多主题切换能力，而是本版本默认视觉、动效、文案和反馈的统一方向：应用仍然围绕薪资和赚钱反馈，但整体应更柔和、可靠、低压力，让用户愿意长期把小猫放在桌面上。

### 4.0 v0.4 目标文件结构增量

v0.4 新增和修改文件集中在五类区域：`doc/prototypes/` 放高保真原型与体验规格，`assets/pets/cat/` 放橘猫 v2 动画素材，`src/scenes/` 与 `src/autoload/` 放动画、交互、Panel、设置和窗口编排，`scripts/` 放 v0.4 自动验证，`releases/` 放正式 Zip beta 发布说明与清单。

```text
LetsMakeMoney/
├── assets/
│   └── pets/
│       └── cat/
│           ├── cat_resource.tres
│           ├── cat_sprite_frames.tres
│           └── orange_v2/
│               ├── idle/
│               ├── working/
│               ├── resting/
│               ├── clicked_hold/
│               ├── idle_clicked_single/
│               ├── idle_clicked_double/
│               ├── working_clicked_single/
│               ├── working_clicked_double/
│               ├── resting_clicked_single/
│               └── resting_clicked_double/
├── doc/
│   ├── prototypes/
│   │   ├── index.html
│   │   └── prototype-spec.md
│   ├── verification/
│   │   └── v0.4.md
│   ├── v0.4-ui-polish-spec.md
│   ├── v0.4-animation-spec.md
│   ├── implementation-plan.md
│   └── progress.md
├── scripts/
│   ├── verify_v04.gd
│   ├── verify_v04.ps1
│   └── package_v04.ps1
├── src/
│   ├── autoload/
│   │   ├── config.gd
│   │   ├── pet_manager.gd
│   │   ├── platform.gd
│   │   └── debug_logger.gd
│   ├── platform/
│   │   └── windows_platform.gd
│   └── scenes/
│       ├── main/main.gd
│       ├── panel/panel.gd
│       ├── pet/pet.gd
│       └── settings/settings_dialog.gd
└── releases/
    ├── CHANGELOG.md
    ├── v0.4-beta-notes.md
    └── v0.4/
        ├── manifest.json
        ├── checksums.txt
        └── LetsMakeMoney-v0.4-beta-windows-x86_64.zip
```

`assets/pets/cat/orange_v2/`、`scripts/package_v04.ps1` 和 `releases/v0.4/` 是 v0.4 目标结构，具体是否创建取决于对应里程碑是否进入实现。本次计划撰写只要求更新 `doc/implementation-plan.md`。

### 4.1 v0.4 模块职责边界

- **Prototype 负责体验方向，不负责运行逻辑**。`doc/prototypes/index.html` 和 `doc/prototypes/prototype-spec.md` 用来确认默认温暖陪伴方向、Panel 状态、设置页状态、托盘找回和发布包说明，不直接决定 Godot 节点结构。
- **UI Polish Spec 负责默认视觉与交互细节，不负责主题系统**。`doc/v0.4-ui-polish-spec.md` 用来定义“极简生产力小工具 + 宠物陪伴”的默认 Panel、设置窗口、反馈文案、动效节奏和验收标准；v0.4 不新增 Theme Tab、主题切换或主题商店。
- **Animation Spec 负责素材标准，不负责生成素材**。`doc/v0.4-animation-spec.md` 只定义画布、锚点、帧数、FPS、命名、状态含义、验收标准和素材记录格式。生成工具可以是 SpriteCook 或其他工具，但接入标准必须统一。
- **PetManager 负责状态，不负责输入命中**。`pet_manager.gd` 继续维护基础状态 `idle` / `working` / `resting`，单击/双击按基础状态解析到 `<base>_clicked_single` / `<base>_clicked_double`，长按使用 `clicked_hold`，不直接判断 native hit-test。
- **Pet 场景负责动画播放，不负责窗口策略**。`pet.gd` 只消费 PetManager 的状态和 SpriteFrames，不直接处理托盘、任务栏、透明窗口和注册表。
- **Main 负责运行形态编排**。`main.gd` 负责读取配置、设置窗口形态、刷新命中区、协调 Panel、设置窗口、托盘和 Debug 兜底。
- **Panel 负责薪资信息和展开定位**。`panel.gd` 负责折叠态、展开态、边缘方向、内容密度和 hover 展开，不直接写配置或 native 逻辑。
- **Settings 负责配置编辑和用户反馈**。`settings_dialog.gd` 负责展示配置、差异保存、保存成功/失败提示、恢复默认、平台能力不可用说明，不直接写 Win32。
- **Platform / WindowsPlatform 负责平台能力和降级**。`platform.gd` 和 `windows_platform.gd` 判断 native 是否可用，统一处理托盘、透明窗口、点击穿透、任务栏 / Alt+Tab、开机自启和错误回退。
- **Verification 负责阻塞发布**。`verify_v04.gd`、`verify_v04.ps1` 和打包验证必须能阻止动画资源缺失、设置保存回归、发布包缺文件等问题进入 tag。

---

### 4.2 里程碑 V04-M0: 原型与体验规格

#### Task V04-M0.1: 更新默认桌宠体验原型

**Files:**
- Modify: `doc/prototypes/index.html`
- Modify: `doc/prototypes/prototype-spec.md`

- [ ] **Step 1: 在原型中增加 v0.4 默认桌宠画面**

`doc/prototypes/index.html` 需要新增或调整一个 v0.4 默认桌宠状态，至少包含：

- 透明桌面背景示意
- 橘猫主体
- 折叠态 Panel
- 托盘入口或找回提示
- 右键菜单入口说明

原型默认风格采用“温暖陪伴型”，但不得出现主题切换控件。禁止新增以下入口：

```text
选择主题
主题商店
自定义主题
切换主题
```

- [ ] **Step 2: 记录默认风格原则**

`doc/prototypes/prototype-spec.md` 需要增加 v0.4 体验方向说明：

```markdown
## v0.4 默认体验方向

v0.4 默认采用温暖陪伴型体验。视觉、动效、文案和反馈应柔和、轻量、低压力，但仍保持薪资工具属性。

不进入 v0.4 的内容：
- 多主题
- 主题切换
- 主题商店
- 用户自定义主题
```

- [ ] **Step 3: 验收**

人工检查：
- 原型能看出 v0.4 默认桌宠状态
- Panel 折叠态没有压过小猫主体
- 页面文案没有把主题系统列为 v0.4 必做项
- 原型说明与 PRD 的“温暖陪伴型”一致

---

#### Task V04-M0.2: 补齐 Panel 折叠、展开和边缘原型

**Files:**
- Modify: `doc/prototypes/index.html`
- Modify: `doc/prototypes/prototype-spec.md`

- [ ] **Step 1: 增加 Panel 折叠态**

折叠态必须展示：
- 金额 + 短状态垂直居中
- 单行或紧凑信息
- 不遮挡小猫主体
- 不像调试面板

折叠态示例：

```text
¥128.60 工作中
¥0.00 休息中
未配置 待设置
```

- [ ] **Step 2: 增加 Panel 展开态**

展开态至少覆盖：
- 今日已赚
- 本月累计
- 时薪
- 工作进度
- 当前状态

展开态内容应以可读为先，不为了装饰压缩到无法辨认。

- [ ] **Step 3: 增加边缘状态**

原型需要展示以下边缘策略：

| 场景 | Panel 预期方向 |
|------|----------------|
| 小猫靠屏幕右侧 | Panel 向左展开 |
| 小猫靠屏幕左侧 | Panel 向右展开 |
| 小猫靠屏幕底部 | Panel 向上展开 |
| 小猫靠屏幕顶部 | Panel 不超出顶部可见区域 |

- [ ] **Step 4: 写入体验规则**

`prototype-spec.md` 记录：
- Panel 不贴脸
- Panel 不离小猫太远
- Panel 不遮挡小猫主体
- 展开/收起动画轻量、短促，不抢小猫反馈

---

#### Task V04-M0.3: 补齐设置页关键状态原型

**Files:**
- Modify: `doc/prototypes/index.html`
- Modify: `doc/prototypes/prototype-spec.md`

- [ ] **Step 1: 保留五类设置页**

设置页仍保留：

```text
Salary
Pet
Display
Panel
General
```

不得在 v0.4 原型中新增 Theme / Appearance 作为主题系统入口。若需要外观相关说明，只能放在 Display 页中解释默认体验，不提供选择。

- [ ] **Step 2: Display 页说明窗口关系**

Display 页需要解释：
- 窗口模式
- 透明度
- 缩放
- 纯桌宠模式
- 点击穿透

说明重点是“这些选项怎么影响窗口可见性和可找回性”，不是堆功能说明。

- [ ] **Step 3: General 页说明恢复和调试**

General 页需要包含：
- 开机自启
- 关闭隐藏到托盘
- Debug 模式
- 重置窗口位置
- 恢复默认设置

- [ ] **Step 4: 补充保存反馈状态**

原型至少覆盖：
- 保存成功
- 保存失败
- 平台能力不可用
- 设置需要重启或重新显示窗口
- 无变化保存

设置窗口应呈现为单一窗口，不再出现“一个大黑窗口里套一个设置窗口”的观感。

---

#### Task V04-M0.4: 补齐托盘、隐藏和发布包体验原型

**Files:**
- Modify: `doc/prototypes/index.html`
- Modify: `doc/prototypes/prototype-spec.md`

- [ ] **Step 1: 托盘菜单原型**

托盘菜单至少包含：

```text
显示窗口 / 隐藏窗口
设置
关于 LetsMakeMoney
退出
```

菜单文案以 v0.3 已实现能力为基础，不在 v0.4 增加安装器、自动更新或账号入口。

- [ ] **Step 2: 关闭隐藏提示**

关闭窗口后隐藏到托盘时，原型需要给出轻量提示，说明程序仍在运行，并可以通过托盘找回。

- [ ] **Step 3: 发布包说明页草图**

发布包说明页需要展示 Zip 内文件：

```text
LetsMakeMoney.exe
letsmakemoney_native.dll
README.md
v0.4-beta-notes.md
manifest.json
checksums.txt
```

- [ ] **Step 4: 验收**

原型确认后，才能进入 V04-M1 到 V04-M5 的实现。若原型与 PRD 冲突，以 PRD 为准先修原型。

---

### 4.3 里程碑 V04-M1: 橘猫动画与素材管线

#### Task V04-M1.1: 编写 v0.4 动画素材规格

**Files:**
- Add: `doc/v0.4-animation-spec.md`
- Modify if needed: `doc/prototypes/prototype-spec.md`

- [ ] **Step 1: 写入动画状态模型**

`doc/v0.4-animation-spec.md` 需要明确：

```markdown
# LetsMakeMoney v0.4 Animation Spec

## 基础状态
- idle
- working
- resting

## 基础状态延伸动作
- idle_clicked_single / idle_clicked_double
- working_clicked_single / working_clicked_double
- resting_clicked_single / resting_clicked_double
- clicked_hold

基础状态由工作时间、休息模式和薪资状态决定。单击、双击是当前基础状态的延伸动作；长按是通用持续反馈。交互结束后必须回到进入交互前的基础状态。
```

- [ ] **Step 2: 定义素材规格**

规格中必须包含：
- 统一画布尺寸
- 透明边界
- 角色锚点
- 脚底基线
- 视觉中心
- 推荐 FPS
- 最低帧数
- loop / one-shot 规则
- 帧间漂移验收标准

建议表格：

```markdown
| 动画 | 类型 | 最低帧数 | FPS | Loop | 恢复规则 |
|------|------|----------|-----|------|----------|
| idle | 基础 | 4 | 6-10 | 是 | 自动状态 |
| working | 基础 | 6 | 8-12 | 是 | 自动状态 |
| resting | 基础 | 4 | 6-10 | 是 | 自动状态 |
| `<base>_clicked_single` | 延伸 | 3 | 10-14 | 否 | 回到进入前基础状态 |
| `<base>_clicked_double` | 延伸 | 4 | 10-14 | 否 | 回到进入前基础状态 |
| clicked_hold | 通用长按 | 4 | 8-12 | 是 | 松开后回到进入前基础状态 |
```

- [ ] **Step 3: 定义命名规则**

素材命名采用：

```text
cat_orange_v2_<animation>_<frame>.png
```

示例：

```text
cat_orange_v2_idle_00.png
cat_orange_v2_working_03.png
cat_orange_v2_idle_clicked_single_01.png
cat_orange_v2_working_clicked_double_02.png
cat_orange_v2_clicked_hold_02.png
```

- [ ] **Step 4: 定义素材记录格式**

每批素材都要记录：
- 工具
- 输入图
- 提示词
- 输出批次
- 筛选结论
- 是否接入
- 接入成本

未达标素材不得替换默认素材。

---

#### Task V04-M1.2: 生成或筛选橘猫 v2 动画素材

**Files:**
- Add/Modify: `assets/pets/cat/orange_v2/`
- Add: `doc/v0.4-animation-assets-log.md`

- [ ] **Step 1: 准备素材目录**

创建目标目录：

```text
assets/pets/cat/orange_v2/
assets/pets/cat/orange_v2/idle/
assets/pets/cat/orange_v2/working/
assets/pets/cat/orange_v2/resting/
assets/pets/cat/orange_v2/clicked_hold/
assets/pets/cat/orange_v2/idle_clicked_single/
assets/pets/cat/orange_v2/idle_clicked_double/
assets/pets/cat/orange_v2/working_clicked_single/
assets/pets/cat/orange_v2/working_clicked_double/
assets/pets/cat/orange_v2/resting_clicked_single/
assets/pets/cat/orange_v2/resting_clicked_double/
```

- [ ] **Step 2: 按状态筛选素材**

筛选要求：
- `idle`：长期常驻不烦躁，不抢注意力
- `working`：包含键盘、电脑、金币等工作/金钱道具，能看出正在努力赚钱或工作
- `resting`：先探索困倦坐姿、躺下和其他低动作休息姿态，再选择与 idle 明显不同的候选
- `<base>_clicked_single`：idle / working / resting 下都短促、明确、轻量，并符合基础状态语境
- `<base>_clicked_double`：idle / working / resting 下都比单击更明显，并符合基础状态语境
- `clicked_hold`：可持续循环，松开后自然恢复

- [ ] **Step 3: 记录筛选结果**

`doc/v0.4-animation-assets-log.md` 示例：

```markdown
## Batch 001

- Tool:
- Input:
- Prompt:
- Output path:
- Candidate animations:
- Accepted:
- Rejected:
- Reason:
- Integration notes:
```

- [ ] **Step 4: 质量门禁**

只有同时满足以下条件的素材才能进入 SpriteFrames：
- 不裁切
- 不明显漂移
- 不闪烁
- 透明边界干净
- 状态差异可感知
- 与温暖陪伴型方向一致

---

#### Task V04-M1.3: 接入 SpriteFrames 并保留回退

**Files:**
- Modify: `assets/pets/cat/cat_sprite_frames.tres`
- Modify: `assets/pets/cat/cat_resource.tres`
- Modify: `src/scenes/pet/pet.gd`
- Modify: `src/autoload/pet_manager.gd`

- [ ] **Step 1: 接入动画资源**

在 SpriteFrames 中新增或替换以下动画：

```text
idle
working
resting
clicked_hold
idle_clicked_single
idle_clicked_double
working_clicked_single
working_clicked_double
resting_clicked_single
resting_clicked_double
```

如果某个 v2 动画缺失，不允许用错误动画名硬凑。应保持 v0.3 旧素材，并在验证中标记素材未达标。

- [ ] **Step 2: 保留 v0.3 资源回退**

不得删除 v0.3 橘猫资源。建议保留：

```text
assets/pets/cat/orange_v1/
```

如果当前 v0.3 资源不在 `orange_v1` 目录，也应在 `cat_resource.tres` 或资源说明中明确旧资源路径。

- [ ] **Step 3: 确认状态恢复**

PetManager 必须继续遵守：

```text
基础状态: idle / working / resting
延伸动作: <base>_clicked_single / <base>_clicked_double
通用长按: clicked_hold
交互结束后: 回到进入交互前的基础状态
```

禁止把单击、双击、长按重新设计成基础状态。

- [ ] **Step 4: 手动预览**

在 Godot 中运行主场景，手动触发：
- 工作时间 idle / working 切换
- 休息状态 resting
- 单击
- 双击
- 长按
- 拖拽后恢复

记录裁切、漂移、闪烁、状态不明显等问题。

---

#### Task V04-M1.4: 新增动画自动验证

**Files:**
- Add/Modify: `scripts/verify_v04.gd`
- Add/Modify: `scripts/verify_v04.ps1`

- [ ] **Step 1: 编写 Godot 验证脚本**

`scripts/verify_v04.gd` 至少检查：

```gdscript
extends SceneTree

var failures: Array[String] = []

func _init() -> void:
    _verify_cat_animations()
    _verify_pet_state_model()
    if failures.is_empty():
        print("v0.4 verification passed")
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)

func _assert(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _verify_cat_animations() -> void:
    var frames := load("res://assets/pets/cat/cat_sprite_frames.tres")
    _assert(frames != null, "cat_sprite_frames.tres missing")
    for anim in ["idle", "working", "resting", "clicked_hold", "idle_clicked_single", "idle_clicked_double", "working_clicked_single", "working_clicked_double", "resting_clicked_single", "resting_clicked_double"]:
        _assert(frames.has_animation(anim), "missing animation: " + anim)
        _assert(frames.get_frame_count(anim) > 0, "animation has no frames: " + anim)

func _verify_pet_state_model() -> void:
    _assert(load("res://src/autoload/pet_manager.gd") != null, "pet_manager.gd missing")
```

- [ ] **Step 2: 编写 PowerShell 包装脚本**

`scripts/verify_v04.ps1` 示例：

```powershell
$ErrorActionPreference = "Stop"

$Godot = "$env:LMM_GODOT_EXE"
$Project = "<PROJECT_ROOT>"

& $Godot --headless --path $Project --script "res://scripts/verify_v04.gd"
if ($LASTEXITCODE -ne 0) {
    throw "v0.4 verification failed"
}
```

- [ ] **Step 3: 验证**

运行：

```powershell
.\scripts\verify_v04.ps1
```

预期：

```text
v0.4 verification passed
```

---

#### Task V04-M1.5: 素材生成产能路线 Spike

**Files:**
- Modify: `doc/v0.4-animation-spec.md`
- Modify: `doc/v0.4-animation-assets-log.md`
- Modify: `doc/progress.md`

> 本任务用于避免 v0.4 动画素材完全依赖单一免费额度或单一外部服务。它不替代 V04-M1.2 的 v2 素材筛选，也不降低 V04-M1.3 的接入质量门禁。

- [ ] **Step 1: 记录短期 SpriteCook 路线**

记录当前可用的 SpriteCook skill / MCP 前提：

```markdown
## Asset Production Routes

### Route A: SpriteCook
- Role: short-term candidate generation
- Strength: fast still image and animation exploration
- Constraint: requires SpriteCook MCP and credits
- Use in v0.4: generate first orange v2 candidates when available
```

要求：
- 记录本地已有 `spritecook-generate-sprites`、`spritecook-animate-assets`、`spritecook-use-assets-in-godot` 三类 skill。
- 明确 SpriteCook 适合快速生成候选，但不作为长期唯一产能。
- 若使用 SpriteCook，必须把输入图、提示词、输出批次、额度成本和筛选结论写入 assets log。

- [ ] **Step 2: 记录 ComfyUI 本地工作流 Spike**

记录 ComfyUI 作为中长期自托管路线：

```markdown
### Route B: ComfyUI local workflow
- Role: long-term self-hosted production spike
- Candidate nodes/workflows: IP-Adapter, ControlNet, AnimateDiff
- Goal: preserve cat identity, control pose/motion, export transparent or cleanup-ready frames
- v0.4 status: non-blocking spike
```

v0.4 不要求立即完成 ComfyUI 安装和调参，但需要把它作为后续素材产能的正式调研方向。若进入实测，最小验证为：
- 使用现有橘猫图作为 reference。
- 输出至少一张保持身份一致的 idle / working / resting 候选图。
- 记录是否能稳定控制透明背景、画布、姿态和道具。
- 记录显卡、耗时、依赖和维护成本。

- [ ] **Step 3: 记录本地编辑与修帧工具**

记录 Pixelorama、LibreSprite、Aseprite 等工具的角色：

```markdown
### Route C: Local sprite editing tools
- Role: cleanup and frame normalization
- Tools: Pixelorama, LibreSprite, Aseprite
- Use: transparent cleanup, canvas normalization, drift correction, low-frame manual fixes
```

要求：
- 优先把免费开源工具作为默认建议。
- Aseprite 只作为体验更好的可选工具，不要求 v0.4 强制购买或安装。
- 本地编辑工具不直接解决“生成”，但能显著降低 AI 输出不稳定带来的接入成本。

- [ ] **Step 4: 记录 Godot cutout 确定性兜底**

记录当逐帧 AI 动画不稳定时的兜底方案：

```markdown
### Route D: Godot cutout animation
- Role: deterministic fallback
- Parts: head, body, tail, paws, eyes, keyboard, computer, coins
- Use: breathing, blinking, typing, coin bounce, small reaction loops
```

要求：
- 明确 cutout 不追求复杂逐帧表现，重点是稳定、轻量、可控。
- 如果 v2 逐帧动画难以稳定，可先用静态橘猫 v2 + cutout 动作完成 `idle` / `working` / `resting` 的体验提升。
- cutout 方案同样必须通过窗口尺寸、点击区域和 Panel 协调验证。

- [ ] **Step 5: 形成 v0.4 动画产能决策**

在接入默认 v2 资源前，必须在 assets log 中给出当前选择：

```markdown
## Production Decision

- Primary route:
- Backup route:
- Why:
- Remaining risks:
- Manual approval required:
```

验收标准：
- `doc/v0.4-animation-spec.md` 明确三类以上素材路线。
- `doc/v0.4-animation-assets-log.md` 记录当前路线结论。
- v0.4 自动验证检查这些路线说明存在。
- 不把 ComfyUI / cutout 写成普通用户可见功能，也不把它们写成主题系统。

---

### 4.4 里程碑 V04-M2: 交互手感优化

#### Task V04-M2.1: 统一交互优先级

**Files:**
- Modify: `src/scenes/pet/pet.gd`
- Modify: `src/autoload/pet_manager.gd`
- Modify: `src/scenes/main/main.gd`
- Test: `scripts/verify_v04.gd`

- [ ] **Step 1: 固定交互优先级**

v0.4 交互优先级为：

```text
右键菜单 > 拖拽 > 长按 > 双击 > 单击 > hover > 自动基础状态
```

实现时必须保证：
- 右键不触发左键交互
- 拖拽阈值触发后不进入 `clicked_hold`
- 双击不被两次单击提前吞掉
- hover 不打断正在播放的短反馈

- [ ] **Step 2: 记录进入交互前基础状态**

进入单击、双击、长按交互前，需要记录当前基础状态：

```text
previous_base_state = idle | working | resting
```

交互结束后恢复到 `previous_base_state`，不能统一回到 idle。

- [ ] **Step 3: 验证**

手动验证顺序：
1. idle 状态单击，确认反馈后回 idle
2. working 状态双击，确认反馈后回 working
3. resting 状态长按，确认松开后回 resting
4. 左键按住并移动，确认进入拖拽而不是长按
5. 右键打开菜单，确认不触发单击/双击/长按

---

#### Task V04-M2.2: 优化单击、双击、长按与拖拽反馈

**Files:**
- Modify: `src/autoload/pet_manager.gd`
- Modify: `src/scenes/pet/pet.gd`
- Modify: `src/scenes/main/main.gd`

- [ ] **Step 1: 单击反馈**

单击反馈要求：
- 短促
- 可感知
- 不阻塞后续拖拽或右键
- 播放结束后回到进入前基础状态

- [ ] **Step 2: 双击反馈**

双击反馈要求：
- 比单击明显
- 稳定识别
- 不被两次单击动画拆开
- 播放结束后回到进入前基础状态

- [ ] **Step 3: 长按反馈**

长按反馈要求：
- 约 0.5 秒后出现
- 鼠标未超过拖拽阈值才触发
- 松开后自然恢复
- 拖拽开始时立即取消或覆盖长按

- [ ] **Step 4: 拖拽反馈**

拖拽要求：
- 窗口移动速度等于鼠标屏幕位移
- 不出现窗口移动过快
- 拖拽结束后动画不冻结
- 拖拽保存窗口位置不引入明显卡顿

---

#### Task V04-M2.3: 协调小猫 hover 与 Panel hover

**Files:**
- Modify: `src/scenes/panel/panel.gd`
- Modify: `src/scenes/pet/pet.gd`
- Modify: `src/scenes/main/main.gd`

- [ ] **Step 1: 明确 hover 边界**

小猫 hover 只负责小猫轻量反馈；Panel hover 只负责 Panel 展开/收起。二者不能互相重置计时器导致闪烁。

- [ ] **Step 2: 鼠标移动路径验证**

必须验证以下路径：

```text
桌面空白 -> 小猫 -> Panel 折叠区 -> Panel 展开区 -> 桌面空白
Panel 展开区 -> 小猫 -> 桌面空白
小猫 -> 右键菜单 -> 关闭菜单
```

预期：
- Panel 不疯狂展开/收起
- 小猫状态不被 Panel hover 永久占用
- Panel 收起后小猫能回自动状态

---

### 4.5 里程碑 V04-M3: 窗口、点击穿透与 Panel 打磨

#### Task V04-M3.1: 增加点击穿透调试视图

**Files:**
- Modify: `src/scenes/main/main.gd`
- Modify: `src/platform/windows_platform.gd`
- Modify: `native/windows/src/window_controller.cpp`
- Test: `scripts/verify_v04.gd`

- [ ] **Step 1: 增加 Debug 命中区开关**

Debug 模式下增加命中区可视化能力。用户模式默认不显示。

可视化至少区分：

| 区域 | 用途 |
|------|------|
| Pet core | 普通 hover、单击、双击、长按、拖拽 |
| Pet context | 右键菜单区域 |
| Panel collapsed | 折叠态 Panel |
| Panel expanded | 展开态 Panel |

- [ ] **Step 2: 增加日志**

每次刷新命中区时输出：

```text
reason=
scale=
window_position=
pet_core_rect=
pet_context_rect=
panel_collapsed_rect=
panel_expanded_rect=
```

日志只在 Debug 模式或用户主动开启时输出，不能污染普通模式。

- [ ] **Step 3: native 失败回退**

原生 hit-test / region 设置失败时：
- 写入可读日志
- 清空穿透区域或回到安全窗口模式
- 保留设置入口
- 保留托盘或任务栏找回路径

---

#### Task V04-M3.2: 优化命中区刷新与节流

**Files:**
- Modify: `src/scenes/main/main.gd`
- Modify: `src/platform/windows_platform.gd`
- Modify: `native/windows/src/window_controller.cpp`

- [ ] **Step 1: 列出刷新原因**

命中区刷新只在以下情况发生：
- 窗口移动
- 缩放变化
- Panel 展开
- Panel 收起
- 小猫资源尺寸变化
- 设置窗口打开
- 设置窗口关闭
- Debug 模式切换

- [ ] **Step 2: 避免无变化重复调用**

刷新前比较上一次 rects。无变化时不重复调用 native region。

伪代码：

```gdscript
if new_rects == _last_passthrough_rects:
    return
_last_passthrough_rects = new_rects
Platform.set_mouse_passthrough(true, new_rects)
```

- [ ] **Step 3: 验证**

验证场景：
- 拖动窗口 10 次，日志不应爆量
- Panel 展开/收起后命中区更新
- 设置打开时穿透清空
- 设置关闭后穿透恢复

---

#### Task V04-M3.3: 优化 Panel 边缘定位与缩放表现

**Files:**
- Modify: `src/scenes/main/main.gd`
- Modify: `src/scenes/panel/panel.gd`
- Modify: `doc/verification/v0.4.md`

- [ ] **Step 1: 明确边缘策略**

| 窗口位置 | Panel 策略 |
|----------|------------|
| 靠右 | 向左展开 |
| 靠左 | 向右展开 |
| 靠底 | 向上展开 |
| 靠顶 | 不超出顶部可见区域 |
| 四角 | 优先保证 Panel 完整可见，再保证距离小猫较近 |

- [ ] **Step 2: 多缩放验证**

必须覆盖：

```text
50%
75%
100%
125%
150%
200%
```

每个缩放下验证：
- 小猫不裁切
- Panel 文字不溢出
- 折叠态金额垂直居中
- 点击穿透区域接近视觉区域

---

#### Task V04-M3.4: 保持桌宠窗口可找回

**Files:**
- Modify: `src/scenes/main/main.gd`
- Modify: `src/autoload/config.gd`
- Modify: `src/autoload/platform.gd`

- [ ] **Step 1: 托盘失败回退**

托盘不可用时：
- 保留任务栏入口
- 保留 Alt+Tab
- 禁止进入完全不可找回的纯桌宠模式
- 关闭按钮不能隐藏到不可找回状态

- [ ] **Step 2: native 初始化失败回退**

native bridge 加载失败时：
- 回退普通窗口或 Debug 安全状态
- 写入日志
- 设置页显示平台能力不可用原因

- [ ] **Step 3: 配置异常回退**

配置文件损坏或字段缺失时：
- 使用默认值启动
- 保留窗口可见
- 保留设置入口
- 下次保存时补齐默认字段

---

### 4.6 里程碑 V04-M4: 设置体验与保存反馈

#### Task V04-M4.1: 重整设置窗口信息架构

**Files:**
- Modify: `src/scenes/settings/settings_dialog.gd`
- Modify: `src/scenes/settings/settings_dialog.tscn`
- Modify: `doc/prototypes/prototype-spec.md`

- [ ] **Step 1: 保留五类设置**

设置页仍为：

```text
Salary
Pet
Display
Panel
General
```

不新增 Theme 作为 v0.4 设置项。

- [ ] **Step 2: Display 页重整**

Display 页集中管理：
- 窗口模式
- 透明度
- 缩放
- 纯桌宠模式
- 点击穿透说明

Display 页必须解释这些设置对“窗口是否可见、是否可找回、是否穿透鼠标”的影响。

- [ ] **Step 3: General 页重整**

General 页集中管理：
- 开机自启
- 关闭隐藏到托盘
- Debug 模式
- 重置窗口位置
- 恢复默认设置

- [ ] **Step 4: 修复窗口套窗口观感**

设置窗口应该呈现为单一设置窗口或明确的独立对话框，不再出现“大宿主窗口 + 内部设置窗”的黑底套娃效果。

---

#### Task V04-M4.2: 保存差异检测与轻量反馈

**Files:**
- Modify: `src/scenes/settings/settings_dialog.gd`
- Modify: `src/autoload/config.gd`
- Modify: `src/platform/windows_platform.gd`

- [ ] **Step 1: 保存前计算差异**

保存前对比当前配置与表单值。无变化时：
- 不重复写 config
- 不重复写注册表
- 不重复调用 native
- 显示“没有变化”或轻量成功提示

- [ ] **Step 2: 按字段应用副作用**

| 字段类型 | 副作用 |
|----------|--------|
| salary / schedule | 只写配置并刷新薪资 |
| opacity / scale | 写配置并刷新窗口/Panel |
| window mode / pure pet mode | 写配置并重新应用窗口策略 |
| auto start | 仅变化时写入或删除注册表 |
| minimize to tray | 写配置，不立即隐藏窗口 |
| debug mode | 写配置，并提示重启或重新打开生效范围 |

- [ ] **Step 3: 保存反馈**

保存成功：

```text
已保存
```

无变化：

```text
没有需要保存的更改
```

保存失败：

```text
保存失败：<可读错误>
```

失败时保留用户输入，不自动恢复旧值。

---

#### Task V04-M4.3: 恢复默认与调试入口

**Files:**
- Modify: `src/scenes/settings/settings_dialog.gd`
- Modify: `src/autoload/config.gd`
- Modify: `doc/verification/v0.4.md`

- [ ] **Step 1: 重置窗口位置**

提供明确入口：

```text
重置窗口位置
```

执行后：
- 窗口回到安全可见区域
- Panel 不超出屏幕
- 配置写入新的窗口坐标

- [ ] **Step 2: 恢复默认设置**

提供明确入口：

```text
恢复默认设置
```

恢复默认不应删除薪资等核心用户数据，除非用户明确选择“同时清空薪资配置”。

- [ ] **Step 3: Debug 模式说明**

设置页或文档中写清配置路径：

```text
%APPDATA%\LetsMakeMoney\config.json
```

说明 `debug_mode=true` 的用途和恢复方式。

---

### 4.7 里程碑 V04-M5: 性能、稳定性与发布包

#### Task V04-M5.1: 常驻性能与日志整理

**Files:**
- Modify: `src/autoload/platform.gd`
- Modify: `src/scenes/main/main.gd`
- Modify: `src/scenes/panel/panel.gd`
- Modify: `src/autoload/debug_logger.gd`
- Modify if needed: `native/windows/src/`

- [ ] **Step 1: 收敛日志**

普通模式只保留：
- 错误
- 启动/退出
- native 初始化结果
- 托盘创建失败
- 保存失败

Debug 模式才输出：
- 命中区 rects
- native region 刷新原因
- Panel 展开/收起原因
- 托盘轮询命令

- [ ] **Step 2: 收敛高频 native 调用**

以下调用必须避免无变化重复执行：
- mouse passthrough region
- taskbar / Alt+Tab visibility
- window opacity
- window topmost

- [ ] **Step 3: 长时间运行验证**

至少验证：
- 运行 30 分钟后托盘仍可用
- Panel 金额仍刷新
- 窗口仍可拖拽
- 设置仍可打开并保存
- 日志文件没有高频刷屏

---

#### Task V04-M5.2: 新增 v0.4 自动验证与回归验证

**Files:**
- Add/Modify: `scripts/verify_v04.ps1`
- Add/Modify: `scripts/verify_v04.gd`
- Modify if needed: `scripts/verify_v03.ps1`
- Modify if needed: `scripts/verify_v03_export.ps1`

- [ ] **Step 1: 自动验证覆盖项**

`verify_v04.gd` 覆盖：
- 动画资源存在
- 动画帧数不为 0
- PetManager 状态接口存在
- 设置场景可加载
- Main 场景可加载
- 关键配置默认值存在

- [ ] **Step 2: PowerShell 验证入口**

运行：

```powershell
.\scripts\verify_v04.ps1
```

预期：

```text
v0.4 verification passed
```

- [ ] **Step 3: 回归验证**

v0.4 发布前继续运行：

```powershell
.\scripts\verify_v02.ps1
.\scripts\verify_v03.ps1
.\scripts\verify_v04.ps1
```

如果存在 v0.4 等价导出验证，也必须运行。

---

#### Task V04-M5.3: 正式 Zip beta 发布包

**Files:**
- Add: `scripts/package_v04.ps1`
- Add: `releases/v0.4-beta-notes.md`
- Add: `releases/v0.4/manifest.json`
- Add: `releases/v0.4/checksums.txt`
- Output ignored or release artifact: `releases/v0.4/LetsMakeMoney-v0.4-beta-windows-x86_64.zip`

- [ ] **Step 1: 定义发布包内容**

Zip 包命名：

```text
LetsMakeMoney-v0.4-beta-windows-x86_64.zip
```

Zip 内必须包含：

```text
LetsMakeMoney.exe
letsmakemoney_native.dll
README.md
v0.4-beta-notes.md
manifest.json
checksums.txt
```

不做安装器，不做自动更新，不写入系统安装目录。

- [ ] **Step 2: 编写 manifest**

`manifest.json` 示例：

```json
{
  "name": "LetsMakeMoney",
  "version": "v0.4-beta",
  "platform": "windows-x86_64",
  "entry": "LetsMakeMoney.exe",
  "native_dll": "letsmakemoney_native.dll",
  "config_path": "%APPDATA%\\LetsMakeMoney\\config.json"
}
```

- [ ] **Step 3: 生成 checksum**

PowerShell 示例：

```powershell
Get-FileHash ".\LetsMakeMoney.exe" -Algorithm SHA256
Get-FileHash ".\letsmakemoney_native.dll" -Algorithm SHA256
```

- [ ] **Step 4: 发布包验证**

验证：
- 解压到全新目录后 exe 能启动
- native dll 能被加载
- 配置路径仍为 `%APPDATA%\LetsMakeMoney`
- 托盘、透明窗口、点击穿透不因路径变化失效
- release notes 说明已知限制和回报模板

---

### 4.8 里程碑 V04-M6: UI polish 与交互原型完善

> 本里程碑承接 PRD `V04-G10`。v0.4 的 UI polish 不等于主题系统，而是把“极简生产力小工具 + 宠物陪伴”落实为可评审、可实现、可验证的默认体验。小猫负责陪伴感，Panel 负责薪资反馈，设置窗口保持工具化。

#### Task V04-M6.1: 沉淀 UI polish 规格文档

**Files:**
- Add/Modify: `doc/v0.4-ui-polish-spec.md`
- Modify: `doc/prototypes/prototype-spec.md`

- [ ] **Step 1: 明确 UI polish 定位**

规格文档需要说明 v0.4 的默认 UI 方向：

```text
极简生产力小工具 + 宠物陪伴
```

该定位要求：
- Panel / 桌宠主界面可以更温暖、更轻量，但薪资信息必须可读。
- 设置窗口保持工具化、清楚、可恢复，不做宠物主题化包装。
- 默认视觉服务于日常常驻桌面，不做营销式大卡片或装饰性页面。
- UI polish 不改变薪资计算、宠物状态、托盘、窗口模式等核心行为。

- [ ] **Step 2: 明确主题系统不进入 v0.4**

规格文档必须写清：
- 不新增 Theme Tab。
- 不新增主题切换。
- 不新增主题商店。
- 不新增用户自定义主题。
- 主题系统仅作为 v0.4 之后的独立规划，不混入本版本实现任务。

- [ ] **Step 3: 定义可实现的 UI 基准**

规格至少覆盖：
- Panel 折叠态信息结构。
- Panel 展开态信息层级。
- 设置窗口五个分类的职责。
- 设置窗口参考当前紧凑暖色偏好面板：顶部中文 tabs、右上关闭按钮、中部行式设置、底部保存/取消 action bar。
- 右键菜单一级项与二级子菜单结构。
- 托盘图标、窗口图标、exe 图标和关于窗口图标的尺寸与识别度要求。
- 保存反馈文案。
- 透明度、缩放、窗口模式、纯桌宠、点击穿透的说明方式。
- 动效节奏：轻量、可中断、不抢小猫主体。

- [ ] **Step 4: 同步 Prototype Spec**

`doc/prototypes/prototype-spec.md` 需要引用 `doc/v0.4-ui-polish-spec.md`，并说明原型中每组交互用于验证什么，避免评审者猜测按钮含义。

---

#### Task V04-M6.2: 重置当前状态可交互原型

**Files:**
- Modify: `doc/prototypes/index.html`
- Modify: `doc/prototypes/prototype-spec.md`

- [x] **Step 1: 重置为当前状态单一原型**

原型不再按 v0.1-v0.4 历史版本切屏，而是按当前真实功能模块组织：
- 总览。
- 桌宠主界面。
- Panel 便签。
- 右键菜单与托盘。
- 设置面板。
- 首次启动向导。
- Debug 与验证。
- 发布包。

- [ ] **Step 2: 增加 Panel 状态切换**

v0.4 UI polish 屏至少提供：

```text
对照
折叠
展开
```

预期：
- 对照状态用于比较旧版/新版信息密度。
- 折叠态显示“金额 + 短状态”，例如 `¥12.34 工作中`。
- 展开态显示完整薪资详情，但层级以“今日已赚”为主。

- [ ] **Step 3: 增加业务状态切换**

原型至少提供：

```text
工作中
休息中
待配置
```

切换后需要能观察到：
- 金额显示变化。
- 短状态变化。
- 进度表达变化。
- 空配置或待配置状态不应伪装为正常赚钱状态。

- [ ] **Step 4: 增加设置反馈切换**

原型至少覆盖四类反馈：

```text
已保存
无变化
需重显
保存失败
```

反馈必须显示在设置窗口内部，不依赖可能被桌宠窗口遮挡的外部弹层。

- [x] **Step 5: 增加设置分类预览交互**

原型中的设置预览使用顶部中文 tabs + 当前页内容 + action bar，并能切换：

```text
工资
桌宠
显示
面板
通用
```

不得新增：

```text
Theme
Appearance
主题
主题商店
```

若存在外观说明，只能作为 Display 页中的默认体验说明，不提供主题切换入口。

- [ ] **Step 6: 增加右键菜单二级入口预览**

原型需要展示角色右键菜单的一级项：

```text
设置
窗口模式 >
选择宠物 >
关于 LetsMakeMoney
退出
```

其中：
- `窗口模式 >` 子菜单包含 `置顶悬浮` / `融入桌面`，并标记当前项。
- `选择宠物 >` 子菜单包含当前橘猫项；只有一个宠物时仍显示当前项，不报错。
- 子菜单需要表达“鼠标悬停右侧展开”的交互意图。

- [ ] **Step 7: 增加图标尺寸预览**

原型需要展示同一 app icon 在以下尺寸下的识别度：

```text
16 / 24 / 32 / 48 / 64 / 128 / 256
```

预期：
- 16 / 24 尺寸重点模拟托盘图标。
- 32 / 48 尺寸重点模拟窗口图标和任务栏图标。
- 128 / 256 尺寸重点模拟 exe、关于窗口和发布说明中使用的大图。
- 小尺寸不要求直接缩放完整身体图，可以在后续实现中使用简化猫头或轮廓版本。

- [ ] **Step 8: 修复原型图片引用**

原型图片资源必须引用项目内真实存在的素材路径，例如：

```text
assets/pets/cat/orange_v2/...
```

不得继续引用已经失效的历史目录。提交前需要用静态检查或本地浏览器确认图片没有 404。

---

#### Task V04-M6.3: 将 UI polish 落到 Godot Panel

**Files:**
- Modify: `src/scenes/panel/panel.gd`
- Modify if needed: `src/scenes/panel/panel.tscn`
- Modify if needed: `src/scenes/main/main.gd`

- [ ] **Step 1: 调整折叠态信息结构**

折叠态从“只有金额”升级为：

```text
金额 + 短状态
```

示例：

```text
¥12.34 工作中
¥0.00 休息中
未配置 待设置
```

折叠态不显示：
- 今日详情。
- 本月累计。
- 时薪。
- 进度条。
- 复杂说明文案。

- [ ] **Step 2: 调整展开态信息层级**

展开态层级建议：

1. 今日已赚。
2. 当前状态。
3. 本月累计。
4. 时薪。
5. 工作进度。

展开态仍保持轻量薪资便签观感，不变成密集调试面板。

- [ ] **Step 3: 保持现有窗口与穿透兼容**

Panel polish 不能破坏：
- hover 展开 / 收起。
- 边缘定位。
- 点击穿透命中区。
- 透明度。
- 缩放。
- Debug 模式中的可观察性。

- [ ] **Step 4: 视觉验收**

至少验证：
- 100% / 150% / 200% 缩放下文字不溢出。
- 折叠态金额和短状态垂直居中。
- 展开态不遮挡小猫主体。
- 靠屏幕右侧、底部时仍能选择合理展开方向。

---

#### Task V04-M6.4: 将 UI polish 落到 Godot 设置窗口

**Files:**
- Modify: `src/scenes/settings/settings_dialog.gd`
- Modify if needed: `src/scenes/settings/settings_dialog.tscn`
- Modify: `doc/verification/v0.4.md`

- [ ] **Step 1: 收敛为紧凑暖色偏好设置面板**

设置窗口整体参考当前原型，不再继续沿用大型 Win11 后台式结构：

```text
顶部：工资 / 桌宠 / 显示 / 面板 / 通用 tabs + 右上关闭按钮
中部：当前页标题 + section + row
底部：取消 / 保存 action bar
内部：轻量保存反馈
```

当前不实现搜索入口。若后续恢复搜索，必须低权重，不抢占设置主体空间。

- [ ] **Step 2: 保持工具化设置窗口**

设置窗口继续保留：

```text
Salary
Pet
Display
Panel
General
```

要求：
- 不新增 Theme Tab。
- 不新增 Appearance 作为主题入口。
- 不做宠物主题化装饰。
- 不把设置页做成营销介绍页。
- 不再出现窗口套窗口观感。

- [ ] **Step 3: 优化 Display / Panel / General 说明**

Display 页重点解释：
- 窗口模式。
- 透明度。
- 缩放。
- 纯桌宠模式。
- 点击穿透。
- 修改后是否需要重新显示窗口或重启。

Panel 页重点解释：
- 展开/收起行为。
- 边缘定位。
- 薪资显示密度。

General 页重点解释：
- 开机自启。
- 关闭隐藏到托盘。
- Debug 模式。
- 重置窗口位置。
- 恢复默认设置。

- [ ] **Step 4: 统一保存反馈**

设置保存反馈使用 v0.4 UI polish 规格中的四类状态：

| 反馈 | 使用场景 |
|------|----------|
| 已保存 | 配置写入成功，并已应用可即时生效项 |
| 无变化 | 表单内容与当前配置一致 |
| 需重显 | 已保存，但窗口策略需要重新显示窗口或重启后完全生效 |
| 保存失败 | 写配置、写注册表或 native 应用失败 |

失败时保留用户输入，并显示可读错误，不自动吞掉失败。

- [ ] **Step 5: 恢复默认行为说明**

恢复默认设置必须明确影响范围：
- 可以恢复窗口、Panel、显示、调试等体验配置。
- 默认不清空薪资、角色和用户核心数据。
- 若将来需要清空核心数据，必须做成单独入口和二次确认。

---

#### Task V04-M6.5: 将右键菜单改为二级入口

**Files:**
- Modify: `src/autoload/drag_resize_system.gd`
- Modify if needed: `src/scenes/main/main.gd`
- Modify: `doc/verification/v0.4.md`

- [ ] **Step 1: 移除平铺快速入口**

右键菜单一级项不再直接平铺“设置窗口模式”和“选择宠物”的具体选项。

一级菜单建议为：

```text
设置
窗口模式 >
选择宠物 >
关于 LetsMakeMoney
退出
```

- [ ] **Step 2: 实现窗口模式子菜单**

`窗口模式 >` 子菜单包含：

```text
置顶悬浮
融入桌面
```

要求：
- 当前项有勾选、圆点、高亮或其他可读标记。
- 切换后继续走现有配置保存和窗口策略应用逻辑。
- 子菜单打开时不能破坏右键菜单退出、设置、关于等降级入口。

- [ ] **Step 3: 实现选择宠物子菜单**

`选择宠物 >` 子菜单从 `PetManager` 当前可用宠物列表生成。

要求：
- 当前只有一个宠物时仍显示当前项。
- 当前项可禁用或标记为当前，但不能报错。
- 后续新增宠物时不需要改菜单结构。

- [ ] **Step 4: 子菜单位置和穿透保护**

子菜单靠屏幕右侧时不能溢出屏幕，必要时向左展开。

菜单打开期间需要保护：
- 右键命中区。
- 点击穿透区域。
- 拖拽恢复。
- 托盘降级入口。
- 退出保存流程。

---

#### Task V04-M6.6: 托盘图标与窗口图标 polish

**Files:**
- Modify/Add: `icons/`
- Modify: `export_presets.cfg`
- Modify if needed: `native/windows/src/*`
- Modify if needed: `src/scenes/about/*`
- Modify: `doc/verification/v0.4.md`

- [ ] **Step 1: 确定图标源图**

图标需要基于当前橘猫形象，但优先保证小尺寸识别度，不强制完整身体入镜。

建议策略：
- 大尺寸使用完整或半身橘猫。
- 小尺寸使用简化猫头、轮廓或高对比脸部。
- 保留橙色、白脸、圆眼或其他最强识别特征。

- [ ] **Step 2: 生成多尺寸图标**

至少整理：

```text
16 / 24 / 32 / 48 / 64 / 128 / 256
```

用途：
- 16 / 24：托盘。
- 32 / 48：窗口、任务栏、Alt+Tab。
- 128 / 256：exe、关于窗口、README / release notes。

- [ ] **Step 3: 更新导出和 native 引用**

需要确认：
- Godot export preset 使用最终 `.ico`。
- Windows native 托盘图标加载最终图标或小尺寸优化图标。
- 关于窗口、README 或 release notes 使用高分辨率图标时不失真。

- [ ] **Step 4: 验证小尺寸可读**

验证时重点看：
- 16px 托盘是否能识别为 LetsMakeMoney。
- 暗色任务栏上是否糊成一团。
- 亮色背景下是否有足够轮廓。
- 不因透明边缘过大导致图标显得过小。

---

#### Task V04-M6.7: 补齐 UI polish 验证与回归门禁

**Files:**
- Modify: `doc/verification/v0.4.md`
- Modify if needed: `scripts/verify_v04.ps1`
- Modify if needed: `scripts/verify_v04.gd`

- [ ] **Step 1: 手动验证增加 UI polish 分组**

`doc/verification/v0.4.md` 需要增加或确认以下检查项：
- 原型中 v0.4 UI polish 屏可打开。
- 原型图片不缺失。
- Panel 折叠态显示“金额 + 短状态”。
- Panel 展开态显示完整薪资详情。
- 设置窗口采用左侧分类导航 + 右侧卡片内容。
- 设置反馈覆盖已保存、无变化、需重显、保存失败。
- 右键菜单有 `窗口模式 >` 和 `选择宠物 >` 二级入口。
- 托盘/窗口/exe 图标尺寸预览或真实资源存在。
- 设置窗口保持工具化，不出现 Theme Tab / Appearance 主题入口。
- 设置窗口不再出现窗口套窗口观感。

- [ ] **Step 2: 自动验证增加静态检查**

如果脚本成本可控，`verify_v04.ps1` 增加：
- `doc/v0.4-ui-polish-spec.md` 存在。
- `doc/prototypes/index.html` 存在 v0.4 UI polish 入口。
- 原型引用的项目内图片路径存在。
- 原型中不出现 `Theme Tab` / `主题商店` 作为 v0.4 设置入口。
- 设置窗口仍保留 Salary / Pet / Display / Panel / General 五类。
- 右键菜单存在 `窗口模式` 与 `选择宠物` 二级入口。
- 图标文件存在，导出预设引用路径有效。

- [ ] **Step 3: 发布前回归**

v0.4 发布前必须确认：
- UI polish 原型和 PRD 一致。
- Godot Panel 与设置窗口没有偏离原型方向。
- 主题系统仍只在后续规划中出现，不进入 v0.4 实现范围。

---

### 4.9 里程碑 V04-DOC: 验证文档与发布记录

> 本节列出 v0.4 后续开发阶段必须同步的文档任务。本次“实施计划撰写”只更新 `doc/implementation-plan.md`，不直接修改 progress、verification 或 release notes。

#### Task V04-DOC.1: 编写 v0.4 手动验证文档

**Files:**
- Add: `doc/verification/v0.4.md`

- [ ] **Step 1: 文档结构**

手动验证文档沿用每个版本只保留一个验证文档的规则：

```text
doc/verification/v0.4.md
```

建议结构：

```markdown
# LetsMakeMoney v0.4 Beta 手动验证

## 环境
- Windows 版本：
- Godot 版本：
- exe 路径：
- 是否清空配置：

## 验证表
| 编号 | 操作步骤 | 预期行为 | 结果 | 备注 | 优化方案 | 复测结果 |
|------|----------|----------|------|------|----------|----------|
```

- [ ] **Step 2: 验证范围**

必须覆盖：
- 原型确认
- UI polish 原型交互
- 动画状态
- 单击/双击/长按/拖拽/右键
- Panel 折叠/展开/边缘定位
- 点击穿透
- 设置保存
- 托盘显示/隐藏
- 纯桌宠可找回
- Zip 发布包

---

#### Task V04-DOC.2: 同步 Progress、Release Notes 和 Changelog

**Files:**
- Modify: `doc/progress.md`
- Add/Modify: `releases/v0.4-beta-notes.md`
- Modify: `releases/CHANGELOG.md`

- [ ] **Step 1: 更新 Progress**

v0.4 开发启动后，将 V04-M0 到 V04-M6、V04-DOC 同步到 progress，并拆成 Vibe Coding 可执行任务。

- [ ] **Step 2: 更新 Release Notes**

`releases/v0.4-beta-notes.md` 需要说明：
- v0.4 用户可感知变化
- 动画优化范围
- UI polish 与 Panel / 设置体验变化
- 设置体验变化
- 发布包结构
- 已知限制
- 升级建议
- 问题回报模板

- [ ] **Step 3: 更新 Changelog**

`releases/CHANGELOG.md` 增加 v0.4 条目，保持中文。

---

### 4.10 v0.4 Beta 实施计划与 PRD 对照

| PRD 需求 | 实现任务 |
|---------|---------|
| V04-G1 橘猫动画体验升级 | Task V04-M1.1 + V04-M1.2 + V04-M1.3 + V04-M1.4 |
| V04-G2 交互手感优化 | Task V04-M2.1 + V04-M2.2 + V04-M2.3 |
| V04-G3 窗口与点击穿透打磨 | Task V04-M3.1 + V04-M3.2 + V04-M3.4 |
| V04-G4 Panel 与薪资信息体验优化 | Task V04-M0.2 + V04-M3.3 |
| V04-G5 设置系统体验优化 | Task V04-M0.3 + V04-M4.1 + V04-M4.2 + V04-M4.3 |
| V04-G6 性能与稳定性整理 | Task V04-M5.1 + V04-M5.2 |
| V04-G7 发布体验规范化 | Task V04-M0.4 + V04-M5.3 + V04-DOC.2 |
| V04-G8 默认体验风格统一 | Task V04-M0.1 + V04-M6.1 + V04-M6.2 |
| V04-G9 素材生成产能路线确认 | Task V04-M1.5 |
| V04-G10 UI polish 与交互原型完善 | Task V04-M6.1 + V04-M6.2 + V04-M6.3 + V04-M6.4 + V04-M6.5 |
| 主题系统后续规划 | 不进入 v0.4；不得写成实现任务 |

### 4.11 v0.4 Beta 必须完成项

以下内容是 v0.4 Beta 正式范围，不作为降级或 Spike：

- 更新现有原型，覆盖 v0.4 默认温暖陪伴方向。
- 编写 `doc/v0.4-ui-polish-spec.md`，明确“极简生产力小工具 + 宠物陪伴”的默认体验。
- v0.4 UI polish 原型支持 Panel 状态、业务状态、设置反馈和设置 Tab 交互。
- 明确主题系统不进入 v0.4。
- 编写 v0.4 动画素材规格。
- 记录 SpriteCook、ComfyUI、本地 sprite 编辑工具和 Godot cutout 的素材生成产能路线，避免依赖单一免费额度。
- 筛选并接入至少一套质量达标的橘猫 v2 动画素材。
- 保留 v0.3 橘猫素材回退。
- 保持基础状态 + 交互叠加状态模型。
- 单击、双击、长按、拖拽、右键菜单优先级稳定。
- Debug 模式可以观察或记录点击穿透命中区。
- Panel 在边缘和多缩放下不裁切、不明显溢出。
- Panel 折叠态显示“金额 + 短状态”，展开态符合轻量薪资便签层级。
- 设置窗口不再出现窗口套窗口观感。
- 设置窗口保持工具化，不新增 Theme Tab、不新增主题切换入口。
- 设置保存具备差异检测和明确反馈。
- 托盘、关闭隐藏到托盘、纯桌宠模式保持可找回。
- 自动验证覆盖 v0.4 动画、状态、配置和发布包关键项。
- 发布正式 Zip beta 包，包含 exe、native dll、README、release notes、manifest/checksum。

以下内容明确不进入 v0.4：

- 多主题、主题切换、主题商店、用户自定义主题。
- Windows 安装器。
- 自动更新。
- macOS / Linux 原生托盘、穿透、任务栏隐藏实现。
- iOS / Android。
- 多角色同屏、角色商店、账号系统、云同步。
- 完整统计报表、收入趋势图、日历热力图。
- 彻底重写 Godot 架构或替换主引擎。

### 4.12 v0.4 风险控制与回退要求

| 风险 | 必须执行的回退 |
|------|----------------|
| 原型方向与 PRD 冲突 | 先修原型和 prototype spec，不进入实现 |
| UI polish 被做成主题系统 | 立即回退 Theme Tab、主题切换、主题商店等入口，只保留默认体验规格 |
| 原型图片引用失效 | 静态检查项目内素材路径，修复原型后再进入实现 |
| Godot UI 实现偏离原型 | 回到 `doc/v0.4-ui-polish-spec.md` 和原型对齐，不在实现阶段重新发明 UI 方向 |
| 橘猫 v2 素材质量不稳定 | 保留 v0.3 橘猫素材，不替换默认资源 |
| SpriteCook 免费额度或 MCP 不可用 | 切换到 ComfyUI 本地 Spike、本地编辑清理或 Godot cutout 兜底，不阻塞非素材模块 |
| 部分动画缺失 | 验证失败，不用错误动画名硬凑 |
| 动画状态机回退 | 自动验证基础状态和交互叠加状态恢复路径 |
| 双击被单击吞掉 | 调整双击等待窗口，手动验证阻塞发布 |
| 长按影响拖拽 | 拖拽阈值触发后取消长按 |
| 点击穿透破坏右键菜单 | 保留右键上下文区，Debug 视图验证后再调命中区 |
| 设置保存变慢 | 差异保存，无变化不写配置、不写注册表、不调用 native |
| 设置反馈被外部弹层遮挡 | 反馈回到设置窗口内部展示 |
| 托盘不可用 | 保留任务栏 / Alt+Tab，禁止不可找回隐藏 |
| 发布包缺少 dll | package / export 验证阻塞发布 |
| Zip 解压后无法运行 | 发布包验证阻塞 tag |

### 4.13 v0.4 完成定义

v0.4 Beta 只有在以下条件全部满足后才能进入 tag 准备：

- [ ] `doc/prototypes/index.html` 和 `doc/prototypes/prototype-spec.md` 已覆盖 v0.4 默认体验，并明确主题系统不进入 v0.4。
- [ ] `doc/v0.4-ui-polish-spec.md` 完成，并明确“极简生产力小工具 + 宠物陪伴”的默认 UI polish 方向。
- [ ] v0.4 UI polish 原型支持 Panel 状态、业务状态、设置反馈和设置 Tab 交互。
- [ ] `doc/v0.4-animation-spec.md` 完成。
- [ ] `doc/v0.4-animation-assets-log.md` 已记录 SpriteCook、ComfyUI、本地 sprite 编辑工具和 Godot cutout 的素材产能路线，并明确当前主路线与兜底路线。
- [ ] 至少一套橘猫 v2 动画素材通过质量验收并接入默认资源。
- [ ] v0.3 橘猫素材保留回退。
- [ ] `idle` / `working` / `resting` / `clicked_hold` / `<base>_clicked_single` / `<base>_clicked_double` 均可稳定播放和恢复。
- [ ] 交互优先级经手动验证通过：hover、单击、双击、长按、拖拽、右键菜单不互相破坏。
- [ ] 点击穿透调试视图或日志能帮助定位小猫、Panel、右键上下文区域。
- [ ] 多缩放、多边缘位置下小猫和 Panel 不裁切、不明显错位，折叠态“金额 + 短状态”垂直居中。
- [ ] Panel 展开态符合轻量薪资便签层级，不退化为调试面板观感。
- [ ] 设置窗口保持工具化，不出现 Theme Tab、主题商店或宠物装饰化设置页。
- [ ] 设置保存有明确反馈，进入任意选项卡后不影响其他选项卡保存，保存无变化项不会明显卡顿。
- [ ] 托盘显示/隐藏、关闭隐藏到托盘、纯桌宠模式和 Debug 兜底仍保持可找回。
- [ ] `.\scripts\verify_v02.ps1` 通过。
- [ ] `.\scripts\verify_v03.ps1` 通过。
- [ ] `.\scripts\verify_v04.ps1` 通过。
- [ ] v0.4 等价导出验证通过。
- [ ] v0.4 Zip 包包含 exe、native dll、README、release notes、manifest/checksum。
- [ ] 用户完成 `doc/verification/v0.4.md` 并未记录阻塞问题。
- [ ] `doc/LetsMakeMoneyPRD.md`、`doc/implementation-plan.md`、`doc/progress.md`、`doc/verification/v0.4.md`、`releases/v0.4-beta-notes.md` 与实际状态一致。
