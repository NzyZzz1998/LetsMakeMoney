# LMM Windows v0.9 Figma Development Plugin

这是 LetsMakeMoney 项目内的本地 Figma Development Plugin，用于在 Figma Desktop 中生成可编辑的 LMM 产品设计。它不调用 Figma MCP，也不消耗 Starter MCP 配额。

## 页面范围

插件只维护一个页面：

1. `LMM 01 Full Product Flow`

插件会清空并重建名称完全匹配、且通过 `lmm` Shared Plugin Data 所有权检查的目标页。旧的 `00 Foundations & Components`、`01 Windows v0.9 Product UI` 和 `02 Animation Contract` 只有在确认由旧版 LMM 插件生成时才会删除；其有效内容已经合并进 LMM 01。其他页面不会被删除或修改。

## 生成内容

- LMM 暖色产品变量与中性文档变量；
- 中文桌面端文字样式和窗口阴影样式；
- Button、Input、Select、Toggle、Slider、Status Chip 核心组件；
- 启动、首次配置、桌宠、Panel、今日详情、Settings、托盘与退出产品链路；
- 关于、诊断、更新、配置恢复、原生能力降级和宠物包回退状态；
- Classic 与多多的 6 张确定性 PNG 产品关键帧，写入 Figma 后逐字节校验；
- 按当前 Godot 运行界面尺寸重建的全可编辑原型；Figma 画布不嵌入运行截图。

其中 `LMM 01 Full Product Flow` 是完整 UI Atlas 大画布，集中包含：

- working、awake_rest、sleeping 三种桌宠基础状态；
- Panel 折叠、展开和屏幕边缘状态；
- 今日详情窗口及调整今天入口；
- Wizard 收入与休息、上班时间、午休时长和确认配置四步；
- Settings 工资、作息、桌宠、显示和通用五个页签；
- 保存成功、无变化、保存失败和恢复默认确认状态；
- 桌宠右键菜单、窗口模式二级菜单和 Windows 原生托盘菜单；
- 纯桌宠任务栏策略及窗口找回路径；
- 关于、诊断、更新下载、取消、安装确认及失败回退；
- 产品可见动作、资源回退和 Windows native 边界。

画布顶部提供产品关系总览：主链覆盖“启动 → 首次配置 → 桌面伴件 → 今日详情 → 偏好设置 → 托盘 → 退出”；点击穿透保护、纯桌宠任务栏策略、配置恢复、更新和诊断作为支线与主链关联。各界面分区统一使用 5120px 内容栅格、24px 区域内边距、18px 组内间距和顶部对齐。

控件契约不集中堆在画布开头。每个产品分区与 QuickRec 保持同构：先展示无额外标题的流程节点，再排列“A · 可编辑原型”和“B · 本区控件契约”，使说明与对应窗口保持在同一视觉上下文。当前共覆盖 77 个按钮、菜单项、页签、开关、输入框、选择器和可点击入口，每项均注明所在界面、出现条件、用户操作、Godot 信号、调用对象与方法、配置或持久化位置、状态变化、成功结果、失败结果、取消语义及跳转目标。

Settings、Wizard、Panel、今日详情和桌宠菜单已经使用当前 Godot 运行界面完成一次校准；对应可编辑稿采用 300×124、344×232、480×620、700×520、720×520、232px 菜单最小宽及 34px 菜单行高。截图只作为校准输入，不写入生成后的 Figma 页面。

每条契约使用稳定的 `LMM-B-xxx` 编号。编号与完整契约同时写入对应 Figma 控件节点的 `lmm/control-contract-ids` 和 `lmm/control-contract` Shared Plugin Data；选中控件即可反查同区契约卡。

Windows 通知区菜单、任务栏策略、Shell 打开、剪贴板和安装确认作为原生系统边界说明。125% 与 150% DPI 当前只记录逻辑缩放矩阵，明确标记为“待真实 Windows 验证”，不使用 100% DPI 位图放大冒充验收。

## 构建与验证

```powershell
powershell -ExecutionPolicy Bypass -File "E:\codex\LetsMakeMoney\doc\prototypes\v0.9-polished\figma-plugin\build.ps1"
powershell -ExecutionPolicy Bypass -File "E:\codex\LetsMakeMoney\doc\prototypes\v0.9-polished\figma-plugin\test-plugin.ps1"
```

构建会生成确定性的 6 张宠物 PNG，并以 Base64 嵌入 `ui.html`。验证覆盖页面数量、旧页面所有权、非 LMM 页面保护、重复运行幂等性、JavaScript 语法、77 项契约、PNG 格式与哈希、截图零嵌入、关键窗口尺寸、三段式文档结构、UTF-8/乱码和 `git diff --check`。

## Figma Desktop 导入

1. 运行上面的构建和验证命令。
2. 使用 Figma Desktop 打开目标 Design 文件。
3. 选择 `Plugins > Development > Import plugin from manifest...`。
4. 选择 `E:\codex\LetsMakeMoney\doc\prototypes\v0.9-polished\figma-plugin\manifest.json`。
5. 运行 `Plugins > Development > LetsMakeMoney Full Product Flow Builder`。
6. 点击“生成 / 更新 LMM 设计”。

插件可重复运行；再次运行只更新一个 LMM 页面、`LMM Semantic` 变量集合和 `LMM/` 前缀样式，不产生重复内容。无法确认所有权的旧页会保留并显示告警。

## Starter 边界

- 插件只生成一个 LMM 页面，低于 Starter 的三页限制。
- 本地变量、样式和组件可在当前文件内编辑和复用。
- Starter 不能将这些内容发布为跨文件团队 Library。
