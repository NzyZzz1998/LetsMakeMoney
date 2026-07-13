# LetsMakeMoney Apple 产品线

## 当前状态

- 目标版本：`ios-v0.1-beta`
- 开发分支：`ios-main`
- 当前阶段：M0 基线与环境门禁
- 当前可执行范围：文档、schema 契约、测试向量准备与纯 Swift 模块设计
- 当前环境限制：没有 macOS/Xcode；Widget、Live Activity、Watch、多 Target、签名和 TestFlight 尚不可验证

## 产品边界

Apple 产品线不是 Windows 桌宠的移植：

- Windows 继续使用 Godot、GDScript 和 Windows native integration。
- Apple 使用 Swift、SwiftUI、WidgetKit、ActivityKit、App Intents、UserNotifications 和 WatchConnectivity。
- 两条产品线仅共享 `salary-schema v1`、JSON 测试向量、算法口径和节假日数据契约。
- Apple 实现不得依赖 Windows `config.json`、Godot scene、native DLL 或 `%APPDATA%`。

## 目录入口

| 路径 | 职责 | 当前状态 |
| --- | --- | --- |
| `Packages/SalaryCore/` | 纯 Swift 工资、工作日、午休与状态计算 | M1 建立 |
| `Shared/Models/` | App、Widget、Activity、Watch 共享 Codable 模型 | M2 建立 |
| `Shared/Resources/` | 节假日数据、本地化与共享设计资源 | M1-M3 建立 |
| `App/` | iPhone/iPad SwiftUI 主 App | M2-M3 建立 |
| `WidgetExtension/` | Widget 与 Live Activity UI | M4 建立 |
| `WatchApp/` | Apple Watch App 与通信协调 | M5 建立 |
| `WatchWidgetExtension/` | Watch 复杂功能与 Smart Stack | M5 建立 |
| `Tests/` | 集成、UI、快照和跨 Target 一致性测试 | 随模块建立 |
| `Playgrounds/` | iPad Swift Playgrounds 能力验证与迁移说明 | M0 验证 |
| `Config/` | 无秘密的标识符示例；真实 Team ID 只保留本地 | M0 建立 |

详细目录契约见 `PROJECT_LAYOUT.md`。

## 开发环境门禁

1. Windows 可以运行文档、UTF-8、schema 和 JSON 测试向量检查，但不能证明 Apple Target 可构建。
2. Swift Playgrounds 可用于 iPad 上的 SwiftUI App 和 Swift Package 能力验证；实际结果记录在 `doc/releases/ios-v0.1/playgrounds-verification.md`。
3. Xcode workspace、多 Target、entitlements、签名和真实设备调试必须在 macOS/Xcode 环境完成。
4. 未拥有的工具、权限或设备证据必须写“待补证”，不得用静态代码检查替代。

Apple 官方资料：

- [Swift Playgrounds](https://developer.apple.com/documentation/swift-playgrounds)
- [在 App Playground 中添加 Swift Package](https://developer.apple.com/documentation/swift-playgrounds/add-a-swift-package)
- [创建 Xcode App 工程](https://developer.apple.com/documentation/xcode/creating-an-xcode-project-for-an-app/)

## 当前验证

在仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\apple\check_ios_m0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\apple\test_check_ios_m0.ps1
```

这些命令只验证 M0 当前树契约，不编译 Swift，也不代表 App 已可运行。
