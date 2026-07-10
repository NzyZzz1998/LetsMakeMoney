# LetsMakeMoney v0.6 Beta 人工补证

**状态**：已完成；纯桌宠托盘恢复通过，真实登录开机自启暂不验证
**适用包**：`releases/v0.6/LetsMakeMoney-v0.6-beta-windows-x86_64.zip`
**Zip SHA256**：`CECD3C3ABACFCB5EF594584E2AEB0E25C1824BAE97AB84B224073E7444E72615`

Settings 保存失败可见反馈和纯桌宠托盘恢复已经通过。真实登录开机自启按当前决定标记为“暂不验证”，不要求本轮继续注销、重启或补充证据，也不得写成通过。最终 Acceptance 将其作为 Beta 已知限制和发布后观察项，不再保留其他人工补证门禁。

## 1. 验收前准备

### 1.1 创建独立验收目录

在 PowerShell 中执行：

```powershell
$Project = "<PROJECT_ROOT>"
$Zip = Join-Path $Project "releases\v0.6\LetsMakeMoney-v0.6-beta-windows-x86_64.zip"
$TestRoot = Join-Path $Project ".manual-test\v0.6-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$ExtractRoot = Join-Path $TestRoot "app"
$BackupRoot = Join-Path $TestRoot "backup"
$AppDataRoot = Join-Path $env:APPDATA "LetsMakeMoney"

New-Item -ItemType Directory -Path $ExtractRoot, $BackupRoot -Force | Out-Null
Expand-Archive -LiteralPath $Zip -DestinationPath $ExtractRoot -Force
$Exe = Join-Path $ExtractRoot "LetsMakeMoney.exe"
```

后续所有测试都必须启动 `$Exe`，不要使用 `build\LetsMakeMoney.exe` 或以前解压的程序。

### 1.2 核对候选包身份

```powershell
Get-Item -LiteralPath $Zip | Select-Object FullName, Length, LastWriteTime
Get-FileHash -LiteralPath $Zip -Algorithm SHA256
Get-Item -LiteralPath $Exe | Select-Object FullName, Length, LastWriteTime
Get-FileHash -LiteralPath $Exe -Algorithm SHA256
```

预期：

- Zip 大小：`42,778,715` 字节。
- Zip SHA256：`CECD3C3ABACFCB5EF594584E2AEB0E25C1824BAE97AB84B224073E7444E72615`。
- EXE 大小：`113,240,688` 字节。
- EXE SHA256：`749F18E35E757A250EDA8D3DE5B712BD554861082E33D607E1D07835AA943E3B`。

任一值不一致时停止验证，说明使用的不是当前候选包。

### 1.3 结束旧进程并备份用户数据

```powershell
Get-Process LetsMakeMoney -ErrorAction SilentlyContinue | Stop-Process -Force

if (Test-Path -LiteralPath "$AppDataRoot\config.json") {
    Copy-Item -LiteralPath "$AppDataRoot\config.json" -Destination "$BackupRoot\config.json" -Force
}
if (Test-Path -LiteralPath "$AppDataRoot\debug.log") {
    Copy-Item -LiteralPath "$AppDataRoot\debug.log" -Destination "$BackupRoot\debug.log" -Force
}
if (Test-Path -LiteralPath "$AppDataRoot\debug.log.1") {
    Copy-Item -LiteralPath "$AppDataRoot\debug.log.1" -Destination "$BackupRoot\debug.log.1" -Force
}

$RunKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$AutoStartBefore = (Get-ItemProperty -Path $RunKey -Name "LetsMakeMoney" -ErrorAction SilentlyContinue).LetsMakeMoney
$AutoStartBefore | Set-Content -LiteralPath "$BackupRoot\autostart-before.txt" -Encoding UTF8
```

记录 `$TestRoot` 的实际值，验收结束前不要删除该目录。

## 2. Settings 保存失败可见反馈

### 2.1 记录测试前配置

```powershell
$BeforeConfig = Get-Content "$AppDataRoot\config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$BeforeSalary = $BeforeConfig.monthly_salary
$BeforeSalary
```

如果配置文件不存在，先正常启动 `$Exe` 并完成一次向导，然后退出程序再继续。

### 2.2 打开设置并修改输入

1. 执行 `Start-Process -FilePath $Exe`。
2. 在小猫区域右键。
3. 点击“设置”。
4. 打开“工资”页签。
5. 将“月薪”修改为一个与 `$BeforeSalary` 不同的值，例如 `13000`。
6. 暂时不要点击“保存”。

### 2.3 制造安全的临时写入失败

保持 Settings 窗口打开，在 PowerShell 中执行：

```powershell
$TempConfigPath = Join-Path $AppDataRoot "config.json.tmp"
Remove-Item -LiteralPath $TempConfigPath -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $TempConfigPath | Out-Null
Get-Item -LiteralPath $TempConfigPath | Select-Object FullName, PSIsContainer
```

预期 `PSIsContainer=True`。该方法只占用配置临时文件路径，不修改目录权限，也不破坏有效 `config.json`。

### 2.4 点击保存并观察

1. 将截图工具或手机录像提前准备好。
2. 点击 Settings 右下角“保存”。
3. 立即观察底部反馈区域。
4. 记录以下结果：
   - 是否出现“保存失败”或等效可读错误。
   - 输入框是否仍显示刚才输入的值。
   - Settings 是否保持打开且仍可操作。
5. 如果反馈出现，立即截图；反馈可能自动隐藏。

预期：

- 必须显示可读的保存失败反馈，不能显示“保存成功”。
- 用户输入必须保留。
- Settings 不能崩溃或自动关闭。

### 2.5 检查配置和日志

```powershell
$AfterFailedConfig = Get-Content "$AppDataRoot\config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
"测试前月薪：$BeforeSalary"
"失败后月薪：$($AfterFailedConfig.monthly_salary)"

Get-Content "$AppDataRoot\debug.log" -Tail 100 |
    Select-String "config_save_failed|settings_transaction_rollback|settings_save_failed"
```

预期：

- 失败后月薪与 `$BeforeSalary` 相同。
- 日志包含 `config_save_failed`。
- 日志包含 `settings_transaction_rollback`，且结果为 `success`。
- 日志包含 `settings_save_failed`。

### 2.6 清理失败条件

```powershell
Remove-Item -LiteralPath "$AppDataRoot\config.json.tmp" -Recurse -Force -ErrorAction SilentlyContinue
```

回到 Settings 点击“取消”或右上角关闭，避免把测试输入再次保存。

结果：`[√] 通过  [ ] 失败`
失败反馈是否可见： 是
输入是否保留：  是
有效配置是否未污染：  是
截图：  ![[6d6fb232bc053e12e17b09a98b931e11.png]]
日志关键行：  PS <WORKSPACE_ROOT>> $AfterFailedConfig = Get-Content "$AppDataRoot\config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
PS <WORKSPACE_ROOT>> "测试前月薪：$BeforeSalary"
测试前月薪：1000.0
PS <WORKSPACE_ROOT>> "失败后月薪：$($AfterFailedConfig.monthly_salary)"
失败后月薪：1000.0
PS <WORKSPACE_ROOT>>
PS <WORKSPACE_ROOT>> Get-Content "$AppDataRoot\debug.log" -Tail 100 |
>>     Select-String "config_save_failed|settings_transaction_rollback|settings_save_failed"

2026-07-10T22:06:56 | error | config_save_failed: temp_open_failed error=Can't open file
2026-07-10T22:06:57 | info | settings_transaction_rollback: reason=temp_open_failed error=Can't open file result=success
2026-07-10T22:06:57 | error | settings_save_failed: reason=temp_open_failed error=Can't open file
2026-07-10T22:07:03 | error | config_save_failed: temp_open_failed error=Can't open file
2026-07-10T22:07:03 | info | settings_transaction_rollback: reason=temp_open_failed error=Can't open file result=success
2026-07-10T22:07:03 | error | settings_save_failed: reason=temp_open_failed error=Can't open file
2026-07-10T22:07:04 | error | config_save_failed: temp_open_failed error=Can't open file
2026-07-10T22:07:05 | info | settings_transaction_rollback: reason=temp_open_failed error=Can't open file result=success
2026-07-10T22:07:05 | error | settings_save_failed: reason=temp_open_failed error=Can't open file
2026-07-10T22:07:15 | error | config_save_failed: temp_open_failed error=Can't open file
2026-07-10T22:07:15 | info | settings_transaction_rollback: reason=temp_open_failed error=Can't open file result=success
2026-07-10T22:07:15 | error | settings_save_failed: reason=temp_open_failed error=Can't open file
2026-07-10T22:07:16 | error | config_save_failed: temp_open_failed error=Can't open file
2026-07-10T22:07:17 | info | settings_transaction_rollback: reason=temp_open_failed error=Can't open file result=success
2026-07-10T22:07:17 | error | settings_save_failed: reason=temp_open_failed error=Can't open file
2026-07-10T22:07:27 | error | config_save_failed: temp_open_failed error=Can't open file
2026-07-10T22:07:28 | info | settings_transaction_rollback: reason=temp_open_failed error=Can't open file result=success
2026-07-10T22:07:28 | error | settings_save_failed: reason=temp_open_failed error=Can't open file
2026-07-10T22:10:05 | error | config_save_failed: temp_open_failed error=Can't open file
2026-07-10T22:10:05 | error | config_save_failed: temp_open_failed error=Can't open file

## 3. Windows 通知区真实左键

### 3.1 配置普通模式

先退出应用，再执行：

```powershell
$Config = Get-Content "$AppDataRoot\config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$Config.debug_mode = $false
$Config.pure_pet_mode = $false
$Config.minimize_to_tray = $true
$Config.system_tray_enabled = $true
$Config | ConvertTo-Json -Depth 10 | Set-Content "$AppDataRoot\config.json" -Encoding UTF8
```

### 3.2 普通模式隐藏与恢复

1. 执行 `Start-Process -FilePath $Exe`。
2. 等待 3 至 5 秒。
3. 确认桌宠和 Panel 可见。
4. 确认 Windows 任务栏存在 LetsMakeMoney 入口。
5. 点击通知区“显示隐藏的图标”箭头，找到橘猫托盘图标。
6. 左键单击橘猫托盘图标一次。
7. 确认桌宠和 Panel 隐藏。
8. 执行以下命令确认进程仍存在：

```powershell
Get-Process LetsMakeMoney -ErrorAction SilentlyContinue |
    Select-Object Id, Path, StartTime, Responding
```

9. 再次左键单击托盘图标。
10. 确认桌宠和 Panel 恢复。
11. 确认任务栏 LetsMakeMoney 入口正常出现。

普通模式结果：`[√] 通过  [ ] 失败`
隐藏后进程是否存在：  是
恢复后任务栏入口：`[√] 有  [ ] 无`
截图/录屏：
![[Pasted image 20260710221330.png]]
### 3.3 配置纯桌宠模式

先从右键菜单选择“退出”，确认进程结束，再执行：

```powershell
$Config = Get-Content "$AppDataRoot\config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$Config.debug_mode = $false
$Config.pure_pet_mode = $true
$Config.minimize_to_tray = $true
$Config.system_tray_enabled = $true
$Config | ConvertTo-Json -Depth 10 | Set-Content "$AppDataRoot\config.json" -Encoding UTF8
```

### 3.4 纯桌宠模式隐藏与恢复

1. 执行 `Start-Process -FilePath $Exe`。
2. 等待 3 至 5 秒。
3. 确认桌宠和 Panel 可见。
4. 确认任务栏没有 LetsMakeMoney 入口。
5. 左键单击通知区橘猫图标，确认桌宠和 Panel 隐藏。
6. 使用 `Get-Process LetsMakeMoney` 确认进程仍存在。
7. 再次左键单击托盘图标。
8. 确认桌宠和 Panel 恢复。
9. 重点确认恢复后任务栏仍然没有 LetsMakeMoney 入口。

纯桌宠结果：`[ ] 通过  [√] 失败（第一轮）`
隐藏后进程是否存在：是
恢复后任务栏入口：`[√] 有  [ ] 无`
截图/录屏：  ![[Pasted image 20260710221445.png]]

### 3.5 检查托盘日志

```powershell
Get-Content "$AppDataRoot\debug.log" -Tail 160 |
    Select-String "tray_left_toggle_requested|tray_left_toggle_result|window_policy_reapplied|set_taskbar_visible"
```

每次隐藏或恢复预期至少包含：

- `tray_left_toggle_requested`
- `tray_left_toggle_result`

每次恢复预期还包含：

- `window_policy_reapplied`
- 普通模式：任务栏策略为可见。
- 纯桌宠模式：`set_taskbar_visible` 最终为 `visible=false`。

全部通过

## 4. 真实登录开机自启

该项会注销或重启电脑，开始前先保存其他应用中的工作。

### 4.1 开启开机自启

1. 确认当前运行的是独立解压目录中的 `$Exe`。
2. 打开 Settings -> 通用。
3. 开启“开机自启”。
4. 点击“保存”。
5. 确认出现保存成功反馈。
6. PowerShell 检查注册表：

```powershell
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "LetsMakeMoney"
```

预期：注册表值存在，并且路径指向当前 `$Exe`，不是项目 `build` 目录或旧版本。
通过

### 4.2 注销或重启后检查

1. 记录当前 `$Exe` 路径。
2. 注销并重新登录，或重启电脑。
3. 登录后等待 10 至 20 秒。
4. 确认 LetsMakeMoney 自动启动。
5. 检查只有一个实例：

```powershell
Get-Process LetsMakeMoney -ErrorAction SilentlyContinue |
    Select-Object Id, Path, StartTime
```

预期：仅一条进程记录，`Path` 与 `$Exe` 相同。
未看到应用启动
![[Pasted image 20260710223327.png]]

### 4.3 关闭开机自启

1. 打开 Settings -> 通用。
2. 关闭“开机自启”。
3. 点击“保存”。
4. 执行：

```powershell
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "LetsMakeMoney"
```

预期：系统提示找不到该注册表值。
![[Pasted image 20260710223424.png]]

5. 再次注销/登录或重启。
6. 等待 10 至 20 秒，确认 LetsMakeMoney 不会自动启动。

开机自启结果：`[ ] 通过  [√] 失败（第一轮）`
开启后注册表路径：
登录后实例数量：
关闭后是否仍自动启动：
截图/注册表证据：

### 4.4 修复候选包定向复测

第一轮失败原因已经修复：纯桌宠恢复现在显式同步 Windows Shell 任务栏标签；开机自启写入前会把 Godot 路径规范为 Windows 反斜杠路径，并拒绝把旧的正斜杠启动项误判为有效。

1. 重新执行第 1.1 节，解压当前 Zip 到一个新的时间戳目录，不要复用第一轮 `.manual-test`。
2. 核对本页顶部的新 Zip/EXE 大小和 SHA256。
3. 只重测第 3.3、3.4 节。预期恢复后桌宠可见，但任务栏没有 LetsMakeMoney 入口。
4. 打开“设置 -> 通用”，开启开机自启并保存。
5. 执行注册表查询，值中必须使用反斜杠，例如 `<WORKSPACE_ROOT>\...\LetsMakeMoney.exe`，不得再出现 `<WORKSPACE_ROOT>/...`。
6. 注销并重新登录或重启，等待 10 至 20 秒；预期当前 `$Exe` 自动启动且只有一个实例。
7. 完成后关闭开机自启，并按第 5 节恢复原配置和原启动项。

修复后纯桌宠结果：`[√] 通过  [ ] 失败`
修复后恢复任务栏入口：`[ ] 有  [√] 无`
修复后开机自启结果：`暂不验证`
修复后注册表值：
修复后实例路径/数量：
截图/备注：Computer Use 完成通知区显隐链路；恢复后桌宠和 Panel 可见，任务栏无 LetsMakeMoney 入口。截图：`.tmp_acceptance/cu-pure-taskbar-20260710/pure-restored-no-taskbar-entry.png`；日志：同目录 `pure-restored-log-evidence.txt`。

## 5. 验收结束后恢复环境

### 5.1 结束测试程序

```powershell
Get-Process LetsMakeMoney -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-Item -LiteralPath "$AppDataRoot\config.json.tmp" -Recurse -Force -ErrorAction SilentlyContinue
```

### 5.2 恢复配置和日志

```powershell
foreach ($Name in @("config.json", "debug.log", "debug.log.1")) {
    $Current = Join-Path $AppDataRoot $Name
    $Backup = Join-Path $BackupRoot $Name
    Remove-Item -LiteralPath $Current -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $Backup) {
        Copy-Item -LiteralPath $Backup -Destination $Current -Force
    }
}
```

### 5.3 恢复原开机启动项

```powershell
$AutoStartBefore = Get-Content "$BackupRoot\autostart-before.txt" -Raw -Encoding UTF8
$AutoStartBefore = $AutoStartBefore.Trim()
if ($AutoStartBefore) {
    New-ItemProperty -Path $RunKey -Name "LetsMakeMoney" -PropertyType String -Value $AutoStartBefore -Force | Out-Null
} else {
    Remove-ItemProperty -Path $RunKey -Name "LetsMakeMoney" -ErrorAction SilentlyContinue
}
```

最后执行：

```powershell
Get-Process LetsMakeMoney -ErrorAction SilentlyContinue
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "LetsMakeMoney"
```

确认没有遗留测试进程，启动项与验收前一致。

## 6. 补证提交格式

```text
验收时间：
测试目录：
实际 EXE 路径：
EXE SHA256：

Settings 保存失败可见反馈：通过
失败反馈文字：保存失败:temp_open_failed error=Can't open file
输入是否保留：是 / 否
有效配置是否未污染：是 / 否

普通模式托盘左键：通过 / 失败
普通模式隐藏后进程是否存在：是 / 否
普通模式恢复后任务栏入口：有 / 无

纯桌宠托盘左键：通过 / 失败
纯桌宠隐藏后进程是否存在：是 / 否
纯桌宠恢复后任务栏入口：有 / 无

开启开机自启后登录：通过 / 失败
登录后实例数量：
关闭开机自启后登录：通过 / 失败

debug.log 关键行：
截图/录屏：
备注：
```
