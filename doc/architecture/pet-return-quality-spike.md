入口判断：/prd

# pet-return Quality Spike 执行合同

> Spike：B / Quality
> 目标：证明 Classic 动作可以稳定达到身份、节奏、循环、状态边界和长期观感门禁
> 当前状态：S2.2 五动作、完整动作目录 Batch A 及 Batch B 两个工作期间陪伴动作已通过；`working_pounce` 因语义不符退役且无需补位，18 动作完整目录仍未 ready
> 结果性质：黄金样片与生产路线证据，不是正式产品素材发布
> 最后更新：2026-08-12

## 1. 需要证明的核心结论

历史问题不是“动作数量不够”，而是身份不稳、动作粗糙、道具主导、状态语义重复、循环机械和交互收势不自然。本 Spike 只回答：

1. Classic 是否能在不依赖电脑、键盘和金币的前提下，稳定表现低干扰玩耍、观察、休息、睡眠与状态回应。
2. 五个黄金动作能否共享同一身份、尺度、脚底线和状态边界。
3. `run_prepare -> run_loop -> run_stop` 是否是一条完整运动链，而不是三个互不相关的 GIF。
4. 自动 QA 与真实时长人工审查能否共同阻止粗糙素材进入净化包。
5. 该路线是否具备扩展 rest、sleep 和多多的可重复性。

## 2. 黄金样片范围

第一阶段只生产和验证：

| 动作 | 必须证明的语义 | 候选帧数/时长 | 输出 |
| --- | --- | --- | --- |
| `working_play_loop_a` | 持续专注玩耍，循环自然 | 16-24 / 2.4-4.0s | 无接缝基础 loop |
| `working_ack` | 工作中被单击后的短反馈 | 8-12 / 0.8-1.2s | 明显但不过度庆祝 |
| `run_prepare` | 长按成立后的蓄力与起跑准备 | 8-12 / 0.6-0.9s | 能连接 run_loop |
| `run_loop` | 拖动期间持续跑动 | 8-12 / 0.55-0.9s 每轮 | 安全镜像优先 |
| `run_stop` | 释放后的减速、停稳与收势 | 8-12 / 0.8-1.2s | 回到最新基础状态 |

候选值只服务样片探索；通过人工审查后才回写为冻结 Profile。第一片未通过时，不扩展 `awake_rest`、`sleeping`、业务事件或多多新动作。

## 3. 明确禁止

- 不把电脑、键盘、金币或收益数字作为动作成立的必要道具。
- 不使用同一个庆祝动作替代 ack、休息、复工和上班语义。
- 不从扁平合成图按颜色反推角色层、道具层或头部蒙版。
- 不用单个合成图的边界决定角色缩放。
- 不把 AI 视频直接切帧、去背景后作为产品动作。
- 不在自动测试通过后自动写 `ready: true`。
- 不修改 fixed-pro 历史包及 Classic S4.3、多多 S5.5 既有证据。
- 不把失败尝试、Prompt 或绝对路径复制到 LMM。

## 4. 输入身份与基线

执行前必须锁定：

| 输入 | 证据 |
| --- | --- |
| Classic 身份板 | 正面、侧面、坐姿、趴姿、耳尾和五官关键点 |
| 当前 fixed-pro 包 | 四文件路径、大小、SHA256 |
| Classic S4.3 | manifest、图集、真实时长 GIF、Contact Sheet、motion review、SHA256 |
| 多多 S5.5 | 仅作通用合同对照，不参与 Classic 身份混合 |
| 动作 Profile | 五动作 source/target、候选帧数、时长、safe exit、方向与 fallback |
| 生产环境 | PetManager HEAD、Skill 版本、Python/依赖、生成服务与人工工具版本 |

身份板必须先由项目所有者确认；未经确认的单张参考图不能成为身份锁定证据。

## 5. G0-G8 生产与 QA

### G0 身份锁定

- 输入：Classic 已批准参考、S4.3 角色基线。
- 处理：建立不可变 identity board，标记眼距、耳型、额纹、脸部白区、胸口白区、尾巴条纹、头身比例和脚底线。
- 输出：`identity-board.png`、`identity-landmarks.json`、哈希清单。
- 失败：任一关键身份特征无法从参考确认，停止动作生成。

### G1 动作规格

为五个动作分别输出：

- 一句话语义和禁止语义。
- source state / target state。
- 关键姿态 3-6 个。
- 运动弧、重心、脚接触与尾巴路径。
- 候选帧数和逐帧节奏。
- safe exit frame 候选。
- 是否可安全镜像。
- 前一动作末帧与后一动作首帧边界。

输出：`action-profile.json`、`compiled-profile.json`；必须人工批准后进入 G2。

### G2 分层输入

每个关键姿态必须保留：

- `character_rgba`：完整角色，不因道具遮挡缺失身体。
- `prop_rgba`：可选道具，黄金五动作默认不依赖道具。
- `head_mask`：用于身份、尺度和连续性测量。
- `contact_points`：脚底/身体接触点。
- `motion_path`：重心、头部和尾巴运动弧。

缺层、哈希不符、尺寸不一致或颜色反推层一律拒绝。

### G3 关键姿态

- 先批准姿态，再生成中间帧。
- `working_play_loop_a` 必须明确循环起点、动作峰值和回到起点的过渡。
- `run_prepare` 末姿态必须可接 `run_loop` 首姿态。
- `run_loop` 末姿态必须可继续自身首姿态，也可在 safe exit 接 `run_stop`。
- `run_stop` 末姿态必须能平滑回 working 基础姿态，未来也应允许回 awake_rest/sleeping。

输出：关键姿态板、边界对照图和人工批准记录。

### G4 补间与稳帧

优先路线：分层角色 + 关键姿态 + 可控补间/绑定。AI 仅辅助运动弧与候选关键姿态探索。

处理要求：

- 稳定头身比例、眼睛、耳朵、尾巴和四肢数量。
- 脚接触帧不漂浮、不穿地。
- 运动快慢由逐帧 duration 控制，不复制固定 FPS。
- 不为平滑而插入无意义静止帧。
- 保留每次人工重建位置与原因。

### G5 标准化

- 统一 RGBA、色彩空间、逻辑画布、anchor、foot baseline、visual offset。
- 只对背景做去色，保护黑色描边、白色毛发和低饱和暗部。
- 对所有帧生成确定性 alpha 与 head mask 指标。
- 禁止相邻图集槽位污染、空帧和未声明裁切。

### G6 图集、manifest 与 hit mask

- 生成 schema vNext unpublished 候选包。
- 写逐帧 `durationMs`、safe exit、max runtime、fallback、direction 和 hit mask。
- 包含许可与脱敏 provenance；不含生产源和失败尝试。
- 输出 package index、manifest 和文件哈希。

### G7 素材 QA

- 自动：几何、透明、哈希、schema、路径、fallback、循环像素边界。
- 人工：真实时长 GIF、Contact Sheet、状态边界、方向镜像、身份与节奏评分。
- 输出状态只能是 `review_pending`、`approved` 或 `rejected`；只有人工批准后才可 `PetManager ready`。

### G8 LMM 产品 QA

输入是 G7 的 unpublished 净化包和 Runtime Spike 沙盒。验证：

- 五个动作真实播放。
- 30 分钟初步编排。
- 500ms 拖拽链、方向和收势。
- 三 DPI 动态命中。
- 2 小时稳定与坏包回退。

G8 失败不回写 PetManager 包为“素材必然失败”，必须区分素材、编排、输入和运行时责任。

## 6. 三轮上限

每个生产路线最多三轮，轮次不是无限重抽：

| 轮次 | 目的 | 允许调整 | 必须停止的信号 |
| --- | --- | --- | --- |
| R1 | 验证身份、关键姿态与动作语义 | Prompt/草图、关键姿态、运动弧 | 身份明显漂移、动作语义错误 |
| R2 | 修正尺度、节奏、层与边界 | 分层重建、补间、duration、safe exit | 仍需从扁平图反推缺失身体 |
| R3 | 最终稳帧、循环与产品连接 | 局部人工重建、边界、透明和图集 | 仍有身份/尺度/语义/循环关键缺陷 |

三轮后仍失败：停止当前生成路线，转为绑定或手工关键帧；若成本或质量仍不可控，则停止桌宠回归，不以更多候选掩盖失败。

## 7. 动作级质量门禁

| 维度 | 自动门槛 | 人工门槛 |
| --- | --- | --- |
| 脚底线 | 漂移 <=2px | 无漂浮、沉地或突然跳动 |
| 头部尺度 | 基础 loop 相邻 <=2%；oneshot <=4% | 肉眼不缩放抽动 |
| 整体尺度 | 相邻 <=5% | 状态边界无角色忽大忽小 |
| 身份 | 关键点与身份板可比 | 眼耳尾、纹路和脸型一致 |
| 结构 | 空帧 0、槽位污染 0、多肢/缺肢 0 | 四肢和尾巴运动符合姿态 |
| 透明 | 色键残留 0、alpha 合法 | 无明显白边、黑边和蓝绿边 |
| 节奏 | duration 完整、总时长在候选范围 | 有预备、主动作、缓冲和恢复 |
| 循环 | 首尾几何差异可解释 | 连续三轮无明显跳帧 |
| 边界 | source/target 对照指标通过 | 动作前后姿态自然衔接 |

任何自动指标通过都不能覆盖人工“身份不对”“动作僵硬”或“语义不成立”。

## 8. 人工评分表

每个动作按 1-5 分评分：

| 项目 | 通过线 | 说明 |
| --- | ---: | --- |
| 身份一致性 | >=4 | 一眼仍是同一只 Classic |
| 动作语义 | >=4 | 不看动作名也能理解大致意图 |
| 节奏与重量感 | >=4 | 有重心、惯性、预备和收势 |
| 轮廓与结构 | >=4 | 无多肢、缺耳、缺尾和形变 |
| 循环/边界 | >=4 | loop 和动作连接不突跳 |
| 长期干扰度 | >=4 | 频率与幅度不抢占用户注意力 |

任一 P0 动作任一项低于 4，不能写 `approved`。评分必须附一句可执行原因，不能只给总分。

## 9. 五动作专项验收

### working_play_loop_a

- 连续播放至少 10 个循环。
- 首尾无跳动、停顿或突然眨眼重置。
- 动作幅度足以看出在玩耍/专注，但不持续大幅移动。
- 不依赖桌面电脑、键盘或金币解释工作。

### working_ack

- 与 base loop 肉眼可区分。
- 不表现统一庆祝，不跳离工作语境。
- 单击 10 次仍不会显得同一个大动作反复轰炸。

### run_prepare / run_loop / run_stop

- 作为一条链连续审查，不只看三个独立 GIF。
- prepare 有明确蓄力，loop 有稳定步态，stop 有减速与停稳。
- 左右方向优先镜像同一套素材；镜像后身份纹路和动作语义不矛盾。
- release 时不瞬间切静态帧；run_stop 结束后脚底线和角色尺度回到基础状态。

## 10. 30 分钟初步编排审查

### 样本

- working 10 分钟：base loop、working_ack 和五动作中的可用内容。
- awake_rest 10 分钟：本 Spike 尚无新 rest 动作时，只用批准的安全基线，不据此宣称 rest 质量通过。
- sleeping 10 分钟：同上，只验证状态机不乱播 working/drag 动作。

### 记录

- 每个动作触发次数、开始/完成/中断、冷却命中、连续重复和 fallback。
- 同一 ambient 不得连续。
- ack 只由人工点击触发。
- 业务事件不在黄金五动作质量结论中冒充完成。
- 项目所有者记录“自然、机械、吵、突兀、难以理解”及时间点。

### 结论边界

五动作通过只能证明首轮生产路线和 working/drag 质量方向成立；不能证明完整 rest、sleep、业务事件或多多已通过。

## 11. ComfyUI + MiniMax 有界分支

### 11.1 当前已核对事实（2026-08-10）

- 本机秋叶 ComfyUI 中已发现的内置 MiniMax/Hailuo 节点标识为 `MiniMax-Hailuo-02`，通过 Comfy.org/API 调用，不是本地离线模型。
- MiniMax 官方文档当前主要提供 H3 视频生成，公开说明包含 768P/2K、4-15 秒能力；这不等于本机已经具备 H3 节点。
- 官方按量价格页面当前列出 H3 768P `$0.08/秒`、2K `$0.13/秒`；执行前必须重新联网核对，本文价格不构成预算承诺。

参考入口：

- [MiniMax Video Generation Guide](https://platform.minimax.io/docs/guides/video-generation)
- [MiniMax Pay-as-you-go Pricing](https://platform.minimax.io/docs/guides/pricing-paygo)
- [ComfyUI MiniMax Hailuo built-in node](https://docs.comfy.org/built-in-nodes/MinimaxHailuoVideoNode)
- [MiniMax Terms of Service](https://platform.minimax.io/protocol/terms-of-service)

### 11.2 执行前门禁

必须重新核对并保存脱敏摘要：

1. 本机节点清单与真实模型 ID。
2. 是否需要 Comfy.org Credits 或 MiniMax API Key。
3. 当前价格、单次最长时长、分辨率和失败计费规则。
4. 输入角色图、输出视频、商业使用与再分发许可。
5. API Key 的凭据存储与日志脱敏。
6. `PET-DEC-004` provenance 披露；任何新的 AI 动作探索还必须另行建立动作选择决定。

任一项不清楚则本分支 `blocked`，不阻塞绑定/手工路线。

### 11.3 最小实验

- 本轮不执行：`PET-DEC-005` 已关闭，`working_pounce` 已从必需目录退役。未来如重启 AI 探索，必须重新选择符合安静陪伴语义的动作并单独批准预算与合规边界。
- 每轮最多 8 个候选，最多 3 轮，共最多 24 个候选。
- 使用 768P 和满足动作表达的最短时长；不得为了“更顺”默认拉长视频。
- 预算公式：`候选数 × 实际秒数 × 当期单价`；执行前由项目所有者批准单轮和总预算。
- 输出仅提取运动弧、重心、关键姿态和节奏参考。
- 任何帧进入正式动作前必须在 PetManager 中重建完整 `character_rgba`、关键姿态和稳帧。

### 11.4 继续/停止

- 继续：一轮中至少有一个候选同时保持 Classic 身份、动作语义与可重建的运动弧。
- 停止：三轮后仍无候选满足上述条件，或许可/预算/凭据安全失败；转绑定或手工关键帧。

## 12. 自动测试

- Profile schema、动作 ID、帧数、duration、safe exit 和 fallback。
- 分层证据文件存在、尺寸与哈希一致。
- 头部/角色尺度、脚底线、透明、空帧和槽位污染。
- 首尾循环与 source/target 边界指标。
- hit mask 与最终 alpha 一致。
- 净化包不含 Prompt、绝对路径、凭据和失败候选。
- 缺少人工 review 时 validator 必须返回非零。

## 13. 证据文件

PetManager 工作区建议：

```text
projects/letsmakemoney-classic-pro/workspace/pet-return-quality-spike/<run-id>/
  identity/
  profiles/
  generation/
  layers/
  normalized/
  runtime/
  qa/
    contact-sheet.png
    boundary-transitions.png
    previews/*.gif
    motion-review.json
    quality-spike-evidence.json
```

必须保留：

- 每轮候选与失败原因。
- 人工重建前后哈希。
- 真实时长 GIF、Contact Sheet 和三动作运行链 GIF。
- 自动指标与人工评分。
- 净化包身份和许可/provenance 摘要。

API Key、个人路径和 Prompt 全文不进入仓库内脱敏证据。

## 14. 继续条件

全部满足才可写 `Quality Spike: pass`：

1. 五个黄金动作全部达到动作级自动门禁和人工 >=4/5。
2. `run_prepare -> run_loop -> run_stop` 连续链通过。
3. 净化 vNext 候选包通过 schema、哈希、许可和来源验证。
4. 30 分钟初步审查没有连续重复、明显机械感或高频干扰。
5. 项目所有者明确批准 Classic 黄金样片。
6. fixed-pro、S4.3 和多多 S5.5 历史输入未被修改。

## 15. 停止条件

- 三轮后身份、尺度、语义、节奏或循环仍有关键缺陷。
- 必须依赖电脑/键盘/金币才能说明工作。
- 只能从扁平图颜色反推层，或角色被道具遮挡后身体不完整。
- 自动指标通过但真实时长观感仍被评为粗糙、僵硬或重复。
- AI 探索许可、成本或凭据边界不清。
- 为适配 Classic 需要在 LMM 中加入 `petId` 特判。

## 16. 回退路线

1. AI 辅助失败：保留身份板与 Profile，转绑定或手工关键帧。
2. 自动补间失败：保留批准关键姿态，人工补间和稳帧。
3. working 动作通过、drag 失败：暂停互动回归，不用瞬移或静态拖拽冒充通过。
4. Classic 整体失败：停止多多扩展和正式回归，保留 v1 零宠物主线。

## 17. 非正式产品边界

- `PetManager ready` 不代表 LMM 可以显示给用户。
- 黄金样片不替换 Classic S4.3、不修改默认包、不进入 Release。
- 未完成 Runtime Spike 时，不因 GIF 好看宣称交互可用。
- 未确认 PET-DEC-001 至 005 时，不冻结公开宠物、默认开关、业务事件开关或 AI 披露。

## 18. 结论回写

- 冻结帧数、duration、权重、冷却、safe exit、mirrorSafe 回写 `pet-return-prd.md` 动作矩阵。
- vNext Profile 与命中结果回写 `pet-package-vnext-contract.md`。
- 生产路线与失败条件回写 PetManager `motion-quality-roadmap.md`，但需另行授权修改 PetManager。
- 通过/失败和证据索引回写 `pet-return-traceability.md`。

## 19. 本轮执行结果（2026-08-10）

### 19.1 候选范围

仅制作 Classic 五个黄金样片，不扩展多多、rest、sleep、业务事件或 pointer follow：

| 动作 | 帧数 | 总时长 | 播放方式 |
| --- | ---: | ---: | --- |
| `working_play_loop_a` | 16 | 2400ms | loop |
| `working_ack` | 8 | 960ms | oneshot |
| `run_prepare` | 13 | 910ms | oneshot |
| `run_loop` | 8 | 690ms | loop |
| `run_stop` | 13 | 1070ms | oneshot |

生产路线为 `manual-keyframes`：从已批准的 Classic 透明历史帧中确定性筛选、重建和标准化。未调用 MiniMax、imagegen 或视频切帧。S2.2 以现有 S4.3 侧身减速关键姿态连接正面落稳关键姿态，并将完整收势链反向用作预备链；没有缩放、扭曲或生成新画面。该参数仍是样片候选，尚未冻结为正式产品合同。

### 19.2 S1、S2 人工拒绝与 S2.1/S2.2 修复

- S1 被项目所有者人工拒绝：整体动画仍显粗糙，拖动收势出现缺乏动作依据的整只角色放大。
- 根因已确认：S1 `run_stop` 对完整角色逐帧施加 `1.05 -> 1.43` 的缩放，而旧 QA 将尺度变化硬编码为 `0%`，既制造了异常观感，也掩盖了真实问题。
- S1 原始 GIF、Contact Sheet、指标、manifest 和人工结论已完整归档到 PetManager `attempts/s1-user-rejected/`，不得被 S2 重构证据覆盖。
- S2a 曾尝试不缩放的独立收势，但末帧角色明显偏小，在提交项目所有者前已内部淘汰并保留失败证据。
- S2 删除所有时间线整体缩放；Contact Sheet 与状态边界图使用统一画布变换，逐帧 alpha bbox、头部区域和脚底线均由真实 PNG 重新计算，消除了“拖动时整只角色莫名变大”。
- S2 随后被项目所有者人工拒绝：五组动画均能看到脱离角色主体的低透明度碎片，以及蓝紫色边缘哑光。根因是历史源帧本身含有这些像素，旧标准化只清除了高饱和蓝色，GIF 调色板量化又把接近不可见的半透明污染放大成了实线和虚线。
- S2 原始审查页、GIF、指标、normalized PNG、manifest 和人工结论已归档到 PetManager `attempts/s2-user-edge-rejected/`，不得被新候选覆盖。
- S2.1 保持动作、姿态和时序不变，仅保留每帧最大的 alpha 连通主体、清理 4px 轮廓带内的蓝紫哑光，并在整幅主体内清理高置信度色键残留；颜色修复保留原 alpha，不把受污染像素直接挖空。
- 项目所有者确认 S2.1 整体质量有所改善，但未批准该候选：侧身 `run_loop` 直接切换正面 `run_stop`，方向变化和节奏仍不自然。S2.1 完整证据归档到 `attempts/s2.1-edge-cleaned-direction-pending/`。
- S2.2 锁定 S2.1 的 working 动作和边缘清理结果。`run_stop` 先使用 5 帧已存在的侧身减速姿态，再连接 8 帧正面落稳姿态；`run_prepare` 是整条收势链的精确反向，因此形成“正面预备 -> 侧身跑动 -> 侧身减速 -> 正面落稳”的方向闭环。
- 拖拽素材只维护一套右向 authored frames，`run_prepare`、`run_loop`、`run_stop` 均为 `mirrorSafe:true`；左向由运行时对画面和透明命中区执行精确水平镜像。审查页必须同时展示向右原始链、向左镜像链和左右关键姿态对照，不能再用 manifest 字段代替左向视觉证据。
- S2.2 保持所有帧 authored scale，禁止时间线整体缩放；工作动作逐帧哈希与 S2.1 完全一致。APNG 使用完整帧覆盖且不在帧间清空画布，消除了循环边界的透明闪帧。

### 19.3 自动 QA

- Quality Spike 独立测试：14/14 通过，其中左向逐帧必须等于右向逐帧的精确水平镜像，帧数与时长完全一致；新增人工决定持久化与防误发布测试。
- PetManager 全量回归：167/167 通过。
- LMM v1.0.8 current gate 全量通过，样片工作区未改变正式产品入口、默认配置或门禁脚本。
- 五个动作均为 0 空帧、0 槽位污染、0 色键残留、0 脱离主体组件、0 边缘哑光像素；脚底基线固定为 Y=198；hit mask 与最终 alpha 一致。
- S2.2 的全局缩放策略为 `forbidden`，五个动作所有时间线缩放因子均为 `1.0`；QA 指标可从 normalized PNG 独立复算。
- 生成 `schemaVersion: 2` 沙盒候选 manifest、atlas、逐帧 duration、alpha RLE hit mask、来源、许可与 provenance。
- fixed-pro 四文件、Classic S4.3 manifest 和历史输入哈希保持不变。
- 项目所有者于 2026-08-10 明确确认 S2.2 通过；决定写入独立 `review-decision.json`，重新生成后仍稳定产出 `approved / ready:true / published:false`。

### 19.4 审查入口

PetManager 工作区：`projects/letsmakemoney-classic-pro/workspace/pet-return-quality-spike/`

- `review.html`
- `qa/contact-sheet.png`
- `qa/boundary-transitions.png`
- `qa/previews/*.png`（权威 APNG）
- `qa/run-chain.png`（权威 APNG）
- `qa/previews/*.gif`、`qa/run-chain.gif`（兼容证据）
- `qa/quality-metrics.json`
- `qa/failure-history.json`
- `qa/layout-contract.json`
- `review-decision.json`
- `attempts/s1-user-rejected/`
- `attempts/s2a-authored-stop-no-scaling/`
- `attempts/s2-user-edge-rejected/`
- `attempts/s2.1-edge-cleaned-direction-pending/`

失败历史明确记录了测试先行的红灯、S1 项目所有者拒绝、S2a 内部拒绝、S2 边缘污染人工拒绝、S2.1 继续精修结论，以及拒绝“直接切 AI 视频作为正式帧”的路线。

### 19.5 人工签核与剩余边界

- 项目所有者已检查 S2.2 五动作、左右拖拽链、边缘质量和整体节奏，并明确回复“通过”。
- 本次使用项目所有者整体签核，没有另存逐动作数值评分表；该事实记录为证据形式差异，不反向补造分数。
- 30 分钟观感由项目所有者签署确认，但未单独保存计时录屏；后续 LMM 产品级 30 分钟编排验收仍需独立执行。
- 本轮没有验证 `awake_rest`、`sleeping`、业务事件或多多兼容，不能外推为完整宠物包通过。
- 样片没有进入 LMM 正式资源，`published:false` 保持不变。
- 项目所有者后续明确表示不满意 Runtime Spike 所用旧 S4.3 fixture 中的电脑动画。该意见针对旧运行时测试夹具；S2.2 五动作黄金样片本身不含电脑道具，因此不撤销本轮签核。后续 G8 必须使用无电脑 S2.2 包，不得继续把旧电脑动画当作产品素材。

### 19.6 独立判断

`PetManager ready = true（仅限 S2.2 Classic 五动作黄金样片）`。

S1 与 S2 已明确失败，S2.1 已归档为继续精修，S2.2 已通过自动门禁与项目所有者人工签核。该结论只打开 Quality 轨输出门禁，不代表 `LMM sandbox pass` 或产品回归批准；样片仍不得直接复制进 LMM 正式资源。

## 20. 完整动作目录 Batch A（2026-08-11）

### 20.1 批次范围与生产路线

PetManager 在独立工作区 `projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/` 最初建立 19 动作候选目录，并仅完成以下 Batch A 候选。后续 `working_pounce` 退役，当前正式候选目录为 18 项：

- `awake_rest_loop`
- `rest_ack`
- `sleeping_loop`
- `sleep_twitch`
- `sleep_ack`

本批次从已批准的透明源素材中确定性筛选、排序和标准化，没有调用 imagegen、MiniMax 或视频生成，也没有使用电脑、键盘、显示器、`lunch_relief` 或 `lunch_return` 素材。S2.2 的五个锁定动作按文件逐字节复用，生成器测试会阻止其被重写。

### 20.2 自动 QA 与人工决定

- 目录测试：8/8 通过。
- Batch A 所有帧均为 192×208 RGBA；脚底线漂移不超过 2px，空帧、脱离主体碎片和边缘残留均为 0。
- `awake_rest_loop` 与 `sleep_twitch` 的自动几何指标在阈值内。
- `rest_ack`、`sleeping_loop`、`sleep_ack` 因真实姿态变化触发头部或整体相邻尺度预警；预警没有被自动门禁冒充通过。
- 项目所有者检查真实时长预览、逐帧图与状态边界后明确回复“可以”，并接受本候选中的上述几何预警。
- 决定写入独立 `review-decision.json`，重新生成后稳定得到 `approved / batchReady:true / catalogReady:false / published:false`。

### 20.3 审查与证据入口

- 审查页：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/review.html`
- 决定：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/review-decision.json`
- 批次 Profile：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/profiles/batch-a-profile.json`
- 完整目录 Profile：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/profiles/catalog-profile.json`
- 自动指标：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/qa/quality-metrics.json`
- 绑定证据：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/qa/catalog-evidence.json`

### 20.4 结论边界

`PetManager Batch A ready = true`，仅覆盖上述五个清醒休息与睡眠动作。Batch B 中 `working_play_loop_b` 与 `working_observe` 已在后续人工审查中获批，并在项目所有者将 `working_pounce` 退役后关闭为 `batchReady:true`。18 动作完整目录仍有六个未关闭动作：`rest_groom`、`rest_stretch`、`work_start`、`break_relief`、`break_return`、`work_end_celebrate`。

因此 `PetManager ready = false（完整目录）`、`Product return approved = false`。本批次批准不替代 LMM 正式产品级 30 分钟低重复编排、完整动作目录 G8 或正式入口验收。

## 21. 完整动作目录 Batch B 候选（2026-08-11）

### 21.1 已批准范围

本轮从已通过标准视觉 QA 的透明动作行中确定性提取并标准化候选。自动边界检查后，以下两个低干扰陪伴动作进入项目所有者人工审查，并于 2026-08-11 获得批准：

- `working_play_loop_b`：6 帧，820ms，脚底线漂移 0px，头部最大相邻尺度变化 1.724%，角色最大相邻尺度变化 1.754%。
- `working_observe`：6 帧，1030ms，脚底线漂移 0px，头部最大相邻尺度变化 3.509%，角色最大相邻尺度变化 3.550%。

两者均无空帧、脱离主体碎片或边缘残留；真实时长预览、逐帧图和 `working_play_loop_a -> candidate -> working_play_loop_a` 边界证据已经生成。本轮未调用 imagegen、MiniMax 或视频生成，也未使用电脑、键盘或显示器道具。`working` 在这里表示用户工作期间的安静陪伴，不表示小猫需要表演工作。

### 21.2 扑跳失败证据

`working_pounce` 的旧 `jumping` 源行虽通过历史标准包 QA，但与工作基础循环相比，头部最大相邻尺度变化为 42.105%，角色最大相邻尺度变化为 40.909%。在 192×208 锁定画布内按工作状态尺度放大将造成裁切，因此稳定化不能解决其状态边界问题。

该动作已在人工批准前因尺度问题被拒绝。后续隔离重建虽然通过几何硬门禁，但项目所有者进一步确认它与安静陪伴语义无关，因此正式退役且不要求补位。失败帧、完整链和边界对照继续作为负向证据保留。

### 21.3 门禁状态与证据

- 目录专项测试：10/10 通过。
- PetManager 核心测试：167/167 通过；Quality Spike 独立测试：14/14 通过。
- 生成确定性：目录生成器连续运行保持确定性；最终数量以 `catalog-evidence.json` 为准。
- Batch A 的 `review-decision.json` 和 S2.2 锁定动作保持不变。
- 当前主目录状态：`batch_b_approved / reviewedActionsReady:true / batchBReady:true / catalogReady:false / published:false`。
- 审查页：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/review.html`。
- 可审查逐帧图：`qa/batch-b-contact-sheet.png`。
- 工作状态边界：`qa/working-boundary-transitions.png`。
- 扑跳退役证据：`pounce-rebuild/review.html` 与 `pounce-rebuild/review-decision.json`。

`working_play_loop_b` 与 `working_observe` 的人工审查已经关闭；Batch B 已 ready。该批次通过不代表完整目录或正式产品回归通过。

### 21.4 `working_pounce` 隔离重建与退役证据

旧 `jumping` 来源继续作为尺度失配的拒绝证据保留，不被覆盖或改写。新的 `S3-Batch-B-Pounce-Rebuild` 候选在独立目录中仅复用已批准 S2.2 的 `run_prepare`、`run_loop` 和 `run_stop` 帧，不重绘、不缩放、不修改像素，也不合入当前 Batch B。

- 候选：25 帧，1785ms，支持运行时安全镜像。
- 自动硬门禁：脚底线漂移 0px、空帧 0、脱离主体碎片 0、边缘残留 0。
- 最大相邻头部尺度变化：23.404%；最大相邻角色尺度变化：23.022%。这些数值来自正面坐姿到侧身伏低的姿态包围盒变化，不是整猫缩放；所有来源帧保持 1.0 倍。
- 生成确定性：同一输入连续重建后，37 个生成文件 SHA256 全部一致。
- 最终状态：`rejected / hardGate:pass / semanticGate:rejected_by_owner / retiredFromCatalog:true / replacementRequired:false / published:false`。
- 审查入口：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/pounce-rebuild/review.html`。

2026-08-12，项目所有者确认工作态只需要简单陪伴，扑跳与工作陪伴没有语义关系。该动作因此从必需目录退役，不进入新关键帧或绑定补做；`run_prepare`、`run_loop` 与 `run_stop` 保持拖拽专用。自动硬门禁通过不改变这一产品语义结论。

## 22. 剩余动作来源审计与生产 Profile（2026-08-12）

### 22.1 来源审计

剩余六个动作已经逐项核对现有 Standard v2、fixed-pro、Classic S4.3 与当前 Quality Spike 素材。结论如下：

- `rest_groom`：现有前爪轻动和进食动作均不能完整表达舔爪、擦脸与回位，禁止改名复用。
- `rest_stretch`：旧跳跃动作包含腾空且没有舒展回收，禁止改名复用。
- `work_start`：挥爪和单击回应属于互动语义，不能代替开始工作的低干扰边界。
- `break_relief`：失败、进食与旧电脑午休动作分别存在负面、道具或旧工作表演语义，不进入候选。
- `break_return`：旧午休返回依赖电脑道具，与无道具陪伴定位冲突。
- `work_end_celebrate`：旧庆祝动作仅作为姿态参考；其八帧数量、节奏和状态边界不足以直接晋级。

因此六项继续保持 `generation_required`，统一采用 `new-layered-keyframes`。本轮未调用 imagegen、MiniMax 或视频生成。

### 22.2 Profile 与 A2 视觉探索结果

- A2 Profile：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/plans/batch-a2/action-profile.json`
- A2 `compiled-profile.json` SHA256：`44B95F081E7303F071D924244F2DF074C6816A662FBC711CFA1E5EA44E2BDD93`
- C Profile：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/plans/batch-c/action-profile.json`
- C `compiled-profile.json` SHA256：`548E0691CF28EA7DA4F1DFC1628E07A099E87B4FA4070CE2F2E91F3FB6D156D9`
- 来源审计：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/plans/source-audit.json`
- 审查页：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/plans/review.html`

两份 Profile 均已由 `compile_action_profile.py` 编译为 `planned`，输出 manifest 保持空动作和空图集。项目所有者随后批准 A2 Profile，Batch C 仍为 `profile_review_pending`。

### 22.3 A2 整条带路线被拓扑门禁拒绝

A2 获批后仅进入隔离视觉探索。`rest_groom` 与 `rest_stretch` 的五次整条带尝试出现以下不可接受问题：

- 坐姿保留四只落地爪的同时又生成一只抬起前爪，形成五爪。
- 后续修正候选只剩三只可辨爪，且抬起肢体在帧间改变身份。
- 伸展候选出现缺肢、前后肢边界漂移和遮挡关系不连续。

该问题被分类为 `ANATOMY_TOPOLOGY_UNSTABLE`。它不能通过去背景、色键清理、稳帧、脚底线校准或节奏修正补救，因此旧生成路线立即停止。所有失败条带只保留为来源证据，禁止进入标准化、图集、manifest 或人工 `ready`。

- 失败证据：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/plans/batch-a2/motion-a2-candidate/generation/failure-evidence.json`
- 修订路线：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/plans/batch-a2/topology-locked-rig-spike.md`
- 当前状态：`generation_failed_anatomy_gate / ready:false / published:false`

下一步只允许先审查固定拓扑的分层角色套件与 K0/K1/K2 三张关键姿态。头、躯干、左前肢、右前肢、左后肢、右后肢和尾巴必须使用固定图层身份；每张姿态都必须能明确核对四只爪。该门禁未通过前，不制作 16 帧补间，也不启动 Batch C。

### 22.4 分层路线停止与首轮降级

后续单张 `rest_groom` 关键姿态探索没有立即产生多肢，但头身比例、线条、后爪结构和整体尺度均明显偏离已批准 Classic 母版，触发 `IDENTITY_SCALE_DRIFT`。同时，本机未发现 Inkscape、Blender、Krita、OpenToonz、Synfig、Spine、DragonBones 或 Rive 等可复验分层绑定环境，无法证明“固定图层身份”合同能够被真实执行。

因此 A2 按既定停止条件延后：首轮桌宠回归的清醒休息状态只消费已经人工批准的 `awake_rest_loop` 与 `rest_ack`。`rest_groom` 和 `rest_stretch` 不改名、不由其他语义动作补位，也不再通过整条带或逐张 AI 重绘继续尝试。未来只有取得真正的分层角色源文件与绑定工具后才能重新开启。

- 关键姿态失败 SHA256：`CB5D46474EC72F7486689DFFC22C437A3641BCA970F4AC0371FE85F819F80313`
- 回退决定：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/plans/batch-a2/fallback-decision.json`
- A2：`deferred / ready:false / published:false`
- Batch C：继续阻塞，未生成素材

## 23. 首轮回归精简动作包（2026-08-12）

### 23.1 范围收敛

项目所有者接受质量优先的首轮降级：不再为凑齐原 18 动作目录而继续使用不可控的整条带或逐张 AI 重绘。首轮开发沙盒只消费以下 12 个已经完成自动 QA 和人工视觉审查的动作：

- working：`working_play_loop_a`、`working_play_loop_b`、`working_observe`、`working_ack`
- awake_rest：`awake_rest_loop`、`rest_ack`
- sleeping：`sleeping_loop`、`sleep_twitch`、`sleep_ack`
- dragging：`run_prepare`、`run_loop`、`run_stop`

`rest_groom`、`rest_stretch` 与四个业务事件动作继续延后，不改名、不硬补。业务边界只切换 LMM 最新权威 BaseState，不播放尚未通过的 one-shot。`working_pounce` 保持退役。

结构化决定：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/plans/batch-a2/fallback-review-decision.json`。

### 23.2 确定性净化包

PetManager 从既有已批准帧确定性组装首轮运行时包，没有调用 imagegen、MiniMax 或视频生成，也没有修改任何已批准帧：

- 候选：`S3-First-Return-Reduced-Catalog`
- package version：`0.4.0-sandbox.1`
- 动作：12
- 帧：118
- manifest SHA256：`73A722D022EB4138B5FA8F7469D5304F08DC026EB3CB98D480A9C56CAE911E0E`
- package tree SHA256：`745AB4A26B4B149FC279686D9FA236384BDDF150DF2D18C2DBDA643A1A596A4E`
- 状态：`ready_for_first_return_sandbox / published:false`

运行时包只包含 atlas、逐帧 alpha RLE hit mask、manifest、package index 以及净化后的来源、许可和 provenance。生产源文件、失败条带、Prompt、绝对路径和 QA 中间文件均不进入该包。

### 23.3 30 分钟确定性编排模拟

以固定随机种子分别模拟 working、awake_rest 和 sleeping 三种基础状态，每种状态至少 30 分钟：

| 状态 | 种子 | 事件数 | 分布摘要 | 违规 |
| --- | ---: | ---: | --- | ---: |
| working | 10701 | 1013 | loop A 611、loop B 381、observe 18、ack 3 | 0 |
| awake_rest | 10702 | 444 | loop 441、ack 3 | 0 |
| sleeping | 10703 | 439 | loop 424、twitch 12、ack 3 | 0 |

左右拖拽都使用 `run_prepare -> run_loop -> run_stop`，左向为逐帧精确水平镜像。模拟未引用任何延后或退役动作。该结果只证明动作范围、权重、冷却、最大连续次数与确定性，不替代真人连续观看。

### 23.4 独立结论

- `PetManager reduced-scope ready = true`
- `PetManager full-catalog ready = false`
- `LMM loader compatibility = pass`
- `LMM first-return desktop sandbox pass = false`
- `Product return approved = false`
- `formal product entry allowed = false`

LMM 已证明新包可按显式 12 动作范围解析和校验，且旧 5 动作预期不会静默接受扩展包；尚未使用这份 12 动作包完成真实桌面播放、输入、DPI、动态命中、坏包和两小时稳定性验收。

审查入口：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/first-return-review.html`。结构化证据：`qa/first-return-package-evidence.json` 与 `qa/first-return-schedule-simulation.json`。
