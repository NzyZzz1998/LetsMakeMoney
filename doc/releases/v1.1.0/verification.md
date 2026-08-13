# LetsMakeMoney Windows v1.1.0 验证记录

## 当前结论

原干净候选在 125% DPI 验收中发现 `V110-BUG-001`：拖拽期间触发系统截图会因窗口失焦丢失指针结束事件并卡在跑动状态，因此该候选已经淘汰、不得发布。最小修复已完成自动门禁和真实 Windows 125% DPI 定向复验；最终发布候选仍需从包含修复的干净提交重新构建，并补齐 150% DPI、通知区及环境恢复。当前结论仍为“部分通过”。

## 候选身份

| 字段 | 当前值 |
| --- | --- |
| 版本 | `1.1.0` |
| 分支 | `main` |
| 发布源 HEAD | `d9d51cfe2ca8b90d8b3adfbf423f346d814092cd` |
| Source tree | clean |
| Candidate ID | `V110-20260812T163314Z-d9d51cfe-clean` |
| Zip | `LetsMakeMoney-v1.1.0-windows-x86_64.zip`，6,229,202 字节 |
| Zip SHA256 | `B7D7A6E1D4D094A9C01F07EB83791C3C90A631666AC8ED1A1A8150474F190671` |
| EXE | `LetsMakeMoney.exe`，14,818,304 字节 |
| EXE SHA256 | `4A674A7E121E6DD30B87AB5AF9FC49F1AE681C88F9E2D7963FF30C29C9AD1177` |
| WebView2Loader.dll | 160,320 字节 |
| DLL SHA256 | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |
| 公开发布 | 未发布 |

> 上表是已淘汰候选的历史身份，仅用于证明缺陷对应对象。修复后临时 EXE SHA256 为 `DD2C372C7EEF6468400C2665AF97F22E87C4B4F079F0F7CF008E7242C10362DA`，大小 `14,811,648` 字节；它是定向复验载荷，不是最终发布候选。

## 自动门禁

- `scripts/verify_windows_current.ps1` 通过：Vite、TypeScript strict、Rust fmt、clippy、91/91 Rust tests 和宠物包合同均通过。
- `scripts/package_v110.ps1` 从干净提交生成唯一候选；`scripts/verify_v110_package.ps1 -Mode candidate` 两次通过。
- npm、Cargo、Tauri、包名、BUILD-INFO 和发布说明均锁定为精确版本 `1.1.0`。
- Classic 正式运行时包 manifest SHA256 为 `9E50542B436D197F0CD5CB8CD7149B6E0C57EE9A12073DF2A2E5B588719992AC`，package tree SHA256 为 `BC62C560134CD240015ABE742DAFA9E76D80196412C73C60423BD173A3548EA1`。
- 隔离坏包夹具覆盖 package index 缺失、非法 JSON 和 manifest 哈希错误，3/3 均安全回退 `embedded_static_shape`。正式 EXE 内嵌资源无法在不重建或注入测试钩子的情况下原位损坏，桌面坏包注入继续标记待补证。

## 已完成真实 GUI

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
- idle/基础循环与跑动姿态的可见体量、头部位置及抓取点存在明显视觉跳变，登记为 `V110-UX-001` 待优化；本轮没有修改宠物素材或假定该项通过。

## 待补证

- 从包含 `V110-BUG-001` 修复的干净提交重建最终候选，并完成 125% 回归与 150% DPI 验收；旧候选不得复用。
- Windows 通知区隐藏、恢复、右键菜单与退出。
- Classic 包缺失、哈希错误和 manifest 损坏的精确桌面候选注入回落。
- 用户配置、日志和系统 DPI 的完整恢复。
