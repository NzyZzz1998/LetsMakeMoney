# v1.0.7 脱敏证据

本目录只保存可公开、可复核的脱敏摘要，不保存完整日志、截图、录屏、用户配置、注册表导出、本机绝对路径或秘密。

当前入口：

- `m0-baseline.json`：Git、v1.0.6 正式发布、冻结文档、配置、脚本和行为基线。
- `m2-window-privacy.json`：窗口、隐私贴边、Workbench 协同和环境恢复摘要。
- `m3-date-overtime.json`：共享日期事务、加班领域和 IPC 摘要。
- `m4-monthly-calendar.json`：月度总结、五周/六周日历和初始 100% DPI 摘要。
- `m5-combobox-surface.json`：Combobox、窗口表面和初始 100% DPI 摘要。
- `m6-governance-security-performance.json`：脚本治理、支持矩阵、CSP 撤回和 10+10 性能基线。
- `m7-candidate-package.json`：dirty 验收候选身份、包体与发布边界。
- `acceptance-summary.json`：独立 GUI 验收结论、阻塞、待补证与环境恢复脱敏摘要。
- `acceptance-fix-summary.json`：两项阻塞修复后的定向 GUI 复验、事务日志与环境恢复脱敏摘要。
- `acceptance-dpi-summary.json`：真实 125%/150% DPI 首次失败、布局修复、定向复验和环境恢复脱敏摘要。
- `acceptance-completion-summary.json`：休息日/跨夜加班、重启持久化、Mini 恢复与最终验收结论的脱敏摘要。
- `acceptance-tray-summary.json`：托盘左键隐藏/恢复、右键菜单、任务栏组合与环境恢复的脱敏摘要。
- `external-evidence-index.md`：外部原始证据逻辑 ID、摘要哈希和唯一副本规则。

后续证据文件必须包含 `schema_version`、`milestone`、`source_head`、时间、环境摘要、结论和原始证据逻辑 ID。原始证据不在仓库时，应明确写 `external`，不得伪造可点击路径。
