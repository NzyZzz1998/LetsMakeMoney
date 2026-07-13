# LetsMakeMoney 历史文档归档

本目录保存已结束版本、跨版本历史汇总、旧验证记录、旧日志和素材探索。归档内容只用于追溯，不得覆盖 [当前状态入口](../current.md) 或对应版本的 `doc/releases/vX.Y/` 事实。

## 分层规则

| 目录 | 内容 | 当前用途 |
|---|---|---|
| `legacy-core/` | v0.1-v0.4 跨版本 PRD、实施计划和进度原文 | 历史汇总，只读 |
| `v0.1/` 至 `v0.3/` | 旧版验证与素材探索 | 历史验收与研究 |
| `v0.4/` | 验证、动画/UI 规格、提示词、早期原型和日志 | v0.4 历史快照 |
| `v0.5/logs/` | v0.5 Bugfix 日志 | 历史排障 |
| `v0.6/logs/` | v0.6 开发与 Bugfix 日志 | 历史排障 |

旧路径保留了轻量兼容页，历史文档中的链接不会因为迁移立即失效。新文档不得继续引用兼容页，应直接引用归档正文或版本目录。

## 当前事实源

1. [当前状态](../current.md)
2. [v0.7 发布状态](../releases/v0.7/current.md)
3. [v0.7 验证](../releases/v0.7/verification.md)
4. [v0.8 工程治理 Review](../releases/v0.8/engineering-governance-review.md)

## 归档清单

### 跨版本历史

- [历史 PRD](legacy-core/LetsMakeMoneyPRD.md)
- [历史实施计划](legacy-core/implementation-plan.md)
- [历史进度](legacy-core/progress.md)

### v0.1-v0.3

- [v0.1 验证](v0.1/verification.md)
- [v0.2 验证](v0.2/verification.md)
- [v0.2 素材探索](v0.2/asset-spike.md)
- [v0.2 素材提示词](v0.2/asset-prompt-pack.md)
- [v0.2 临时 PC 工作区](v0.2/temp-pc-work/README.md)
- [v0.3 验证](v0.3/verification.md)

### v0.4-v0.6

- [v0.4 验证](v0.4/verification.md)
- [v0.4 动画规格](v0.4/animation-spec.md)
- [v0.4 动画素材日志](v0.4/animation-assets-log.md)
- [v0.4 UI 规格](v0.4/ui-polish-spec.md)
- [v0.4 早期暖色原型](v0.4/ui-prototype-warm-widget.html)
- [v0.4 日志](v0.4/logs/dev-log.md)
- [v0.5 Bugfix 日志](v0.5/logs/bugfix-log.md)
- [v0.6 开发日志](v0.6/logs/dev-log.md)
- [v0.6 Bugfix 日志](v0.6/logs/bugfix-log.md)

## 尚未处理

- `doc/releases/v0.4/` 至 `doc/releases/v0.7/` 已经按版本分层，继续留在原位。
- Day4 AI 产品方案 DOCX 属于演示交付物，等待项目所有者决定迁到仓库外 `deliverables/`，还是归入 `archive/demos/`。
- 脚本分层属于 C3，不在本次文档迁移中移动。
