# LetsMakeMoney 日志文档规范

本目录只保存**当前开发版本**仍在使用的开发、Bugfix 或 Spike 日志。已结束版本的完整日志迁入 [历史归档](../archive/README.md)，旧路径仅保留轻量兼容页。

## 文件职责

| 类型 | 建议文件名 | 记录内容 | 不应包含 |
|---|---|---|---|
| 开发日志 | `dev_log_vX.Y.md` | 技术决策、实现摘要、影响范围 | 进度 checklist |
| Bugfix 日志 | `vX.Y-bugfix-log.md` | 现象、复现、根因、修复摘要、验证结果 | 新需求讨论 |
| Spike 日志 | `vX.Y-spike-log.md` | 技术调研、方案比较、结论 | 已承诺的正式需求 |
| 进度 | `doc/releases/vX.Y/progress_vX.Y.md` | 状态、最小任务、阻塞、最近验证 | 排查流水账 |

## 当前日志

- [v0.7 开发日志](dev_log_v0.7.md)
- [v0.7 Bugfix 日志](v0.7-bugfix-log.md)

v0.8 当前处于工程治理准备阶段；若进入正式实施，应新建 `dev_log_v0.8.md`，不要继续写入 v0.7 日志。
