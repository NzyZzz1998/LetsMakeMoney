# LetsMakeMoney Windows v1.0.4 人工验证

## 当前结论

结论：**通过。**

隔离干净提交候选已完成真实 Windows 100%/125%/150% DPI、深色主题、减少动态效果、首次配置、日历事务、Mini 左右隐私贴边及通知区真实鼠标找回复验。当前环境只有单显示器；项目所有者已批准将真实多显示器、负坐标工作区和显示器移除回落延期验证，该项记录为“暂不验证”，不阻塞 v1.0.4 进入发布收口。

## 验收对象

- 分支：`main`
- 构建基线：`661b0f748798e28f7999eac23532aa7ed7510640`
- 源码状态：`source_tree_dirty=false`
- Zip：`LetsMakeMoney-v1.0.4-windows-x86_64.zip`
- Zip 大小：`3,229,111` 字节
- Zip SHA256：`2BBC5B79F9A615F31CFDFFC27C55450C660363A643DE5EB33A6E7B3A1B049340`
- EXE 大小：`10,108,416` 字节
- EXE SHA256：`EB0FA82F5506B775F03774E429A12DB66F838E705B608F4A7664D6F9243830DF`
- WebView2Loader 大小：`160,320` 字节
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- Windows：Windows 11 Pro `10.0.26200`
- WebView2：`150.0.4078.105`
- 实际系统缩放：100%、125%、150%；验收结束恢复为 100%

## 分项结果

| ID | 场景 | 结果 | 真实结果 |
| --- | --- | --- | --- |
| V104-MAN-001 | 右侧工作区边缘停靠 | 通过 | 拖至右边缘后进入停靠并收起，只保留隐私唤回条 |
| V104-MAN-002 | 左侧工作区边缘停靠 | 通过 | 拖至左边缘后进入停靠并收起，只保留隐私唤回条 |
| V104-MAN-003 | 收起隐私 | 通过 | 收起态不显示工资、阶段、时间或日期 |
| V104-MAN-004 | 悬停/点击展开与移开收回 | 通过 | 展开内容完整；指针移开后按状态机重新收起 |
| V104-MAN-005 | 跨窗口关闭“贴边自动隐藏” | 通过 | Settings 保存关闭后，已收起 Mini 立即恢复完整内容，不再出现空白全尺寸窗口 |
| V104-MAN-006 | 关闭开关后的移开行为 | 通过 | 指针移开后 Mini 保持完整，不再自动收起 |
| V104-MAN-007 | 重启持久化 | 通过 | 重启后开关保持关闭，停靠状态为 floating |
| V104-MAN-008 | 100% DPI | 通过 | Mini 完整态和隐私唤回条无裁切、错位或不可达 |
| V104-MAN-009 | 125% DPI | 通过 | Mini 347×110、Workbench 923×642、Settings 762×562，无裁切、重叠或模糊 |
| V104-MAN-010 | 150% DPI | 通过 | Mini 348×111、Workbench 924×643、Settings 763×562，无裁切、重叠或模糊 |
| V104-MAN-011 | 深色主题 | 通过 | Mini、Workbench、Settings 即时同步；重启后保持深色 |
| V104-MAN-012 | 减少动态效果 | 通过 | 关闭 Windows 动画效果后，右侧收起直接进入 3px 隐私条，无崩溃或残留过渡 |
| V104-MAN-013 | 多显示器与负坐标 | 暂不验证 | 纯几何门禁通过；当前没有真实硬件，项目所有者于 2026-07-31 批准延期，不作为 v1.0.4 发布阻塞 |
| V104-MAN-014 | 首次启动 Wizard | 通过 | 全新隔离配置完成三步流程；返回保留月薪；取消/关闭确认和完成路径正确 |
| V104-MAN-015 | Workbench 今日与日历 | 通过 | 今日时间线、2026 官方日历、7 月/8 月跨月和返回正常 |
| V104-MAN-016 | 日期调整取消事务 | 通过 | 选择带薪休息后取消，日期仍为自动工作日，未产生持久化污染 |
| V104-MAN-017 | 通知区真实鼠标找回 | 通过 | 项目所有者真实左键点击通知区图标；首次隐藏、再次恢复，进程持续运行且日志事件完整 |

## 通知区补证

- 验证时间：2026-07-31。
- 输入方式：项目所有者使用真实鼠标左键点击 Windows 通知区中的 LetsMakeMoney 图标，Computer Use 负责前后窗口观察。
- 首次点击：Mini 从 Windows 窗口列表消失，`LetsMakeMoney.exe` 继续运行。
- 再次点击：同一 Mini 窗口恢复，内容正常，进程未重启。
- 日志顺序：`tray.left_click action=toggle_mini` → `window.hidden label=mini` → `tray.left_click action=toggle_mini` → `window.shown label=mini` → `earnings.authoritative_sync.requested reason=window_shown`。
- 候选 EXE SHA256：`EB0FA82F5506B775F03774E429A12DB66F838E705B608F4A7664D6F9243830DF`，与锁定候选一致。
- 结论：真实通知区左键隐藏、恢复和窗口找回通过。

## 缺陷复验

### 收起状态关闭设置后出现空白窗口

- 原现象：Mini 已收起时从 Settings 关闭自动隐藏，原生窗口恢复完整尺寸，但 Mini 前端仍停留在隐私标签分支。
- 根因：Mini 窗口没有订阅其他窗口发出的 `configuration-updated`。
- 修复：
  - Configuration Service 增加配置更新 listener 和 disposer。
  - Mini Hook 收到更新后重新读取权威配置并刷新停靠状态。
  - 增加跨窗口关闭开关与 listener 清理行为测试。
- 真实复验：通过。保存关闭后 Mini 立即显示完整内容，移开后保持完整；重启后配置仍为关闭。

## 日志证据

验收期间的脱敏语义计数：

| 事件 | 数量 |
| --- | ---: |
| `mini.edge_dock.detected` | 15 |
| `mini.edge_dock.retracted` | 13 |
| `mini.edge_dock.revealed` | 9 |
| `mini.edge_dock.canceled` | 7 |
| `settings.saved` | 9 |
| `tray.left_click` | 2 |
| `window.hidden` | 11 |
| `window.shown` | 31 |
| `calendar.override.opened` | 1 |
| `calendar.override.cancelled` | 1 |

日志确认左右边缘均出现 detected/retracted/revealed 序列；关闭设置时出现 `mini.edge_dock.canceled reason=settings_disabled`；日历调整打开和取消事件成对出现。未发现工资、精确坐标或用户路径被写入 Mini 贴边语义事件。

## 证据边界

- 机器可读摘要：`evidence/acceptance-summary.json`。
- 人工可读摘要：`evidence/acceptance-summary.md`。
- Computer Use 截图未建立持久外部归档，因此原始证据状态为 `not_collected`；本清单不把它写成已归档。
- 候选来自隔离干净提交，但尚不是最终发布提交；哈希或源码提交变化后，本文件中的候选级 GUI 证据必须按发布门禁重新评估。

## 用户环境恢复

- [x] 主验收结束时，普通用户配置、前一版本配置与日志的 SHA256 均与验收前一致。
- [x] Codex 隔离 Roaming 目录的配置与日志 SHA256 均与验收前一致。
- [x] 全部 LetsMakeMoney 进程已停止，进程数为 `0`。
- [x] Windows 系统缩放恢复为 100%，动画效果恢复开启。
- [ ] Computer Use 原始截图外部归档未建立。

通知区补证没有执行配置保存，补证结束后进程数恢复为 `0`；本次真实托盘事件已追加到本机 `debug.log`，未把日志写回或伪装为主验收结束时的原始哈希状态。

## 暂不验证与发布收口

1. 真实双显示器、负坐标工作区与移除显示器后的安全回落延期至具备硬件环境时验证，不得在后续文档中追溯写成已通过。
2. 发布提交确定后重新构建、锁定哈希，并按变更影响重新评估本轮证据。

## 非阻塞观察

- Mini WebView 内右键会显示 WebView2 浏览器上下文菜单，而不是产品菜单；不影响本版隐私贴边主链路，建议后续作为桌面质感问题单独评估。
- 减少动态效果下的收起已通过；由于隐私条仅 3px，Computer Use 无法稳定点击完成该模式下的独立唤回。正常动态模式下的唤回已经通过。
