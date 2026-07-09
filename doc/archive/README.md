# LetsMakeMoney 历史文档归档索引

本目录当前只作为归档说明和迁移计划入口。为了避免破坏已有引用，本轮没有移动历史文档，也没有删除任何内容。

## 当前原则

- v0.4 Beta 是当前版本。
- v0.1、v0.2、v0.3 文档只作为历史参考。
- v0.2 素材 Spike 和提示词包属于历史素材探索。
- `doc/temp-pc-work/` 属于临时 PC 工作区资料。
- 后续如果真正移动文件，必须同步更新：
  - [doc/current.md](../current.md)
  - [doc/releases/v0.4/README.md](../releases/v0.4/README.md)
  - 相关 PRD / implementation-plan / progress / verification 中的链接
  - 根 [README.md](../../README.md) 中的文档入口

## 当前历史参考文件

| 文件 / 目录 | 类型 | 当前用途 | 建议归档位置 |
|---|---|---|---|
| `doc/verification/v0.1.md` | v0.1 验证 | 历史验收记录 | `doc/archive/v0.1/verification.md` |
| `doc/verification/v0.2.md` | v0.2 验证 | 历史验收记录 | `doc/archive/v0.2/verification.md` |
| `doc/verification/v0.3.md` | v0.3 验证 | 历史验收记录 | `doc/archive/v0.3/verification.md` |
| `doc/v0.2-asset-spike.md` | Spike | 历史素材探索 | `doc/archive/spikes/v0.2-asset-spike.md` |
| `doc/v0.2-asset-prompt-pack.md` | Spike | 历史素材提示词 | `doc/archive/spikes/v0.2-asset-prompt-pack.md` |
| `doc/temp-pc-work/` | 临时工作区 | PC 临时素材 / 提示词 | `doc/archive/spikes/temp-pc-work/` |
| `doc/ui-prototype-warm-widget.html` | 原型历史 | 早期暖色方向参考 | `doc/archive/prototypes/ui-prototype-warm-widget.html` |

## 跨版本大文档状态

以下文件仍保留原位，作为原始跨版本资料。v0.4 章节已经复制到 `doc/releases/v0.4/` 下，日常接手优先读取拆分副本：

- `doc/LetsMakeMoneyPRD.md`
- `doc/implementation-plan.md`
- `doc/progress.md`

当前已建立的 v0.4 拆分副本：

- `doc/releases/v0.4/prd.md`
- `doc/releases/v0.4/implementation-plan.md`
- `doc/releases/v0.4/progress.md`
- `doc/releases/v0.4/verification.md`
- `doc/releases/v0.4/release-checklist.md`

建议后续继续拆分方式：

```text
doc/
  releases/
    v0.1/
      prd.md
      implementation-plan.md
      progress.md
      verification.md
    v0.2/
      prd.md
      implementation-plan.md
      progress.md
      verification.md
    v0.3/
      prd.md
      implementation-plan.md
      progress.md
      verification.md
    v0.4/
      README.md
      status.md
      prd.md
      implementation-plan.md
      progress.md
      verification.md
      release-checklist.md
      ui-polish.md
      animation.md
```

拆分前不要直接删除原大文档。更安全的做法是：

1. 先复制对应版本章节到新文件。
2. 在原大文档顶部加入“此文档已拆分，当前入口见 doc/current.md”的提示。
3. 更新 `doc/current.md` 和 `doc/releases/v0.4/README.md`。
4. 全文搜索旧路径引用并逐一替换。
5. 确认所有链接可用后，再决定是否保留或归档原大文档。

## 当前不作为 v0.4 事实源的内容

- v0.1-v0.3 的验证结论。
- v0.1-v0.3 的 PRD / Plan / Progress 历史章节。
- v0.2 的素材 Spike 与提示词。
- 临时 PC 工作区内容。
- 早期暖色原型文件。

如果这些内容与 [doc/current.md](../current.md)、[doc/releases/v0.4/status.md](../releases/v0.4/status.md) 或 [doc/releases/v0.4/verification.md](../releases/v0.4/verification.md) 冲突，以当前状态入口和 v0.4 验证文档为准。
