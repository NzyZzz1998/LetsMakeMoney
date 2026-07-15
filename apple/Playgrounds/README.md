# iPad Swift Playgrounds 能力验证

本目录不维护独立业务实现。M0 先在 iPad 的 Swift Playgrounds 中创建最小 App Playground，再验证能否添加未来的 `SalaryCore` Swift Package。

真实操作步骤和证据模板见：

`doc/releases/ios-v0.1/playgrounds-verification.md`

验证通过后，仅将可复用 Swift 源码迁回仓库；不要把带个人账号、Team ID 或设备信息的工程设置直接提交。

## M3 App 真机包

在 Windows 仓库根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apple\export_playgrounds_m3.ps1
```

输出位于 `build/apple-playgrounds/`。将 `LetsMakeMoneyM3-playgrounds.zip` 传到 iPad，解压后在“文件”中点击 `LetsMakeMoneyM3.swiftpm`，选择 Swift Playgrounds 打开。

该目录是从 `apple/App` 与 `SalaryCore` 单一事实源生成的本地验收产物，不提交到 Git。若 Playgrounds 要求选择签名身份，只选择本人的本地开发身份，不把 Team ID 回写仓库。
