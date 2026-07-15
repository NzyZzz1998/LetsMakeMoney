# LetsMakeMoney Apple 产品线

## 当前状态

- 目标版本：`ios-v0.1-beta`
- 开发分支：`ios-main`
- 当前阶段：M0-M3 与 M3R 已完成，M4 已进入 Widget/Activity 实施
- 当前可执行范围：文档、schema、SalaryCore、iPhone/iPad SwiftUI App、iPad Playgrounds 包，以及 GitHub macOS Apple SDK 编译门禁
- 当前环境限制：本地没有 macOS/Xcode；GitHub 已通过 App、Widget/Activity 与 Watch SDK probe 编译，但正式 Extension、entitlement、签名、XCTest 和 TestFlight 尚未验证

## 产品边界

Apple 产品线不是 Windows 桌宠的移植：

- Windows 继续使用 Godot、GDScript 和 Windows native integration。
- Apple 使用 Swift、SwiftUI、WidgetKit、ActivityKit、App Intents、UserNotifications 和 WatchConnectivity。
- 两条产品线仅共享 `salary-schema v1`、JSON 测试向量、算法口径和节假日数据契约。
- Apple 实现不得依赖 Windows `config.json`、Godot scene、native DLL 或 `%APPDATA%`。

## 目录入口

| 路径 | 职责 | 当前状态 |
| --- | --- | --- |
| `Packages/SalaryCore/` | 工资计算、配置持久化、共享快照与结构化日志 | M1-M2 已实现并通过 Windows Swift 测试 |
| `Shared/Models/` | Apple Targets 的工程装配与共享模型入口 | M3 接入；当前模型事实源位于 SalaryCore |
| `Shared/Resources/` | 节假日数据、本地化与共享设计资源 | String Catalog 已建立，设计资源随 M3 补齐 |
| `App/` | iPhone/iPad SwiftUI 主 App | M2-M3 建立 |
| `WidgetExtension/` | Widget 与 Live Activity UI | M4 当前实施入口 |
| `WatchApp/` | Apple Watch App 与通信协调 | M5 建立 |
| `WatchWidgetExtension/` | Watch 复杂功能与 Smart Stack | M5 建立 |
| `Tests/` | 集成、UI、快照和跨 Target 一致性测试 | 随模块建立 |
| `Playgrounds/` | iPad Swift Playgrounds 能力验证与迁移说明 | M0 验证 |
| `Config/` | 无秘密的标识符示例；真实 Team ID 只保留本地 | M0 建立 |

详细目录契约见 `PROJECT_LAYOUT.md`。

## 开发环境门禁

1. Windows 可以运行文档、UTF-8、schema 和 JSON 测试向量检查，但不能证明 Apple Target 可构建。
2. Swift Playgrounds 可用于 iPad 上的 SwiftUI App 和 Swift Package 能力验证；实际结果记录在 `doc/releases/ios-v0.1/playgrounds-verification.md`。
3. GitHub macOS 使用 `Packages/ApplePlatformGate/` 验证 iOS/watchOS SDK 与 Framework 编译边界；probe 不是正式产品 Target。
4. Xcode workspace、正式 Extension、多 Target entitlements、签名和真实设备调试仍必须在 macOS/Xcode 或真机环境完成。
5. 未拥有的工具、权限或设备证据必须写“待补证”，不得用静态代码检查替代。

Apple 官方资料：

- [Swift Playgrounds](https://developer.apple.com/documentation/swift-playgrounds)
- [在 App Playground 中添加 Swift Package](https://developer.apple.com/documentation/swift-playgrounds/add-a-swift-package)
- [创建 Xcode App 工程](https://developer.apple.com/documentation/xcode/creating-an-xcode-project-for-an-app/)

## 当前验证

在仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\apple\check_ios_m0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\apple\test_check_ios_m0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\apple\test_check_ios_m2.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\apple\check_ios_m4.ps1 -RequireSwift
```

M4 Windows 门禁会保留 M1-M3 回归并检查 G3 probe 与工作流合同；真正的 Apple SDK 编译由 GitHub macOS 工作流执行。任何本地合同或 probe 结果都不代表 App Group entitlement、签名或真实 Apple 设备行为已通过。
