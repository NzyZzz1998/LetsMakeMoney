# LetsMakeMoney Windows v1.0.7 进度

## 追踪信息

| 字段 | 内容 |
| --- | --- |
| 目标版本 | Windows v1.0.7 Stable |
| 开发基线 | `main@12b6b03ce91b716d49590e21eb8dd7fe90fa283c` |
| 当前公开版本 | v1.0.6 Stable |
| 当前阶段 | V107-ACC 锁定 dirty 候选验收通过；项目所有者已批准发布收口 |
| 总体状态 | 验收通过，发布门禁未完成 |
| PRD | `prd.md` |
| 开发计划 | `dev_plan_v1.0.7.md` |
| 追踪矩阵 | `traceability.md` |
| 开发日志 | `../../logs/dev_log_v1.0.7.md` |
| 最后更新 | 2026-08-04 |

## 版本目标

关闭 v1.0 系列已有可信、窗口、隐私、日历与维护缺口，交付按日加班和月度工时总结，并以可回退的条件门禁收口视觉、安全和性能候选。

## 总体进度

| 里程碑 | 状态 | 完成数 | 阻塞 | 最近证据 |
| --- | --- | ---: | --- | --- |
| V107-M0 事实、基线与行为刻画 | 已完成 | 10/10 | 无 | `scripts/verify_v107_m0.ps1` 通过 |
| V107-M1 Current、配置、版本与 IPC 合同 | 已完成 | 12/12 | 无 | `scripts/verify_windows_current.ps1` 通过 |
| V107-M2 窗口、隐私与自由拖动 | 已完成 | 14/14 | 无 | 自动门禁通过；左右各 15 次真实贴边通过 |
| V107-M3 日期事务、加班领域与局部边界 | 已完成 | 14/14 | 无 | M3 与 current 聚合门禁通过 |
| V107-M4 月度总结与六周日历 | 已完成 | 10/10 | 无 | 首次高 DPI 失败修复后，真实 100%/125%/150% DPI 通过 |
| V107-M5 Combobox 与窗口表面条件 Spike | 已完成 | 12/12 | 无 | 四窗口三档 DPI、双主题、键盘/ARIA 和窗口表面最终结论通过 |
| V107-M6 治理、证据、安全与性能条件门禁 | 已完成 | 14/14 | 无 | M6 门禁 6/6；CSP 撤回，10+10 性能基线完成 |
| V107-M7 聚合门禁与唯一候选 | 部分完成 | 10/12 | 干净发布提交与最终候选尚未建立 | 修复 dirty 候选、M7/current 聚合门禁与包内容审计通过 |
| V107-ACC 独立候选验收与状态收口 | 部分通过 | 14/14 | 干净发布身份 | 首次失败、阻塞修复及 `evidence/acceptance-dpi-summary.json` 均已记录 |
| **合计** | **部分通过** | **110/112** | **干净发布提交与最终候选身份仍待完成** | **三项产品阻塞已关闭；dirty 候选仍禁止发布** |

## Checklist

### V107-M0 事实、基线与行为刻画

- [x] V107-M0-001 基线与发布身份
- [x] V107-M0-002 PRD、追踪、原型与证据失效条件
- [x] V107-M0-003 current/historical 脚本调用图
- [x] V107-M0-004 config v8 四层合同基线
- [x] V107-M0-005 首次置顶行为基线
- [x] V107-M0-006 Mini/Workbench 显示事务基线
- [x] V107-M0-007 Mini 自动隐藏与拖动事件夹具
- [x] V107-M0-008 日期与加班测试向量
- [x] V107-M0-009 日历、主题和 DPI 证据矩阵
- [x] V107-M0-010 证据、候选和环境恢复合同

### V107-M1 Current、配置、版本与 IPC 合同

- [x] V107-M1-001 current manifest
- [x] V107-M1-002 唯一 current 验证入口
- [x] V107-M1-003 CI 单入口
- [x] V107-M1-004 current 负向测试
- [x] V107-M1-005 config v8 四层对齐
- [x] V107-M1-006 历史迁移与失败保护
- [x] V107-M1-007 版本 metadata 单一读取链
- [x] V107-M1-008 版本六点与包身份一致性
- [x] V107-M1-009 配置事务 IPC fixture
- [x] V107-M1-010 Dashboard/窗口 IPC fixture
- [x] V107-M1-011 加班 IPC fixture 骨架
- [x] V107-M1-012 M1 聚合门禁

### V107-M2 窗口、隐私与自由拖动

- [x] V107-M2-001 首次置顶应用时序
- [x] V107-M2-002 置顶失败与重试
- [x] V107-M2-003 visibility lease
- [x] V107-M2-004 Workbench 生命周期补偿
- [x] V107-M2-005 Mini 四种进入前状态恢复
- [x] V107-M2-006 桌面错误与浏览器 fallback 分离
- [x] V107-M2-007 10,000 条状态序列
- [x] V107-M2-008 30 次真实贴边
- [x] V107-M2-009 条件最小修复或停止
- [x] V107-M2-010 move/finalize/recover
- [x] V107-M2-011 安全抓取区 DPI 阈值
- [x] V107-M2-012 出屏与找回回归
- [x] V107-M2-013 隐私竖条排除丢失判断
- [x] V107-M2-014 窗口综合回归

### V107-M3 日期事务、加班领域与局部边界

- [x] V107-M3-001 共享日期调整事务
- [x] V107-M3-002 日期状态覆盖
- [x] V107-M3-003 日期事务失败补偿
- [x] V107-M3-004 overtime schema 与模型
- [x] V107-M3-005 overtime repository
- [x] V107-M3-006 overtime service 与 commands
- [x] V107-M3-007 前端 overtime 状态与 service
- [x] V107-M3-008 精度、范围与删除
- [x] V107-M3-009 费率快照
- [x] V107-M3-010 日期类型、历史、跨夜与跨月
- [x] V107-M3-011 加班编辑弹窗全状态
- [x] V107-M3-012 四类 IPC fixture 完整覆盖
- [x] V107-M3-013 前端/Rust 局部边界
- [x] V107-M3-014 行为等价与回滚门禁

### V107-M4 月度总结与六周日历

- [x] V107-M4-001 三项工时聚合函数
- [x] V107-M4-002 过去/当前/未来月
- [x] V107-M4-003 数据源失败分离
- [x] V107-M4-004 日历加班标记
- [x] V107-M4-005 5/6 周布局
- [x] V107-M4-006 820×620 无纵向滚动
- [x] V107-M4-007 数据状态覆盖
- [x] V107-M4-008 主题与长内容
- [x] V107-M4-009 三档 DPI
- [x] V107-M4-010 原型与真实壳复验

### V107-M5 Combobox 与窗口表面条件 Spike

- [x] V107-M5-001 原生 select 基线
- [x] V107-M5-002 Combobox 隔离样件
- [x] V107-M5-003 键盘与焦点
- [x] V107-M5-004 ARIA、错误与翻转
- [x] V107-M5-005 FR-010 条件判定
- [x] V107-M5-006 FR-010 实施或回退
- [x] V107-M5-007 四窗口表面基线
- [x] V107-M5-008 三种表面 owner 样件
- [x] V107-M5-009 四窗口 × 三 DPI 证据
- [x] V107-M5-010 FR-011 接受或回退
- [x] V107-M5-011 窗口行为回归
- [x] V107-M5-012 Spike 结论与证据入口

### V107-M6 治理、证据、安全与性能条件门禁

- [x] V107-M6-001 脚本 lifecycle 索引
- [x] V107-M6-002 historical 误用保护
- [x] V107-M6-003 current 文档收口
- [x] V107-M6-004 脱敏摘要与原始证据索引
- [x] V107-M6-005 Windows 11 支持矩阵
- [x] V107-M6-006 Windows 10 证据或支持收窄
- [x] V107-M6-007 多显示器暂不验证声明
- [x] V107-M6-008 IPC/文档/隐私扫描
- [x] V107-M6-009 CSP 隔离候选
- [x] V107-M6-010 CSP 全链路回归
- [x] V107-M6-011 CSP 启用或撤销
- [x] V107-M6-012 性能基线采集
- [x] V107-M6-013 条件性能优化或停止
- [x] V107-M6-014 局部治理边界回归

### V107-M7 聚合门禁与唯一候选

- [x] V107-M7-001 1.0.7 身份统一
- [x] V107-M7-002 current/CI 最终自检
- [x] V107-M7-003 隔离打包入口
- [x] V107-M7-004 candidate/published 包验
- [x] V107-M7-005 TypeScript 与前端构建
- [x] V107-M7-006 Rust 与 release build
- [x] V107-M7-007 v1.0.7 聚合门禁
- [x] V107-M7-008 文档、隐私和 diff 检查
- [ ] V107-M7-009 干净提交唯一候选
- [ ] V107-M7-010 产物哈希锁定
- [x] V107-M7-011 包内容审计
- [x] V107-M7-012 验收文档候选身份

### V107-ACC 独立候选验收与状态收口

- [x] V107-ACC-001 候选身份核对：通过
- [x] V107-ACC-002 独立解压与环境保护：通过
- [x] V107-ACC-003 首次置顶：托盘真实鼠标组合补证后通过
- [x] V107-ACC-004 Mini/Workbench 显示事务：修复后通过，首次失败证据保留
- [x] V107-ACC-005 自动隐藏最终结论：通过
- [x] V107-ACC-006 拖动、回落与找回：部分通过
- [x] V107-ACC-007 共享日期事务：通过
- [x] V107-ACC-008 加班全流程：通过，休息日、跨夜 owner date 与重启持久化已补证
- [x] V107-ACC-009 月度总结与六周日历：通过
- [x] V107-ACC-010 Combobox/窗口表面最终结论：通过
- [x] V107-ACC-011 Win11 双主题与三档 DPI：首次失败修复后通过
- [x] V107-ACC-012 核心回归：版本与更新链路修复后通过
- [x] V107-ACC-013 Win10 与多显示器边界：部分通过
- [x] V107-ACC-014 环境恢复与发布判断：部分通过，环境已恢复但发布门禁未完成

## 当前阻塞

- `V107-BUG-001`：已修复，自动测试与真实 GUI 定向复验通过。
- `V107-BUG-002`：已修复，自动测试与连续三次真实 GUI 定向复验通过。
- `V107-BUG-003`：已修复，六周日历摘要在真实 125%/150% DPI 下定向复验通过。
- Windows 10 已收窄为未验证环境；多显示器暂不验证。二者均不得进入 v1.0.7 通过声明。
- M4/M5 的真实 100%/125%/150% DPI 已完成，首次失败证据与修复后通过证据均已保留。
- `V107-M7-DIRTY-20260804-03` 只允许用于 DPI 定向复验；源树为 dirty，禁止作为 Release 附件。
- 项目所有者已批准发布收口；V107-M7-009 与 V107-M7-010 仍需以干净提交重新构建并锁定最终身份。

## 最近验证

- `scripts/verify_v107_m0.ps1`：通过；2 组行为测试与 7 组证据检查通过。
- `scripts/verify_architecture.ps1`：通过；既有 15 组行为套件、结构、M6 与工具解析门禁全部通过。
- `scripts/verify_v107_m1.ps1`：通过；5 组 M1 合同、config 迁移保护、6 项版本 metadata 行为与 13 个 IPC 场景通过。
- `scripts/verify_v107_m2.ps1`：通过；6 组静态合同、10,000 条确定性状态序列和 Mini 自动隐藏行为套件通过。
- `scripts/verify_v107_m3.ps1`：通过；3 组静态合同、日期事务 6/6、加班状态 13/13、加班 service 5/5 与 15 个 IPC 场景通过。
- `scripts/verify_v107_m4.ps1`：通过；月度总结 10/10、加班月状态 7/7、5/6 周布局、独立失败状态和 820×620 合同通过。
- `scripts/verify_v107_m5.ps1`：通过；Combobox 14/14、窗口表面 5/5、静态合同 3/3 通过。
- `scripts/verify_v107_m6.ps1`：通过；脚本治理、支持矩阵、脱敏证据、CSP 撤回、性能停止门禁和局部治理边界 6/6 通过。
- `scripts/verify_v107_m7.ps1`：通过；身份、隔离打包、candidate/published 负向合同、包内容与发布边界通过。
- `scripts/verify_v107.ps1 -Milestone M7 -CandidatePath <dirty acceptance Zip>`：通过；M1-M7 聚合门禁通过。
- `scripts/verify_windows_current.ps1`：2026-08-04 最终复跑通过；current manifest、M1-M7、架构与文档门禁、TypeScript strict、Vite、Rust 67/67、fmt、clippy 与 `git diff --check` 全部通过。
- dirty 验收候选 Zip SHA256：`173207AE508DB8D8504818F16B21165164E6C50C29ABF74C4C4D5C08B40CC05D`；EXE SHA256：`760C0E80952181BA80352187DCCE9C6823F3BE19B0EC1BC04553ACCC34156035`。
- 性能正式采样：10 次冷启动 + 10 次暖启动；暖 Mini P95 1,067ms、暖 Workbench P95 1,442ms、JS gzip 140,841 bytes、最大长任务 0ms 通过；冷启动约 6.2s 超阈值并保留量化债务。
- CSP 隔离候选：Mini bootstrap 不可用，候选按门禁撤销；正式 `csp: null` 未改变。
- `scripts/verify_windows_current.ps1`：通过；唯一 current 入口完成 manifest、M1-M3、架构、文档、TypeScript、Vite、Rust 66 项测试、fmt、clippy 与 `git diff --check`。
- Windows 11 单显示器 100% DPI：左、右边缘各 15 次真实贴边均通过，不需要第二次点击；Workbench 展开前态恢复、重启可找回和用户环境恢复通过。
- Windows 11 单显示器 100% DPI：真实 Tauri 中 2026-08 六周月和 2026-09 五周月均一屏完整显示，月度总结、图例、浅色/深色主题及加班编辑器取消路径通过。
- Windows 11 单显示器 100% DPI：圆角 Combobox 的指针、键盘、Escape、外点击、ARIA、条件字段和双主题通过；Settings/Workbench/Mini 单一表面与隐私状态恢复通过。
- `ACC-V107-20260804` 独立验收：14/14 项已评估，7 项通过、4 项部分通过、3 项未通过；发现 `V107-BUG-001` 与 `V107-BUG-002` 两项发布阻塞。
- 独立验收外部证据：`ACC-001` 至 `ACC-028`、两份运行日志；仓库内脱敏摘要为 `doc/releases/v1.0.7/evidence/acceptance-summary.json`。
- `V107-ACCEPTANCE-FIX-20260804-01` 定向复验：`V107-BUG-001` 与 `V107-BUG-002` 均通过；Workbench 三次事务无 timeout，版本显示 `1.0.7`，更新检查返回“当前已是最新版本”。
- 修复候选 Zip SHA256：`EF57B0361B379B0D009EBD014B8717B4D7FA50C08330B297C3071A8171E56D47`；EXE SHA256：`37DE58BCD9FE1F0FE41C0F31AA640E68C4A07004A9E9BC6E4C26B0FB6236FB98`。
- 修复后 `scripts/verify_windows_current.ps1` 通过；Rust 67/67、TypeScript、Vite、fmt、clippy、文档与 `git diff --check` 通过。
- `V107-M7-DIRTY-20260804-03`：Zip SHA256 `322EB52DD01AE3B9BEE50EC3346B027C2AEA6E4669505735D01A493A3028A6E5`；EXE SHA256 `91F9EB87FBA35F7A6B3165A4E25CF05E544CDC598CB329FFC150ED416072BA46`；包体验证通过。
- 真实 Windows 125%/150% DPI：旧候选六周摘要重叠失败证据保留；新候选在两档缩放下均一屏完整、无裁切、重叠或文本溢出。
- `V107-ACC-COMPLETION` 最终补证：休息日 1.25 小时保存为 75 分钟，跨夜 owner date 0.5 小时保存为 30 分钟，两项均在重启后持久化；月度汇总从 1 小时 15 分钟更新为 1 小时 45 分钟。
- 关闭 Workbench 后 Mini 按进入前展开状态恢复，窗口生命周期与 timer 暂停/恢复日志成对。
- 托盘真实鼠标组合通过：左键隐藏后 Mini 不可见但进程存活，再次左键恢复进入前隐私竖条，右键原生菜单打开；隐藏后任务栏固定快捷图标无运行中横线。
- DPI 复验结束后 Windows 缩放恢复 100%，原始 `config.json` 与 `config.json.previous` 哈希恢复一致，候选进程为 0。
- 定向复验结束后原始 `config.json`、`config.json.previous` 和 `debug.log` 哈希恢复一致，候选进程为 0。
- 验收结束后原始 `config.json`、`config.json.previous` 和 `debug.log` 哈希恢复一致，候选进程为 0，无新增加班文件残留。
- M0 已冻结 v1.0.6 正式附件身份、v1.0.7 文档哈希、config v8 漂移、current/historical 脚本漂移、窗口与拖动红灯。
- M0 未修改产品、Rust、React、依赖或构建 metadata；真实 Windows 壳、候选包和发布身份仍未进入验收。

## 证据入口

- PRD：`doc/releases/v1.0.7/prd.md`
- 追踪：`doc/releases/v1.0.7/traceability.md`
- 原型说明：`doc/prototypes/v1.0/README.md`
- 开发计划：`doc/releases/v1.0.7/dev_plan_v1.0.7.md`
- 开发日志：`doc/logs/dev_log_v1.0.7.md`
- M0 基线：`doc/releases/v1.0.7/m0-baseline.md`
- 脚本基线：`doc/releases/v1.0.7/script-lifecycle-baseline.md`
- 证据矩阵：`doc/releases/v1.0.7/evidence-matrix.md`
- 环境与证据合同：`doc/releases/v1.0.7/artifact-and-evidence-contract.md`
- M0 机器证据：`doc/releases/v1.0.7/evidence/m0-baseline.json`
- M2 窗口与隐私证据：`doc/releases/v1.0.7/evidence/m2-window-privacy.json`
- M3 日期与加班证据：`doc/releases/v1.0.7/evidence/m3-date-overtime.json`
- M4 月度总结与日历证据：`doc/releases/v1.0.7/evidence/m4-monthly-calendar.json`
- M5 Combobox 与窗口表面证据：`doc/releases/v1.0.7/evidence/m5-combobox-surface.json`
- M6 治理、安全与性能证据：`doc/releases/v1.0.7/evidence/m6-governance-security-performance.json`
- M7 候选与包体证据：`doc/releases/v1.0.7/evidence/m7-candidate-package.json`
- 独立验收脱敏摘要：`doc/releases/v1.0.7/evidence/acceptance-summary.json`
- 阻塞修复脱敏摘要：`doc/releases/v1.0.7/evidence/acceptance-fix-summary.json`
- DPI 修复脱敏摘要：`doc/releases/v1.0.7/evidence/acceptance-dpi-summary.json`
- 最终业务矩阵脱敏摘要：`doc/releases/v1.0.7/evidence/acceptance-completion-summary.json`
- 托盘真实鼠标脱敏摘要：`doc/releases/v1.0.7/evidence/acceptance-tray-summary.json`
- 外部原始证据索引：`doc/releases/v1.0.7/evidence/external-evidence-index.md`
- 开发验证汇总：`doc/releases/v1.0.7/verification.md`

## 下一步

项目所有者已批准提交、推送、tag 和 GitHub Release。下一步创建干净发布提交，重新构建并锁定最终候选身份。

## 记录边界

progress 只记录状态、checklist、阻塞、最近验证和证据入口。实施过程、失败尝试、决策与修复详情写入 dev log。
