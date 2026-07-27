# LetsMakeMoney Windows v1.0 高保真产品原型

打开 [index.html](index.html) 可检查 v1.0 无宠物稳定版的产品结构、视觉方向和关键交互。

## 覆盖范围

- 迷你收入视图；
- 今日/日历工作台；
- 三步首次配置 Wizard；
- Settings 的收入与作息、日历、窗口与启动、数据与支持；
- 保存成功、无变化和失败；
- 恢复默认与放弃修改确认；
- 托盘隐藏、驻留与找回；
- 配置失败、诊断摘要、数据目录和更新检查反馈；
- 工作中、午休、非工作日；
- 长金额、长中文和英文；
- normal、hover、focus、pressed、disabled、loading、success、error。

## 说明

- 页面顶部“验证控制条”仅用于切换窗口、业务状态和异常状态，不属于产品界面。
- 正式实现采用 Rust + Tauri + TypeScript/React；WinUI 3 已淘汰，Godot 仅保留为 v0.9 回退基线。
- 原型是结构与视觉事实源，不能以网页截图替代真实控件实现。
- 真实通知区左键、窗口复用和 125%/150% DPI 仍属于开发前平台门禁。
