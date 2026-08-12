# pet-return 开发承接计划

## 追踪信息

- 当前状态：进行中
- 目标版本：内部代号 `pet-return`，不对应公开版本
- 上游来源：[pet-return-prd.md](./pet-return-prd.md)
- 下游承接：[pet-return-progress.md](./pet-return-progress.md)、两条 Spike 人工审查
- 当前事实源：PRD；本文；progress
- 执行基线：LMM `main@40f3d5047024d0833dccb2b3638520d5ab9835ea`，PetManager `main@7bd83c6eed1fc2fb9f3e153dfbda39ef13f46d92`
- 最后更新：2026-08-12

## 1. 开发范围

- 本次包含：并行执行 Runtime Spike 与 Quality Spike，验证桌宠回归的承重假设。
- 本次不包含：正式产品入口、默认配置、current gate、多多、`pointer_follow`、MiniMax、正式宠物包或正式发布。
- 范围保护：两轨代码、证据、状态和结论相互独立；任一轨道 P0 失败只停止并回滚该轨道。
- 发布边界：不提交、不推送、不打 tag、不构建正式产品、不创建 Release。

## 2. PRD 对照

| PRD 需求点 | 开发模块 | 覆盖方式 |
| --- | --- | --- |
| 独立透明 WebView 沙盒 | Runtime Spike | 仅位于 `spikes/pet-return-runtime/` 的独立 Tauri 应用 |
| 逐帧时长与 `animation_finished` | Runtime Spike | 行为测试、运行日志和真实窗口证据 |
| 动态命中、点击穿透、长按拖拽 | Runtime Spike | 原生桥与输入状态机测试；P0 失败即停轨 |
| 隐藏恢复、坏包回退、主应用隔离 | Runtime Spike | 故障注入、独立配置目录和进程边界证据 |
| Classic 五个黄金样片 | Quality Spike | PetManager 隔离工作区中的候选帧、图集、GIF 与 QA |
| 身份、尺度、基线、边界和节奏 | Quality Spike | 自动指标加真实时长人工审查门禁 |
| 三层门禁 | 两轨汇总 | 分别输出 `LMM sandbox pass` 与 `PetManager ready`，不得互相继承 |

## 3. 文件与模块影响

| 模块 | 允许改动 | 禁止改动 |
| --- | --- | --- |
| LMM Runtime | `spikes/pet-return-runtime/` | `apps/windows-v1/`、默认配置、current gate、正式入口 |
| PetManager Quality | `projects/letsmakemoney-classic-pro/workspace/pet-return-quality-spike/` | Skill、S4.3/S5.5、正式样例、LMM |
| 项目文档 | 本计划、progress、spike log、两份既有 Spike 文档的结果区 | PRD 产品合同和公开版本事实 |

## 4. 实施顺序

1. 锁定仓库、输入包、工具链和证据目录身份。
2. 两轨分别先建立失败测试，不共享完成状态。
3. Runtime 完成最小透明窗口、播放器、输入、命中、生命周期和回退验证。
4. Quality 完成五个 Classic 候选动作、净化候选包和自动 QA。
5. 汇总截图、GIF、日志、哈希和失败尝试，分别作门禁判断。
6. 更新两份 Spike 文档，停在人工视觉与桌面审查点。

## 5. 任务拆解

### A. Runtime Spike

- A1：建立隔离应用身份、fixture 哈希和失败测试。
- A2：实现逐帧播放器与真实完成事件。
- A3：实现 500ms 长按、拖拽阈值、方向和释放收势状态机。
- A4：验证逐帧原生命中、透明穿透及 DPI 边界。
- A5：验证隐藏/恢复、坏包降级和主应用隔离。
- A6：生成可复核证据并给出 `LMM sandbox pass`。

### B. Quality Spike

- B1：锁定 Classic 身份与五动作 Profile，建立失败测试。
- B2：以绑定、手工关键帧或既有分层素材制作五个候选动作。
- B3：生成逐帧时长、图集、manifest、GIF、Contact Sheet 和边界图。
- B4：执行自动质量指标、来源与许可检查。
- B5：保留失败尝试，生成审查页并给出 `PetManager ready`。

## 6. 测试与验收

- 自动化：合同解析、逐帧时序、状态机、输入仲裁、包损坏、哈希、基线、尺度、空帧、污染和循环边界。
- 桌面检查：透明窗口、命中、穿透、隐藏恢复、拖拽和主应用隔离。
- 视觉检查：五动作真实时长 GIF、Contact Sheet、状态边界和连续播放。
- 证据：每轨独立保存命令、环境、输入哈希、日志、截图/GIF、失败尝试和判定。
- 失效条件：任一输入包、实现、工具链、候选图集或 manifest 哈希变化时，对应轨证据失效。

## 7. 开发日志约定

- 使用 [pet-return-spike-log.md](./pet-return-spike-log.md) 记录实现、失败注入和取舍。
- progress 只记录状态、门禁、阻塞和证据入口。
- 不将 API Key、隐私路径、完整临时日志或生成服务凭据写入仓库。

## 8. 风险与回退

| 风险 | 影响 | 回退 / 处理 |
| --- | --- | --- |
| 动态命中在 WebView/Windows 上不可稳定实现 | Runtime P0 | 停止 Runtime 轨道，移除沙盒进程，不降级为永久矩形命中 |
| Tauri 沙盒触碰正式配置或窗口 | 主线隔离失效 | 立即停止并清理沙盒状态，正式产品文件不得修改 |
| 五动作身份、尺度或边界不稳定 | Quality P0 | 保持 `review_pending/ready:false`，停止扩动作，转绑定或手工关键帧 |
| 旧 S4.3 ready 被误当新样片通过 | 错误发布判断 | 新候选使用独立 manifest、哈希和审查状态，不继承 ready |
| 自动指标替代人工观感 | 粗糙动画误通过 | 自动通过只允许进入人工审查，不得直接 `PetManager ready` |

## 9. 开放问题

- 首次公开宠物、默认开关、业务事件开关和 AI provenance 仍由 `PET-DEC-001` 至 `PET-DEC-004` 管理；本轮不冻结。`PET-DEC-005` 已关闭：不执行 `working_pounce` MiniMax 实验。
