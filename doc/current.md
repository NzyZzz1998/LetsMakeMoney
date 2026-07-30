# LetsMakeMoney 当前状态

> 本文件是项目当前状态的唯一内部入口。历史版本结论以各版本目录为准。

## 当前版本

| 项目 | 状态 |
| --- | --- |
| 当前公开版本 | Windows v1.0.2 Stable |
| 当前公开 tag | `v1.0.2` |
| 当前开发版本 | Windows v1.0.3 最终验收通过，待发布收口 |
| v1.0.1 阶段 | 已发布 |
| v1.0.2 阶段 | 已发布 / 发布后观察 |
| v1.0.3 阶段 | 最终验收通过，可进入发布收口 |
| 技术栈 | Rust + Tauri + TypeScript/React |
| 产品形态 | 无宠物、本地优先的 Windows 收入进度工具 |
| 发布阻塞 | 无 |
| 最后更新 | 2026-07-30 |

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

v1.0.3 的发布后 Review、Idea、性能技术 Spike、PRD、开发承接、业务实现和最终验收已经完成。聚合自动验证、年度数据验证、权威同步、窗口生命周期、Rust 回归、打包及包体验证通过；当前可进入发布收口。

已确认范围方向：

1. 在 2027 官方日历数据尚未发布时，按休息模式与手动日期调整继续计算，并明确标记为非官方估算。
2. 建立官方年度日历数据的导入、验证、打包和回滚合同，不预置虚假 2027 数据。
3. Mini 与 Workbench 仍各自维护可见窗口同步；隐藏窗口已经暂停本地 tick 与权威同步，恢复后执行一次即时同步并恢复唯一 timer。
4. 共享快照或单一同步所有权未过收益门槛，不进入本版。
5. 睡眠恢复和系统时间跳变为发布阻塞；时区变化需要真实人工证据；由于 timer 生命周期将变化，两小时稳定运行成为发布阻塞。

当前完成度为 `62/62`。官方/估算日历、日期调整、Settings、首次启动 Wizard、隐藏恢复、连续 10 次显隐、真实时区切换、真实系统时间前后跳变、通知区真实鼠标左键、两条真实 S3 睡眠跨边界路径和修正版候选 120 分钟稳定运行均已取得证据。原候选的稳定性采样发现隐藏 Workbench 后持续高 CPU，已定位为原生 WebView2 未挂起；修正版连续运行 `7201.27` 秒并通过 CPU、内存、日志与同步频率门禁，`V103-BUG-001` 已关闭。

最终候选从干净提交 `ebcd58844bc905874c2ddc9b267848ee1aec5b7b` 重新构建，`source_tree_dirty=false`。Zip SHA256 为 `E4FF7771B3ACD5658DD84EE2CC6E14B1DACA685EBD0D2D180FC318B7BB1F2183`，EXE SHA256 为 `7DD45D6B35CE82A6241D359EFB2FE88A9A62B3ECD20703B19BAE82CEE98F5BBA`，WebView2Loader SHA256 为 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。最终候选已重新通过全量自动验证、包体验证和新解压启动冒烟，当前无发布阻塞。

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

## 下一步

等待项目所有者确认发布动作。发布收口应推送 `main`、创建 `v1.0.3` annotated tag，并只上传最终便携 Zip 与 `SHA256SUMS.txt`；本轮尚未执行这些远端动作。
