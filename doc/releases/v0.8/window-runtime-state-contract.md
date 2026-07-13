# v0.8 窗口运行时状态合同

**状态**：C4 实施基线
**上游合同**：`doc/releases/v0.7/window-native-state-contract.md`

本合同不改变 v0.7 已验收行为，只收敛状态所有权并把布局计算变成可测试的纯函数。

## 状态快照

`WindowRuntimeState` 只保存 Main 编排需要的业务状态：

| 字段 | 含义 | 写入者 |
|---|---|---|
| `debug_mode` | 是否处于调试窗口模式 | Main / Config 同步 |
| `pure_pet_mode` | 是否请求纯桌宠模式 | Main / Config 同步 |
| `tray_ready` | 托盘是否已成功建立 | Main 的托盘生命周期 |
| `native_capable` | 当前窗口是否具备纯桌宠原生能力 | Main 从 Platform 读取 |
| `window_visible` | 业务窗口是否可见 | DragResizeSystem 同步给 Main |
| `modal_open` | Settings 或 Wizard 是否打开 | OverlayLifecycle |
| `popup_open` | Godot PopupMenu 是否打开 | OverlayLifecycle |
| `passthrough_configured` | 配置是否允许点击穿透 | Main / Config 同步 |

状态快照不直接调用 Godot Window 或 native DLL。`WindowPolicyCoordinator` 读取快照并输出任务栏与点击穿透意图。

## 单一所有者（Single cache owner）

| 状态/能力 | 唯一业务所有者 | 执行与缓存所有者 |
|---|---|---|
| 窗口显示/隐藏 | DragResizeSystem | Platform / Godot Window fallback |
| Modal/Popup 生命周期 | OverlayLifecycle | DragResizeSystem 只负责创建和布局 |
| 右键菜单结构与主题 | ContextMenuBuilder | DragResizeSystem 只负责定位和命令分发 |
| 任务栏是否可见 | Main + WindowPolicyCoordinator | WindowsPlatform 是唯一缓存所有者 |
| 点击穿透意图与矩形 | Main | WindowsPlatform / native 执行 |
| Panel/Pet 窗口几何 | PetWindowGeometry 纯函数 | Main 应用结果 |
| native 能力健康 | WindowsPlatform | native bridge 提供执行结果 |

Main 不再保存第二份任务栏可见性缓存。托盘恢复需要重放原生策略时，Main 通过 Platform 显式使 WindowsPlatform 的缓存失效。该边界称为 `Platform cache invalidation`。

## 行为矩阵（Behavior matrix）

| 窗口 | 模式 | 托盘/native | Overlay | 任务栏意图 | 穿透意图 |
|---|---|---|---|---|---|
| 显示 | 普通 | 任意 | 无 | 显示 | 按配置启用 |
| 隐藏 | 普通 | 任意 | 无 | 不参与窗口恢复判断 | 关闭 |
| 显示 | 纯桌宠 | 托盘与 native 可用 | 无 | 隐藏 | 按配置启用 |
| 显示 | 纯桌宠 | 托盘或 native 不可用 | 无 | 显示并回退普通模式 | 关闭原生能力 |
| 显示 | 任意 | 任意 | Modal | 保持当前模式策略 | 强制关闭 |
| 显示 | 任意 | 任意 | Popup | 保持当前模式策略 | 强制关闭 |
| 恢复后首帧 | 纯桌宠 | 可用 | 无 | 强制重放隐藏 | 重新计算矩形 |

## 几何合同（Geometry contract）

- 缩放输入限制在 `0.5..2.0`。
- Pet 窗口大小必须同时容纳 Pet sprite bounds、Panel target size 和内容边距。
- Pet 命中矩形以 Pet 提供的 local interaction rect 为优先，缺失时回退 sprite bounds。
- Panel 命中矩形至少覆盖最小命中尺寸，并添加 hover padding。
- 纯函数不得读取 Config、场景树、DisplayServer 或 native 状态。

## 回退门禁

任一切面导致普通模式、纯桌宠托盘恢复、Modal/Popup 穿透保护、Panel/Pet 命中矩形、DPI/缩放或 native 降级回退时，只回退该切面，不继续后续 C4 工作。
