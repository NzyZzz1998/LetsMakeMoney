# LetsMakeMoney 当前状态

> 本文件是项目当前状态的唯一内部入口。历史版本结论以各版本目录为准。

## 当前版本

| 项目 | 状态 |
| --- | --- |
| 当前公开版本 | Windows v1.0.1 Stable |
| 当前公开 tag | `v1.0.1` |
| 当前开发版本 | Windows v1.0.2 正式优化版 |
| v1.0.1 阶段 | 已发布 |
| v1.0.2 阶段 | 最终 Acceptance 通过，可进入发布收口 |
| 技术栈 | Rust + Tauri + TypeScript/React |
| 产品形态 | 无宠物、本地优先的 Windows 收入进度工具 |
| 发布阻塞 | 无 |
| 最后更新 | 2026-07-28 |

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

最终验收候选身份：

- Zip SHA256：`BA7330C0C14745CE1DB355C3E28CE75255E7B64250212CE25D8B36C054653DB2`
- EXE SHA256：`BE54F049F2134536564EC8222F3C5446F54C3653223206A97BDE2A3B575CB6F7`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`

`V102-BUG-001` 至 `V102-BUG-007` 已关闭。最终候选将二级窗口显示命令改为异步执行并隔离阻塞式窗口创建，Workbench、Settings 和首次配置 Wizard 均从新解压包形成 `show_requested -> policy_applied -> visible -> focused -> shown` 完整日志链。Settings 的深色草稿预览、关闭确认、放弃回滚和重新打开无残留确认框完成真实 GUI 复验。

真实 Windows 125%/150% 系统缩放已完成补证，Mini、Workbench、日历、Settings、Wizard 及浅色/深色关键状态均通过清晰度检查。Windows 通知区真实鼠标左键隐藏与恢复也已由项目所有者补证通过。

配置完成后通过托盘入口重新打开 Wizard 的旧候选曾错误显示首次配置退出语义。修复后首次配置保存会立即更新前端状态，每次复用窗口显示都会重新读取权威配置状态，并阻止旧异步结果回写。项目所有者已从真实 Windows 通知区完成定向复验，关闭弹窗正确显示“放弃本次配置？”和“放弃配置”，应用继续运行。v1.0.1 仍是当前公开稳定版；v1.0.2 已可进入发布收口。

## 待人工补证

以下项目没有写为通过：

- 真实 Windows 睡眠与恢复后的权威同步
- 手动修改系统时间或时区后的即时校正
- 连续两小时桌面稳定运行
以上项目未写为通过，继续作为非阻塞环境补证项。配置后 Wizard 托盘入口复用已经项目所有者人工补证通过，不再列入待人工补证。

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
- [v1.0.2 发布检查](releases/v1.0.2/release-checklist.md)
- [v1.0.2 高保真原型说明](prototypes/v1.0/README.md)
- [v1.0.2 原型验证证据](prototypes/v1.0/evidence/v1.0.2/README.md)

## 下一步

进入发布收口：创建签核后的发布提交，从干净提交重新构建并验证最终候选，更新最终哈希；经项目所有者确认后再执行 push、`v1.0.2` tag 和 GitHub Release。当前尚未执行 commit、push、tag 或 Release。
