# LetsMakeMoney Windows v1.0 验证记录

## 当前结论

| 项目 | 状态 |
|---|---|
| 当前阶段 | M7 验收通过，可进入 Stable 发布收口 |
| M0 结论 | 通过 |
| M1 结论 | 通过 |
| M2 结论 | 通过 |
| M3 结论 | 通过 |
| M4 结论 | 通过 |
| M5 结论 | 通过（通知区左键与 Explorer 重启后重新注册均已通过） |
| M6 结论 | 通过（9/9） |
| GUI 验收 | 独立解压候选核心黄金路径通过 |
| 发布判断 | 可进入 Stable 发布收口；多显示器待补证但不阻塞，仍需干净提交重打包 |

## M0 自动门禁

| 检查 | 预期 | 当前结果 |
|---|---|---|
| JSON 合同解析 | 所有合同与 fixture 可解析 | 通过 |
| 配置默认值 | `config_version=6`，大小周周型为 `null` | 通过 |
| 黄金 fixture | 单休、双休、大小周、午休、夜班、日历齐全 | 通过 |
| 窗口合同 | 四窗口、托盘、关闭与单实例语义完整 | 通过 |
| 日志合同 | 保存、窗口、托盘、诊断语义事件与脱敏完整 | 通过 |
| 视觉合同 | 窗口尺寸、token 与 100/125/150 DPI 冻结 | 通过 |
| 正式工程隔离 | 不修改 v0.9 业务路径，不含宠物能力 | 通过 |
| Rust 骨架 | `cargo check --locked --offline` | 通过 |
| Web 骨架 | `npm run build:web` | 通过 |
| 文档 | 验证、人工验证、发布清单与基线存在 | 通过 |
| `git diff --check` | 无空白错误 | 通过 |

运行入口：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m0.ps1
```

## 证据边界

- M0 只证明合同和工程边界可进入实现，不证明 Tauri GUI、托盘、DPI 或发布包可用。
- v0.9 回退包身份来自已发布 tag 与版本验证文档；当前工作树没有本地发布 Zip，因此未重新计算文件哈希。
- Web 构建临时使用已批准技术 Spike 的本地依赖目录；M0 没有证明全新环境可以离线安装依赖，正式 bootstrap 留给后续里程碑。
- M0 图标是确定性生成的无宠物金币占位图标，不代表 v1.0 正式品牌图标已经验收。
- 真实 125%/150% DPI、通知区真实左键与 Explorer 重启均已在 M7 通过。

## M1 自动与视觉门禁

| 检查 | 当前结果 |
|---|---|
| Node、React、TypeScript、Tauri、Rust 依赖精确锁定 | 通过 |
| Windows named mutex 单实例 | 通过 |
| 迷你、工作台、Settings、Wizard 注册与复用 | 通过 |
| 关闭隐藏与迷你窗口任务栏策略 | 通过 |
| 生产级颜色、字体、间距、圆角、阴影和动效 token | 通过 |
| Button、IconButton、Field、Switch、Segmented、Progress、Feedback | 通过 |
| focus-visible、ARIA 与 reduced motion | 通过 |
| 正式应用壳宠物能力数量为 0 | 通过 |
| Rust/Tauri 离线编译 | 通过 |
| React/TypeScript/Vite 生产构建 | 通过 |
| 344×120、920×640、760×560、780×580 目标尺寸 | 通过 |
| 浏览器 DPR 1.0、1.25、1.5 布局溢出检查 | 通过，裁切控件 0 |

运行入口：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m1.ps1
```

视觉证据：`.tmp_m1_mini.png`、`.tmp_m1_workbench.png`、`.tmp_m1_settings.png`、`.tmp_m1_wizard.png`。这些临时截图仅用于开发校准，不进入发布包。

边界：DPR 仿真证明逻辑像素布局稳定，但不替代 M7 的真实 Windows 125%/150% 清晰度和系统缩放验收。
## M2 计算、配置与支持服务

- 结果：通过。
- 静态合同：10/10 通过。
- Rust 行为测试：10/10 通过。
- 覆盖：单休、双休、大小周显式锚点、午休冻结、跨夜归属、日历优先级、v5→v6 去宠物字段迁移、原子写入、无变化、写入失败与副作用失败回滚、日志轮换、脱敏诊断、更新失败降级。
- 命令：`powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m2.ps1`。
## M3 迷你收入视图与工作台

- 结果：通过。
- 静态合同：10/10 通过。
- 前端生产构建：通过。
- Playwright：迷你视图 `344×120`、工作台 `920×640` 均无页面级溢出；工作台内容完整收口在可视区。
- 交互：键盘可聚焦迷你主入口；Today/Calendar 切换、日期选择与“跟随规则/工作日/休息日”覆盖通过。
- 证据：`.tmp_m3_mini.png`、`.tmp_m3_workbench.png`、`.tmp_m3_calendar.png`（仅本地临时验收，不进入发布包）。
- 命令：`powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m3.ps1`。

## M4 Wizard 与 Settings

- 结果：通过。
- 静态合同：11/11 通过；Rust 配置与故障注入回归：10/10 通过。
- Wizard：月薪、单双休、大小周显式周型、工作/午休自动推算、确认、返回、取消和关闭通过。
- Settings：四任务组、保存成功、无变化、失败、恢复默认确认和脏草稿关闭确认通过。
- 失败语义：模拟配置目录不可写时显示可读错误，输入 `13500` 保留；校验错误自动聚焦首个无效输入。
- 大小周：选择“大小周”后“下一步”保持禁用，用户明确选择“大周”或“小周”后才可继续。
- DPI：DPR 1.0、1.25、1.5 下 `760×560` 的页面宽高均无溢出；该结果不替代真实 Windows DPI。
- 证据：`.tmp_m4_settings_1.png`、`.tmp_m4_settings_125.png`、`.tmp_m4_settings_15.png`、`.tmp_m4_wizard.png`。
- 命令：`powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m4.ps1`。

## M5 托盘、窗口生命周期与诊断

- 结果：通过；通知区真实左键与 Explorer 重启后重新注册均已在 M7 通过。
- 自动门禁：静态合同 12/12、Rust 平台测试 13/13、Release 构建通过。
- 正式资源：修复 Tauri `custom-protocol` 构建特性后，Release EXE 不再访问开发用 `localhost`，可直接加载内嵌前端。
- 真实桌面：迷你收入视图、今日工作台、Settings 窗口复用、关闭隐藏、数据与支持页均通过 Computer Use 检查。
- 支持能力：诊断摘要复制成功，内容不含绝对路径；更新查询出现 HTTP 404 时显示可读降级信息并明确当前版本可继续使用。
- 能力检测：WebView2 注册表检测覆盖 64 位、32 位和当前用户路径，实际运行显示“原生能力：可用”。
- 日志：已记录 `tray.registered`、`window.show_requested`、`window.policy_applied`、`window.shown`、`window.hidden`、`support.diagnostic_copied` 和 `update.check_failed`。
- 证据目录：`.tmp_acceptance/v1.0-m5-20260724-154117/`。
- 真实通知区左键：通过。实际点击系统通知区图标完成“恢复 → 隐藏 → 再恢复”，日志连续记录 `tray.left_click`、`window.hidden label=mini`、`window.show_requested label=mini`、`window.policy_applied label=mini skip_taskbar=true` 和 `window.shown label=mini`。
- 任务栏策略：通过。迷你窗口恢复时没有任务栏入口；Settings 显示时任务栏入口出现，关闭后正常消失。
- Explorer 重启：通过。Explorer 进程由 `19352` 切换为 `20252` 后应用进程保持运行，日志重新记录 `tray.registered detail=provider=tray-icon-0.24.1 explorer_recovery=TaskbarCreated`；重启后真实左键可继续隐藏并恢复迷你窗口。
- 命令：`powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m5.ps1 -SkipBuild`。

## M6 宠物安全下线与迁移收口

- 结果：通过，9/9。
- 当前树已移除旧 Godot 主工程、native 扩展、宠物资源、旧安装链、旧依赖副本和 v0.2-v0.9 脚本。
- v1 生产 UI、Rust 运行时、Tauri 配置和当前 README 中没有用户可见宠物能力。
- 配置迁移明确丢弃 `pet_id`、`pet_package_id`、`pet_package_version`、`pure_pet_mode`、`pet_scale` 和 `click_through`。
- Rust 配置测试 3/3 通过；失败保存、无变化和成功事务没有回归。
- `v0.9-beta` tag 仍存在，抽查到 205 个 Godot、宠物与 native 历史对象，未改写历史恢复基线。
- 新增源码与 Zip 双重零宠物门禁、宠物退役审计和 v0.9 回退说明。
- 官方 v0.9 Release 包真实回退已通过：官方 Zip SHA256 为 `B10FDE2027D4ABC71C41F0F7AC7BDCE3D93AEB8AFAF4058BA1A592B6A75CC1EC`；隔离启动日志确认 v0.9、native、托盘和窗口能力加载成功。
- v0.9 继续使用 `%APPDATA%\LetsMakeMoney\`，v1 使用 `%APPDATA%\io.letsmakemoney.windows\`；v1 三个关键文件在回退测试前后哈希一致。
- 回退证据：`.tmp_acceptance/v0.9-rollback-20260724/evidence/`。
- 命令：`powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_m6.ps1`。

## M7 最终候选验收

### 候选身份

| 对象 | 结果 |
|---|---|
| 分支 | `agent/v1.0-review` |
| 源码基线 | `aa7c0b93780d7511a6551624f2eea88595cee51f` |
| 工作树 | 含尚未提交的 v1.0 实现；仅作为 Acceptance 候选 |
| Zip | `releases/v1.0/LetsMakeMoney-v1.0-windows-x86_64.zip` |
| Zip SHA256 | `8EB5060994A4265B90F57A50E304F7F698754AD055CAD53E9AEE08F19F4B334B` |
| EXE SHA256 | `286F99D3B6C03B4D22362E968502C5644562CE2CCA7B8B892184547BC32B5334` |
| WebView2Loader SHA256 | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |
| 新候选 GUI 复验路径 | `releases/v1.0/LetsMakeMoney-v1.0-windows-x86_64/LetsMakeMoney.exe` |
| 上一候选完整黄金路径证据 | `.tmp_acceptance/v1.0-final-20260724-172154/evidence/` |

### 自动门禁

- `scripts/verify_v10.ps1`：通过。
- `scripts/verify_v10_docs.ps1`：通过；19 份当前文档可按 UTF-8 读取，本地链接有效，三个候选身份事实源哈希一致。
- `scripts/package_v10.ps1`：通过。
- `scripts/verify_v10_package.ps1`：通过。
- Rust：14/14 通过；包体验证定向测试 4/4 通过。
- 前端构建、组件/流程/可访问性和 Playwright 视觉回归：通过。
- 零宠物、许可、包内容、UTF-8、乱码、文档状态和 `git diff --check`：通过。
- 新候选包重新运行 `scripts/verify_v10.ps1`、`scripts/package_v10.ps1` 与 `scripts/verify_v10_package.ps1`：通过。
- 包内 `WebView2Loader.dll` 与系统 WebView2 Runtime 的分发边界已在第三方声明和包体验证中分别校验。

### 真实桌面结果

| 路径 | 结论 | 证据 |
|---|---|---|
| 无配置首次启动进入 Wizard | 通过 | 窗口标题“LetsMakeMoney 开始配置”；日志 `wizard.opened reason=config_missing_or_invalid` |
| Wizard 三步与完成 | 通过 | 月薪 10000、双休、08:00–18:00、午休 12:00–14:00 |
| 首次配置持久化 | 通过 | `evidence/config-after-first-run.json` |
| 迷你收入视图 | 通过 | 工作状态、今日已赚、进度和剩余有效工时可见 |
| Today 工作台 | 通过 | 收益、日薪、时薪、时间线和月度摘要完整 |
| Calendar | 通过 | 月视图、工作日/休息日/手动调整图例完整 |
| Settings 四任务组 | 通过 | 收入与作息、日历、窗口与启动、数据与支持均可打开 |
| Wizard → Settings 配置刷新 | 通过 | Settings 首次打开即显示月薪 `10000` |
| Settings 无变化保存 | 通过 | 显示“没有需要保存的更改” |
| 日志语义 | 通过 | `evidence/debug-final.log` 包含配置、窗口、托盘、支持与更新事件 |
| 通知区真实左键 | 通过 | `evidence/tray-restore-0.jpg`、`evidence/tray-restore-1.jpg` 与 `evidence/tray-left-click.log` |
| Explorer 重启与托盘重注册 | 通过 | `evidence/explorer-restart-tray-restore.jpg` 与 `evidence/explorer-restart-tray.log` |
| 真实 125%/150% DPI | 通过 | `evidence/dpi-125-*.png` 与 `evidence/dpi-150-*.png`；迷你、Today、Settings、Wizard 均无裁切或重叠 |
| 长期运行 | 通过 | 约 95 分钟连续运行无资源漂移；项目所有者确认按约 100 分钟门禁通过；`evidence/soak-owner-accepted-summary.json` |
| 任务栏策略 | 通过 | 左键恢复迷你窗口后日志重新应用 `skip_taskbar=true`；Settings 关闭后任务栏入口消失 |
| 用户环境恢复 | 通过 | 测试进程已停止；验收前配置与日志已恢复 |
| v0.9 官方包桌面回退 | 通过 | 官方 Release Zip 与 `SHA256SUMS.txt` 一致；隔离 EXE 启动日志、配置目录差异和恢复证据位于 `.tmp_acceptance/v0.9-rollback-20260724/evidence/` |

### 新候选定向 GUI 复验

| 路径 | 结论 | 证据 |
|---|---|---|
| 新 EXE 启动 | 通过 | 实际进程路径为新候选解包目录，窗口标题为 `LetsMakeMoney` |
| 迷你收入视图 | 通过 | 已下班、今日已赚、100% 进度与剩余有效工时显示正常 |
| 今日工作台 | 通过 | 收益、日薪、时薪、时间线、月度摘要和 Settings 入口完整 |
| Calendar | 通过 | 月视图、工作日/休息日图例、当天高亮和调整日期入口完整 |
| Settings 四任务组 | 通过 | 收入与作息、日历、窗口与启动、数据与支持均可打开 |
| Settings 收入与作息 | 通过 | 月薪、休息模式、上下班和午休字段正确读取 |
| Settings 无变化保存 | 通过 | 显示“没有需要保存的更改” |
| 配置不污染 | 通过 | 复验前后 `config.json` SHA256 均为 `02297DC840464938AEB0A9B83898842865CC98742DC2BCEA0E9E89338BF4E7DA` |
| 日志语义 | 通过 | `tray.registered`、`window.show_requested`、`window.policy_applied`、`window.shown`、`window.hidden` 均可读 |
| 通知区左键双向切换 | 通过 | 真实鼠标先隐藏、再恢复；日志和截图位于 `.tmp_acceptance/v1.0-final-20260724-172154/evidence/` |
| Explorer 重启恢复 | 通过 | 托盘自动重新注册，重启后左键隐藏/恢复继续有效，恢复后任务栏无迷你窗口入口 |
| 迷你窗口任务栏策略 | 通过 | 恢复后 `skip_taskbar=true`；Settings 关闭后任务栏入口正常消失 |
| 进程清理 | 通过 | 复验结束后新候选进程已停止 |

### 结论边界

- 当前结论：**通过**。
- 无新的业务逻辑发布阻塞。
- 多显示器安全回落因当前设备只有一台显示器而待补证；项目所有者确认该项不阻塞本次 Stable，且不得追溯改写为通过。
- 当前包由脏工作树生成，不得直接作为 Stable Release；人工门禁关闭后必须基于干净提交重新打包并复核哈希。
