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
继续 LetsMakeMoney iOS v0.1 的 Mac/Xcode 恢复开发。

仓库路径是当前打开的 LetsMakeMoney-ios，目标分支 ios-main。
先阅读：
- doc/releases/ios-v0.1/mac-codex-handoff.md
- doc/releases/ios-v0.1/status.md
- doc/releases/ios-v0.1/progress_ios-v0.1.md
- doc/releases/ios-v0.1/m4-device-verification.md
- doc/releases/ios-v0.1/m5-device-verification.md
- doc/releases/ios-v0.1/m6-device-verification.md

本轮只执行 mac-codex-handoff.md 的“身份核对”和“第一轮无签名门禁”：
记录 macOS、Xcode、Swift、Python、分支和 HEAD；运行 SalaryCore 与 Python 合同测试；使用仓库固定 XcodeGen 2.45.4 生成工程；无签名编译正式 iOS App/Widget 与 Watch App/Watch Widget。

不得修改业务代码、部署下限、schema、工资算法、签名、Team ID 或 App Group。失败时先定位并汇报最小错误与日志证据，不猜测修复。成功后更新 status、progress 和开发日志，并停下等待我确认是否进入 G4 签名与真机阶段。不要提交或推送，除非我另行授权。
```

