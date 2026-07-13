# iPad Swift Playgrounds M0 人工验证

## 状态

- 验收 ID：`IOS01-M0-007`
- 当前结论：待人工补证
- 设备：iPad Pro M4，iPadOS 26.5.2（由项目所有者提供）
- 目标：确认 App Playground、多个 Swift 文件、SwiftUI Preview 和添加 Swift Package 的真实可用性
- 边界：不验证 Widget、Live Activity、Watch、多 Target、签名或 TestFlight

## 准备

1. 在 iPad 更新并打开最新版 Swift Playgrounds。
2. 确保可创建新 App；本步骤不要求登录 App Store Connect。
3. 不填写或截图 Apple ID、Team ID、设备序列号等私人信息。

## 操作步骤

### 1. 创建 App Playground

1. 点击“新建 Playground”或加号。
2. 选择“App”模板，而不是 Playground Book。
3. 名称填写 `LetsMakeMoneyCapability`。
4. 等待项目生成后运行默认 App。

通过标准：预览或全屏运行出现默认 SwiftUI 页面，无编译错误。

### 2. 验证多文件与 SwiftUI

1. 新建 Swift 文件 `CapabilityModel.swift`。
2. 输入一个简单模型：

```swift
struct CapabilityModel {
    let monthlySalaryMinor: Int64 = 1_200_000
}
```

3. 在 `ContentView` 里引用该模型并显示 `1200000`。
4. 刷新 Preview，再全屏运行。

通过标准：不同 Swift 文件可互相引用，Preview 和运行结果一致。

### 3. 验证本地 Package 迁移边界

1. 在项目导航中确认存在“添加 Swift Package”入口。
2. 只确认入口和版本选择界面；本轮不添加未知第三方依赖。
3. 记录该入口是否仅支持 URL、是否允许本地 Package，以及界面显示的限制。

通过标准：能确认 App Playground 使用 Swift Package Manager；若只支持 URL，记录为限制，不判失败。

### 4. 验证导出/转交

1. 打开项目分享菜单。
2. 确认可以导出或共享 App Playground 项目文件。
3. 不实际上传公开仓库；记录导出文件扩展名与可用目的地。

通过标准：项目可从 iPad 导出，未来能交给 macOS/Xcode 继续开发。

## 结果填写

```text
验证日期：
Swift Playgrounds 版本：
创建 App：通过 / 未通过
多 Swift 文件：通过 / 未通过
SwiftUI Preview：通过 / 未通过
全屏运行：通过 / 未通过
添加 Package 入口：通过 / 部分通过 / 未通过
导出项目：通过 / 未通过
导出扩展名：
错误信息：
截图路径或文件名：
备注：
```

## 判定

- 全部主项通过：G2 通过，可进入 iPad App 原型实施。
- App 可运行但 Package 受限：G2 部分通过；SalaryCore 仍保持独立源码目录，待 Xcode 接入。
- App 无法创建/运行：G2 未通过；停止 Playgrounds 双轨，保留 schema/SalaryCore 工作并等待 macOS/Xcode。
