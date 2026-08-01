# LetsMakeMoney Windows v1.0.5 开发日志

> 本文记录开发过程、关键决策、异常处理和验证结果。它不替代 `progress_v1.0.5.md`；progress 只保留状态看板和最小任务 checklist。

## 基本信息

- 版本：Windows v1.0.5 Stable
- 对应 PRD：`doc/releases/v1.0.5/prd.md`
- 对应 dev plan：`doc/releases/v1.0.5/dev_plan_v1.0.5.md`
- 对应 progress：`doc/releases/v1.0.5/progress_v1.0.5.md`
- 对应追踪：`doc/releases/v1.0.5/traceability.md`
- 代码开发基线：`main` / `8a63da7836fb24c3b7f8ff12f896ac40571adeb7`
- 当前阶段：V105-M6 部分完成，9/10；等待干净提交候选

## 开发记录

### 2026-07-31 开发承接

- 本轮目标：将已确认的 v1.0.5 PRD 转换为可执行、可跟踪、可验收的开发计划。
- 改动模块：PRD 状态、需求追踪、dev plan、progress、dev log、current 和原型说明。
- 关键决策：
  - 日历“今天”采用方案 A：左上“今”角标与数字加粗。
  - FR-008 真实 Tauri 壳 Spike 先行；失败时保留 v1.0.4 表面。
  - FR-004 仅在 20 次真实复现锁定界面与事件链后进入实施。
  - 本地 dirty v1.0.4 candidate 仅登记，删除保持独立授权。
- 遇到的问题：无业务实施问题；原型矩阵首次自动测试使用了过期选择器。
- 处理方式：按当前 HTML 的 select 与窗口导航真实交互路径校正验证脚本，未修改产品代码。
- 已验证：
  - 11 个业务状态隐私文案零收入泄露。
  - 5 个日历可信度状态显示合同通过。
  - 双主题、三档 DPI、四类窗口 24 个布局组合无横向溢出。
  - JavaScript、UTF-8、乱码、本地链接、文档状态和 `git diff --check` 通过。
- 未验证 / 待补证：业务实现、真实 Tauri 壳、候选包、系统通知区、多显示器。
- 关联 bugfix / spike：FR-004 条件复现；FR-008 单一表面 Spike。

### 2026-07-31 V105-M0 事实、决策与门禁冻结

- 本轮目标：执行 `V105-M0-001` 至 `V105-M0-008`，冻结发布对象、Mini 现状、条件缺陷复现合同和后续证据失效规则。
- 新增产物：
  - `doc/releases/v1.0.5/m0-baseline.md`
  - `doc/releases/v1.0.5/fr004-reproduction-contract.md`
  - `doc/releases/v1.0.5/evidence-matrix.md`
  - `doc/releases/v1.0.5/verification.md`
  - `doc/releases/v1.0.5/evidence/README.md`
  - `doc/releases/v1.0.5/evidence/m0-baseline.json`
  - `apps/windows-v1/tests/verify_v105_m0.py`
  - `apps/windows-v1/tests/verify_v105_m0_tests.py`
  - `scripts/verify_v105.ps1`
- 正式身份：开发基线 `main` / `8a63da...deb7`；v1.0.4 tag 目标 `4d06dc...d5b6`；GitHub 正式 Zip `C4F288...DE50E`，`source_tree_dirty=false`。
- 本地对象：dirty candidate Zip `C67E730...C249B`，`source_head=09f838...1f52`，`source_tree_dirty=true`；仅登记并保留，未删除或改名。
- 决策冻结：日历今天标记只实施方案 A；FR-008 真实壳不通过时完整保留 v1.0.4 表面；FR-004 必须先完成 20 次真实复现。
- Mini 基线：600ms 单一收起 timer、180ms 过渡、10px 现状标签、config v8 可选字段，以及 `focus` 与 `window-shown` 当前共用 reveal 语义均已记录。
- 门禁实现：聚合脚本验证机器证据、Git/tag、dirty 包内身份、文档合同、业务代码零差异和负向篡改拒绝；读取 BUILD-INFO 时兼容 UTF-8 BOM。
- 验证结果：M0 正向 `6/6`、负向 `8/8`、75 份文档 UTF-8/乱码与链接检查、`git diff --check` 全部通过。
- 未执行：FR-004 真实复现仍为 `0/20`；真实 DPI、多显示器、三窗 Tauri 壳、构建、打包和候选验收均未执行。
- 边界：未修改业务代码，未删除 dirty candidate，未执行 commit、push、tag 或 Release。

### 2026-08-01 V105-M1 README、发布身份与目录合同

- 本轮目标：执行 `V105-M1-001` 至 `V105-M1-008`，关闭公开 README 漂移、candidate/published 混淆与证据唯一副本风险。
- README：根中英文与应用 README 统一为当前公开 v1.0.4 Stable，默认构建、包验与聚合入口统一使用现有 v104 脚本。
- 身份验证：新增 candidate/published 双模式 Python 验证器和 PowerShell 入口；锁定版本、平台、架构、source HEAD、dirty、构建时间、EXE/DLL/README/许可/日历哈希。
- 负向夹具：合成包覆盖 clean candidate、dirty candidate、published cache 三条正向，以及 source、版本、字段、载荷、目录、dirty、tag、Release URL、回下载 SHA 和 checksums 共十二条拒绝路径。
- 目录与证据：建立 `.artifacts/candidates`、`acceptance`、`published`、仓库脱敏摘要和 `releases` staging 的独立所有权；新增 BUILD-INFO、acceptance summary、raw evidence index 和 published cache index 四份严格 schema。
- 唯一副本保护：原始证据只在仓库外保留并由索引声明可用状态；唯一副本禁止删除，替代证据不得覆盖历史结论。
- dirty candidate：未来删除所需六项条件已经写入合同；本轮没有下载 published cache，也没有获得独立清理授权，因此原文件继续保留。
- 验证结果：M0 `6/6 + 8/8`、M1 `8/8 + 8/8`、包身份 `3` 条正向与 `12` 条负向、89 份文档、`git diff --check` 全部通过。
- 边界：业务代码差异为 0；未构建、未打包、未创建真实 v1.0.5 candidate，未执行 commit、push、tag 或 Release。

### 2026-08-01 V105-M2 Mini 行为刻画与条件异常复现

- 本轮目标：执行 `V105-M2-001` 至 `V105-M2-010`，只建立行为夹具、失败刻画、真实复现、根因和最小修复边界。
- 自动刻画：新增 8 状态 fixture，覆盖左右停靠、无 `pointerleave` 释放、拖回浮动、menu/modal/focus 锁、普通 focus 和 explicit native shown。
- FR-003：左右边缘当前行为测试均通过，证实拖动结束后 `pointerInside=true` 阻止 timer；目标行为测试以 `M2_RED_NO_POINTERLEAVE_RETRACT` 按预期保持红灯。
- FR-004：使用 GitHub v1.0.4 正式 Zip 的新解压实例完成 20 个有效轮次；另有 1 个关闭坐标校准轮，未计入结果。
- 真实结果：20/20 轮关闭 Workbench 前 Mini 均为收起态，关闭后均展开；实际界面为 Mini，不是托盘菜单。
- 事件链：采集切片包含 21 条 Workbench hidden、0 条原生 Mini shown、43 条 `window_focus`、20 条 `source=window_shown` Mini reveal、1 条 pointer-enter reveal 和 21 条 pointer-leave retract。
- 根因：浏览器 `focus` 与原生 `lmm:window-shown` 共用 reveal handler，普通焦点回归被错误标记为显式 shown 并展开 Mini。
- 路由：FR-004 满足“至少 1/20 且普通 focus 单独触发”的合同，进入 M3；只允许分离普通 focus 与 explicit shown。
- 环境恢复：原配置 SHA 前后一致，原日志已恢复，未修改注册表，进程数归零。
- 证据：仓库只保存 `evidence/m2-characterization-summary.json`；完整日志、原图和逐轮记录位于被 Git 忽略的本地证据目录。
- 验证：M2 正向/负向合同、当前行为、预期红灯、继承文档门禁和 `git diff --check` 通过；业务代码差异为 0。
- 边界：未修复 FR-003/004，未构建、未打包、未创建 v1.0.5 candidate，未执行 M3 或远端写操作。

### 2026-08-01 V105-M3 Mini 首次收起与隐私竖条

- 本轮目标：执行 `V105-M3-001` 至 `V105-M3-010`，按 M2 锁定的根因修复首次贴边和普通 focus 展开，并实现无金额隐私竖条。
- 状态机：拖动完成时清除过期 pointer intent 并重新计算收起资格；用 generation/token 保护单 timer 和晚到原生结果；menu、modal、drag 与 focus 锁保持独立。
- 窗口事件：普通浏览器 focus 只设置交互锁，不再触发 reveal；显式 `lmm:window-shown`、隐私条点击和托盘恢复仍使用独立 reveal source。
- 原生几何：隐私条逻辑宽度从装饰线调整为 28px，正常位置和收起位置分别计算；左右边缘、100%/125%/150% DPI 与失败回退由 Rust 测试覆盖。
- 呈现：新增 10 状态非金额选择器；普通、带薪和不带薪休息统一显示“今日休息”，工作阶段仅显示到下一边界的分钟级信息；DOM、ARIA 和日志禁止收入及工资制度词。
- 样式：新增左右边缘竖排、浅色/深色、焦点与 reduced-motion 合同；展开后焦点回到 Mini 主操作区。
- 自动验证：Mini `37/37`、隐私选择器 `10/10`、Rust `54/54`；TypeScript strict、Vite build、cargo test/fmt/clippy、架构与隐私扫描通过。
- 受控候选：`V105-M3-20260801-015617`，EXE SHA256 `67F14FB8...B5E61`，Native DLL SHA256 `8427B1FC...E0F1C`；来源工作树为 dirty，只允许 M3 定向验证。
- 真实 Windows：左右首次贴边无需额外交互即可收起；点击/指针进入可展开，移开可收回；普通 focus 与关闭 Workbench 均不再展开 Mini。
- 证据边界：键盘、通知区显式找回、深色主题和故障回退当前只有自动合同，保留到独立 ACC 做真实补证；多显示器仍未覆盖。
- 环境恢复：原配置和日志已恢复，注册表未变化，进程归零；原始截图和日志只在 Git 忽略目录保存，仓库落盘脱敏摘要。
- 停止边界：M3 通过不等于 v1.0.5 可发布；未进入 M4、M5、M6，未提交、推送、打 tag 或创建 Release。

### 2026-08-01 V105-M4 日历内容与复合导航方案 A

- 本轮目标：执行 `V105-M4-001` 至 `V105-M4-008`，降低 official 正常态噪音，并让今天、选中日期、业务状态与交互状态能够组合表达。
- 呈现选择器：新增日历可信度呈现合同；official 返回不可见，estimated、stale 与完整性错误保留明确标题、详情和风险语气。
- 日期合同：业务状态、今天、选中、stale 和 disabled 使用独立 class；“今天”采用项目所有者确认的左上“今”角标和日期数字加粗，选中使用独立边框。
- 可访问性：ARIA 同时表达业务状态、今天、当前选中、数据过期和不可用；键盘 focus、stale 虚线和今天角标均提供非颜色线索。
- 行为测试：新增 49 条日历矩阵断言，覆盖六种业务状态、复合导航层、浅/深主题、长内容和 100%/125%/150% DPI 合同。
- 受控候选：`V105-M4-20260801-024851`，EXE SHA256 `1A2C5AA9...1FE55F`，Native DLL SHA256 `8427B1FC...E0F1C`；来源工作树为 dirty，只允许 M4 定向验证。
- 真实 Windows：官方 2026 年日历没有常驻来源块；2027 estimated 在浅色与深色均显示且明确不代表法定放假；8 月 1 日同时表达休息日、今天和当前选中。
- 证据边界：loading、integrity error、重试、长内容和 125%/150% DPI 当前为自动合同，保留到独立 ACC 做真实桌面补证。
- 环境恢复：原配置、前一配置和日志均按 SHA256 恢复，注册表未变化，进程归零；仓库只保存脱敏摘要。
- 停止边界：M4 通过不等于 v1.0.5 可发布；未进入 M5、M6，未提交、推送、打 tag 或创建 Release。

### 2026-08-01 V105-M5 三窗单一表面真实壳 Spike

- 本轮目标：执行 `V105-M5-001` 至 `V105-M5-008`，用真实 Tauri 壳判定 Workbench、Settings、Wizard 是否可安全采用单一表面职责。
- v1.0.4 基线：三个窗口分别为 `922×642`、`762×562`、`782×582`；Web `.window-frame` 与原生窗口同时拥有阴影，形成双重职责。
- 最小实现：`WindowFrame` 写入表面/阴影所有权标记，`.window-frame` 移除 CSS 阴影；背景、边框和圆角继续由 Web 表面负责，透明壳和阴影由 Tauri 原生窗口负责。
- Mini 保护：`.mini-window` 继续使用原有 CSS 阴影，不接入 `WindowFrame`；隐私竖条和展开回归通过。
- 自动验证：窗口表面 `16/16`、Rust `54/54`、TypeScript strict、Vite build、fmt、clippy、release build 与架构门禁通过。
- 受控候选：`V105-M5-20260801-032724`，EXE SHA256 `DF18CC5A...546A3B`，Native DLL SHA256 `8427B1FC...E0F1C`；来源工作树为 dirty，只允许 M5 验证。
- 真实 Windows：Workbench、Settings、Wizard 的拖动、关闭、焦点/模态、保存与窗口找回通过；浅/深主题及 100%/125%/150% 真实系统缩放未见裁切、重叠或异常尺寸。
- 平台边界：Windows 11 Pro build 26200 通过；当前没有 Windows 10 设备或 VM，记录为待环境补证，不推断通过。
- 决策：保留单一表面候选进入 M6；如表面代码、原生阴影、窗口尺寸、Mini 表面或候选哈希变化，M5 证据失效并必须重验或回退。
- 环境恢复：系统缩放恢复为 100%，配置、前一配置和日志按备份 SHA256 恢复，进程归零。
- 停止边界：M5 通过不等于 v1.0.5 可发布；未执行 M6 或 ACC，未提交、推送、打 tag 或创建 Release。

### 2026-08-01 V105-M6 聚合门禁与受控候选准备

- 版本身份：npm、Cargo、Tauri、更新评估器和关于页统一为 `1.0.5`；公开版本事实仍保持 v1.0.4 Stable。
- 打包入口：新增 `package_v105.ps1`，只写入 `.artifacts/candidates/v1.0.5/<candidate-id>/`，先在临时 staging 中生成和验证，再事务式移动到最终候选目录。
- 身份合同：candidate/published 模式分离；candidate 必须记录 HEAD、dirty 状态和载荷哈希，published 额外要求干净源码、锁定 tag、Release URL、回下载 SHA 与校验文件。
- 受控候选：`V105-20260731T204214Z-8a63da78-dirty`；Zip SHA256 `ED69EEB4...5BD5`，EXE SHA256 `1CD25830...11F2`，WebView2Loader SHA256 `8427B1FC...E0F1C`。
- 构建结果：M5 聚合、TypeScript strict、Vite production build、Rust release build、便携 README 渲染及两次 candidate 包验证通过。
- 证据边界：候选来自 dirty 工作树，`publication_allowed=false`，只证明构建与身份合同；不能代替 `V105-M6-009` 的干净提交候选或独立 ACC。
- 下一步：对锁定候选运行 M6 全聚合门禁，再更新完成度；未获授权前不提交、不推送、不打 tag、不创建 Release。

### 2026-08-01 V105-M6 完整聚合复跑

- 首次失败：M5 验证器将总进度 `52/74` 写死，项目进入 M6 后产生假阳性；改为验证 M5 表格 `8/8`、八项 checklist 和 current 的下游路由，并增加三项负向测试。
- 第二次失败：M6 验证器仍匹配旧版 `currentVersion` 与关于页 JSX 结构；应用真实两条更新检查路径和关于页均已是 `1.0.5`。门禁改为枚举全部更新评估版本并精确校验版本行，增加三项负向测试。
- 最终结果：M0 至 M5 继承门禁、前端行为与结构、包身份正负向合同、TypeScript strict、Vite production build、Rust `54/54`、fmt、clippy、release build、94 份文档和 `git diff --check` 全部通过。
- 完成度：M6 `9/10`；`V105-M6-009` 需要来自干净提交的唯一候选，受当前“不提交”边界阻塞。
- 停止边界：不启动独立 ACC，不提交、不推送、不打 tag、不创建 Release，不将 dirty 候选写成正式候选。

### 2026-08-01 V105-M6 干净候选锁定

- 授权：项目所有者明确选择方案 A，授权创建 v1.0.5 候选提交并继续正式验收；未授权 push、tag 或 Release。
- 源码提交：`277b121bbc68958382d06f4b29de3bd7685650f4`，候选构建时 `source_tree_dirty=false`。
- 候选 ID：`V105-20260801T002456Z-277b121b-clean`。
- Zip：3,231,540 字节，SHA256 `BE2E1004427859AD30A4A4B23B12C00CF8A5EBD69F7A2442F345813F28CA521C`。
- EXE：10,110,976 字节，SHA256 `0B650A0DF85A315104BDDA0B5E0E0B1E0D97DA21A5B96D72C26217FC3206A25A`。
- WebView2Loader：160,320 字节，SHA256 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 门禁：candidate 身份、M0 至 M5 继承合同、前端行为与结构、TypeScript/Vite、Rust `54/54`、fmt、clippy、release build、文档和负向合同全部通过；最终进程退出码为 `0`。
- 完成度：M6 `10/10`，总体 `62/74`；候选只进入独立 ACC，验收和发布授权完成前不可发布。
- 历史边界：旧 dirty M6 候选继续作为开发证据保留，不替代、覆盖或污染 clean 候选身份。

## 关键决策

| 决策 | 背景 | 取舍 | 影响范围 | 后续观察 |
| --- | --- | --- | --- | --- |
| 日历使用方案 A | A/B 高保真原型已完成 | 选择角标，B 只留历史对照 | 日历 CSS、呈现和 ARIA | 浅/深与复合状态可辨性 |
| FR-008 允许失败回退 | 透明 Tauri 壳不能由浏览器原型证明 | 真实壳通过才实装 | 三个窗口、CSS、Tauri | 四角、拖动、DPI、Win10/11 |
| FR-004 先复现 | 异常界面身份仍未知 | 不猜根因，不提前改 focus | Mini、Workbench、窗口事件 | 20 次事件链与窗口标签 |
| dirty candidate 删除独立授权 | 本地同名 Zip 与正式附件身份不同 | 本版先建立证据和目录合同 | 发布工程、证据治理 | 正式附件可回下载后再处置 |

## Bugfix 摘要

V105-BUG-001 与 V105-BUG-002 已在 M3 按最小边界修复并完成定向复验；最终候选的键盘、通知区和系统边界仍由独立 ACC 复核。详细记录见 `doc/logs/v1.0.5-bugfix-log.md`。

## Spike / 技术探索摘要

| 主题 | 当前结论 | 是否进入本版本 | 后续动作 |
| --- | --- | --- | --- |
| 三窗单一表面 | 仅有浏览器原型，不能证明真实壳安全 | 条件进入 | V105-M5 完成真实 Tauri 壳 Spike |
| Workbench 关闭异常 | 已修复并定向复验 | 已完成 | 独立 ACC 复核通知区显式找回 |

## 验证摘要

- 自动化验证：V105-M0 至 M6 聚合门禁、前端行为与结构、TypeScript/Vite、Rust 和包身份正负向合同通过。
- 真实桌面验证：M3 左右贴边、指针/点击找回、移开收回、普通 focus 和 Workbench 关闭回归通过。
- 日历真实桌面验证：official、estimated、今天/选中/业务复合状态和浅/深主题通过。
- 表面验证：M5 在 Windows 11 的 Workbench、Settings、Wizard 和 100%/125%/150% DPI 通过，Windows 10 待环境补证。
- 打包验证：唯一 clean M6 候选已锁定，只用于独立 ACC，不是正式发布包。
- 未覆盖项：通知区真实鼠标、键盘真实焦点、故障回退、多显示器和独立 ACC。

## 收尾事项

- 文档同步：M0 至 M3 的事实、身份、修复、隐私合同和验证边界已落盘。
- 发布说明：尚未生成 v1.0.5 Release Notes 最终口径。
- 回滚方式：M3 可按 Mini 状态机、Hook、隐私 presenter、CSS 与原生几何的里程碑边界整体回退，不涉及收入、日历或配置 schema。
- 下一阶段建议：只对唯一 clean 候选执行 V105-ACC；不得换包或沿用旧候选证据。
