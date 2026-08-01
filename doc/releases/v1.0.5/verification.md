# LetsMakeMoney Windows v1.0.5 验证

## 1. 当前结论

| 项目 | 状态 |
| --- | --- |
| 当前阶段 | v1.0.5 Stable 已发布，tag、Release、published 模式与回下载核验通过 |
| M0 结论 | 通过，8/8 |
| M1 结论 | 通过，8/8 |
| M2 结论 | 通过，10/10；仅完成行为刻画与复现，缺陷未修复 |
| M3 结论 | 通过，10/10；FR-003、FR-004 已按最小边界修复 |
| M4 结论 | 通过，8/8；日历内容与方案 A 已实现并定向复验 |
| M5 结论 | 通过，8/8；保留三窗单一表面候选，Windows 10 待环境补证 |
| M6 结论 | 通过，10/10；唯一 clean 候选已从干净提交构建并锁定 |
| 用户可见实现 | M3 至 M5 范围已实现：Mini 隐私行为、日历复合状态与三窗单一表面 |
| v1.0.5 候选 | 修复后 clean 候选通过 M6 与独立 ACC；最终发布对象已由干净发布提交重建 |
| 构建 / 打包 | TypeScript/Vite/Rust、隔离打包、candidate 与 published 包验证全部通过 |
| 发布判断 | 已发布；GitHub Stable Release 与回下载哈希已核实 |

历史验收 candidate 未直接上传；正式发布对象已从最终合并后的干净提交重新构建并通过 published 模式验证。

## 2. M0 验证对象

- 开发基线：`main` / `8a63da7836fb24c3b7f8ff12f896ac40571adeb7`。
- 正式回归基线：GitHub v1.0.4 Release Zip `C4F288...DE50E`。
- 本地 dirty candidate：Zip `C67E730...C249B`，保留但禁止作为正式对象。
- 机器证据：`evidence/m0-baseline.json`。
- M0 聚合入口：`scripts/verify_v105.ps1 -Milestone M0`。

## 3. M0 验证结果

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| Git、tag、Release、资产身份 | 通过 | `m0-baseline.md`、机器证据 |
| 正式 Zip 回下载 SHA 与 BUILD-INFO | 通过 | GitHub asset digest、包内事实 |
| dirty candidate 路径、SHA、dirty 与 HEAD | 通过 | 本地只读交叉核对 |
| 正式与 dirty 对象不可混淆 | 通过 | Zip、HEAD、dirty、built_at、EXE 均不同 |
| PRD、方案 A、FR-008 回退 | 通过 | PRD / traceability / dev plan |
| FR-001 至 FR-010 实现与缺口映射 | 通过 | `m0-baseline.md` |
| Mini v1.0.4 状态、事件、timer、几何、配置 | 通过 | 源码与既有测试只读审计 |
| FR-004 20 次复现合同 | 通过（合同建立） | `fr004-reproduction-contract.md`；真实执行留给 M2 |
| 主题/DPI/边缘/显示器矩阵 | 通过（矩阵建立） | `evidence-matrix.md`；硬件项仍待执行 |
| v1.0.5 聚合骨架 | 通过 | `verify_v105.ps1`、M0 正/负向验证器 |
| 业务代码差异 | 通过，0 | `git diff -- apps/windows-v1/src apps/windows-v1/src-tauri/src` |
| dirty candidate 处置 | 通过，未删除 | 处置状态为等待独立授权 |

## 4. 聚合验证骨架

M0 聚合入口执行：

1. `verify_v105_m0.py`：机器证据、文档、tag、dirty candidate 包内身份和安全边界。
2. `verify_v105_m0_tests.py`：正式/dirty 混淆、方案漂移、复现次数漂移、回退漂移和敏感路径负向测试。
3. `verify_v10_docs.ps1`：UTF-8、乱码、链接和文档状态。
4. `git diff --check`。

实际执行命令：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\verify_v105.ps1 -Milestone M0
```

实际结果：M0 正向检查 `6/6` 通过、负向合同 `8/8` 通过、继承文档检查覆盖 75 份文档、`git diff --check` 通过。当前机器的默认 PowerShell 执行策略会阻止直接运行本地脚本，因此验证入口显式使用 `-ExecutionPolicy Bypass`；该参数只影响当前进程，不修改系统执行策略。

本入口当前不执行 TypeScript/Vite/Rust build，也不打包。M1-M6 只能扩展同一个入口，不能新建互相漂移的“旁路通过脚本”。

## 5. 继承证据与失效条件

| 证据 | 当前状态 | 失效条件 | 失效后的处理 |
| --- | --- | --- | --- |
| v1.0.4 GitHub Release 身份 | 锁定 | tag/asset 被远端改写，或回下载 SHA 不符 | 立即阻塞，重新审计远端对象 |
| v1.0.4 Mini 几何与配置兼容 | 可继承为基线 | `platform.rs` 阈值、config schema/serde、位置持久化变化 | 重跑 Rust 几何和配置兼容测试 |
| v1.0.4 Mini 状态机 | 可继承为刻画基线 | controller、Hook、drag、window source 发生变化 | M2/M3 全量状态机与真实桌面重验 |
| v1.0.4 托盘与窗口找回 | 可继承为回归基线 | show/hide/toggle、focus、lifecycle event 变化 | 通知区真实鼠标与窗口策略重验 |
| 开发前原型矩阵 | 仅 L0 | 原型状态、文案、主题或尺寸变化 | 重跑原型静态矩阵；仍不能替代真实壳 |
| FR-004 复现 | 已产生，20/20 | 正式包 SHA、配置、入口、关闭方式或事件采集合同变化 | 20 次全部作废并重跑 |
| FR-008 Spike | M5 已通过并保留候选 | WindowFrame、Tauri 配置、CSS 表面、OS/DPI 或候选哈希变化 | 受影响窗口全部重验或回退 |
| v1.0.5 candidate 验收 | 尚未产生 | source HEAD、dirty 状态、Zip/EXE/DLL/README 任一 SHA 变化 | 整套候选自动与 GUI 证据失效 |

历史证据失效不等于删除：原结论保留为当时对象的事实，后续只能新增重验结果，不能把新证据覆盖成旧候选通过。

## 6. M0 未执行项

- 未执行 FR-004 的 20 次真实桌面操作。
- 未执行 125%/150% DPI、多显示器、负坐标和显示器移除。
- 未执行三窗真实 Tauri 壳 Spike。
- 未修改或验证 v1.0.5 用户可见实现。
- 未构建、未打包、未创建候选、未执行发布验收。

这些项目是后续里程碑的计划输入，不得在 M0 写成通过。

## 7. 下一验证入口

M5 已完成。下一批执行 V105-M6：统一版本身份、聚合门禁、隔离候选打包和候选文档；在没有干净提交时不得把 dirty 开发候选写成正式验收对象。

## 8. M1 验证结果

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| 三个 README 当前版本、命令和 Release 链接 | 通过 | README 与 docs gate |
| candidate / acceptance / published cache / staging 目录合同 | 通过 | `artifact-and-evidence-contract.md`、`.gitignore` |
| BUILD-INFO 严格身份字段 | 通过 | `v105-build-info.schema.json`、包验证器 |
| Candidate 模式 | 通过 | clean 与 dirty 两条合成正向；错误 HEAD、版本、字段、载荷和目录均拒绝 |
| Published 模式 | 通过 | clean published 正向；dirty、tag、URL、回下载 SHA、checksums 和目录漂移均拒绝 |
| 脱敏摘要与外部原始证据索引 | 通过 | 三份证据 schema、`evidence/m1-contract.json` |
| 唯一副本保护 | 通过 | 删除与历史覆盖负向夹具 |
| dirty v1.0.4 candidate | 通过，仍保留 | 删除未授权，published cache 尚未复验 |
| 业务代码差异 | 通过，0 | Git scoped status |
| 构建 / 打包 / 真实候选 | 未执行 | M1 边界 |

实际入口：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\verify_v105.ps1 -Milestone M1
```

结果为 M0 正向 `6/6`、M0 负向 `8/8`、M1 正向 `8/8`、M1 负向 `8/8`、包身份 `3` 条正向和 `12` 条负向、89 份文档与 `git diff --check` 全部通过。合成包仅证明验证器行为，不构成 v1.0.5 candidate 或发布证据。

## 9. M2 验证结果

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| Mini 交互状态夹具 | 通过，8 状态 | `fixtures/v105-mini-interaction-fixtures.json` |
| 左右边缘当前行为刻画 | 通过 | 无 `pointerleave` 时不调度收起，后续 `pointerleave` 可收起 |
| M3 目标行为 | 按预期未通过 | `M2_RED_NO_POINTERLEAVE_RETRACT`；证明缺陷尚未修复 |
| 取消、拖回与晚到 timer | 通过 | menu、modal、focus 锁和浮动态行为断言 |
| FR-004 真实桌面复现 | 通过，20/20 复现 | v1.0.4 正式 Zip、新解压目录、固定关闭入口 |
| 异常界面身份 | 已确认 | Mini 展开态；不是托盘菜单、Settings 或 Wizard |
| FR-004 事件根因 | 已确认 | 原生 Mini shown 为 0；普通 focus 后出现 `source=window_shown` reveal |
| FR-004 路由 | 进入 V105-M3 | 只分离普通 focus 与 explicit shown |
| 托盘、位置、配置基线 | 未改变 | 原配置哈希前后一致，测试环境已恢复 |
| 业务代码差异 | 通过，0 | `apps/windows-v1/src` 与 `src-tauri/src` scoped status |
| 构建 / 打包 / v1.0.5 候选 | 未执行 | M2 停止边界 |

实际入口：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\verify_v105.ps1 -Milestone M2
```

M2 聚合入口继承 M0/M1 门禁，并新增：

1. `verify_v105_m2.py`：夹具、脱敏摘要、根因路由、环境恢复和业务代码边界。
2. `verify_v105_m2_tests.py`：轮次、事件来源、M3 路由、红灯状态、配置恢复、敏感路径等 8 条负向合同。
3. esbuild + Node 执行当前行为 characterization。
4. esbuild + Node 执行 M3 目标行为，并要求以指定 marker 非零退出；意外通过会使 M2 门禁失败。

仓库脱敏摘要为 `evidence/m2-characterization-summary.json`。原始截图、完整日志和逐轮本地证据保存在 Git 忽略目录，只用于复核，不进入仓库。原用户配置和日志已恢复，未修改注册表，结束后相关进程数为 0。

### M2 结论边界

- `V105-BUG-001`：已确认，未修复。
- `V105-BUG-002 / FR-004`：已确认，20/20，未修复，进入 M3。
- M2 通过表示“复现和根因已闭环”，不表示用户可见行为已修复、v1.0.5 候选已创建或版本可发布。

## 10. M3 验证结果

### 10.1 对象身份

- 候选 ID：`V105-M3-20260801-015617`。
- 类型：`dirty-controlled-m3-candidate`，来源基线为 `8a63da7836fb24c3b7f8ff12f896ac40571adeb7`。
- EXE SHA256：`67F14FB8E4455AF20693E2AA279D42B0B827C224E13B2B07EE77149BC4AB5E61`。
- Native DLL SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 该对象来自有意的 M0-M3 dirty 工作树，仅用于开发里程碑验证，不是正式候选、发布包或 Release 附件。

### 10.2 自动与真实桌面结果

| 检查 | 结果 | 证据边界 |
| --- | --- | --- |
| Mini 状态机 | 通过，37/37 | generation、单 timer、取消、晚到结果与交互锁 |
| 隐私文案选择器 | 通过，10/10 | loading、error、四个工作阶段与四类休息状态 |
| Rust 单元测试 | 通过，54/54 | 左右边缘、三档 DPI、正常/收起位置分离与故障回退 |
| TypeScript strict / Vite build | 通过 | M3 当前源码生产构建 |
| clippy / fmt / 架构门禁 | 通过 | 未改变收入、日历与配置 schema |
| 左右边缘首次收起 | 真实 Windows 通过 | 释放后无需额外点击；FR-003 关闭 |
| 点击、指针进入、移开收回 | 真实 Windows 通过 | `mini.edge.*` 语义事件与截图 |
| 普通 focus | 真实 Windows 通过 | 收起态不展开 |
| 关闭 Workbench | 真实 Windows 通过 | Mini 保持收起；FR-004 关闭 |
| 键盘 Enter/Space 找回 | 自动合同通过，ACC 待真实补证 | 当前 Computer Use 无法可靠把键盘焦点留在竖条 |
| 通知区显式找回 | 自动/原生接线通过，ACC 待真实补证 | 当前 Computer Use 无法稳定保持通知区焦点 |
| 深色主题 | CSS 与选择器合同通过，ACC 待真实视觉补证 | M3 未将自动结果冒充人工观感 |
| 原生故障回退 | Rust/状态机合同通过，ACC 待受控桌面补证 | 必须保持完整窗口可找回 |

隐私竖条逻辑宽度为 `28px`。当前 100% DPI 的实测可见宽度约为 21 个物理像素，因为原生收起几何按合同将 7px 置于屏幕外；这不改变 28px 逻辑交互表面。DOM、ARIA 及 217 条 `mini.edge.*` 日志未发现月薪、今日已赚、日薪、时薪或金额符号。

### 10.3 环境恢复与结论边界

- 原配置和原 `debug.log` 已恢复；注册表未变化；结束后 LetsMakeMoney 进程数为 0。
- 原始截图和完整日志只保存在 Git 忽略的本地证据目录；仓库只保存 `evidence/m3-mini-privacy-summary.json` 脱敏摘要。
- M3 通过表示 FR-003、FR-004 与 FR-005 的本里程碑实现和定向验证闭合，不表示 v1.0.5 已完成独立候选验收或可发布。

## 11. M4 验证结果

### 11.1 对象身份

- 候选 ID：`V105-M4-20260801-024851`。
- 类型：`dirty-controlled-m4-candidate`，来源基线为 `8a63da7836fb24c3b7f8ff12f896ac40571adeb7`。
- EXE SHA256：`1A2C5AA9A2F58B42EB2B3D3DF0F5875C42580A99D0D051F6F866EC7B901FE55F`。
- Native DLL SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 该对象来自有意的 M0-M4 dirty 工作树，只用于开发里程碑验证，不是正式候选、发布包或 Release 附件。

### 11.2 自动与真实桌面结果

| 检查 | 结果 | 证据边界 |
| --- | --- | --- |
| 日历复合状态矩阵 | 通过，49/49 | 六种业务状态、今天、选中、stale、disabled、ARIA 与键盘合同 |
| TypeScript strict / Vite build | 通过 | M4 当前源码生产构建 |
| Rust test / fmt / clippy | 通过，54/54 | 收入、日历数据和配置 schema 未改变 |
| official 正常态 | 真实 Windows 通过 | 日历首屏没有常驻来源块 |
| estimated 风险态 | 真实 Windows 通过 | 2027 年浅色与深色均显示估算及非官方声明 |
| 今天 + 选中 + 业务状态 | 真实 Windows 通过 | 左上“今”、数字加粗、选中边框和休息日底色并存 |
| ARIA 复合语义 | 通过 | `8月1日，休息日，今天，当前选中` |
| loading / integrity error / retry | 自动合同通过，ACC 待真实补证 | 未伪造桌面失败状态 |
| 长内容 | 自动合同通过，ACC 待真实补证 | 不作为 M4 实机观感结论 |
| 100% DPI | 真实 Windows 通过 | 浅色与深色无裁切和文本重叠 |
| 125% / 150% DPI | 自动合同通过，ACC 待真实补证 | 开发里程碑未修改系统缩放 |

### 11.3 环境恢复与结论边界

- 原 `config.json`、`config.json.previous` 和 `debug.log` 已按 SHA256 恢复；注册表未变化；结束后进程数为 0。
- 原始 Computer Use 画面保留在本次任务记录中；本地忽略目录只保存候选身份、环境备份和脱敏操作索引，仓库不保存原始截图或完整日志。
- 仓库脱敏摘要：`evidence/m4-calendar-presentation-summary.json`。
- M4 通过表示 FR-006、FR-007 与相关 FR-009 门禁在本里程碑闭合，不表示 v1.0.5 已完成独立候选验收或可发布。

## 12. M5 验证结果

### 12.1 对象身份

- v1.0.4 正式回归对象：Zip SHA256 `C4F28892831891A4266C4D9B12D432CD5C970BB3C9B36A6B8DB21FA2566DE50E`，EXE SHA256 `E0C9C603703FC2632619AFBC84F63B1B1D403273CD01D29AA0A308A95243E107`。
- 候选 ID：`V105-M5-20260801-032724`。
- 类型：`dirty-controlled-m5-candidate`，来源基线为 `8a63da7836fb24c3b7f8ff12f896ac40571adeb7`。
- EXE SHA256：`DF18CC5A3A99975CE1A8CEE965D0A83F2DB0FB5B4628F079FDA96D4262546A3B`。
- Native DLL SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 该对象来自有意的 M0-M5 dirty 工作树，只用于开发里程碑验证，不是正式候选、发布包或 Release 附件。

### 12.2 表面职责与自动验证

| 检查 | 结果 | 证据边界 |
| --- | --- | --- |
| v1.0.4 三窗基线 | 通过 | Workbench `922×642`、Settings `762×562`、Wizard `782×582` |
| 单一表面合同 | 通过，16/16 | Web 负责背景/边框/圆角；原生窗口负责透明壳/阴影 |
| Mini 表面保护 | 通过 | Mini 保留 CSS 阴影且未使用 `WindowFrame` |
| TypeScript strict / Vite build | 通过 | M5 当前源码生产构建 |
| Rust test / fmt / clippy / release build | 通过，54/54 | 收入、日历数据和配置 schema 未改变 |

### 12.3 真实 Windows 结果

| 检查 | 结果 | 说明 |
| --- | --- | --- |
| Workbench | 通过 | 浅/深、拖动、关闭与焦点恢复正常 |
| Settings | 通过 | 浅/深、拖动、保存与未保存关闭模态正常 |
| Wizard | 通过 | 浅色真实壳、拖动与退出模态通过；深色由合同覆盖并留待 ACC 复核 |
| Mini 回归 | 通过 | 隐私竖条、展开和独立阴影正常 |
| 100% DPI | 通过 | 真实 Windows 系统缩放，无裁切或双边框 |
| 125% DPI | 通过 | 真实 Windows 系统缩放，无裁切或异常尺寸 |
| 150% DPI | 通过 | 真实 Windows 系统缩放，无裁切或异常尺寸 |
| Windows 11 | 通过 | Windows 11 Pro build 26200 |
| Windows 10 | 待环境补证 | 当前没有 Windows 10 设备或 VM，不以 Windows 11 推断通过 |

### 12.4 环境恢复与结论边界

- Windows 缩放恢复为 100%，`AppliedDPI=96`，两项 per-monitor DPI 值恢复为 `0`。
- 原 `config.json`、`config.json.previous` 和 `debug.log` 按备份 SHA256 恢复；结束后进程数为 `0`。
- 原始桌面证据保存在 Git 忽略目录，仓库只保存 `evidence/m5-window-surface-summary.json` 和 `window-surface-spike.md`。
- M5 结论为“通过且 Windows 10 待环境补证”；保留单一表面候选进入 M6。M5 通过不表示 v1.0.5 已完成独立候选验收或可发布。

## 13. M6 干净候选身份

### 13.1 构建对象

- 候选 ID：`V105-20260801T002456Z-277b121b-clean`。
- 源码 HEAD：`277b121bbc68958382d06f4b29de3bd7685650f4`。
- 源码状态：`clean`，`source_tree_dirty=false`。
- Zip：`LetsMakeMoney-v1.0.5-windows-x86_64.zip`，3,231,540 字节。
- Zip SHA256：`BE2E1004427859AD30A4A4B23B12C00CF8A5EBD69F7A2442F345813F28CA521C`。
- EXE SHA256：`0B650A0DF85A315104BDDA0B5E0E0B1E0D97DA21A5B96D72C26217FC3206A25A`。
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 中文 README SHA256：`904D79C7FE4B28F320AF2FA91732E90587B11BFF593EE2A57A4926E1FB5AFA39`。
- 英文 README SHA256：`2991F36F5FA307B99364D9CAEE068C3848629725E7CEBE29EC349B5A615539B0`。

### 13.2 当前结论

- 隔离打包、候选目录、BUILD-INFO、内部载荷哈希和 `SHA256SUMS.txt` 已通过 candidate 模式验证。
- 候选明确记录 `source_tree_dirty=false`，但独立验收与发布授权均未完成；**不可发布**。
- M6 完整聚合门禁已对上述锁定对象通过；它是唯一独立验收对象，不等于已完成验收或获得发布授权。

### 13.3 聚合结果

- M0 至 M5 继承门禁、前端行为与结构门禁通过。
- candidate/published 包身份合同通过；M6 负向合同 `13/13` 通过。
- TypeScript strict 与 Vite production build 通过，构建转换 `1,826` 个模块。
- Rust test `54/54`、fmt、clippy 和 release build 通过。
- 文档状态、94 份文档 UTF-8/乱码/链接、敏感路径、隐私文本和 `git diff --check` 通过。
- 首次聚合暴露 M5 文档路由与 M6 应用版本两项过时断言；两项均按现有真实结构修正并增加负向测试，最终完整复跑通过。
- 证据：`evidence/m6-candidate-summary.json`；原始输出保存在 Git 忽略目录 `.artifacts/acceptance/v1.0.5/`。

## 14. 独立候选验收

### 14.1 对象与环境

- 验收 ID：`ACC-20260801-083448`。
- 候选 ID：`V105-20260801T002456Z-277b121b-clean`。
- 候选源码 HEAD：`277b121bbc68958382d06f4b29de3bd7685650f4`。
- Zip SHA256：`BE2E1004427859AD30A4A4B23B12C00CF8A5EBD69F7A2442F345813F28CA521C`。
- EXE SHA256：`0B650A0DF85A315104BDDA0B5E0E0B1E0D97DA21A5B96D72C26217FC3206A25A`。
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 环境：Windows 11，2560×1440，工作区 2560×1392，100% DPI，单显示器。
- 运行入口：仅运行 `ACC-20260801-083448/run/` 下全新解压的 EXE。

### 14.2 分项结果

| ACC | 结果 | 说明 |
| --- | --- | --- |
| ACC-001 | 通过 | 分支、源码、Zip、EXE 和 DLL 身份一致 |
| ACC-002 | 通过 | 全新解压、配置与日志备份完成 |
| ACC-003 | 未通过 | 首次右侧贴边后保持焦点时不收起，失焦后才收起 |
| ACC-004 | 部分通过 | 休息态隐私条零金额泄露通过；全状态矩阵受 ACC-003 阻塞 |
| ACC-005 | 部分通过 | Workbench 拖动与关闭通过；通知区真实鼠标未完成 |
| ACC-006 | 通过 | 日期调整事务与日历复合状态通过 |
| ACC-007 | 部分通过 | 本轮 100% DPI 通过；125%/150% 只继承 M5 |
| ACC-008 | 部分通过 | 核心配置与窗口链路通过，隐私自动隐藏回归未通过 |
| ACC-009 | 待人工补证 | 当前无多显示器环境 |
| ACC-010 | 通过 | 用户配置、日志和开机自启状态恢复 |
| ACC-011 | 通过 | 验收事实已写回正式文档 |
| ACC-012 | 未通过 | 发布收口被 V105-BUG-001 阻塞 |

### 14.3 发布阻塞证据

- 拖拽完成后原生侧正确记录 `side=right`，但前端的 `focus_inside` 交互锁仍存在。
- 失焦前没有收起调度；失焦后才出现 `mini.edge.retract.scheduled source=lock_released` 与 `mini.edge_dock.retracted source=lock_released`。
- 源码行为与日志一致：`eligible()` 受 focus 锁阻止，而 `dragCompleted()` 只清理 pointer intent，没有处理本次拖拽留下的 focus 锁。
- 原始证据位于 `.artifacts/acceptance/v1.0.5/ACC-20260801-083448/evidence/`，仓库文档不复制包含本机状态的完整日志。

### 14.4 环境恢复与结论

- 原 `config.json`、`config.json.previous` 与 `debug.log` 的恢复后 SHA256 均与验收前一致。
- 开机自启匹配项为 0，结束后 LetsMakeMoney 进程数为 0。
- 结论：**未通过**。必须先完成最小修复，从新干净提交重建候选，再复验受影响项目；本候选不得发布。

## 15. ACC 修复后替代候选锁定（复验前历史状态）

- 候选 ID：`V105-20260801T013259Z-6c9f010a-clean`。
- 源码 HEAD：`6c9f010a164fb2b73c9068bd4fdcb6e863bd5100`。
- 源码状态：`clean`，`source_tree_dirty=false`。
- 构建时间：`2026-08-01T01:33:30.3812708Z`。
- Zip：`LetsMakeMoney-v1.0.5-windows-x86_64.zip`，3,231,697 字节。
- Zip SHA256：`0FED6256E1E979D4BEC41E64C4290EF1917A6A6AB2B04D9A6EF47F1DD3C48826`。
- EXE：10,110,464 字节；SHA256 `BCF2309F3EF12FC494BEC7A4E43A5FDD62612CB7D086CB1C04AA5533AAE75112`。
- WebView2Loader：160,320 字节；SHA256 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 当时包身份已通过，但 M6 聚合复核与独立真实 Windows 复验尚未完成，因此**不可发布**；后续最终结果见第 16 节。

## 16. 修复后候选最终复验

### 16.1 验收对象

- 验收 ID：`ACC-20260801-105930-retest`。
- 候选 ID：`V105-20260801T013259Z-6c9f010a-clean`。
- 源码 HEAD：`6c9f010a164fb2b73c9068bd4fdcb6e863bd5100`，源码状态 `clean`。
- Zip：`3,231,697` 字节，SHA256 `0FED6256E1E979D4BEC41E64C4290EF1917A6A6AB2B04D9A6EF47F1DD3C48826`。
- EXE：`10,110,464` 字节，SHA256 `BCF2309F3EF12FC494BEC7A4E43A5FDD62612CB7D086CB1C04AA5533AAE75112`。
- WebView2Loader：`160,320` 字节，SHA256 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。

### 16.2 自动与真实 Windows 结果

| 项目 | 结论 | 证据边界 |
| --- | --- | --- |
| M6 聚合 | 通过 | 17 项负向合同、15 个前端行为套件、22/22 架构检查、Rust 54/54、fmt、clippy、release、包身份和文档门禁通过 |
| ACC-001 候选身份 | 通过 | 分支、HEAD、Zip、EXE、DLL、大小与 SHA256 一致 |
| ACC-003 Mini 隐私状态机 | 通过 | 左右首次收起、悬停展开、移开收回、点击与键盘找回均完成真实 GUI 复验 |
| ACC-004 双主题与零泄露 | 通过 | 深色 working 隐私条只显示阶段倒计时，敏感字段扫描为零 |
| ACC-005 Workbench 与通知区 | 通过 | 关闭 Workbench 后 Mini 保持收起；真实通知区图标经真实鼠标左键完成隐藏与恢复 |
| ACC-006 日历 | 通过 | M6 与既有未失效真实证据通过 |
| ACC-007 DPI 与表面 | 通过 | 本轮 100%；125%/150% 沿用未受修复影响的 M5 真实证据 |
| ACC-008 核心回归 | 通过 | v1.0.4 自动全回归与受影响 Mini 真实 GUI 通过 |
| ACC-009 多显示器 | 暂不验证 | 项目所有者批准延期，不阻塞本版 |
| ACC-010 环境恢复 | 通过 | 正常与虚拟化用户根按哈希恢复，注册表状态不变，进程数为 0 |
| ACC-011 文档 | 通过 | 当前事实、verification、manual、progress、checklist 与 release notes 同步 |
| ACC-012 发布判断 | 通过 | 当前无发布阻塞，可进入发布收口 |

通知区证据使用 Windows 通知区域中名称为 `LetsMakeMoney` 的真实图标与物理鼠标事件：第一次左键后 Mini 原生窗口由可见变为隐藏，进程保持运行；第二次左键后窗口恢复可见。日志同时出现 `tray.left_click`、`window.hidden`、`tray.left_click`、`window.shown`。

### 16.3 证据边界与最终判断

- 旧候选 `V105-20260801T002456Z-277b121b-clean` 的失败结论继续保留，不被本节改写。
- 自动隐藏未保存前置配置产生的单张展开截图属于无效尝试，不计入通过或失败。
- Windows 10 因无设备或 VM 保持环境待补证，不以 Windows 11 推断通过。
- 原始截图、完整日志和用户配置只保存在 Git 忽略的本地验收目录；仓库只跟踪脱敏摘要。
- 最终结论：**通过，发布收口已获授权并开始执行**。最终发布身份仍待合并后干净重建、published 模式和 GitHub 回下载核验锁定。

## 17. 最终合并后重建候选

- 候选 ID：`V105-20260801T075629Z-ffc431af-clean`。
- 源码 HEAD：`ffc431af3fbf7c3b54bca8aaff44946cc8d6aeaf`。
- 源码状态：`clean`，`source_tree_dirty=false`。
- 构建时间：`2026-08-01T07:57:44.7606083Z`。
- Zip：`LetsMakeMoney-v1.0.5-windows-x86_64.zip`，3,231,663 字节；SHA256 `019B706E18E7D57D0B7E6DBFB6300762422B5723A11EB6ACCB601DA438215889`。
- EXE：10,110,464 字节；SHA256 `68FA8FC443B12A2BA8BD757F532EC6B90E09E3DA7E1027255267150C4DAEC37A`。
- WebView2Loader.dll：160,320 字节；SHA256 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 最终合并提交相对通过 `ACC-20260801-105930-retest` 的业务源码只增加文档与历史验证器合同修正；旧候选及其真实 Windows 验收记录继续保留，不被本节覆盖。
- 该候选已通过 annotated tag、GitHub Release、published 模式和 GitHub 回下载核验，现为正式附件。
- 最终候选 M6 聚合：通过；包含行为级测试、TypeScript strict、Vite production build、54 个 Rust 测试、cargo fmt、clippy 和 release build。
- 受控启动冒烟：`LMM-V105-SMOKE-20260801080945`；新解压 EXE 成功显示 Mini，Zip 与 EXE 哈希匹配，用户环境精确恢复且残留进程为 0。脚本结果为 `partial`，因为本轮只执行非交互启动范围；完整 GUI 结论继续引用独立验收 `ACC-20260801-105930-retest`。

## 18. 发布后远端核验

- Release 源提交：`ffc431af3fbf7c3b54bca8aaff44946cc8d6aeaf`。
- annotated tag：`v1.0.5`；tag object `7d7734ca1f45d24672a46523ae4bd93cfaf201fb`，peeled target 与发布源提交一致。
- GitHub Release：`https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.5`；Stable、非草稿、非预发布。
- Release 附件严格为 2 个：`LetsMakeMoney-v1.0.5-windows-x86_64.zip` 与 `SHA256SUMS.txt`。
- GitHub 回下载 Zip 大小为 3,231,663 字节，SHA256 为 `019B706E18E7D57D0B7E6DBFB6300762422B5723A11EB6ACCB601DA438215889`，与最终候选及 Release digest 一致。
- 回下载 `SHA256SUMS.txt` 大小为 107 字节，文件 SHA256 为 `E84F6F01A6A703829926AC684325C3B2A6D6737AADB2381880BF4EDE962C6741`。
- `verify_v105_package.ps1 -Mode published`：通过；tag、Release URL、下载目录、Zip、checksum 与 BUILD-INFO 身份一致。
- 机器可读摘要：`evidence/release-summary.json`。
- 最终结论：**v1.0.5 Stable 已发布，无发布阻塞。**
