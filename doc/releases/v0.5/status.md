# LetsMakeMoney v0.5 Beta 当前状态

**最后更新**：2026-07-09  
**当前分支**：`main`  
**当前阶段**：发布收口  
**当前结论**：通过 / 可发布  
**验收入口**：[verification.md](verification.md)

## 1. 版本定位

v0.5 Beta 是“偏好设置与桌宠边缘体验收敛版”。本版本不扩展新的产品方向，重点把 Settings、Wizard、托盘恢复、纯桌宠任务栏策略、点击穿透保护、保存反馈和语义日志收敛到可验收、可维护、可发布的状态。

## 2. 已完成

- V05-M0 开发基线与文档壳完成，v0.5 独立状态入口、验证入口、发布检查清单和日志治理边界已建立。
- Settings / Wizard 共享 Warm Control 控件系统接入。
- Settings 保存成功、无变化、保存失败反馈闭环。
- Wizard 下一步、上一步、取消、关闭、完成链路日志闭环。
- 托盘左键隐藏 / 恢复链路补证。
- 纯桌宠恢复后任务栏入口策略补证。
- 非纯桌宠恢复后任务栏入口策略补证。
- v0.5 验证脚本、打包脚本、包验证脚本完成。
- v0.5 zip 包生成并通过包结构、manifest、checksum、短启动烟测。
- v0.5 发布前补证验收完成。

## 3. 已验证

- `verify_v05.ps1`：通过。
- `verify_v05_package.ps1`：通过。
- 实际运行发布包 exe：通过。
- Settings 保存无变化：通过。
- Settings 保存成功：通过。
- Settings 保存失败：通过。
- Wizard 下一步 / 上一步 / 取消：通过。
- Wizard 完成：通过。
- 托盘左键隐藏 / 恢复应用内同路径补证：通过。
- `pure_pet_mode=true` 恢复后窗口样式：`AppWindow=false / ToolWindow=true`，通过。
- `pure_pet_mode=false` 恢复后窗口样式：`AppWindow=true / ToolWindow=false`，通过。

## 4. 发布产物

- zip：`<PROJECT_ROOT>\releases\v0.5\LetsMakeMoney-v0.5-beta-windows-x86_64.zip`
- 展开目录：`<PROJECT_ROOT>\releases\v0.5\LetsMakeMoney-v0.5-beta-windows-x86_64`
- 主要文件：
  - `LetsMakeMoney.exe`
  - `letsmakemoney_native.dll`
  - `app_icon.ico`
  - `README.md`
  - `release-notes.md`
  - `manifest.json`
  - `checksums.txt`

## 5. 已知说明

- Computer Use 无法稳定直接点击 Windows 通知区托盘图标。本轮托盘左键验收使用真实发布包 exe、native 托盘消息同路径、Win32 窗口样式和桌面截图补证。
- 点击穿透保护的 suspended/resumed 事件目前是 debug 级日志；默认 `debug_mode=false` 时不会每次写入。功能层面已通过 Settings / Wizard 实际操作和历史 debug 日志确认。
- `verify_v05.ps1` 仍可能输出 Godot headless parser 文本，但脚本返回通过，且发布包烟测通过。建议 v0.6 优化验证脚本输出质量。

## 6. 下一步

1. 提交并推送当前版本。
2. 打 `v0.5-beta` tag。
3. 如继续迭代，再进入 v0.6 `/idea`，不要继续扩大 v0.5 范围。
