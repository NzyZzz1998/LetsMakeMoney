# LetsMakeMoney Windows v1.1.0 进度

## 当前状态

- 版本：`1.1.0`，不使用 Beta 后缀。
- 状态：发布阻塞均已完成代码修复并合入 clean `main`；项目所有者完成真实桌面定向复验并批准推送与创建 `v1.1.0` tag。
- 产品范围：Classic-only 可选桌面陪伴；默认 Mini；严格互斥。
- 当前阻塞：tag 无阻塞。左右边缘各 10 次逐次统计作为已接受的发布后观察风险保留；GitHub Release 尚未授权，附件发布仍冻结。

## 已完成

- PetManager reduced-scope ready。
- LMM Runtime Spike 与 sandbox pass。
- 产品候选获项目所有者批准。
- 100% DPI 先导 GUI 链路通过。
- config v9、运行时、动态命中、拖拽与故障回落实现完成。
- v1.1.0 版本、许可和 current gate 合同已建立。
- 干净发布源提交 `d9d51cfe2ca8b90d8b3adfbf423f346d814092cd` 已生成候选 `V110-20260812T163314Z-d9d51cfe-clean`。
- current gate、候选包验证、100% DPI 核心 GUI、sleeping 单击矩阵、动态命中及 30 分钟观感通过。
- working、awake_rest 与 sleeping 三基础状态各 10 次状态化单击均通过，动作开始、真实完成和基础状态恢复证据完整。
- 5 次真实 500ms 长按拖拽通过，覆盖左右方向与两种快速反向；`run_stop` 5/5 完整结束且无单击误判。
- 两小时稳定运行通过：121 个样本全程存活且路径匹配，工作集与私有内存首尾均仅增加约 6.6 MB，日志轮换受控且无异常事件。
- 自动坏包夹具 3/3 通过；精确桌面候选的内嵌资源损坏注入尚无安全测试入口。
- `V110-BUG-001` 已完成 TDD 修复及真实 Windows 125% DPI 定向复验：截图/失焦中断拖拽后会取消输入、播放 `run_stop` 并允许后续正常点击。
- `V110-UX-001` 已完成帧级体量重组；`V110-UX-002` 已用单请求在途与合并位移调度消除 IPC 队列积压。两项均已在 2026-08-17 本机直接输入验收中通过。
- 最新代码补跑陪伴窗口策略 6/6 与拖拽协调器行为 6/6，Mini/Pet 互斥、Workbench 恢复及中断后清除陈旧位移的自动合同继续成立；真实桌面手感结论不随自动测试升级。
- 日志轮换保持约 2 MB × 当前文件及三份备份的有界策略；基础循环与命中摘要事件偏密已列为非阻塞诊断噪声债务，后续不得与拖拽发布门禁混为一项。
- dirty 定向候选 `V110-20260813T055122Z-7eb9f88d-dirty` 已通过 current gate、91/91 Rust tests、Clippy、release 构建与候选包审计；Zip SHA256 为 `7C37C64DC192F4613AD0006CC3D42C38E99A7D6D50349A79506F7F64B635720F`，EXE SHA256 为 `56567550B9AC2A3996FAA0CA089E7D8A08E42142F249C405F6237E039EE4C6B5`。该候选不可发布。
- 最新修正提交 `f5ae4ac3fcfeef0c3a3c5f321a690b8ed3aa6ab8` 已形成干净测试候选 `V110-20260813T081246Z-f5ae4ac3-clean`；Zip SHA256 为 `E79D3716400D74E9E2F5419700B97630F273AA67761982081AED07E8C87C6EB7`，EXE SHA256 为 `0D02CC9AA628FD7FC66EADFB518E36BFE023689F82581C52F258B75A0694384B`，DLL SHA256 为 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 修复提交 `7eb9f88d13b8f59e1560bfd8b58cccc8e9501d1f` 曾形成既有干净候选 `V110-20260813T042624Z-7eb9f88d-clean`；Zip SHA256 为 `0E6757775658929E89CF158E97FA5AEBBCCA2CEBFB63F35F574F567845AD96A3`，EXE SHA256 为 `57478CDC1B307B33815C830DCA608D37BD8F24A7DAFB87983F8B539359492E52`。
- 完整人工验收候选在 100%、125%、150% DPI 下完整可见，可见/透明命中、输入锁和完整拖拽链路均已通过。
- 真实通知区左键隐藏/恢复、托盘右键菜单六个入口、菜单命令逐项执行和退出均已通过。
- 2026-08-17 本机直接输入补证全部通过：抓取连续性、拖拽跟手、快速左右反向、截图中断恢复、Mini/Classic 互斥、Workbench 协同、Settings/Modal 锁定、托盘命令/退出及 100%/125%/150% DPI 均已闭环。
- 验收结束后系统缩放恢复到 100%，用户配置、加班记录和日志与备份 SHA256 全部一致，进程数为 0。
- `V110-BUG-002` 已关闭：Classic manifest 统一使用仓库规范化 LF 字节计算身份，Python 合同显式拒绝 CRLF；宠物包 Python 门禁及 Rust 定向测试 3/3 通过。
- `V110-BUG-006` 已关闭代码根因：Workbench 补偿阶段原子取得重基后的最新陪伴状态，禁止陈旧 Mini 快照覆盖 Classic。
- `V110-BUG-007` 已关闭代码根因：拖拽完成事务与收起计时器使用独立版本号，原生吸附期间的指针/焦点抖动不再丢弃首次收起。
- clean 修复提交 `00ac5389dcd19d3fc26151a76616ef895f8507e8` 已生成候选 `V110-20260817T114653Z-00ac5389-clean`；Zip SHA256 为 `9071A6676EB85DC990526712C91DDDC654230BF7139BBBEC527FE1BA91B59054`，完整 current gate、93/93 Rust tests、Clippy、前端构建和候选包审计通过。
- 项目所有者从新解压目录实际运行该候选后确认贴边自动隐藏“现在好多了”；首次收起不再依赖额外点击。该结论是定向真实 GUI 证据，不等同于左右各 10 次逐次统计。
- 修复经 PR #31 合入 clean `main`，提交为 `642b0dd3cf5af5347aa9d9d92000f200eafb7850`；CI `Windows v1 verification` 通过。
- clean 候选 `V110-20260817T120916Z-642b0dd3-clean` 已通过 current gate 与候选包身份审计；Zip SHA256 为 `9214B30DE21F8B634766DFE09ED6C5989F87AEF69F61D26805581843B5478118`，EXE SHA256 为 `9F2D770C30DF1C7D67299067114EB8CEE5BB31B041FCDD91435888816047E796`，DLL SHA256 为 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 项目所有者明确表示“这次 bug 基本解决了，可以推送，打 tag 了”；tag 发布授权成立，未授权 GitHub Release。
- 最终修复提交 `71616e2e0ce3e4fb6d687d3115689e7a6ffeb2d1` 已生成候选 `V110-20260817T031659Z-71616e2e-clean`；Zip SHA256 为 `DA11AAD0928E52DEEBA366E834FBAFD6182CD5F107FCBA01E9BDFA14D1898527`，EXE SHA256 为 `8EAC6B9F277421207D679F55E91AA9E5A535FF8C721E4BF945CBFA9D9123D42C`，DLL SHA256 为 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 最终候选通过完整 current gate、91/91 Rust tests、Clippy、前端构建及候选包身份审计，并从新解压目录完成 10 秒启动冒烟；进程路径和 EXE SHA256 与候选一致。

## 下一步

1. 推送包含 `V110-BUG-003` 至 `V110-BUG-007` 的修复与真实验收记录。
2. 从推送后的干净提交重新构建并锁定 Zip、EXE、DLL、manifest 与 package tree 身份。
3. 发布前如需升级为 Stable，再补齐左右贴边逐次统计和最终授权。
