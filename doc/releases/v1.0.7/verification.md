# LetsMakeMoney Windows v1.0.7 验证记录

## 当前结论

v1.0.7 首次 dirty 候选的独立验收结论为**未通过**，该历史结论与原始证据保持不变。随后 `V107-BUG-001`、`V107-BUG-002` 与高 DPI 验收发现的 `V107-BUG-003` 均已修复，自动门禁和真实 GUI 定向复验通过；通知区真实鼠标组合也已补齐。锁定 dirty 候选的验收结论现为**通过**，项目所有者已批准发布收口；但候选源树仍为 dirty，干净发布身份尚未建立，因此当前仍没有可发布候选。

M0 至 M6 已完成，M7 完成 10/12；Windows 11 单显示器 100%/125%/150% DPI 已取得真实证据。CSP 候选已按失败门禁撤销，正式配置保持不变；性能基线保留冷启动量化债务，未保留无证据优化。

## 自动验证

| 入口 | 结论 | 覆盖 |
| --- | --- | --- |
| `scripts/verify_v107_m0.ps1` | 通过 | 基线、发布身份、窗口与配置行为刻画 |
| `scripts/verify_v107_m1.ps1` | 通过 | current、config v8、版本与 IPC 合同 |
| `scripts/verify_v107_m2.ps1` | 通过 | 窗口、隐私、自由拖动与 10,000 条状态序列 |
| `scripts/verify_v107_m3.ps1` | 通过 | 日期事务、加班领域与 IPC fixture |
| `scripts/verify_v107_m4.ps1` | 通过 | 月度总结、5/6 周日历和加班月状态 |
| `scripts/verify_v107_m5.ps1` | 通过 | Combobox 14/14、窗口表面 5/5、静态合同 3/3 |
| `scripts/verify_v107_m6.ps1` | 通过 | 脚本治理、支持矩阵、脱敏证据、CSP 撤回、10+10 性能停止门禁与局部治理边界 |
| `scripts/verify_v107_m7.ps1` | 通过 | 版本身份、隔离打包、candidate/published 合同和包内容审计 |
| `scripts/verify_v107.ps1 -Milestone M7 -CandidatePath <Zip>` | 通过 | M1-M7 聚合门禁与锁定候选包验证 |
| `scripts/verify_windows_current.ps1` | 2026-08-04 最终复跑通过 | current manifest、M1-M7、架构与文档门禁、TypeScript strict、Vite、Rust 67/67、fmt、clippy 与 `git diff --check` |

## M7 验收候选身份

| 字段 | 值 |
| --- | --- |
| Candidate ID | `V107-M7-DIRTY-20260803-01` |
| 用途 | 仅用于独立 GUI 验收 |
| Source HEAD | `12b6b03ce91b716d49590e21eb8dd7fe90fa283c` |
| Source tree | dirty |
| Zip | `.artifacts/candidates/v1.0.7/V107-M7-DIRTY-20260803-01/LetsMakeMoney-v1.0.7-windows-x86_64.zip` |
| Zip SHA256 | `173207AE508DB8D8504818F16B21165164E6C50C29ABF74C4C4D5C08B40CC05D` |
| EXE SHA256 | `760C0E80952181BA80352187DCCE9C6823F3BE19B0EC1BC04553ACCC34156035` |
| WebView2Loader SHA256 | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |
| 发布许可 | 禁止；独立验收未通过且源树为 dirty |

包内 13 个登记文件通过 allowlist、哈希、许可、日历数据与私有/临时内容审计；详细机器证据见 `evidence/m7-candidate-package.json`。这组哈希只锁定验收对象，不是最终 Release 身份。独立验收摘要见 `evidence/acceptance-summary.json`。

### 修复候选

| 字段 | 值 |
| --- | --- |
| Candidate ID | `V107-M7-DIRTY-20260804-02` |
| 用途 | 仅用于两项阻塞的真实 GUI 定向复验 |
| Source HEAD | `12b6b03ce91b716d49590e21eb8dd7fe90fa283c` |
| Source tree | dirty |
| Zip | `.artifacts/candidates/v1.0.7/V107-M7-DIRTY-20260804-02/LetsMakeMoney-v1.0.7-windows-x86_64.zip` |
| Zip SHA256 | `EF57B0361B379B0D009EBD014B8717B4D7FA50C08330B297C3071A8171E56D47` |
| EXE SHA256 | `37DE58BCD9FE1F0FE41C0F31AA640E68C4A07004A9E9BC6E4C26B0FB6236FB98` |
| WebView2Loader SHA256 | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |
| 包体验证 | 通过 |
| 发布许可 | 禁止；源树为 dirty，DPI 与最终发布身份门禁未完成 |

定向复验脱敏摘要见 `evidence/acceptance-fix-summary.json`。它补充首次验收摘要，不替换首次失败记录。

### DPI 修复候选

| 字段 | 值 |
| --- | --- |
| Candidate ID | `V107-M7-DIRTY-20260804-03` |
| 用途 | 仅用于六周日历摘要修复后的真实 125%/150% DPI 定向复验 |
| Source HEAD | `12b6b03ce91b716d49590e21eb8dd7fe90fa283c` |
| Source tree | dirty |
| Zip | `.artifacts/candidates/v1.0.7/V107-M7-DIRTY-20260804-03/LetsMakeMoney-v1.0.7-windows-x86_64.zip` |
| Zip 大小 / SHA256 | `3,317,755` 字节 / `322EB52DD01AE3B9BEE50EC3346B027C2AEA6E4669505735D01A493A3028A6E5` |
| EXE 大小 / SHA256 | `10,271,744` 字节 / `91F9EB87FBA35F7A6B3165A4E25CF05E544CDC598CB329FFC150ED416072BA46` |
| WebView2Loader 大小 / SHA256 | `160,320` 字节 / `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |
| BUILD-INFO SHA256 | `66FE6121DE896AFA206BBEE394BA6E10CAE9859AD22024B099F97C0200C8D300` |
| 包体验证 | 通过 |
| 发布许可 | 禁止；源树为 dirty，必须从干净发布提交重新构建 |

首次真实 DPI 失败证据与修复后通过证据同时保留，脱敏摘要见 `evidence/acceptance-dpi-summary.json`。

## M6 条件门禁

| 门禁 | 结论 | 说明 |
| --- | --- | --- |
| 脚本 lifecycle | 通过 | 每个 `scripts/*.ps1` 唯一归类；current 仅调用 current/reusable |
| historical 误用保护 | 通过 | 版本错误、historical 引用和缺失 gate 均按预期失败 |
| Windows 11 支持矩阵 | 通过 | 单显示器 100%/125%/150% DPI 已取得真实证据 |
| Windows 10 | 未验证并收窄声明 | 不进入 v1.0.7 已验证支持声明 |
| 多显示器 | 暂不验证 | 不进入 v1.0.7 通过声明 |
| CSP 隔离候选 | 未通过，已撤销 | Mini bootstrap 不可用；正式 `csp: null` 保持不变 |
| 性能 10+10 | 部分通过 | 暖启动、JS gzip、长任务通过；冷启动超过阈值 |
| 定向性能优化 | 停止 | 跳过托盘初始化未达到 15% 收益，诊断代码已移除 |
| 用户环境恢复 | 通过 | 配置与日志 SHA256 恢复，候选进程为 0 |

## 真实 Windows 验证

| 范围 | 环境 | 结论 |
| --- | --- | --- |
| Mini 左右贴边 | Windows 11、单显示器、100% DPI | 左右各 15/15 通过 |
| Workbench 显示事务 | Windows 11、单显示器、100% DPI | 首次失败记录保留；修复候选连续三次打开/关闭通过，第 2、3 次跨过 8 秒 watchdog 后仍可见 |
| 5/6 周日历与月度总结 | Windows 11、单显示器、100% DPI | 一屏完整、无纵向滚动通过 |
| Mini、Workbench、Settings、Wizard 与 Combobox | Windows 11、单显示器、125%/150% DPI | 实际系统缩放下无裁切、重叠或文本溢出；旧候选的日历摘要失败单独保留 |
| 六周日历与月度总结修复 | Windows 11、单显示器、125%/150% DPI | `V107-M7-DIRTY-20260804-03` 定向复验通过，四项摘要和图例一屏可见 |
| 浅色/深色与跨窗口预览 | Windows 11、单显示器、100% DPI | 通过 |
| Combobox | Windows 11、单显示器、100% DPI | 指针、键盘、Escape、外点击、ARIA 通过 |
| 窗口表面 | Windows 11、单显示器、100% DPI | 未见双重阴影或框中框 |

## 独立候选验收

| 范围 | 结论 | 说明 |
| --- | --- | --- |
| 候选身份与独立解压 | 通过 | Zip、EXE、DLL 身份一致，只运行独立解压目录中的 EXE |
| Mini 隐私贴边 | 通过 | 隐私竖条、指针展开、移开收起及成对日志通过 |
| 日期调整与月度总结 | 通过 | 今日/日历共享事务、六周日历和月度统计通过 |
| Wizard 与 Settings | 通过 | 首次配置、返回、取消、完成、主题与 Combobox 通过 |
| Workbench 重复打开 | 通过 | 修复候选连续三次 requested/open/closed；第 2、3 次各等待 9.5 秒，timeout 与 initialization timeout 均为 0 |
| 关于与更新检查 | 通过 | 修复候选显示版本 `1.0.7`，检查更新返回“当前已是最新版本” |
| DPI | 通过 | 100%/125%/150% 均为真实 Windows 系统缩放；首次高 DPI 摘要失败修复后定向通过 |
| 加班完整矩阵 | 通过 | 新建、修改、保存、删除与月度汇总通过；最终补证覆盖休息日、跨夜 owner date、分钟换算及重启持久化 |
| 托盘与任务栏组合 | 通过 | 项目所有者真实鼠标完成左键隐藏、再次左键恢复和右键菜单；隐藏时固定快捷图标无运行中横线，Mini 进程保持运行 |
| 环境恢复 | 通过 | 原始配置与日志哈希恢复，无候选进程和新增加班文件残留 |

首次独立验收共保存外部原始截图 `ACC-001` 至 `ACC-028`，运行日志为 `ACC-runtime-debug-normal.log` 与 `ACC-runtime-debug-codex-sandbox.log`。修复后定向复验保存 `ACC-FIX-001` 至 `ACC-FIX-008`；运行日志 SHA256 为 `B89B36AD6A393F008F2E9734B992A08173059AE4897B3810CF5811F8EBB2FA97`。仓库不保存本机绝对路径、完整用户配置或原始日志，只保存脱敏摘要。

## 已关闭的产品阻塞

1. `V107-BUG-001`：最小 app version capability 已接入并受合同测试保护；真实 GUI 复验通过。
2. `V107-BUG-002`：复用窗口按精确 transaction 完成原生确认，stale transaction 被拒绝且 watchdog 保留；真实 GUI 与日志复验通过。
3. `V107-BUG-003`：六周日历月度总结改为稳定双列布局；真实 125%/150% DPI 定向复验通过，首次失败证据保留。

## 剩余发布门禁

1. 创建干净发布提交。
2. 从干净提交重建唯一最终候选，重新锁定并复核全部发布身份。

## 待补证

- Windows 10：取得真实证据或在发布前收窄公开支持声明。
- 多显示器：按 PRD 明确为暂不验证，不进入通过声明。

## 证据入口

- `doc/releases/v1.0.7/evidence/m0-baseline.json`
- `doc/releases/v1.0.7/evidence/m2-window-privacy.json`
- `doc/releases/v1.0.7/evidence/m3-date-overtime.json`
- `doc/releases/v1.0.7/evidence/m4-monthly-calendar.json`
- `doc/releases/v1.0.7/evidence/m5-combobox-surface.json`
- `doc/releases/v1.0.7/evidence/m6-governance-security-performance.json`
- `doc/releases/v1.0.7/evidence/m7-candidate-package.json`
- `doc/releases/v1.0.7/evidence/acceptance-summary.json`
- `doc/releases/v1.0.7/evidence/acceptance-fix-summary.json`
- `doc/releases/v1.0.7/evidence/acceptance-dpi-summary.json`
- `doc/releases/v1.0.7/evidence/acceptance-completion-summary.json`
- `doc/releases/v1.0.7/evidence/acceptance-tray-summary.json`
- `doc/releases/v1.0.7/evidence/external-evidence-index.md`

## 边界

当前修复候选由脏工作树构建，只能作为验收证据对象。真实 100%/125%/150% DPI 与托盘真实鼠标组合已完成，锁定对象验收通过；项目所有者已经批准发布收口，发布判断仍必须等待干净提交重建和最终身份复核。冷启动 P95 未达预设目标，作为已量化性能债保留；它不是对候选功能正确性的通过声明。
