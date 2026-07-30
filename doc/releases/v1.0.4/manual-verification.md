# LetsMakeMoney Windows v1.0.4 人工验证

## 当前结论

结论：**部分通过。**

Mini 隐私贴边的核心 Windows 行为已在 100% DPI 下完成真实 GUI 复验；125%/150% DPI、深色主题、减少动态效果和真实多显示器仍待补证。当前运行对象来自脏工作树，只用于开发验收，不是正式发布候选。

## 验收对象

- 分支：`main`
- 构建基线：`09f838d05c67efb5219437ec2208920e441f3f52`
- Zip：`releases/v1.0.4/LetsMakeMoney-v1.0.4-windows-x86_64.zip`
- Zip SHA256：`C67E730BF81741D03BFAF6D14F3F16EB74FD8591D8B3AB76D45A980E854C249B`
- EXE SHA256：`B2A1831D0F7832C77033582871C12A2148CC8F3279753A5B812C293869ED1C66`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- Windows：Windows 11 Pro `10.0.26200`
- WebView2：`150.0.4078.105`
- 实际系统缩放：100%

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
| V104-MAN-009 | 125% DPI | 待人工补证 | 当前未切换真实 Windows 缩放 |
| V104-MAN-010 | 150% DPI | 待人工补证 | 当前未切换真实 Windows 缩放 |
| V104-MAN-011 | 深色主题 | 待人工补证 | 自动合同通过，未完成真实桌面观感复核 |
| V104-MAN-012 | 减少动态效果 | 待人工补证 | 自动合同通过，未完成真实桌面观感复核 |
| V104-MAN-013 | 多显示器与负坐标 | 待人工补证 | 纯几何门禁通过，当前没有真实硬件证据 |

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
| `mini.edge_dock.detected` | 12 |
| `mini.edge_dock.retracted` | 7 |
| `mini.edge_dock.revealed` | 5 |
| `mini.edge_dock.canceled` | 2 |
| `settings.saved` | 4 |
| `window.hidden` | 7 |
| `window.shown` | 17 |

日志确认左右边缘均出现 detected/retracted/revealed 序列；关闭设置时出现 `mini.edge_dock.canceled reason=settings_disabled`。未发现工资、精确坐标或用户路径被写入 Mini 贴边语义事件。

## 证据边界

- 机器可读摘要：`evidence/acceptance-summary.json`。
- 人工可读摘要：`evidence/acceptance-summary.md`。
- Computer Use 截图未建立持久外部归档，因此原始证据状态为 `not_collected`；本清单不把它写成已归档。
- 候选哈希发生变化后，本文件中的候选级 GUI 证据必须按发布门禁重新评估。

## 用户环境恢复

- [x] 普通用户数据目录与备份逐文件比较 `7/7` 一致。
- [x] 验收过程中变化的 `config.json.previous` 已恢复。
- [x] 全部 LetsMakeMoney 进程已停止，进程数为 `0`。
- [x] 测试运行使用的 Codex 沙箱化 Roaming 目录与普通用户数据隔离。
- [ ] Computer Use 原始截图外部归档未建立。

## 最小剩余补证

1. 在真实 125% 与 150% Windows 缩放下重复左右贴边、唤回和拖离。
2. 在深色主题与“减少动态效果”下检查隐私标签、过渡和文字对比度。
3. 在真实双显示器、包含负坐标的工作区中验证左右边缘，并验证移除显示器后的安全回落。
4. 从干净提交构建最终候选后，重新锁定哈希并完成通知区、Wizard 和主要窗口冒烟。
