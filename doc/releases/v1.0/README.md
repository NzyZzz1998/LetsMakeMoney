# LetsMakeMoney Windows v1.0 文档入口

v1.0 是首个 Stable 候选版本，使用 Rust、Tauri 与 React 重建 Windows 客户端，并暂时完整下线用户可见的宠物能力。

## 当前状态

- 阶段：M7 Acceptance。
- 结论：验收通过，可进入 Stable 发布收口。
- 已完成：业务实现、自动门禁、便携包验证、100% DPI 核心 GUI 验收和 v0.9 回退验证。
- 已完成：真实 100%/125%/150% DPI、通知区左键、Explorer 重启和核心黄金路径。
- 待完成：干净提交重打包；多显示器因当前环境不具备而待补证，经项目所有者批准不阻塞本次 Stable。

## 推荐阅读

1. [当前状态](../../current.md)
2. [产品需求](prd.md)
3. [开发计划](dev_plan_v1.0.md)
4. [进度看板](progress_v1.0.md)
5. [验证记录](verification.md)
6. [人工验证](manual-verification.md)
7. [发布清单](release-checklist.md)
8. [候选说明](release-notes.md)

## 版本边界

- v1.0 当前树与发布包不包含宠物 UI、运行时、资源和配置。
- v0.9 Beta tag 与 GitHub Release 是桌宠版本的恢复基线。
- 正式 Stable 包必须从干净提交重新生成，不能直接使用脏工作树候选。
