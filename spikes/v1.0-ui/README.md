# v1.0 UI 技术 Spike

本目录保存 LetsMakeMoney Windows v1.0 三条技术路线的隔离样板。

## 目录

- `common/`：三路共用 fixture、设计 token 与黄金路径。
- `tauri-react/`：Rust + Tauri + TypeScript/React 首选候选。
- `winui3/`：C# + WinUI 3 原生对照。
- `godot/`：Godot 4.7 现状基线。
- `evidence/`：本机运行后生成的截图、日志与测量结果；默认不提交大体积运行证据。

## 边界

- 不读取 `%APPDATA%\LetsMakeMoney`。
- 保存操作只写各样板自己的临时目录。
- 不实现宠物。
- 不连接真实更新源。
- 不复用运行截图作为界面图层。
- 所有路线必须使用 `common/` 中完全相同的数据和操作语义。

