# LetsMakeMoney Windows v0.9 Beta 验证

## 状态

| 项目 | 当前口径 |
|---|---|
| 阶段 | 动画合同修订实施中；输入与业务事件层已完成，带电脑候选被“无电脑、玩耍优先”方向替代 |
| 当前门禁 | `V09-CORR-006/008/009`：完成四个玩耍优先动作、运行时接入、重打包与独立验收 |
| 稳定回退 | Windows v0.8 Beta |
| 发布判断 | 不可发布；`V09-BUG-001` 已关闭，但旧候选不代表最终动画合同，必须重新打包并重新执行独立验收 |
| 独立验收 | 2026-07-18 结论为“未通过”，见本文件与 `manual-verification.md` |

### 2026-07-21 动画视觉方向修订

- PetManager S4/S5 已证明 custom profile、图集、逐帧时长、分层证据与 QA 门禁可用。
- 项目所有者实际审查认为电脑/键盘叙事生硬，要求全部移除，并以小猫玩耍作为主要视觉表达。
- 当前带电脑的 `working_loop`、`working_ack`、`lunch_relief`、`lunch_return` 仅保留为历史过程证据，结论为“不进入发布候选”。
- 新候选必须遵循 `pet-animation-play-first-revision.md`；在新素材通过人工视觉门禁前，动画观感保持“待验证”，v0.9 保持不可发布。

### 2026-07-21 Windows UI 精修定向复验

本轮使用隔离配置目录启动 Godot Debug 构建，仅验证 Windows UI 精修和窗口生命周期，不改变历史候选包身份，也不替代最终发布验收。

| 范围 | 结论 | 证据 |
|---|---|---|
| Panel 折叠态与展开态 | 100% DPI 通过 | `.tmp_ui_review/screenshots/panel-expanded.png` |
| 今日详情窗口 | 100% DPI 通过 | `.tmp_ui_review/screenshots/today-detail.png`；窗口以独立原生 `Window` 显示，日志记录 `embedded=false`、窗口 ID、位置和尺寸 |
| Settings 工资、显示、通用代表页 | 100% DPI 通过 | `.tmp_ui_review/screenshots/settings-salary.png`、`settings-display.png`、`settings-general.png` |
| OptionButton 下拉菜单 | 100% DPI 通过 | 暖色纸面 popup 正常，无深色系统菜单回退 |
| Wizard 欢迎、收入、作息、宠物与确认链路 | 100% DPI 通过 | `.tmp_ui_review/screenshots/wizard-welcome.png`、`wizard-income.png`、`wizard-pet.png`、`wizard-confirm.png` |
| Wizard 内容滚动与固定操作栏 | 100% DPI 通过 | 作息页滚动到底部后，下班时间和只读有效工时均可见，操作栏不遮挡内容 |
| 125%/150% DPI | 待验证 | 本轮未切换系统缩放，不得写为通过 |
| 全量无导出回归 | 通过 | `scripts/verify_v09.ps1 -SkipExport`；包含 v0.6-v0.8、M4、native 与当前 v0.9 合同 |

今日详情此前的失败原因是子窗口创建后处于不可见原生窗口状态。现改为初始隐藏、创建时临时关闭根窗口子窗口嵌入，并通过 `popup(Rect2i)` 显式展示；关闭后再次打开沿用同一原生窗口生命周期。该修正未改工资、配置、托盘或动画业务逻辑。

## v0.9 历史候选身份

- 分支：`main`
- 开发 HEAD：`c4290823f888a9f6092b125c41d88bb731576772`，工作区包含未提交的 v0.9 实现；独立验收需重新核对。
- Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`
- Zip 大小：`50,197,694` 字节
- Zip SHA256：`72972CB344FEE25549DC930A45809C2DAE82F29F9DA4915CE341B995A956E83F`
- EXE 大小：`120,667,528` 字节
- EXE SHA256：`BA41DBB61BCE35926C0FB0677CA8722A9F9F71BC8A815A59FE0C82EAC0AC8403`
- DLL 大小：`1,606,144` 字节
- DLL SHA256：`E3E2030003A7DA725446A3873C3EC2E19D9442B98A67F24A771E76BD0BAD5089`
- 说明：这是首轮独立验收使用的历史候选，不是 Release 身份，也不包含 2026-07-18 后冻结的新动画输入/事件合同；最终验收不得继续使用该身份。

## 实施起点

- 分支：`main`
- HEAD：`c4290823f888a9f6092b125c41d88bb731576772`
- 描述：`v0.8-beta-1-gc429082-dirty`
- v0.8 发布标签：`v0.8-beta`
- v0.8 发布 Zip 预期路径：`releases/v0.8/LetsMakeMoney-v0.8-beta-windows-x86_64.zip`
- v0.8 发布 Zip 已记录 SHA256：`A2065B82F7674E5A19AC4FD467E7DEA3E8D665E3C148634C3721B7BD90AE098E`
- 当前本地未保留上述 Zip，不能用其他构建冒充该发布产物。

## V09-M0 行为矩阵

### 窗口、托盘与任务栏

| 模式 | 初始显示 | 托盘左键隐藏 | 托盘左键恢复 | 恢复后任务栏入口 | 证据 |
|---|---|---|---|---|---|
| 普通模式 | 桌宠与 Panel 可见 | 窗口隐藏、进程保留 | 窗口恢复 | 显示 | v0.8 验收事实 + M4/M5 门禁 |
| 纯桌宠 | 桌宠与 Panel 可见 | 窗口隐藏、进程保留 | 窗口恢复 | 不显示 | v0.8 验收事实 + window policy 门禁 |
| 原生能力不可用 | 可交互窗口 | 按能力降级 | 可由普通窗口找回 | 显示 | 兼容降级合同 |

### 模态、Popup 与点击穿透

| 入口 | 打开时 | 关闭时 | 证据 |
|---|---|---|---|
| Settings | 暂停点击穿透，主桌宠输入受保护 | 恢复窗口策略与点击穿透 | `passthrough_suspended/resumed` 日志合同 |
| Wizard | 暂停点击穿透，避免输入穿过 | 恢复窗口策略与点击穿透 | `passthrough_suspended/resumed` 日志合同 |
| Godot Popup/菜单 | 暂停点击穿透 | Popup 关闭后刷新命中区 | Overlay 生命周期门禁 |
| 原生托盘菜单 | 由 Windows 原生窗口处理 | 不改变桌宠持久状态 | Windows native 门禁 |

## 自动验证

| 命令 | 作用 | 当前结果 |
|---|---|---|
| `scripts/test_v09_verification_contract.ps1` | v0.9 验证入口完整性 | 通过 |
| `scripts/test_v09_behavior_baseline.ps1` | 动画回退、1.55 秒恢复和输入分类基线 | 通过 |
| `scripts/test_v09_schedule.ps1` | 跨端工资向量、官方日历、跨夜作息与状态边界 | 通过 |
| `scripts/verify_v09.ps1 -SkipExport` | v0.8、M4 与 v0.9 基线 | 通过，5.5 秒 |
| `scripts/verify_v09.ps1` | 含 M5 导出烟测的完整基线 | 通过，15.9 秒 |
| `scripts/test_v09_configuration_experience.ps1` | Wizard/Settings 草稿、推算、保存事务 | 通过 |
| `scripts/test_v09_window_experience.ps1` | Panel、今日详情、窗口回落与模态引用 | 通过 |
| `scripts/test_v09_pet_package.ps1` | 包校验、导入、透明帧、命中区与方向 | 通过；可重复执行 |
| `scripts/test_v09_pet_animation.ps1` | 事件状态机、输入仲裁与动作恢复 | 通过 |
| `scripts/test_v09_pet_integration.ps1` | Classic/多多、选择、回退、尺寸与基线 | 通过 |
| `scripts/verify_v09_package.ps1` | 包内容、许可、哈希和独立解压烟测 | 通过 |
| `scripts/check_asset_licenses.ps1` | 源码素材许可清单；排除生成型构建/发布副本 | 通过 |
| `scripts/test_check_asset_licenses.ps1` | 发布副本不误报、未知源码素材仍阻断 | 通过 |
| `scripts/check_third_party_compliance.ps1` | 第三方依赖、许可和分发边界 | 通过 |
| `scripts/check_docs_status.ps1` | v0.9 候选与历史发布事实一致性 | 通过 |

M5 导出烟测生成 `build/LetsMakeMoney.exe`，大小为 113,026,776 字节；使用隔离的 `.tmp_appdata/verify_v09_m5` 启动、响应和退出均通过。该产物仅为开发烟测，不是候选发布包。

## V09-M1 计薪与日程门禁

- Windows 直接复用 iOS `salary-schema/v1` 的 7 组黄金向量，单双休、大小周、午休、官方调休、手动覆盖、缺失年份和闰年结果误差不超过 0.01 元。
- 2026 官方节假日数据版本为 `cn-2026-gov-20251104`；缺失年份与损坏 JSON 均降级为周规则，并通过 `calendar.dataset.*` 语义日志标明。
- `WorkScheduleResolver` 支持日班与跨夜班次，夜班按开始日归属；工作覆盖夜间睡眠，午休覆盖工作。
- 状态边界 `23:00`、`07:30`、跨午夜午休、调休夜班与系统时间倒退均通过。
- 配置由 v4 安全迁移到 v5，保留旧字段并新增日历版本、今日窗口位置/尺寸及宠物包身份字段。
- v0.8 全量自动回归与 M5 隔离导出烟测通过。

## V09-M4 至 M6 宠物门禁

- Classic 与多多使用同一 v1 宠物包 schema、validator 和 importer，不存在按 `pet_id` 的一次性导入特判。
- 图集逐帧时长、pivot、脚底线、动作偏移、命中策略、许可、来源和文件 SHA256 已进入运行时包合同。
- 修正两套图集清单中指向全透明单元格的声明；所有已声明帧均包含可见像素。
- 全透明纹理的命中区现在为空，不再错误扩张成整张图片可点击。
- Godot 自动生成的 `.import` 元数据不属于宠物包载荷，重复导入后校验保持稳定。
- 动画由请求 token、优先级、完成事件和超时保护驱动，不再依赖固定 1.55 秒恢复。
- single/double/hold/drag 分类、环境动作、指针跟随、逐帧命中区及 union 降级已有自动门禁。
- 运行时将宠物包逻辑尺寸和 pivot 归一化到 v0.8 视觉基线；旧资源保持原场景几何。
- Classic 是新配置默认候选；旧用户选择保持不变；Settings 提供回滚；多多以通用动作映射进入真实观感验收。

## 候选包验证

- `package_v09.ps1 -SkipExport` 生成便携 Zip并包含项目许可、受限素材许可、第三方声明与许可证原文。
- `verify_v09_package.ps1` 校验包名、版本、manifest、内部 checksums、未登记二进制及许可结构。
- 验证器把 Zip 解压到 `.tmp_release/verify_v09_package`，以隔离 APPDATA 启动 EXE 5 秒；进程保持存活并可终止。
- 启动烟测不等于真实桌面工作流通过，不能替代下方人工门禁。
- 素材许可检查只审计源码候选素材；`build/`、`releases/` 和 `.tmp*` 中的生成副本由包内 manifest、checksums 与第三方合规检查负责，避免把同一图标副本误报为新素材。

## 结论约束

- 自动化通过只表示开发门禁通过，不代表真实 Windows GUI 验收通过。
- `V09-ACC-001` 必须使用候选发布包、日志、配置和截图执行。
- 在独立验收完成前，不得写“可发布”。
- 尚未通过或尚未完成：`V09-M2-011/012`、`V09-M3-011`、`V09-M6-003/004`、`V09-M7-009` 至 `013`，以及除身份锁定和验收结论外的 `V09-ACC` 项。

## 2026-07-18 独立验收

### 验收对象

- 分支：`main`
- HEAD：`c4290823f888a9f6092b125c41d88bb731576772`
- Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`
- Zip SHA256：`72972CB344FEE25549DC930A45809C2DAE82F29F9DA4915CE341B995A956E83F`
- 独立解压目录：`.tmp_acceptance/v0.9-20260718-102105/extracted`
- EXE SHA256：`BA41DBB61BCE35926C0FB0677CA8722A9F9F71BC8A815A59FE0C82EAC0AC8403`
- Native DLL SHA256：`E3E2030003A7DA725446A3873C3EC2E19D9442B98A67F24A771E76BD0BAD5089`
- 启动时间：`2026-07-18 10:23:57 +08:00`

### 结论

**未通过。** 候选身份与预期一致，独立解压 EXE 可以启动，Windows 原生窗口、托盘和任务栏策略初始化成功；但发布包运行时拒绝 Classic Pro 与多多两套 v0.9 宠物包，并回退到 `cat_orange_v2`。该问题直接阻断动画、宠物包、回滚和多宠物相关验收，也阻断发布。

### 发布阻塞证据

实际候选运行日志记录：

```text
PetManager.package rejected root=res://assets/pets/packages/letsmakemoney-classic-pro errors=["missing package file: spritesheet.webp", "missing package file: extra-actions.webp", "missing package file: LICENSE.md", "missing package file: SOURCE.md"]
PetManager.package rejected root=res://assets/pets/packages/duoduo-cat errors=["missing package file: spritesheet.webp", "missing package file: extra-actions.webp", "missing package file: LICENSE.md", "missing package file: SOURCE.md"]
PetManager._ready: scanned pets=3
PetManager._ready: current_pet=cat_orange_v2
```

现有 `verify_v09_package.ps1` 复跑返回退出码 `0` 并打印 `Package verification passed: 0.9-beta`，但其隔离运行日志同时出现上述两条 `package rejected`。因此当前包验证只证明 EXE 存活，不能证明 v0.9 宠物包在导出产物中可消费。

### 分项结果

| 验收模块 | 结论 | 证据 | 备注 |
|---|---|---|---|
| 候选身份 | 通过 | `identity.json`、文件哈希 | Zip、EXE、DLL 与锁定身份一致 |
| 独立解压启动 | 通过 | `candidate-debug.log` | 仅证明进程和基础窗口链路可启动 |
| Classic Pro 与多多加载 | 未通过 | `runtime-evidence.txt` | 两套包均被拒绝，实际只加载 3 个旧宠物 |
| 包验证门禁 | 未通过 | `package-verifier-runtime.txt` | 出现运行时拒绝仍返回成功 |
| 工资、Wizard、Settings、DPI、输入、穿透、托盘、回滚、稳定运行 | 待验证 | 本轮未继续 | 核心候选身份已失真，继续验收不能代表 v0.9 目标 |
| v0.8 回归 | 部分通过 | 启动与原生初始化日志、既有自动门禁 | 独立候选的完整桌面回归未执行 |

### 证据位置与环境恢复

- 证据目录：`.tmp_acceptance/v0.9-20260718-102105/evidence`
- 候选日志：`candidate-debug.log`
- 候选配置：`candidate-config.json`
- 关键日志摘录：`runtime-evidence.txt`
- 包验证器隔离日志摘录：`package-verifier-runtime.txt`
- 原候选进程已结束。
- `%APPDATA%\LetsMakeMoney\config.json` 与 `debug.log` 已按验收前备份恢复，恢复后 SHA256 与备份一致。

## 2026-07-18 V09-BUG-001 定向复验

### 新候选身份

- Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`
- Zip SHA256：`7D1D7199362779AE2EE4E5DC9F8278C0B730D26AD39DB761A9680930E0AFD4BD`
- EXE SHA256：`B6CACC6D802E85DE6FBEB0D8BD0C5864B3ADEC2E72E9EDF72F0B6BD88D1D1E07`
- Native DLL SHA256：`E3E2030003A7DA725446A3873C3EC2E19D9442B98A67F24A771E76BD0BAD5089`

### 结果

| 项目 | 结论 | 证据 |
|---|---|---|
| 原始宠物图集导出 | 通过 | 四个 WebP 使用 `Keep File (exported as is)`，原始字节和 manifest SHA256 保持一致 |
| Classic 运行时加载 | 通过 | 包验证隔离日志包含 `PetManager.package shadow_loaded id=letsmakemoney-classic-pro` |
| 多多运行时加载 | 通过 | 包验证隔离日志包含 `PetManager.package shadow_loaded id=duoduo-cat` |
| 运行时拒绝断言 | 通过 | 任一包出现 `PetManager.package rejected root=res://assets/pets/packages/` 时验证器返回非零 |
| 旧坏包识别 | 通过 | `test_v09_exported_pet_payload.ps1` 能拒绝缺少原始 WebP 的旧候选 |
| 新候选包验证 | 通过 | `verify_v09_package.ps1` 返回 `Package verification passed: 0.9-beta` |

`V09-BUG-001` 的导出阻塞已关闭。该结果仅证明宠物包可被候选运行时真实消费，不替代动画观感、输入仲裁、DPI、托盘和长时间运行验收。由于产品随后取消双击并将长按/拖动统一为方向跑步，新动作合同实现后必须重新生成最终候选并从头执行独立验收。

## 2026-07-18 动画输入合同定向验证

| 项目 | 结论 | 证据 |
|---|---|---|
| 快速单击 | 通过 | 释放后立即产生状态感知 `single`，不再等待双击窗口 |
| 连续快速点击 | 通过 | 两次输入保持为两次单击，不产生独立双击产品动作 |
| 跑动进入 | 通过 | 按住 500ms 后产生 `run_prepare`，阈值前移动不接管窗口 |
| 跑动移动与释放 | 通过 | `run_move` 驱动窗口并保持最近水平朝向；释放产生 `run_settle`，不补发单击 |
| 旧宠物降级 | 通过 | 缺少跑动帧时仍可移动窗口，并恢复最新基础状态 |
| 自动回归 | 通过 | `verify_v09.ps1 -SkipExport`，包含 v0.9、v0.8、v0.7、v0.6 与 M4 门禁 |

该验证只证明运行时输入与回退合同。Classic 新跑动、工作、环境和业务事件素材尚未完成 S2-S5，真实动作观感与最终候选仍不得写为通过。

## 2026-07-19 业务事件层定向验证

| 项目 | 结论 | 证据 |
|---|---|---|
| 首次观察 | 通过 | 只建立当日快照与收益桶基线，不补播启动前已经发生的事件 |
| 午休开始与复工 | 通过 | `scheduled_work -> lunch` 只产生一次 `lunch_started`；`lunch -> scheduled_work` 产生 `work_resumed` |
| 下班 | 通过 | 有效工作进度完成后离开工作/午休区间，产生一次 `work_finished` |
| 收益里程碑 | 通过 | 工作状态跨越 100 元内部里程碑时产生 `income_milestone`，同一收益桶不重复 |
| 跨日去重 | 通过 | 日期变化重建基线，不把前一日状态跳变补播到新日期 |
| 显式交互与 Modal | 通过 | 事件仍被观察和去重，但动作活跃、跑步、显式输入或 Overlay 期间只记录跳过原因，不排队补播 |
| 缺失素材 | 通过 | 通用候选无法解析到专用动作时记录 `missing_frames` 并保持最新基础状态 |
| 全量回归 | 通过 | `verify_v09.ps1 -SkipExport` 覆盖 v0.9 全模块及 v0.6-v0.8、M4/native 历史门禁 |

语义日志入口为 `pet.business_event.observed`、`pet.business_event.requested` 和 `pet.business_event.skipped`。该结果证明事件触发和安全降级，不证明 S2-S5 最终动画的观感、锚点与流畅度。
