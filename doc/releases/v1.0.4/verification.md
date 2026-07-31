# LetsMakeMoney Windows v1.0.4 验证

## 当前结论

- 阶段：M0 至 M6、ACC 全部完成。
- 结论：通过。自动门禁、包体验证、隔离干净提交构建和真实 Windows 100%/125%/150% DPI 验收通过；深色主题、减少动态效果、首次配置、日历事务、左右隐私贴边、通知区真实鼠标找回和环境恢复通过。
- 发布判断：可进入发布收口。真实多显示器、负坐标工作区与显示器移除回落由项目所有者批准延期，记录为“暂不验证”且不阻塞 v1.0.4；发布源提交变化后仍必须重新构建并锁定最终哈希。
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

## 后续边界

- M6 真实多显示器、负坐标工作区和显示器移除回落已批准延期；具备硬件环境后再补证，不得追溯写成已通过。
- 发布提交确定后，从该提交重新构建最终候选并重新锁定全部哈希。

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
| V104-M3-AUTO-005 | 无 spike 新鲜 clone 完整验证、构建与打包 | 通过 | 隔离干净提交 `661b0f748798e28f7999eac23532aa7ed7510640` |

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
| V104-M4-MAN-001 | 通知区、DPI、多显示器与真实 Mini 贴边 | 通过 | 通知区、三档 DPI 与 Mini 贴边通过；多显示器已批准暂不验证 |

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

- 分支：`main`（隔离验收 clone）
- 构建基线：`661b0f748798e28f7999eac23532aa7ed7510640`
- 工作树：干净，`source_tree_dirty=false`
- Zip：隔离验收 clone 中的 `releases/v1.0.4/LetsMakeMoney-v1.0.4-windows-x86_64.zip`
- Zip 大小：`3,229,111` 字节
- Zip SHA256：`2BBC5B79F9A615F31CFDFFC27C55450C660363A643DE5EB33A6E7B3A1B049340`
- EXE 大小：`10,108,416` 字节
- EXE SHA256：`EB0FA82F5506B775F03774E429A12DB66F838E705B608F4A7664D6F9243830DF`
- WebView2Loader 大小：`160,320` 字节
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- 身份边界：独立验收候选；该提交尚未成为最终发布提交，发布源变化后证据失效。

| ID | 验证 | 结果 | 证据 |
| --- | --- | --- | --- |
| V104-M6-AUTO-001 | Mini 几何、状态机、timer、配置兼容和日志隐私 | 通过 | `verify_v104.ps1`、`verify_v104_m6.py` |
| V104-M6-AUTO-002 | 跨窗口关闭贴边开关，收起 Mini 立即恢复完整内容 | 通过 | `mini-edge-auto-hide.behavior.ts` 22/22、`desktop-services.behavior.ts` 27/27 |
| V104-M6-GUI-001 | 左右工作区边缘停靠与自动收起 | 通过 | `manual-verification.md`、语义日志 |
| V104-M6-GUI-002 | 收起态不显示工资，悬停/点击展开，移开后收回 | 通过 | `manual-verification.md` |
| V104-M6-GUI-003 | Settings 关闭自动隐藏后立即展开且不再收起 | 通过 | `manual-verification.md`、`mini.edge_dock.canceled reason=settings_disabled` |
| V104-M6-GUI-004 | 重启后开关保持关闭且 Mini 保持 floating | 通过 | `manual-verification.md` |
| V104-M6-GUI-005 | 100% DPI 清晰度与窗口边界 | 通过 | `manual-verification.md` |
| V104-M6-GUI-006 | 125%/150% DPI | 通过 | Mini、Workbench、Settings 无裁切、重叠或模糊 |
| V104-M6-GUI-007 | 深色主题与减少动态效果 | 通过 | 深色跨窗口即时同步及重启持久化通过；系统动画关闭时收起无残留动画 |
| V104-M6-GUI-008 | 多显示器、负坐标与显示器移除回落 | 暂不验证 | 自动几何通过；项目所有者批准延期，不阻塞 v1.0.4 |
| V104-ACC-GUI-001 | 首次启动 Wizard 三步、返回、取消、关闭与完成 | 通过 | 全新隔离配置真实操作 |
| V104-ACC-GUI-002 | Workbench 今日、跨月日历及日期调整取消事务 | 通过 | 官方 2026 日历；取消后未持久化 |
| V104-ACC-GUI-003 | Windows 通知区左键隐藏、恢复与窗口找回 | 通过 | 项目所有者真实左键输入；Computer Use、进程与语义日志交叉复核 |

## 自动门禁结果

- `scripts/verify_v104.ps1`：通过。
- TypeScript/Vite 生产构建：通过。
- Rust test、format 与 clippy：通过。
- `scripts/package_v104.ps1`：通过。
- `scripts/verify_v104_package.ps1`：通过。
- 验收摘要生成与复核：通过，结论为 `passed`。
- 历史版本文档状态：通过。
- v1.0.4 UTF-8、乱码和本地链接：通过。
- `git diff --check`：通过。
- 详细机器证据：`evidence/acceptance-summary.json`、`evidence/acceptance-summary.md`。

## 用户环境恢复

- 主验收结束时，普通 `%APPDATA%\io.letsmakemoney.windows` 与验收前备份逐文件比较：配置、前一版本和日志哈希全部一致。
- Codex 隔离 Roaming 目录的配置和日志哈希与验收前备份一致。
- 全部 LetsMakeMoney 进程已停止：`0`。
- Windows 系统缩放已恢复至 100%，动画效果已恢复开启。
- 通知区补证未保存配置，但向普通用户 `debug.log` 追加了真实托盘语义事件；未沿用补证前的日志哈希结论。
- Computer Use 原始截图未建立持久外部归档；仓库只保留脱敏身份、结果与语义日志计数，未将缺失原始证据冒充为已归档。

## 发布收口要求

1. 发布源提交确定后，从该提交重新构建，要求 `source_tree_dirty=false`，并重新锁定 Zip、EXE、DLL、README、BUILD-INFO 和 SHA256SUMS。
2. 最终哈希变化后，不得沿用本候选的身份结论，必须重新执行受影响门禁。
3. 获得独立发布授权后才允许提交、推送、打 tag 和创建 Release。

v1.0.4 独立验收已通过，可以进入发布收口；本文件不授权任何远端写操作。
