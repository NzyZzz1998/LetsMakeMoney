# iOS v0.1 环境、Target 与标识符策略

## 工具链策略

| 项目 | 策略 | 当前证据 |
| --- | --- | --- |
| iOS/iPadOS/watchOS 最低版本 | 26.5，与 PRD 和目标设备一致 | 文档已冻结，待 Xcode 验证可选 SDK |
| Swift 语言模式 | 使用正式 Xcode 所附稳定 Swift；M0 不猜测具体小版本 | 待 G3 |
| Swift Package tools version | 在首次可用 macOS/Xcode 环境按实际版本固定 | 待 G3 |
| Xcode | 选择支持目标系统的稳定正式版，记录完整 build version | 待 G3 |
| Swift Playgrounds | iPad 上验证 App Playground 与 Package 接入 | 待 G2 人工补证 |
| 第三方依赖 | 首版默认无第三方运行时依赖 | 已确认策略 |

M0 不提交未经编译验证的 Xcode 工程元数据。取得 macOS/Xcode 后，必须把 Xcode、SDK、Swift 和构建目标写入构建 manifest。

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
