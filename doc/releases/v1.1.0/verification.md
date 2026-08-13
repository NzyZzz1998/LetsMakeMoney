# LetsMakeMoney Windows v1.1.0 验证记录

## 当前结论

包含 `V110-BUG-001` 修复的干净提交已重建为最终候选 `V110-20260813T042624Z-7eb9f88d-clean`，current gate、候选包验证、100%/125%/150% DPI 可见性与命中、Windows 通知区左键隐藏/恢复及用户环境恢复均通过。旧候选 `V110-20260812T163314Z-d9d51cfe-clean` 继续明确淘汰，不得发布。

当前结论为“部分通过”。阻塞缺陷本身已关闭，但最终候选仍缺少截图中断拖拽的完整人工复验、托盘右键命令与退出、Settings/Modal 输入锁定三条真实桌面闭环；精确 EXE 内嵌资源损坏没有安全注入入口。`Public release approved` 仍为 `false`，不得据此自动推送、打 tag 或创建 Release。

在最终干净候选之后，新增 `V110-UX-001` 体量重组与 `V110-UX-002` 拖拽合并位移调度。两项已形成 dirty 定向候选并通过自动门禁；远程环境仅确认体量观感改善，不能证明真实本机拖拽手感。因此既有最终干净候选不再覆盖最新代码，新修正也不得因 dirty 候选而进入发布。

## 候选身份

| 字段 | 当前值 |
| --- | --- |
| 版本 | `1.1.0` |
| 分支 | `main` |
| 发布源 HEAD | `7eb9f88d13b8f59e1560bfd8b58cccc8e9501d1f` |
| Source tree | clean |
| Candidate ID | `V110-20260813T042624Z-7eb9f88d-clean` |
| 构建时间（UTC） | `2026-08-13T04:28:26.0756711Z` |
| Zip | `LetsMakeMoney-v1.1.0-windows-x86_64.zip`，6,229,431 字节 |
| Zip SHA256 | `0E6757775658929E89CF158E97FA5AEBBCCA2CEBFB63F35F574F567845AD96A3` |
| EXE | `LetsMakeMoney.exe`，14,818,816 字节 |
| EXE SHA256 | `57478CDC1B307B33815C830DCA608D37BD8F24A7DAFB87983F8B539359492E52` |
| WebView2Loader.dll | 160,320 字节 |
| DLL SHA256 | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |
| 公开发布 | 未发布 |

### 最新定向候选（不可发布）

| 字段 | 当前值 |
| --- | --- |
| Candidate ID | `V110-20260813T055122Z-7eb9f88d-dirty` |
| Source tree | dirty |
| 构建时间（UTC） | `2026-08-13T05:52:54.3661317Z` |
| Zip | 6,570,393 字节；SHA256 `7C37C64DC192F4613AD0006CC3D42C38E99A7D6D50349A79506F7F64B635720F` |
| EXE | 15,360,000 字节；SHA256 `56567550B9AC2A3996FAA0CA089E7D8A08E42142F249C405F6237E039EE4C6B5` |
| DLL | 160,320 字节；SHA256 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |
| 用途 | 仅用于体量与拖拽调度定向复验 |

> 已淘汰候选的 Zip SHA256 为 `B7D7A6E1D4D094A9C01F07EB83791C3C90A631666AC8ED1A1A8150474F190671`，EXE SHA256 为 `4A674A7E121E6DD30B87AB5AF9FC49F1AE681C88F9E2D7963FF30C29C9AD1177`。修复后临时定向复验 EXE SHA256 为 `DD2C372C7EEF6468400C2665AF97F22E87C4B4F079F0F7CF008E7242C10362DA`。两者都不是最终发布对象。

## 自动门禁

- 最终发布源提交上的 `scripts/verify_windows_current.ps1` 通过：Vite、TypeScript strict、Rust fmt、clippy、91/91 Rust tests、宠物运行时行为测试 4/4 和宠物包合同均通过。
- `scripts/package_v110.ps1` 从干净提交生成唯一候选；`scripts/verify_v110_package.ps1 -Mode candidate` 通过，Zip、EXE、DLL、README 和 BUILD-INFO 身份一致。
- npm、Cargo、Tauri、包名、BUILD-INFO 和发布说明均锁定为精确版本 `1.1.0`。
- Classic 正式运行时包 manifest SHA256 为 `9E50542B436D197F0CD5CB8CD7149B6E0C57EE9A12073DF2A2E5B588719992AC`，package tree SHA256 为 `BC62C560134CD240015ABE742DAFA9E76D80196412C73C60423BD173A3548EA1`。
- 隔离坏包夹具覆盖 package index 缺失、非法 JSON 和 manifest 哈希错误，3/3 均安全回退 `embedded_static_shape`。正式 EXE 内嵌资源无法在不重建或注入测试钩子的情况下原位损坏，桌面坏包注入继续标记待补证。

## 真实 GUI 与证据边界

### 最终候选实测

- 只运行新解压目录中的最终候选 EXE；100% DPI 复核可见，125% 与 150% DPI 下 192×208 桌宠窗口均完整显示，无裁切或空白。
- 可见头部/身体点击产生输入事件；透明角落点击不产生宠物输入，逐帧透明命中合同保持有效。
- 桌宠右键菜单三次打开均出现成对的 `pet_input_input_locked source=context-menu` 与 `pet_input_input_unlocked`，未遗留输入锁。
- 使用真实 Windows 通知区左键隐藏和恢复：隐藏时记录 `tray.left_click`、`window_hidden` 与 `dashboard.lifecycle.paused`；恢复时记录 `dashboard.lifecycle.resumed`、`window_shown`、权威同步和主题恢复。右键托盘菜单已真实渲染全部六个入口。
- 系统缩放已恢复到验收前的 100%；备份中的配置、加班记录和日志逐文件 SHA256 与恢复后完全一致；验收结束后 LetsMakeMoney 进程数为 0。

### 定向修复与可继承证据

- 从新解压目录启动精确 EXE，首次配置后默认显示 Mini；Settings 显式切换 Classic 后 Mini 消失，重启后只恢复 Classic。
- Workbench 打开时 Classic 隐藏，关闭后恢复进入前模式。
- 100% DPI 下 sleeping 基础循环稳定；连续单击 10 次均触发 `sleep_ack`，每次约 1320ms 完整结束并恢复 sleeping，无超时或 fallback。
- 受控班次配置将同一候选分别置于 working 与 awake_rest：两个状态各连续单击 10 次，分别得到 10 次 `working_ack` / `rest_ack` 开始事件和 10 次带 `elapsedMs` 的真实完成事件；未出现 `action_timeout`、`runtime_failed` 或 `invalid_state`。
- 完成 5 次真实 Windows 长按拖拽：全部在 500.7–501.2ms 后进入拖拽，覆盖左、右、左转右和右转左；5 次均启动 `run_prepare` 与 `run_stop`，长距离动作进入 `run_loop`，5 次 `run_stop` 均真实完成。拖拽前后单击计数保持 20，无误判。
- 右键菜单输入锁定与释放事件成对出现。
- 可见区域点击产生宠物输入；透明点点击不产生宠物输入，逐帧 hit mask 自动探针同时通过。
- 30 分钟连续观察通过：无动画卡死、比例跳变、边缘残留或高频机械重复；统计为 sleeping_loop 488 次、sleep_ack 10 次、sleep_twitch 21 次，异常事件 0。
- 两小时稳定运行通过：121.02 分钟、121 个一分钟样本，候选进程与 EXE 路径全程一致；进程树工作集为 557.16–567.67 MB，首尾增加 6.64 MB；私有内存为 278.55–289.60 MB，首尾增加 6.61 MB；主进程句柄 401–412、线程 29–33，未出现单调失控。
- 日志按 2,000,000 字节阈值正常轮换至三份备份，总量 6,036,182 字节；全部当前及轮换日志中未发现 panic、fatal、runtime_failed、action_timeout、unhandled 或 invalid_state。
- 125% DPI 定向复验发现并关闭 `V110-BUG-001`：保持拖拽并触发真实 `Win+Shift+S` 后立即产生 `pet_input_drag_released(cancelled:true, reason:window_blur)` 与 `pet_input_interruption_recovered`，完整播放 `run_stop` 后恢复基础状态；随后单击正常触发 `working_ack`，普通长按拖拽也可再次完成，没有重新进入卡死状态。
- idle/基础循环与跑动姿态已通过 `256×208` 逻辑画布和帧级重组改善体量连续性；远程观感确认改善，但抓取点与拖拽手感保持待本机补证。
- 拖拽原生移动改为“单请求在途 + 增量合并”，并在输入中断时清除陈旧位移；行为测试 6/6、91/91 Rust tests、Clippy 和包体审计通过。远程桌面不能作为跟手性通过证据。
- 最新代码再次执行陪伴窗口策略定向回归：Mini/Pet 严格互斥、Workbench 进入前状态恢复、Workbench 打开期间切换重基线等 6 项 Rust 测试全部通过；这属于自动行为证据，不代替托盘与真实窗口人工闭环。
- 当前运行日志继续按 2,000,000 字节阈值保留三份轮换文件，未见失控增长；但基础循环的 `action_started` 与逐帧命中摘要仍较密集，记录为非阻塞诊断噪声债务，不据此宣称存在稳定性故障或内存泄漏。

上述三基础状态单击、5 次 500ms 拖拽、Workbench/Mini 互斥、30 分钟观感和两小时稳定运行来自旧干净候选或同源定向复验载荷。最终提交只修改宠物输入中断恢复并增加行为测试，因此这些未受影响的证据继续保留，但不改写为最终 Zip 的重新实测。

## 待人工补证

- 在最终 Zip 中完成 500ms 长按、方向反转、截图/失焦中断、`run_stop` 和后续再次交互的连续闭环。
- 在本机直接操作环境确认体量切换后的抓取连续性和合并位移后的真实跟手性；当前远程结论仅为“观感改善”。
- 在最终 Zip 中逐项点击托盘右键菜单命令并验证退出后的进程状态；当前仅证明菜单渲染及左键隐藏/恢复。
- Settings/Modal 打开期间的输入锁定及异常关闭后的释放。

## 暂不验证

- Classic 内嵌包缺失、哈希错误和 manifest 损坏的精确 EXE 原位注入：没有不会改变候选身份的安全注入入口。隔离坏包夹具 3/3 通过，正式桌面注入不写成通过。
- 多显示器与 Windows 10：不在本轮已验证环境内。
