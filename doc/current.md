# LetsMakeMoney 当前状态

> 本文件是项目当前状态的唯一内部入口。历史版本结论以各版本目录为准。

## 当前版本

| 项目 | 状态 |
| --- | --- |
| 当前公开版本 | Windows v1.0.5 Stable |
| 当前公开 tag | `v1.0.5` |
| 当前开发版本 | Windows v1.0.6；定向主题修复、原生关闭事务修复、干净候选构建和 GUI 身份冒烟已通过 |
| 下一版本候选 | Windows v1.0.6；等待独立发布授权 |
| v1.0.1 阶段 | 已发布 |
| v1.0.2 阶段 | 已发布 / 发布后观察 |
| v1.0.3 阶段 | 已发布 / 发布后观察 |
| v1.0.4 阶段 | M0 至 M6、ACC 全部完成，74/74；已发布 |
| v1.0.5 阶段 | M0 至 M6、ACC、tag、Release 与 published 回下载核验全部完成；已发布 |
| 技术栈 | Rust + Tauri + TypeScript/React |
| 产品形态 | 无宠物、本地优先的 Windows 收入进度工具 |
| 发布阻塞 | v1.0.5 无；v1.0.6 无技术阻塞，尚未取得推送、tag 与 Release 授权 |
| 最后更新 | 2026-08-02 |

v1.0.5 已完成 GitHub Stable Release。v1.0.6 只处理主题首帧、跨窗口 ThemeSession、配置 hydration、原生关闭事务和同源日志/门禁，不改变收入、日历、Mini 隐私贴边或窗口视觉。受控 dirty 候选继续作为历史排错证据保留；随后从干净提交 `ced768aba54bf06d61045b38c1008fe8624a6e82` 重建的新候选已通过 M6、包体验证和真实 Windows 最小身份冒烟，当前停在独立发布授权点。

## v1.0 公开基线

- v1.0 已通过并发布；`v1.0` tag 指向发布提交 `76a480602af9a3429f9919ec9f9ee66a2add089d`。
- v1.0 tag、Release 和便携包不因 v1.0.1 开发而改变。
- v0.9-beta 仍是需要桌宠体验时的历史回退版本。
- v1.0 Zip SHA256：`A5C33B9DB8787536145AE4B9A1AC00213E692C99A2201CC91EB811A0A0F3BBE6`。
- v1.0 EXE SHA256：`BD25B13F084A0F101DD77239F215019C0BB9E246847BBD15B2D0BEE98B381C44`。
- v1.0 WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 多显示器安全回落因当前设备仅有一台显示器，标记为待补证；该历史边界不因 v1.0.1 开发而追溯改写。

## v1.0.1 当前结论

v1.0.1 只处理收入、日历、状态和用户信任链，不扩展产品范围：

1. 接入 2025、2026 年中国大陆法定节假日与调休数据。
2. 日期调整支持工作日、带薪休息、不带薪休息和恢复自动。
3. 日期调整具备取消、关闭、无变化、失败补偿、持久化和全链路重算。
4. 修正跨夜班次 owner date。
5. 工作期间按秒展示收入，并每 30 秒与权威快照同步。
6. 金额使用整数分累计差分配，完整工作月严格等于月薪。
7. 增加 Rust、TypeScript、配置事务、打包和包资源行为门禁。
8. 修复日期调整反馈丢失和更新版本误判。

自动门禁、包验证和新解压候选 GUI 验收均已通过，当前无发布阻塞。`main`、`v1.0.1` tag 与 GitHub Release 已完成。

当前已验收干净发布构建：

- Zip SHA256：`DB45332F908669445B34FF40C490936B0EEAC0B41DC2FCDC2F5806924E5D1AC2`
- EXE SHA256：`C71B378E55B455BB71FA356837039DC7BBC2DA2695371AE027BA21D715FE7694`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- 构建源码提交：`4d00f97ff908d58f4ca14a6218377386c10bdc19`，`source_tree_dirty=false`。
- GitHub Release：`https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.1`

## v1.0.2 当前状态

项目所有者已将 v1.0.2 从最小热修调整为正式优化版本。FR-001 至 FR-008 已实现，自动门禁、历史回归、打包、包体验证、真实主题事务和 WebView2 冷启动压力复验通过。

已完成的启动修复：

1. 首次权威同步遇到瞬时 `calculation_unavailable` 时保持加载状态并进行有限重试。
2. 真实配置错误继续显示失败，不被重试逻辑掩盖。
3. 增加重试语义日志、行为测试和新候选包门禁。

该启动修复的定向复验已通过。正式优化 Idea 阶段已经完成压力测试，以下内容已进入完整 PRD：

1. 阶段化“距离上班 / 休息 / 恢复工作 / 下班”内容合同。
2. 今日安排三列时间线和统一“休息”语义。
3. 迷你视图移除冗余横线并建立状态尺寸合同。
4. 今天、选中日期、业务日期和手动调整的复合状态体系。
5. 今日、日历、设置与月份切换入口的统一图标。
6. 调休工作日来源和跨夜 owner date 内容合同。
7. 阶段、日历、长内容与 100%/125%/150% DPI 行为门禁。
8. 浅色模式（默认）和深色模式双主题，覆盖全部应用窗口、配置迁移、跨窗口同步和启动防闪白。

项目所有者已确认推荐方案。局部组件拆分只作为降低本轮回归风险的约束；多窗口权威同步只做技术测量，不预设共享所有权实现。主题范围严格锁定为浅色默认和深色，不扩展系统跟随、自定义配色、定时切换或主题市场。

完整 PRD、需求追踪矩阵、高保真交互原型、开发计划和正式实现已完成。浅色/深色配置事务与跨窗口同步已从真实候选通过；WebView2 辅助窗口改为按需创建后，连续 5 次冷启动均存活并响应。

最终发布身份：

- 发布源码提交：`fe074439521bda77c57e2e96f8065dad329a8686`，`source_tree_dirty=false`。
- Zip：`LetsMakeMoney-v1.0.2-windows-x86_64.zip`，3,195,066 字节。
- Zip SHA256：`EEBA1788A8C1D6AEB071728B78C71C3634062B3F5BD6E61BDB46DD171C97FEA2`
- EXE SHA256：`4057E2F9F94B801A1A0A6C3D6F7B7AFE14DED2049478BF37AE6BBF17E33AD3BA`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- GitHub Release：`https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.2`

`V102-BUG-001` 至 `V102-BUG-007` 已关闭。最终候选将二级窗口显示命令改为异步执行并隔离阻塞式窗口创建，Workbench、Settings 和首次配置 Wizard 均从新解压包形成 `show_requested -> policy_applied -> visible -> focused -> shown` 完整日志链。Settings 的深色草稿预览、关闭确认、放弃回滚和重新打开无残留确认框完成真实 GUI 复验。

真实 Windows 125%/150% 系统缩放已完成补证，Mini、Workbench、日历、Settings、Wizard 及浅色/深色关键状态均通过清晰度检查。Windows 通知区真实鼠标左键隐藏与恢复也已由项目所有者补证通过。

配置完成后通过托盘入口重新打开 Wizard 的旧候选曾错误显示首次配置退出语义。修复后首次配置保存会立即更新前端状态，每次复用窗口显示都会重新读取权威配置状态，并阻止旧异步结果回写。项目所有者已从真实 Windows 通知区完成定向复验，关闭弹窗正确显示“放弃本次配置？”和“放弃配置”，应用继续运行。

发布提交经 PR #12 和必需 CI 检查合入 `main`，随后从干净提交重新构建。`v1.0.2` annotated tag 与 GitHub Stable Release 已发布；Release 只包含便携 Zip 和 `SHA256SUMS.txt`，远端下载包哈希与本地最终产物一致。v1.0.1 继续作为直接回滚基线。

## v1.0.3 当前状态

v1.0.3 的发布后 Review、Idea、性能技术 Spike、PRD、开发承接、业务实现和最终验收已经完成。发布源已经通过 PR #15 和必需 CI 合入 `main`；聚合自动验证、年度数据验证、权威同步、窗口生命周期、Rust 回归、打包及包体验证均通过。

已确认范围方向：

1. 在 2027 官方日历数据尚未发布时，按休息模式与手动日期调整继续计算，并明确标记为非官方估算。
2. 建立官方年度日历数据的导入、验证、打包和回滚合同，不预置虚假 2027 数据。
3. Mini 与 Workbench 仍各自维护可见窗口同步；隐藏窗口已经暂停本地 tick 与权威同步，恢复后执行一次即时同步并恢复唯一 timer。
4. 共享快照或单一同步所有权未过收益门槛，不进入本版。
5. 睡眠恢复和系统时间跳变为发布阻塞；时区变化需要真实人工证据；由于 timer 生命周期将变化，两小时稳定运行成为发布阻塞。

当前完成度为 `62/62`。官方/估算日历、日期调整、Settings、首次启动 Wizard、隐藏恢复、连续 10 次显隐、真实时区切换、真实系统时间前后跳变、通知区真实鼠标左键、两条真实 S3 睡眠跨边界路径和修正版候选 120 分钟稳定运行均已取得证据。原候选的稳定性采样发现隐藏 Workbench 后持续高 CPU，已定位为原生 WebView2 未挂起；修正版连续运行 `7201.27` 秒并通过 CPU、内存、日志与同步频率门禁，`V103-BUG-001` 已关闭。

最终发布包从 PR #15 合并提交 `87f6766a33fd6ff284f0fb3a42dc18c5a7292bf4` 重新构建，`source_tree_dirty=false`。Zip SHA256 为 `259CAE23D785FC7712CAC0EFD42991C8EE210C0BCEA1EB5C07FC171DFB993B28`，EXE SHA256 为 `41BB11FCBC95C3789AD283D0F85E67DB0E17D4BC769B133B317FDB1804607237`，WebView2Loader SHA256 为 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。最终发布包已重新通过全量自动验证、包体验证和 Computer Use 全新解压启动冒烟，当前无发布阻塞。

`v1.0.3` annotated tag 指向上述发布源提交，GitHub Stable Release 已发布：
`https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.3`。Release 仅包含便携 Zip 与 `SHA256SUMS.txt`；从 GitHub 重新下载的 Zip SHA256 与上述锁定值一致。

## v1.0.4 当前状态

v1.0.4 定位为发布可信度、测试可信度、开发可复现性和局部可维护性优化，并新增一个边界严格受控的隐私能力：Mini 左右贴边自动隐藏。除该能力外，不改变收入、日历、主题或其他窗口行为。

深度 Review、Idea 需求池、完整 PRD、需求追踪矩阵和高保真原型已完成。项目所有者已经确认推荐方案、四项治理决策、方案 A 的 Mini 隐私贴边能力及完整 PRD。PR #19 已将渐进式架构基线合入 `main`（`09f838d05c67efb5219437ec2208920e441f3f52`）。

V104-M0 已完成 10/10：冻结 v1.0.3 Git/Release 身份，完成 stable/fixed Rust 对照、work-area 与三档 DPI 几何夹具、v1.0.3 配置兼容门禁、正常/收起位置合同、脱敏机器证据和 v1.0.4 聚合验证入口。配置决策为继续使用 config v8 可选字段，不引入 `window-state.json`；只持久化展开态正常位置。

V104-M1 已完成 8/8：包专用双语离线 README、语义与负向验证、README/BUILD-INFO 哈希合同、原子打包与包体验证脚本、v1.0.3 Release 差异披露草案均已建立。远端正文未获独立授权，因此没有执行远端写操作。

V104-M2 已完成 8/8，V104-M3 已完成 8/8，V104-M4 已完成 8/8，V104-M5 已完成 6/6。统一工具解析、固定 Rust/Node/Python、只读环境诊断和 CI 合同已经通过；高风险组合行为增加了生命周期代际保护、配置事务和可信快照失败收敛的直接证据，完整聚合连续运行 10 次无随机失败。历史资产矩阵已确认 iOS 同名文件仍有唯一差异，Spike、v0.9 Figma/宠物、用户手册和历史 release 均建立了迁移前签核与回滚门禁，本版没有移动或删除历史资产。新鲜 clone 的无 spike 完整打包与完整通知区冒烟已经通过。

V104-M6 已完成实现和自动化门禁，并使用隔离干净提交候选在真实 Windows 100%/125%/150% DPI 下完成主要窗口清晰度、左右贴边、隐私收起、悬停/点击展开、移开收回、深色主题、减少动态效果、Settings 跨窗口关闭和重启持久化复验。复验期间发现并修复了一个跨窗口配置刷新缺口：收起 Mini 从 Settings 关闭自动隐藏时，原生窗口已展开但前端仍显示隐私标签，形成空白全尺寸窗口；修复后立即恢复完整内容且重启持久化正常。

v1.0.4 发布源提交为 `4d06dc73dbc5c27d7a97462d8262a553dd97d5b6`，最终产物从该干净提交重新构建，`source_tree_dirty=false`。Zip SHA256 为 `C4F28892831891A4266C4D9B12D432CD5C970BB3C9B36A6B8DB21FA2566DE50E`，EXE SHA256 为 `E0C9C603703FC2632619AFBC84F63B1B1D403273CD01D29AA0A308A95243E107`，WebView2Loader SHA256 为 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。`v1.0.4` annotated tag 指向该发布源，GitHub Stable Release 已发布且仅包含便携 Zip 与 `SHA256SUMS.txt`；从 GitHub 回下载的 Zip 哈希与锁定值一致。首次启动 Wizard、日历跨月、日期调整取消事务及通知区真实鼠标找回均已通过。真实多显示器、负坐标与显示器移除回落由项目所有者批准延期，明确记录为暂不验证且不阻塞本版。

GitHub Release：`https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.4`

## v1.0.5 发布结论

项目所有者在 v1.0.4 Stable 真实发布包中记录了日历正常态提示、今天标记、Mini 首次贴边收起、隐私竖条、关闭今日工作台后的非预期界面，以及窗口边界“框中框”观感等六项反馈。深度 Review、Idea、推荐方案 PRD、需求追踪矩阵与高保真交互原型已经完成并确认；V105-M0 至 M6 已完成。唯一 clean 候选 `V105-20260801T002456Z-277b121b-clean` 从源码提交 `277b121bbc68958382d06f4b29de3bd7685650f4` 构建并通过完整自动聚合，Zip SHA256 为 `BE2E1004427859AD30A4A4B23B12C00CF8A5EBD69F7A2442F345813F28CA521C`。

首个独立 ACC 在 Windows 11、100% DPI、单显示器环境发现 Mini 保持焦点时首次贴边不收起，复开 V105-BUG-001；该旧候选及其哈希继续作为历史失败证据保留。最小修复完成后，新 clean 候选 `V105-20260801T013259Z-6c9f010a-clean` 从提交 `6c9f010a164fb2b73c9068bd4fdcb6e863bd5100` 构建，Zip SHA256 为 `0FED6256E1E979D4BEC41E64C4290EF1917A6A6AB2B04D9A6EF47F1DD3C48826`。

修复后独立验收 `ACC-20260801-105930-retest` 已通过：左右首次贴边收起、悬停/移开、点击/键盘找回、深色 working 隐私竖条、关闭 Workbench 后保持收起，以及真实 Windows 通知区左键隐藏/恢复均有真实证据；M6 聚合、核心回归和用户环境恢复通过。V105-BUG-001 已关闭。最终发布对象从干净提交 `ffc431af3fbf7c3b54bca8aaff44946cc8d6aeaf` 构建，`v1.0.5` annotated tag 指向该提交，GitHub Stable Release 已发布并完成回下载核验。多显示器由项目所有者批准延期，Windows 10 因无设备或 VM 保持环境待补证：

发布后锁定身份：

- 发布源码提交：`ffc431af3fbf7c3b54bca8aaff44946cc8d6aeaf`。
- GitHub Release：`https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.5`。
- Zip：`LetsMakeMoney-v1.0.5-windows-x86_64.zip`，3,231,663 字节。
- Zip SHA256：`019B706E18E7D57D0B7E6DBFB6300762422B5723A11EB6ACCB601DA438215889`。
- EXE SHA256：`68FA8FC443B12A2BA8BD757F532EC6B90E09E3DA7E1027255267150C4DAEC37A`。
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- Release 仅包含便携 Zip 与 `SHA256SUMS.txt`；远端附件哈希已经核对。

- `doc/releases/v1.0.5/issue-pool.md`
- `doc/releases/v1.0.5/review.md`
- `doc/releases/v1.0.5/slimming-candidates.md`
- `doc/releases/v1.0.5/idea-pool.md`
- `doc/releases/v1.0.5/prd.md`
- `doc/releases/v1.0.5/traceability.md`
- `doc/releases/v1.0.5/dev_plan_v1.0.5.md`
- `doc/releases/v1.0.5/progress_v1.0.5.md`
- `doc/releases/v1.0.5/m0-baseline.md`
- `doc/releases/v1.0.5/fr004-reproduction-contract.md`
- `doc/releases/v1.0.5/evidence-matrix.md`
- `doc/releases/v1.0.5/artifact-and-evidence-contract.md`
- `doc/releases/v1.0.5/verification.md`
- `doc/releases/v1.0.5/window-surface-spike.md`
- `doc/logs/dev_log_v1.0.5.md`
- `doc/logs/v1.0.5-bugfix-log.md`
- `doc/prototypes/v1.0/index.html`

### v1.0.4 继承架构与范围基线

架构基线已完成：

1. `AppRuntime`、统一时间服务和配置、Dashboard、支持、窗口 Service。
2. `WindowFrame`、`MiniWindow`、全窗口拖动 Hook。
3. Rust 配置与收入链路的 Command/Service/Repository/Model 分层。
4. Runtime、配置领域、Desktop Service、生命周期、权威同步、Presentation 和结构测试。

这些内容在 v1.0.4 中只作为继承门禁，不重复开发，也不继续扩大模块拆分。

v1.0.4 已完成范围包括：

1. 便携包专用离线 README 与语义包验。
2. 两层验收证据耐久合同。
3. 既有架构基线上的高风险行为缺口补测与聚合门禁。
4. 新解压包桌面启动与窗口找回冒烟。
5. 剩余可复现开发环境、统一工具解析和正式脚本与 spike 目录解耦。
6. Runtime/Service 与首轮局部切片的继承验证；本版不重复实现或扩大拆分。
7. 历史资产所有权矩阵；本版不执行批量迁移或删除。
8. Mini 隐私贴边自动隐藏：仅左右工作区边缘，收起态不显示工资信息，悬停或托盘找回时展开；不扩展为通用停靠系统。

v1.0.3 GitHub Release 的 README 快照差异披露已进入需求范围，但属于远端文档写操作，实际执行前仍需独立授权。

## 待人工补证

当前无待人工补证的 v1.0.3 系统门禁。

真实 Windows 时区切换至 Tokyo 并恢复 `China Standard Time`、系统时间前拨/后拨及恢复、通知区真实鼠标左键隐藏与恢复、连续两小时桌面稳定运行，以及两条真实 S3 睡眠跨边界恢复均已通过。

## 范围边界

- 不恢复宠物或 PetManager。
- 主题仅包含浅色默认和深色；不加入第三种主题、自定义配色、系统跟随、定时切换或主题市场。
- 不加入账号、云同步、安装器或静默更新。
- 不猜测 2027 年节假日数据。
- 不修改 v1.0 和更早版本的 tag、Release 或历史验收结论。
- 无数据库影响；配置和离线数据继续保存在本地。

## 当前文档入口

- [v1.0.1 版本入口](releases/v1.0.1/README.md)
- [v1.0.1 PRD](releases/v1.0.1/prd.md)
- [v1.0.1 开发计划](releases/v1.0.1/dev_plan_v1.0.1.md)
- [v1.0.1 进度](releases/v1.0.1/progress_v1.0.1.md)
- [v1.0.1 验证](releases/v1.0.1/verification.md)
- [v1.0.1 人工补证](releases/v1.0.1/manual-verification.md)
- [v1.0.1 发布说明](releases/v1.0.1/release-notes.md)
- [v1.0.1 发布检查](releases/v1.0.1/release-checklist.md)
- [v1.0.1 计算说明](user-guide/v1.0.1/calculation-reference.md)
- [v1.0.2 正式优化 Review](releases/v1.0.2/review.md)
- [v1.0.2 问题池](releases/v1.0.2/issue-pool.md)
- [v1.0.2 Idea 需求池](releases/v1.0.2/idea-pool.md)
- [v1.0.2 完整 PRD](releases/v1.0.2/prd.md)
- [v1.0.2 需求追踪矩阵](releases/v1.0.2/traceability.md)
- [v1.0.2 开发计划](releases/v1.0.2/dev_plan_v1.0.2.md)
- [v1.0.2 进度](releases/v1.0.2/progress_v1.0.2.md)
- [v1.0.2 验证](releases/v1.0.2/verification.md)
- [v1.0.2 人工补证](releases/v1.0.2/manual-verification.md)
- [v1.0.2 发布说明](releases/v1.0.2/release-notes.md)
- [v1.0.2 发布检查](releases/v1.0.2/release-checklist.md)
- [v1.0.2 高保真原型说明](prototypes/v1.0/README.md)
- [v1.0.2 原型验证证据](prototypes/v1.0/evidence/v1.0.2/README.md)
- [v1.0.3 深度 Review](releases/v1.0.3/review.md)
- [v1.0.3 候选分流](releases/v1.0.3/candidate-routing.md)
- [v1.0.3 Idea 需求池](releases/v1.0.3/idea-pool.md)
- [v1.0.3 多窗口性能 Spike](releases/v1.0.3/performance-spike.md)
- [v1.0.3 完整 PRD](releases/v1.0.3/prd.md)
- [v1.0.3 需求追踪矩阵](releases/v1.0.3/traceability.md)
- [v1.0.3 开发计划](releases/v1.0.3/dev_plan_v1.0.3.md)
- [v1.0.3 进度](releases/v1.0.3/progress_v1.0.3.md)
- [v1.0.3 验证](releases/v1.0.3/verification.md)
- [v1.0.3 人工补证](releases/v1.0.3/manual-verification.md)
- [v1.0.3 发布检查](releases/v1.0.3/release-checklist.md)
- [v1.0.3 开发日志](logs/dev_log_v1.0.3.md)
- [v1.0.4 深度 Review](releases/v1.0.4/review.md)
- [v1.0.4 发布后差距](releases/v1.0.4/v1.0.3-post-release-gap.md)
- [v1.0.4 瘦身候选](releases/v1.0.4/slimming-candidates.md)
- [v1.0.4 Idea 需求池](releases/v1.0.4/idea-pool.md)
- [v1.0.4 完整 PRD](releases/v1.0.4/prd.md)
- [v1.0.4 需求追踪矩阵](releases/v1.0.4/traceability.md)
- [v1.0.4 开发计划](releases/v1.0.4/dev_plan_v1.0.4.md)
- [v1.0.4 历史资产矩阵](releases/v1.0.4/historical-assets.md)
- [v1.0.4 进度](releases/v1.0.4/progress_v1.0.4.md)
- [v1.0.4 验证](releases/v1.0.4/verification.md)
- [v1.0.4 人工验证](releases/v1.0.4/manual-verification.md)
- [v1.0.4 发布检查](releases/v1.0.4/release-checklist.md)
- [v1.0.4 发布说明](releases/v1.0.4/release-notes.md)
- [v1.0.4 开发日志](logs/dev_log_v1.0.4.md)
- [v1.0.5 深度 Review](releases/v1.0.5/review.md)
- [v1.0.5 候选问题池](releases/v1.0.5/issue-pool.md)
- [v1.0.5 瘦身候选](releases/v1.0.5/slimming-candidates.md)
- [v1.0.5 Idea 需求池](releases/v1.0.5/idea-pool.md)
- [v1.0.5 完整 PRD](releases/v1.0.5/prd.md)
- [v1.0.5 需求追踪矩阵](releases/v1.0.5/traceability.md)
- [v1.0.5 开发计划](releases/v1.0.5/dev_plan_v1.0.5.md)
- [v1.0.5 进度看板](releases/v1.0.5/progress_v1.0.5.md)
- [v1.0.5 开发日志](logs/dev_log_v1.0.5.md)
- [v1.0.6 维护版本 Review](releases/v1.0.6/review.md)
- [v1.0.6 问题池](releases/v1.0.6/issue-pool.md)
- [v1.0.6 进度](releases/v1.0.6/progress_v1.0.6.md)
- [v1.0.6 验证](releases/v1.0.6/verification.md)
- [v1.0.6 Bugfix 记录](logs/v1.0.6-bugfix-log.md)

## 下一步

确认是否授权 v1.0.6 发布收口。获授权后，应将本次状态文档形成最终本地提交，从该干净提交再次构建并锁定最终 Zip、EXE 与 DLL 哈希，随后才可推送、创建 annotated tag 与 GitHub Release。dirty 验收候选及其哈希始终不得用于 Release。
