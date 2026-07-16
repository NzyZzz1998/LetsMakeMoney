# LetsMakeMoney Apple 产品线

## 当前状态

- 目标版本：`ios-v0.1-beta`
- 开发分支：`ios-main`
- 当前阶段：M3/M3R 已完成；M4 为 16/17，M5 为 13/14，M6 为 9/13；自动化与无签名编译范围已收口，现暂停于 Mac、签名和真机门禁
- 产品边界：iPhone、iPad、Widget、Live Activity、Apple Watch 与复杂功能
- 环境边界：Windows 负责纯 Swift、静态合同和文档门禁；Apple SDK 编译由 GitHub macOS 执行；签名与真实系统行为必须由 Xcode/TestFlight 和真机证明

未拥有的工具、签名或设备证据一律写“待补证”，不得用源码检查或 Preview 冒充真机通过。

当前检查点、阻塞原因、Mac 到位后的准备清单与恢复顺序见 [`../doc/releases/ios-v0.1/status.md`](../doc/releases/ios-v0.1/status.md)。

## 与 Windows 产品线的关系

Apple 产品线不是 Godot 桌宠的移植：

- Windows 继续使用 Godot、GDScript 和 Windows native integration。
- Apple 使用 Swift、SwiftUI、WidgetKit、ActivityKit、App Intents、UserNotifications 和 WatchConnectivity。
- 两条产品线只共享 `salary-schema v1`、工资算法口径、测试向量和节假日数据契约。
- Apple 实现不读取 Windows `config.json`、Godot scene、native DLL 或 `%APPDATA%`。
- ios-v0.1 不包含桌宠、云同步、口令同步、加班、主题系统或更多宠物。

## 目录入口

| 路径 | 职责 |
| --- | --- |
| `Packages/SalaryCore/` | 工资计算、配置持久化、共享快照、结构化日志与跨 Target 一致性 |
| `Packages/ApplePlatformGate/` | iOS/watchOS SDK 编译探针，不是正式产品 Target |
| `Shared/` | App、Widget、Activity 与 Watch 共用模型、资源和协调器 |
| `App/` | iPhone/iPad SwiftUI App |
| `WidgetExtension/` | 桌面/锁屏 Widget 与 Live Activity |
| `WatchApp/` | Apple Watch App 与连接协调 |
| `WatchWidgetExtension/` | 表盘复杂功能与 Smart Stack |
| `Playgrounds/` | iPad Swift Playgrounds 能力验证与迁移探针 |
| `Config/` | 无秘密的标识符示例；真实 Team ID 不提交 |

完整目录契约见 [`PROJECT_LAYOUT.md`](PROJECT_LAYOUT.md)。

## 开发环境

### Windows

Windows 可运行：

- SalaryCore 的 Windows Swift 单元测试；
- schema、JSON、文档、本地化、隐私和源码合同检查；
- Playgrounds 导出；
- 原型与正式中文文案一致性检查。

Windows 不能证明：

- 正式 iOS/watchOS Target 可签名安装；
- App Group、Widget、Activity、通知和 WatchConnectivity 的真实系统行为；
- 真机外观、常亮显示、锁屏、低电量和系统限流行为。

### iPad Swift Playgrounds

Playgrounds 用于验证 Swift Package、主 App 代码和有限 SwiftUI 页面。它不能替代正式 Extension、entitlement、签名、TestFlight 或 Watch App 验收。操作与已知限制见 [`../doc/releases/ios-v0.1/playgrounds-verification.md`](../doc/releases/ios-v0.1/playgrounds-verification.md)。

### macOS / GitHub Actions

GitHub macOS 工作流会运行 SalaryCore 测试、源码合同、Playgrounds 导出和 Apple SDK 编译探针。正式 archive、签名、App Group entitlement、TestFlight 和真机验收仍需可用的 Apple Developer 环境。

## 验证命令

在仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\apple\check_ios_m5.ps1 -RequireSwift
python .\scripts\apple\validate_apple_localization.py
python .\scripts\apple\validate_apple_product_quality.py
python .\scripts\apple\validate_ios_prototype_contract.py
swift test --package-path .\apple\Packages\SalaryCore
```

M6 全量入口建立后以 `scripts/apple/check_ios_m6.ps1` 为当前自动门禁。自动门禁通过仍不代表 M4、M5 或 M6 真机矩阵通过。

## 人工验证入口

- M3 iPhone/iPad App：[`../doc/releases/ios-v0.1/m3-device-verification.md`](../doc/releases/ios-v0.1/m3-device-verification.md)
- M4 Widget/Activity：[`../doc/releases/ios-v0.1/m4-device-verification.md`](../doc/releases/ios-v0.1/m4-device-verification.md)
- M5 Apple Watch：[`../doc/releases/ios-v0.1/m5-device-verification.md`](../doc/releases/ios-v0.1/m5-device-verification.md)
- M6 跨 Target 与体验矩阵：[`../doc/releases/ios-v0.1/m6-device-verification.md`](../doc/releases/ios-v0.1/m6-device-verification.md)

## 隐私与限制

- 隐私说明：[`../doc/releases/ios-v0.1/privacy.md`](../doc/releases/ios-v0.1/privacy.md)
- 已知限制：[`../doc/releases/ios-v0.1/known-limitations.md`](../doc/releases/ios-v0.1/known-limitations.md)

Apple 官方资料：

- [Swift Playgrounds](https://developer.apple.com/documentation/swift-playgrounds)
- [Adding a Swift package to an app playground](https://developer.apple.com/documentation/swift-playgrounds/adding-a-swift-package-to-an-app-playground)
- [Creating an Xcode project for an app](https://developer.apple.com/documentation/xcode/creating-an-xcode-project-for-an-app)
