# LetsMakeMoney Windows v1.0.3 验收

## 当前结论

结论：**通过，可进入发布收口。**

- 自动门禁、官方/估算日历、日期调整、Settings、窗口生命周期、原生 WebView2 挂起、真实时区切换、首次启动 Wizard 和修正版候选 120 分钟稳定运行已有证据。
- `V103-BUG-001` 已由同一修正版候选的连续 7201 秒运行结果关闭。
- Windows 通知区真实鼠标左键隐藏与恢复、系统时间向前/向后跳变及恢复、两条真实 Windows 睡眠跨边界路径均已通过。
- 深度 GUI 与系统门禁由修正版验收候选完成；随后将同一实现内容提交并从干净提交重新构建。
- 最终干净候选已通过全量自动验证、包体验证和新解压启动冒烟，发布身份门禁已关闭。

## 验收对象

| 项目 | 身份 |
| --- | --- |
| 分支 | `main` |
| 发布候选源码提交 | `ebcd58844bc905874c2ddc9b267848ee1aec5b7b` |
| Source tree dirty | `false` |
| Zip | `releases/v1.0.3/LetsMakeMoney-v1.0.3-windows-x86_64.zip` |
| Zip 大小 | 3,204,792 字节 |
| Zip SHA256 | `E4FF7771B3ACD5658DD84EE2CC6E14B1DACA685EBD0D2D180FC318B7BB1F2183` |
| EXE 大小 | 9,997,312 字节 |
| EXE SHA256 | `7DD45D6B35CE82A6241D359EFB2FE88A9A62B3ECD20703B19BAE82CEE98F5BBA` |
| WebView2Loader 大小 | 160,320 字节 |
| WebView2Loader SHA256 | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |
| 最终候选解压目录 | `.tmp_acceptance/v1.0.3-clean-build-20260730-173416/candidate/LetsMakeMoney-v1.0.3-windows-x86_64/` |
| 最终身份与冒烟证据 | `.tmp_acceptance/v1.0.3-clean-build-20260730-173416/evidence/` |
| 深度 GUI 与系统证据 | `.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/` |

### 证据继承边界

- 深度 GUI、睡眠、系统时间、时区、托盘和 120 分钟稳定性证据来自修正版验收候选
  `91491B65F0CABFCA6889C18355AFD26E1BB22720DB8F61DB835F8CB86A4E0743`。
- 该候选的实现内容完整进入提交 `ebcd58844bc905874c2ddc9b267848ee1aec5b7b`，没有在提交后修改业务实现。
- 最终干净构建因构建身份变化获得新的 Zip 与 EXE 哈希；本轮对其重新执行全量自动验证、包体验证及新解压真实启动冒烟。
- 未将深度 GUI 项目描述为在新哈希上重复执行。

## 自动门禁

| 项目 | 结论 | 证据 |
| --- | --- | --- |
| v1.0.3 聚合验证 | 通过 | `scripts/verify_v103.ps1` |
| 年度日历数据 | 通过 | 11/11 |
| 权威同步行为 | 通过 | 25/25 |
| 生命周期行为 | 通过 | 8/8 |
| 原生 WebView2 挂起合同 | 通过 | `apps/windows-v1/tests/verify_webview_suspend_v103.py` |
| Rust 回归 | 通过 | 38/38 |
| 历史版本回归 | 通过 | v1.0-v1.0.2 聚合门禁 |
| 打包与包体验证 | 通过 | `scripts/package_v103.ps1`、`scripts/verify_v103_package.ps1` |
| 2025 年数据 SHA256 | 通过 | `3C7911EEEEC200FFCD4C7C20ED84C64B06F23EC81818AD50D9EAEE88081C1280` |
| 2026 年数据 SHA256 | 通过 | `440169EAD0FCDA71C15CBAAE11EC557DC0846EECA103A988D267303D9C306042` |
| 文档与差异检查 | 通过 | v1.0.3 相关 18 份文档严格 UTF-8、乱码和本地链接检查通过；`git diff --check` 通过 |

## 真实桌面结果

| 模块 | 结论 | 证据与说明 |
| --- | --- | --- |
| 官方 2026 日历 | 通过 | `V103-GUI-CALENDAR-OFFICIAL-001.jpg` |
| 2027 估算日历 | 通过 | `V103-GUI-CALENDAR-ESTIMATED-2027-001.jpg`；界面明确标记为估算 |
| 官方年份日期调整 | 通过 | 带薪休息草稿、应用和 Dashboard 回算截图 |
| 估算年份日期调整 | 通过 | 估算来源和手动调整同时可辨 |
| Settings 五页 | 通过 | 保存、无变化、恢复默认及各页截图 |
| 隐藏窗口静默 | 通过 | Workbench 隐藏超过 64 秒未产生自身 interval 同步 |
| 恢复立即收敛 | 通过 | `V103-GUI-LIFECYCLE-RESTORED-001.jpg` 和日志 |
| 隐藏期间配置变化 | 通过 | 恢复后立即收敛，随后恢复原配置 |
| 连续 10 次显隐 | 通过 | `V103-LIFECYCLE-10-CYCLES.json`；10 次 shown/hidden、paused/resumed 成对且无重复 timer |
| 原生 WebView2 挂起/恢复 | 通过 | 修正版候选 10 次 suspend/resume 均完成，失败为 0 |
| 隐藏 Workbench CPU 定向复验 | 通过 | 6 分钟平均单核 `0.7808%`，最大 `1.7368%`，无连续高 CPU |
| 隐藏后 timer 唯一性 | 通过 | 第十次隐藏后 75 秒产生 2 次 30 秒 interval，同 Mini 单窗口预期一致 |
| Windows 时区切换 | 通过 | Tokyo 与 China Standard Time 真实切换、恢复及 `schedule.timezone_changed` 日志 |
| stale / 完整性失败 | 部分通过 | 行为测试与包门禁通过；候选没有安全故障注入入口，未伪造真实 GUI 失败 |
| 首次启动 Wizard | 通过 | `first-run-wizard/V103-WIZARD-RESULT.json`；空配置、关闭确认、三步配置、保存、Mini 显示和 Wizard 隐藏均通过 |
| 120 分钟稳定运行 | 通过 | `webview-suspend-fix/stability-post-fix/V103-STABILITY-FINAL-EVALUATION.json`；连续 7201.27 秒，进程存活，无 5 分钟持续高 CPU |
| Windows 睡眠恢复 | 通过 | 工作跨休息、休息跨恢复工作两条路径均真实进入 S3 并在唤醒后正确收敛 |
| 系统时间向前/向后跳变 | 通过 | 项目所有者确认 UAC 后完成真实前拨、后拨和恢复；阶段在数秒内收敛，最终时间偏差不超过 5ms |
| 通知区真实鼠标左键 | 通过 | `remaining-gates/V103-TRAY-LEFT-CLICK-EVIDENCE.json`；真实左键隐藏/恢复、进程存活、WebView 挂起/恢复和 timer 暂停/恢复通过 |

### 稳定性结果

- 15 分钟预热后进程树采样 413 次、覆盖 6306.64 秒，平均单核 CPU `0.3302%`，最大 `2.8137%`，超过 `10%` 的连续样本为 `0`。
- 进程树私有内存增加 `4,108,288` 字节，工作集增加 `6,541,312` 字节；未出现持续异常增长。
- 根进程权威同步请求 `242` 次，日志增长 `45,300` 字节。
- 最终日志统计：请求 `257`、完成 `256`、失败 `0`；WebView2 suspend/resume 失败均为 `0`，panic/fatal 为 `0`。
- 同一候选哈希的 10 次真实 GUI 显隐和隐藏后 timer 唯一性证据共同满足稳定性门禁。
- 剩余系统门禁能力核对见
  `.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/remaining-gates/V103-REMAINING-GATES-CAPABILITY.json`；
  当前工作阶段基线截图为同目录 `V103-SYSTEM-TIME-BASELINE-COMPUTER-USE.jpg`。
- 系统时间向前跳变、休息阶段收敛与恢复证据位于
  `.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/remaining-gates/system-time-actual-real-20260730-094556/`。
- 系统时间向后跳变、上班前阶段收敛与最终恢复证据位于
  `.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/remaining-gates/system-time-backward-gui-20260730-095020/`。
- 工作阶段跨休息边界的真实 S3 证据位于
  `.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/remaining-gates/sleep-work-to-rest-retry-20260730-170704/`：
  Windows 实际休眠约 `194.42` 秒，唤醒后界面收敛为“休息中 / 距离恢复工作”；日志包含
  `schedule.sleep_resumed`、`sleep_resume` 和 `business_boundary` 的 `phase=lunch` 收敛，未出现同步失败、崩溃或重复 timer。
- 休息阶段跨恢复工作边界的真实 S3 证据位于
  `.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/remaining-gates/sleep-rest-to-work-20260730-171642/`：
  Windows 实际休眠约 `262.28` 秒，唤醒后界面由“休息中 / 距离恢复工作”收敛为“工作中 / 距离下班”，
  金额继续增长；日志只有一次 `sleep_resume`，权威同步完成为 `phase=working`，同步失败、panic、fatal 和重复 timer 均为 `0`。

## 发布阻塞

无发布阻塞项。

修复前候选的 120 分钟稳定性结果为未通过：隐藏 Workbench 后出现连续 28 分钟单核占用超过 `10%`。该结果保留为 `V103-BUG-001` 根因证据；同一修正版候选随后完成连续 7201 秒稳定运行并通过门禁，缺陷现已关闭。

## 最终候选复核

- `scripts/verify_v103.ps1`：通过。
- `scripts/verify_v103_package.ps1`：通过。
- `BUILD-INFO.json`：`source_head=ebcd58844bc905874c2ddc9b267848ee1aec5b7b`、`source_tree_dirty=false`。
- 新解压候选真实启动并显示 Mini 工作状态；截图为
  `.tmp_acceptance/v1.0.3-clean-build-20260730-173416/evidence/clean-candidate-mini-smoke.png`。
- 启动进程路径、大小、哈希和退出结果见同目录 `launch-identity.json`；进程已停止。
- stale/error 缺少真实 GUI 注入的边界继续如实保留，不冒充 GUI 通过。

## 用户环境恢复

- `%APPDATA%\io.letsmakemoney.windows` 已按验收前 manifest 恢复，7/7 文件大小和 SHA256 一致，无多余或缺失文件。
- 时区为 `China Standard Time`；真实系统时间前拨、后拨后均已恢复，辅助脚本最终偏差不超过 `5ms`。
- LetsMakeMoney 候选进程数为 `0`。
- 证据：`.tmp_acceptance/v1.0.3-final-20260730-014452/evidence/V103-ENVIRONMENT-RESTORE-RESULT.json`。
