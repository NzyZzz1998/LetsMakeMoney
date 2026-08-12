# LetsMakeMoney Windows v1.1.0

> 状态：本地候选准备中，未发布。公开版本不使用 Beta 后缀。

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

## 事实边界

- v1.0.8 tag 保持为 v1.0 系列本地收官基线。
- 100% DPI 已有先导 GUI 证据来自 dirty 工作树，不代表最终发布包。
- v1.1.0 必须从干净提交重新构建并锁定 Zip、EXE、WebView2Loader.dll 和包内文档哈希。
- 未完成 [发布检查](release-checklist.md) 前，不得推送、打 tag 或创建 GitHub Release。
