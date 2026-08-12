入口判断：/prd

# pet-return Runtime Spike 执行合同

> Spike：A / Runtime
> 目标：证明方案 B 的独立 Tauri 透明 WebView 能承载真实逐帧动画、输入仲裁、动态命中和故障隔离
> 当前状态：S1.9 与隔离 G8 已通过，正式产品入口仍未批准
> 结果性质：技术证据，不是正式产品实现
> 最后更新：2026-08-11

## 1. 承重假设

| 假设 ID | 假设 | 现有证据 | 本 Spike 关闭方式 |
| --- | --- | --- | --- |
| RT-H1 | Tauri 透明 WebView 在 Windows 11 三档 DPI 下可稳定播放桌宠 | v1 已使用多窗口，但没有透明桌宠证据 | 真实窗口、逐帧时序与三 DPI 录屏 |
| RT-H2 | WebView 与小型原生桥可以实现逐帧透明命中 | 当前尚无产品证据 | 可见点命中、透明点穿透、帧变化同步 |
| RT-H3 | 500ms 长按、窗口移动与 run 动画可以稳定仲裁 | 历史 Godot 交互曾误判 | 组合输入脚本与人工操作 |
| RT-H4 | 同进程独立 WebView 的故障可以被限制在沙盒能力内 | 方案 B 只有窗口/资源隔离，不是进程隔离 | 故障注入后主线健康检查 |
| RT-H5 | 旧 Classic 包可作为播放器 fixture，但不能冒充 vNext ready | S4.3 approved/ready/unpublished，缺 run_loop 与 hitMask | 测试 adapter 明确暴露缺口 |

## 2. 范围

### 包含

- 独立、无装饰、透明、默认隐藏的 Tauri WebView 测试窗口。
- 现有 Classic S4.3 包的只读测试 adapter。
- 逐帧时长、真实完成事件、超时和晚到事件。
- 隐藏、恢复、销毁和最多一次异常重建。
- 500ms 长按、左右方向拖拽、释放收势。
- 动态 hit mask 到 Windows 原生命中桥的最小链路。
- 资源损坏、导航失败和状态机故障的主线隔离。
- Windows 11 单显示器 100%、125%、150% DPI。

### 不包含

- 正式 Settings、托盘或首次引导入口。
- 用户可见 feature flag、配置迁移或默认值。
- 新素材生成、Classic 正式替换或多多公开接入。
- 完整业务事件、低重复产品编排和公开发布包。
- Godot、原生 GPU 渲染器或多显示器适配。

## 3. 执行隔离

1. 只在独立 worktree/分支执行，名称由执行者记录，不直接改 `main`。
2. 通过编译期或开发环境门禁 `pet-sandbox-spike` 启动；正式 current 构建默认不包含入口。
3. 不写入正式用户配置。Spike 配置和状态写入独立临时目录。
4. 运行前后备份并恢复 LMM 用户配置、日志、托盘和开机启动状态。
5. 原始证据保存在仓库外；仓库只保留脱敏摘要、哈希和必要截图索引。

建议证据位置：

```text
外部原始证据：E:\codex\.evidence\LetsMakeMoney\pet-return\runtime-spike\<run-id>\
仓库脱敏摘要：doc/architecture/evidence/pet-return/runtime-spike/<run-id>/
```

本合同不创建上述目录；执行 Spike 时才建立。

## 4. 输入

| 输入 | 锁定方式 |
| --- | --- |
| LMM 源码 | 分支、HEAD、dirty 状态 |
| Classic S4.3 manifest | 文件路径、大小、SHA256、review 状态 |
| Classic S4.3 atlas | 文件路径、大小、SHA256 |
| 测试 adapter | 源码提交和 fixture 哈希 |
| Dashboard fixtures | working / awake_rest / sleeping / loading / error / 跨夜 |
| Windows 环境 | OS build、WebView2、DPI、分辨率、单显示器 |
| 时间与 RNG | 可注入单调时钟、墙上时间与固定 seed |

Classic 输入基线：

```text
E:\codex\PetManager\projects\letsmakemoney-classic-pro\workspace\custom-actions-s4\motion-s4.3-lunch-return-quality\runtime\
```

执行前必须重新核对真实文件与 SHA256；本文件不硬编码当前未复核的哈希。

## 5. 旧包 adapter 边界

- adapter 只存在于测试/Spike 路径，不得进入生产解析器。
- 缺少 `run_loop` 时使用显式标记的测试占位循环，仅证明播放器与输入链路，不作为动画质量证据。
- 缺少 per-frame hit mask 时，可由最终 RGBA alpha 确定性生成测试 mask，并在证据中标记 `derived_for_runtime_spike`。
- adapter 不得填充虚假 license、provenance 或 v2 ready 状态。
- 报告必须分别写“旧包原字段”和“测试派生字段”。

## 6. 最小实现模块

| 模块 | 最小职责 | 禁止扩张 |
| --- | --- | --- |
| `PetSandboxWindow` | create/show/hide/destroy，透明窗口 | 不加入正式菜单入口 |
| `PetPackageFixtureLoader` | 只读 S4.3 + 测试 adapter | 不做生产迁移 |
| `FramePlayer` | 逐帧 duration、loop、finished、timeout | 不加入复杂特效 |
| `PetRuntimeMachine` | 四域最小状态机和 instance token | 不复制 Dashboard 计算 |
| `PetInputArbiter` | 单击、500ms 长按、拖拽、右键锁 | 不恢复双击 |
| `PetHitTestBridge` | 当前帧 mask 与 Windows hit-test | 不使用永久矩形兜底 |
| `PetSandboxHealth` | 故障捕获、一次重建、会话禁用 | 不阻断主窗口 |

## 7. 执行阶段

### RT0 身份与环境

- 锁定源 HEAD、Classic 包、adapter、OS、WebView2 和 DPI。
- 确认当前正式产品仍为零宠物，current gate 基线通过。
- 输出 `identity.json` 与 `environment.md`。

### RT1 静态透明窗口

- 创建默认隐藏窗口，加载安全静态帧。
- 验证透明背景、无任务栏污染、显示/隐藏/销毁和窗口找回。
- 故障时主应用继续打开今日、日历、Settings 和托盘。

### RT2 逐帧播放器

- 播放 S4.3 的 loop 和 oneshot。
- 记录计划帧开始时间、实际帧开始时间和累计漂移。
- 验证最后帧完整显示后只派发一次 `animation_finished`。
- 注入超时、旧 instance 完成和帧资源缺失。

### RT3 生命周期

- 隐藏时暂停 frame timer、ambient timer、权威同步和命中更新。
- 恢复时重置单调样本，立即拉取权威快照，恢复一组 timer，不重复注册。
- 导航失败最多重建一次；再次失败会话禁用。

### RT4 输入仲裁

- 单击、长按 499/500/501ms、位移阈值前后、pointercancel。
- 左右拖拽、拖拽后立即单击、动作中再次输入。
- 释放后 run_stop 完整播放，再回最新 BaseState。
- 右键菜单/模态 lock token 异常关闭也能释放。

### RT5 动态透明命中

- 头、身体、尾巴和动作伸展区域可点。
- 透明背景、四角和帧外空白穿透到底层窗口。
- 帧变化时 mask 在一个当前帧时长内收敛。
- 100%、125%、150% DPI 逐项记录坐标转换和应用延迟。

### RT6 故障隔离

受控注入：

- manifest 损坏。
- 图集缺失或哈希错误。
- hit mask 缺失/越界。
- WebView 导航失败。
- 状态机异常和连续 timeout。
- 原生桥返回失败。

每次确认沙盒降级或关闭，收入、日历、Settings、托盘、更新检查与配置保存仍可用。

### RT7 两小时稳定运行

- 轮换基础 loop、ack、拖拽、隐藏/恢复和故障恢复。
- 记录 timer 注册数、动作计数、请求数、CPU、Private Working Set、日志增长和命中失败。
- 观察预热后是否持续单向异常增长；不得仅凭短时波动宣称泄漏。

### RT8 回滚

- 禁用编译/开发门禁后，正式应用恢复零宠物行为。
- 删除 Spike 临时配置与运行时包不影响用户配置。
- current gate 再次通过。

## 8. 时序与可见结果

### 8.1 播放器

| 验证 | 可见结果 | 机器证据 |
| --- | --- | --- |
| 逐帧时长 | 动作无固定 1.55s 空等或截断 | 计划/实际帧时间表 |
| 真实完成 | 最后一帧完整显示后恢复 | finished 事件与录屏 |
| 超时 | 卡帧后回安全状态 | timeout/recovered 日志 |
| 晚到完成 | 旧动作完成不改变当前画面 | instance ID 组合测试 |
| 累计漂移 | 连续循环无肉眼加速/减速 | 60 秒帧时序报告 |

时序继续门槛：60 秒连续播放后累计偏差不超过该动作一个最短帧时长，且无跳过未声明帧；若未达到，先修播放器时钟，不进入输入和命中结论。

### 8.2 动态命中

| 点位 | 期望 |
| --- | --- |
| 不透明头/身/尾 | 桌宠接收输入 |
| 半透明抗锯齿边缘 | 按包级 alpha 阈值确定 |
| 完全透明区域 | 底层桌面或窗口收到输入 |
| 动作新伸展区域 | mask 更新后可点 |
| 上一帧已收回区域 | mask 更新后穿透 |
| 菜单/模态期间 | 按锁合同暂停并成对恢复 |

## 9. 自动测试矩阵

| 类别 | fixture |
| --- | --- |
| 包 | 合法、坏 manifest、坏 atlas、坏 mask、未知动作、旧包 adapter |
| 播放 | loop、oneshot、不同 duration、超时、晚到 finished、隐藏中暂停 |
| 状态 | working/rest/sleeping/loading/error、快速切换、跨夜 fixture |
| 输入 | 499/500/501ms、位移阈值、左右方向、取消、重复释放 |
| 锁 | 菜单、Modal、异常关闭、旧 token 解锁新锁 |
| 命中 | frame mask、镜像 mask、三 DPI、桥失败、不允许矩形回退 |
| 隔离 | 每种故障后主线健康检查 |

## 10. Computer Use 与人工步骤

1. 在 100% DPI 打开沙盒，确认透明背景和安全静态帧。
2. 逐个播放现有 loop/oneshot，录制最后一帧到恢复状态。
3. 每个 BaseState 单击 10 次。
4. 长按拖拽 5 次，覆盖左右方向、窗口边缘和释放收势。
5. 动作中再次单击、长按并打开右键菜单。
6. 点击可见区域与透明区域，验证底层窗口是否收到点击。
7. 隐藏 1 分钟后恢复，检查 timer、状态和命中。
8. 在 125%、150% DPI 重复窗口、拖拽和命中主链路。
9. 执行受控包损坏并验证主应用。
10. 运行两小时，结束后执行零宠物回滚。

## 11. 证据文件

| 文件 | 内容 |
| --- | --- |
| `identity.json` | 源、包、adapter、二进制、哈希 |
| `environment.md` | Windows/WebView2/DPI/分辨率 |
| `frame-timing.csv` | 计划与实际帧时序 |
| `state-transitions.jsonl` | 四域状态迁移与 action instance |
| `input-matrix.md` | 单击/长按/拖拽/菜单结果 |
| `hit-test-matrix.md` | 点位、帧、DPI、预期与实际 |
| `fault-injection.md` | 故障、主线影响、回退结果 |
| `stability-2h.csv` | timer、CPU、内存、日志与动作计数 |
| `screenshots/` / `recordings/` | 原始 GUI 证据，仅外部保存 |
| `summary.md` | 脱敏结论、阻塞和哈希索引 |

## 12. 继续条件

全部满足才能写 `Runtime Spike: pass`：

1. 逐帧时长、真实完成、超时和晚到事件通过。
2. 500ms 长按、拖拽方向、释放收势和菜单锁通过。
3. 三档 DPI 下可见像素可点、透明像素穿透，且不使用永久矩形兜底。
4. 隐藏/恢复无重复 timer，状态能从权威快照收敛。
5. 所有包/窗口故障不阻断收入主线。
6. 两小时无卡死、命中漂移、日志刷屏或预热后持续异常资源增长。
7. 回滚后 current gate 与零宠物行为通过。

## 13. 停止条件

命中任一项即停止方案 B，不扩展动作或产品入口：

- 透明窗口无法稳定显示或 DPI 下出现不可接受裁切/模糊。
- 动态命中必须永久吞下整个矩形区域。
- WebView/原生桥故障能拖垮 Tauri 主进程或破坏配置。
- 拖拽持续误判单击，窗口位移与 run 动画明显打滑且无法通过小范围修正解决。
- 两小时出现重复 timer、卡死或持续异常增长且不能定位到 Spike 实现。
- 解决问题必须恢复 Godot 或进行超出方案 B 的整体渲染重写。

## 14. 回退路线

1. hit-test 桥不可行：评估“WebView 展示 + 极小原生命中桥”是否仍属方案 B；若仍不行，回到 `/idea` 比较原生渲染，不默认实现。
2. 逐帧播放器问题：保留 Tauri 沙盒，仅重做时钟与实例 token；不改素材。
3. 输入问题：保留静态/基础循环 Spike，暂停互动，不冒充完整通过。
4. 隔离失败：停止同进程 WebView 方案，保留 v1 零宠物主线。

## 15. 非正式产品边界

- Spike pass 不创建用户设置、托盘菜单、默认开关或公开资源。
- Spike 源码不得直接合并为 production path；必须先经代码 Review、PRD 参数回写和开发承接拆分。
- 旧包 adapter、派生 hit mask 和测试 run_loop 永远不能成为正式素材。
- 报告结论只能是 `pass` / `partial` / `fail` / `blocked`，不能写“桌宠已回归”。

## 16. 结论回写

- 时序、输入、命中与生命周期参数回写 `pet-runtime-state-machine.md`。
- vNext 解析与 hit mask 结论回写 `pet-package-vnext-contract.md`。
- 通过/失败及证据索引回写 `pet-return-traceability.md`。
- 只有 Runtime 与 Quality 两条 Spike 均通过，才允许重新进入 `/prd` 冻结正式公开入口。

## 17. 本轮执行结果（2026-08-10）

### 17.1 实现范围

- 在 `spikes/pet-return-runtime/` 建立独立 Tauri 2 沙盒；应用标识、窗口、状态目录和配置访问均与正式产品隔离。
- 使用 Classic S4.3 只读 fixture 和显式旧包 adapter；它只用于验证运行时，不声明旧包已成为 vNext 包。
- 实现逐帧 duration、绝对帧截止时间、真实 `animation_finished`、实例 token、oneshot 超时、隐藏暂停与恢复。
- 实现 500ms 长按、位移阈值、方向拖拽、`run_prepare -> run_loop -> run_stop` 和菜单 token 锁。
- 实现逐帧 alpha RLE、Win32 `SetWindowRgn` 动态命中、完整矩形拒绝及 100%/125%/150% DPI 坐标转换。
- 实现坏 manifest、坏 atlas 哈希、坏 mask、原生桥超时和连续沙盒故障的局部降级。
- 未修改 `apps/windows-v1/`、正式配置、默认入口或 current gate。

### 17.2 失败尝试与修正

第一版播放器按每次回调相对调度下一帧。真实运行 138.322 秒时，622 个帧样本的最大绝对漂移达到 1447.6ms，并在 120 秒错误触发基础 loop timeout。该实现判定失败。

修正为绝对帧截止时间，并把 `maxRuntimeMs` 限定为 oneshot 保护。新增 60 秒同步帧工作回归测试。修正后最长实机运行 113.864 秒，629 个帧样本的最大绝对漂移为 2ms、平均绝对漂移为 0.437ms，未再出现异常 timeout。

第一轮真实左拖使用窗口局部坐标；窗口跟随指针移动后，左移被错误判定为 `right`。失败证据保留后，输入仲裁和窗口位移统一改用 `screenX/screenY`。重新构建后的实机右拖判定为 `right`、左拖判定为 `left`，两者均在释放后播放 `run_stop` 并恢复 `working_loop`。

### 17.3 自动与短时实机结果

| 门禁 | 结果 |
| --- | --- |
| Node 行为测试 | 33/33 通过 |
| Rust 集成测试 | 6/6 通过 |
| `cargo fmt --check` | 通过 |
| `cargo clippy --all-targets --locked -- -D warnings` | 通过 |
| `cargo build --locked` | 通过 |
| 真实透明窗口 | 192x208；背景可见 |
| 原生动态区域 | 236-259 个逐行区域；采样应用延迟最大 2ms |
| 可见/透明原生探针 | 16 组全部匹配 |
| 2 秒隐藏/恢复功能探针 | 隐藏时帧 timer 为 0；恢复后仅 1 个 timer，并取得新权威 revision |
| 真实单击 | 80ms 单击触发 `working_ack`，完成后恢复 `working_loop` |
| 真实左右长按拖拽 | 约 500.8ms 进入 `run_prepare`；方向正确；释放后 `run_stop` 并恢复基础状态 |
| 60 秒隐藏/恢复 | 隐藏期间 timer 为 0；恢复后 timer 为 1，revision 由 1 更新为 2 |
| 主应用隔离 | 正式配置未读写，正式产品目录未修改 |
| 正式产品 current gate | v1.0.8 current gate 全量通过；Spike 未修改正式入口、默认配置或门禁脚本 |

仓库内证据入口：`spikes/pet-return-runtime/evidence/summary.md`。原始 JSONL 与桌面截图仅保存在仓库外证据目录，避免把本机路径和桌面内容写入仓库。

### 17.4 最终桌面验收

| 门禁 | 结果 |
| --- | --- |
| 三种 BaseState 单击 | `working` 10/10、`awake_rest` 10/10、`sleeping` 至少 10 次有效反馈通过；均无 timeout/P0 并恢复正确基础循环 |
| 左右拖拽压力 | 右向 5/5、左向 5/5；完整执行 `run_prepare -> run_loop -> run_stop` 并恢复最新 BaseState |
| 菜单锁 | 锁中点击不派发，解锁后输入恢复 |
| 连续输入 | 连续 10 次单击均完成；拖拽释放后立即单击未打断 `run_stop` |
| 透明点真实穿透 | 透明点点击后底层 Notepad 获得前台，Runtime 日志无新增 |
| 可见点真实命中 | 可见点点击后 Runtime 获得前台并记录输入 |
| 100% DPI | 通过 |
| 100% -> 125% DPI | 触发 P0 `hitmask_latency_exceeded_frame_duration`，未通过 |
| 150% DPI | 被 125% P0 停止规则阻塞，未执行 |
| 两小时稳定运行 | 被 125% P0 停止规则阻塞，未执行 |

真实切换到 125% 后，沙盒依次记录 `safe_static_fallback_requested`、`p0_runtime_stopped` 与 `window_hidden`，frame timer 归零并安全隐藏。fail-closed 合同有效，但 DPI 切换过程中的动态命中更新不满足 P0 可靠性要求。系统显示缩放已恢复为 100%，Runtime WebView 的 `devicePixelRatio` 已恢复为 1。

结构化证据：`spikes/pet-return-runtime/evidence/acceptance/runtime-gate-20260810.json`。本轮最终二进制 SHA256 为 `93EE5B28CED6A12A6A584565C5A78B9B7C71B4F19967B560EA2BA364A0975F8F`。

### 17.5 最小修复方向

1. 为 DPR/显示缩放变化增加显式过渡状态；过渡期间暂停或合并旧 hit mask 请求。
2. 缩放稳定后，只重放当前最新帧的命中区，不得应用旧比例队列中的 mask。
3. 保留 fail-closed 行为，不以永久矩形命中或静默放宽阈值冒充修复。
4. P0 日志必须记录 DPR 前后值、frame duration、native latency、队列代次与当前 frame ID。
5. 增加 `1 -> 1.25`、`1.25 -> 1.5`、旧 mask 晚到和最新 mask 重放测试。
6. 修复后先定向复验 125%/150%，两档通过后才重新开始两小时稳定运行。

### 17.6 独立判断

`LMM sandbox pass = false（未通过）`。

输入压力、真实透明穿透、逐帧时钟、隐藏恢复、坏包回退和主应用隔离均已获得证据，但真实 125% DPI 切换触发 P0，Runtime Gate 失败。150% 与两小时门禁因停止规则未执行，不得写成通过。Quality S2.2 的独立签核保持有效；两轨不得进入产品联调或正式产品路径。

### 17.7 S1.1 定向修复结果

S1.1 按 17.5 的既定方向完成了显式 DPI generation、旧代请求丢弃、转场期间最新帧合并、稳定后重放、首个转场慢调用单次重试、按倍率原生探针及完整 P0 诊断。Node 41/41、Rust 6/6、fmt、clippy、build 和 `git diff --check` 均通过；复验二进制 SHA256 为 `AAFEDDFDAF6A83098EA96D8507119F46F461EE3FDB64D5E86395146A01440749`。

真实 100%→125% 复验仍失败。`working_loop-009` 在 generation 0、scale 1 下执行原生命中更新 291ms，超过 90ms 帧时长；P0 于 `1786361023704` 记录，而 WebView 于 `1786361023723` 才收到 1→1.25 的 resize/DPR 事件。通知后的旧代请求已被 S1.1 正确丢弃，但通知前已经完成的慢调用无法由当前 generation 机制接管。

因此 `LMM sandbox pass` 继续为 false。150% 与两小时门禁仍未执行，系统缩放已恢复并核验为 100%，沙盒和 Settings 进程均已停止。下一轮若继续，必须先评审 S1.2 的延迟 fail-closed 分类：只允许紧随真实 DPR 变化的候选慢调用被转场接管，普通慢调用仍须失败；不得全局放宽 latency 阈值。

S1.1 结构化证据：`spikes/pet-return-runtime/evidence/acceptance/runtime-s1.1-gate-20260810.json`。

### 17.8 S1.5 普通帧持续运行失败

S1.5 的延迟分类器完成真实 100%→125%→150%→100% 循环，证明只有紧随真实 DPR 变化的慢调用才可由 DPI 转场接管，普通慢调用不会被全局放宽。然而在 100% 下持续播放约 14 分 42 秒后，`working_loop-007` 的原生命中调用耗时 494ms，超过 120ms 帧时长且没有真实 DPI 事件，沙盒正确触发 P0、清空 timer 并隐藏。

该失败把根因进一步收敛到“可见帧提交与同步原生命中更新的先后关系”及普通帧背压，而不是 DPI 分类本身。S1.5 未完成两小时门禁，结构化证据为 `spikes/pet-return-runtime/evidence/acceptance/runtime-s1.5-gate-20260810.json`。

### 17.9 S1.6 最终结果

S1.6 仅在隔离沙盒中完成以下修正：

1. 每帧先离屏准备，再应用原生命中区，成功后才提交可见画面。
2. 普通帧维持一个 in-flight 和一个最新 pending；新帧覆盖旧 pending，不形成无界队列。
3. DPI 转场和隐藏会丢弃尚未应用的普通 pending，并在稳定后只重放最新命中区。
4. `SetWindowRgn` 使用非同步重绘方式，避免窗口区域更新阻塞视觉提交。
5. 可见提交日志采用采样策略；两小时采样器从精确日志偏移开始读取，新 P0 在 5 秒内中止并保留部分证据。

最终候选：

- EXE：`spikes/pet-return-runtime/runtime-bin/pet-return-runtime-spike.exe`
- 大小：11,196,416 字节
- SHA256：`65E993C5BF062F1CE7EDFEECAFA592326532FA8E3A971416C8E8B6EF5640A86D`

最终门禁：

| 门禁 | 结果 |
| --- | --- |
| Node 行为测试 | 51/51 通过 |
| Rust 集成测试 | 7/7 通过 |
| fmt / clippy / build | 通过 |
| 正式产品 current gate | v1.0.8 全量通过 |
| 真实 DPI | 两轮 100%→125%→150%→100%，共 6 次转换通过；最终 generation 6、DPR 1 |
| 动态命中 | 三档倍率原生可见点/透明点探针通过；无永久矩形命中 |
| 两小时稳定 | 121 个样本、P0 0；工作集、私有内存、句柄和线程无持续增长 |
| 运行时尾态 | 1 个帧 timer、无 pending frame、无 DPI 转场、无 P0 |

两小时运行从 2026-08-10 20:56:52 +08:00 持续到 22:56:54，共 7202.594 秒。工作集由 31,789,056 降至 30,560,256 字节，私有内存由 8,638,464 降至 8,458,240 字节，句柄起止均为 355，线程起止均为 26，日志增长 628,589 字节。门禁窗口内原生命中延迟为 1-6ms，可见提交为 2.5-7.6ms。

帧遥测在两小时采样前形成约 4011ms 的一次性固定偏移，采样期间没有继续增长。该现象保留为遥测准确性债务，不能改写为“零漂移”，但不构成长时间累积漂移或本轮稳定性失败。

125%/150% 的 CopyFromScreen 截图被 Windows Settings 遮挡，已移动到 `rejected-captures/`，不得引用为有效截图。真实 DPI 状态、generation、原生探针和 100% 桌面截图均有效；正式产品级验收仍需重新取得三档无遮挡视觉证据。

结构化证据：`spikes/pet-return-runtime/evidence/acceptance/runtime-s1.6-gate-20260810.json`；稳定性证据：`spikes/pet-return-runtime/evidence/stability/s1.6-20260810T125651/`。

### 17.10 素材限制与独立判断

本 Runtime 使用的仍是 `classic_s4_3_runtime_only` 旧夹具。项目所有者明确不满意其中的电脑动画；该素材只保留为播放器测试输入，`vNextReady:false`，不得进入后续产品联调或发布资源。Quality S2.2 五动作黄金样片不含电脑道具，其独立签核不受影响。

最终判断：`Runtime Spike pass = true`；`LMM sandbox pass = false（待 G8）`。S1.6 证明方案 B 的承重运行时可行，但 Gate 2 还要求用已签核 vNext 质量包完成 G8；当前旧 fixture 不能代替该项。`Product return approved = false`。下一阶段只允许用无电脑 S2.2 包替换旧 fixture，在隔离产品级沙盒执行 G8 和 30 分钟编排审查，继续禁止正式入口、默认配置和发布包接入。

### 17.11 G8：S2.2 vNext 产品级沙盒验收

G8 已使用无电脑 Classic S2.2 五动作净化包执行，不再以旧 S4.3 电脑动画夹具充当产品级证据。候选身份如下：

- Runtime EXE：`spikes/pet-return-runtime/runtime-bin/pet-return-runtime-spike.exe`
- 大小：12,703,744 字节
- SHA256：`9A0590CFFD6696A7E001CFA1A8C4B8833A9B06540C84514277BAF7D099040EFD`
- 包版本：`0.2.0-sandbox.4`
- 包索引 schema：1；motion manifest schema：2
- 包索引 SHA256：`CD597264F4DE2AA0AF2BCABE6605F4ECEFAA54AC52D493827BD35716CBBBE60E`
- manifest SHA256：`F9624DB5A608AF10CFED3B59407C3F16CE7FF210A36A3276C2D709344AB2931B`
- 包树 SHA256：`250962401E536E166B66C16CC2B25C7149455466226927699522A91BA40173B6`

本轮 Node 58/58、Rust 7/7、fmt、clippy、build 与 v1.0.8 current gate 均通过。真实单击、左右拖拽、`run_stop` 收势、隐藏/恢复和无电脑素材边界通过；未观察到拖拽比例突变。

两小时门禁从 2026-08-10 23:55:31 运行至 2026-08-11 01:55:35，共 7203.8 秒、121 个样本。门禁窗口内 P0 为 0；工作集增加 466,944 字节，私有内存增加 425,984 字节，句柄 360→360，线程 29→26，未形成持续增长证据。前 30 分钟包含 5 次长按拖拽及一次隐藏/恢复编排，但不等同于完整动作目录的低重复产品审查。

定时窗口结束后，在尚未更改 Windows 缩放、仅打开显示设置准备 DPI 取证时，普通帧 `working_play_loop_a-013` 的原生命中区调用耗时 1610ms，超过 150ms 帧时长及 750ms 分类宽限，触发 `hitmask_latency_exceeded_frame_duration`。该事件发生于 scale 1、generation 2，不能归类为 DPI 转场。沙盒正确 fail-closed：请求安全回退、清空 timer 并隐藏窗口。

| G8 门禁 | 结论 |
| --- | --- |
| S2.2 vNext 解析与五动作播放 | 通过 |
| 单击、左右拖拽与隐藏恢复 | 通过 |
| 两小时定时观察窗 | 通过，但不能覆盖随后发生的 P0 |
| 100% 普通帧动态命中 | 未通过：定时窗口后出现 1610ms 原生调用 |
| 125% / 150% DPI | 未执行：按 P0 停止规则终止 |
| 坏 manifest / atlas 桌面注入 | 未执行：按 P0 停止规则终止；仅有自动测试证据 |
| 正式产品与默认配置 | 未修改，继续零宠物 |

结构化总证据为 `spikes/pet-return-runtime/evidence/acceptance/g8-s2.2-gate-20260811.json`；P0 原始摘要为 `g8-post-stability-p0-status.json` 与 `g8-post-stability-p0-event.jsonl`；定时证据位于 `evidence/stability/g8-s2.2-20260810T2356/`。

独立判断保持分层：`PetManager ready = true（仅限 S2.2 五动作）`，`Runtime Spike pass = true（S1.6 技术运行时）`，`LMM sandbox pass = false（G8 未通过）`，`Product return approved = false`。下一轮只允许调查和修复外部桌面/UI 负载下普通帧 `SetWindowRgn` 延迟；修复后必须从 G8 动态命中、三档 DPI、坏包桌面注入和两小时门禁重新取证。在此之前不得扩展 rest/sleep、业务事件、正式入口或默认配置。

| 未关闭缺口 | 最小补证动作 | 所需证据 | 通过标准 |
| --- | --- | --- | --- |
| 普通帧原生命中调用在外部 UI 负载下阻塞 | 在隔离沙盒复现并修复 `SetWindowRgn` 路径，不放宽普通帧 P0 阈值 | 失败前后事件顺序、候选 EXE 哈希、针对性自动测试、真实桌面日志 | 外部设置窗口打开/关闭与普通桌面负载均不触发 P0；fail-closed 仍有效 |
| 125% / 150% 产品级 DPI 未执行 | 修复 P0 后按 100%→125%→150%→100% 重跑 | 各倍率 DPR、generation、原生命中探针、无遮挡截图和日志 | 三档可见/透明命中正确，无 P0、无矩形命中、最终恢复 100% |
| 坏包桌面注入未执行 | 分别损坏 manifest 与 atlas，在桌面候选上启动 | 注入前包哈希、失败日志、窗口状态、主线健康与恢复证据 | 沙盒局部降级或隐藏，收入主线不受影响，恢复有效包后可重新启动 |
| 修复后长期稳定性未证明 | 同一修复候选重新运行至少两小时，并在结束后保留额外 UI 负载观察窗 | 资源样本、P0 扫描、timer/pending 尾态、日志增长 | 全观察期 P0 为 0；无持续资源增长；尾态仅一个 timer、无 pending |

### 17.12 S1.9 游标感知穿透最终复验

S1.9 将普通帧命中路径从同步窗口区域重建改为“逐帧 alpha mask + 原生游标位置判定 + 顶层 `WS_EX_TRANSPARENT` 切换”。原生线程每 8ms 读取一次全局游标，透明像素启用顶层穿透，可见像素关闭穿透；任一鼠标键按下时冻结当前模式。普通帧不再调用 `SetWindowRgn`，也没有放宽普通帧 P0 阈值。

锁定桌面候选：

- EXE：`spikes/pet-return-runtime/runtime-bin/pet-return-runtime-spike-s1.9-cursor-passthrough.exe`
- 大小：8,856,576 字节
- SHA256：`39F6DA5D191178CD0A74BCEDB71CDB39A5BAD69FC7A2DF7AF8E7A8471A1CC395`

最终门禁：

| 门禁 | 结果 |
| --- | --- |
| Node / Rust | 60/60、12/12 通过 |
| fmt / clippy / Release Build | 通过 |
| 正式产品 current gate | v1.0.8 全量通过，Rust 77/77 |
| 真实动态命中 | 100%、125%、150% 的可见点与透明点通过；无永久矩形命中 |
| 坏包桌面注入 | manifest 与 atlas 均局部降级，主线健康，恢复有效包后可重新启动 |
| 30 分钟编排 | 5 次长按拖拽及 1 次隐藏/恢复通过，权威 revision 1→2 |
| 两小时稳定运行 | 7203.7 秒、121 个样本、P0 0，无资源加速增长 |
| 结束后外部 UI 负载 | 两次打开并保持 Windows 显示设置，P0/错误 0 |
| 最终环境 | 100% / 96 DPI；Runtime、设置和辅助窗口已关闭 |

两小时资源从工作集 32,997,376 增至 34,394,112 字节，私有内存从 7,761,920 增至 9,707,520 字节，句柄 368→369，线程 36→29，日志增长 635,452 字节。全会话普通帧原生采样最大 4.438ms，视觉提交最大 10.8ms，最大绝对帧漂移约 1.9ms。结束后外部设置负载窗口的原生采样最大 1.378ms，没有重现 G8 的 1610ms 普通帧 P0。

S1.9 没有把以下内容包装成已完成：

1. 原生 8ms 指针 timer 随窗口销毁清理，但窗口隐藏期间尚未暂停。
2. `WM_TIMER` 回调当前忽略 `refresh_pointer_passthrough` 错误，正式运行时必须补诊断和 fail-closed 路径。
3. 干净 Release Build 通过，但 MSVC 重新链接得到 8,863,232 字节、SHA256 `FED0432F9DF41CD4D86419078F25B0FCFCE2AD9CCC75650BFAF46A4B88C1EE59`，未字节复现 GUI 候选；锁定候选身份仍以其 SHA256 为准。
4. S2.2 只有五个黄金样片动作，不能证明完整动作目录或长期低重复产品编排。

结构化证据为 `spikes/pet-return-runtime/evidence/acceptance/runtime-s1.9-gate-20260811.json`；两小时原始摘要与资源采样位于 `evidence/stability/s1.9-cursor-passthrough-20260811T1142/`。

分层结论更新为：`PetManager ready = true（仅限 Classic S2.2 五动作）`；`Runtime Spike pass = true`；`LMM sandbox pass = true（仅限隔离 G8 承重假设）`；`Product return approved = false`；`formal product entry allowed = false`。下一阶段只能进入正式开发前的生命周期/诊断补强与完整动作质量阶段，仍不得把 Spike 源码或五动作样片直接接入发布产品。

### 17.13 Runtime 产品化准备补强

本轮仅在隔离 Runtime 沙盒内关闭 S1.9 留下的三项工程债，不重新解释或替换 S1.9 的完整 G8 桌面证据。

#### 生命周期与故障合同

1. 隐藏前停止原生 8ms 指针轮询，并强制顶层窗口进入点击穿透；最后一份有效快照继续保留。
2. 恢复时只允许启动一个原生 timer，并立即执行一次权威命中刷新。
3. `show`、原生恢复或前端 `window_shown` 事件任一步失败，恢复事务都重新暂停原生轮询并隐藏窗口，记录 `window_restore_failed`，不留下半恢复窗口。
4. `WM_TIMER` 中的 `refresh_pointer_passthrough` 错误不再被丢弃。失败会停止 timer、强制点击穿透、锁存 `failed_closed` 和 `last_error`，并通过一次 `hit_test_bridge_failed_closed` 事件及 P0 IPC 错误对外暴露。
5. 即使诊断状态锁异常，也会返回固定兜底错误 `hit_test_bridge_failed_closed_diagnostic_unavailable`，不能误把 failed-closed 状态清空或重启。

真实 Win32 集成测试创建隐藏 `STATIC` HWND，证明安装后 polling active、暂停后 inactive、恢复后 active；注入原生刷新失败后 timer 停止、窗口保持点击穿透、桥锁存失败且不能重新启动。Node 组合测试同时覆盖恢复补偿和重复 timer 防护。

#### 构建可复现性调查

未启用确定性链接时，两次同路径干净构建大小均为 8,957,952 字节，但 SHA256 不同：

- `D4BDF2678C330D4936A61B8C87D6724A10E09CEEB501B7FC46B8F8B116986911`
- `B455CA93C0777D65522577C1A824EECA38187E75B4069F794BAD37E7D5862452`

二进制比较仅发现 24 个差异字节：四组 PE/调试时间戳字段和一个 16 字节 RSDS/PDB GUID；代码与资源区域未发现其他差异。沙盒随后在 `src-tauri/.cargo/config.toml` 固定 MSVC `/Brepro`。两次干净同路径构建及一次不设置环境变量的默认构建均得到：

- 大小：8,957,952 字节
- SHA256：`E371145962A85145E5922939ED1E68A735772DFA2E8308B91C3C4AB37D1FF461`

因此“当前隔离沙盒源码可生成逐字节一致的 Release EXE”已获证明。该新构建不是 S1.9 的完整 G8 候选，不能替换 `39F6...CC395` 的历史桌面验收身份。

#### 验证结果与边界

| 项目 | 结果 |
| --- | --- |
| Node 行为测试 | 60/60 通过 |
| Rust 测试 | 16/16 通过，包含真实 Win32 HWND 生命周期与故障注入 |
| `cargo fmt --check` | 通过 |
| clippy `-D warnings` | 通过 |
| Release build | 通过；首次尝试曾被运行中的沙盒进程锁定，停止该进程后通过 |
| 透明桌面渲染 | 192x208 窗口正确渲染 Classic |
| 桌面快捷键隐藏 | 不可判定；点击穿透窗口未可靠取得键盘焦点，未产生新 hidden/shown 事件，不计通过 |
| 正式产品代码与入口 | 未修改 |

结构化证据：`spikes/pet-return-runtime/evidence/acceptance/runtime-productization-prep-20260811.json`。

三项工程债更新为：隐藏轮询暂停 `closed`；原生轮询错误诊断和 fail-closed `closed`；MSVC 字节可复现性 `closed_for_isolated_sandbox`。剩余阻塞仍是完整 awake_rest、sleeping、业务事件和低重复动作目录，以及正式入口、设置、默认值和公开决策。

分层结论保持：`PetManager ready = true（仅限 Classic S2.2 五动作）`；`Runtime Spike pass = true`；`LMM sandbox pass = true（仅限隔离 G8 承重假设）`；`Product return approved = false`；`formal product entry allowed = false`。

### 17.14 首轮 12 动作包加载兼容（2026-08-12）

PetManager 以质量优先方式把首轮范围收敛为 12 个已经批准的动作，并生成新的确定性 vNext 包。LMM 本轮只把该包复制到隔离 fixture，扩展解析器的显式动作范围参数，不创建正式入口、不修改默认配置，也不启动桌面候选。

包身份：

- fixture：`spikes/pet-return-runtime/fixtures/classic-first-return-vnext/`
- 动作：12
- 帧：118
- manifest SHA256：`73A722D022EB4138B5FA8F7469D5304F08DC026EB3CB98D480A9C56CAE911E0E`
- package tree SHA256：`745AB4A26B4B149FC279686D9FA236384BDDF150DF2D18C2DBDA643A1A596A4E`

解析器保持旧 G8 五动作默认合同，同时允许调用方显式传入首轮动作范围和 ready 状态。新增测试证明：

1. 12 动作包可完整解析，manifest、文件和包树哈希有效。
2. working、awake_rest、sleeping、ack、ambient 和拖拽语义完整。
3. `run_prepare`、`run_loop`、`run_stop` 均保持 `mirrorSafe:true`。
4. 六个延后动作和退役的 `working_pounce` 不存在于包中。
5. 旧 5 动作预期不能静默接受扩展包，而是以 `g8_action_scope_invalid` 安全降级。

Node 行为测试 63/63 通过，其中首轮包新增测试 3/3。结构化证据：`spikes/pet-return-runtime/evidence/acceptance/first-return-package-loader-20260812.json`。

本节只签署 `LMM loader compatibility = pass`。既有 S1.9 的 `LMM sandbox pass = true` 仍只针对旧五动作隔离承重假设；新的 12 动作包尚未执行真实桌面 30 分钟观感、输入仲裁、三档 DPI、透明命中、坏包和两小时稳定性，因此：

- `LMM first-return desktop sandbox pass = false`
- `Product return approved = false`
- `formal product entry allowed = false`

### 17.15 主屏边缘启动与首轮调度桌面复核（2026-08-12）

本轮只修改隔离沙盒。桌宠窗口在首次 `show` 前读取主屏 Windows 工作区，以物理像素将 192×208 窗口放置在右下边缘，避开任务栏并保留 16px 安全间距。工作区过小时拒绝生成不可达位置，本轮不声称支持多显示器。

真实 Windows 11 桌面观察到的窗口坐标为 `(2352, 1168)`，尺寸为 `192×208`；换算后窗口右侧和底部均与工作区保留 16px，默认不遮挡屏幕中央内容。`window.show()` 之前会写入 `sandbox_positioned`，随后才写入 `sandbox_ready`。

首轮调度器直接消费 12 动作 manifest 的 `variantGroup`、`weight`、`cooldownMs` 和 `maxConsecutive`：

1. working 在 `working_play_loop_a` 与 `working_play_loop_b` 之间按循环边界轮换。
2. `working_observe` 仅在窗口可见、输入空闲、ActionLayer 为 `base_loop` 且冷却到期时插入。
3. 隐藏、降级、ack 或拖拽会取消待执行调度，不会用环境动作覆盖高优先级交互。
4. 固定随机种子 `10701` 只用于 QA 可复现性，不是正式产品随机策略。

在 2026-08-12 11:24 的样本窗口内，日志记录 `working_play_loop_a` 89 次、`working_play_loop_b` 54 次、`working_observe` 4 次和 `working_ack` 1 次启动。Computer Use 单击产生 `pet_input_press_pending -> pet_input_click -> working_ack -> working_play_loop_a`，证明单击反馈和基础恢复通过。

Computer Use 的快速 drag 不能持续 500ms，本次只证明位移超过阈值后会取消单击；不能将其写为 `run_prepare -> run_loop -> run_stop` 桌面通过。500ms 状态机合同已有自动测试，新包的真实长按仍待人工或专用输入工具补证。

最新自动回归为 Node 69/69、Rust 19/19，`cargo fmt --check`、clippy `-D warnings` 和 Release build 通过。Release 沙盒 EXE 大小为 8,947,200 字节，SHA256 为 `65AE79960DDE65710861B6BCBCA7EEEB4B8F0F21ED5957E7FB1461780D1755F1`。结构化证据：`spikes/pet-return-runtime/evidence/acceptance/first-return-edge-sandbox-20260812.json`。

分层结论为：`LMM first-return edge placement pass = true`；`LMM first-return working interaction pass = true`；`LMM first-return desktop sandbox pass = partial`；`Product return approved = false`；`formal product entry allowed = false`。三状态桌面切换、30 分钟人工观感、三档 DPI、坏包和两小时稳定性仍未关闭。

### 17.16 拖拽反向跟随修正（2026-08-12）

项目所有者在真实桌面发现：向左跑动后将鼠标改为向右移动，桌宠仍长时间保持左向。对应日志中，一次拖拽从 `x=2455` 开始，在 `x=2449` 产生唯一的 `left` 事件，到 `x=2205` 释放前未产生 `right`。

根因是 Input Arbiter 使用“当前鼠标 X - 500ms 长按起点 X”判断方向。鼠标向左移动得越远，反向后就需要先返回并跨过最初长按点才会切换为右向，因而表现为严重迟钝。

修正后使用滚动方向锚点累计最近水平移动：

1. 方向判定不再依赖原始长按点。
2. 反向累计达 4 个 CSS 像素即切换朝向，低于该阈值的鼠标抖动不翻转。
3. `run_loop` 单帧最长 90ms，方向事件后下一帧同步镜像画面和动态命中区。

TDD 证据先以“仍在原长按点左侧时已反向向右”场景稳定复现 `actual=[left] / expected=[left,right]`，实现后定向 6/6 和全量 Node 70/70 通过。新沙盒 EXE 大小为 8,947,200 字节，SHA256 为 `3C2C8AF00F008A0D3E923687E7C04CA828D661927323F51F029CA44613C2F7B6`，已重新在主屏右下边缘启动。

结构化证据：`spikes/pet-return-runtime/evidence/acceptance/drag-direction-reversal-fix-20260812.json`。自动方向合同与真实桌面连续左右折返均已通过。项目所有者确认反向跟随“明显流畅了许多”；同一运行实例记录 23 次方向切换，其中向左 12 次、向右 11 次。方向反转门禁关闭，但 `LMM first-return desktop sandbox pass` 仍由其余产品级门禁独立判定。

### 17.17 方向画面与动态命中区同步（2026-08-12）

方向镜像现由独立的方向帧合同统一解析。每一帧只读取一次方向，随后同时得到画面 `mirrorX` 与对应的镜像命中区；运行时先应用并探测原生命中区，再提交同一个请求中的画面，避免两个异步链路各自读取可变方向。

新增行为门禁覆盖右向原始命中区、左向镜像命中区、非法方向拒绝，以及 DynamicHitCoordinator 原生应用和视觉提交消费同一个方向帧对象。全量 Node 回归从 70 项增加到 74 项并全部通过，Rust 19/19、fmt、clippy 和 Release build 保持通过。

项目所有者在新构建中完成两轮 500ms 长按连续折返。进程 `41348` 共记录 10 次方向事件；连同初始右向，共有 11 个方向帧进入同步审计，其中左向 5 个、右向 6 个。全部 11 个原生命中验证事件都找到同方向、同帧 ID、同命中签名的画面提交，未配对为 0，原生命中验证到画面提交最大相差 1ms，P0 事件为 0。

本轮 EXE 大小为 8,947,712 字节，SHA256 为 `9ACFF0B0A2CA95F9C38A3AC410F672739CCC267C4F07926FE1872C3BFDD6F5B7`。结构化证据：`spikes/pet-return-runtime/evidence/acceptance/drag-direction-hitmask-sync-20260812.json`。`directional visual-hitmask sync = pass` 与 `real 500ms drag = pass`；整体 `LMM first-return desktop sandbox pass` 仍为 `partial`，正式产品入口继续关闭。

### 17.18 三基础状态与状态化单击恢复（2026-08-12）

为避免桌面验收依赖重复计算班次，隔离沙盒增加了仅供验收的权威 BaseState 控制器。数字键 1/2/3 分别映射 `working`、`awake_rest`、`sleeping`；由于透明非标准 WebView 在 Computer Use 下不能可靠取得键盘焦点，真实桌面证据改用仅限沙盒的中键循环。该控制器不属于正式产品交互，也未修改正式入口或默认配置。

进程 `32272` 从 `working:r1` 启动，中键依次产生并接受 `awake_rest:r2`、`sleeping:r3` 和 `working:r4`。三个状态各执行一次可见区域左键单击：

| 基础状态 | 单击动作 | Frame Player 实际时长 | 完成后恢复 |
| --- | --- | ---: | --- |
| `awake_rest` | `rest_ack` | 960.1ms | `awake_rest_loop` |
| `sleeping` | `sleep_ack` | 1321.7ms | `sleeping_loop` |
| `working` | `working_ack` | 961.5ms | `working_play_loop_a` |

每个 ack 只有一个 Frame Player 完成；日志中的第二条同名 `animation_finished` 是状态机镜像事件，不能重复计数。三次切换均被接受，拒绝为 0，观察窗口内 P0 和 degraded 事件为 0。工作态恢复后继续正常执行 A/B 轮播。

本轮候选 EXE 为 8,948,224 字节，SHA256 `9E9A946CC5D700A99AE16B82339A75407292E71AAC01B923ABC5E6C3EC8738EB`；Node 76/76、Rust 19/19、fmt、clippy 和 Release build 通过。结构化证据及八张原始桌面截图见 `spikes/pet-return-runtime/evidence/acceptance/base-state-desktop-20260812.json`。

分层结论：`three base-state desktop = pass`；`state-specific click and restore = pass`；`Product return approved = false`。30 分钟人工观感、三档 DPI、坏包和两小时稳定性仍需独立关闭。

### 17.19 首轮 12 动作包 30 分钟桌面观察（2026-08-12）

锁定候选进程 `32272` 在主屏右下边缘连续运行 30 分钟，Computer Use 按 `working -> awake_rest -> sleeping -> working` 覆盖三个基础状态。观察窗口从 13:48:18 至 14:18:19，共取得 31 个一分钟资源样本；进程未退出，P0、degraded 和 fail-closed 事件均为 0。

动作启动分布如下：

| 动作 | 次数 | 观察结论 |
| --- | ---: | --- |
| `working_play_loop_a` | 294 | 作为主要工作陪伴循环 |
| `working_play_loop_b` | 178 | 与 A 轮换，无连续卡死 |
| `working_observe` | 14 | 冷却后低频插入并恢复基础循环 |
| `awake_rest_loop` | 74 | 清醒休息段稳定，无跨态动作 |
| `sleeping_loop` | 150 | 睡眠段稳定，无透明空帧 |
| `sleep_twitch` | 6 | 90 秒冷却后低频插入，无连续刷动作 |

视觉观察未发现异常比例跳变、边缘残影、透明空帧、状态串台或 ActionLayer 卡死。20 分钟节点从睡眠切回工作时，第一次中键落在透明像素并被底层窗口接收；刷新后在可见身体像素成功切态，作为动态穿透的补充证据保留。

资源采样中，工作集从 37,531,648 增至 37,724,160 字节，私有内存从 9,543,680 增至 9,744,384 字节；句柄 395→395，线程 28→28，未见加速增长。日志增加 658,151 字节，来源是沙盒逐帧证据模式，不代表正式产品日志策略，产品化前仍需收敛采样量。

结构化证据：`spikes/pet-return-runtime/evidence/acceptance/first-return-30min-observation-20260812.json`；资源明细：`spikes/pet-return-runtime/evidence/stability/first-return-30min-20260812/`。

分层结论：`Computer Use 30-minute observation = pass`；项目所有者随后明确回复“完成”，故 `project-owner 30-minute signoff = pass`；`Product return approved = false`。三档 DPI、坏包和两小时稳定性仍需用当前 12 动作候选独立复验。

### 17.20 首轮包 DPI、动态命中与坏包门禁（2026-08-12）

当前 12 动作候选在真实 Windows 显示设置中按 `100% -> 125% -> 150% -> 100%` 完成复验。三个倍率的逻辑窗口均为 192x208，物理命中区分别为 192x208、240x260 和 288x312；每档可见像素单击均触发对应 ack，透明像素均未产生新的桌宠单击事件。DPI 转场安全暂停成对出现，最终恢复到 100% / 96 DPI，P0 为 0。

坏包门禁分别覆盖 manifest 哈希不符、运行时目录出现合同外文件和绑定图集哈希不符。三种情况均局部降级到 `embedded_static_shape`，窗口保持可见、进程未崩溃；恢复有效包后重新进入 `ready_for_first_return_sandbox` 并播放基础动作。正式产品代码、入口、默认配置与 current gate 均未修改。

证据：

- `spikes/pet-return-runtime/evidence/acceptance/first-return-dpi-20260812.json`
- `spikes/pet-return-runtime/evidence/faults/first-return-corrupt-package-20260812/result.json`

结论：`first-return DPI gate = pass`；`dynamic visible hit = pass`；`transparent pass-through = pass`；`corrupt package fallback = pass`。这些结论只适用于隔离桌面沙盒，不能授权正式产品入口。

### 17.21 真实 Windows 睡眠恢复与 S3 根因关闭（2026-08-12）

首轮真实睡眠恢复暴露过一个 P0：系统恢复后 `GetCursorPos` 短时返回访问拒绝，旧桥将瞬态桌面切换错误直接锁存为永久 fail-closed，导致前端停止。该失败证据保留在 `evidence/stability/s3-sleep-resume-20260812T190742/`；19:41 与 19:42 的两次工具调用未形成有效睡眠周期，不计入通过证据。

修正仅作用于隔离 Runtime：桌面切换窗口内的暂态游标读取失败保持点击穿透并继续探测，连续恢复后记录 `native_pointer_desktop_transition_recovered`；非暂态错误及超出恢复预算的错误仍进入既有 fail-closed。修正后的真实 Windows 睡眠约 72.427 秒，观察到 24 次暂态失败与恢复事件；前端、原生心跳均恢复，进程存活，19 个采样完整，P0 为 0。系统调用返回记录中的 `win32Error=1300` 与 `accepted=true` 原样保留，不改写为零错误。

修复后短时 smoke 继续通过隐藏/恢复、右向转左向拖拽、方向画面与命中区同步，尾态收敛到 `working / base_loop / idle`，P0 为 0。

证据：

- `spikes/pet-return-runtime/evidence/stability/s3-transient-fix-20260812T194600/s3-analysis.json`
- `spikes/pet-return-runtime/evidence/stability/s3-transient-fix-20260812T194600/s3-events.jsonl`
- `spikes/pet-return-runtime/evidence/acceptance/post-s3-smoke-20260812T1955/analysis.json`

结论：`real Windows sleep/resume = pass`，但只证明当前候选的沙盒恢复合同，不代表正式产品生命周期已经实现。

### 17.22 首轮包最终两小时稳定性与沙盒签核（2026-08-12）

最终候选 EXE 为 9,016,832 字节，SHA256 `2463940CA9AFC0BECD2DB9252F558315FA1AE1CA19CCB89BD480B27BABEB826B`。进程 `41124` 从 19:58:59 运行至 22:00:06，共 7266.473 秒、121/121 个一分钟样本。观察器同时监控进程、前端心跳和原生心跳，避免再次出现“进程存活但 WebView 已停摆”的假通过。

前 30 分钟编排执行 5 次 500ms 长按和 1 次隐藏/恢复，共取得 31 个状态样本；P0 为 0，每次交互后均恢复 `working / base_loop / idle`。Frame Player、陪伴调度器和前端心跳在结束时各只有 1 个 timer，权威 revision 因隐藏/恢复从 1 增至 2。运行中出现三段真实桌面切换瞬态错误，共 378 次 `GetCursorPos` 失败，均通过新恢复合同自行收敛，没有锁存 P0。

资源结果：工作集 33,136,640 -> 35,467,264 字节，最大 35,508,224；私有内存 7,884,800 -> 10,444,800 字节，最大 10,522,624；句柄 398 -> 398，线程 37 -> 31，WebView 进程 6 -> 6。后 10 个样本已进入平台期，未见持续加速增长。CPU 累计增加 91.562 秒，约占单核观察时间的 1.26%。日志增加 6,229,207 字节，来源是沙盒逐帧证据模式；正式产品入口前必须改为采样或摘要日志，不能沿用该密度。

最终机械回归为 Node 81/81、Rust 21/21，`cargo fmt --check`、clippy `-D warnings`、Release build、UTF-8 和 `git diff --check` 全部通过。Release 重建后 EXE 大小和 SHA256 未变化，证明本节验收身份可复现。

此前 `first-return-2h-20260812` 因 P0 提前停止；`first-return-2h-retry-20260812T1625` 虽取得 121 个资源样本，但前端心跳已停摆且采样器误报完成，明确归类为失败证据。最终签核只引用本节的新候选、新心跳采样器与完整证据目录。

证据：

- `spikes/pet-return-runtime/evidence/stability/final-2h-20260812T1959/final-2h-analysis.json`
- `spikes/pet-return-runtime/evidence/stability/final-2h-20260812T1959/g8-session-summary.json`
- `spikes/pet-return-runtime/evidence/stability/final-2h-20260812T1959/final-runtime-status.json`
- `spikes/pet-return-runtime/evidence/stability/final-2h-20260812T1959/stability/runtime-samples.csv`

最终分层判断：

- `PetManager reduced-scope ready = true`，仅限 Classic 首轮 12 动作。
- `PetManager full-catalog ready = false`，A2/C 六个动作继续延后。
- `LMM first-return desktop sandbox pass = true`，仅限隔离 12 动作沙盒。
- `LMM sandbox pass = true`，仅限本 PRD 定义的承重与首轮回归范围。
- `Product return approved = false`。
- `formal product entry allowed = false`。

下一阶段不再重复本轮 Spike 门禁。若项目所有者决定继续，应单独授权正式产品回归实现，并为正式入口、设置开关、默认关闭、配置迁移、日志采样、回滚和发布验收建立开发计划；Spike 源码和样片不得直接视为产品产物。
