# LetsMakeMoney Windows v1.1.0

> 状态：自动门禁、本机直接输入验收、最终干净候选重建、包体审计与启动冒烟均已完成，未发布。公开版本固定为 `v1.1.0`。

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

## 最终本地候选身份

- 发布源提交：`71616e2e0ce3e4fb6d687d3115689e7a6ffeb2d1`，构建时工作树 clean。
- Candidate ID：`V110-20260817T031659Z-71616e2e-clean`。
- Zip：`6,727,322` 字节；SHA256 `DA11AAD0928E52DEEBA366E834FBAFD6182CD5F107FCBA01E9BDFA14D1898527`。
- EXE：`15,244,800` 字节；SHA256 `8EAC6B9F277421207D679F55E91AA9E5A535FF8C721E4BF945CBFA9D9123D42C`。
- WebView2Loader.dll SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 公开发布：未授权。

完整本机 GUI 验收使用行为候选 `V110-20260813T081246Z-f5ae4ac3-clean`。最终候选只增加规范化 LF 包身份修复与验收文档，并已完成新解压目录启动冒烟；两类证据分开记录。

## 已淘汰候选身份

- 发布源提交：`d9d51cfe2ca8b90d8b3adfbf423f346d814092cd`，构建时工作树 clean。
- Candidate ID：`V110-20260812T163314Z-d9d51cfe-clean`。
- Zip SHA256：`B7D7A6E1D4D094A9C01F07EB83791C3C90A631666AC8ED1A1A8150474F190671`。
- EXE SHA256：`4A674A7E121E6DD30B87AB5AF9FC49F1AE681C88F9E2D7963FF30C29C9AD1177`。
- WebView2Loader.dll SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。

该候选在 125% DPI 验收中暴露 `V110-BUG-001`，仅作为历史缺陷证据保留，不得发布。

## 事实边界

- v1.0.8 tag 保持为 v1.0 系列本地收官基线。
- 最终候选的 current gate、包体验证、91 项 Rust 测试、Clippy、前端构建及宠物行为测试通过。
- 体量连续性、抓取点、真实拖拽手感和快速左右反转已在本机直接输入环境通过。
- 截图中断拖拽、托盘右键命令/退出及 Settings/Modal 输入锁定已在当前 Zip 完成本机闭环。
- 三基础状态单击、反向拖拽、30 分钟连续观感和两小时稳定运行保留未受本次输入恢复修改影响的历史证据，不冒充最终 Zip 重新实测。
- 最终候选已从包含验收文档和规范化哈希修复的干净提交重建，并锁定身份。
- 未完成 [发布检查](release-checklist.md) 前，不得推送 `main`、打 tag 或创建 GitHub Release；`test` 仅用于继续验收。

## 验收边界

- 当前锁定测试候选的功能与真实 Windows GUI 验收通过。
- 正式 EXE 内嵌坏包没有不改变候选身份的安全桌面注入入口；现有自动隔离夹具 3/3 通过，该项列为暂不验证。
- Windows 10 与多显示器不在本轮已验证环境内。
- 推送 `main`、创建 `v1.1.0` tag 和 GitHub Release 仍需项目所有者单独授权。
