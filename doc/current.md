# LetsMakeMoney 当前状态

> 本文件是项目当前状态的唯一内部入口。历史版本结论以各版本目录为准。

## 当前版本

| 项目 | 状态 |
| --- | --- |
| 当前公开版本 | Windows v1.0 Stable |
| 当前公开 tag | `v1.0` |
| 当前开发版本 | Windows v1.0.1 Stable 候选 |
| v1.0.1 阶段 | 实现与独立验收完成，可进入发布收口 |
| 技术栈 | Rust + Tauri + TypeScript/React |
| 产品形态 | 无宠物、本地优先的 Windows 收入进度工具 |
| 发布阻塞 | 无 |
| 最后更新 | 2026-07-27 |

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

自动门禁、包验证和新解压候选 GUI 验收均已通过，当前无发布阻塞。尚未执行提交、推送、tag 或 GitHub Release。

当前已验收收口候选：

- Zip SHA256：`CBF19024A8337E36E58F2EC23B0AE10EA1013616ED278CB2FEC590AA717F280D`
- EXE SHA256：`5BC7E6D04DDD65E4CE745D368CCF2369E66ED501D9BC683EC690EB16DA807C38`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- 该候选来自尚未提交的 v1.0.1 工作树；创建正式发布提交后必须重新构建并重新锁定发布哈希。

## 待人工补证

以下项目没有写为通过：

- 真实 Windows 睡眠与恢复后的权威同步
- 手动修改系统时间或时区后的即时校正
- 连续两小时桌面稳定运行
- Computer Use 无法稳定覆盖时的通知区真实鼠标左键

这些项目当前不阻塞候选进入发布收口，但发布后应继续观察。

## 范围边界

- 不恢复宠物或 PetManager。
- 不加入账号、云同步、主题、安装器或静默更新。
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

## 下一步

项目所有者确认后进入发布收口：创建发布提交、推送、创建 `v1.0.1` tag 和 GitHub Release。未经确认，不执行任何远端写操作。
