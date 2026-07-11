# v0.7 窗口与原生状态合同

本合同冻结 v0.6 已验收行为，是 B5 分阶段治理的前置门禁。文中的英文锚点用于自动检查：Single owner、normal mode、pure pet mode、multi-display。

## 唯一所有者（Single owner）

| 状态 | 唯一决策者 | 执行者 | 禁止事项 |
|---|---|---|---|
| 窗口是否显示 | `DragResizeSystem` | `Platform.set_window_visible` / Godot Window fallback | Main 与 native 分别保存第二份业务真值 |
| 是否显示任务栏入口 | Main 的窗口策略 | `WindowsPlatform` / native WindowController | native 自行推断 pure pet mode |
| 托盘生命周期和命令 | `Platform` | WindowsPlatform / TrayController | Main 直接解释 Win32 消息 |
| 点击穿透意图和交互矩形 | Main | WindowsPlatform / WindowController | native 自行计算 Panel/Pet 布局 |
| Popup/Modal 暂停穿透 | Main modal coordinator | Platform | Settings/Wizard 直接调用 native bridge |
| native health | WindowsPlatform | LMMNativeBridge 各控制器 | 失败后只缓存 false、没有 last_error |

## 状态矩阵

| 模式/事件 | 窗口 | 任务栏 | 托盘 | 穿透 |
|---|---|---|---|---|
| normal mode 显示 | 可见 | 可见 | 配置启用时可用 | 透明区穿透 |
| normal mode 隐藏 | 隐藏 | 不可见 | 保持可找回 | 关闭 |
| pure pet mode 显示 | 可见 | 不可见 | 必须可用 | 透明区穿透 |
| pure pet mode 隐藏 | 隐藏 | 不可见 | 保持可找回 | 关闭 |
| Settings/Wizard Modal | 主内容隐藏、模态可见 | 保持当前策略 | 保持 | 强制暂停 |
| Popup 菜单 | 主窗口保持 | 保持当前策略 | 保持 | 打开时暂停，关闭后重算 |
| native unavailable | Godot 可见窗口降级 | 保持可找回 | 可使用 Godot fallback 时启用 | 关闭原生穿透 |
| native degraded | 仅失败能力降级 | 不得隐藏最后找回入口 | 可用能力继续 | last_error 可诊断 |

## 原生健康合同

- `available`：能力调用可执行且返回值可信。
- `degraded`：DLL 已加载，但一个或多个控制器失败；UI 保持可找回并记录 `last_error`。
- `unavailable`：DLL 或类不可用；不启用纯桌宠，不静默承诺托盘/穿透。

## 托盘与退出时序

托盘命令协议以 `native/windows/native-protocol.json` 为事实源。左键只产生 `left_toggle`；右键菜单产生 toggle/settings/about/exit。正常退出、托盘退出和未来更新退出都必须先关闭 Popup/Modal、关闭托盘、清除窗口 subclass/穿透，再终止进程。

## Popup/Modal 点击穿透边界

- Popup 打开：暂停穿透；关闭：排队重算当前 Pet/Panel 交互矩形。
- Modal 打开：暂停穿透并隐藏主内容；关闭：下一帧重新应用窗口、任务栏和穿透策略。
- 原生托盘菜单不改变窗口交互矩形；命令回到 Godot 后由 Main 执行策略。

## multi-display 与 DPI 人工矩阵

Acceptance 至少覆盖单屏与双屏、主/副屏边缘、100%/125%/150%/200% DPI、任务栏底部与侧边。自动测试只验证计算合同，不冒充真实 Windows 合成器、通知区和任务栏行为。

## 回退规则

任一 B5 切面导致普通模式、纯桌宠、托盘 10 轮、Settings/Wizard Modal、Panel/Pet 输入或 DLL 降级矩阵回退时，只回退该切面提交，不继续后续切面。
