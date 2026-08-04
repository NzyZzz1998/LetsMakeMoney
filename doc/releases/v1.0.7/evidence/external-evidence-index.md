# v1.0.7 外部原始证据索引

本索引只记录逻辑 ID、类型、摘要哈希和保留状态，不记录本机绝对路径、用户名、完整日志、截图内容或用户配置。

| 逻辑 ID | 类型 | 仓库摘要 | 原始摘要 SHA256 | 状态 |
| --- | --- | --- | --- | --- |
| `V107-M2-WINDOW-RAW` | Windows 11 单显示器窗口与隐私操作 | `m2-window-privacy.json` | 由外部证据库管理 | 保留 |
| `V107-M4-CALENDAR-RAW` | 五周/六周日历与月度总结 GUI | `m4-monthly-calendar.json` | 由外部证据库管理 | 保留 |
| `V107-M5-SURFACE-RAW` | Combobox、主题与窗口表面 GUI | `m5-combobox-surface.json` | 由外部证据库管理 | 保留 |
| `V107-M6-CSP-RAW` | 隔离 CSP 失败候选 | `m6-governance-security-performance.json` | `2375A2A64900967654C9E5A8815193CB353A9A89F8876B73BAA86C97C177140B` | 保留，候选已撤销 |
| `V107-M6-PERF-RAW` | 10 次冷启动与 10 次暖启动采样 | `m6-governance-security-performance.json` | `07A35DA26171DF61E5B54D1FE3835737105E2795B4CE05B643B70AE5D24B6606` | 保留 |
| `ACC-V107-20260804` | dirty 候选独立 GUI 验收：28 张截图与两份运行日志 | `acceptance-summary.json` | 由外部证据库管理 | 保留，验收未通过 |
| `V107-ACCEPTANCE-FIX-20260804-01` | 修复候选定向复验：8 张截图、运行日志与事件摘要 | `acceptance-fix-summary.json` | 运行日志 `B89B36AD...FA97`；事件摘要 `3FCD6E90...5643` | 保留，定向复验通过 |
| `V107-ACCEPTANCE-DPI-20260804-01` | 实际 Windows 125%/150% DPI：旧候选失败与新候选修复后截图 | `acceptance-dpi-summary.json` | 125% `14EA8C68...3563`；150% `240DD5AF...34E56` | 保留，首次失败与定向通过并存 |
| `V107-ACC-COMPLETION-20260804-01` | 休息日/跨夜加班、重启持久化与 Mini 恢复：7 张截图及运行日志 | `acceptance-completion-summary.json` | 由外部证据库管理 | 通过，环境已恢复 |
| `V107-ACC-TRAY-20260804-01` | 托盘左键隐藏/恢复、右键原生菜单与任务栏组合 | `acceptance-tray-summary.json` | 运行日志 `82E2310F...FE12` | 通过，环境已恢复 |

## 唯一副本规则

1. 仓库只提交脱敏摘要，不复制原始截图、录屏、配置或完整日志。
2. 同一原始证据只分配一个逻辑 ID；修订采样必须创建新 ID 或在摘要中明确失效关系。
3. 候选 EXE、Zip 和原始证据不得复制到 `doc/`、`releases/` 或源码目录。
4. 原始证据不可用时写“丢失”或“外部不可用”，不得用后续重构证据冒充。
5. 最终候选身份变化后，所有绑定旧 EXE 哈希的 GUI、CSP 和性能证据必须重新判定有效性。
