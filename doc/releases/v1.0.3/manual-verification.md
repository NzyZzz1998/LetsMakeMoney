# LetsMakeMoney Windows v1.0.3 人工验证

## 当前状态

本清单用于记录自动化或 Computer Use 无法独立证明的真实 Windows 行为。未执行项不得写为通过。

| ID | 项目 | 状态 | 说明 |
| --- | --- | --- | --- |
| V103-MAN-001 | Windows 睡眠跨业务边界与恢复 | 通过 | 工作跨休息、休息跨恢复工作两条真实 S3 路径均通过 |
| V103-MAN-002 | 系统时间向前、向后跳变与恢复 | 通过 | 经项目所有者确认 UAC 后完成真实前拨、后拨及恢复；阶段在 5 秒内收敛，配置、时区和系统时间均已恢复 |
| V103-MAN-003 | Windows 时区切换与恢复 | 通过 | Tokyo 与 China Standard Time 已真实切换并恢复 |
| V103-MAN-004 | Windows 通知区真实左键隐藏/恢复 | 通过 | 真实通知区图标完成两次鼠标左键操作；隐藏、进程存活、恢复和生命周期日志均通过 |
| V103-MAN-005 | 修正版最终候选连续 120 分钟运行 | 通过 | 连续运行 7201.27 秒，进程存活；CPU、内存、日志和同步频率均满足门禁 |

修复前候选已完成一次 120 分钟采样，但因隐藏 Workbench 造成连续高 CPU 而未通过。该失败已进入 `doc/logs/v1.0.3-bugfix-log.md`；修正版候选使用新的候选哈希重新采样并通过，未沿用失败候选证据。

剩余门禁的权限、Computer Use 边界与睡眠能力证据：
`.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/remaining-gates/V103-REMAINING-GATES-CAPABILITY.json`。
受控时间表的系统时间、工作转休息、休息转工作三种配置均完成准备与逐字节恢复自测，非法时间顺序会返回非零；证据位于
`.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/remaining-gates/boundary-helper-postpatch-tests-20260730-085743/`。
真实睡眠辅助脚本的两种场景干跑通过，设备继续报告支持 S3；证据位于
`.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/remaining-gates/sleep-helper-final-dryrun-20260730-085810/`。

## V103-MAN-001 睡眠与恢复

### 工作阶段跨过休息边界

1. 打开迷你视图与今日详情，确认当前为工作阶段。
2. 将休息开始时间设置到当前时间后 2 至 3 分钟，并保存。
3. 记录当前金额、阶段、owner date 和倒计时。
4. 让 Windows 真实进入睡眠，等待跨过休息开始时间后唤醒。
5. 5 秒内应显示休息阶段，金额停止增长，倒计时切换为距离恢复工作。
6. 日志应出现睡眠/时钟跳变检测和一次恢复同步，不得重复注册 timer。

2026-07-30 真实执行结果：**通过。**

- 工作阶段实际进入 Windows S3，休眠约 `194.42` 秒并跨过休息开始边界。
- 唤醒后界面收敛为“休息中 / 距离恢复工作”，候选进程保持存活。
- 日志出现 `schedule.sleep_resumed`、`earnings.authoritative_sync.requested reason=sleep_resume`，
  并在边界触发 `business_boundary` 同步后收敛为 `phase=lunch`。
- 未出现权威同步失败、panic、崩溃或重复 timer。
- 配置 SHA256、候选进程和 `China Standard Time` 均已恢复。
- 证据：
  `.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/remaining-gates/sleep-work-to-rest-retry-20260730-170704/`。

### 休息阶段跨过恢复工作边界

重复上述步骤，但从休息阶段进入睡眠并跨过恢复工作边界。唤醒后 5 秒内应回到工作阶段，收益继续增长。

2026-07-30 真实执行结果：**通过。**

- 休息阶段实际进入 Windows S3，休眠约 `262.28` 秒并跨过恢复工作边界。
- 唤醒后界面由“休息中 / 距离恢复工作”收敛为“工作中 / 距离下班”，金额从休眠前的 `¥54.35` 恢复增长。
- 日志出现一次 `schedule.sleep_resumed` 和一次 `reason=sleep_resume`；后续权威同步完成为 `phase=working`。
- 权威同步失败、panic、fatal 和重复 timer 均为 `0`，候选进程保持存活。
- 配置与 `debug.log` 已按测试前 SHA256 恢复，候选进程为 `0`，时区为 `China Standard Time`。
- 证据：
  `.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/remaining-gates/sleep-rest-to-work-20260730-171642/`。

### 证据

- 唤醒前后截图。
- `debug.log` 对应片段。
- 验证前后配置。
- Windows 电源状态及实际经过时间。

## V103-MAN-002 系统时间跳变

1. 记录当前日期、时间、时区和自动设置开关。
2. 将系统时间向前调整并跨过休息或下班边界。
3. 5 秒内核对阶段、金额、owner date、今日安排和日历。
4. 恢复原时间并再次核对。
5. 将系统时间向后调整到较早业务阶段，重复核对后恢复。
6. 不得出现金额负增长、重复 timer、配置损坏或跨日 owner date 错误。

非提权 `Set-Date` 曾被 Windows 以 `A required privilege is not held by the client` 拒绝；前两次管理员提升也在脚本启动前被取消。这些失败仅保留为权限边界历史，不计入通过证据。

2026-07-30 经项目所有者确认 UAC 后完成真实系统时间复验：

- 向前调整 10 分钟后，界面由“工作中 / 距离休息”在数秒内收敛为“休息中 / 距离恢复工作”。
- 向后调整 10 分钟后，界面在数秒内收敛为“上班前 / 工作进度 0% / 距离上班”。
- 恢复系统时间后，界面重新收敛为“工作中 / 距离休息”。
- 日志包含工作、休息、上班前和恢复后的权威同步语义；未出现权威同步失败或重复 timer。
- 两次辅助脚本均报告 `restored: true`、`resync_exit_code: 0`；最终时间偏差分别约为 `-4ms` 和 `-5ms`。
- `China Standard Time`、候选进程和两处配置文件均恢复；配置 SHA256 为验收前值 `1C2C4194DE66D5F76DB0586D01179C01436CF5D94B5B077ED74506ED4A578288`。

向前调整、恢复及日志证据：
`.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/remaining-gates/system-time-actual-real-20260730-094556/`。

向后调整与最终恢复的真实 GUI 证据：
`.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/remaining-gates/system-time-backward-gui-20260730-095020/`。

## V103-MAN-003 时区变化

- 初始时区：`China Standard Time`
- 验证时区：`Tokyo Standard Time`
- 恢复结果：`China Standard Time`
- 日志：`schedule.timezone_changed` 与恢复同步均出现。
- 证据：`V103-TIMEZONE-*.json`、`V103-GUI-TIMEZONE-*.jpg`。

## V103-MAN-004 通知区左键

- 真实通知区图标：`SystemTray.NormalButton`，可访问名称为 `LetsMakeMoney`。
- 第一次真实鼠标左键后，迷你视图从可见变为隐藏，候选进程继续运行。
- 第二次真实鼠标左键后，迷你视图恢复并立即执行权威同步。
- 日志中的 `tray.left_click`、`window.hidden`、`window.shown`、`window.webview_suspend_completed`、`window.webview_resume_completed`、`dashboard.lifecycle.paused` 和 `dashboard.lifecycle.resumed` 语义完整。
- 主证据：`.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/remaining-gates/V103-TRAY-LEFT-CLICK-EVIDENCE.json`。
- 截图：同目录 `V103-TRAY-BEFORE-HIDE.png`、`V103-TRAY-AFTER-HIDE.png`、`V103-TRAY-BEFORE-RESTORE.png`、`V103-TRAY-AFTER-RESTORE.png`。

## V103-MAN-005 连续 120 分钟运行

- 候选 Zip SHA256：`91491B65F0CABFCA6889C18355AFD26E1BB22720DB8F61DB835F8CB86A4E0743`。
- 实际运行：`7201.27` 秒，候选进程始终存活。
- 15 分钟预热后的进程树平均单核 CPU `0.3302%`，最大 `2.8137%`，没有连续超过 `10%` 的样本。
- 私有内存增加 `4,108,288` 字节，工作集增加 `6,541,312` 字节，未见持续异常增长。
- 日志增长 `45,300` 字节；权威同步失败、WebView2 suspend/resume 失败、panic/fatal 均为 `0`。
- 证据：`evidence/webview-suspend-fix/stability-post-fix/V103-STABILITY-FINAL-EVALUATION.json`。

## 环境恢复

本轮候选验收结束后已经：

- [x] 恢复 `China Standard Time`；真实系统时间前拨、后拨后均完成校时恢复，最终偏差不超过 `5ms`。
- [x] 按备份清单恢复 `%APPDATA%\io.letsmakemoney.windows` 的 7 个原始文件。
- [x] 逐项核对文件大小与 SHA256，匹配 `7/7`，无多余或缺失文件。
- [x] 恢复实际与重定向配置文件，SHA256 均为验收前值。
- [x] 停止全部候选进程，进程数为 `0`。
- [x] 将最终测试态归档到验收证据目录，不保留临时系统设置。

恢复证据：`.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/V103-ENVIRONMENT-RESTORE-RESULT.json`。
