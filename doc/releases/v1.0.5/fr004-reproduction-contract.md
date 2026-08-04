# FR-004 Workbench 关闭异常 20 次真实复现合同

## 1. 目的与停止条件

本合同只回答：关闭 Workbench 后，是否有非用户意图的 Mini 展开、托盘菜单或其他界面出现；若出现，具体是哪一个窗口和哪条事件链触发。

- M0 只建立合同，不执行 20 次操作。
- 复现必须使用同一个已锁定候选、新解压目录和同一配置快照。
- 不得把普通焦点变化、显式托盘找回或预期 Mini 可见状态记为缺陷。
- `0/20` 且无异常界面证据时，结论只能是“未复现、保留观测”，不得写“已修复”。
- 出现至少一次时，必须先锁定窗口标签、关闭方式、事件来源和前后 Mini 状态，才能进入 M3 最小修复。

## 2. 固定前置状态

1. 记录 candidate Zip、EXE、WebView2Loader.dll、BUILD-INFO 和源码 HEAD 的 SHA/身份。
2. Mini 使用右侧停靠、自动隐藏开启、当前状态为 `retracted`。
3. Workbench 由 Mini 主入口打开；不得混用托盘入口。
4. 每轮开始前确认只有 `mini` 与 `workbench` 两个相关窗口；Settings/Wizard 关闭。
5. 每轮关闭方式固定为 Workbench 窗口右上角关闭按钮，关闭行为应进入 native hide，而不是退出应用。
6. 每轮间隔至少 1 秒，等待异步 shown/hidden/focus 和收起 timer 收敛。

## 3. 允许采集的字段

| 字段 | 允许值 / 规则 |
| --- | --- |
| run | `01` 至 `20` |
| relative_ms | 以本轮开始为 0 的相对毫秒，不记系统绝对时间 |
| window_label | `mini`、`workbench`、`settings`、`wizard`、`native_tray_menu`、`unknown` |
| event | `focus`、`blur`、`lmm:window-shown`、`lmm:window-hidden`、`window.show_requested`、`window.visible`、`window.focused`、`window.shown`、`window.hidden`、`window.close_hidden`、`mini.edge.revealed`、`mini.edge.retracted` |
| source | `workbench_primary`、`workbench_close`、`window_focus`、`window_shown`、`tray_restore`、`pointer_enter`、`focus_inside`、`unknown` |
| mini_before / mini_after | `expanded`、`retract_pending`、`retracted`、`not_observed` |
| observed_surface | `none`、`mini_expanded`、`native_tray_menu`、`settings`、`wizard`、`unknown` |
| result | `expected`、`unexpected`、`inconclusive` |

禁止采集窗口标题全文、工资、金额、进度、配置内容、精确窗口坐标、用户名、绝对路径、Token 或完整日志。

## 4. 事件来源判定

| 来源 | 当前 v1.0.4 事实 | 复现时要回答的问题 |
| --- | --- | --- |
| browser `focus` | Hook 调用 `handleShown` | Workbench 关闭后 Mini 获得普通焦点是否触发展开 |
| native `lmm:window-shown` | `show_window_internal` 成功后注入 | 本轮是否发生了显式 show，而不是普通 focus |
| native close hide | 关闭请求调用 `hide_window_internal` | Workbench 是否只发 hidden/close_hidden |
| tray restore | 收起 Mini 时直接调用原生 reveal | 本轮没有托盘操作时不得出现该 source |
| pointer enter | 指针进入 Mini 时 reveal | 指针位置是否真实进入了 Mini/隐私条 |
| focus inside | Mini 内可聚焦控件获得焦点时 reveal | 是否存在 DOM 焦点迁移而非窗口显式找回 |

## 5. 20 次复现表

| Run | 候选身份 | Mini 前态 | Workbench 标签/关闭方式 | 事件时间线索引 | 观察到的界面 | Mini 后态 | 结果 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 01 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#1` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 02 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#2` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 03 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#3` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 04 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#4` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 05 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#5` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 06 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#6` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 07 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#7` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 08 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#8` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 09 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#9` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 10 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#10` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 11 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#11` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 12 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#12` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 13 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#13` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 14 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#14` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 15 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#15` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 16 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#16` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 17 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#17` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 18 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#18` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 19 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#19` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |
| 20 | v1.0.4 official | `retracted` | `workbench` / 关闭按钮 | `m2-summary#20` | `mini_expanded` | `expanded` | `unexpected` | ordinary focus |

M2 实际结果：20/20 复现。每轮没有原生 Mini `window.shown`，普通 focus 后却记录 `source=window_shown` 的 Mini reveal；界面身份确认为 Mini 展开态。完整脱敏机器摘要见 `evidence/m2-characterization-summary.json`，校准轮不计入上表。

## 6. 判定与后续路由

| 结果 | FR-004 路由 |
| --- | --- |
| 0/20，事件链只含 Workbench hidden/close_hidden，Mini 未异常展开 | `未复现`；M3 不改生产 focus/shown 语义，保留观测证据 |
| 至少 1/20，Mini 展开且由普通 focus 单独触发 | 进入 M3，只分离普通 focus 与 explicit shown |
| 至少 1/20，出现原生托盘菜单 | 先锁定原生菜单来源，禁止用 Mini focus 修复掩盖 |
| 至少 1/20，但窗口或 source 无法识别 | `inconclusive`；补采集，不进入实现 |
| 候选身份、配置或关闭方式中途变化 | 本轮 20 次全部失效，重新执行 |

复现结论必须写入 `progress_v1.0.5.md` 的状态入口与 `dev_log_v1.0.5.md` 的详细记录；原始截图/录屏保存在仓库外，仓库内只保存脱敏摘要和索引。
