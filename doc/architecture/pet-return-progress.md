# pet-return Spike 进度

## 追踪信息

- 当前状态：Classic 首轮 12 动作已取得 `PetManager reduced-scope ready` 与隔离桌面 `LMM sandbox pass`；项目所有者已批准 Classic-only 本地产品候选，正式主线已打开 Classic 入口并完成 Mini/Pet 严格互斥。产品包仍为 `published:false`，公开发布尚未批准
- 目标版本：内部代号 `pet-return`
- 上游来源：[pet-return-prd.md](./pet-return-prd.md)、[pet-return-dev-plan.md](./pet-return-dev-plan.md)
- 下游承接：补齐同一正式候选的 125%/150% DPI 与两小时发布验收，再决定是否公开发布；A2/C 六动作继续延后
- 对应开发日志：[pet-return-spike-log.md](./pet-return-spike-log.md)
- 当前事实源：本文
- 最后更新：2026-08-12

## 版本目标

- 在默认 Mini、用户显式二选一的边界下，验证 Classic 首轮 12 动作从隔离沙盒进入本地产品候选的完整链路；本阶段不宣称公开发布。

## 总体进度概览

| 里程碑 | 模块 | 状态 | 完成度 |
| --- | --- | --- | --- |
| M0 | 输入与隔离基线 | 已完成 | 4/4 |
| M1 | Runtime Spike | S1.9 最终门禁已通过 | 10/10 |
| M2 | Quality Spike | S2.2 已通过 | 5/5 |
| M3 | 独立门禁与文档回写 | 已完成 | 4/4 |
| M4 | S2.2 vNext G8 | 已通过 | 5/5 |
| M5 | Runtime 产品化准备 | 已完成 | 4/4 |
| M6 | 完整动作目录 | Batch A 与 Batch B 已批准；六个 A2/C 动作待生产 | 3/5 |
| M7 | 首轮精简目录 | 12 动作隔离桌面沙盒已通过 | 5/5 |
| M8 | 正式主线产品候选 | Mini/Pet 互斥、配置 v9、正式 Runtime、安全回落与 Classic 本地入口已完成；发布补证待完成 | 6/7 |

## 模块任务

### M0. 输入与隔离基线

- [x] M0.1 锁定 LMM `main@40f3d5047024d0833dccb2b3638520d5ab9835ea`。
- [x] M0.2 锁定 PetManager `main@7bd83c6eed1fc2fb9f3e153dfbda39ef13f46d92`。
- [x] M0.3 锁定 Runtime fixture 与 Classic 输入哈希。
- [x] M0.4 确认两轨仅写独立工作区。

### M1. Runtime Spike

- [x] M1.1 失败测试与独立应用身份。
- [x] M1.2 逐帧时长和 `animation_finished`。
- [x] M1.3 500ms 长按拖拽与输入仲裁的自动测试。
- [x] M1.4 动态命中、透明窗口和 DPI 坐标测试。
- [x] M1.5 隐藏恢复、坏包回退和主应用隔离的自动测试。
- [x] M1.6 执行真实输入、透明穿透与 DPI 门禁；125% 切换触发 P0，150% 和两小时按停止规则未执行，`LMM sandbox pass` 未签署。
- [x] M1.7 执行 S1.1：增加 DPI 代际、旧 mask 丢弃、最新帧重放、单次转场重试和完整诊断；41/41 Node 与 6/6 Rust 通过，但真实 125% 仍在 DPR 通知前触发 P0。
- [x] M1.8 执行 S1.5：真实三档 DPI 循环通过，但普通 100% 播放约 14 分 42 秒后出现 494ms 原生命中调用并触发 P0；证明需调整呈现顺序和背压。
- [x] M1.9 执行 S1.6：原生区域优先提交、最新帧背压和非同步重绘通过；两轮三档 DPI、2 小时稳定运行、51/51 Node、7/7 Rust 及 v1.0.8 current gate 全部通过，签署 `Runtime Spike pass`。Gate 2 仍等待无电脑 S2.2 的 G8。
- [x] M1.10 执行 S1.9：以逐帧 alpha mask 和 8ms 原生指针轮询切换顶层 `WS_EX_TRANSPARENT`，普通帧不再调用 `SetWindowRgn`；不放宽 P0 阈值，并完成三档 DPI、透明/可见点位、坏包、两小时稳定性及外部 UI 负载复验。

### M2. Quality Spike

- [x] M2.1 五动作 Profile、输入哈希和失败测试。
- [x] M2.2 五动作逐帧候选与标准化。
- [x] M2.3 图集、manifest、GIF、Contact Sheet 和边界图。
- [x] M2.4 自动质量与 provenance 门禁。
- [x] M2.5 项目所有者完成整体视觉审查并签署 `PetManager ready`；未单独保存逐动作数值评分表和计时录屏。

### M3. 独立门禁与回写

- [x] M3.1 核对两轨工作区无越界改动。
- [x] M3.2 更新 Runtime Spike 文档结果。
- [x] M3.3 更新 Quality Spike 文档结果。
- [x] M3.4 输出独立判断并停在人工审查。

### M4. S2.2 vNext G8

- [x] M4.1 将无电脑 S2.2 五动作净化包接入隔离沙盒，旧电脑夹具移入 historical 边界。
- [x] M4.2 完成 Node 58/58、Rust 7/7、fmt、clippy、build 与 v1.0.8 current gate。
- [x] M4.3 完成真实单击、左右拖拽、完整收势、隐藏/恢复及 30 分钟编排动作。
- [x] M4.4 完成 7203.8 秒、121 样本稳定性观察窗，观察窗内 P0 为 0。
- [x] M4.5 三档 DPI、坏 manifest/atlas 桌面注入、7203.7 秒稳定运行及观察窗后的外部 UI 负载均通过；最终签署隔离范围内的 Gate 2。

### M5. Runtime 产品化准备

- [x] M5.1 隐藏窗口时暂停原生 8ms 指针轮询，恢复时立即刷新且最多启动一个 timer；部分恢复失败会重新暂停并隐藏窗口。
- [x] M5.2 `WM_TIMER` 原生轮询失败会停止 timer、强制顶层穿透、锁存 `failed_closed` 并上报一次诊断事件；诊断锁异常也不会解除 fail-closed。
- [x] M5.3 增加真实 Win32 HWND 生命周期集成测试，以及隐藏/恢复、恢复补偿和故障锁存的前后端行为测试。
- [x] M5.4 为隔离沙盒启用 MSVC `/Brepro`；两次干净同路径构建及一次默认配置构建得到相同 SHA256，构建可复现性债务在沙盒范围内关闭。

### M6. 完整动作目录

- [x] M6.1 建立 18 动作目录、批次门禁、来源映射、质量指标和可重复生成审查页。
- [x] M6.2 完成 Batch A：`awake_rest_loop`、`rest_ack`、`sleeping_loop`、`sleep_twitch`、`sleep_ack`，并取得项目所有者批次级批准。
- [x] M6.3 完成 Batch B：`working_play_loop_b` 与 `working_observe` 已获项目所有者批准；`working_pounce` 因与安静陪伴语义不符正式退役且无需补位，批次为 `batchReady:true`。
- [ ] M6.4 完成 Batch A2 与 C：理毛、伸展及四个业务事件动作。
- [ ] M6.5 使用完整目录执行 30 分钟低重复编排和正式产品级质量审查。

### M7. 首轮精简目录

- [x] M7.1 项目所有者接受 12 动作质量优先降级；A2/C 延后，`working_pounce` 保持退役。
- [x] M7.2 从已批准帧确定性生成净化运行时包，锁定 12 动作、118 帧及包树哈希。
- [x] M7.3 对 working、awake_rest、sleeping 各执行 30 分钟固定种子虚拟编排，拖拽左右链使用精确镜像且未引用延后动作。
- [x] M7.4 LMM 隔离加载器兼容 12 动作包，新增 3 项包合同测试，Node 行为测试 63/63 通过。
- [x] M7.5 使用 12 动作包完成真实桌面 G8：右下边缘启动、working A/B 轮播、`working_observe` 冷却、500ms 真实长按、连续方向折返、动态命中同步、三基础状态、状态化单击恢复、项目所有者观感、100%/125%/150% DPI、坏包、真实睡眠恢复和 121 样本两小时稳定运行全部通过。

### M8. 正式主线基础设施

- [x] M8.1 升级配置到 v9，新增 `desktop_companion_mode = mini | pet` 与独立位置字段；新用户、旧配置和非法枚举均安全回落 Mini。
- [x] M8.2 建立 Mini/Pet 原子互斥切换：切换失败回滚原可见状态，Workbench 打开期间隐藏当前陪伴并在关闭后恢复进入前状态，托盘只操作当前陪伴。
- [x] M8.3 将独立 Tauri 透明 WebView、逐帧播放、500ms 输入仲裁、方向切换和逐帧原生命中桥接入正式代码边界；未复用故障注入、心跳或验收快捷键。
- [x] M8.4 锁定 7 项净化运行时文件、12 动作、manifest SHA256 与 package tree SHA256；坏包、运行时失败和持久化失败均 fail closed 并回落 Mini。
- [x] M8.5 完成配置、互斥、包身份、状态感知单击、拖拽、命中桥、生命周期和回落的行为测试；完整 current gate、89 个 Rust 测试、TypeScript、Vite、fmt 与 clippy 通过。
- [x] M8.6 取得 Classic 首轮精简范围的产品候选批准与产品运行时再分发许可，打开本地 Classic 入口，并完成 100% DPI 真实 GUI、互斥切换、Workbench 租约、状态单击、动态命中和拖拽链路验证。
- [ ] M8.7 对同一干净发布候选补齐 125%/150% DPI、两小时稳定运行、托盘与坏包桌面回退，完成后才允许讨论公开发布。

## 当前边界

- Runtime：S1.9 已关闭普通帧同步 `SetWindowRgn` 阻塞，三档 DPI 和原 P0 外部 UI 负载复验均通过；普通帧 P0 阈值未放宽。
- Quality：S2.2 五动作、Batch A 五动作及 Batch B 两个陪伴动作均已获项目所有者明确通过。`working` 是用户工作期间的低干扰陪伴态；旧 `working_pounce` 与隔离重建均作为负向证据保留，不进入目录。完整目录仍有六个动作被质量门禁阻塞，但首轮 12 动作精简范围已经独立 ready。
- 素材：无电脑 S2.2 已用于 G8；旧 S4.3 电脑夹具只保留在 historical，不再作为当前联调输入。
- 沙盒：`LMM sandbox pass = true` 只证明隔离 G8 的承重假设，不等于正式产品入口获批。
- 产品候选：`productReturnApproved:true / published:false`。Settings 可在 Mini 与 Classic 之间显式二选一，新用户、旧配置和故障回落仍为 Mini；产品候选批准不等于公开发布。
- 产品化前工程债：隐藏 timer、`WM_TIMER` 错误诊断和沙盒构建可复现性均已关闭。S1.9 锁定候选仍作为历史 G8 证据保留，不由后续重链产物替换。
- 首轮沙盒：`LMM first-return desktop sandbox pass = true`。12 动作桌面 G8 已关闭，不需要重复执行同一轮 Spike。
- 剩余发布阻塞：当前包为 `approved / ready:true / productReturnApproved:true / published:false`，已完成本地产品候选 100% DPI GUI 验证；同一干净候选的 125%/150% DPI、两小时稳定运行、托盘及坏包桌面回退仍需补证。A2/C 六动作继续延后，不阻塞首轮精简回归范围，但仍阻塞“完整目录 ready”。

## 最近验证

- 验证时间：2026-08-12
- 验证方式：Runtime 桌面证据、PetManager 目录与 Quality 回归、12 动作确定性包、Computer Use、真实 DPI、坏包注入、Windows 睡眠恢复、双心跳采样和最终两小时稳定运行。
- 结果：项目所有者完成观感签核；三基础状态、状态化单击、500ms 拖拽、左右连续折返及画面/命中同步通过；100%/125%/150% DPI 与透明穿透通过；manifest/atlas 损坏安全降级通过；真实睡眠约 72 秒后恢复通过。最终候选 SHA256 `2463940CA9AFC0BECD2DB9252F558315FA1AE1CA19CCB89BD480B27BABEB826B` 连续运行 7266.473 秒，121/121 样本、双心跳持续、P0 为 0，资源后段进入平台期。最终机械回归 Node 81/81、Rust 21/21、fmt、clippy、Release build、UTF-8 与 `git diff --check` 全部通过。
- 证据状态：新测。
- 失效条件：分支、HEAD、dirty 文件或输入包身份变化。

### 正式基础设施机械验证

- 验证时间：2026-08-12。
- 输入包：manifest SHA256 `73A722D022EB4138B5FA8F7469D5304F08DC026EB3CB98D480A9C56CAE911E0E`；package tree SHA256 `745AB4A26B4B149FC279686D9FA236384BDDF150DF2D18C2DBDA643A1A596A4E`。
- 结果：`verify_windows_current.ps1` 通过；桌面陪伴行为 10/10、桌宠基础状态 6/6、正式 Runtime 3/3、包身份与门禁检查通过；Rust 89/89、TypeScript strict、Vite production build、fmt、clippy 和 `git diff --check` 通过。
- 边界：本轮未打开产品元数据门禁，因此没有把正式桌宠窗口 GUI 验收或公开回归写成通过。

### 正式产品候选验证

- 验证时间：2026-08-13。
- 输入包：`0.4.0-rc.1`；manifest SHA256 `9E50542B436D197F0CD5CB8CD7149B6E0C57EE9A12073DF2A2E5B588719992AC`；package tree SHA256 `BC62C560134CD240015ABE742DAFA9E76D80196412C73C60423BD173A3548EA1`；`approved / ready:true / productReturnApproved:true / published:false`。
- 本地 EXE：SHA256 `D1F4E8B006D0A2E0C7091313886CCA4EC3C03F52F51EAD2B19E8744AA7D56A88`，大小 `14,957,568` 字节；该身份来自 dirty 工作树，只能作为本地产品候选证据，不得冒充发布附件。
- 真实 GUI：默认 Mini；Workbench 打开时隐藏当前陪伴；Workbench 打开期间由 Mini 切换 Classic 不死锁，关闭后只恢复 Classic；重启保持 Classic；桌宠可见渲染、`sleep_ack` 完整结束并恢复 `sleeping_loop`；透明区域不接收点击；拖拽日志覆盖 `run_prepare -> run_loop -> run_stop` 与左右方向变化。
- 自动门禁：`verify_windows_current.ps1` 通过；Rust `91/91`、TypeScript/Vite、fmt、clippy、宠物包合同和行为门禁通过。
- 结论：本地产品候选在 Windows 11 单显示器 100% DPI 下部分通过，可进入发布补证；尚未取得公开发布批准。

## 下一步

- 保留所有失败尝试、S1.9 历史候选和最终 12 动作证据，不用后续构建覆盖既有 SHA256 身份。
- 不再重复同一轮沙盒验证。下一阶段仅从干净提交构建锁定候选，补齐 125%/150% DPI、两小时、托盘与坏包桌面回退；不得用旧沙盒证据替代新候选发布验收。
- A2 与业务事件继续延后，不得为凑数量重新启用失败生成路线；当前公开版本继续保持零宠物，Classic 仅处于本地产品候选阶段。

## 记录边界

本文只记录状态、阻塞、验证和下一步；技术排查、失败尝试和实现细节写入 spike log 或各轨 evidence。
