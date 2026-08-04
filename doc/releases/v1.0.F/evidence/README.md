# v1.0.F 脱敏证据索引

本目录保存可公开、可复核的脱敏摘要；完整截图、录屏、用户配置、注册表导出和原始日志可保存在外部证据库，但不得依赖临时目录作为唯一副本。

每份摘要至少包含：

- `schema_version`
- `milestone`
- `source_head`
- 候选或测试对象 SHA256
- Windows 版本、架构、显示器数量和 DPI
- 执行步骤与真实结论
- 未执行、失败和环境恢复状态
- 外部原始证据逻辑 ID；外置时明确标记 `external`

当前开发阶段已有自动门禁、代码和冷启动测量证据。真实 GUI、三档 DPI 和最终候选身份尚未完成，不得提前写为通过。

计划入口：

| 里程碑 | 摘要文件 | 当前状态 |
| --- | --- | --- |
| M1-M5 | `m7-automation-summary.json` | current gate 已通过；真实 GUI 待验收 |
| M6 | `m6-cold-start-performance-baseline.json`、`m6-cold-start-performance.json` | 冷暖启动测量完成，定向优化保留 |
| M7 自动化 | `m7-automation-summary.json` | 聚合门禁通过；记录为 dirty 开发树 |
| M7 候选 | `m7-candidate.json` | 待项目所有者批准干净提交后生成 |
