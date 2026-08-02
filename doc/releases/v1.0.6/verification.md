# LetsMakeMoney Windows v1.0.6 验证

## 当前结论

**定向验收通过，发布身份未通过。** 源码级门禁、受控 dirty 候选包验证和真实 Windows 主题链路均已通过；该候选来自 dirty 工作树，不能作为 Release 对象。正式发布仍需从干净提交重建并对新身份执行冒烟。

## 验收对象

- 分支：`release/v1.0.5`。
- HEAD：`0b2c3461a59b9e8063b2e43974483f64759dc737`。
- 候选 ID：`V106-20260802T124844Z-0b2c3461-dirty`。
- Zip：3,245,264 字节；SHA256 `87347729CBCB1B5EBA228CB40FA323D6BEC0425F20E6C915EB4EEC949D9FF187`。
- EXE：10,140,160 字节；SHA256 `DAC97F7AE6F05D6AA5A994D72A5C02810BD65B8666764EBA0F89C2101D810236`。
- WebView2Loader：160,320 字节；SHA256 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 实际运行：仅运行全新解压目录 `runtime-fixed-20260802-205140/` 中的 EXE。
- 候选身份：`source_tree_dirty=true`、`publication_allowed=false`。

## 自动验证

| 项目 | 结果 | 证据 |
| --- | --- | --- |
| v1.0.6 主题行为 | 通过 | 17/17：权威首帧、旧缓存清理、晚监听、代际、预览/提交/回滚 |
| 高风险组合 | 通过 | 24/24：包含 hydration 未完成禁止保存与旧配置保护 |
| 架构行为聚合 | 通过 | 既有 15 组行为测试与 22/22 结构门禁 |
| Rust 单元测试 | 通过 | 56/56，含 ThemeSession preview/revert 与过期事务保护 |
| TypeScript strict / Vite | 通过 | 生产 Web 构建通过 |
| Rust fmt | 通过 | `cargo fmt --check` |
| Rust clippy | 通过 | `-D warnings` 通过 |
| 文档事实门禁 | 通过 | v1.0.6 聚合门禁通过 |
| 候选打包与包体验证 | 通过 | candidate 模式身份、内部哈希与许可文件通过 |
| `git diff --check` | 通过 | 当前变更无空白错误 |

## 候选验收矩阵

| 场景 | 结论 |
| --- | --- |
| 浅色配置的 Mini、晚创建 Workbench 与 Settings 首帧 | 通过；三窗口首个可观察状态均为浅色 |
| 深色配置四窗口冷启动 | 通过；Mini、Workbench、Settings、Wizard 首帧均为深色 |
| Settings 深色/浅色预览后原生关闭并放弃 | 通过；显示确认，其他窗口恢复 persisted 主题 |
| Settings 保存主题并重启 | 通过；配置哈希改变，四窗口冷启动读取新 persisted 主题 |
| 配置 hydration 与写入保护 | 自动通过；24/24 高风险组合覆盖加载前拒绝保存和旧配置保护 |
| Wizard hydration 与原生关闭 | 通过；深色首帧及 Alt+F4 放弃确认真实可见；失败注入由自动门禁覆盖 |
| Mini/Workbench 隐藏恢复 | 通过；恢复后保持 persisted 主题并重新收敛 |
| preview 期间异常退出后重启 | 通过；配置 SHA256 不变，重启恢复 persisted 主题 |
| 非法主题枚举 | 通过；浅色安全回退、配置修复并记录 `theme.invalid_fallback` |
| 日志来源、窗口、revision 与 reason | 通过；bootstrap、listener、preview、saved、reverted 与 close route 闭环 |

## 验收中新发现的缺陷

首次复验发现 Settings/Wizard 的原生 Alt+F4 直接触发 Tauri 隐藏，绕过 React 未保存确认，其他窗口会残留 preview 主题。修复后原生关闭请求统一路由到 React：Settings 显示“放弃未保存的更改?”，Wizard 显示“放弃本次配置?”；放弃后执行 `theme.preview_reverted` 并恢复 persisted 主题。该修复已进入同一候选并完成自动与真实 GUI 复验。

## 配置与日志证据

- 验收前浅色配置 SHA256：`62A5B2A846D990E98F0556CF5BE657D4E9D943E7426AC9BC6ACFC594858909CC`。
- 保存深色后 SHA256：`2A8D7D2C4EDF0233E09934733B2FDEA6E1FC95D8B17F40CD6758FE3495C41DE7`。
- preview 期间异常终止后仍为上述深色 SHA256。
- 非法主题回退后恢复浅色 SHA256：`62A5B2A846D990E98F0556CF5BE657D4E9D943E7426AC9BC6ACFC594858909CC`。
- 本地脱敏日志：`.artifacts/acceptance/v1.0.6/20260802-204009/theme-window-events.log`。
- 本地截图：同目录 `screenshots/`；仓库不跟踪原始 GUI 证据。

## 环境边界

- Windows 11 单显示器：本轮候选 GUI 环境。
- Windows 10：待环境补证，不冒充通过。
- 真实多显示器：延续既有延期，不扩大为本版功能。

## 发布判断

- v1.0.6 定向 Bugfix：通过。
- 当前 dirty 候选：不可发布。
- 可进入下一步：将有意变更形成干净提交，重新构建、重新锁定哈希、执行 published 身份门禁与最小 GUI 冒烟。
- 用户环境：已按备份逐文件恢复，3/3 文件 SHA256 一致；结束后 LetsMakeMoney 进程数为 0。
- 本轮未提交、未推送、未打 tag、未创建 Release。
