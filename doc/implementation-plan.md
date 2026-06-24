# LetsMakeMoney v0.1 Beta 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个基于 Godot 4.x 的 Windows 桌面宠物应用，通过可爱小动物形象实时展示"今日已赚"金额。

**Architecture:** 采用 Godot Autoload 单例模式。6 个全局模块协作：`Platform`（平台抽象工厂）→ `Config`（持久化）→ `SalaryEngine`（计算）→ `PetManager`（状态机中枢，唯一驱动动画）+ `PanelSystem`（面板交互）+ `DragResizeSystem`（拖拽与右键菜单）。所有 UI 场景（pet / panel / settings / wizard / main）只负责渲染和事件转发，不自己管理业务状态。

**Tech Stack:** Godot 4.x / GDScript / Windows 平台 API（通过 `Platform` Autoload 抽象）

**项目路径:** `<PROJECT_ROOT>\`

---

## 项目文件结构

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

**模块职责边界**（关键设计决策）：
- **PetManager 是唯一的状态机中枢**。pet.gd 只监听鼠标事件并调用 `PetManager.request_state()`，不自己维护状态，不自己决定播什么动画——动画播放由 `PetManager.state_changed` 信号驱动 pet.gd。
- **拖拽逻辑放在 pet.gd**。DragResizeSystem 只提供 `move_window_to(pos)` 和 `save_position()` 工具方法，不自己监听鼠标。
- **托盘和"融入桌面"在 v0.1 是降级方案**，不假装实现，用 PopupMenu 代替托盘，用普通非置顶窗口代替真嵌入桌面。

---

## 里程碑 1: 基础设施 — 项目搭建 + Config + SalaryEngine

### Task 1.1: 创建 Godot 项目 + 目录结构 + .gitignore

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

### Task 1.2: 实现 PlatformInterface + WindowsPlatform + Platform Autoload

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

---

### Task 1.3: 实现 Config Autoload

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

### Task 1.4: 实现 SalaryEngine

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

### Task 1.5: 实现 PetResource

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

## 里程碑 2: 角色系统 — PetManager 状态机中枢 + Pet 场景

### Task 2.1: 实现 PetManager Autoload

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

### Task 2.2: 实现 Pet 场景

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

### Task 2.3: 准备占位素材

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

## 里程碑 3: UI 与交互

### Task 3.1: 实现 PanelSystem Autoload

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

### Task 3.2: 实现 Panel 场景

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

### Task 3.3: 实现 DragResizeSystem Autoload

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

### Task 3.4: 实现 Main 场景整合

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

## 里程碑 4: 设置对话框 + 首次启动向导

### Task 4.1: 实现设置对话框

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

### Task 4.2: 实现首次启动向导

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

## 里程碑 5: 打包发布

### Task 5.1: Godot 打包为 Windows exe

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

## 附录 A: 实施计划与 PRD 对照

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

## 附录 B: v0.1 降级方案

| PRD 要求 | v0.1 实现 | 后续版本 |
|---------|----------|---------|
| 系统托盘图标 | PopupMenu 代替（`show_tray_menu`） | v1.0 用 GDExtension 实现真托盘 |
| 融入桌面模式 | 非置顶窗口（`always_on_top=false`） | v1.0 用 Progman 父窗口技巧 |
| 扁平卡通矢量素材 | 像素风占位素材 | v1.0 AI 生成扁平卡通 |
| 开机自启 | 设置项禁用占位 | v1.x 用 Windows 注册表实现 |
| 多角色（2-3） | 仅小猫 | v1.0 补小狗和仓鼠 |
