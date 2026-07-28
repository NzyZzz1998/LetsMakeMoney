# LetsMakeMoney v1.0.2

## 版本定位

v1.0.2 是 v1.0.1 之后的正式优化版本。在不改变既有收入、日历、日期调整和跨夜班次口径的前提下，修复启动信任问题，并统一优化高频桌面界面、状态文案和日历表达。

## 已完成基线

- 修复有效配置启动时短暂误报“暂时无法计算”的问题。
- 瞬时计算不可用只触发有限重试，界面继续显示加载状态。
- 真实配置错误仍显示可读失败。
- 增加启动重试日志、行为测试、打包与包验证门禁。

## 方案与 PRD 收敛结果

- 推荐进入 PRD：阶段化倒计时、今日安排三列时间线、迷你视图尺寸合同、日历复合状态、统一图标、调休与跨夜内容合同、行为与 DPI 门禁，以及浅色默认/深色双主题。
- 仅做必要治理：阶段呈现选择器、日历状态映射和本轮直接修改的窗口组件可局部拆分，禁止整体重构。
- 继续验证：多窗口权威同步先测量请求、日志和性能，不预设共享所有权实现。
- 已完成基线：`V102-BUG-001` 不重复进入开发范围。

完整证据、评分、矩阵和三档方案见 [v1.0.2 Idea 需求池](idea-pool.md)。推荐方案已经落实为：

- [完整 PRD](prd.md)
- [需求追踪矩阵](traceability.md)
- [v1.0.2 高保真交互原型](../../prototypes/v1.0/index.html)
- [原型说明](../../prototypes/v1.0/README.md)
- [原型浏览器验证证据](../../prototypes/v1.0/evidence/v1.0.2/README.md)

## 当前状态

完整 PRD、开发计划和 FR-001 至 FR-008 实现已经完成。聚合验证、历史回归、打包、包体验证、真实主题事务、二级窗口显示、WebView2 冷启动压力、真实 Windows 125%/150% DPI、通知区左键和配置后 Wizard 托盘复用均通过。`V102-BUG-007` 已关闭，最终 Acceptance 通过，v1.0.2 Stable 已发布。

最终发布身份：

- 发布源码提交：`fe074439521bda77c57e2e96f8065dad329a8686`
- Zip SHA256：`EEBA1788A8C1D6AEB071728B78C71C3634062B3F5BD6E61BDB46DD171C97FEA2`
- EXE SHA256：`4057E2F9F94B801A1A0A6C3D6F7B7AFE14DED2049478BF37AE6BBF17E33AD3BA`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- GitHub Release：`https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.2`

上述哈希标识从干净发布提交构建并上传 GitHub Release 的最终产物。`V102-BUG-004` 至 `V102-BUG-007` 已关闭；Workbench、Settings 和 Wizard 均完成真实窗口显示链。配置后从托盘重新打开 Wizard 时，关闭弹窗正确使用“放弃本次配置”语义。远端下载包已重新计算 SHA256，并与本地最终产物一致。

## 证据入口

- [v1.0.1 发布后观察](post-release-observation.md)
- [验证记录](verification.md)
- [人工补证](manual-verification.md)
- [进度](progress_v1.0.2.md)
- [发布检查](release-checklist.md)
- [发布说明](release-notes.md)
- [问题池](issue-pool.md)
- [正式优化 Review](review.md)
- [Idea 需求池](idea-pool.md)
- [完整 PRD](prd.md)
- [需求追踪矩阵](traceability.md)
- [高保真原型说明](../../prototypes/v1.0/README.md)
- [原型验证证据](../../prototypes/v1.0/evidence/v1.0.2/README.md)
- [Bugfix Log](../../logs/v1.0.2-bugfix-log.md)

## 范围边界

- 不恢复宠物。
- 主题仅包含浅色默认与深色；不加入第三种主题、自定义配色、系统跟随、定时切换或主题市场。
- 不加入账号、云同步、安装器或静默更新。
- 不改变 v1.0.1 tag、Release、发布包和历史验收结论。
- 不以当前启动修复候选替代正式优化版验收。
- 无数据库影响。
