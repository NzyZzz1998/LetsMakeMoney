# iOS v0.1 环境、Target 与标识符策略

## 工具链策略

| 项目 | 策略 | 当前证据 |
| --- | --- | --- |
| 编译部署下限 | SalaryCore 与 G3 probe 当前固定为 iOS/iPadOS 18、watchOS 11；目标设备 26.x 是验收系统，不等同部署下限 | GitHub macOS G3 编译通过；发布前仍需正式 Xcode 工程复核 |
| Swift 语言模式 | Swift 6；使用正式 Xcode 所附稳定 Swift | GitHub runner 为 Apple Swift 6.1.2 |
| Swift Package tools version | `swift-tools-version: 6.0` | SalaryCore 与 ApplePlatformGate manifest 已验证 |
| Xcode | GitHub `macos-15` runner 的 Xcode 16.4（16F6）作为当前无签名编译基线 | Actions run `29397574782` 通过 |
| Swift Playgrounds | iPad 上验证 App Playground 与 Package 接入 | G2 已通过，Swift Playgrounds 4.7 |
| 第三方依赖 | 首版默认无第三方运行时依赖 | 已确认策略 |

G3 使用 `apple/Packages/ApplePlatformGate/` 验证 App、Widget/Activity 与 Watch 所需 SDK 边界。该 probe 只证明工具链和 Framework 可编译，不替代正式 Extension target、entitlement、签名、XCTest 或真机证据。

## 标识符模板

公共模板位于 `apple/Config/Identifiers.example.xcconfig`：

```text
App:          $(ORGANIZATION_IDENTIFIER).LetsMakeMoney
Widget:       $(APP_BUNDLE_IDENTIFIER).Widget
Watch App:    $(APP_BUNDLE_IDENTIFIER).Watch
Watch Widget: $(WATCH_BUNDLE_IDENTIFIER).Widget
App Group:    group.$(APP_BUNDLE_IDENTIFIER)
```

### 本地私有值

- 开发者在本地复制为 `Identifiers.local.xcconfig`。
- 本地文件可填写真实 `DEVELOPMENT_TEAM` 与正式 organization identifier。
- `Identifiers.local.xcconfig`、证书、描述文件和私钥均被 `.gitignore` 排除。
- 构建日志和截图不得泄露 Apple ID、Team ID、设备 UDID 或签名证书序列号。

## Target 与权限

| Target | Bundle ID 后缀 | 计划权限 | 配置权限 |
| --- | --- | --- | --- |
| App | 无 | App Group、通知、Live Activity、Watch 通信 | 唯一可写事实源 |
| Widget/Activity | `.Widget` | App Group、ActivityKit/App Intents | 只读快照 |
| Watch App | `.Watch` | WatchConnectivity | 只读快照，请求由 iPhone 确认 |
| Watch Widget | `.Watch.Widget` | WidgetKit/App Intents | 只读快照 |

真实 entitlement 文件只在 Xcode 建立并验证后提交；M0 仅冻结名称、职责和禁止越权规则。

## 签名与秘密边界

- 仓库只保存无秘密模板和能力说明。
- Apple Developer Program、Team ID、App Store Connect key、证书和 provisioning profile 不进入 Git。
- 无签名时可以推进纯 Swift 内核和部分 App 原型，但不能将 App Group、Activity、Watch 真机能力写成通过。
