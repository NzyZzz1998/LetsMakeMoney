# LetsMakeMoney v1.0.2 人工补证

> `V102-MAN-001` 通知区真实鼠标左键、`V102-MAN-002` 真实 Windows 125%/150% 系统缩放和 `V102-MAN-003` 配置后 Wizard 托盘入口复用均已通过。`V102-BUG-007` 已关闭，当前无人工验收发布阻塞。

## V102-MAN-000 今日工作台历史复现

状态：历史失败已关闭。

旧候选曾稳定复现 Workbench 创建后保持隐藏，对应 `V102-BUG-005`。完整 GUI 候选已从新解压目录完成 Workbench、Settings 和首次配置 Wizard 的真实显示复验，三类窗口均形成完整的 `show_requested -> policy_applied -> visible -> focused -> shown` 日志链。最新候选只增加 Wizard 首次/复用状态修复，并从新的独立解压目录完成托盘入口定向复验；其余窗口沿用完整 GUI 验收证据和自动回归结果。

最新 Acceptance 候选：

- Zip SHA256：`BA7330C0C14745CE1DB355C3E28CE75255E7B64250212CE25D8B36C054653DB2`
- EXE SHA256：`BE54F049F2134536564EC8222F3C5446F54C3653223206A97BDE2A3B575CB6F7`

旧候选失败证据继续作为历史保留，不代表最终候选状态。

## V102-MAN-001 Windows 通知区真实鼠标左键

状态：通过。

验证时间：2026-07-28。

真实结果：

1. 项目所有者使用真实鼠标左键点击 Windows 通知区 LetsMakeMoney 图标，迷你收入视图隐藏，进程保持运行。
2. 再次左键点击同一图标，迷你收入视图恢复。
3. 右键托盘菜单可打开，“重新配置”等入口可触达。
4. `debug.log` 记录 `tray.left_click` 以及成对的窗口隐藏、显示与策略恢复语义事件。

证据：

- `.tmp_acceptance/v1.0.2-final-20260728-174755/evidence/manual-tray-and-wizard-debug.log`
- 日志 SHA256：`7AECD10F49EAB6D37012A6641763A54D0889C4B0B32308DD761E353E372DBC40`

## V102-MAN-002 真实 Windows 125%/150% DPI

状态：通过。

验证时间：2026-07-28。

验证对象：

- Zip SHA256：`776E5E64B97E7573F45C6A4AD4A86406A87976C430D5289BDA3D0CA757AC65EE`
- EXE SHA256：`FE96E46DB0CFEF9069D459A46138BDB4D243ECE69A046FAC29926457C0D89CB1`
- 实际 EXE：`.tmp_acceptance/v1.0.2-final-20260728-174755/extracted/LetsMakeMoney-v1.0.2-windows-x86_64/LetsMakeMoney.exe`
- 显示器：`2560 × 1440`
- 系统缩放：真实 Windows `125%`、`150%`

真实结果：

1. Windows 设置页面分别显示 `125%` 与 `150%`，每档缩放均关闭并重新启动锁定 EXE。
2. 125% 下完成 Wizard 第 1 至第 3 步、Mini、Workbench 今日页、日历、Settings 收入页及外观页检查。
3. 150% 下完成 Wizard 第 1 步、Mini、Workbench 今日页、日历、Settings 收入页及外观页检查。
4. 两档缩放下均未发现文字或控件裁切、重叠、模糊、异常缩放、异常留白或不可访问内容。
5. 日历图例和 Settings 下半部分通过窗口内预期滚动可完整访问；固定页脚没有遮挡末行控件。
6. 浅色与深色下的正文、金额、Lucide 图标、边框、状态色及 Mini/Workbench 均保持清晰。
7. 深色仅作为未保存草稿预览，随后切回浅色，Settings 显示“没有未保存的更改”，没有污染原配置。
8. 自动化 100%/125%/150% 布局矩阵与本次真实系统缩放结果一致。

证据目录：

- `.tmp_acceptance/v1.0.2-dpi-20260728-181435/evidence/`
- 125%：`125-wizard-step-1.png` 至 `125-wizard-step-3.png`、`125-mini.png`、`125-workbench-today.png`、`125-calendar.png`、`125-calendar-bottom.png`、`125-settings-income.png`、`125-settings-income-bottom.png`、浅色/深色主题截图。
- 150%：`150-wizard-step-1.png`、`150-mini.png`、`150-workbench-today.png`、`150-calendar.png`、`150-calendar-bottom.png`、`150-settings-income.png`、`150-settings-income-bottom.png`、浅色/深色主题截图。
- 系统缩放：`windows-display-125-percent.png`、`windows-display-150-percent.png`、`windows-display-restored-100-percent.png`。

环境恢复：

- Windows 显示缩放已恢复为验收前的 `100%（推荐）`。
- `%APPDATA%\io.letsmakemoney.windows\config.json` 与 `debug.log` 已恢复，SHA256 与验收前备份完全一致。
- 验收结束后 LetsMakeMoney 进程数为 0。

## V102-MAN-003 配置后 Wizard 托盘入口复用

状态：通过。

验证时间：2026-07-28。

真实结果：

1. 已完成首次配置后，从 Windows 原生托盘菜单点击“重新配置”。
2. Wizard 从第 1 步打开，窗口显示链完成到 `window.shown`。
3. 关闭重新配置窗口时，项目所有者确认显示“放弃本次配置？”和“放弃配置”，不再显示“退出首次配置？”或“退出应用”。
4. 选择放弃后 Wizard 隐藏，迷你收入视图继续运行，应用未退出。
5. 日志记录 `tray.command id=tray-wizard`、完整 Wizard 显示链、`window.hidden label=wizard` 和草稿回滚事件。

修复复核：

- Wizard 的 `firstRun` 仅在 React 组件首次挂载时读取 `configuration_initialized`。
- 首次配置保存后 Rust 已将配置状态更新为已初始化，但隐藏并复用的 Wizard WebView 没有刷新 `firstRun`。
- 修复后首次配置保存会立即更新前端状态；每次 `lmm:window-shown` 都重新读取权威配置状态，并使用请求序号防止旧异步结果回写。
- 首次未配置用户的退出语义保持不变，已配置用户复用 Wizard 时使用放弃本次配置语义。

证据：

- 新候选 Zip SHA256：`BA7330C0C14745CE1DB355C3E28CE75255E7B64250212CE25D8B36C054653DB2`
- 新解压 EXE SHA256：`BE54F049F2134536564EC8222F3C5446F54C3653223206A97BDE2A3B575CB6F7`
- `.tmp_acceptance/v1.0.2-bug007-20260728-193200/evidence/manual-tray-wizard-postfix-debug.log`
- 日志 SHA256：`55816D518ACC3FF0F11AB488B0AD22C90ACEE81789F96B693A5C0AEE121D7621`
- `.tmp_acceptance/v1.0.2-bug007-20260728-193200/evidence/manual-tray-wizard-returned-to-mini.jpg`
- 截图 SHA256：`B45B13628F8FD97E06DAF15BA8DC5110E2AA758A4F83AC0BA550952AA07B9812`
- 项目所有者于真实 Windows 通知区完成托盘“重新配置”与关闭确认文字核对。

环境恢复：

- 候选进程已停止，进程数为 0。
- `%APPDATA%\io.letsmakemoney.windows\config.json` 已恢复，SHA256：`EA0839031F9DD217B7B2331F9DB961BC3626DDC7862762469DDD7B619A93EE5C`。
- `%APPDATA%\io.letsmakemoney.windows\debug.log` 已恢复，SHA256：`DA474CC9492D060B360EED65DC685A481784A42E3079833553D6A25A6ECE59B2`。

结论：`V102-BUG-007` 已关闭，`V102-MAN-003` 通过，不再构成发布阻塞。
