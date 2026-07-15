# iOS v0.1 分层调试流程

## 目标

减少 Swift Playgrounds 只显示 `Build failed` 或静默退出时的重复传包、猜测修复和人工二分成本。调试按 Windows、macOS CI、iPad 三层进行；任何一层通过都不能替代下一层证据。

## 三层职责

| 层级 | 负责内容 | 能发现 | 不能证明 |
| --- | --- | --- | --- |
| Windows | SalaryCore、配置、状态机、共享模型、源码合同 | 业务错误、迁移错误、已知危险 API 和回归 | SwiftUI/UIKit 的 Apple SDK 类型与运行时行为 |
| GitHub Actions macOS | Apple 工具链、iOS Simulator SDK 编译 | Apple API 不可用、SwiftUI 类型推断、资源和 Target 编译错误 | 真机触控、系统弹窗、Playgrounds 特有运行时差异 |
| iPad Debug Hub / 正式候选包 | Swift Playgrounds 与真机运行 | 静默崩溃边界、页面交互、横竖屏和辅助功能 | iPhone、Widget、Activity、Watch 与正式签名 |

## 日常调试顺序

1. 在 Windows 修改代码并运行对应 Swift/Python/合同测试。
2. 运行 `scripts/apple/check_ios_m3.ps1`；失败时不传 iPad。
3. 需要 Apple SDK 类型证据时，推送 `ios-main` 的 Apple 相关变更以自动运行 `.github/workflows/apple-sdk-experimental.yml`，也可在工作流注册后手动触发。
4. macOS 工作流首次验证通过前只作为实验性门禁；失败时下载 `apple-sdk-experimental-diagnostics` 查看 `xcodebuild.log`。
5. Apple SDK 编译通过后，再将完整候选包传入 iPad。
6. 完整候选包静默崩溃时，改用 Debug Hub，不再立即创建新探针。

## Debug Hub

生成命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\apple\export_playgrounds_debug_hub.ps1
```

输出：

```text
build/apple-playgrounds-debug-hub/LMMDebugHub-playgrounds.zip
```

Hub 按层提供：

- `CORE`
- `MODEL`
- `NAVIGATION`
- `TODAY`
- `CALENDAR`
- `SETTINGS`
- `ONBOARDING`
- `FULLAPP`

每次只打开一层。打开前写入 `opening.<module>`，页面完成显示后写入 `visible.<module>`。如果页面导致 Playgrounds 静默退出，重新启动 Debug Hub，顶部 `LAST STAGE` 即为上次最后成功边界。

判断示例：

| LAST STAGE | 含义 |
| --- | --- |
| `hub.launch` | Hub 自身或模型初始化前后失败 |
| `opening.navigation` | 导航页面开始创建，但未完成显示 |
| `visible.navigation` | 导航已显示，故障发生在后续交互 |
| `opening.fullApp` | 完整根视图组合阶段失败 |

## 旧探针的保留边界

`export_playgrounds_*_probe.ps1` 保留为最后的最小二分工具。只有 Debug Hub 本身无法启动，或某个模块在 Hub 中仍无法进一步定位时才使用。不得把探针通过写成正式 App 验收通过。

## 本次已固化的兼容规则

Swift Playgrounds 4.7 中，下面的 `@MainActor` 方法引用可以编译，但在真机启动时静默崩溃：

```swift
Binding(get: { model.navigation.destination }, set: model.select)
```

必须使用显式闭包：

```swift
Binding(get: { model.navigation.destination }, set: { model.select($0) })
```

该规则由 `scripts/apple/tests/test_app_root_playgrounds_compatibility.py` 守护。

## 当前限制

- Windows 官方 Swift 工具链不包含 SwiftUI/UIKit 运行环境。
- macOS Actions 工作流尚需首次远端手动运行，当前不能写成已通过。
- Swift Playgrounds 的静默崩溃仍可能没有系统堆栈；Debug Hub 只能缩小边界，不能替代 Xcode 崩溃日志。
- Widget、Live Activity、Apple Watch 和签名仍需要后续 Xcode 多 Target 环境。
