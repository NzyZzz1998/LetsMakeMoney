# LetsMakeMoney Windows v1.0.1 验证记录

## 验收结论

- 版本：v1.0.1 Stable 候选
- 实施分支：`agent/v1.0.1-implementation`
- 构建基线：`5fa9293799a15956dd5d18bcd297b5d0e542cd3b`
- 最终结论：通过
- 发布判断：可进入发布收口
- 发布阻塞：无
- 说明：候选包含基线之后尚未提交的实现，最终身份以 Zip、EXE、DLL 与 `BUILD-INFO.json` 的 SHA256 为准。

## 最终候选身份

- 生成时间：2026-07-27 20:33:22（Asia/Shanghai）
- 便携 Zip：`releases/v1.0.1/LetsMakeMoney-v1.0.1-windows-x86_64.zip`
- Zip 大小：3,128,362 字节
- Zip SHA256：`CBF19024A8337E36E58F2EC23B0AE10EA1013616ED278CB2FEC590AA717F280D`
- EXE 大小：9,776,640 字节
- EXE SHA256：`5BC7E6D04DDD65E4CE745D368CCF2369E66ED501D9BC683EC690EB16DA807C38`
- WebView2Loader 大小：160,320 字节
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- 日历 manifest SHA256：`66EFF12D277E75CF2E178AE7DCCB59BF678F16E056C514A1C1676E00C0D482A1`
- 构建身份：`BUILD-INFO.json` 记录版本 `1.0.1`、渠道 `stable-candidate`、源码基线 `5fa9293799a15956dd5d18bcd297b5d0e542cd3b`。
- 工作树说明：候选包含尚未提交的 v1.0.1 实现，因此 `source_tree_dirty` 为 `true`；发布提交创建后必须重新构建并重新验收哈希，不得沿用本段哈希冒充发布提交产物。

## 自动验证

| 门禁 | 结论 | 证据 |
| --- | --- | --- |
| M0 合同与数据 | 通过 | `scripts/verify_v101_m0.ps1` |
| M1 日历数据与状态机 | 通过 | `scripts/verify_v101_m1.ps1` |
| M2 日期调整事务 | 通过 | `scripts/verify_v101_m2.ps1` |
| M3 跨夜与金额守恒 | 通过 | `scripts/verify_v101_m3.ps1` |
| M4 秒级同步 | 通过 | `scripts/verify_v101_m4.ps1` |
| v1.0.1 聚合验证 | 通过 | `scripts/verify_v101.ps1 -SkipReleaseBuild` |
| v1.0 回归 | 通过 | 聚合验证内调用 v1.0 现有门禁 |
| Web 构建 | 通过 | TypeScript 与 Vite 生产构建 |
| Rust 测试 | 通过 | 领域、配置、日历、窗口与更新版本比较 |
| TypeScript 行为测试 | 通过 | 日历、日期草稿、权威同步，4/4 |
| 包验证 | 通过 | `scripts/verify_v101_package.ps1` |

## 真实桌面验收

所有 GUI 证据均来自候选 Zip 的独立新解压目录，不使用开发构建目录替代。

| 模块 | 结论 | 关键证据 |
| --- | --- | --- |
| 迷你收入视图与今日工作台 | 通过 | `01-mini-final-candidate.png`、`02-workbench-today-baseline.png` |
| 2025/2026 官方日历 | 通过 | `03-calendar-baseline.png`、`10-calendar-supported-2025.png`、`11-calendar-supported-upper-bound-2026.png` |
| 带薪休息 | 通过 | `04-calendar-paid-rest-applied.png`、`05-today-paid-rest.png` |
| 不带薪休息 | 通过 | `06-calendar-unpaid-rest-applied.png`、`07-today-unpaid-rest.png` |
| 恢复自动与休息日禁用条件 | 通过 | `08-calendar-restored-automatic.png`、`09-weekend-disabled-paid-options.png` |
| Settings 五页 | 通过 | `12-settings-income.png`、`13-settings-calendar-static-facts.png`、`17-settings-data-support.png` |
| Settings 无变化、成功、失败 | 通过 | `14-settings-no-change.png`、`15-settings-save-success.png`、`16-settings-save-failure.png` |
| Wizard 进入、返回、取消、关闭、完成 | 通过 | `18-wizard-first-step.png` 至 `22-wizard-complete-mini.png` |
| 诊断摘要与数据目录 | 通过 | `23-diagnostic-summary-copied.png`、`24-data-directory-opened.png` |
| 更新版本比较 | 通过 | `26-update-check-version-order-fixed.png` |
| 托盘隐藏、恢复与窗口策略 | 通过 | `debug-final-candidate.log` 中 `tray.left_click`、`window.hidden`、`window.shown`、`window.policy_applied` |

## 配置与日志证据

- 普通保存后配置持久化并可重启读取。
- 无变化保存不产生无意义写入。
- 保存失败时显示可读错误、保留输入，失败前后有效配置哈希一致。
- 日期调整记录 `calendar.override.opened/applied/removed/cancelled`。
- Settings 记录 `settings.saved` 与 `settings.save_failed`，失败日志包含可读原因。
- Wizard 记录打开与完成链路；取消未写入半成品配置。
- 诊断和数据目录记录 `support.diagnostic_copied` 与 `support.data_directory_opened`。
- 更新修复前的错误结果保留为缺陷证据；修复后记录 `update.checked status=up_to_date`。

## 已关闭缺陷

| 缺陷 | 结论 | 复验结果 |
| --- | --- | --- |
| `V101-BUG-001` 日期调整成功反馈因视图刷新消失 | 通过 | 反馈状态提升至 CalendarView 所有，成功、无变化关闭弹层，失败保留草稿 |
| `V101-BUG-002` 更新版本使用字符串不等比较 | 通过 | 改为数字段比较；`1.0` 不再被判为比 `1.0.1` 更新 |

## 待人工补证

- 真实 Windows 睡眠与恢复后的权威同步
- 手动修改系统时间或时区后的即时同步
- 连续两小时稳定运行
- Computer Use 无法可靠覆盖时的通知区真实鼠标左键

这些项目未写为通过。现有自动行为测试、真实 GUI、托盘日志和候选包验证未发现相应发布阻塞，因此不阻塞进入发布收口。

## 验收边界

- 自动测试只证明合同、算法、配置事务、构建和包结构。
- GUI 证据证明了本轮可稳定操作的真实桌面链路。
- 变更未恢复宠物、账号、云同步、主题、安装器或静默更新。
- v1.0 tag、Release 和历史发布包未修改。

## 用户环境恢复

- 验收结束后 LetsMakeMoney 进程数：0。
- 原始 `config.json` 已恢复，SHA256：`E825D224026290E67135FBF7D3005D98567F881494CFBD02EA9776A09153C4CD`。
- 原始 `debug.log` 已恢复，SHA256：`AB7A2B457768448AB2056F730DB6C245894025691DBB229399607D194622D27B`。
- 恢复后文件哈希与验收前备份逐项一致。
