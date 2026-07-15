# SalaryCore

`SalaryCore` 是不依赖 SwiftUI 和 Apple 系统扩展框架的纯 Swift Package。它负责真实工作日、午休、日期覆盖、工资、进度与状态计算，并提供可跨 Target 复用的配置持久化、共享快照和结构化日志能力。

## 公开 API

```swift
let snapshot = try SalaryCalculator.calculate(
    configuration: configuration,
    now: now,
    timeZone: timeZone,
    holidays: holidayCalendar
)
```

调用方必须显式传入配置、当前时刻、时区和节假日数据。输出 `SalarySnapshot` 不可变；配置非法时抛出 `SalaryCoreError`，不返回误导金额。

M2 数据层提供：

- `ConfigurationDraft`：取消或关闭时恢复原值，不污染有效配置。
- `ConfigurationStore`：字段校验、无变化保存、临时写入、读回校验、原子替换、损坏备份与旧 schema 迁移。
- `SharedSnapshotStore`：向 Widget、Activity 和 Watch 提供同一身份的只读快照。
- `AppGroupContainerProvider`：封装 App Group 容器获取，并在 entitlement 不可用时返回结构化降级错误。
- `LocalEventLogger`：JSON Lines 结构化日志、有限轮换及路径、工资和账号类字段脱敏。

## 本地验证

```powershell
swift test --package-path apple/Packages/SalaryCore
python -m unittest scripts.apple.tests.test_salary_contract -v
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\apple\test_check_ios_m2.ps1
```

Windows 当前使用 Swift 6.3.3、MSVC 14.44 与 Windows SDK 10.0.22621.0 完成纯 Swift 验证。App Group 的真实容器、Xcode Target 和签名能力仍需 macOS/Xcode 与 Apple 设备补证。
