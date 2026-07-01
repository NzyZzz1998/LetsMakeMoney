# LetsMakeMoney 多版本实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按版本推进 LetsMakeMoney Windows 桌面宠物应用：v0.1 Beta 完成可运行产品雏形，v0.2 Beta 打磨真实桌宠窗口体验、系统托盘和开机自启。

**Architecture:** 采用 Godot Autoload 单例模式。6 个全局模块协作：`Platform`（平台抽象工厂）→ `Config`（持久化）→ `SalaryEngine`（计算）→ `PetManager`（状态机中枢，唯一驱动动画）+ `PanelSystem`（面板交互）+ `DragResizeSystem`（拖拽与右键菜单）。所有 UI 场景（pet / panel / settings / wizard / main）只负责渲染和事件转发，不自己管理业务状态。

**Tech Stack:** Godot 4.x / GDScript / Windows 平台 API（通过 `Platform` Autoload 抽象）

**项目路径:** `<PROJECT_ROOT>\`

---

## 0. 通用项目结构与架构约束

### 0.0 实际开发状态基线（2026-07-01）

本实施计划包含两类内容：

- **v0.1 Beta**：历史实施计划 + 当前实际完成状态。v0.1 已打包，但真实形态是“普通调试窗口版产品雏形”，不是完整透明桌宠版。
- **v0.2 Beta**：实施中并进入稳定候选。V02-M1、V02-M2 核心交互、V02-M4 设置与开机自启、V02-M5 验证导出、V02-S1 橘猫素材接入已完成；V02-M3 真系统托盘与 V02-M2 透明穿透因 Godot 4.7 Windows 原生访问违例暂缓。

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
- [x] 新增并更新 `doc/v0.2-manual-verification.md`。
- [x] 重新导出 `build\LetsMakeMoney.exe`。

#### V02-S1 当前完成清单

- [x] 合并临时素材分支中的橘猫素材。
- [x] 接入 `cat_orange_v1` 资源。
- [x] 调整动画状态模型：基础状态为 idle / working / resting。
- [x] 单击、双击、长按作为基础状态上的交互叠加表现。
- [x] 新增橘猫素材验证脚本。
- [ ] 更自然的正式动画帧继续作为后续打磨项。

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
├── icons/
│   └── app_icon.ico
└── doc/
    ├── LetsMakeMoneyPRD.md
    ├── implementation-plan.md
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
│   ├── v0.2-manual-verification.md
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
- 如果使用 GDExtension/插件，在 `doc/v0.2-manual-verification.md` 记录安装来源、版本、构建/复制步骤。
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
- Modify: `doc/` 下手动验证文档（如新增 `doc/v0.2-manual-verification.md`）

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
- Add: `doc/v0.2-manual-verification.md`

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
