# LetsMakeMoney Windows v1.1.0 验证记录

## 当前结论

v1.1.0 处于本地候选准备阶段，未发布。正式候选身份与哈希尚待从干净提交构建后写入；当前不得判定可发布。

## 候选身份

| 字段 | 当前值 |
| --- | --- |
| 版本 | `1.1.0` |
| 分支 | `main` |
| 发布源 HEAD | 待本地实现提交后锁定 |
| Source tree | 最终构建必须为 clean |
| Candidate ID | 待生成 |
| Zip / EXE / DLL SHA256 | 待生成 |
| 公开发布 | 未发布 |

## 已有先导证据

- 完整 current gate 已在 pet-return 工作树通过：Rust 91/91、TypeScript 行为测试、Vite、fmt、clippy 和宠物包合同均通过。
- 100% DPI 真实 GUI 已验证默认 Mini、Workbench 租约、互斥切换、重启持久化、可见渲染、状态单击、动态命中和左右拖拽。
- 上述 GUI 来自 dirty 工作树 EXE，只能作为实现先导证据，不能替代最终 v1.1.0 候选验收。

## 最终候选待补

- 100%、125%、150% DPI 的同一干净候选。
- Windows 通知区隐藏、恢复、右键菜单与退出。
- Classic 包缺失、哈希错误和 manifest 损坏的桌面回落。
- 30 分钟连续动画观感。
- 两小时稳定运行及 CPU、内存、日志增长。
- 用户配置、日志和系统 DPI 的完整恢复。
