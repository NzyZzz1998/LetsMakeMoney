# LetsMakeMoney iOS v0.1 Beta 当前状态

## 状态摘要

- 版本：`ios-v0.1-beta`
- 分支：`ios-main`
- 检查点 HEAD：`d1d2182dc173fcac179d74036989432ad5c04851`
- 当前阶段：自动化与无签名编译范围已完成，暂停于 Mac、签名与 Apple 真机系统行为门禁
- 当前结论：实现尚未完成，不具备生成正式 Beta 候选包的条件
- 最后更新：2026-07-16

## 里程碑进度

| 里程碑 | 状态 | 完成度 | 剩余内容 |
| --- | --- | --- | --- |
| M0 基线与可行性 | 已完成 | 10/10 | 无 |
| M1 SalaryCore | 已完成 | 16/16 | 无 |
| M2 配置与共享快照 | 已完成 | 14/14 | 无 |
| M3 App 与日历 | 已完成 | 17/17 | 无 |
| M3R 首次引导返工 | 已完成 | 14/14 | 无 |
| M4 Widget/Activity | 待真机验收 | 16/17 | iPhone 系统行为验收 |
| M5 Watch | 待真机验收 | 13/14 | Series 10 真机验收 |
| M6 一致性与质量 | 暂停于真机门禁 | 9/13 | 外观、辅助功能、系统状态四组矩阵 |
| M7 候选构建与 Beta | 未开始 | 0/15 | 签名、归档、真机 Acceptance 与发布 |

## 已完成能力

- iPhone/iPad 今日、日历、设置、首次引导与横竖屏适配。
- 真实工作日、午休、工资金额、状态和进度的统一 SalaryCore 计算。
- 安全配置写入、损坏恢复、共享快照和结构化日志。
- Widget、Live Activity、通知、控制中心入口与 App Intent 源码实现。
- Watch App、WatchConnectivity、复杂功能、Smart Stack 和三指标切换源码实现。
- App、Widget、Activity、Watch 跨 Target 事实一致性比较器。
- 简体中文、本地化、隐私、日志脱敏、产品质量和原型合同门禁。
- Windows SalaryCore 86/86 测试通过；GitHub macOS 已完成四类正式 Target 的无签名 Simulator SDK 编译。

## 阻塞项与原因

| 阻塞项 | 原因 | 直接影响 | 关闭方式 |
| --- | --- | --- | --- |
| 本地没有 Mac/Xcode | Windows 和 Swift Playgrounds 不能生成正式 Xcode archive，也不能管理完整签名能力 | G4、M4-M7 | 在 Mac 安装兼容 Xcode，克隆 `ios-main` 并运行本地门禁 |
| Apple Developer Program/Team ID 未确认 | 完整 App Group、扩展签名、TestFlight 与分发需要有效开发者团队 | G4、App Group、Beta | 确认 Apple Developer Program、Team ID 和 App Store Connect 权限 |
| 正式 Bundle ID/App Group 未配置 | 仓库只保留无秘密占位配置，不能替代开发者账号中的正式标识符 | App/Widget/Watch 联调 | 在安全的本地配置或 CI Secret 中设置正式值，不提交仓库 |
| 无签名安装包 | CI 当前只证明 Simulator SDK 编译 | 真机安装与 M7 | 使用 Xcode 自动签名或受控证书生成候选 archive |
| Apple 系统行为无真实证据 | Preview、Playgrounds 和 CI 不能证明锁屏、灵动岛、常亮、低电量和系统限流 | M4-017、M5-014、M6-007～010 | 在指定 iPhone、iPad、Watch 上按验证文档补证 |
| 2027 官方节假日数据尚不可用 | 不能猜测未来官方调休 | 离线数据覆盖范围 | 官方数据发布后更新数据集和版本，未发布前明确标记未覆盖 |

## 恢复开发所需条件

### 必需环境

- 一台可运行项目所需 Xcode 的 Mac。
- Xcode；当前 CI 基线为 Xcode 16.4，升级工具链前应先运行全量门禁。
- Git、Python 3 和项目脚本要求的基础命令行工具。
- 可登录的 Apple Account。

### 完整首版需要的开发者能力

- 有效的 Apple Developer Program 会员资格与 Team ID。
- App、Widget/Activity、Watch App、Watch Widget 的正式 Bundle ID。
- 一个正式 App Group 标识符，并为相关 Target 开启相同 capability。
- 自动签名权限，或受控的证书与 provisioning profile。
- App Store Connect/TestFlight 访问权限。

### 建议真机

- iPhone 16 Pro Max。
- iPad Pro M4。
- Apple Watch Series 10。

## Mac 到位后的执行顺序

1. 在 Mac 克隆仓库并切换 `ios-main`，核对本状态文档记录的检查点及其后续提交。
2. 安装 Xcode，运行 SalaryCore 测试、项目生成和所有无签名编译门禁。
3. 通过本地未跟踪配置或 CI Secret 填入 Team ID、Bundle ID 和 App Group；禁止写入提交。
4. 在 Xcode 中确认各 Target capability 和自动签名，关闭 G4。
5. 分别安装到 iPhone、iPad 和 Watch，完成 M4、M5 与 M6 验证文档。
6. 仅在所有发布阻塞项关闭后进入 M7，生成 archive、导出包、manifest 和 SHA256。
7. 执行 Acceptance；未执行或失败项不得写成通过。

## 安全边界

以下内容不得提交：Apple Account 密码、证书私钥、`.p12`、provisioning profile、App Store Connect API 私钥、CI token、真实用户日志或包含隐私的诊断文件。Team ID、Bundle ID 和 App Group 虽非密码，也应通过明确的环境配置流程管理，避免把个人开发身份固化到公共代码。

## 下一步

在 Mac 到位前，iOS 主线保持此检查点，只接受不依赖 Apple SDK 真机行为的明确缺陷修复。当前可将开发重心切回 Windows；iOS 恢复时从本文件、`progress_ios-v0.1.md` 和三份真机验证文档开始。

