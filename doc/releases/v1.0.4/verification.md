# LetsMakeMoney Windows v1.0.4 验证

## 当前结论

- 阶段：M0、M1、M4、M5 完成；M2 6/8；M3 7/8；M6 13/14；ACC 进入部分验收。
- 结论：自动门禁与包体验证通过；Mini 左右贴边、隐私收起、悬停恢复、跨窗口关闭开关和重启持久化已在 100% DPI 真实 Windows 中通过。整体验收为部分通过。
- 发布判断：不可进入发布收口。当前 Zip 来自脏工作树，只是开发验收候选；仍缺干净提交重建、125%/150% DPI、深色/减少动态效果和真实多显示器补证。
- 用户可见行为：新增 Mini 左右工作区边缘隐私贴边自动隐藏，并可在 Settings 中关闭。

## M0 验证矩阵

| ID | 验证 | 结果 | 证据 |
| --- | --- | --- | --- |
| V104-M0-AUTO-001 | v1.0.3 Git、Release、Zip 身份 | 通过 | `evidence/m0-baseline.json` |
| V104-M0-AUTO-002 | M0 证据 schema 与隐私负向规则 | 通过 | `verify_v104_m0.py`、`verify_v104_m0_tests.py` |
| V104-M0-AUTO-003 | 100%/125%/150% work-area 几何 | 通过 | Rust `v104_edge_dock_geometry_matches_work_area_and_dpi_fixtures` |
| V104-M0-AUTO-004 | 负坐标与显示器丢失回落 | 通过 | Rust `v104_missing_monitor_fallback_uses_primary_work_area` |
| V104-M0-AUTO-005 | 24px 拖离阈值 | 通过 | Rust `v104_undock_threshold_is_scaled_from_logical_pixels` |
| V104-M0-AUTO-006 | v1.0.3 读取/保存 v1.0.4 v8 配置 | 通过 | Rust `v103_reader_and_writer_safely_drop_v104_optional_window_fields` |
| V104-M0-AUTO-007 | stable/fixed Rust test/build 对照 | 通过 | `m0-baseline.md` |
| V104-M0-AUTO-008 | FR-007 Runtime/Service 继承门禁 | 通过 | 15/15、21/21 |
| V104-M0-AUTO-009 | FR-009 结构/Presentation 继承门禁 | 通过 | 22/22、18/18 |
| V104-M0-AUTO-010 | 聚合入口失败非零与 `git diff --check` | 通过 | `scripts/verify_v104.ps1` |

## 待后续验证

- M2 新鲜 clone 冒烟，以及主要窗口与通知区找回的完整证据。
- M3 在无 spike 新鲜 clone 中完成构建与打包。
- M6 在 125%/150% DPI、深色主题、减少动态效果和真实多显示器环境中的补证。
- 从干净提交重新构建唯一候选，并对新哈希执行独立 Acceptance。

## M1-M3 验证矩阵

| ID | 验证 | 结果 | 证据 |
| --- | --- | --- | --- |
| V104-M1-AUTO-001 | 包专用中英文 README 正负向合同 | 通过 | 8/8 |
| V104-M1-AUTO-002 | v1.0.4 打包与包验证语义合同 | 通过 | `package_v104.ps1`、`verify_v104_package.ps1` |
| V104-M2-AUTO-001 | 脱敏摘要和外部证据索引隐私合同 | 通过 | 8/8 负向场景 |
| V104-M2-AUTO-002 | 新解压桌面冒烟脚本静态合同 | 通过 | 13/13 |
| V104-M3-AUTO-001 | 显式变量、PATH、仓库缓存和缺失失败 | 通过 | 5/5 |
| V104-M3-AUTO-002 | 固定 CI、工具链和开发环境合同 | 通过 | 17/17 |
| V104-M3-AUTO-003 | 真实环境诊断 | 通过 | Node 22.14.0、Python 3.12.8、Cargo 1.97.1、MSVC、Windows SDK、WebView2 |
| V104-M3-AUTO-004 | Rust 固定工具链定向回归 | 通过 | M0 4/4 |
| V104-M3-AUTO-005 | 无 spike 完整包构建 | 待 ACC | 需先统一升版至 1.0.4 |

## M4 验证矩阵

| ID | 验证 | 结果 | 证据 |
| --- | --- | --- | --- |
| V104-M4-AUTO-001 | hidden/shown、重复事件、卸载和请求代际保护 | 通过 | `dashboard-lifecycle.behavior.ts`，14/14 |
| V104-M4-AUTO-002 | 配置保存成功、无变化、业务失败、invoke 异常和重试 | 通过 | `high-risk-combinations.behavior.ts` |
| V104-M4-AUTO-003 | 同步失败保留可信快照、初次错误和成功收敛 | 通过 | `high-risk-combinations.behavior.ts` |
| V104-M4-AUTO-004 | browser/Tauri 等价 fixture、command/event 和 listener 清理 | 通过 | `high-risk-combinations.behavior.ts`，合计 24/24 |
| V104-M4-AUTO-005 | Runtime、配置、Service、生命周期、同步、Presentation、主题唯一聚合入口 | 通过 | `scripts/verify_architecture.ps1`，158 项断言 |
| V104-M4-AUTO-006 | FR-007 Runtime/Service 继承门禁 | 通过 | Runtime 15/15、Service 21/21 |
| V104-M4-AUTO-007 | FR-009 结构/Presentation 继承门禁 | 通过 | Structure 22/22、Presentation 29/29 |
| V104-M4-AUTO-008 | 高风险聚合连续 10 次 | 通过 | 本地 10/10，无随机失败 |
| V104-M4-MAN-001 | 通知区、DPI、多显示器与真实 Mini 贴边 | 待候选 | `manual-evidence-plan.md` |

## M5 验证矩阵

| ID | 验证 | 结果 | 证据 |
| --- | --- | --- | --- |
| V104-M5-AUDIT-001 | Spike、v0.9 原型/Figma/动画、iOS、用户手册、release 和日志盘点 | 通过 | `historical-assets.md` |
| V104-M5-AUDIT-002 | 代码、脚本和文档引用扫描 | 通过 | `historical-assets.md`；旧版脚本引用被明确保留 |
| V104-M5-AUDIT-003 | Windows 与独立 iOS 仓库路径级比较 | 通过 | 同名 2 份原型和 5 份过程文档均内容不同 |
| V104-M5-AUDIT-004 | 许可、隐私和责任仓库分类 | 通过 | `ASSETS_LICENSE.md`、`ASSETS_MANIFEST.md`、资产 manifest |
| V104-M5-AUDIT-005 | 迁移前签核、恢复和回滚门禁 | 通过 | `historical-assets.md` 第 5 节 |
| V104-M5-AUDIT-006 | 本版无历史资产移动或删除 | 通过 | `git diff --name-status --diff-filter=DR` 为 0 |

## M6 与开发验收矩阵

### 候选身份

- 分支：`main`
- 构建基线：`09f838d05c67efb5219437ec2208920e441f3f52`
- 工作树：有未提交变更
- Zip：`LetsMakeMoney-v1.0.4-windows-x86_64.zip`
- Zip 大小：`3,228,960` 字节
- Zip SHA256：`C67E730BF81741D03BFAF6D14F3F16EB74FD8591D8B3AB76D45A980E854C249B`
- EXE SHA256：`B2A1831D0F7832C77033582871C12A2148CC8F3279753A5B812C293869ED1C66`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- 身份边界：仅用于开发验收，不得作为正式 Release 候选。

| ID | 验证 | 结果 | 证据 |
| --- | --- | --- | --- |
| V104-M6-AUTO-001 | Mini 几何、状态机、timer、配置兼容和日志隐私 | 通过 | `verify_v104.ps1`、`verify_v104_m6.py` |
| V104-M6-AUTO-002 | 跨窗口关闭贴边开关，收起 Mini 立即恢复完整内容 | 通过 | `mini-edge-auto-hide.behavior.ts` 22/22、`desktop-services.behavior.ts` 27/27 |
| V104-M6-GUI-001 | 左右工作区边缘停靠与自动收起 | 通过 | `manual-verification.md`、语义日志 |
| V104-M6-GUI-002 | 收起态不显示工资，悬停/点击展开，移开后收回 | 通过 | `manual-verification.md` |
| V104-M6-GUI-003 | Settings 关闭自动隐藏后立即展开且不再收起 | 通过 | `manual-verification.md`、`mini.edge_dock.canceled reason=settings_disabled` |
| V104-M6-GUI-004 | 重启后开关保持关闭且 Mini 保持 floating | 通过 | `manual-verification.md` |
| V104-M6-GUI-005 | 100% DPI 清晰度与窗口边界 | 通过 | `manual-verification.md` |
| V104-M6-GUI-006 | 125%/150% DPI | 待人工补证 | 当前真实环境未执行 |
| V104-M6-GUI-007 | 深色主题与减少动态效果 | 待人工补证 | 当前真实环境未执行 |
| V104-M6-GUI-008 | 多显示器、负坐标与显示器移除回落 | 待人工补证 | 自动几何通过，缺真实硬件证据 |

## 自动门禁结果

- `scripts/verify_v104.ps1`：通过。
- TypeScript/Vite 生产构建：通过。
- Rust test、format 与 clippy：通过。
- `scripts/package_v104.ps1`：通过。
- `scripts/verify_v104_package.ps1`：通过。
- 验收摘要生成与复核：通过，结论为 `partial`。
- 历史版本文档状态：通过。
- v1.0.4 UTF-8、乱码和本地链接：通过。
- `git diff --check`：通过。
- 详细机器证据：`evidence/acceptance-summary.json`、`evidence/acceptance-summary.md`。

## 用户环境恢复

- 普通 `%APPDATA%\io.letsmakemoney.windows` 与验收前备份逐文件比较：`7/7` 一致。
- 全部 LetsMakeMoney 进程已停止：`0`。
- Codex 沙箱化运行产生的数据与普通用户数据隔离，不作为用户配置持久化证据。
- Computer Use 原始截图未建立持久外部归档；仓库只保留脱敏身份、结果与语义日志计数，未将缺失原始证据冒充为已归档。

## 当前发布门禁

1. 从干净提交重新构建，要求 `source_tree_dirty=false`。
2. 对新 Zip、EXE、DLL、README、BUILD-INFO 和 SHA256SUMS 重新锁定身份。
3. 补齐 125%/150% DPI、深色主题、减少动态效果和真实多显示器证据，或由项目所有者在发布决策中明确延期。
4. 使用最终哈希完成主要窗口、Wizard、通知区和 Mini 找回的独立冒烟。

在上述门禁关闭前，v1.0.4 只能判定为“开发实现完成、验收部分通过”，不能判定为可发布。
