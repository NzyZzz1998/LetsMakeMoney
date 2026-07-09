# LetsMakeMoney v0.4 Beta 实施计划

**拆分日期**: 2026-07-08
**来源文件**: doc/implementation-plan.md
**说明**: 本文件复制自原跨版本大文档的 v0.4 章节。原文档暂不删除，后续以本文件作为 v0.4 快速阅读入口；如两者冲突，以 doc/current.md、doc/releases/v0.4/status.md 和最新验证文档为准。

---

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
