# Apple 测试边界

- `SalaryCore`：纯 Swift 单元测试和 JSON 测试向量。
- App：配置事务、导航和 SwiftUI UI 测试。
- Widget/Activity：快照、时间线和状态机测试。
- Watch：消息编码、超时、离线、重连与跨日测试。
- Integration：相同配置/时刻下的跨 Target 快照一致性。

Windows 静态检查不能替代 Swift/Xcode 测试或真实设备验收。

## M3 UI 自动化矩阵

- `M3SmokeUITests.swift` 使用稳定的无障碍标识覆盖今日、日历、设置关闭和首次引导入口。
- 已配置主路径使用 `-ui-test-reset-configuration -ui-test-configured`，每次从确定配置启动。
- 首次引导使用 `-ui-test-reset-configuration`，不得依赖模拟器或真机残留配置。
- Windows 合同检查只验证测试源码与当前导航结构一致；真正的 `XCTest` 执行必须在 G3 macOS/Xcode 多 Target 环境完成。
