# pet-return Spike 开发日志

## 基本信息

- 版本：内部代号 `pet-return`
- 对应 PRD：[pet-return-prd.md](./pet-return-prd.md)
- 对应 dev plan：[pet-return-dev-plan.md](./pet-return-dev-plan.md)
- 对应 progress：[pet-return-progress.md](./pet-return-progress.md)
- 当前阶段：实施 / 双轨 Spike

## 开发记录

### 2026-08-10 / 双轨启动

- 本轮目标：并行验证 Runtime 与 Quality 两项承重假设。
- 改动模块：仅允许 LMM Runtime 隔离沙盒、PetManager Quality 隔离工作区和本组追踪文档。
- 关键实现：待两轨完成后回写。
- 遇到的问题：LMM 工作树已有未提交的桌宠架构文档和原型；不得覆盖或误计为本轮代码实现。
- 处理方式：锁定基线并限定两轨写入范围；正式应用目录保持只读。
- 已验证：两个仓库分支、HEAD 和初始 dirty 状态。
- 未验证 / 待补证：Runtime 输入压力、真实穿透、DPI 与两小时稳定运行。
- 关联 Spike：Runtime Spike、Quality Spike。

## Spike / 技术探索摘要

| 主题 | 当前结论 | 是否进入正式产品 | 后续动作 |
| --- | --- | --- | --- |
| 独立透明 WebView Runtime | 进行中 | 否 | 完成 P0 验证后再判断 |
| Classic 五动作质量路线 | PetManager ready | 否 | 等待 Runtime 独立通过后进入隔离沙盒联调 |

### 2026-08-10 / Runtime Spike 实施

- 测试先行：建立逐帧时钟、输入仲裁、动态命中、旧包适配、状态实例、故障隔离和 Tauri 表面合同测试。
- 失败尝试：相对调度在 138.322 秒内累积 1447.6ms 漂移，并错误触发 loop timeout。
- 修正：改为绝对帧截止时间，loop 不使用 oneshot 超时；新增 60 秒同步帧工作回归。
- 验证：33/33 Node、6/6 Rust、fmt、clippy、build 通过；短时透明窗口真实运行的最大漂移为 2ms。
- 真实输入修正：旧局部坐标实现把左拖误判为右；切换为屏幕坐标后，真实右拖、左拖、释放收势和基础状态恢复均通过单轮复验。
- 生命周期：60 秒隐藏期间 timer 为 0，恢复后 timer 为 1，权威 revision 更新且无 P0 故障。
- 结论：`LMM sandbox pass = false（部分通过）`；等待输入压力矩阵、透明像素真实穿透、真实 DPI 与两小时补证。

### 2026-08-10 / Quality Spike 实施

- 路线：只使用 Classic 已批准透明历史帧进行手工关键帧筛选和确定性标准化；未调用 MiniMax 或 imagegen。
- 产物：五动作、vNext 沙盒 manifest、atlas、alpha RLE hit mask、GIF、Contact Sheet、边界图和审查页。
- S1 人工结论：因整体粗糙和 `run_stop` 无动作依据的整只角色放大被项目所有者拒绝；旧实现实际使用 `1.05 -> 1.43` 缩放且 QA 错误写死为 `0%`。
- S2 定向重制：归档 S1 原始证据，移除所有整体缩放；S2a 因末帧角色偏小内部淘汰；最终 S2 以反向 `run_prepare` 关键姿态构建 8 帧收势，并用统一画布与真实 alpha bbox 重建 QA。
- S2 人工结论：五组动画均存在脱离主体的低透明碎片和蓝紫色边缘哑光，项目所有者拒绝该候选；根因来自历史源帧残留和 GIF 对半透明污染的调色板量化放大。
- S2.1 定向修复：不改变动作、姿态和时序；保留最大 alpha 连通主体，清理轮廓带哑光和整幅高置信度色键残留，保留原 alpha，并用 APNG 作为权威动态预览。S2 原始证据归档到 `attempts/s2-user-edge-rejected/`。
- S2.1 人工结论：项目所有者确认整体质量有所改善，但侧身跑动直接切到正面收势仍不自然，因此只记录为继续精修，不判定通过；完整证据归档到 `attempts/s2.1-edge-cleaned-direction-pending/`。
- S2.2 定向精修：锁定 working 动作与 S2.1 清边结果；使用 5 帧既有侧身减速姿态连接 8 帧正面落稳姿态，并将完整链反向作为 `run_prepare`。修复 APNG disposal 造成的循环边界透明闪帧。
- 左右覆盖补正：原审查页只展示右向链，不能证明 `mirrorSafe` 的实际观感。现保留一套右向素材，由运行时水平镜像得到左向画面和命中区，并在审查页同时展示左右 APNG 与关键姿态对照。
- 项目所有者签核：确认 S2.2 当前整体动画质量、边缘清理、拖拽衔接和左右方向表现通过；签核写入独立 `review-decision.json`。
- 验证：14/14 Quality 测试、167/167 PetManager 全量回归通过；左向逐帧等于右向精确水平镜像且帧数、时长一致；五动作均为 0 脱离主体组件、0 边缘哑光像素和 0 色键残留；重新生成后签核状态保持一致且 `published:false`。
- 证据边界：项目所有者使用整体签核，未单独保存逐动作数值评分表或计时录屏；这些不得被补造成自动证据。
- 结论：`PetManager ready = true（仅限 S2.2 Classic 五动作黄金样片）`；候选为 `approved / ready:true / published:false`。

## Spike / 技术探索最终摘要

| 主题 | 当前结论 | 是否进入正式产品 | 后续动作 |
| --- | --- | --- | --- |
| 独立透明 WebView Runtime | S1.9、隔离 G8 与产品化准备均已通过 | 否 | 保留历史门禁，等待完整动作目录 |
| Classic 五动作质量路线 | S1、S2 人工拒绝；S2.1 继续精修；S2.2 已通过 | 否 | 扩展 rest/sleep、业务事件与低重复编排 |

### 2026-08-10 / Runtime 最终桌面验收

- 候选身份：`main@40f3d5047024d0833dccb2b3638520d5ab9835ea`；EXE SHA256 `93EE5B28CED6A12A6A584565C5A78B9B7C71B4F19967B560EA2BA364A0975F8F`。
- 输入压力：`working` 10/10、`awake_rest` 10/10、`sleeping` 至少 10 次有效单击通过；右向和左向拖拽各 5/5；菜单锁、连续 10 次单击和拖拽后立即单击通过。
- 命中：透明点实际穿透到底层 Notepad；可见点由 Runtime 接收，主链路通过。
- P0：真实 Windows 从 100% 切换到 125% 时触发 `hitmask_latency_exceeded_frame_duration`。沙盒请求安全回退、停止 Runtime、清空 timer 并隐藏窗口。
- 停止：按 P0 规则没有继续 150% DPI 和两小时稳定运行；不得把未执行项写成通过。
- 环境：显示缩放恢复为 100%，Runtime WebView DPR 恢复为 1；沙盒随后停止。
- 诊断缺口：节流后的日志没有保存失败时的精确 native latency、frame duration 和 DPR 代次；S1.1 必须补齐。
- 结论：`LMM sandbox pass = false（未通过）`。Quality S2.2 签核独立保留，不进入产品联调。

### 2026-08-10 / Runtime S1.1 DPI 定向修复

- 测试先行：补充 DPI transition watcher 与命中协调器测试，覆盖 1→1.25→1.5 代际、同倍率帧不延迟收敛、隐藏取消、旧请求晚到、最新帧合并、首个转场慢调用单次重试和第二次慢调用完整 P0 诊断。
- 实现范围：仅修改隔离 Runtime 沙盒；加入 250ms 收敛窗口、generation、按倍率重复原生探针、隐藏取消以及状态探针。未修改 `apps/windows-v1/`、默认配置或产品入口。
- 自动验证：41/41 Node、6/6 Rust、fmt、clippy、build 与 `git diff --check` 通过。候选 SHA256 为 `AAFEDDFDAF6A83098EA96D8507119F46F461EE3FDB64D5E86395146A01440749`。
- 真实复验：100% 初始稳定；切换 125% 时，scale 1 / generation 0 的 `working_loop-009` 原生调用耗时 291ms，超过 90ms 帧时长并触发 P0。1→1.25 的 DPR 事件在 P0 后 19ms 才到达。
- 根因收敛：S1.1 可处理 DPI 通知之后的旧代请求，但 Windows/WebView 在原生调用阻塞结束后才投递 resize/DPR 事件，通知前的慢调用仍被当作普通 P0。该结论来自事件顺序；不等于证明所有 291ms 均由 DPI API 本身占用。
- 停止：未继续 150% 与两小时稳定运行。系统缩放已通过 UI Automation 恢复为 100%，Runtime 与 Settings 进程均已停止。
- 结论：S1.1 自动合同成立，但真实门禁仍失败；`LMM sandbox pass = false`。下一次修改前必须先评审 S1.2 延迟分类方案，不得直接提高全局 latency 阈值。

### 2026-08-10 / Runtime S1.5 持续运行失败

- S1.5 通过真实 100%→125%→150%→100% 循环，确认有真实 DPR 事件时可安全接管旧倍率慢调用。
- 100% 下持续播放约 14 分 42 秒后，`working_loop-007` 的原生命中调用耗时 494ms，超过 120ms 帧时长且没有 DPI 转场，正确触发 P0。
- 沙盒 fail-closed 有效：窗口隐藏、timer 清零、未继续两小时门禁。没有把普通慢调用错误归类为 DPI。
- 结论：失败原因由 DPI 事件顺序进一步收敛到普通帧的同步区域更新、可见提交顺序和背压。

### 2026-08-10 / Runtime S1.6 最终通过

- 测试先行：新增普通帧背压、离屏准备、原生区域优先可见提交、DPI/暂停丢弃 pending frame、稳定性采样器 P0 快速中止和精确日志偏移测试。
- 实现边界：仅修改隔离 Runtime；未修改 `apps/windows-v1/`、正式配置、入口或 current gate。
- 候选身份：EXE 11,196,416 字节，SHA256 `65E993C5BF062F1CE7EDFEECAFA592326532FA8E3A971416C8E8B6EF5640A86D`。
- 自动验证：51/51 Node、7/7 Rust、fmt、clippy、build、`git diff --check` 与 v1.0.8 current gate 全部通过。
- DPI：同一候选执行两轮 100%→125%→150%→100%，共 6 次真实转换通过；最终 DPR 1、generation 6、1 个 timer、无 pending frame、无 P0。
- 稳定运行：7202.594 秒、121 个样本、P0 0。工作集与私有内存均下降，句柄和线程起止不变，原生命中 1-6ms，可见提交 2.5-7.6ms。
- 遥测债：两小时开始前已有约 4011ms 固定偏移，期间未增长；保留为观测准确性问题，不改写为零漂移。
- 视觉证据限制：125%/150% 截图被 Settings 遮挡并已拒绝；真实倍率状态和原生探针有效，产品级验收需重拍无遮挡截图。
- 结论：`Runtime Spike pass = true`；因无电脑 S2.2 尚未执行 G8，`LMM sandbox pass = false`；`Product return approved = false`。

### 2026-08-10 / 旧电脑素材边界

- Runtime Spike 使用的 Classic S4.3 旧夹具包含电脑动画。项目所有者明确表示不满意，后续可能替换。
- 该夹具继续标记为 `runtime_only / vNextReady:false / productMaterialApproved:false`，只证明播放器能力，不得进入正式素材或产品联调。
- Quality S2.2 五动作本身不含电脑道具，仍保持 `PetManager ready = true`。下一轮联调必须以 S2.2 无电脑包为输入。

### 2026-08-11 / S2.2 vNext G8 与普通帧 P0

- 输入身份：Runtime EXE 12,703,744 字节，SHA256 `9A0590CFFD6696A7E001CFA1A8C4B8833A9B06540C84514277BAF7D099040EFD`；S2.2 包 `0.2.0-sandbox.4`，包树 SHA256 `250962401E536E166B66C16CC2B25C7149455466226927699522A91BA40173B6`。
- 运行时已直接消费无电脑五动作 vNext；旧 S4.3 前端副本移入 historical，未进入正式产品目录。
- 自动结果：Node 58/58、Rust 7/7、fmt、clippy、build 与 v1.0.8 current gate 通过。
- 真实交互：单击、左右拖拽、完整 `run_stop`、隐藏/恢复通过；没有电脑动画或拖拽比例突变。
- 定时门禁：7203.8 秒、121 样本、观察窗内 P0 0；工作集 +466,944 字节、私有内存 +425,984 字节、句柄 360→360、线程 29→26。
- 新失败：观察窗结束后、尚未修改 DPI 时，`working_play_loop_a-013` 的 `SetWindowRgn` 路径耗时 1610ms，超过 150ms 帧时长和 750ms 宽限，触发普通帧 P0。
- fail-closed：请求安全回退、清空 timer、隐藏窗口；125%/150% 和坏包桌面注入按停止规则未继续。
- 结论：`PetManager ready = true`、`Runtime Spike pass = true` 保持独立成立；`LMM sandbox pass = false`、`Product return approved = false`。下一步只调查普通帧原生命中延迟，不扩动作、不恢复产品入口。

### 2026-08-11 / Runtime S1.9 与 G8 最终签核

- 根因处理：普通帧不再同步调用 `SetWindowRgn`。Runtime 保留逐帧 alpha mask，由 8ms 原生指针轮询根据全局指针所在像素切换顶层 `WS_EX_TRANSPARENT`；鼠标按键按下期间冻结切换，未使用永久矩形命中，也未放宽普通帧 P0 阈值。
- 锁定候选：`pet-return-runtime-spike-s1.9-cursor-passthrough.exe`，8,856,576 字节，SHA256 `39F6DA5D191178CD0A74BCEDB71CDB39A5BAD69FC7A2DF7AF8E7A8471A1CC395`。
- 自动验证：Node 60/60、Rust 12/12、fmt、clippy `-D warnings`、release build、`git diff --check` 与 v1.0.8 current gate 全部通过；正式产品代码和入口未修改。
- DPI 与命中：100%、125%、150% 下均证明可见像素由 Runtime 接收、透明像素穿透到底层 Calculator；最终恢复 Windows 100% / 96 DPI。
- 坏包：坏 manifest 以 `manifest_hash_mismatch`、坏 atlas 以 `file_hash_mismatch` 安全降级，timer 为 0，主线健康；恢复有效包后正常收敛。
- 稳定性：7203.7 秒、121 个一分钟样本、P0 0；工作集增加 1,396,736 字节、私有内存增加 1,945,600 字节、句柄 368→369、线程 36→29，未见加速增长。
- 原失败条件复验：观察窗后两次打开并保持 Windows 显示设置，普通帧原生耗时最大 1378us，P0 和错误事件均为 0；尾状态为 `working / base_loop / idle / visible`。
- 构建身份边界：干净 release 重链通过，但输出为 8,863,232 字节、SHA256 `FED0432F9DF41CD4D86419078F25B0FCFCE2AD9CCC75650BFAF46A4B88C1EE59`，不能逐字节复现 GUI 已验收候选，因此不得替换锁定 SHA256。
- 已知产品化债务：窗口隐藏期间 8ms timer 尚未暂停；`WM_TIMER` 回调错误尚未形成诊断事件；MSVC 重链不可逐字节复现；五动作黄金样片不能证明完整动作目录和长期低重复编排。
- 分层结论：`PetManager ready = true（仅 Classic S2.2 五动作）`；`Runtime Spike pass = true`；`LMM sandbox pass = true（仅隔离 G8 承重范围）`；`Product return approved = false`；正式产品入口不得启用。

### 2026-08-11 / Runtime 产品化准备补强

- 范围：只修改 `spikes/pet-return-runtime` 和桌宠专项证据文档；正式 `apps/windows-v1`、产品入口、默认配置与 current gate 均未修改。
- 测试先行：先增加隐藏暂停、恢复单 timer、恢复补偿、原生轮询故障、诊断锁异常和确定性链接合同的失败测试，再完成实现。
- 生命周期：隐藏前停止原生 8ms 指针 timer 并强制顶层点击穿透；恢复时立即刷新并最多启动一个 timer。若 show、原生恢复或前端 shown 事件任一步失败，会重新暂停并隐藏窗口，记录 `window_restore_failed`。
- 原生错误：`WM_TIMER` 不再丢弃 `refresh_pointer_passthrough` 错误。故障会停止 timer、锁存 `failed_closed`、保留 `last_error`、强制点击穿透，并通过 `hit_test_bridge_failed_closed` 和 P0 IPC 错误上报。诊断锁中毒时使用固定兜底原因，不能把失败状态误判为健康。
- 真实 Win32 证据：集成测试创建隐藏 `STATIC` HWND，验证安装后 polling active、隐藏后 inactive、恢复后 active；注入原生刷新失败后 timer 停止、顶层穿透和 failed-closed 全部成立，且失败桥不能重新启动。
- 构建调查：未启用 `/Brepro` 的两次干净同路径构建大小均为 8,957,952 字节，但 SHA256 分别为 `D4BDF2678C330D4936A61B8C87D6724A10E09CEEB501B7FC46B8F8B116986911` 与 `B455CA93C0777D65522577C1A824EECA38187E75B4069F794BAD37E7D5862452`。二进制仅 24 字节不同，来源为四组 PE/调试时间戳和一个 RSDS/PDB GUID，不是代码或资源差异。
- 可复现修正：在沙盒 `src-tauri/.cargo/config.toml` 固定 MSVC `/Brepro`。两次干净构建与随后不设置环境变量的默认构建均得到 8,957,952 字节、SHA256 `E371145962A85145E5922939ED1E68A735772DFA2E8308B91C3C4AB37D1FF461`，逐字节一致。
- 构建插曲：首次 release build 被仍在运行的沙盒进程 PID 31592 锁定；只停止该沙盒进程后，同一构建通过。该事件作为过程证据保留，不改写为首次成功。
- 自动验证：Node 60/60、Rust 16/16、`cargo fmt --check`、clippy `-D warnings` 和 release build 通过。
- 桌面观察：确定性候选在 192x208 透明窗口中正确渲染 Classic。快捷键 `H` 因点击穿透窗口未可靠取得键盘焦点，没有产生新隐藏事件，证据不可判定；不记通过，也不覆盖真实 HWND 集成测试和既有成对 hidden/shown 日志。
- 身份边界：S1.9 锁定候选 `39F6...CC395` 继续作为完整 G8 历史证据；新确定性构建只证明产品化补强和构建合同，不替换旧候选身份，也未重跑全部 G8。
- 结论：隐藏 timer、原生错误诊断和沙盒构建可复现性三项工程债已关闭。完整动作目录、正式入口与公开决策仍未关闭，故 `Product return approved = false`。
- 结构化证据：`spikes/pet-return-runtime/evidence/acceptance/runtime-productization-prep-20260811.json`。

### 2026-08-11 / 完整动作目录 Batch A

- 候选：PetManager `S3-Batch-A`，范围为 `awake_rest_loop`、`rest_ack`、`sleeping_loop`、`sleep_twitch`、`sleep_ack`。
- 生产边界：只从已批准透明源素材中确定性筛选和标准化；未调用 imagegen、MiniMax 或视频生成，未使用电脑、键盘、显示器及旧午休道具动作。
- 测试先行：先将目录状态和人工决定门禁改为红灯，再实现独立 `review-decision.json` 校验。生成器会验证候选、范围、批准者、完整目录关闭状态及每个动作实际几何预警，防止决定漂移。
- 自动结果：目录测试 8/8 通过；S2.2 五个锁定动作逐文件哈希不变；Batch A 的脚底线、空帧、脱离主体碎片和边缘残留门禁通过。
- 自动预警：`rest_ack`、`sleeping_loop`、`sleep_ack` 存在由真实姿态变化产生的头部或整体相邻尺度预警，未由自动测试替代肉眼判定。
- 人工决定：项目所有者检查审查页、真实时长动画、逐帧图及状态边界后回复“可以”，批准本批次并接受上述预警。
- 状态：`approved / batchReady:true / catalogReady:false / ready:false / published:false`。完整目录仍有九个动作未生产，`Product return approved = false`。
- 证据入口：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/review.html`、`review-decision.json`、`qa/catalog-evidence.json`。

### 2026-08-11 / 完整动作目录 Batch B 候选（历史状态，后续已收敛）

- 候选：PetManager `S3-Batch-B`，原计划范围为 `working_play_loop_b`、`working_observe`、`working_pounce`。
- 来源：分别复用已通过历史标准视觉 QA 的 `running`、`review`、`jumping` 透明动作行；只执行确定性标准化，未调用图像或视频生成。
- 自动结果：`working_play_loop_b` 与 `working_observe` 的脚底线漂移、尺度连续性、空帧、碎片和边缘残留均通过，进入项目所有者视觉审查。
- 失败证据：`working_pounce` 的头部与角色最大相邻尺度变化分别为 42.105% 和 40.909%；在锁定画布内放大将裁切，故在人工批准前退回 `generation_required`，保留拒绝边界图和完整失败链。
- 防误批准：Batch B 的 `reviewScope` 仅包含两个有效候选，`blockedScope` 明确包含 `working_pounce`；即使两个候选获批，批次仍保持 `batchReady:false`，直到扑跳动作被可信替换并单独复审。
- 验证：PetManager 核心 167/167、Quality 14/14、目录 10/10 通过；连续两次生成的 151 个文件 SHA256 全部一致；Batch A 决定与 S2.2 锁定帧未改变。
- 项目所有者决定：`working_play_loop_b` 与 `working_observe` 已于 2026-08-11 获限定批准；结构化决定为 `review-decision-batch-b.json`，`reviewedActionsReady:true`。
- 当时主目录状态：`approved / reviewedActionsReady:true / batchBReady:false / catalogReady:false / published:false`。该快照已被 2026-08-12 的退役决定取代；批准不包含 `working_pounce`，不改变完整目录和产品回归门禁。
- 证据入口：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/review.html`、`qa/batch-b-contact-sheet.png`、`qa/working-boundary-transitions.png`、`qa/rejected-working-pounce-boundary.png`。

### 2026-08-11 / `working_pounce` 隔离重建候选（历史状态，后续已退役）

- 候选：PetManager `S3-Batch-B-Pounce-Rebuild`，独立于当前 Batch B，不覆盖旧 `jumping` 失败证据。
- 路线：仅按原始像素复用已批准 S2.2 的 `run_prepare`、单帧 `run_loop` 高点和 `run_stop`，不重绘、不缩放、不调用 imagegen 或 MiniMax。
- 结果：25 帧、1785ms；脚底线漂移 0px，空帧、脱离主体碎片和边缘残留均为 0；最大相邻头部与角色尺度变化分别为 23.404% 和 23.022%。
- 验证：独立测试 8/8 通过；与既有目录 10/10、Quality 14/14、核心 167/167 合计 199 项通过；同一输入连续重建后 37 个生成文件 SHA256 全部一致。
- 当时状态：`review_pending / hardGate:pass / semanticGate:human_review_required / batchBReady:false / published:false`。该快照已被 2026-08-12 的 `rejected / retiredFromCatalog:true` 决定取代。
- 证据入口：`projects/letsmakemoney-classic-pro/workspace/pet-return-action-catalog/pounce-rebuild/review.html`、`qa/pounce-contact-sheet.png`、`qa/pounce-boundary-transitions.png`、`qa/working-pounce-interaction-chain.png`。
- 停止条件：若真实时长预览更像短跑、拖拽动作复用、缩放或形变，停止当前复用路线并转新分层关键帧或绑定生产。

### 2026-08-12 / Batch B 陪伴语义收敛

- 产品决定：`working` 只表示用户工作期间的安静陪伴，不要求小猫表演工作、扑跳或跑动。
- 人工结论：`working_play_loop_b` 与 `working_observe` 保持批准；两者分别承担低干扰玩耍与陪伴观察。
- 退役决定：`working_pounce` 即使通过隔离重建的自动硬门禁，仍因与陪伴语义不符被拒绝并从必需目录退役；无需补做替代动作。
- 输入边界：`run_prepare`、`run_loop`、`run_stop` 继续只服务 500ms 长按拖拽，工作态调度器不得调用。
- 当前状态：`batch_b_approved / batchBReady:true / catalogReady:false / published:false`；完整目录由 19 项收敛为 18 项，仍缺 `rest_groom`、`rest_stretch`、`work_start`、`break_relief`、`break_return`、`work_end_celebrate` 六项。
- 证据入口：主目录 `review-decision-batch-b.json`；退役证据 `pounce-rebuild/review-decision.json` 与 `pounce-rebuild/review.html`。
- 历史保留：2026-08-11 的尺度失败和隔离重建记录继续作为负向证据，不回写为通过，也不删除失败产物。

## 收尾事项

- 文档同步：完成后只更新两份既有 Spike 文档、progress 与本文。
- 发布说明：不适用。
- 回滚方式：删除独立沙盒/候选工作区即可，正式产品不应发生行为变化。
- 下一阶段建议：进入完整动作目录质量阶段，补齐 rest/sleep、业务事件与低重复产品编排；不得因 Runtime 工程债关闭而直接恢复正式入口。

### 2026-08-12 / 首轮 12 动作精简目录与加载兼容

- 范围决定：项目所有者接受质量优先降级。`rest_groom`、`rest_stretch` 和四个业务事件动作继续延后；`working_pounce` 保持退役。首轮只使用 12 个已经获批的基础、互动、环境和拖拽动作。
- 生产：PetManager 新增确定性打包器，只读取既有批准帧，生成 lossless WebP atlas、逐帧 alpha RLE hit mask、manifest、包索引及净化来源/许可/provenance。没有调用 imagegen、MiniMax 或视频生成。
- 身份：12 动作、118 帧；manifest SHA256 `73A722D022EB4138B5FA8F7469D5304F08DC026EB3CB98D480A9C56CAE911E0E`；包树 SHA256 `745AB4A26B4B149FC279686D9FA236384BDDF150DF2D18C2DBDA643A1A596A4E`。
- 编排：working、awake_rest、sleeping 分别以固定种子执行至少 30 分钟虚拟调度，违规为 0；左向拖拽为右向帧的精确水平镜像。该证据不冒充真人连续观看。
- LMM：包被机械复制到隔离 fixture。加载器保留旧五动作默认合同，并增加显式动作范围；新包 3/3 测试通过，完整 Node 行为测试 63/63 通过。旧五动作预期会拒绝扩展包，不能静默漏检。
- 分层结论：`PetManager reduced-scope ready = true`；`LMM loader compatibility = pass`；`LMM first-return desktop sandbox pass = false`；`Product return approved = false`。
- 下一步：只允许以锁定 12 动作包执行真实桌面 30 分钟观感、点击/500ms 拖拽、三档 DPI、动态命中、坏包和两小时稳定性；继续禁止正式入口、默认配置和发布包接入。

### 2026-08-12 / 三基础状态桌面门禁

- 范围：只增加隔离沙盒验收控制器和两项行为测试，未修改正式产品入口、默认配置或 current gate。
- 控制：数字键 1/2/3 保留为辅助切态入口；透明 WebView 在 Computer Use 下未可靠获得键盘焦点，因此真实证据使用仅限沙盒的中键循环，不将其定义为正式交互。
- 真实链路：进程 `32272` 完成 `working:r1 -> awake_rest:r2 -> sleeping:r3 -> working:r4`；三次请求均接受，拒绝为 0。
- 状态反馈：`rest_ack`、`sleep_ack`、`working_ack` 各播放一次，Frame Player 实际时长分别为 960.1ms、1321.7ms 和 961.5ms，完成后分别恢复 `awake_rest_loop`、`sleeping_loop` 和 `working_play_loop_a`。
- 自动验证：Node 76/76、Rust 19/19、fmt、clippy `-D warnings` 和 Release build 通过。候选为 8,948,224 字节，SHA256 `9E9A946CC5D700A99AE16B82339A75407292E71AAC01B923ABC5E6C3EC8738EB`。
- 证据：`spikes/pet-return-runtime/evidence/acceptance/base-state-desktop-20260812.json` 及同目录八张桌面截图；观察窗口 P0/degraded 为 0。
- 结论：三状态与状态化单击恢复门禁关闭。30 分钟人工观感、三档 DPI、坏包和两小时稳定性仍独立待验；`Product return approved = false`。

### 2026-08-12 / 首轮包 30 分钟连续观察

- 对象：同一锁定候选进程 `32272`，EXE SHA256 `9E9A946CC5D700A99AE16B82339A75407292E71AAC01B923ABC5E6C3EC8738EB`，始终位于主屏右下边缘。
- 覆盖：13:48:18 至 14:18:19 依次观察 working、awake_rest、sleeping、working；三次沙盒验收切态均接受。
- 动作分布：working A 294 次、working B 178 次、observe 14 次、awake_rest 74 次、sleeping 150 次、sleep_twitch 6 次。sleep_twitch 按 90 秒冷却低频插入，所有 ambient 均恢复基础循环。
- 视觉：未发现异常放大、边缘残影、透明空帧、状态串台或动作层卡死。一次中键落在透明睡姿像素并穿透到底层窗口，刷新后改点可见身体像素成功切态。
- 稳定性：31/31 个一分钟样本完整，P0 为 0；工作集增加 192,512 字节，私有内存增加 200,704 字节，句柄 395→395，线程 28→28。
- 日志：观察窗增长 658,151 字节，属于沙盒逐帧证据模式；正式产品不得直接沿用该日志密度。
- 证据：`spikes/pet-return-runtime/evidence/acceptance/first-return-30min-observation-20260812.json` 与 `evidence/stability/first-return-30min-20260812/`。
- 结论：`Computer Use 30-minute observation = pass`；项目所有者随后明确回复“完成”，项目所有者观感签核关闭。DPI、坏包、两小时与正式入口在该时点继续关闭。

### 2026-08-12 / 首轮包 DPI 与坏包桌面门禁

- DPI：真实 Windows 100%、125%、150% 均完成可见像素单击和透明像素穿透；物理命中区随 DPR 分别为 192x208、240x260、288x312，最终恢复 100% / 96 DPI，P0 为 0。
- 坏包：manifest 损坏、合同外运行时文件和绑定 atlas 损坏均降级到内嵌安全形状，进程不崩溃；恢复有效包后重新进入 ready 并播放基础循环。
- 隔离：未修改正式产品代码、入口、默认配置或 current gate。
- 证据：`spikes/pet-return-runtime/evidence/acceptance/first-return-dpi-20260812.json`、`spikes/pet-return-runtime/evidence/faults/first-return-corrupt-package-20260812/result.json`。

### 2026-08-12 / 两小时失败历史与心跳采样补强

- `first-return-2h-20260812` 在第 91 个样本前后触发 P0 并停止，保留为失败证据。
- `first-return-2h-retry-20260812T1625` 取得 121 个资源样本且进程仍存活，但前端最后事件停在 18:09:43；旧采样器只看进程与显式 P0，因此误报完成。`runtime-heartbeat-failure.json` 将其明确标为 `samplerFalsePass:true`，不得引用为稳定性通过。
- 后续采样器同时监控前端与原生心跳，任一超时均失败，并保留运行时最终状态与 timer 数量。

### 2026-08-12 / S3 真实睡眠恢复修正

- 负向基线：真实 Windows 睡眠恢复后，桌面切换期间的 `GetCursorPos` 访问拒绝被旧桥错误锁存为永久 fail-closed，触发 P0。
- 修正：仅对可识别的瞬态桌面切换错误保持点击穿透并继续探测；连续成功后记录恢复事件，其他错误仍 fail-closed。
- 复验：真实睡眠约 72.427 秒，24 次瞬态失败后恢复；前端与原生心跳均未停摆，19 个样本完整，进程存活，P0 为 0。`win32Error=1300 / accepted=true` 原始记录保留。
- 证据：`spikes/pet-return-runtime/evidence/stability/s3-transient-fix-20260812T194600/`；随后 `post-s3-smoke-20260812T1955/` 通过隐藏/恢复与方向命中同步。

### 2026-08-12 / 首轮包最终两小时签核

- 候选：9,016,832 字节，SHA256 `2463940CA9AFC0BECD2DB9252F558315FA1AE1CA19CCB89BD480B27BABEB826B`。
- 时长：7266.473 秒，121/121 个一分钟样本；前端、原生心跳均持续，P0 为 0，进程在采样结束时存活。
- 编排：前 30 分钟完成 5 次长按和 1 次隐藏/恢复，31 个状态样本均无 P0；尾态为 `working / base_loop / idle`，Frame Player、调度器和前端心跳各保留 1 个 timer。
- 资源：工作集 +2,330,624 字节，私有内存 +2,560,000 字节，句柄 398→398，线程 37→31，WebView 进程 6→6；后段进入平台期。
- 恢复：三段桌面切换共产生 378 次瞬态游标读取失败，均恢复且未锁存 P0。
- 日志：增加 6,229,207 字节，属于沙盒证据模式；正式产品必须收敛为采样/摘要。
- 最终回归：Node 81/81、Rust 21/21、fmt、clippy、Release build、UTF-8 与 `git diff --check` 全部通过；重建后候选 SHA256 未变化。
- 证据：`spikes/pet-return-runtime/evidence/stability/final-2h-20260812T1959/`。
- 分层结论：`PetManager reduced-scope ready = true`；`LMM first-return desktop sandbox pass = true`；`LMM sandbox pass = true`；`Product return approved = false`；`formal product entry allowed = false`。
