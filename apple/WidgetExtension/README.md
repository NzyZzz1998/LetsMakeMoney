# Widget 与 Live Activity Extension

## 当前状态

- `LetsMakeMoneyWidget` 已作为正式 iOS App Extension target 写入 `apple/project.yml`。
- GitHub macOS 使用固定 XcodeGen 生成工程，并以 Xcode 16.4 无签名构建 App 与 Widget。
- `SalaryWidgetProvider` 通过 `SharedSnapshotReading` 读取 App Group 中的 `SharedSnapshotBundle`，不得写主配置。
- `.systemSmall` 已展示今日金额和显式工作状态；`.systemMedium` 在此基础上增加工作进度百分比和进度条。
- 两种尺寸共用占位、未配置与快照不可用三类降级界面，不复制快照读取或错误状态机。
- 大、锁屏 families、时间线过期策略、Live Activity 与通知仍按 `IOS01-M4-005` 之后的任务推进。

## 数据边界

1. App 是配置和计算事实源。
2. App 在成功加载或保存配置后生成共享快照。
3. Widget 只读快照并生成时间线，不复制工资算法，也不直接修改配置。
4. App Group 不可用时，Widget 显示可降级状态，不伪造实时数据。

## 生成与验证

```bash
bash scripts/apple/bootstrap_xcodegen.sh /tmp/lmm-xcodegen
xcodegen generate --spec apple/project.yml --project apple
xcodebuild \
  -project apple/LetsMakeMoney.xcodeproj \
  -scheme LetsMakeMoneyApp \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

生成的 `.xcodeproj` 是构建产物，不作为手工事实源提交。正式签名、真机 App Group 读写、桌面添加和系统刷新行为仍需 Apple Developer Team 与真机验收。
