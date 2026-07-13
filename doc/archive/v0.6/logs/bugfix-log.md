# LetsMakeMoney v0.6 Bugfix Log

## V06-BUG-001 诊断摘要复制出现错误失败反馈

- 发现时间：2026-07-10
- 来源：v0.6 Beta 发布包真实 Acceptance
- 严重度：发布阻塞
- 状态：已修复并完成定向复验
- 影响范围：Settings 通用页“复制诊断摘要”、诊断反馈、`debug.log`

### 复现步骤

1. 从独立解压目录启动 v0.6 Beta 发布包。
2. 打开“设置 -> 通用”。
3. 点击“复制诊断摘要”。
4. 观察界面反馈并读取系统剪贴板和 `debug.log`。

### 实际结果

- 剪贴板已得到 251 字符诊断摘要。
- 摘要符合白名单，未发现用户名、用户目录、薪资、工作时间、窗口坐标或原始日志正文。
- 界面连续两次显示“剪贴板写入后校验失败。”。
- 日志记录：`diagnostics_copy_failed: reason=剪贴板写入后校验失败。`

### 期望结果

- 写入与读回内容等价时显示复制成功。
- 真正写入失败或内容不一致时才显示失败，并保留可读原因。
- 成功/失败反馈按 PRD 约定自动隐藏。

### 根因

摘要使用 LF（`\n`）拼接，Windows 文本剪贴板可能以 CRLF（`\r\n`）返回；旧实现仅执行一次同步读回并做原始字符串完全相等比较，因此会把仅换行格式不同或剪贴板尚未完成传播的真实成功判为失败。Godot 的 `DisplayServer.clipboard_set()` 不返回可用于判定成功的布尔值，旧逻辑实际上把“读回未确认”错误等同为“写入失败”。

### 修复

1. 写入后最多执行 3 次有限读回，每次间隔 40 ms。
2. 比较前统一 CRLF、CR 与 LF，仅忽略平台换行表示差异，不修改摘要内容。
3. 任一次等价读回即返回 `verified=true`。
4. 写入请求已发出但有限读回仍不可确认时返回成功并标记 `verification_uncertain=true`，UI 显示复制成功，日志额外记录不确定原因。
5. 摘要为空或明确处于 headless/不支持剪贴板环境时仍返回可读失败，不删除失败处理。
6. 脱敏白名单、摘要字段、打开数据目录和磁盘产物行为均未修改。

### 测试与验证

- 定向契约覆盖：延迟后读回成功、CRLF/LF 等价、有限读回不可确认、明确写入失败。
- `scripts/verify_v06.ps1`：通过。
- `scripts/verify_v06_config.ps1`：通过。
- `scripts/verify_v05.ps1`、`verify_v04.ps1`、`verify_m4.ps1`、`verify_m5.ps1`：通过。
- `scripts/verify_v06_package.ps1`：通过。
- Computer Use 从 `.tmp_acceptance/v0.6-bugfix-final4/extracted/LetsMakeMoney.exe` 实际点击“复制诊断摘要”：UI 显示“诊断摘要已复制。”。
- 剪贴板摘要长度 251 字符；用户名、用户目录、月薪、工作时间、窗口坐标和原始日志检查均为未包含。
- 日志：`diagnostics_copy_success: verification=verified`。
- 截图：`.tmp_acceptance/v0.6-bugfix-final4/evidence/diagnostics-copy-success-2.png`。

### Settings 保存失败反馈调查

保存失败仍能保留输入、保护旧配置并记录完整回滚日志。曾尝试延长反馈时长、移入 action row 和底部 overlay，但 Computer Use 仍未捕获可见反馈；这些无效尝试均已撤销，未带入候选包。该证据缺口继续保留在 `manual-verification.md`，本次不扩大为 Settings 结构重构。

### 发布门禁

`V06-BUG-001` 已关闭，不再单独阻塞发布。后续人工补证已确认 Settings 保存失败反馈通过；`V06-BUG-002` 也已修复并完成 Computer Use 定向复测。当前仅剩 `V06-BUG-003` 的真实登录开机自启复测。

## V06-BUG-002 纯桌宠从托盘恢复后任务栏入口残留

- 发现时间：2026-07-10
- 来源：v0.6 Beta 第一轮人工补证
- 严重度：发布阻塞
- 状态：已修复并完成 Computer Use 定向复测

### 证据与根因

第一轮人工补证中，普通模式托盘隐藏/恢复通过；纯桌宠模式恢复后桌宠可见，但 Windows 任务栏仍出现 LetsMakeMoney 入口。同期日志记录 `set_taskbar_visible ... visible=false` 和 `ok=true`，说明原生调用完成，却不能证明 Windows Shell 已移除任务栏标签。

原生实现此前只切换 `WS_EX_TOOLWINDOW/WS_EX_APPWINDOW` 并调用 `SetWindowPos(... SWP_FRAMECHANGED)`。窗口从隐藏状态恢复后，Explorer 已经重新登记任务栏标签，仅修改扩展样式可能不会立即刷新 Shell 的任务栏注册状态。

### 修复

1. 在 Windows 原生层使用 `ITaskbarList::DeleteTab/AddTab` 显式同步任务栏标签。
2. Shell COM 接口不可用时，使用一次隐藏/恢复窗口作为刷新兜底。
3. 保留既有扩展样式切换、纯桌宠策略和托盘交互逻辑，不改变用户操作方式。
4. 原生构建增加 `ole32`、`uuid` 系统库。

### 验证

- 原生 DLL 重新编译通过。
- 最终候选 EXE 的 normal/pure 托盘专项各 10 轮通过。
- `scripts/verify_v06.gd` 增加 Shell 任务栏同步静态契约。
- Computer Use 完成通知区显隐链路；恢复后桌宠和 Panel 可见，Computer Use 顶层窗口枚举无 LetsMakeMoney，完整桌面截图的任务栏也无 LetsMakeMoney 入口。
- 日志存在 `tray_left_toggle_result: visible_after=true pure_pet_mode=true`、`set_taskbar_visible ... visible=false` 和两阶段 `window_policy_reapplied`。
- 证据：`.tmp_acceptance/cu-pure-taskbar-20260710/pure-restored-no-taskbar-entry.png`、同目录 `pure-restored-log-evidence.txt`。

## V06-BUG-003 开机自启注册成功但真实登录未启动

- 发现时间：2026-07-10
- 来源：v0.6 Beta 第一轮人工补证
- 严重度：发布阻塞
- 状态：已修复；真实登录复测暂不验证

### 证据与根因

第一轮截图显示 Run 启动项存在，但值为 `<WORKSPACE_ROOT>/.../LetsMakeMoney.exe`；注销或重启后没有 LetsMakeMoney 进程。`OS.get_executable_path()` 返回的 Godot 路径使用正斜杠，旧实现直接把该字符串写入 Windows Run 启动项。

此外，旧 `is_auto_start_enabled()` 会把注册表输出和预期路径都替换为反斜杠后执行包含判断，导致旧的正斜杠启动项仍被判定为有效，Settings 不会主动重写它。

### 修复

1. 写入 Run 启动项前将可执行文件路径规范为 Windows 反斜杠形式，并生成带引号命令。
2. 读取注册表的真实 `REG_SZ` 命令并进行严格比较；仅允许当前反斜杠路径或其带引号形式算作有效。
3. 旧路径、旧分隔符和其他命令均判定为需刷新，避免“已启用”假阳性。
4. 写入后立即二次读取确认；失败时返回失败，不伪装成功。
5. 增加 `auto_start_apply_success/auto_start_apply_failed` 语义日志。

### 验证

- `scripts/verify_v06.ps1` 通过，包含路径规范化、命令引号和严格读取契约。
- `scripts/verify_v06_config.ps1` 通过，配置事务和失败保旧无回归。
- 真实注销/登录或重启尚未复测，当前按用户决定标记为暂不验证；不得将该能力写为已通过。

### 最终 Acceptance 口径

- 开机自启仍为“暂不验证”，历史失败和未完成复测记录全部保留。
- 自动验证仅证明注册表路径格式、启停事务和补偿契约，不证明真实登录启动成功。
- 该能力默认关闭，不影响手动启动、桌宠主流程、配置安全和托盘找回，因此最终 Acceptance 将其归为 v0.6 Beta 已知限制和发布后观察项，不作为本次发布阻塞。
- 若后续恢复该项验收，仍按 `doc/releases/v0.6/manual-verification.md` 第 4 节执行；通过前不得改写为已验证。

## 最终 Acceptance 结果

- 验收时间：2026-07-11
- 验收对象：`.tmp_acceptance/v0.6-final-20260710-235245/extracted/LetsMakeMoney.exe`
- 结果：通过，可进入发布收口。
- 新发现发布缺陷：无。
- 证据目录：`.tmp_acceptance/v0.6-final-20260710-235245/evidence/`

## 本轮新候选包

- Zip：`releases/v0.6/LetsMakeMoney-v0.6-beta-windows-x86_64.zip`
- Zip 大小：`42,778,715` 字节
- Zip SHA256：`CECD3C3ABACFCB5EF594584E2AEB0E25C1824BAE97AB84B224073E7444E72615`
- EXE：`releases/v0.6/LetsMakeMoney-v0.6-beta-windows-x86_64/LetsMakeMoney.exe`
- EXE 大小：`113,240,688` 字节
- EXE SHA256：`749F18E35E757A250EDA8D3DE5B712BD554861082E33D607E1D07835AA943E3B`
