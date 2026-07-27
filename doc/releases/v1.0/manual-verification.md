# LetsMakeMoney Windows v1.0 人工验证

## 当前状态

M7 独立候选包核心黄金路径、三档真实 DPI 与长期运行已通过。多显示器安全回落因当前设备只有一台显示器而待补证；项目所有者批准其不阻塞本次 Stable。

## 必须真实验证

| ID | 项目 | 阶段 | 当前状态 |
|---|---|---|---|
| `V10-MAN-001` | 100%、125%、150% 系统缩放下四窗口布局 | M1/M7 | 通过；三档真实 Windows 缩放均完成 GUI 检查 |
| `V10-MAN-002` | 通知区真实鼠标左键隐藏与找回迷你视图 | M5/M7 | 通过 |
| `V10-MAN-003` | Explorer 重启后托盘图标重新注册 | M5/M7 | 通过 |
| `V10-MAN-004` | 多显示器变化后的窗口安全回落 | M5/M7 | 待补证；当前环境不具备，项目所有者批准不阻塞本次 Stable |
| `V10-MAN-005` | v0.9 配置迁移、失败保存和回退 | M2/M7 | 通过；官方 v0.9 Release 包可独立启动，旧版与 v1 配置目录隔离，测试后已恢复用户环境 |
| `V10-MAN-006` | 独立解压便携 Zip 首次启动与长期运行 | M7 | 通过；约 95 分钟连续运行无资源漂移，项目所有者确认按约 100 分钟门禁通过 |

## 已完成的真实操作

- 从 `.tmp_acceptance/v1.0-final-20260724-172154/extracted/` 启动候选 EXE。
- 无配置首次启动进入三步 Wizard。
- 完成后显示迷你收入视图，并可打开 Today、Calendar 和 Settings。
- Settings 首次打开读取到 Wizard 刚保存的月薪 `10000`。
- Settings 无变化保存反馈正确。
- 验收后停止进程并恢复验收前配置与日志。
- 从 GitHub `v0.9-beta` Release 下载并校验官方 Zip，SHA256 为 `B10FDE2027D4ABC71C41F0F7AC7BDCE3D93AEB8AFAF4058BA1A592B6A75CC1EC`。
- 从 `.tmp_acceptance/v0.9-rollback-20260724/extracted/` 启动官方 v0.9 EXE；日志确认 `app_started: version=0.9-beta`，原生窗口、托盘、任务栏和点击穿透能力均可用。
- v0.9 仅写入 `%APPDATA%\LetsMakeMoney\debug.log`；v1 的 `config.json`、`config.json.previous`、`debug.log` 与测试前哈希完全一致。
- v0.9 测试进程已停止，旧版用户目录顶层文件已恢复到测试前状态。
- 从锁定 Zip 重新解压并启动 v1 候选，应用窗口可见且托盘注册日志正常。
- 使用真实 Windows 通知区图标完成左键恢复、左键隐藏和再次左键恢复。日志按顺序记录 `tray.left_click`、`window.hidden label=mini`、`window.show_requested label=mini`、`window.policy_applied label=mini skip_taskbar=true`、`window.shown label=mini`。
- 迷你窗口恢复后没有任务栏入口；Settings 打开时任务栏入口存在，关闭后入口正常消失。
- 通知区复验证据：`.tmp_acceptance/v1.0-final-20260724-172154/evidence/tray-restore-0.jpg`、`tray-restore-1.jpg`、`tray-left-click.log`。
- 主动结束并重启 Explorer 后，应用进程保持运行，托盘自动重新注册；重启后真实左键隐藏与恢复继续有效，迷你窗口恢复后没有任务栏入口。证据：`explorer-restart-tray-restore.jpg`、`explorer-restart-tray.log`。
- 使用新候选 EXE（SHA256 `286F99D3B6C03B4D22362E968502C5644562CE2CCA7B8B892184547BC32B5334`）复验迷你收入视图、Today、Calendar 和 Settings 四任务组；无变化保存反馈正确，配置哈希未变化，进程已停止。
- 在真实 Windows 显示设置中依次切换 125% 与 150%，分别检查迷你收入视图、Today 工作台、Settings 和 Wizard；窗口逻辑尺寸稳定，文字、控件和底部操作区均无裁切、重叠或异常缩放。
- 三档 DPI 证据：`.tmp_acceptance/v1.0-final-20260724-172154/evidence/dpi-125-mini.png`、`dpi-125-workbench.png`、`dpi-125-settings.png`、`dpi-125-wizard.png`、`dpi-150-mini.png`、`dpi-150-workbench.png`、`dpi-150-settings.png`、`dpi-150-wizard.png`。
- DPI 复验结束后系统缩放已恢复为原始 `100% (推荐)`；验收期间生成的 Wizard 配置已移出用户目录，原配置 SHA256 恢复为 `02297DC840464938AEB0A9B83898842865CC98742DC2BCEA0E9E89338BF4E7DA`。
- 锁定候选连续运行约 95 分钟；10 至 90 分钟每 10 分钟采样的工作集稳定在 `37.51–37.52 MB`，私有内存 `12.43 MB`，CPU 累计 `0.41 秒`，句柄数 `414`，未观察到资源漂移或应用自行退出。
- 原计划 120 分钟观察因验收工具会话结束而中止；项目所有者明确接受该结果作为约 100 分钟长期运行门禁通过。证据：`soak-owner-accepted-summary.json` 与 `soak-owner-accepted-95m-debug.log`。

## 结论规则

- 自动测试只能作为辅助证据，不能替代真实桌面行为。
- 未执行项只能写“待验证”或经批准写“暂不验证”。
- 任一配置污染、窗口不可找回、迁移失败或三档 DPI 裁切均阻塞 Stable 发布。
- 多显示器不写为通过；本次仅按项目所有者批准记录为非阻塞待补证项。

## 迷你收入视图拖动复验

- 结论：通过。
- 从独立解压目录 `.tmp_acceptance/v1.0-drag-capability-20260724-234710/` 启动候选 EXE。
- 使用真实 Windows 鼠标在顶部拖动柄按住并移动，窗口坐标由 `(1108, 636)` 变为 `(988, 706)`。
- `%APPDATA%\io.letsmakemoney.windows\config.json` 同步保存新坐标，`debug.log` 记录 `window.position_saved detail=label=mini x=988 y=706`。
- 停止并重新启动相同候选后，窗口恢复到保存位置；点击收入主体仍可打开“LetsMakeMoney 今日工作台”。
- Computer Use 的快速合成拖动无法维持按住时长，因此最终使用带停顿的真实 Windows 鼠标输入补证；窗口截图和配置、日志共同作为结果证据。
