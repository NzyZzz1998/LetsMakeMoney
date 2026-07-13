# LetsMakeMoney v0.8 C4 验证记录

**验证日期**：2026-07-13
**范围**：Main/native 状态治理、菜单与模态职责分离、窗口几何纯函数
**结论**：通过，可以进入 C5 决策；C4 未发现发布阻塞回归

## 1. 实现边界

- `WindowRuntimeState` 只保存编排快照，不直接操作窗口或 native DLL。
- `WindowPolicyCoordinator` 根据快照计算任务栏和点击穿透意图。
- `WindowsPlatform` 是任务栏可见性缓存的唯一所有者。
- `PetWindowGeometry` 只做纯几何计算。
- `OverlayLifecycle` 管理 Modal/Popup 生命周期；`ContextMenuBuilder` 管理菜单结构与主题。
- `DragResizeSystem` 继续负责窗口移动、菜单定位、命令分发与模态创建，不改变外部信号合同。

## 2. 自动验证

| 验证 | 结果 | 说明 |
|---|---|---|
| `scripts/test_window_state_contract.ps1` | 通过 | 状态所有权、缓存唯一性、源码边界合同 |
| `scripts/verify_v07.ps1` | 通过 | v0.6 兼容、安装/签名/更新/公开治理及 C4 Godot 合同 |
| `scripts/verify_m4.ps1` | 通过 | Settings 与配置回归 |
| `scripts/verify_m5.ps1` | 通过 | 临时导出 EXE，首次启动窗口可响应 |
| `scripts/verify_v04.gd` | 通过 | v0.4 UI 与窗口回归 |
| `scripts/verify_v05.gd` | 通过 | v0.5 共享控件与行为回归 |
| `scripts/verify_v06.gd` | 通过 | v0.6 配置、诊断与策略回归 |

`verify_v06.gd` 会主动写入损坏 JSON 来验证恢复逻辑，因此控制台出现一次预期的 JSON 解析错误；脚本最终成功标记和退出码均为通过。

## 3. 真实 Windows 原生验证

使用 C4 源码临时导出的 `.tmp_c4/LetsMakeMoney.exe` 和真实 native DLL 执行 `scripts/verify_v06_tray.ps1 -Rounds 10`：

- 普通模式：10/10 通过。
- 纯桌宠模式：10/10 通过。
- 验证覆盖：原生托盘命令、窗口隐藏/恢复、窗口样式、任务栏策略重放。

本次会话没有可调用的 Computer Use 能力，因此没有重复执行真实鼠标通知区点击和 125%/150% DPI 截图。C4 未改变视觉样式与 DPI 参数，相关人工证据沿用 v0.7 发布验收；后续若 C5 改动窗口或 Settings 视觉，必须重新人工复核。

## 4. 非阻塞发现

- 当前 Godot export preset 会把仓库中的 `deliverables/` 带入导出 PCK，临时 M5 导出体积因此高于预期。
- 该问题不影响 C4 状态治理结论，但必须在 C5 调整发布目录或导出排除规则，并重新验证便携 Zip 内容。

## 5. 回退边界

C4 可以按以下独立切片回退：状态快照、窗口几何、Overlay 生命周期、菜单 builder、任务栏缓存所有权。若后续真实桌面验收发现回归，应只回退对应切片，不撤销 C0-C3 的文档和仓库治理。
