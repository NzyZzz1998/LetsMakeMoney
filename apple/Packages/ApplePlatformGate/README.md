# ApplePlatformGate

该 Swift Package 仅用于 G3 环境门禁：

- `G3AppProbe` 验证 SwiftUI App 边界；
- `G3WidgetActivityProbe` 验证 WidgetKit、ActivityKit 与 App Intents 边界；
- `G3WatchProbe` 验证 watchOS SwiftUI、WidgetKit 与 WatchConnectivity 边界。

probe 在 GitHub macOS runner 的 iOS/watchOS Simulator SDK 上编译。通过只表示工具链与 SDK 可用，不表示正式 Extension、entitlement、签名或真机行为已经通过。
