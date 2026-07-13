# Apple 工程目录契约

## 单一事实源

- 纯计算逻辑只存在于 `Packages/SalaryCore/Sources/SalaryCore/`。
- 配置与快照模型只存在于 `Shared/Models/`；各 Target 不复制字段定义。
- 用户文案进入 String Catalog；SwiftUI View 中不散落主要硬编码文案。
- App 是配置事实源；Widget、Live Activity 与 Watch 只读取或接收快照。
- Playgrounds 与未来 Xcode workspace 引用同一份 `SalaryCore` 和共享源码，不维护第二套算法。

## 计划结构

```text
apple/
  Config/
    Identifiers.example.xcconfig
  Packages/
    SalaryCore/
  Shared/
    Models/
    Resources/
  App/
  WidgetExtension/
  WatchApp/
  WatchWidgetExtension/
  Tests/
  Playgrounds/
```

## Target 与 Scheme

| Target/Scheme | 平台 | 职责 | 允许写主配置 |
| --- | --- | --- | --- |
| `LetsMakeMoneyApp` | iOS/iPadOS | 今日、日历、设置、引导、配置事务 | 是 |
| `LetsMakeMoneyWidget` | iOS/iPadOS | Widget、Live Activity、App Intent UI | 否 |
| `LetsMakeMoneyWatch` | watchOS | Watch App 与快照展示 | 否 |
| `LetsMakeMoneyWatchWidget` | watchOS | 复杂功能与 Smart Stack | 否 |
| `SalaryCoreTests` | Swift Package | 规则与金额测试 | 不适用 |
| `LetsMakeMoneyUITests` | iOS/iPadOS | App 主路径 UI 自动化 | 不适用 |

Live Activity UI 与桌面 Widget 归入同一 Widget Extension，避免重复 Activity 模型。Watch 操作必须通过 WatchConnectivity 等待 iPhone 结果，不得直接写配置或乐观显示成功。

## Playgrounds 到 Xcode 的迁移

1. iPad App Playground 只承载 App 壳和主页面原型。
2. `SalaryCore` 以独立 Swift Package 方式加入 App Playground。
3. 进入 macOS/Xcode 后，创建正式 workspace 和 Target，再引用同一 Package/共享源文件。
4. Playgrounds 特有的 App 清单、占位资源和预览代码不迁入核心模块。
5. 正式 Xcode 工程建立后，App Playground 停止承载新增业务逻辑，只作为历史 Spike 证据保留。

## 禁止项

- 不提交真实 Team ID、证书、描述文件、私钥、App Store Connect 密钥或本地账号信息。
- 不手工编造不可由 Xcode 验证的 `.xcodeproj`、entitlements 或签名结果。
- 不复制 Windows Godot/GDScript 业务逻辑到 Apple 目录。
- 不在 Widget、Activity 或 Watch 中创建第二套工资计算规则。
