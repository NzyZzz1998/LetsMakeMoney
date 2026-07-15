# Apple 工程目录契约

## 单一事实源

- 纯计算逻辑只存在于 `Packages/SalaryCore/Sources/SalaryCore/`。
- 配置与共享快照模型由 `SalaryCore` 提供，各 Target 不复制字段定义。
- 用户文案进入 String Catalog，SwiftUI View 不散落主要硬编码文案。
- App 是配置事实源；Widget、Live Activity 与 Watch 只读取或接收快照。
- Playgrounds、正式 Xcode 工程和平台探针引用同一份 `SalaryCore`，不维护第二套算法。
- `apple/project.yml` 是正式 App/Extension 工程结构的声明式事实源；生成的 `.xcodeproj` 不手工维护。

## 当前结构

```text
apple/
  Config/
    Identifiers.example.xcconfig
    LetsMakeMoneyApp.entitlements
    LetsMakeMoneyWidget.entitlements
  Packages/
    SalaryCore/
    ApplePlatformGate/
  Shared/
    Resources/
  App/
  WidgetExtension/
  WatchApp/
  WatchWidgetExtension/
  Tests/
  Playgrounds/
  project.yml
```

## Target 与 Scheme

| Target/Scheme | 平台 | 职责 | 允许写主配置 | 当前状态 |
| --- | --- | --- | --- | --- |
| `LetsMakeMoneyApp` | iOS/iPadOS | 今日、日历、设置、引导、配置事务 | 是 | 正式 target 已通过 Simulator 编译 |
| `LetsMakeMoneyWidget` | iOS/iPadOS | Widget，后续承载 Live Activity UI | 否 | 正式 extension 已内嵌并通过编译验证 |
| `LetsMakeMoneyWatch` | watchOS | Watch App 与快照展示 | 否 | 仅 G3 probe，正式 target 待 M5 |
| `LetsMakeMoneyWatchWidget` | watchOS | 复杂功能与 Smart Stack | 否 | 待 M5 |
| `SalaryCoreTests` | Swift Package | 规则、金额、配置和快照测试 | 不适用 | Windows/macOS 均有门禁 |
| `LetsMakeMoneyUITests` | iOS/iPadOS | App 主路径 UI 自动化 | 不适用 | 源码已建立，正式执行待后续 target |

Live Activity UI 与桌面 Widget 归入同一 Widget Extension，避免重复 Activity 模型。Watch 操作必须通过 WatchConnectivity 等待 iPhone 结果，不得直接写配置或乐观显示成功。

## Playgrounds 到正式工程

1. iPad App Playground 保留为 M0-M3 真机验证与历史 Spike 入口。
2. `SalaryCore` 继续以独立 Swift Package 被 Playgrounds 和正式工程复用。
3. 正式工程由固定版本 XcodeGen 根据 `apple/project.yml` 生成。
4. Playgrounds 特有清单、探针和预览代码不进入核心模块。
5. M4 起新增平台能力优先进入正式 target，Playgrounds 不再承担 Extension、签名或系统集成验证。

## 禁止项

- 不提交真实 Team ID、证书、描述文件、私钥、App Store Connect 密钥或本地账号信息。
- 不提交生成的 `.xcodeproj`，不手工维护无法由 CI 复现的工程状态。
- 不复制 Windows Godot/GDScript 业务逻辑到 Apple 目录。
- 不在 Widget、Activity 或 Watch 中创建第二套工资计算规则。
- 不以无签名 Simulator 编译代替签名、真机 App Group、系统 Widget 或通知验收。
