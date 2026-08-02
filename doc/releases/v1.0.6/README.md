# LetsMakeMoney Windows v1.0.6

v1.0.6 是基于 v1.0.5 Stable 的定向主题初始化维护版本。它不改变收入、日历、配置 schema、Mini 隐私贴边或窗口视觉，只修复主题首帧与跨窗口收敛，并补齐配置 hydration 安全门禁。

## 当前状态

- Review：完成。
- 实现：完成。
- 自动回归：通过。
- 隔离候选：受控 dirty 候选作为历史排错证据保留，不得发布。
- 干净候选：已从 `ced768aba54bf06d61045b38c1008fe8624a6e82` 构建并通过 M6 与真实 Windows 身份冒烟。
- 真实 Windows GUI：主题首帧、事务、异常退出、非法值回退和原生关闭链路通过。
- 发布：技术门禁通过；未授权、未执行。

## 入口

- [维护版本 Review](review.md)
- [问题池](issue-pool.md)
- [进度](progress_v1.0.6.md)
- [验证](verification.md)
- [Bugfix 记录](../../logs/v1.0.6-bugfix-log.md)

## 范围边界

- 只支持浅色和深色两种既有主题。
- Rust 配置与进程内 ThemeSession 是唯一权威来源。
- 不恢复宠物，不新增功能，不重做 UI，不改变用户数据格式。
- Windows 10 与真实多显示器继续作为环境补证。
- 正式发布只能使用干净候选的新身份，不能复用 dirty 候选哈希；推送、tag 与 Release 仍需独立授权。
