# LetsMakeMoney v1.0.2 验证

## 当前结论

结论：**通过，可进入发布收口。**

- FR-001 至 FR-008 已实现。
- `V102-BUG-001` 至 `V102-BUG-007` 已关闭。
- v1.0.2 聚合验证、历史回归、打包和包体验证通过。
- 完整 GUI 候选已从全新解压目录完成 Mini、Workbench、Settings、首次配置 Wizard、主题预览、放弃更改和关闭复验；最新候选只增加 Wizard 首次/复用状态修复，并从新的独立解压目录完成托盘入口定向复验。
- Workbench、Settings 和 Wizard 均形成 `show_requested -> policy_applied -> visible -> focused -> shown` 完整日志链。
- Settings 放弃深色主题草稿后恢复浅色，重新打开时没有残留确认框，关闭事务和窗口复用行为通过。
- 真实 Windows 125%/150% 系统缩放已完成补证，Mini、Workbench、日历、Settings、Wizard 及浅色/深色关键状态均通过清晰度检查。
- Windows 通知区真实鼠标左键隐藏与恢复已由项目所有者人工补证通过。
- 配置后通过原生托盘入口重新打开 Wizard 时，关闭弹窗正确显示“放弃本次配置？”和“放弃配置”；`V102-BUG-007` 定向复验通过。
- 候选由尚未提交的 v1.0.2 实现树构建；发布收口仍需从签核后的干净提交重新构建并更新最终发布哈希。

## 最终候选身份

| 项目 | 结果 |
| --- | --- |
| 版本 | `1.0.2` |
| 分支 | `main` |
| 构建基线 HEAD | `1eb3dadbd37dcc06141e82e5e043db529821a104` |
| Zip | `releases/v1.0.2/LetsMakeMoney-v1.0.2-windows-x86_64.zip` |
| Zip 大小 | 3,194,384 字节 |
| Zip SHA256 | `BA7330C0C14745CE1DB355C3E28CE75255E7B64250212CE25D8B36C054653DB2` |
| EXE 大小 | 9,988,608 字节 |
| EXE SHA256 | `BE54F049F2134536564EC8222F3C5446F54C3653223206A97BDE2A3B575CB6F7` |
| WebView2Loader 大小 | 160,320 字节 |
| WebView2Loader SHA256 | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |
| 新解压目录 | `.tmp_acceptance/v1.0.2-bug007-20260728-193200/extracted/` |
| 实际 EXE | `.tmp_acceptance/v1.0.2-bug007-20260728-193200/extracted/LetsMakeMoney-v1.0.2-windows-x86_64/LetsMakeMoney.exe` |

## 自动验证

| 项目 | 状态 | 证据 |
| --- | --- | --- |
| 启动重试策略 | 通过 | 瞬时不可用有限重试，真实配置错误不被掩盖 |
| v1.0.2 呈现行为 | 通过 | 11/11 |
| v1.0.2 主题行为 | 通过 | 5/5 |
| 多窗口权威同步行为 | 通过 | 20/20 |
| Rust 回归 | 通过 | 36/36 |
| 配置回归 | 通过 | 9/9 |
| TypeScript 编译与 Vite 构建 | 通过 | 构建成功 |
| v1.0.2 静态合同 | 通过 | 阶段、时间线、Mini、日历、图标、config v8、主题和窗口合同通过 |
| 二级窗口线程合同 | 通过 | `show_app_window` 使用异步命令与 `spawn_blocking`，避免在 WebView IPC 回调中同步创建窗口 |
| 复用窗口关闭状态合同 | 通过 | Settings 与 Wizard 在确认放弃前先清理 `confirmClose` |
| Wizard 首次/复用状态合同 | 通过 | 保存后立即切换为已配置状态；每次窗口显示刷新权威状态；请求序号阻止旧结果回写 |
| v1.0.1 M0-M4 回归 | 通过 | 历史主链自动门禁通过 |
| v1.0 M0-M6 回归 | 通过 | 历史主链自动门禁通过 |
| 打包与包体验证 | 通过 | Zip、EXE、DLL、包结构、版本及许可文件通过 |
| WebView2 启动压力 | 通过 | 新解压候选连续 5 次冷启动均存活并响应 |

## 真实桌面复验

| 项目 | 状态 | 真实结果 |
| --- | --- | --- |
| 有效配置启动 | 通过 | 新解压 EXE 进入 Mini，没有“暂时无法计算”假失败 |
| 首次配置 Wizard | 通过 | 日志记录完整创建、策略、显示与聚焦链路；四步配置和小数休息推算既有实证继续有效 |
| Mini 权威刷新 | 通过 | 工作状态、今日已赚、进度和阶段倒计时持续刷新 |
| 今日工作台显示 | 通过 | 从 Mini 打开 Workbench，窗口真实可见可交互；日志完成 `show_requested` 至 `shown` 全链 |
| Settings 显示 | 通过 | 从 Workbench 打开 Settings，窗口真实可见可交互；日志完成全链 |
| 深色主题草稿预览 | 通过 | 选择深色后窗口即时预览，界面显示“有尚未保存的更改” |
| 关闭与放弃更改 | 通过 | 关闭时显示可读确认框；选择“放弃更改”后窗口隐藏并恢复浅色 |
| Settings 窗口复用 | 通过 | 再次打开 Settings 时无残留确认框，浅色选中且状态为“没有未保存的更改” |
| Wizard 复用关闭状态 | 通过 | 配置完成后经托盘重新打开 Wizard，关闭时正确显示“放弃本次配置？”和“放弃配置”；放弃后应用继续运行 |
| WebView2 频繁崩溃复验 | 通过 | 未发现 `0x80000003` 应用程序错误窗口 |
| 通知区真实左键 | 通过 | 项目所有者用真实鼠标完成隐藏与恢复，进程保持运行；托盘菜单可用，日志记录成对窗口事件 |
| 125%/150% 真实 DPI | 通过 | `2560 × 1440` 显示器上分别切换真实 Windows 125% 与 150%；Mini、Workbench、日历、Settings、Wizard 及浅色/深色关键状态无裁切、重叠或模糊，预期滚动内容可完整访问 |

## 缺陷关闭复核

### V102-BUG-005

- 根因：按需创建二级 WebView 的同步调用占用 WebView IPC 回调路径，窗口对象创建后显示流程不能继续完成。
- 修复：`show_app_window` 改为异步命令，并通过 `tauri::async_runtime::spawn_blocking` 承载窗口创建与策略应用；补充创建、定位、策略、显示、聚焦和失败阶段日志。
- 实证：Workbench 和 Settings 均从新解压候选完成真实显示；Wizard 首次启动同样形成完整显示链。
- 结论：关闭。

### V102-BUG-006

- 根因：复用隐藏的 Settings 或 Wizard 时，确认放弃后的 `confirmClose` 状态没有在隐藏前清理，下一次打开可能立即显示旧确认框。
- 修复：Settings 与 Wizard 的确认回调均先执行 `setConfirmClose(false)`，再取消草稿并隐藏或退出。
- 实证：Settings 深色草稿放弃后重新打开，没有旧确认框，主题与草稿均恢复；静态回归同时约束 Settings 与 Wizard 两处实现。
- 结论：关闭。该缺陷只涉及遗留 `confirmClose`；后续发现的首次配置状态未刷新问题单独登记为 `V102-BUG-007`。

### V102-BUG-007

- 现象：完成首次配置后，从原生托盘点击“重新配置”，关闭 Wizard 时仍显示“退出首次配置？”和“退出应用”。
- 根因：Wizard 的 `firstRun` 只在组件首次挂载时读取。首次配置保存后 Rust 已更新配置初始化状态，但隐藏并复用的 WebView 未重新读取该权威状态。
- 影响：已配置用户可能误以为关闭重新配置会退出整个应用，且危险按钮语义与真实操作上下文不符。
- 修复：首次配置保存后立即设置已配置状态；每次收到 `lmm:window-shown` 时重新读取 `configuration_initialized`；使用递增请求序号防止旧异步结果回写。
- 自动复验：v1.0.2 定向合同、Rust 36/36、配置 9/9、呈现 11/11、主题 5/5、同步 20/20、历史回归、打包和包体验证通过。
- 真实复验：项目所有者从 Windows 原生托盘点击“重新配置”，关闭时确认显示已配置用户语义；日志记录托盘请求、Wizard 显示、隐藏及草稿回滚，应用继续运行。
- 状态：关闭，不构成发布阻塞。

## 本地证据

本轮证据保存在本地验收目录，不纳入发布附件：

- `.tmp_acceptance/v1.0.2-final-20260728-174755/evidence/settings-unsaved-dark-preview.jpg`
- `.tmp_acceptance/v1.0.2-final-20260728-174755/evidence/settings-discard-confirmation.jpg`
- `.tmp_acceptance/v1.0.2-final-20260728-174755/evidence/settings-reopened-no-confirmation.jpg`
- `.tmp_acceptance/v1.0.2-final-20260728-174755/evidence/settings-reopened-after-discard.jpg`
- `.tmp_acceptance/v1.0.2-final-20260728-174755/evidence/final-candidate-debug.log`
- `.tmp_acceptance/v1.0.2-final-20260728-174755/evidence/final-candidate-config.json`
- `.tmp_acceptance/v1.0.2-final-20260728-174755/evidence/manual-wizard-reopen-first-run-dialog.png`
- `.tmp_acceptance/v1.0.2-final-20260728-174755/evidence/manual-tray-and-wizard-debug.log`
- `.tmp_acceptance/v1.0.2-dpi-20260728-181435/evidence/`
- `.tmp_acceptance/v1.0.2-bug007-20260728-193200/evidence/manual-tray-wizard-postfix-debug.log`
- `.tmp_acceptance/v1.0.2-bug007-20260728-193200/evidence/manual-tray-wizard-returned-to-mini.jpg`

DPI 补证覆盖：

- Windows 缩放设置：100% 原始状态、125%、150% 及恢复后的 100%。
- 125%：Wizard 三步、Mini、Workbench、日历、Settings 收入页与外观页、浅色/深色预览。
- 150%：Wizard 首步、Mini、Workbench、日历、Settings 收入页与外观页、浅色/深色预览。
- 日历和 Settings 的底部内容均通过预期滚动完整显示，未发现固定页脚遮挡。

证据身份：

- `final-candidate-debug.log` SHA256：`ABE80304FF15ACB849219B6D2D4772270F5F5108F2F7BAD248F2FB6263611302`
- `final-candidate-config.json` SHA256：`A79299548DE9AC39926310244306FC6C04D51083272C159351A571A5A46173CD`
- `manual-wizard-reopen-first-run-dialog.png` SHA256：`97758D9FE3BE8573C8084C67064C5D3A2456B7474BF53BA28968D61ADA84F422`
- `manual-tray-and-wizard-debug.log` SHA256：`7AECD10F49EAB6D37012A6641763A54D0889C4B0B32308DD761E353E372DBC40`
- `manual-tray-wizard-postfix-debug.log` SHA256：`55816D518ACC3FF0F11AB488B0AD22C90ACEE81789F96B693A5C0AEE121D7621`
- `manual-tray-wizard-returned-to-mini.jpg` SHA256：`B45B13628F8FD97E06DAF15BA8DC5110E2AA758A4F83AC0BA550952AA07B9812`

## 环境恢复

- 已停止全部 LetsMakeMoney 进程。
- 原始 `%APPDATA%\io.letsmakemoney.windows` 配置与日志已恢复。
- 配置恢复后 SHA256：`EA0839031F9DD217B7B2331F9DB961BC3626DDC7862762469DDD7B619A93EE5C`。
- 日志恢复后 SHA256：`DA474CC9492D060B360EED65DC685A481784A42E3079833553D6A25A6ECE59B2`。
- Windows 显示缩放已恢复为验收前的 `100%（推荐）`，注册表 `DpiValue=0`、`Win8DpiScaling=0`。
- 验收结束后 LetsMakeMoney 进程数为 0。

## 剩余门禁

发布阻塞：**无。**

发布收口仍需执行：

1. 创建签核后的发布提交。
2. 从干净提交重新构建并验证最终候选。
3. 更新 Zip、EXE、WebView2Loader 与 `SHA256SUMS.txt` 最终身份。
4. 经项目所有者确认后再执行 push、tag 和 GitHub Release。

当前发布判断：**可进入发布收口；本轮未执行 commit、push、tag 或 GitHub Release。**
