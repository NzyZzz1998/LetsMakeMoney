# LetsMakeMoney Windows v1.0.5 发布后观察

## 观察结论

**部分通过。** GitHub 正式附件身份、首次启动后的核心读取路径、休息日信息、日历、Settings 无变化保存、更新检查、隐私贴边收起及关闭 Workbench 后保持收起均通过。发现 1 项非阻塞视觉一致性缺陷：配置为浅色主题时，新打开的 Workbench 首帧可能仍显示深色主题；在 Settings 执行一次无变化保存后，各窗口会收敛为浅色主题。

该问题不影响收入、日历、配置数据、隐私收起或程序可用性，因此 **v1.0.5 Stable 继续公开提供，无需撤回或替换附件**。问题编号为 `V105-POST-001`，建议进入下一维护版本的 Review / Bugfix，不改写 v1.0.5 发布前验收结论。

## 阶段与对象

- 子阶段：v1.0.5 发布后观察。
- 观察日期：2026-08-02。
- 观察工作树：`postrelease/v1.0.5-observation`，HEAD `67dc345f4f6e2de6756847573c24fdab13a4fdba`。
- Release 源提交：`ffc431af3fbf7c3b54bca8aaff44946cc8d6aeaf`。
- annotated tag：`v1.0.5`，tag object `7d7734ca1f45d24672a46523ae4bd93cfaf201fb`。
- GitHub Release：<https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.5>。
- Release 状态：Stable、非草稿、非预发布。
- 附件：便携 Zip 与 `SHA256SUMS.txt`，共 2 个。

## 正式附件身份

本轮从 GitHub Release 全新回下载，不使用本地历史候选或构建目录。

| 对象 | 大小 | SHA256 |
| --- | ---: | --- |
| `LetsMakeMoney-v1.0.5-windows-x86_64.zip` | 3,231,663 字节 | `019B706E18E7D57D0B7E6DBFB6300762422B5723A11EB6ACCB601DA438215889` |
| `SHA256SUMS.txt` | 107 字节 | `E84F6F01A6A703829926AC684325C3B2A6D6737AADB2381880BF4EDE962C6741` |
| `LetsMakeMoney.exe` | 10,110,464 字节 | `68FA8FC443B12A2BA8BD757F532EC6B90E09E3DA7E1027255267150C4DAEC37A` |
| `WebView2Loader.dll` | 160,320 字节 | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |

`BUILD-INFO.txt` 记录版本 `1.0.5`、`source_head=ffc431af3fbf7c3b54bca8aaff44946cc8d6aeaf`、`source_tree_dirty=false`，与正式发布身份一致。

## 使用工具与证据来源

- GitHub Release / 回下载：核对 tag、Release 元数据、附件数量、名称和实际下载内容。
- PowerShell：`Get-FileHash`、文件大小、进程、注册表与用户状态前后对照。
- Computer Use：只运行全新解压目录中的正式 EXE，实际观察 Mini、Workbench、日历、Settings、更新检查与贴边隐私状态。
- 日志与配置：读取本轮运行产生的 `debug.log` 与 `config.json`；报告只记录脱敏事件和哈希，不复制用户原始内容。
- 原始证据：本轮曾保存在 Git 忽略的本机临时目录；按证据合同不作为仓库永久附件，结论固化后已清理。
- 环境：Windows 11、单显示器、100% DPI。Windows 10 和真实多显示器未在本轮重测。

## 新测结果

| ID | 预期 | 实际结果与证据 | 结论 |
| --- | --- | --- | --- |
| POST-001 | GitHub 回下载对象与 Release 身份一致 | Zip、EXE、DLL、checksum、`BUILD-INFO.txt` 与锁定身份一致 | 通过 |
| POST-002 | 休息日 Mini 不展示无意义收入和有效工时 | 2026-08-02 显示“休息日 / 今天没有工作安排 / 安心休息 / 下一个工作日 8/3 09:00”；原始截图编号 `POST-V105-MINI-001.png` | 通过 |
| POST-003 | Workbench 休息日文案与计算口径一致 | 显示休息日、无工作安排，并明确不计算有效工时、工作进度和今日收入；原始截图编号 `POST-V105-WORKBENCH-001.png` | 通过 |
| POST-004 | 日历正常态不显示常驻来源块，并区分今天与业务状态 | 2026 年 8 月正常加载，8 月 2 日同时表达“今天”和休息日；未出现常驻绿色来源块；原始截图编号 `POST-V105-CALENDAR-001.jpg` | 通过 |
| POST-005 | Settings 可读取配置并正确处理无变化保存 | 五个设置分组可打开；点击保存后提示“没有需要保存的更改”，配置文件哈希未变化；原始截图编号 `POST-V105-SETTINGS-NOCHANGE-001.jpg` | 通过 |
| POST-006 | 正式包能检查当前版本状态 | 实际点击“检查更新”，返回“当前已是最新版本”；日志记录 `update.checked status=up_to_date`；原始截图编号 `POST-V105-UPDATE-001.jpg` | 通过 |
| POST-007 | 隐私贴边态不泄露收入，关闭 Workbench 后不应意外展开 | 收起态仅显示“今日休息”；关闭 Workbench 前后均保持窄条，未显示金额；原始截图编号 `POST-V105-MINI-EDGE-BEFORE-CLOSE.jpg`、`POST-V105-MINI-EDGE-AFTER-CLOSE.jpg` | 通过 |
| POST-008 | 已保存浅色主题应在各窗口首次显示时一致恢复 | `config.json` 为 `theme_mode=light`，但新打开 Workbench/日历先显示深色；Settings 无变化保存触发 `theme.preview_applied theme=light reason=unchanged` 后才切回浅色；原始截图编号 `POST-V105-CALENDAR-001.jpg`、`POST-V105-CALENDAR-AFTER-NOCHANGE-SAVE.jpg` | 未通过 |

## 日志语义核对

- Workbench 隐藏时出现 `window.hidden`、`window.webview_suspend_requested`、`dashboard.lifecycle.paused` 和 `window.webview_suspend_completed suspended=true`。
- Mini 独立保持权威同步，符合窗口生命周期合同。
- 关闭 Workbench 后未出现 Mini 隐私态被错误 reveal 的实际现象。
- 更新检查出现 `update.checked status=up_to_date`。
- 主题问题实际出现 `theme.preview_applied theme=light reason=unchanged`，说明无变化保存承担了本应在窗口初始化完成的主题收敛。

## 证据继承

| 验收范围 | 状态 | 继承依据 | 本轮处理 | 失效条件 |
| --- | --- | --- | --- | --- |
| 正式发布身份与包内容 | 新测通过 | GitHub Release | 全新回下载并重算哈希 | Release 附件或 tag 身份变化 |
| 休息日、日历、Settings、更新、贴边隐私、Workbench 关闭 | 新测通过 | 正式附件 | 使用同一正式 EXE 实际操作 | 正式附件变化 |
| 左右边缘首次收起、悬停/移开、点击/键盘找回、真实通知区左键 | 继承通过 | `ACC-20260801-105930-retest` | 本轮定向确认收起态和关闭 Workbench，不无理由重跑全部动作 | Mini、托盘或窗口实现变化 |
| 125% / 150% DPI | 继承通过 | v1.0.5 发布前 M5 真实 Windows 证据 | 正式发布业务实现未变化；本轮不重复切换系统 DPI | UI/CSS、WebView2 或窗口尺寸合同变化 |
| 多显示器 | 暂不验证 | 项目所有者已批准延期 | 本轮仍为单显示器 | 获得真实多显示器环境后补证 |
| Windows 10 | 待验证 | 无 Windows 10 设备或 VM | 不以 Windows 11 推断 | 获得 Windows 10 环境后补证 |

## 新发现问题

### V105-POST-001：Workbench 首次显示时未立即采用已保存主题

- 证据状态：已确认。
- 严重度：Minor，非发布阻塞。
- 用户影响：同一应用的 Mini、Workbench 和 Settings 可能短暂或持续呈现不同主题，降低视觉一致性；无数据丢失、计算错误或隐私泄露。
- 最小修复方向：让每个 WebView 在首帧前从统一配置恢复主题；`window-shown` 仅负责生命周期恢复，不应依赖 Settings 保存事件纠正主题。
- 回归保护：覆盖浅色和深色、首次启动和重启、Mini/Workbench/Settings/Wizard、隐藏后恢复，以及无变化保存不改变主题。
- 建议去向：下一维护版本 Review / Bugfix。

## 未关闭缺口

| 未关闭缺口 | 最小补证动作 | 所需证据 | 通过标准 |
| --- | --- | --- | --- |
| `V105-POST-001` 跨窗口主题首帧不一致 | 使用浅色和深色配置分别冷启动，依次打开 Mini、Workbench、Settings 和 Wizard；在任何保存操作前截图并读取日志 | 同一候选的配置前后哈希、四窗口首次显示截图、主题初始化日志 | 所有窗口首帧即采用已保存主题；无变化保存不再承担主题纠正 |
| Windows 10 未覆盖 | 在 Windows 10 受控设备或 VM 中运行正式 Zip，完成启动、窗口、托盘和退出冒烟 | 系统版本、EXE 哈希、截图、日志与环境恢复记录 | 正式 EXE 可启动，核心窗口和托盘链路无阻塞 |
| 真实多显示器未覆盖 | 在双显示器环境验证左右边缘、负坐标、拔除/禁用副屏后的安全回落 | 显示器布局、操作前后截图、窗口位置与日志 | 窗口不丢失，隐私条方向正确，显示器变化后可找回 |

## 用户环境恢复

- `config.json`、`config.json.previous` 和 `debug.log` 已从测试前备份恢复，三者 SHA256 均逐项一致。
- 开机自启注册表值测试前后均为不存在。
- LetsMakeMoney 残留进程数为 0。
- 测试产生的解压目录和原始证据已按合同清理，不混入用户数据目录或正式 Release。

## 发布面判断

| 发布面 | 判断 | 说明 |
| --- | --- | --- |
| 源码仓库 | 继续公开 | 本轮未发现需要转私有或回滚的问题 |
| v1.0.5 便携包 | 继续公开 | 核心链路通过；主题问题非阻塞，不替换附件 |
| 安装器 / 商店包 | 不适用 | v1.0.5 Release 未提供这些产物 |
| v1.0.5 版本整体 | 保持已发布 | 不撤回、不重打 tag、不重建附件 |
| 本地提交 | 暂不执行 | 本轮仅固化发布后观察文档，未执行提交 |
| 远端 push | 暂不执行 | 未执行远端写入 |
| tag | 暂不执行 | 既有 `v1.0.5` 不得修改 |
| Release / 附件 | 暂不执行 | 既有 Release 与附件保持不变 |
| 仓库可见性 | 暂不执行 | 无需改变 |

## 后续动作

1. 保持 v1.0.5 Stable 公开可用。
2. 将 `V105-POST-001` 作为下一维护版本的真实缺陷输入，先 Review 影响范围，再定向修复和复验。
3. Windows 10 与真实多显示器继续保留为环境补证项，不冒充通过。
