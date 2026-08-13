# LetsMakeMoney Windows v1.1.0

> 状态：本地候选正在针对拖拽跟手与动作体量连续性重新构建，尚未完成发布前复验，未发布。公开版本固定为 `v1.1.0`。

v1.1.0 在不改变收入、日历、加班和配置事务口径的前提下，恢复 Classic 橘猫作为可选桌面陪伴。新用户、旧配置和非法值均默认使用 Mini；用户必须在 Settings 中显式选择 Classic，Mini 与 Classic 严格互斥。

## 正式范围

- 独立透明 Tauri WebView 桌宠窗口。
- working、awake_rest、sleeping 三种基础状态。
- 各基础状态独立单击反馈。
- 500ms 长按进入跑动，方向实时切换，释放后完整收势。
- 逐帧时长、真实完成事件、超时与晚到事件保护。
- 逐帧透明命中与透明区域穿透。
- Workbench 打开期间隐藏当前陪伴，关闭或失败后只恢复进入前模式。
- Classic 包校验失败时回落 Mini，不影响收入主线。

## 不进入本版

- 多多、多宠物选择、下载系统、宠物市场。
- 业务事件动作、pointer follow、双击动作。
- Godot 桌宠运行时、PetManager 生产目录和 QA 中间文件。
- 账号、云同步、安装器或静默更新。

## 最终候选身份

- 发布源提交：`7eb9f88d13b8f59e1560bfd8b58cccc8e9501d1f`，构建时工作树 clean。
- Candidate ID：`V110-20260813T042624Z-7eb9f88d-clean`。
- Zip SHA256：`0E6757775658929E89CF158E97FA5AEBBCCA2CEBFB63F35F574F567845AD96A3`。
- EXE SHA256：`57478CDC1B307B33815C830DCA608D37BD8F24A7DAFB87983F8B539359492E52`。
- WebView2Loader.dll SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 公开发布：未授权。

## 已淘汰候选身份

- 发布源提交：`d9d51cfe2ca8b90d8b3adfbf423f346d814092cd`，构建时工作树 clean。
- Candidate ID：`V110-20260812T163314Z-d9d51cfe-clean`。
- Zip SHA256：`B7D7A6E1D4D094A9C01F07EB83791C3C90A631666AC8ED1A1A8150474F190671`。
- EXE SHA256：`4A674A7E121E6DD30B87AB5AF9FC49F1AE681C88F9E2D7963FF30C29C9AD1177`。
- WebView2Loader.dll SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。

该候选在 125% DPI 验收中暴露 `V110-BUG-001`，仅作为历史缺陷证据保留，不得发布。

## 事实边界

- v1.0.8 tag 保持为 v1.0 系列本地收官基线。
- 最终候选的 current gate、包体验证、100%/125%/150% DPI 可见性与透明命中、通知区左键隐藏/恢复和环境恢复通过。
- 截图中断拖拽已在同源定向复验载荷关闭；最终 Zip 的完整人工重复、托盘右键命令/退出及 Settings/Modal 输入锁定仍待补证。
- 三基础状态单击、反向拖拽、30 分钟连续观感和两小时稳定运行保留未受本次输入恢复修改影响的历史证据，不冒充最终 Zip 重新实测。
- 未完成 [发布检查](release-checklist.md) 前，不得推送、打 tag 或创建 GitHub Release。
