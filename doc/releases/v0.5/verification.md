# LetsMakeMoney v0.5 Beta 验证文档

**最后更新**: 2026-07-09
**适用版本**: v0.5 Beta
**当前结论**: 未通过 / 发布阻塞

## 1. 验证范围

本文件用于 v0.5 Beta 的实际验收。v0.5 验收重点是 Settings / Wizard 共享控件系统、托盘恢复、纯桌宠、点击穿透保护、debug.log 关键事件、发布包可用性和文档事实源一致性。

结果只能使用：`通过` / `部分通过` / `未通过` / `待验证`。

## 2. 验证环境

| 项目 | 结果 |
|---|---|
| Godot 版本 | 4.7 stable |
| 运行方式 | 导出 exe / Godot 编辑器 |
| 包路径 | `releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip` |
| 配置路径 | `%APPDATA%\LetsMakeMoney\config.json` |
| 日志路径 | `%APPDATA%\LetsMakeMoney\debug.log` |
| 验证结论 | 未通过 / 发布阻塞 |

## 3. 自动验证

已记录通过：

```powershell
.\scripts\verify_v05.ps1
.\scripts\verify_v04.ps1
.\scripts\verify_m4.ps1
.\scripts\verify_m5.ps1
.\scripts\check_docs_status.ps1
.\scripts\package_v05.ps1
.\scripts\verify_v05_package.ps1
```

## 4. Settings 验证

| 编号 | 操作 | 预期 | 结果 | 备注 |
|---|---|---|---|---|
| V05-MAN-001 | 右键小猫，点击“设置” | 设置窗口打开，整体为紧凑暖色偏好面板 | 通过 | Computer Use 已截图。 |
| V05-MAN-002 | 切换“工资”页 | 月薪、休息模式、时间输入和只读小时数布局稳定 | 通过 | 共享控件已接入。 |
| V05-MAN-003 | 展开“休息模式”下拉框 | popup 为暖色纸面风格，不出现深灰系统菜单 | 通过 | 已复测通过。 |
| V05-MAN-004 | 切换“桌宠”页 | 宠物选择列表可用，当前宠物可识别 | 通过 |  |
| V05-MAN-005 | 切换“显示”页 | 透明度、缩放、窗口模式、纯桌宠模式控件统一 | 通过 | slider 轨道不可见问题已修复。 |
| V05-MAN-006 | 展开“窗口模式”下拉框 | 下拉样式与 Settings 一致，选中态清楚 | 通过 |  |
| V05-MAN-007 | 切换“面板”页 | 面板项目开关紧凑、可读、可点击 | 通过 |  |
| V05-MAN-008 | 切换“通用”页 | 开机自启、隐藏到托盘和维护按钮布局稳定 | 通过 |  |
| V05-MAN-009 | 修改一个设置并保存 | 出现“已保存”反馈，配置写入 | 通过 | debug.log 有 `settings_save_success`。 |
| V05-MAN-010 | 不修改设置直接保存 | 出现“无变化”反馈，不误报失败 | 通过 | debug.log 有 `settings_save_no_change`。 |
| V05-MAN-011 | 模拟配置保存失败后保存 | 显示保存失败，可读错误，用户输入保留 | 通过 | debug.log 有 `settings_save_failed` / `config_save_failed`。 |
| V05-MAN-012 | 点击取消或关闭 | 未确认修改不保存，桌宠恢复交互策略 | 通过 |  |

## 5. Wizard 验证

| 编号 | 操作 | 预期 | 结果 | 备注 |
|---|---|---|---|---|
| V05-MAN-020 | 从设置中点击“重新运行向导” | Wizard 打开，风格与 Settings 同源 | 通过 |  |
| V05-MAN-021 | 查看欢迎页 | 页面紧凑，不像默认弹窗或旧向导 | 通过 |  |
| V05-MAN-022 | 进入薪资 / 时间页 | SpinBox、OptionButton、时间输入与 Settings 一致 | 通过 |  |
| V05-MAN-023 | 展开休息模式下拉框 | popup 为暖色纸面风格 | 通过 |  |
| V05-MAN-024 | 进入宠物页 | 至少有当前宠物可选，不出现“无动物可选” | 通过 |  |
| V05-MAN-025 | 进入确认页 | 配置摘要可读，完成按钮清楚 | 通过 |  |
| V05-MAN-026 | 测试上一步 / 下一步 | 步骤切换正常，表单值不丢失 | 通过 | debug.log 有 `wizard_step_changed`。 |
| V05-MAN-027 | 点击取消或关闭 | Wizard 关闭，桌宠恢复原交互策略 | 通过 | debug.log 有 `wizard_cancelled` / `wizard_closed`。 |
| V05-MAN-028 | 点击完成 | 配置保存，向导关闭，桌宠可继续使用 | 通过 | debug.log 有 `wizard_finished`。 |

## 6. 托盘 / 点击穿透 / 纯桌宠恢复

| 编号 | 操作 | 预期 | 结果 | 备注 |
|---|---|---|---|---|
| V05-MAN-040 | 开启纯桌宠模式 | 任务栏策略按配置应用，窗口仍可找回 | 部分通过 | 仍需最终托盘复测。 |
| V05-MAN-041 | 托盘左键隐藏窗口 | 桌宠隐藏，托盘图标保留 | 部分通过 | 非纯桌宠通过。 |
| V05-MAN-042 | 再次托盘左键显示窗口 | 桌宠恢复，重新应用纯桌宠和点击穿透策略 | 未通过 | 用户最新证据显示纯桌宠恢复后任务栏入口依旧存在。 |
| V05-MAN-043 | 托盘右键打开菜单 | 菜单可用，样式不破坏 | 通过 |  |
| V05-MAN-044 | 从托盘菜单打开设置 | 设置窗口可点击，不被透明穿透破坏 | 通过 |  |
| V05-MAN-045 | 关闭 Settings / Wizard 后检查空白区域 | 点击穿透恢复，小猫和 Panel 仍可交互 | 通过 | debug.log 有 passthrough resume。 |
| V05-MAN-046 | native 不可用时启动 | 降级到可找回普通窗口，不进入不可恢复状态 | 待验证 |  |

## 7. debug.log 验证

| 编号 | 操作 | 预期日志 | 结果 | 备注 |
|---|---|---|---|---|
| V05-MAN-060 | 打开并关闭 Settings | `settings_opened` / `settings_closed` 或等价稳定事件 | 通过 |  |
| V05-MAN-061 | 保存 Settings | `settings_save_success` / `settings_save_no_change` / `settings_save_failed` | 通过 |  |
| V05-MAN-062 | 打开并完成 Wizard | `wizard_opened` / `wizard_step_changed` / `wizard_finished` | 通过 |  |
| V05-MAN-063 | 托盘左键隐藏 / 显示 | `tray_toggle_requested` / `window_policy_reapplied` | 部分通过 | 日志可见，但纯桌宠任务栏策略仍需通过证据。 |
| V05-MAN-064 | 打开 Settings 或 Wizard | `passthrough_suspended` / `passthrough_resumed` | 通过 |  |
| V05-MAN-065 | 开启纯桌宠后恢复窗口 | `pure_pet_mode_apply` 或 fallback 事件 | 未通过 | 当前证据显示任务栏入口仍存在。 |

## 8. 回归验证

| 编号 | 操作 | 预期 | 结果 | 备注 |
|---|---|---|---|---|
| V05-REG-001 | Panel 折叠 / 展开 | 暖色 Panel 正常显示，不错位 | 通过 |  |
| V05-REG-002 | 小猫单击 / 双击 / 长按 / 拖拽 / 右键 | 交互仍可用，日志无异常 | 通过 |  |
| V05-REG-003 | 右键菜单二级项 | 菜单功能不变 | 通过 |  |
| V05-REG-004 | M4 自动验证 | `verify_m4.ps1` 通过 | 通过 |  |
| V05-REG-005 | M5 自动验证 | `verify_m5.ps1` 通过 | 通过 |  |

## 9. 最终结论

| 项目 | 结论 | 说明 |
|---|---|---|
| Settings 共享控件 | 通过 |  |
| Wizard 共享控件 | 通过 |  |
| 设置保存反馈 | 通过 | 成功、无变化、失败均可区分。 |
| 点击穿透保护 | 通过 | Settings/Wizard 打开关闭路径有日志。 |
| 日志完整性 | 通过 | 关键语义日志已补齐。 |
| 发布包可用性 | 通过 | zip 可生成并冒烟。 |
| 托盘 / 纯桌宠恢复 | 未通过 | 纯桌宠恢复后任务栏入口依旧存在。 |
| 是否可发布 | 未通过 | 发布阻塞。 |

## 10. 必须补测的最终路径

使用 `releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip`：

1. 开启纯桌宠模式。
2. 左键托盘图标隐藏桌宠。
3. 再次左键托盘图标恢复桌宠。
4. 预期：桌宠恢复，任务栏入口保持隐藏。
5. 检查 `%APPDATA%\LetsMakeMoney\debug.log`，应包含托盘切换、窗口策略重应用、纯桌宠策略重应用相关事件。

当前发布决策：**不发布、不打 tag、不扩新功能，只修复或复测该阻塞项。**
