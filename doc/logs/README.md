# LetsMakeMoney 日志文档规范

本目录用于承接开发过程中的过程性记录，避免 `progress` 文档再次变成流水账。

## 文档边界

| 类型 | 建议文件 | 内容 | 不应包含 |
|---|---|---|---|
| dev-log | `vX.Y-dev-log.md` | 重要开发决策、实现摘要、影响范围 | checklist 状态看板 |
| bugfix-log | `vX.Y-bugfix-log.md` | bug 现象、复现、根因、修复摘要、验证结果 | 新需求讨论 |
| spike-log | `vX.Y-spike-log.md` | 技术调研、素材实验、方案比较、结论 | 已承诺交付的正式需求 |
| verification | `doc/releases/vX.Y/verification.md` | 人工验证步骤、结果、备注 | 开发过程长文 |
| progress | `doc/releases/vX.Y/progress_vX.Y.md` | 模块状态、最小任务 checklist、验收状态 | 调试流水、失败尝试、截图吐槽 |

## v0.5 规则

- `doc/releases/v0.5/progress_v0.5.md` 只记录状态和 checklist。
- 共享控件实现中的技术细节如需记录，写入 `v0.5-dev-log.md`。
- 托盘、点击穿透、纯桌宠路径中的 bugfix 过程如需记录，写入 `v0.5-bugfix-log.md`。
- UI 或素材方向探索如需记录，写入 `v0.5-spike-log.md`。

## 历史迁出建议

v0.4 及更早的 `doc/progress.md` 中，如果出现以下内容，后续可迁出到本目录：

- 多轮 bugfix 过程。
- 具体命令输出和排错记录。
- 素材生成实验。
- UI 截图评价。
- 临时方案与被放弃方案。

迁出历史内容时不要删除原始记录；优先复制到日志文档，并在原位置补充链接或迁移说明。
