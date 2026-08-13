# LetsMakeMoney Windows v1.1.0

> 状态：本地候选（干净提交）最终验收中，未发布。公开版本固定为 `v1.1.0`。

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

## 已淘汰候选身份

- 发布源提交：`d9d51cfe2ca8b90d8b3adfbf423f346d814092cd`，构建时工作树 clean。
- Candidate ID：`V110-20260812T163314Z-d9d51cfe-clean`。
- Zip SHA256：`B7D7A6E1D4D094A9C01F07EB83791C3C90A631666AC8ED1A1A8150474F190671`。
- EXE SHA256：`4A674A7E121E6DD30B87AB5AF9FC49F1AE681C88F9E2D7963FF30C29C9AD1177`。
- WebView2Loader.dll SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。

该候选在 125% DPI 验收中暴露 `V110-BUG-001`，仅作为历史缺陷证据保留，不得发布。最终候选身份将在修复提交完成干净构建后写入。

## 事实边界

- v1.0.8 tag 保持为 v1.0 系列本地收官基线。
- 100% DPI 核心 GUI、动态命中、sleeping 单击矩阵和 30 分钟连续观感已在上述干净候选通过。
- 长按反向拖拽、125%/150% DPI、Windows 通知区和其余基础状态仍待补证；两小时稳定运行已通过。
- 未完成 [发布检查](release-checklist.md) 前，不得推送、打 tag 或创建 GitHub Release。
