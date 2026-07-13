# LetsMakeMoney v0.7 Beta 发布说明

**状态**：最终验收通过，可发布便携 Zip

**便携 Zip SHA256**：`16F47A844EFD78D387E9D08FBCD3DE76C8C8BDD518731C1B0BA022E7F598121F`

## 主要变化

- 建立 MIT 代码许可、受限素材许可、第三方声明和公开贡献边界。
- 固定 Godot/godot-cpp/native 工具链，统一 Windows CI、验证和打包入口。
- 分阶段治理 Main/native 窗口、托盘、任务栏和点击穿透状态所有权。
- 新增当前用户 Inno Setup 安装器基线；安装器必须完成 Authenticode 签名后才可公开分发。
- 新增用户控制的稳定/测试更新通道、GitHub Release 查询、SHA256/发布者校验、取消和手动回退。
- 完成中英双语入口、贡献/安全规范、Issue/PR 模板和未来规划。

## 发布边界

- Windows x86_64 Beta。
- 便携 Zip 已通过 Acceptance；未签名测试安装器不得作为 Release 附件。
- v0.7 不实现 iOS/macOS/Android、主题切换或新宠物。iOS 是后续平台研究最高优先级。
- 真实通知区/任务栏、DPI 与安装/卸载链路已取得实机证据；开机自启仍需独立人工证据。多显示器、干净 Windows 用户/VM、Authenticode/SmartScreen 暂不验证，不阻塞便携 Zip；未签名安装器不作为 Release 附件。
