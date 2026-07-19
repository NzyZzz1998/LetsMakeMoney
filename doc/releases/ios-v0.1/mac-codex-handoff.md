# LetsMakeMoney iOS v0.1 Mac Codex 交接

## 1. 交接目标

本文件是 Mac 上 Codex 恢复 iOS v0.1 开发的第一入口。第一轮只建立本机 Xcode 基线、复现无签名构建并记录工具链差异；在基线通过前，不修改业务逻辑、不处理发布，也不把模拟器结果写成真机通过。

## 2. 当前事实

- 产品线：Apple 独立产品线，版本 `ios-v0.1-beta`。
- 分支：`ios-main`。
- 交接前 HEAD：`aa5e127292cc332ec38c7992a129a505bf8a9a8c`；Mac 端必须以拉取后的实际 HEAD 为验收身份。
- 已完成：M0-M3、M3R；M4 为 16/17，M5 为 13/14，M6 为 9/13。
- 自动证据：SalaryCore 86/86；GitHub macOS 已完成 App、Widget/Activity、Watch App 与 Watch Widget 的无签名 Simulator SDK 编译。
- 待关闭：本地 Xcode 基线、正式签名与 App Group、M4/M5/M6 真机补证、M7 archive 与 Acceptance。
- 部署下限保持 iOS/iPadOS 18、watchOS 11；目标设备运行 26.x 不代表把部署下限改成 26.x。
- CI 历史基线为 Xcode 16.4 / Swift 6.1.2。新 Mac 推荐使用支持 iOS 26.5 的 Xcode 26.6；这属于工具链升级复核，不能默认等价通过。

## 3. Mac 必需环境

1. macOS Tahoe 26.2 或更高。
2. Xcode 26.6 正式版，不使用 Xcode 27 Beta。
3. Xcode 的 iOS 26.5 与 watchOS 26.5 平台组件。
4. Xcode Command Line Tools、Git、系统 shell。
5. Python 3，用于现有合同测试。
6. 仓库固定的 XcodeGen 2.45.4，由 `scripts/apple/bootstrap_xcodegen.sh` 下载并校验，不依赖全局 Homebrew 安装。

PowerShell 7 只在复跑现有 `.ps1` 全量门禁时需要。第一轮无签名 Xcode 基线不要求先安装；如确需安装，Codex 应先说明用途并等待项目所有者确认。

## 4. 克隆与身份核对

```bash
mkdir -p ~/Developer
cd ~/Developer
git clone --branch ios-main https://github.com/NzyZzz1998/LetsMakeMoney.git LetsMakeMoney-ios
cd LetsMakeMoney-ios

git status --short --branch
git rev-parse HEAD
git remote -v
xcodebuild -version
swift --version
python3 --version
```

通过标准：位于 `ios-main`，工作树干净，远端为官方仓库，实际 HEAD、Xcode、Swift、Python 和 macOS 版本已记录。

## 5. 第一轮无签名门禁

### 5.1 初始化 Xcode

```bash
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### 5.2 运行纯 Swift 与合同测试

```bash
swift test --package-path apple/Packages/SalaryCore
python3 -m unittest discover -s scripts/apple/tests -p 'test_*.py'
```

### 5.3 安装固定 XcodeGen 并生成正式工程

```bash
XCODEGEN_ROOT="$HOME/Library/Caches/LetsMakeMoney/xcodegen-2.45.4"
bash scripts/apple/bootstrap_xcodegen.sh "$XCODEGEN_ROOT"
"$XCODEGEN_ROOT/xcodegen/bin/xcodegen" generate \
  --spec apple/project.yml \
  --project apple

xcodebuild -project apple/LetsMakeMoney.xcodeproj -list
```

### 5.4 无签名编译正式 App 与 Watch

```bash
mkdir -p build/apple-mac-handoff

set -o pipefail
xcodebuild \
  -project apple/LetsMakeMoney.xcodeproj \
  -scheme LetsMakeMoneyApp \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/apple-mac-handoff/AppDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build | tee build/apple-mac-handoff/app-widget.log

xcodebuild \
  -project apple/LetsMakeMoney.xcodeproj \
  -scheme LetsMakeMoneyWatchApp \
  -destination 'generic/platform=watchOS Simulator' \
  -derivedDataPath build/apple-mac-handoff/WatchDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build | tee build/apple-mac-handoff/watch.log
```

通过标准：SalaryCore、Python 合同测试、工程生成、App/Widget 与 Watch/Watch Widget 无签名编译全部通过；日志保存于 `build/apple-mac-handoff/`，不得提交。

## 6. 第一轮停止条件

出现以下任一情况必须停止在诊断阶段，不得顺手改业务代码：

- 分支、远端或工作区身份不正确。
- Xcode 26.6 编译暴露 Swift 6.3/API 差异。
- 固定 XcodeGen 下载或 SHA256 校验失败。
- App、Widget、Watch 或 Watch Widget target 缺失。
- 需要修改部署下限、schema、工资算法或共享快照合同才能编译。
- 需要填写 Team ID、证书或 App Group 才能完成无签名门禁。

失败时记录最小错误、日志路径、受影响 target 和建议方案，等待项目所有者确认。

## 7. 签名阶段边界

无签名门禁通过后才能进入 G4：

1. 在 Xcode 登录 Apple Account。
2. 确认是否已有 Apple Developer Program 会员与 Team ID。
3. 使用本地忽略文件 `apple/Config/Identifiers.local.xcconfig` 保存本机标识符；不得提交真实 Team ID、Bundle ID、App Group、证书或 profile。
4. App、Widget、Watch App 与 Watch Widget 必须使用同一受控 App Group 合同。
5. 免费 Personal Team 可以做基础真机测试，但七天 profile、App ID 数量和高级 capability 存在限制；不得把它写成完整 G4 或 TestFlight 通过。
6. 未确认本地配置如何安全覆盖 `project.yml` 前，不直接修改跟踪的公共示例配置。

## 8. 真机验收入口

G4 关闭后按顺序执行：

1. `m4-device-verification.md`：iPhone Widget、Live Activity、通知与系统行为。
2. `m5-device-verification.md`：Apple Watch、离线/重连、复杂功能与 Smart Stack。
3. `m6-device-verification.md`：iPhone/iPad 外观、辅助功能、跨 Target 一致性和系统状态。
4. 全部通过后才进入 M7 archive、候选身份锁定和 Acceptance。

## 9. 安全边界

不得提交：

- Apple Account 密码、Team 私钥、`.p12`、`.mobileprovision`。
- App Store Connect API 私钥和 token。
- `Identifiers.local.xcconfig`。
- DerivedData、archive、真机日志、设备标识符和隐私截图。
- 包含真实工资、用户路径或完整配置的诊断文件。

## 10. 发给 Mac Codex 的启动提示词

```text
目标：接手 LetsMakeMoney Apple 产品线，在新 Mac 上恢复 iOS v0.1 Beta 开发，并完成第一轮 Xcode 无签名基线验证。本轮不是新功能开发，也不是发布或签名阶段。

## 项目介绍

LetsMakeMoney 是一个本地优先的工资进度工具。用户配置月薪、休息模式、上下班和午休时间后，应用按照真实工作日、法定节假日、调休和手动覆盖，计算今日已赚、日薪、时薪、工作进度与今日安排。

Apple 产品线不复制 Windows 桌宠形态，而是提供：
- iPhone/iPad SwiftUI App：今日、日历、设置和首次引导；
- Widget 与 Live Activity：桌面、锁屏和灵动岛展示；
- Apple Watch App 与复杂功能：查看收入、进度、剩余时间和今日安排；
- 本地配置与 App Group 共享快照；
- 无账号、无后端、无云同步，工资与日志不上传。

当前 GitHub 仓库同时包含 Windows 与 Apple 代码。你只接手 Apple 产品线：
- 仓库地址：https://github.com/NzyZzz1998/LetsMakeMoney.git；
- 目标分支：ios-main；
- Apple 工程：apple/；
- 工资计算内核：apple/Packages/SalaryCore/；
- iPhone/iPad App：apple/App/；
- Widget/Live Activity：apple/WidgetExtension/、apple/Shared/LiveActivity/；
- Watch：apple/WatchApp/、apple/WatchWidgetExtension/、apple/Shared/Watch/；
- 工程定义：apple/project.yml；
- 跨平台 schema 与节假日数据：shared/salary-schema/；
- 构建和验证入口：scripts/apple/。

不要修改 Windows src/、native/、installer/ 或 Windows 发布逻辑。

## 当前进度

- 目标版本：ios-v0.1-beta。
- M0-M3 与 M3R 已完成。
- M4 Widget/Activity 为 16/17，只剩真实 iPhone 系统行为验收。
- M5 Watch 为 13/14，只剩 Apple Watch 真机验收。
- M6 一致性与质量为 9/13，剩余深浅色、辅助功能和系统状态真机矩阵。
- M7 候选归档、Acceptance 与 Beta 发布尚未开始。
- SalaryCore 已有 86/86 自动测试通过记录。
- GitHub macOS 曾使用 Xcode 16.4 完成 App、Widget/Activity、Watch App 与 Watch Widget 的无签名 Simulator SDK 编译。
- 新 Mac 计划使用 Xcode 26.6，因此必须先验证 Swift 6.3 和新 SDK 是否产生差异，不能沿用旧 CI 结论冒充本机通过。
- 部署下限保持 iOS/iPadOS 18、watchOS 11；设备运行 iOS/watchOS 26.x 不代表提高部署下限。
- 当前没有正式签名与 App Group 真机证据，不具备 Beta 发布条件。

## 获取仓库

如果 Mac 本地尚未存在项目，先在终端执行：

```bash
mkdir -p ~/Developer
cd ~/Developer
git clone --branch ios-main --single-branch \
  https://github.com/NzyZzz1998/LetsMakeMoney.git \
  LetsMakeMoney-ios
cd LetsMakeMoney-ios
```

随后核对身份：

```bash
git status --short --branch
git branch --show-current
git rev-parse HEAD
git remote -v
```

必须确认当前分支为 `ios-main`，`origin` 指向
`https://github.com/NzyZzz1998/LetsMakeMoney.git` 或等价 SSH 地址。

如果 `~/Developer/LetsMakeMoney-ios` 已存在：

- 不得直接删除、覆盖、重新克隆或执行 `git reset --hard`；
- 先检查分支、remote 和工作区状态；
- 工作区干净时才可执行 `git fetch origin` 和 `git pull --ff-only origin ios-main`；
- 存在未提交修改或身份不一致时，停止并向项目所有者报告。

## 开始前必须阅读

- doc/releases/ios-v0.1/mac-codex-handoff.md
- doc/releases/ios-v0.1/status.md
- doc/releases/ios-v0.1/progress_ios-v0.1.md
- doc/releases/ios-v0.1/prd.md
- doc/releases/ios-v0.1/dev_plan_ios-v0.1.md
- apple/README.md
- apple/PROJECT_LAYOUT.md
- doc/releases/ios-v0.1/m4-device-verification.md
- doc/releases/ios-v0.1/m5-device-verification.md
- doc/releases/ios-v0.1/m6-device-verification.md

先建立项目和模块地图，再执行任务；不要只读一份 README 就开始修改。

## 本轮任务

严格执行 mac-codex-handoff.md 第 4、5、6 节：

1. Mac 尚无项目时，按“获取仓库”一节克隆 `ios-main`；已有项目时先保护并核对现有工作区。
2. 核对 Git 身份：分支、HEAD、remote、工作区状态和最近提交。
3. 记录 Mac 型号、芯片、macOS、Xcode、Swift、Python 和可用 Simulator runtime。
4. 初始化 Xcode Command Line Tools。
5. 运行 SalaryCore 全量 Swift 测试。
6. 运行 scripts/apple/tests 下的 Python 合同测试。
7. 使用仓库脚本下载并校验固定 XcodeGen 2.45.4，不使用未锁定的全局版本。
8. 根据 apple/project.yml 生成正式 Xcode 工程。
9. 列出正式 schemes，确认 App、Widget、Watch App 和 Watch Widget 都存在。
10. 使用 CODE_SIGNING_ALLOWED=NO：
   - 编译 LetsMakeMoneyApp 及内嵌 Widget/Activity；
   - 编译 LetsMakeMoneyWatchApp 及内嵌 Watch Widget。
11. 检查产物中对应 .app/.appex 是否真实存在。
12. 将完整日志保存在 build/apple-mac-handoff/，不得提交构建产物。

## 本轮禁止事项

- 不修改 Swift 业务代码、工资算法、配置 schema 或节假日数据。
- 不修改部署下限，不因 Xcode 26.6 自动建议就接受工程迁移。
- 不配置 Team ID、Bundle ID、App Group、证书或 provisioning profile。
- 不登录或记录 Apple Account 密码。
- 不安装未知第三方依赖；PowerShell/Homebrew 如确有需要，先解释用途并等待确认。
- 不把模拟器、Preview 或无签名编译写成真机通过。
- 不进入 M4/M5/M6 真机验收或 M7。
- 不提交、不推送、不打 tag，除非项目所有者另行授权。

## 失败处理

失败时先按系统化调试定位：记录第一条真实编译错误、受影响 target、完整日志路径和最小复现命令。区分：
- 环境/平台组件缺失；
- XcodeGen 或工程生成问题；
- Swift 6.3 / Xcode 26.6 工具链差异；
- Apple SDK API 变化；
- 既有源码缺陷。

不要为了让构建通过直接改业务代码。若必须修改源码、project.yml、entitlement 或部署下限，先停下给出证据和最小方案，等待确认。

## 完成后输出

1. 项目与 Apple 模块地图。
2. 分支、HEAD、工作区与 remote。
3. Mac、macOS、Xcode、Swift、Python、XcodeGen 和 Simulator 版本。
4. SalaryCore 与 Python 测试准确结果。
5. App/Widget 和 Watch/Watch Widget 无签名构建结果及日志路径。
6. 与旧 Xcode 16.4 CI 基线的差异。
7. 阻塞项、非阻塞警告和未执行项。
8. 是否满足进入 G4 签名阶段。

若全部通过，只更新 status、progress 和 dev log 的事实；随后停下等待项目所有者确认。不要自行进入签名或真机阶段。
```
