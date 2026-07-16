# iOS v0.1 已知限制

## 产品范围

- 首版只支持 iPhone、iPad、Apple Watch、Widget 和 Live Activity；不包含 macOS、Android 或 Windows 配置同步。
- 首版不包含桌宠、主题系统、更多宠物、加班收入、账号或云同步。
- iPhone 与 iPad 各自保存配置，不自动同步。口令式跨终端同步仅作为后续设想。

## 数据与计算

- 中国大陆节假日数据固定覆盖 2025-2027；超出范围时按周休规则回退，并明确提示数据范围不足。
- Widget、Live Activity、复杂功能和 Watch 使用最近有效共享快照，不直接修改工资配置。
- Widget、Live Activity、Smart Stack 和常亮显示的刷新频率由系统决定，产品不承诺每秒重绘；金额由时间锚点在展示时推导。
- Watch 离线时只展示最近快照和同步时间，启动/结束 Live Activity 必须等待 iPhone 确认。

## 开发与分发

- Windows Swift 和静态门禁不能替代 Apple SDK、签名、TestFlight 或真机验收。
- Swift Playgrounds 只能验证有限 App/Package 能力，不能完整创建正式 Widget、Activity、Watch Extension 或 entitlement。
- 当前没有可用 macOS/Xcode 本机环境；Apple SDK 编译使用 GitHub macOS 工作流。
- 完整 Beta 发布仍依赖 Apple Developer Program、正式 Bundle ID/App Group、签名 archive 和真实设备验收。

## 待补证项目

- iPhone 16 Pro Max：通知、Widget、Live Activity、锁屏、灵动岛和系统限流；
- iPad Pro M4：横竖屏、分屏、动态字体和配置主路径；
- Apple Watch Series 10：在线、离线、重连、复杂功能、Smart Stack 和常亮；
- 全设备：深浅色、高对比度、VoiceOver、降低动态效果、时区、跨日、锁屏、重启与低电量。

这些项目在真实设备证据完成前只能标记“待补证”，不能写成通过。
