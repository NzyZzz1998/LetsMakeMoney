# LetsMakeMoney Windows v1.0.7 开发日志

> 本文记录实施过程、关键决策、失败尝试、修复和验证。它不替代 `progress_v1.0.7.md`；progress 只保留状态看板和证据入口。

## 基本信息

- 版本：Windows v1.0.7 Stable
- 对应 PRD：`doc/releases/v1.0.7/prd.md`
- 对应 dev plan：`doc/releases/v1.0.7/dev_plan_v1.0.7.md`
- 对应 progress：`doc/releases/v1.0.7/progress_v1.0.7.md`
- 对应追踪：`doc/releases/v1.0.7/traceability.md`
- 代码开发基线：`main` / `12b6b03ce91b716d49590e21eb8dd7fe90fa283c`
- 当前阶段：V107-M7 已完成 dirty 验收候选与聚合门禁，进入 V107-ACC；真实 125%/150% DPI 留待独立验收补证

## 开发记录

### 2026-08-03 开发承接

- 本轮目标：将项目所有者确认的 v1.0.7 PRD 转换为可执行、可追踪、可验收的开发计划。
- 新增产物：`dev_plan_v1.0.7.md`、`progress_v1.0.7.md` 和本开发日志。
- 关键决策：
  - 先完成 current/config/version/IPC 合同，再进入窗口与加班实现。
  - Mini 自动隐藏、Combobox、窗口表面、CSP 和性能优化均保留条件门禁，不默认实施。
  - 前端最多治理 `features/calendar`，Rust 最多治理 `window_policy`，不扩大到整体重构。
  - Windows 11 单显示器为强制验收环境；Windows 10 需真实证据或收窄声明；多显示器暂不验证。
- 已验证：FR、IDEA、REV、OBS 全量追踪已写入计划；里程碑依赖、回退点和验收边界已定义。
- 未验证：业务实现、真实 Tauri 壳、Windows GUI、候选包、发布身份和支持矩阵均未执行。
- 边界：未修改业务代码，未构建、打包、提交、推送、打 tag 或创建 Release。
- 下一步：等待项目所有者下达 `V107-M0` 实施指令。

### 2026-08-03 V107-M0 事实、基线与行为刻画

- 冻结开发身份：`main@12b6b03ce91b716d49590e21eb8dd7fe90fa283c`，并核对 `origin/main` 一致。
- 冻结 v1.0.6 正式 Release：tag object、发布提交、Zip、SHA256SUMS、EXE、WebView2Loader.dll 与 BUILD-INFO 身份均写入机器证据。
- 冻结 PRD、追踪、开发计划和 v1.0 原型三份核心文件的大小与 SHA256；定义 source、IPC、窗口、候选和 UI 变化的证据失效条件。
- 建立 current/historical 脚本调用图，确认当前 CI 仍恢复 v1.0.3 并调用 `verify_v104.ps1`，作为 M1 红灯保留。
- 核对 config v8 四层合同：Rust、TypeScript 与 defaults 已对齐到 8；JSON Schema 缺少 `mini_edge_auto_hide` 和 `mini_edge_dock`，作为 M1 红灯保留。
- 建立首次置顶、Mini/Workbench 四种进入前状态、自动隐藏锁、拖动、日期调整、加班精度/费率快照以及 5/6 周 × 双主题 × 三档 DPI 的机器夹具。
- 新增独立 M0 验证入口 `scripts/verify_v107_m0.ps1`。该入口运行当前 Mini 自动隐藏回归，不把描述旧缺陷的历史 characterization 测试误并入通过门禁。
- 首轮失败：验证器假设迁移函数名为 `migrate_v5_to_v8` 等，与实际阶段式命名不符；改为同时验证 `migrate_v5/v6/v7` 函数和 dispatcher 分支。
- 第二轮失败：本机路径扫描把 `https://` 中的 `s:/` 误判为盘符；收紧正则为独立盘符边界后通过，未放宽真实绝对路径检查。
- 最终验证：
  - `scripts/verify_v107_m0.ps1` 通过；2 组 TypeScript 行为测试、7 组机器证据检查和 `git diff --check` 通过。
  - `scripts/verify_architecture.ps1` 通过；15 组行为套件、结构检查、v1.0.4 M6 合同与工具解析检查全部通过。
- 范围核对：未修改 React/Rust 产品代码、依赖、构建 metadata 或发布产物；未触碰无关的 `doc/releases/v1.0.5/post-release-observation.md`。
- 结论：V107-M0 10/10 完成，可以进入 V107-M1。

### 2026-08-03 V107-M1 Current、配置、版本与 IPC 合同

- 新增 `scripts/current-manifest.json` 与 `scripts/script-lifecycle.json`，把 current、reusable、manual 和 historical 脚本显式分层；CI 与贡献文档统一只调用 `scripts/verify_windows_current.ps1`。
- 新增 manifest 验证及错误分类，覆盖版本错误、historical 误用、文件缺失和用户取消四类负向路径；current gate 不再下载或调用旧版本验证入口。
- 建立 canonical config v8 defaults/schema，补齐 `mini_edge_auto_hide` 与 `mini_edge_dock`，Rust 默认值改为嵌入 canonical defaults；保留旧版 defaults 作为历史证据。
- 将开发身份统一推进到 `1.0.7`，新增 `versionService`：桌面读取 Tauri package metadata，浏览器预览明确返回 `dev-preview`，不再在 UI 和更新检查中硬编码旧版本。
- 新增高风险 IPC fixture schema 与 13 个场景，覆盖配置事务、Dashboard、窗口显示补偿及加班 read/save/delete/conflict/corruption 骨架。
- 首轮 current 总门禁因 Rust 未进入当前 PATH 中止；定位并显式使用固定工具链 `D:\Work\Software\lmm-v103-toolchain`，未修改系统环境。
- 第二轮门禁发现旧文档验证器仍要求 `verify_v106.ps1`；更新为唯一 current 入口后，文档门禁恢复通过，没有放宽 UTF-8、链接或事实检查。
- 最终验证：
  - `scripts/verify_v107_m1.ps1` 通过：5 组 M1 合同、6 组既有配置合同、6 项版本 metadata 行为、13 个 IPC 场景全部通过。
  - `scripts/verify_windows_current.ps1` 通过：current manifest、架构与文档门禁、TypeScript、Vite、Rust 56 项测试、fmt、clippy 及 `git diff --check` 全部通过。
  - Vite 产物构建成功；主包约 715.43 kB（gzip 132.62 kB），该数值作为后续性能门禁基线，不在 M1 做无证据优化。
- 范围核对：未提交、推送、打 tag 或创建 Release；未触碰无关的 `doc/releases/v1.0.5/post-release-observation.md`。
- 结论：V107-M1 12/12 完成，可以进入 V107-M2 与 V107-M3。

### 2026-08-03 V107-M2 窗口、隐私与自由拖动

- 将 Mini 首次显示改为“先读取配置并应用权威窗口策略，再显示且不抢焦点”；置顶请求、应用与失败使用独立语义日志，失败保持非阻塞并在托盘找回时重试。
- 新增 visibility lease 状态机与 transaction id，区分 `expanded`、`privacy_retracted`、`hidden_by_user`、`not_present` 四种 Mini 前态，并覆盖 opening、open、compensating、closed、failed 的幂等转移和晚到事件拒绝。
- Workbench 的打开、重复打开、WebView ready、关闭、系统 X、初始化超时和窗口销毁统一进入事务补偿；真实 GUI 验证展开态打开后 Mini 隐藏、关闭后原样恢复。
- 桌面 show/hide 失败改为 typed error 与用户可见非阻塞提示；浏览器 query fallback 只在非 Tauri 预览中启用，不再静默吞掉桌面错误。
- 将拖动拆成 move、finalize 和 recover：移动过程不钳制；释放和找回时才依据安全抓取区回落。Mini 使用 28×48、其他窗口使用 48×48 逻辑像素基线，并用 100%、125%、150% 单元矩阵验证缩放。
- 自动隐藏条件结论为“实施最小修复”：拖动完成后清理 stale pointer/focus 状态；迟到 timer 只有仍持有当前 timer 时才能清空句柄，避免 generation 已更新时破坏新一轮收起。
- 新增 10,000 条确定性随机状态序列，基础种子为 `275775490`；未发现重复 timer、锁泄漏、悬空 dock、迟到回调破坏或状态循环。
- 真实 Windows 11 单显示器 100% DPI 验证：左右边缘各 15 次贴边全部收为 21–23px 隐私竖条，拖动结束后无需第二次点击；测试中的一次右侧未收起由自动化步长拖过边缘阈值导致，校准真实终点后连续 15/15 通过，产品日志未记录失败。
- 中间 GUI 候选明确标记为 dirty、不可发布；EXE SHA256 为 `2B8A33286F127F0872C0D43A24F57E806B1084092D444411C4DE73394268B04A`，WebView2Loader.dll SHA256 为 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 最终自动验证：`scripts/verify_v107_m2.ps1`、`scripts/verify_windows_current.ps1`、Rust 60/60、`cargo fmt --check`、`cargo clippy -- -D warnings` 和 `git diff --check` 全部通过。
- 用户环境恢复：候选进程为 0；`config.json`、`config.json.previous` 与 `debug.log` 均按备份 SHA256 原样恢复。原始截图与完整日志仅保存在外部证据目录，仓库只写入脱敏摘要。
- 验证边界：真实 125%/150% DPI 和四种 Mini 前态的完整 GUI 组合留给独立候选验收；本里程碑由逻辑像素矩阵、状态机单元测试和 100% DPI 真实壳证据闭合实现任务。
- 结论：V107-M2 14/14 完成，可以进入 V107-M3；M5 的窗口表面 Spike 前置依赖同时解除。

### 2026-08-03 V107-M3 日期事务、加班领域与局部边界

- 将今日页与日历页统一接入 `DateOverrideEditor`，日期调整共用 reducer、service、状态和失败补偿；无变化、取消、关闭与失败均不污染旧配置。
- 建立 `overtime-records.json` schema v1 及 Rust model/repository/service/command 分层，保持 config v8 不变且不引入数据库。
- 加班时长执行 0–24 小时、最多两位小数和最近一分钟合同；0 走删除语义。新建捕获当前时薪快照，修改保留旧快照，删除后重建才捕获新快照。
- 仓储写入使用串行锁、临时文件、回读校验、previous 备份和原子替换；损坏文件保留为证据并拒绝伪造 0，只有显式恢复才能建立空仓储。
- 加班入口覆盖今日 owner date、任意历史日期、全部日期类型和跨月查询；日志只记录日期、分钟、动作、schema 与错误代码，不记录薪资和费率值。
- IPC fixture 从 M1 的 5 个骨架推进为 7 个 active 场景，连同配置、Dashboard 与窗口共 15 个场景；M1 门禁升级为允许骨架整体原子推进到 active，仍禁止混合阶段状态。
- current manifest 与 lifecycle 正式登记 `verify_v107_m3.ps1`。首轮 current gate 因漏登记失败，第二轮因 M1 仍断言 skeleton 失败；两处均按阶段单调性修正，未删除或放宽合同。
- 最终验证：`verify_v107_m3.ps1` 通过；日期事务 6/6、加班状态 13/13、service 5/5、IPC 15 个场景、Rust 66/66、Vite 生产构建、`cargo fmt --check`、`cargo clippy -- -D warnings` 和 current gate 全部通过。
- 中间产物明确为 dirty、不可发布；本里程碑未宣称月度总结、日历加班标记、六周布局或真实 GUI 已完成。
- 结论：V107-M3 14/14 完成，可以进入 V107-M4。

### 2026-08-03 V107-M4 月度总结与六周日历

- 新增月度工时纯函数，分别计算计划工时、已流逝计划工时和主动记录的加班工时；过去、当前、未来月份以及跨夜 owner date 均由确定性行为测试覆盖。
- 加班月数据使用独立状态与读取链，区分 loading、ready、empty、stale、error 和 corrupt；失败时保留同月缓存并明确提示，禁止把失败伪造为 0 分钟。
- 日历日期格增加非收入性质的加班标记；月度总结固定三列，并明确“不代表实际出勤”，没有展示或累计加班收入。
- Workbench 收敛为 820×620 逻辑尺寸；5 周与 6 周月份使用自适应行高，日历页不出现纵向滚动条。
- 新增 `monthly-summary.behavior.ts` 与 `overtime-month-state.behavior.ts`；`scripts/verify_v107_m4.ps1` 最终通过，分别为 10/10 与 7/7。
- Vite production build 与真实 Tauri debug build 均成功。直接 `pnpm run build:web` 因本机 pnpm 拒绝未批准的 esbuild build script 而停止，未修改依赖许可；改用锁定的本地 `tsc` 与 `vite` 可执行文件完成等价构建验证。
- 真实 Windows 11 单显示器 100% DPI 验证：2026-08 六周月和 2026-09 五周月均在 820×620 内完整显示，月度总结与图例可见；加班编辑器入口、范围/精度文案和取消语义通过；浅色、深色及保存后的跨窗口主题同步通过。
- 环境保护：操作前备份 config/debug.log，结束后停止候选进程并原样恢复；未保存任何加班数据。
- 证据边界：真实 125% 与 150% 系统 DPI 尚未取得，不以浏览器缩放或静态矩阵冒充通过，因此 M4 记录为 9/10；该门禁与 M5 的三档 DPI 一并留给最终验收。
- 结论：M4 产品逻辑、布局和 100% DPI 真实壳可进入 M5；不存在产品或技术阻塞。

### 2026-08-03 V107-M5 Combobox 与窗口表面条件 Spike

- 先冻结原生 `select` 与四窗口表面基线，再实现不依赖第三方 UI 库的 `AccessibleCombobox`；组件统一提供 `combobox/listbox/option` 语义、键盘选择、Escape、外点击关闭、禁用和错误状态。
- Settings 的休息模式与大小周“本周类型”改用同一组件，避免只修一个入口；条件字段在选择大小周后稳定出现，未引入产品专用一次性分支。
- 窗口表面采用“原生窗口负责外层阴影、Web 根层负责圆角与裁切、内容层不重复投影”的单一 owner 合同；Mini、Workbench、Settings 和 Wizard 共用稳定属性。
- 自动门禁：`verify_v107_m5.ps1` 通过，静态合同 3/3、Combobox 行为 14/14、窗口表面行为 5/5；TypeScript strict、Tauri debug build 和 `git diff --check` 通过。
- 真实 Windows 11 单显示器 100% DPI：指针选择、Arrow/End/Enter、Escape、外点击、焦点环、ARIA、浅色/深色弹层、条件 Combobox 和跨窗口主题即时预览通过。
- 未保存测试草稿通过“放弃更改”恢复原配置；关闭 Workbench 后 Mini 在自动隐藏延迟结束后恢复为隐私竖条。候选进程结束，配置文件最后修改时间未变化。
- dirty 中间 EXE：15,293,440 字节，SHA256 `148E3BA5B47678EEBB6F4979B0EC11839C406CC88AD678F2430E7A33610BCA99`；只用于开发验证，不得进入 Release。
- 条件结论：FR-010 正式实施；FR-011 在 100% DPI 暂定接受，必须等待真实 125%/150% DPI 后才能给出最终接受或回退结论。
- 证据入口：`doc/releases/v1.0.7/evidence/m5-combobox-surface.json` 与 `doc/releases/v1.0.7/verification.md`。
- 结论：M5 完成 10/12，无产品阻塞，可以进入 M6；两项真实 DPI 证据继续保留为最终候选门禁。

### 2026-08-03 V107-M6 治理、证据、安全与性能条件门禁

- 完成脚本 lifecycle 索引：current、reusable、manual、historical 覆盖全部 `scripts/*.ps1`；新增 M6 current gate，并保留 historical 版本脚本不可变。
- 复用 M1 负向测试确认版本错误、historical 误用和缺失 gate 会失败；current CI 仍只有 `verify_windows_current.ps1` 一个入口。
- 将 `doc/current.md` 从历史汇总收敛为当前公开版本、v1.0.7 里程碑、支持边界和 release 链接；旧版本事实仍由各 release 文档保留。
- 建立 Windows 11 单显示器支持矩阵。Windows 10 因无真实设备或 VM 证据收窄为未验证；多显示器按项目所有者决策暂不验证。
- CSP 隔离候选未包含 `unsafe-eval`，但 Mini 首屏未形成主题和 Tauri bridge，IPC/更新链路无法验证，失败代码为 `mini_bootstrap_unavailable`。按条件门禁撤销候选，正式 `tauri.conf.json` 继续保持 `csp: null`。
- 完成正式非 CSP 10 次冷启动与 10 次暖启动采样：冷 Mini P95 6,154ms、冷 Workbench P95 6,527ms，暖 Mini P95 1,067ms、暖 Workbench P95 1,442ms，JS gzip 140,841 bytes，最大长任务 0ms。
- 冷启动超过阈值后执行“跳过托盘初始化”单点诊断，收益未达到 15% 保留门槛；诊断代码已移除，不保留无证据优化。冷启动作为量化性能债记录，未写成达标。
- 性能和 CSP 原始证据保存在外部证据库，仓库只写入逻辑 ID、摘要哈希和脱敏机器摘要；未提交本机路径、完整日志、配置或截图。
- 两轮性能采集结束后 `config.json` 和 `debug.log` SHA256 原样恢复，候选进程为 0；CSP 隔离覆盖未写回正式配置。
- 新增 `verify_v107_m6.py` 与 `verify_v107_m6.ps1`，6 组治理、安全、性能和局部边界检查通过。
- 范围核对：未引入全局状态库、未重命名历史 IPC、未实施共享状态重写、未修改收入或日历口径。
- 结论：M6 14/14 完成，可以进入 M7；真实 125%/150% DPI 继续作为最终候选门禁。

### 2026-08-03 V107-M7 聚合门禁与 dirty 验收候选

- 新增 v1.0.7 隔离打包、候选包验证、M7 聚合门禁与对应负向测试；candidate 与 published 身份分别检查 dirty 状态、发布许可、文件白名单和哈希。
- 将 M7 注册到 current manifest 与脚本 lifecycle，README、贡献文档和应用 README 使用 v1.0.7 current 命令，同时保持 v1.0.6 是当前公开版本的事实。
- 修正包内绝对路径扫描对 `https://` 的误报；新增真实 Windows 绝对路径负向夹具，没有放宽隐私规则。
- 生成锁定的 dirty 验收候选 `V107-M7-DIRTY-20260803-01`：Zip 3,331,364 字节，SHA256 `173207AE508DB8D8504818F16B21165164E6C50C29ABF74C4C4D5C08B40CC05D`；EXE 10,297,344 字节，SHA256 `760C0E80952181BA80352187DCCE9C6823F3BE19B0EC1BC04553ACCC34156035`。
- 包内 13 个文件均在 allowlist，EXE、WebView2Loader、双语 README、BUILD-INFO、许可与 2025–2026 日历数据哈希一致；未发现配置、日志、缓存、截图、临时目录、私有证据或未知二进制。
- 自动验证：`verify_v107_m7.ps1`、带 candidate 的 `verify_v107.ps1 -Milestone M7`、`verify_current_manifest.py` 与 `verify_windows_current.ps1` 均通过；TypeScript、Vite、Rust 66/66、fmt、clippy、文档与 `git diff --check` 通过。
- 发布边界：候选 `source_tree_dirty=true`、`publication_allowed=false`，只可用于独立验收。M7-009 干净提交唯一候选与 M7-010 最终产物哈希必须等待项目所有者批准后重新构建，不能复用本次 dirty 哈希。
- 机器证据：`doc/releases/v1.0.7/evidence/m7-candidate-package.json`。
- 结论：M7 完成 10/12，可以使用锁定候选进入独立验收；不得提交、推送、打 tag 或创建 Release。

### 2026-08-04 V107-ACC 阻塞修复与真实 DPI 收口

- 首次独立 GUI 验收保留未通过结论，并登记 `V107-BUG-001` 版本 capability 缺失与 `V107-BUG-002` Workbench 复用事务超时；两项均按最小范围修复并以新 dirty 候选完成自动和真实 GUI 定向复验。
- 真实 Windows 125%/150% DPI 首轮覆盖 Mini、Workbench、Settings、Wizard、Combobox 与六周日历，发现 `V107-BUG-003`：月度总结在高 DPI 固定高度下被纵向压缩并发生文字重叠。
- 根因收敛到生产 CSS 未落实原型的稳定双列摘要结构；修复仅调整 `.month-summary` 及子项约束，增加双列、最小高度、行高、nowrap 与 ellipsis 合同，没有扩大 Workbench 或重写日历。
- `verify_v107_m4.py` 增加布局回归断言；`verify_v107.ps1 -Milestone M5`、current manifest、TypeScript、Vite、Rust 67/67、fmt、clippy、文档和 `git diff --check` 全部通过。
- 生成 `V107-M7-DIRTY-20260804-03`：Zip 3,317,755 字节，SHA256 `322EB52DD01AE3B9BEE50EC3346B027C2AEA6E4669505735D01A493A3028A6E5`；EXE 10,271,744 字节，SHA256 `91F9EB87FBA35F7A6B3165A4E25CF05E544CDC598CB329FFC150ED416072BA46`；WebView2Loader SHA256 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 只运行新解压目录中的 EXE。真实 Windows 125% 与 150% 下，2026 年 8 月六周日期、月度总结四项内容和图例均一屏可见，无裁切、重叠或文本溢出；首次失败截图未删除。
- Windows 缩放恢复到 100%，候选进程为 0；`config.json` 与 `config.json.previous` 均按 SHA256 恢复原始内容。
- 三项产品发布阻塞已关闭。最新候选仍为 dirty、`publication_allowed=false`，只可作为验收证据；发布必须等待项目所有者批准，从干净提交重建并锁定最终身份。

### 2026-08-04 V107-ACC 最终业务矩阵补证

- 继续使用锁定 dirty 候选 `V107-M7-DIRTY-20260804-03`，未更换 EXE、DLL 或 Zip 身份。
- 在真实 Windows 11 单显示器 100% DPI 下补齐休息日加班：2026-08-02 输入 1.25 小时，持久化为 75 分钟，重启后月度汇总仍为 1 小时 15 分钟。
- 将测试班次切换为 23:00–07:30、休息 02:00–02:30，02:29 实际运行时主标题显示“本次夜班收入进度”，owner date 为 2026-08-03；今日入口默认使用该业务日期，0.5 小时持久化为 30 分钟。
- 再次重启后 2026-08-02 与 2026-08-03 均显示加班标记，月度汇总为 1 小时 45 分钟；关闭 Workbench 后 Mini 恢复进入前展开状态，窗口生命周期与 timer 暂停/恢复事件成对。
- 共保留 7 张外部原始截图，仓库新增脱敏摘要 `evidence/acceptance-completion-summary.json`，不保存薪资、费率、完整配置或本机路径。
- 通知区真实鼠标左键隐藏、再次左键恢复、右键菜单及任务栏组合仍待项目所有者补证，未写为通过。
- 最终补证结束后停止全部候选进程；主机和 Computer Use 隔离环境的配置、previous 与日志均按原始 SHA256 恢复，测试加班记录恢复为空。
- 发布边界不变：该候选源树为 dirty、`publication_allowed=false`，仍需项目所有者批准、干净发布提交和最终候选哈希锁定。

### 2026-08-04 V107-ACC 最终自动门禁

- 新 PowerShell 进程未继承 Node 与 Cargo 路径，首次 current gate 在工具解析阶段按预期失败；未将环境缺失误写为产品失败。
- 使用 Codex 随附 Node/Python 与项目既有 `lmm-v103-toolchain`，通过 `LMM_NODE`、`LMM_PYTHON`、`LMM_CARGO`、`LMM_CARGO_HOME` 和 `LMM_RUSTUP_HOME` 显式锁定工具身份，没有修改系统环境。
- `scripts/verify_windows_current.ps1` 最终通过：current manifest、M1-M7、架构行为测试、文档门禁、TypeScript strict、Vite production build、Rust 67/67、`cargo fmt --check`、`cargo clippy -- -D warnings` 与 `git diff --check` 全部通过。
- 脱敏结果已写入 `doc/releases/v1.0.7/evidence/acceptance-completion-summary.json`；未写入本机工具绝对路径。
- 验收结论当时仍为部分通过：通知区真实鼠标组合待项目所有者补证，且 dirty 候选不得作为最终 Release 身份。

### 2026-08-04 V107-ACC 托盘真实鼠标补证

- 继续使用锁定 dirty 候选 `V107-M7-DIRTY-20260804-03`，在 Windows 11 单显示器 100% DPI 下由项目所有者使用真实鼠标操作通知区。
- 首次左键托盘后 Mini 从可定位窗口列表消失，候选进程继续运行；日志记录 `tray.left_click`、窗口隐藏、WebView suspend 与 Dashboard timer pause。
- 再次左键托盘后 Mini 恢复为进入前的隐私竖条；日志记录窗口显示/聚焦、`skip_taskbar=true`、WebView resume、Dashboard timer resume 与主题恢复。
- 项目所有者确认右键原生托盘菜单打开；菜单项与锁定候选同源 Rust 注册结构交叉核对。
- 对任务栏组合重新补证：隐藏后固定快捷图标没有运行中横线，确认不存在活动任务栏窗口入口。
- 外部完整日志 SHA256 为 `82E2310FF29EE882E69DD7C71A20383733790A3C8AB891F5447E2BE141CCFE12`；仓库只保存 `evidence/acceptance-tray-summary.json` 脱敏摘要。
- 补证结束后候选进程归零，`config.json`、`config.json.previous` 与 `debug.log` 均按验收前 SHA256 恢复。
- 锁定 dirty 候选验收通过；发布边界不变，仍需项目所有者批准、干净发布提交、最终候选重建和哈希锁定。

### 2026-08-04 v1.0.7 发布授权

- 项目所有者明确批准 v1.0.7 有意变更，并授权提交、推送、annotated tag 与 GitHub Release。
- dirty 验收候选继续仅作为验收证据，禁止改名或上传；正式发布必须从干净发布提交重新构建并重新锁定 Zip、EXE、DLL、BUILD-INFO 与 SHA256SUMS。
- 发布附件边界保持不变：只允许便携 Zip 与 `SHA256SUMS.txt`。
