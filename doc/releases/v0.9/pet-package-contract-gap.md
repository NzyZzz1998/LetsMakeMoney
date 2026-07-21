# LetsMakeMoney v0.9 宠物包合同差距

**文档类型**：开发前合同 Review，不是最终 schema

**生产方基线**：PetManager Classic Pro、Pixel Pro、多多 Pro 三套完整交付

**消费方基线**：LetsMakeMoney v0.8 Godot 运行时

**更新日期**：2026-07-17

## 目的与边界

本文不再把多多当作 PetManager 的唯一交付对象，而是用三套完整包验证一个共同问题：**PetManager 能稳定生产多种宠物，但 LetsMakeMoney 尚未形成通用、安全、可回退的宠物包消费合同。**

本文回答：

1. Classic Pro、Pixel Pro 和多多各自适合承担什么角色；
2. 哪些生产合同已经稳定；
3. LMM 消费合同缺少什么；
4. 一个通用适配器如何避免单宠物特例；
5. 哪些问题必须在技术 spike、PRD 或验收阶段关闭。

本文不修改 PetManager 或 LMM，不确定最终 schema，不授权素材公开。

## 宠物候选分层

| 宠物包 | 与当前 LMM 的关系 | v0.9 建议角色 | 不应直接做的事 |
| --- | --- | --- | --- |
| Classic Pro | 明确继承当前橘猫 v2 身份，升级为平滑完整动画 | 默认橘猫第一候选，先影子接入 | 未验收即替换默认资源 |
| Pixel Pro | 同一橘猫的像素风重绘 | 备选风格、合同兼容样例 | 把风格变化包装成无感优化 |
| 多多 Pro | 全新长毛猫身份 | 多宠物合同样例，可选宠物候选 | 把多多当作唯一接入对象 |

## 当前生产合同

### 三套包的共同结构

```text
package/
  pet.json
  spritesheet.webp
  actions.json
  extra-actions.webp
  hashes.json
  validation.json
  qa-actions/
```

- 标准图集：`1536×2288`，8 列 × 11 行，单元格 `192×208`；
- 标准合同：9 个动作 + 16 个方向；
- `spriteVersionNumber = 2`；
- Pro 图集：`1536×832`，4 行 × 8 帧；
- Pro 动作：`sleeping`、`eating`、`celebrating`、`making-money`；
- `actions.json` 提供逐帧时长和循环属性；
- 包内哈希、结构验证和 QA 证据齐全。

### 已确认的差异

- Classic Pro 是平滑非像素风，身份来源为原 LMM v2，运动参考 Pixel Pro；
- Pixel Pro 是像素风完整方案；
- 多多是不同宠物身份；
- 三套包共享几何与动作 schema，证明通用适配器有现实基础；
- 三套包的可见轮廓、比例和动作幅度并不相同，运行时不能只按一套固定命中区处理。

### 完整样例不等于运行时包

完整样例还包含：

- 生产来源与 QA；
- 本机绝对路径；
- 离线验收页；
- Skill 归档或生成上下文；
- 可能不应公开的参考和中间证据。

LMM 运行时只应接收经过净化、带许可、无本机路径的最小包。

## 当前消费合同

LetsMakeMoney v0.8 当前通过 Godot 资源工作：

```text
PetResource (.tres)
  ├─ pet_id
  ├─ display_name
  ├─ SpriteFrames
  ├─ thumbnail
  └─ animation_fps
```

当前行为：

- `.tres` 静态引用逐帧 PNG；
- 运行时扫描固定资源目录；
- 默认 `cat_orange_v2`，失败后回退 v1 和占位猫；
- 动画名以 Godot `SpriteFrames` 中的字符串为合同；
- 单击和双击按基础状态解析；长按仍是通用动作；
- `Main` 用固定 1.55 秒恢复基础状态；
- 命中区以当前纹理 Alpha 扫描结果为基础，并缓存；
- 没有外部包 schema、哈希、许可、版本或净化校验。

## 总体差距矩阵

| 合同维度 | PetManager 当前 | LMM 当前 | 差距 | 严重度 |
| --- | --- | --- | --- | --- |
| 资源格式 | JSON + WebP atlas | `.tres` + PNG + SpriteFrames | 无导入/转换层 | Blocker |
| 包对象 | 三套同 schema 完整包 | 固定 Godot 资源 | 无通用包抽象 | Blocker |
| 许可 | 包内无专属许可 | 公共项目有受限素材许可 | 未绑定到具体包 | Blocker |
| 路径 | QA/来源含绝对路径 | `res://` | 必须净化 | Major |
| 动作语义 | Hatch 标准 + Pro 事件 | 3 基础状态 × 交互延伸 | 不等价 | Major |
| 时间 | Pro 有逐帧毫秒 | 固定 FPS + 1.55 秒恢复 | 无法完整消费 | Major |
| 锚点 | 固定单元格，无运行时锚点字段 | Sprite 居中与现有缩放 | 基线可能跳动 | Major |
| 命中区 | 无逐帧交互几何 | 当前帧 Alpha 扫描并缓存 | 大动作穿透失真 | Major |
| 中断策略 | 未定义 | token + 定时恢复 | 行为不可预测 | Major |
| 版本兼容 | `spriteVersionNumber` + schemaVersion | 无外包版本 | 缺兼容和迁移门禁 | Major |
| 回退 | 包内无 LMM 回退声明 | v2 → v1 → placeholder | 需连接两层回退 | Major |
| 身份定位 | Classic/Pixel/Duoduo 不同角色 | 默认仅橘猫 v2 | 需产品级候选分层 | Minor |

## 候选运行时包边界

### 应进入 LMM 的内容

```text
pet-runtime-package/
  manifest.json
  spritesheet.webp
  extra-actions.webp
  LICENSE.assets.md
  hashes.json
  preview.png               # 可选
```

### 不应进入 LMM 的内容

- PetManager workspace；
- 原始参考、提示词、失败重试和筛选记录；
- `qa/` 与 `provenance/` 全量证据；
- 本机绝对路径；
- `review.html`；
- Skill 源码或归档；
- 未声明公开边界的参考素材。

### 净化导出必须保证

1. 只包含白名单文件；
2. JSON 中不存在盘符路径、用户名或工作区路径；
3. 每个文件都有 SHA256；
4. 包含素材许可、来源类别和可再分发声明；
5. schema 与 LMM profile 可被版本校验；
6. 生产包与运行时包的哈希关系可追溯；
7. Classic、Pixel、多多都通过同一导出器，不使用宠物 ID 特判。

## 候选 manifest 字段

| 字段 | 必需 | 说明 |
| --- | --- | --- |
| `package_schema` | 是 | LMM 宠物包 schema 版本 |
| `lmm_profile_version` | 是 | LMM 动作/几何合同版本 |
| `pet_id` | 是 | 稳定唯一 ID |
| `display_name` | 是 | 用户可见名称 |
| `pet_version` | 是 | 宠物资产版本 |
| `producer` | 是 | `PetManager` |
| `producer_revision` | 是 | 可追溯 commit/tag |
| `visual_family` | 是 | `classic`、`pixel`、`realistic` 等 |
| `identity_role` | 是 | `default_candidate`、`alternative_style`、`additional_pet` |
| `license` | 是 | 许可 ID 与文件路径 |
| `files` | 是 | 图集、哈希、尺寸与 MIME |
| `geometry` | 是 | cell、逻辑尺寸、锚点、基线 |
| `actions` | 是 | 帧、时长、循环和语义 |
| `interaction_profile` | 是 | 精确动作和回退映射 |
| `hit_test` | 是 | 命中区策略 |
| `compatibility` | 是 | 最低/最高 LMM 版本 |
| `fallback` | 否 | 包内动作回退声明 |

### 候选结构示意

```json
{
  "package_schema": 1,
  "lmm_profile_version": 1,
  "pet_id": "letsmakemoney-classic-pro",
  "pet_version": "0.1.0",
  "producer": "PetManager",
  "producer_revision": "<commit-or-tag>",
  "visual_family": "classic",
  "identity_role": "default_candidate",
  "license": {
    "id": "LMM-Restricted-Assets",
    "file": "LICENSE.assets.md"
  },
  "geometry": {
    "cell": [192, 208],
    "logical_size": [256, 256],
    "anchor": [0.5, 1.0],
    "baseline_y": 0.92
  },
  "interaction_profile": "lmm-desktop-v1"
}
```

示例仅用于暴露缺口，不是已批准 schema。

## 动作语义合同

### 产品语义与现有候选

| LMM 语义 | 必需/可回退 | 三套包现有候选 | 当前结论 |
| --- | --- | --- | --- |
| `idle` | 必需 | `idle` | 可直接映射 |
| `working` | 必需 | `making-money`、`review`、`running` | 必须产品确认或补制作 |
| `resting` | 必需 | `sleeping`、`waiting`、`failed` | 必须产品确认或补制作 |
| `idle_clicked_single` | 可回退 | `waving` 候选 | 语义不完全等价 |
| `idle_clicked_double` | 可回退 | `celebrating`、`jumping` 候选 | 需确认 |
| `working_clicked_single` | 可回退 | 无 1:1 动作 | 应补制作或回基础状态 |
| `working_clicked_double` | 可回退 | `making-money` 候选 | 需确认事件语义 |
| `resting_clicked_single` | 可回退 | `waiting` 候选 | 需确认 |
| `resting_clicked_double` | 可回退 | 无 1:1 动作 | 应补制作或回基础状态 |
| 三个 `*_clicked_hold` | 可回退 | 无 | 当前缺失 |
| 收益庆祝事件 | 可选 | `making-money` / `celebrating` | 更适合作为事件动作 |

### 建议回退合同

```text
resolve(base_state, interaction):
  1. base_state + interaction 精确动作
  2. 当前宠物 interaction 通用动作
  3. 当前宠物 base_state
  4. 当前宠物 idle
  5. v0.8 橘猫对应动作
  6. placeholder idle
```

回退必须写入 manifest 或 profile，不允许在代码中按宠物 ID 猜测。

## 播放与中断合同缺口

每个动作至少需要：

- `loop`；
- `durations_ms` 或可计算总时长；
- `priority`；
- `interruptible`；
- `interrupt_points` 或安全退出规则；
- `resume_policy`；
- `timeout_ms`；
- `on_complete`；
- `base_state_guard`。

建议原则：

- 基础循环可被交互动作打断；
- 单击可被双击升级时，必须避免先完整播放单击；
- 长按开始后不再补发单击；
- 拖拽优先级高于点击反馈；
- 菜单和模态窗口期间冻结输入分类，不必强制停止视觉循环；
- 动作完成后恢复触发前或最新基础状态；
- 超时只防损坏资源，不替代真实完成事件。

## 锚点、尺寸和命中区合同缺口

### 已观察事实

- 三套包都使用 192×208 单元格，但可见 bbox 不同；
- Classic 的跳跃、跑动和庆祝帧有明显高度变化；
- Pixel 的轮廓更硬，缩放策略与平滑图不同；
- 多多的毛发轮廓和 Pro 庆祝动作横纵变化更大；
- 当前 LMM 点击穿透几何不会可靠随每帧变化。

### 候选命中策略

| 策略 | 优点 | 风险 | 建议 |
| --- | --- | --- | --- |
| 每帧 Alpha 扫描 | 最精确 | CPU 与 native region 更新频繁 | 仅作基准实验 |
| 每动作 union | 稳定、实现简单 | 透明区域可能多阻挡 | 首选 spike 候选 |
| 关键帧分组 | 精度与成本折中 | manifest 更复杂 | 若 union 体验不佳再评估 |
| 固定逻辑矩形 | 最稳定 | 透明穿透体验最差 | 只作降级路径 |

### 需要的门禁

- 每帧可见 bbox 不越界；
- 脚底基线偏差在合同阈值内；
- 动作间显示尺寸不出现无意缩放；
- 100%、125%、150% DPI 下清晰且位置稳定；
- Panel 邻接区域不被宠物 union 误吞；
- 右键菜单与拖拽命中不回归。

## 导入与校验门禁

### 导入前

1. schema 与 profile 支持；
2. `pet_id` 不冲突；
3. 必需文件和哈希正确；
4. 图集尺寸、cell 和帧索引合法；
5. 动作时长、循环和映射完整；
6. 锚点、逻辑尺寸和命中策略合法；
7. 许可文件存在且允许当前分发；
8. 文本无绝对路径、秘密或私有证据；
9. 不含白名单外文件。

### 导入失败

1. 不写入当前宠物配置；
2. 不覆盖已安装包；
3. 记录脱敏错误和包身份；
4. UI 显示可读错误；
5. 继续加载 v0.8 默认橘猫；
6. 支持删除失败缓存后重试。

## 测试合同

### PetManager 侧

- Classic、Pixel、多多使用同一 schema 和净化导出器；
- 结构、尺寸、空帧、Alpha、哈希和许可检查；
- 动作时长、循环和语义映射检查；
- 锚点、基线和 bbox 稳定性；
- 独立视觉 QA 与跨阶段身份检查；
- 包内绝对路径、私有证据和未知文件扫描。

### LMM 适配器侧

- 三套包都能导入，证明没有 ID 特例；
- 未知 schema、损坏哈希、缺许可和越界帧失败；
- 重复 ID、版本降级和更新兼容；
- 导入失败不污染配置；
- 缓存可复用且可安全失效；
- 回退到 v0.8 橘猫。

### LMM 运行时侧

- 基础状态与三种交互矩阵；
- 动作完整播放与安全中断；
- 连续单击、双击、长按和拖拽仲裁；
- 右键菜单、Panel 和模态保护；
- DPI、缩放、透明度和点击穿透；
- Classic 与 v0.8 橘猫对照；
- Pixel 风格切换不影响几何；
- 多多验证不同身份和大轮廓动作。

## 分阶段接入建议

| 阶段 | 目标 | 通过门禁 |
| --- | --- | --- |
| P0 合同冻结 | 定义 runtime schema、LMM profile、许可和净化边界 | 文档和样例 manifest 评审通过 |
| P1 导出 spike | 从三套包生成净化运行时包 | 无绝对路径、许可和哈希完整 |
| P2 导入 spike | 同一适配器读取三套包 | 无宠物 ID 特例，损坏包安全失败 |
| P3 Classic 影子接入 | Classic 作为非默认实验宠物 | 动作、DPI、穿透、拖拽通过 |
| P4 多包兼容 | Pixel 与多多验证风格和身份差异 | 同一 profile 可消费，回退稳定 |
| P5 默认候选 | Classic 与 v0.8 橘猫并行验收 | 人工与 Computer Use 对照通过 |
| P6 默认替换 | 可选将 Classic 设为默认 | 保留 v0.8 回退和版本回滚 |

## 阻塞项与决策入口

### Blocker

1. 没有通用导入器；
2. 包内没有明确素材许可；
3. 没有 LMM 动作语义 profile；
4. 没有锚点、基线和命中区合同；
5. 完整交付含生产路径，尚无净化包；
6. LMM 播放器仍按固定 1.55 秒恢复。

### 进入技术 spike 前需要确认

1. Classic 是否是 v0.9 默认升级第一候选；
2. Pixel 是否只作备选风格；
3. 多多是可选宠物还是仅作合同测试；
4. 三套包是否统一沿用受限素材许可；
5. `working/resting` 与交互动作采用映射还是补制作；
6. Pro 动作的产品触发语义。

### 必须保留

- v0.8 橘猫、v1 和占位猫回退链；
- 现有输入、托盘、Panel 和点击穿透回归测试；
- PetManager 完整生产证据与 LMM 公共运行时包的隔离；
- 每套宠物包独立版本和哈希；
- Classic、Pixel、多多对同一合同的交叉验证。

## Review 结论

PetManager 已拥有的不只是多多，而是：

- **Classic Pro**：当前橘猫的直接优化和默认候选；
- **Pixel Pro**：完整像素风备选；
- **多多 Pro**：独立身份和多宠物管线证明。

三套交付共同证明生产侧已具备较成熟能力，也共同暴露了同一个核心缺口：LetsMakeMoney 还没有通用宠物包合同、导入器、动作语义、动态几何和安全回退闭环。下一阶段应在 `/idea` 中优先压力测试“Classic 默认候选 + 通用多宠物合同”，而不是围绕多多写一次性接入方案。
