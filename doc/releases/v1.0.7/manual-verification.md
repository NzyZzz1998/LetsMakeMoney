# LetsMakeMoney Windows v1.0.7 手动验收

> 状态：首次独立验收未通过；三项发布阻塞随后完成修复并通过真实 GUI 定向复验。锁定 dirty 候选的验收现已通过，真实 100%/125%/150% DPI、通知区真实鼠标组合与最终自动 current gate 均已完成；干净发布身份尚未建立，dirty 候选禁止发布。

## 对象锁定

- Candidate ID：`V107-M7-DIRTY-20260803-01`。
- 分支：`main`；source HEAD：`12b6b03ce91b716d49590e21eb8dd7fe90fa283c`；工作树：dirty。
- Zip：`.artifacts/candidates/v1.0.7/V107-M7-DIRTY-20260803-01/LetsMakeMoney-v1.0.7-windows-x86_64.zip`。
- Zip SHA256：`173207AE508DB8D8504818F16B21165164E6C50C29ABF74C4C4D5C08B40CC05D`。
- EXE SHA256：`760C0E80952181BA80352187DCCE9C6823F3BE19B0EC1BC04553ACCC34156035`。
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- README SHA256：`783856D9EFC21005BA3C1ABADDDFAABD98D00144BF3FC491D70150BF7C4E65CA`。
- README.en SHA256：`15EFFE0DE88F566AC56CF7750DDB4CEF01A30AE9DEB23493372F1940CC85BBC5`。
- BUILD-INFO SHA256：`DB4E9A1371F170071C4C1A9A8B6F0C020BFAFD0BD8CB69C8063492921FB06517`。
- 外部验收会话：`ACC-V107-20260804`；仅运行该会话独立解压目录中的 EXE。
- 实际 EXE：`candidate/LetsMakeMoney-v1.0.7-windows-x86_64/LetsMakeMoney.exe`；大小 `10,297,344` 字节。
- 环境：Windows 11 x86_64、单显示器、100% DPI；后续 DPI 候选补齐 125%/150% 实际系统缩放。

## 修复候选与定向复验

- Evidence ID：`V107-ACCEPTANCE-FIX-20260804-01`。
- Candidate ID：`V107-M7-DIRTY-20260804-02`。
- Zip：`.artifacts/candidates/v1.0.7/V107-M7-DIRTY-20260804-02/LetsMakeMoney-v1.0.7-windows-x86_64.zip`；大小 `3,317,706` 字节。
- Zip SHA256：`EF57B0361B379B0D009EBD014B8717B4D7FA50C08330B297C3071A8171E56D47`。
- EXE：大小 `10,271,744` 字节；SHA256 `37DE58BCD9FE1F0FE41C0F31AA640E68C4A07004A9E9BC6E4C26B0FB6236FB98`。
- WebView2Loader：大小 `160,320` 字节；SHA256 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- Source HEAD 仍为开发基线且 source tree dirty；`publication_allowed=false`。
- 定向范围：`V107-BUG-001`、`V107-BUG-002`、Mini 恢复链路、用户环境恢复。

## DPI 修复候选与定向复验

- Evidence ID：`V107-ACCEPTANCE-DPI-20260804-01`。
- Candidate ID：`V107-M7-DIRTY-20260804-03`。
- Zip：`.artifacts/candidates/v1.0.7/V107-M7-DIRTY-20260804-03/LetsMakeMoney-v1.0.7-windows-x86_64.zip`；大小 `3,317,755` 字节。
- Zip SHA256：`322EB52DD01AE3B9BEE50EC3346B027C2AEA6E4669505735D01A493A3028A6E5`。
- EXE：大小 `10,271,744` 字节；SHA256 `91F9EB87FBA35F7A6B3165A4E25CF05E544CDC598CB329FFC150ED416072BA46`。
- WebView2Loader：大小 `160,320` 字节；SHA256 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- Source HEAD 仍为开发基线且 source tree dirty；`publication_allowed=false`。
- 首次 DPI 失败：`V107-M7-DIRTY-20260804-02` 在六周月份的月度总结出现重叠，失败截图保留。
- 定向范围：修复后的六周日历、月度总结、图例、125%/150% 实际系统缩放与用户环境恢复。

## 环境保护

验收前已备份配置、加班记录、日志和窗口位置。验收结束后所有候选进程均已停止，原始 `config.json`、`config.json.previous` 与 `debug.log` 的 SHA256 与验收前完全一致；原环境不存在的加班记录文件没有被遗留。多显示器暂不验证，Windows 10 无真实环境时收窄支持声明。

## 验收清单

| ID | 范围 | 结论 | 证据与说明 |
| --- | --- | --- | --- |
| V107-ACC-001 | 候选身份 | 通过 | 分支、HEAD、dirty 标记及 Zip/EXE/DLL 哈希与锁定对象一致。 |
| V107-ACC-002 | 独立运行 | 通过 | 只运行独立解压 EXE；验收前后用户状态哈希一致。 |
| V107-ACC-003 | 始终置顶 | 通过 | 默认配置、设置入口与窗口行为通过；托盘真实鼠标隐藏/恢复及任务栏组合补证通过。 |
| V107-ACC-004 | Mini/Workbench | 通过 | 首次验收失败记录保留；修复候选连续打开/关闭三次，第 2、3 次各等待 9.5 秒仍可见，timeout 为 0，见 V107-BUG-002。 |
| V107-ACC-005 | Mini 自动隐藏 | 通过 | 精确贴边后进入隐私竖条，指针进入展开、移开重新收起；日志事件成对。 |
| V107-ACC-006 | 拖动与回落 | 部分通过 | 单显示器 100% DPI 的拖动、贴边和可见抓取区通过；125%/150% 已完成视觉与窗口布局复核，未重复完整拖动矩阵。 |
| V107-ACC-007 | 日期调整 | 通过 | 今日与日历打开同一事务；应用和恢复均有真实 GUI 证据。 |
| V107-ACC-008 | 加班记录 | 通过 | 新建、保存、月度汇总和删除通过；最终补证进一步覆盖休息日 1.25 小时、跨夜 owner date 0.5 小时及两次重启持久化，分钟换算与月度汇总一致。 |
| V107-ACC-009 | 月度总结 | 通过 | 六周日历、月度统计和一屏布局通过。 |
| V107-ACC-010 | Combobox/窗口表面 | 通过 | 指针、键盘、Escape、双主题及 100%/125%/150% DPI 表面通过。 |
| V107-ACC-011 | DPI | 通过 | 真实 Windows 100%/125%/150% DPI 已完成；六周日历摘要首次失败后修复并定向复验通过。 |
| V107-ACC-012 | 核心回归 | 通过 | 首次验收失败记录保留；修复候选关于页显示 `1.0.7`，检查更新返回“当前已是最新版本”，见 V107-BUG-001。 |
| V107-ACC-013 | 支持边界 | 部分通过 | Windows 11 单显示器 100% DPI 已验证；Windows 10 未验证，多显示器暂不验证。 |
| V107-ACC-014 | 收口 | 部分通过 | 三项产品阻塞已关闭且用户环境已恢复；项目所有者已批准发布收口，干净提交重建与最终身份复核仍未完成。 |

## 真实截图与日志

- GUI 原始截图：`ACC-001` 至 `ACC-028`，覆盖 Mini、Workbench、日历、日期调整、加班、Settings、主题、Combobox、隐私竖条及 Wizard。
- 首次配置：`ACC-023` 至 `ACC-028` 覆盖第一步、第二步、返回、确认、取消确认和完成。
- 阻塞截图：`ACC-017-version-read-failed.png`。
- 运行日志：`ACC-runtime-debug-normal.log` 与 `ACC-runtime-debug-codex-sandbox.log`。
- 定向复验截图：`ACC-FIX-001` 至 `ACC-FIX-008`，覆盖三次 Workbench 事务、版本读取、更新检查和 Mini 恢复。
- 定向复验日志 SHA256：`B89B36AD6A393F008F2E9734B992A08173059AE4897B3810CF5811F8EBB2FA97`；脱敏摘要见 `evidence/acceptance-fix-summary.json`。
- 首次 DPI 截图覆盖 Mini、Workbench、Settings、Wizard、Combobox 和六周日历；六周日历在 125%/150% 的失败证据继续保留。
- 修复后 DPI 截图：`DPI-125-calendar-six-week-summary-fixed.png`，SHA256 `14EA8C682517291A5D316130333333D8EA8276E31AA37DF5D018C9F781913563`；`DPI-150-calendar-six-week-summary-fixed.png`，SHA256 `240DD5AF8FBB33E94BE12A2FA28610A6C02C676FDE7ACD80CEEE6D1E66934E56`。
- DPI 脱敏摘要见 `evidence/acceptance-dpi-summary.json`。
- 最终补证截图：`ACC-COMP-001` 至 `ACC-COMP-007`，覆盖休息日加班、跨夜 owner date、重启持久化及关闭 Workbench 后恢复 Mini；脱敏摘要见 `evidence/acceptance-completion-summary.json`。
- 托盘真实鼠标补证：左键隐藏、再次左键恢复、右键原生菜单和任务栏组合通过；脱敏摘要见 `evidence/acceptance-tray-summary.json`。
- 外部证据未进入仓库；仓库只保存脱敏结论和候选身份。

## 已关闭的发布阻塞

1. `V107-BUG-001`：最小 app version capability 已接入；关于页和更新检查真实 GUI 定向复验通过。
2. `V107-BUG-002`：复用窗口按精确 transaction 完成原生确认；三次事务 requested/open/closed 均为 3，timeout 与 initialization timeout 均为 0。
3. `V107-BUG-003`：六周日历摘要改为稳定双列结构；真实 125%/150% DPI 下无裁切、重叠或文本溢出。

## 剩余发布门禁

1. 创建干净发布提交。
2. 从干净提交重建最终候选，复核 Zip、EXE、DLL、BUILD-INFO 与 SHA256SUMS。

## 待人工补证与暂不验证

- 未验证并收窄：Windows 10。
- 暂不验证：多显示器。

## 结论词汇

每项只能使用：通过、部分通过、未通过、待人工补证、暂不验证。浏览器模拟 DPI 不能替代真实 Windows DPI，自动测试不能代替桌面 GUI。

## 发布边界

首次失败候选与两轮修复候选的身份均只用于锁定对应 GUI 证据。三项产品阻塞已经关闭，真实 100%/125%/150% DPI 与托盘真实鼠标组合均已完成，锁定 dirty 候选验收通过；但最新候选仍满足 `source_tree_dirty=true`，不得上传 GitHub Release、创建 tag 或宣称为最终发布包。项目所有者已批准发布收口，只有从干净提交重建并复核最终身份后，才可执行 tag 与 Release。
