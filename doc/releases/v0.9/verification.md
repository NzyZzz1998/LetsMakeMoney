# LetsMakeMoney Windows v0.9 Beta 验证

## 状态

| 项目 | 当前口径 |
|---|---|
| 阶段 | v0.9 Beta 最终验收与发布收口完成 |
| 当前门禁 | `V09-BUG-006/007/008` 已关闭；本轮未发现新的发布阻塞 |
| 稳定回退 | Windows v0.8 Beta |
| 发布判断 | **已发布**；PR #6、`main`、`v0.9-beta` 和 GitHub Pre-release 已完成 |
| 独立验收 | **通过**；待人工补证和暂不验证项按边界保留，不冒充通过 |
| 最终发布附件 | Zip SHA256 `B10FDE2027D4ABC71C41F0F7AC7BDCE3D93AEB8AFAF4058BA1A592B6A75CC1EC`；最终文档快照重打包，二进制身份未变化 |

本地证据与可再生解压副本的保留边界见 [evidence-retention.md](evidence-retention.md)。2026-07-23 仅清理了可由锁定 Zip 重建的运行副本，截图、日志、配置快照和验收结论均保留。

## 2026-07-23 远端发布收口

- 发布提交：`94f46229cd72a6648fa6d027130efd07354215e2`
- 发布 tag：`v0.9-beta`，annotated tag 已推送并指向上述提交
- Pull Request：[#6](https://github.com/NzyZzz1998/LetsMakeMoney/pull/6)
- GitHub Pre-release：<https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.9-beta>
- 必需检查：`Windows docs and compliance` 通过；`Windows native and Godot verification` 通过
- Release 附件：便携 Zip 与 `SHA256SUMS.txt`
- 未上传：未签名安装器
- GitHub 记录的 Zip digest：`sha256:b10fde2027d4abc71c41f0f7ac7bdce3d93aeb8afaf4058ba1a592b6a75cc1ec`

发布动作没有改变锁定二进制或验收边界。待人工补证和暂不验证项继续保留，不因发布完成而改写为通过。

## 2026-07-23 最终文档快照重打包与定向复验

### 当前发布候选

- Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`
- Zip 大小：`51,789,772` 字节
- Zip SHA256：`B10FDE2027D4ABC71C41F0F7AC7BDCE3D93AEB8AFAF4058BA1A592B6A75CC1EC`
- EXE 大小：`122,252,488` 字节
- EXE SHA256：`E56AB6F045BF6F9E241AB42719BDF00B925754EC3FF0C9083586EB04DECEFC13`
- Native DLL 大小：`1,577,984` 字节
- Native DLL SHA256：`91B1BD23CF48A422AACB66A23B8B09CDE90772039D8D2622E1C703EF03AEB2D4`
- 定向复验证据：`.tmp_acceptance/v0.9-doc-repack-20260723-205908/evidence/`
- 重打包前候选备份：`.tmp_acceptance/v0.9-pre-repack-20260723-205612/`

### 复验结果

| 项目 | 结论 | 证据与边界 |
|---|---|---|
| 重打包范围 | 通过 | 使用 `package_v09.ps1 -SkipExport`，只同步最终 README、release notes、许可及包清单，没有重新导出程序 |
| 二进制身份 | 通过 | EXE 与 Native DLL 的大小、SHA256 均与最终真实 GUI 验收对象完全一致，因此既有 GUI 验收结论继续适用 |
| 包结构与许可 | 通过 | `verify_v09_package.ps1` 检查版本、manifest、checksums、LICENSES 和运行时载荷通过 |
| 新解压冒烟 | 通过 | 从 `.tmp_release/verify_v09_package/` 启动，日志记录 `app_started: version=0.9-beta`，Classic 与多多均为 `shadow_loaded` |
| 包内文档口径 | 通过 | README 与 release notes 已同步“最终验收通过 / 可进入发布收口”，不再包含“部分通过、等待最终验收”的旧快照口径 |
| 用户环境影响 | 通过 | 冒烟使用隔离 APPDATA，不读写用户 `%APPDATA%\LetsMakeMoney` |

### 结论

重打包没有改变可执行程序或 Native DLL，只改变 Zip 文档快照和由此派生的 manifest/checksums。当前发布候选可沿用 2026-07-23 最终真实 GUI 验收结论，继续进入发布收口；旧 Zip SHA256 `DFADCFF7F1DB1F461D4241EFC9F86E286E7C533211785BA7E5C74072FE5144DF` 仅作为最终 GUI 验收历史身份保留。

## 2026-07-23 最终候选验收签核

### 验收对象

- 分支：`agent/v0.9-acceptance-continue`
- 构建基线 HEAD：`a970b0c8c0436976f62c3f84dcdb995325dc5d73`
- Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`
- Zip 大小：`51,789,601` 字节
- Zip SHA256：`DFADCFF7F1DB1F461D4241EFC9F86E286E7C533211785BA7E5C74072FE5144DF`
- EXE 大小：`122,252,488` 字节
- EXE SHA256：`E56AB6F045BF6F9E241AB42719BDF00B925754EC3FF0C9083586EB04DECEFC13`
- Native DLL 大小：`1,577,984` 字节
- Native DLL SHA256：`91B1BD23CF48A422AACB66A23B8B09CDE90772039D8D2622E1C703EF03AEB2D4`
- 独立解压目录：`.tmp_acceptance/v0.9-final-20260723-192018/app/`
- 本轮证据目录：`.tmp_acceptance/v0.9-final-20260723-192018/evidence/`
- 已关闭缺陷定向证据：`.tmp_acceptance/v0.9-bugfix-20260723-184617/evidence/`

### 分项结果

| 验收项目 | 结论 | 真实证据与边界 |
|---|---|---|
| 候选身份与独立启动 | 通过 | 分支、HEAD、Zip、EXE、DLL、大小和 SHA256 均与锁定对象一致；仅从全新解压目录启动 |
| Panel 折叠与展开 | 通过 | 100% DPI 下完成折叠、展开和主窗口回到稳定状态，截图 `01`、`02` |
| 今日详情 | 通过 | 独立窗口正常打开，内容无裁切，截图 `04` |
| Settings 五页 | 通过 | 工资、作息、桌宠、显示、通用和诊断入口均可访问，截图 `05` 至 `11` |
| Settings 保存三状态 | 通过 | 沿用同一候选身份的真实 GUI 定向证据：保存成功、无变化、保存失败均正确；失败时输入保留且旧配置不污染 |
| Wizard 四步、返回、取消和关闭 | 通过 | 四步均实际打开，返回、取消及右上角关闭回到主界面；日志记录步骤切换与取消，截图 `12` 至 `15`、`20` |
| 右键菜单与二级菜单 | 通过 | 主菜单、窗口模式和宠物选择二级菜单均可访问，截图 `03`、`21`、`22` |
| Classic 与多多切换及单击 | 通过 | 两套宠物均完成运行时切换；单击动作肉眼可辨，日志形成请求、开始、结束和基础状态恢复闭环，截图 `16` 至 `18`、`23`、`24` |
| Popup/Modal 点击穿透 | 通过 | Settings、Wizard 和 popup 打开/关闭期间存在成对的暂停与恢复语义事件 |
| 普通/纯桌宠与任务栏策略 | 部分通过 | 普通模式日志确认任务栏策略为可见；普通/纯桌宠 native 消息历史自动门禁各 10 轮通过；真实通知区鼠标与纯桌宠恢复后的可见任务栏结果仍待人工补证 |
| 500ms 长按、方向拖拽和释放收势 | 待人工补证 | Computer Use 可完成拖动并记录位置，但不能可靠控制 500ms 按住阈值，不能据此签署跑动与收势通过 |
| Classic/多多完整三状态观感 | 部分通过 | 本轮确认两套宠物可见、可切换且当前状态单击动作完整；working、awake_rest、sleeping 的全组合连续人工观感仍作为已知体验债保留 |
| 配置、窗口、动画和穿透日志 | 通过 | `debug-final-acceptance.log` 与 `semantic-events.txt` 覆盖配置保存、Wizard、宠物切换、动作请求/完成、窗口策略和穿透暂停/恢复 |
| v0.8 核心回归 | 通过 | 当前 GUI 路径未发现 Panel、Settings、Wizard、菜单、托盘策略、点击穿透或配置安全回退；既有 v0.8 自动回归继续通过 |
| 用户环境恢复 | 通过 | 进程已停止；恢复后 `config.json` 和 `debug.log` SHA256 与验收前备份完全一致 |

### 待人工补证

1. 真实按住桌宠至少 500ms，分别向左、向右拖动并释放，确认进入跑动准备、方向正确、释放收势后恢复基础状态且不补发单击。
2. 使用 Windows 通知区真实鼠标左键分别验证普通模式和纯桌宠模式的隐藏/恢复；普通模式恢复后任务栏入口存在，纯桌宠模式恢复后任务栏入口不存在。
3. 分别让 Classic 与多多进入 working、awake_rest、sleeping，连续观察基础循环并在每种状态执行单击，确认动作可辨、完整结束并恢复最新基础状态。

### 暂不验证

1. 真实 Windows 125%/150% DPI 全界面截图。
2. 受控损坏宠物包的真实桌面回退观感；自动包合同与回退门禁已通过。
3. 连续两小时真实 GUI 稳定运行；60 秒隔离冒烟和本轮交互期间未见异常。

### 签核结论

**通过，可进入发布收口。** `V09-BUG-006/007/008` 保持关闭，本轮未发现新的发布阻塞。上述待人工补证、暂不验证项和 Windows 前端质感体验债必须继续披露，但按本轮已确认的验收规则不阻塞 v0.9 Beta 发布收口。

## 2026-07-23 发布阻塞修复后定向复验

### 验收对象

- 源码分支：`agent/v0.9-acceptance-continue`
- 构建基线 HEAD：`a970b0c8c0436976f62c3f84dcdb995325dc5d73`
- Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`
- Zip 大小：`51,789,601` 字节
- Zip SHA256：`DFADCFF7F1DB1F461D4241EFC9F86E286E7C533211785BA7E5C74072FE5144DF`
- 独立解压 EXE 大小：`122,252,488` 字节
- 独立解压 EXE SHA256：`E56AB6F045BF6F9E241AB42719BDF00B925754EC3FF0C9083586EB04DECEFC13`
- Native DLL 大小：`1,577,984` 字节
- Native DLL SHA256：`91B1BD23CF48A422AACB66A23B8B09CDE90772039D8D2622E1C703EF03AEB2D4`
- 独立解压目录：`.tmp_acceptance/v0.9-bugfix-20260723-184617/app/`
- 证据目录：`.tmp_acceptance/v0.9-bugfix-20260723-184617/evidence/`

### 自动验证

| 项目 | 结论 | 证据 |
|---|---|---|
| Settings 失败反馈持续性 | 通过 | 新增测试验证失败信息 3 秒后仍可见 |
| 关于图标布局合同 | 通过 | 新增测试验证 `EXPAND_IGNORE_SIZE` 与 `96×96` 逻辑尺寸 |
| v0.9 全量门禁 | 通过 | `verify_v09.ps1 -SkipExport`；同时通过 v0.8、v0.7、v0.6、M4、M5 回归 |
| 打包 | 通过 | `package_v09.ps1` |
| 包体验证 | 通过 | `verify_v09_package.ps1`；Classic 与多多运行时包校验通过 |

### 真实 GUI 定向复验

| 项目 | 结论 | 证据与边界 |
|---|---|---|
| Settings 保存失败 | 通过 | 受控占用 `config.json.tmp`，等待 3.2 秒后仍显示“保存失败”；输入 `16204` 保留，磁盘仍为 `15204`，配置 SHA256 前后均为 `773B3FA44BCC0D0B2C0142F2B759D9FE5050521BD023C8FC6A71EA0A396BA751` |
| Settings 保存成功 | 通过 | 实际将月薪保存为 `15206`；配置持久化并记录 `settings_save_success: changed_keys=["monthly_salary"]` |
| Settings 真正无变化保存 | 通过 | 第二次无修改保存显示“没有需要保存的更改。”，日志记录 `settings_save_no_change` |
| 关于窗口 | 通过 | 从右键菜单实际打开；图标、版本、说明、配置路径和关闭入口完整可见，无裁切 |
| 用户环境恢复 | 通过 | `config.json` 与 `debug.log` 恢复后 SHA256 分别与本轮备份一致；临时失败目录已删除 |

### 结论

`V09-BUG-006`、`V09-BUG-007` 和重新打包时发现的 `V09-BUG-008` 均已关闭。当前没有已确认代码发布阻塞，可以重新进入最终 `/acceptance`。真实 125%/150% DPI、Windows 通知区鼠标与任务栏入口、500ms 长按跑动、受控损坏包桌面观感和两小时 GUI 稳定运行仍按既有边界保留，不在本次定向复验中冒充通过。

## 2026-07-23 续测 Computer Use 验收

### 验收对象

- Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`
- Zip 大小：`51,707,737` 字节
- Zip SHA256：`65A04A1BAFF6681FF335DD2966A528E6BD6517A81232BC107EFAF5AF42C9F685`
- 独立解压 EXE SHA256：`B867D515772B4C1D220C98FD7C75B253C42EF689504CE7BB731E80B529A9532D`
- Native DLL SHA256：`E3E2030003A7DA725446A3873C3EC2E19D9442B98A67F24A771E76BD0BAD5089`
- 独立解压目录：`.tmp_acceptance/v0.9-continue-20260723-174124/extracted/`
- 证据目录：`.tmp_acceptance/v0.9-continue-20260723-174124/evidence/`

### 分项结果

| 项目 | 结论 | 证据与边界 |
|---|---|---|
| 候选身份与独立启动 | 通过 | Zip、EXE、Native DLL 哈希与锁定值一致；只运行独立解压目录中的 EXE |
| 主窗口、Panel、右键菜单与今日详情 | 通过 | `01-launch-normal-mode.png` 至 `03-today-details.png`；窗口可打开，主要内容可读 |
| Settings 五页 | 通过 | `04-settings-salary.png` 至 `08-settings-general.png`；100% DPI 下无可见裁切或重叠 |
| Settings 保存成功 | 通过 | 月薪由 `15204` 改为 `15205` 后持久化；`config-after-success.json` 与 `settings_save_success` 日志闭环 |
| Settings 无变化保存 | 待复验 | 本次点击“保存”时内部草稿仍修正了 `work_hours_per_day`，日志记录为成功保存，不能作为真正无变化路径证据 |
| Settings 保存失败 | 未通过 | 受控占用 `config.json.tmp` 后，配置仍为旧值且输入保留，事务回滚成功；但界面未显示可读失败，底部仍错误显示“没有未保存的更改”。证据：`22-settings-save-failure-feedback.png`、`23-settings-save-failure-immediate.png` 及 `settings_save_failed` 日志 |
| Wizard 四步、返回与取消 | 通过 | `11-wizard-step-1.png` 至 `15-wizard-cancel-restored-main.png`；日志包含打开、步骤切换、状态恢复、取消、关闭 |
| 多多与 Classic 状态感知单击 | 通过 | `16-pet-single-click-action.png`、`21-classic-pro-single-click.png`；两套宠物均形成 requested/started/finished 日志 |
| 关于窗口 | 未通过 | 内容受主窗口尺寸约束并在底部被裁切，版本与许可信息不能完整访问。证据：`18-about-window.png` |
| 诊断摘要与数据目录 | 通过 | `24-settings-diagnostics-section.png` 至 `26-app-data-directory.png`；剪贴板摘要已脱敏，日志记录复制与目录打开成功 |
| Popup/Modal 点击穿透保护 | 通过 | `semantic-events.txt` 中多组 suspend/resume 成对出现，Settings 最终关闭后恢复 |
| 长按跑动与拖拽 | 待人工补证 | Computer Use 固定拖动不能可靠满足 500ms 长按阈值；本次拖动尝试只证明 Panel 可展开，不作为拖拽通过证据 |
| 通知区真实鼠标、任务栏、125%/150% DPI、两小时运行 | 暂不验证 | 当前环境或本轮范围不足，保留既有人工边界，不写为通过 |

### 已确认阻塞

1. `V09-BUG-006`：保存失败时没有可见错误反馈，且状态栏错误宣称“没有未保存的更改”。配置安全写入与回滚本身正常。
2. `V09-BUG-007`：关于窗口被主窗口裁切，关键说明无法完整查看。

本轮结论为 **未通过**。在两个阻塞修复、重新生成候选身份并完成定向复验之前，不得进入发布收口。

### 环境恢复

- 候选进程已停止，临时 `config.json.tmp` 已清理。
- 原 `config.json` 已恢复，SHA256：`775022CDCF91E84BF99B4BC3218111D3625661B59CF285475CEA6D5E81968051`。
- 原 `debug.log` 已恢复，SHA256：`6E277E3A2B3ED7E47BA1CB86B51978CB0B71A784F51948A92F4DA3A1A53BB19F`。
- 续测日志、最终测试配置、语义事件和截图均封存在上述证据目录。

## 2026-07-22 修复后候选深度 Computer Use 验收

### 验收对象

- Zip SHA256：`65A04A1BAFF6681FF335DD2966A528E6BD6517A81232BC107EFAF5AF42C9F685`
- EXE SHA256：`B867D515772B4C1D220C98FD7C75B253C42EF689504CE7BB731E80B529A9532D`
- Native DLL SHA256：`E3E2030003A7DA725446A3873C3EC2E19D9442B98A67F24A771E76BD0BAD5089`
- 独立解压目录：`.tmp_acceptance/v0.9-bugfix-20260722-205525/extracted/`

### 结果

| 项目 | 结论 | 证据 |
|---|---|---|
| 独立启动与普通模式任务栏策略 | 通过 | `debug-gui.log` 记录 native、tray、taskbar 和 passthrough 初始化成功 |
| Settings 五页 | 通过 | Computer Use 逐页打开；无裁切、重叠或粗糙默认 popup |
| Wizard 四步、上一步与取消 | 通过 | Computer Use 全链路；日志记录步骤切换、状态恢复、取消和穿透恢复 |
| 多多 `awake_rest` 单击 | 通过 | 可见抬爪动作；日志记录 `rest_ack` 请求、开始、结束并恢复 |
| Classic `awake_rest` 单击 | 通过 | Computer Use 实际点击；日志记录请求、开始及 `animation_finished`，约 1 秒后释放动作 |
| 今日详情 | 通过 | Computer Use 显示 `18:00 / 19:30 / 20:00` 与 `19:30-19:35`，与测试配置一致 |
| 长按拖动 | 待人工补证 | Computer Use 的固定拖动动作无法稳定满足产品 500ms 长按阈值，不冒充通过 |
| DPI、托盘真实鼠标、回退、两小时稳定运行 | 待验证 | 发现发布阻塞后停止扩展验收 |

验收结束后已停止候选进程，并恢复原 `config.json` 与 `debug.log`。恢复后的配置 SHA256 为 `775022CDCF91E84BF99B4BC3218111D3625661B59CF285475CEA6D5E81968051`，与备份完全一致。

### 2026-07-22 独立验收续测

本轮继续使用同一 Zip、EXE 和 Native DLL 身份，从独立解压目录启动候选包。Windows 系统 DPI 实测为 `96`，因此本轮 GUI 证据只代表真实 `100% DPI`，不能替代 `125%/150% DPI`。

| 项目 | 结论 | 证据与边界 |
|---|---|---|
| 候选身份复核 | 通过 | Zip、EXE、Native DLL SHA256 再次核对，与锁定值一致 |
| Settings 五页 | 通过 | Computer Use 逐页打开工资、作息、桌宠、显示、通用；当前 100% DPI 下无裁切、重叠和默认控件回退 |
| 今日详情 | 通过 | 独立窗口实际打开，金额、进度和 `08:00 / 12:00-13:00 / 18:00` 今日安排与本轮隔离配置一致 |
| Wizard 四步与取消 | 通过 | 实际完成 1→2→3→4 步并取消；日志形成 `wizard_step_changed`、`wizard_state_restored`、`wizard_cancelled`、`wizard_closed` 闭环 |
| 右键菜单 | 通过 | 实际打开并确认隐藏到托盘、今日详情、设置、重新运行向导、窗口模式、选择宠物、关于、退出入口 |
| Popup/Modal 点击穿透保护 | 通过 | 日志记录成对的 `passthrough_suspended` 与 `passthrough_resumed`，Wizard 关闭后重新应用窗口策略 |
| 窗口拖动 | 部分通过 | Computer Use 已实际移动窗口并记录 `drag saved`；工具无法稳定控制 500ms 按住阈值，长按进入跑步及释放收势仍待人工补证 |
| 托盘与任务栏策略 | 部分通过 | `verify_v06_tray.ps1` 普通/纯桌宠各 10 轮通过；Windows 通知区真实鼠标左键和可见任务栏入口仍待人工补证 |
| 宠物包损坏与回退 | 部分通过 | `test_v09_pet_package.ps1` 与 `test_v09_pet_integration.ps1` 覆盖损坏哈希拒绝、选择和回退；真实候选包受控损坏后的桌面观感仍待补证 |
| v0.8 行为基线 | 通过 | `test_v09_behavior_baseline.ps1` 通过；窗口、托盘和配置基线未发现新回归 |
| 短时稳定运行 | 通过 | 候选包独立解压后以绝对隔离 APPDATA 连续运行 60 秒，`verify_v04_stability.ps1` 通过并正常退出 |
| 两小时稳定运行 | 待验证 | 60 秒冒烟只证明进程健康，不能替代 PRD 要求的两小时真实 GUI 观察 |

本轮日志位于 `.tmp_acceptance/v0.9-continue-20260722/appdata/LetsMakeMoney/debug.log`；短时稳定证据位于 `.tmp_acceptance/v0.9-stability-absolute/`。交互截图目录中的单击逐帧 PNG 仅用于动作证据，不包含 Settings/Wizard 窗口截图。

补充发现：旧脚本 `test_v08_pet_fallback.ps1` 仍硬编码 v0.8 默认宠物和旧回退顺序，因 v0.9 已批准的 Classic 默认候选而失败。当前 v0.9 包合同与集成测试均通过，因此该项记录为验证脚本债，不作为产品运行时缺陷；后续应更新或归档该旧脚本。Debug 模式还会每 0.5 秒记录指针观察日志，正式模式未见同等刷屏，本版作为非阻塞观察项保留。

本轮总判定仍为 **部分通过**：没有发现新的已确认代码阻塞，但真实 `125%/150% DPI`、通知区鼠标、500ms 长按跑动、两套宠物完整观感、桌面损坏回退和两小时运行证据尚未闭合，暂不可进入发布收口。

### 2026-07-22 Computer Use 收口补证与所有者决策

| 项目 | 结论 | 证据与边界 |
|---|---|---|
| 多多 sleeping 状态感知单击 | 通过 | Computer Use 实际单击；日志完整记录 `pet.input.classified type=single`、`sleep_ack` 请求/开始/完成，并恢复 `sleeping` |
| 单击逐帧证据 | 通过 | `.tmp_acceptance/v0.9-cu-closeout-20260722/appdata/LetsMakeMoney/interaction-screenshots/` 保存 50ms、450ms、900ms 三张运行时截图 |
| 窗口拖动 | 通过 | Computer Use 实际拖动桌宠窗口，界面显示并记录 `Debug: drag saved` |
| 500ms 长按跑动 | 暂不验证 | Computer Use API 只能执行固定拖动，不能可靠控制按住时长；本轮不冒充通过 |
| Windows 通知区真实左键 | 暂不验证 | 通知区/Explorer 不在 Computer Use 可定位窗口列表中；native 消息普通/纯桌宠各 10 轮自动验证已通过 |
| 真实 125%/150% DPI | 暂不验证 | 当前系统真实 DPI 为 100%；确定性缩放渲染已通过，但不替代真实系统缩放 |
| 受控损坏包桌面观感 | 暂不验证 | 包合同与集成回退自动验证通过，未继续破坏真实候选资源取桌面证据 |
| 两小时 GUI 稳定运行 | 暂不验证 | 60 秒隔离 APPDATA 冒烟通过；本轮不将其写成两小时通过 |

项目所有者明确表示当前前端体验仍不满意，但决定停止继续修改并收口 v0.9。本次验收因此维持 **部分通过**，候选冻结归档；未验证项和视觉质感问题作为后续版本输入，不再阻塞 v0.9 的开发结束。该决定不等同于“完整验收通过”，也不授权将候选描述为正式稳定版。

### 2026-07-22 BUG-004/005 定向复验

- 全量自动回归：`verify_v09.ps1 -SkipExport` 通过，包含 v0.6/v0.7/v0.8 与 M4 门禁。
- 包验证：`verify_v09_package.ps1` 通过。
- Classic 日志：`pet.animation.requested`、`started` 后于下一秒记录 `finished reason=animation_finished`，未出现 timeout。
- Settings 作息页：5 分钟午休显示 `0.08 小时`，不再量化为 `0.0`。
- 证据：`.tmp_acceptance/v0.9-bugfix-20260722-205525/evidence/`。

### 2026-07-21 动画视觉方向修订

- PetManager S4/S5 已证明 custom profile、图集、逐帧时长、分层证据与 QA 门禁可用。
- 项目所有者实际审查认为电脑/键盘叙事生硬，要求全部移除，并以小猫玩耍作为主要视觉表达。
- 当前带电脑的 `working_loop`、`working_ack`、`lunch_relief`、`lunch_return` 仅保留为历史过程证据，结论为“不进入发布候选”。
- 新候选必须遵循 `pet-animation-play-first-revision.md`；在新素材通过人工视觉门禁前，动画观感保持“待验证”，v0.9 保持不可发布。

### 2026-07-21 Windows UI 精修定向复验

本轮使用隔离配置目录启动 Godot Debug 构建，仅验证 Windows UI 精修和窗口生命周期，不改变历史候选包身份，也不替代最终发布验收。

| 范围 | 结论 | 证据 |
|---|---|---|
| Panel 折叠态与展开态 | 100% DPI 通过 | `.tmp_ui_review/screenshots/panel-expanded.png` |
| 今日详情窗口 | 100% DPI 通过 | `.tmp_ui_review/screenshots/today-detail.png`；窗口以独立原生 `Window` 显示，日志记录 `embedded=false`、窗口 ID、位置和尺寸 |
| Settings 工资、显示、通用代表页 | 100% DPI 通过 | `.tmp_ui_review/screenshots/settings-salary.png`、`settings-display.png`、`settings-general.png` |
| OptionButton 下拉菜单 | 100% DPI 通过 | 暖色纸面 popup 正常，无深色系统菜单回退 |
| Wizard 欢迎、收入、作息、宠物与确认链路 | 100% DPI 通过 | `.tmp_ui_review/screenshots/wizard-welcome.png`、`wizard-income.png`、`wizard-pet.png`、`wizard-confirm.png` |
| Wizard 内容滚动与固定操作栏 | 100% DPI 通过 | 作息页滚动到底部后，下班时间和只读有效工时均可见，操作栏不遮挡内容 |
| 125%/150% DPI | 待验证 | 本轮未切换系统缩放，不得写为通过 |
| 全量无导出回归 | 通过 | `scripts/verify_v09.ps1 -SkipExport`；包含 v0.6-v0.8、M4、native 与当前 v0.9 合同 |

今日详情此前的失败原因是子窗口创建后处于不可见原生窗口状态。现改为初始隐藏、创建时临时关闭根窗口子窗口嵌入，并通过 `popup(Rect2i)` 显式展示；关闭后再次打开沿用同一原生窗口生命周期。该修正未改工资、配置、托盘或动画业务逻辑。

## v0.9 历史候选身份

- 分支：`main`
- 开发 HEAD：`c4290823f888a9f6092b125c41d88bb731576772`，工作区包含未提交的 v0.9 实现；独立验收需重新核对。
- Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`
- Zip 大小：`50,197,694` 字节
- Zip SHA256：`72972CB344FEE25549DC930A45809C2DAE82F29F9DA4915CE341B995A956E83F`
- EXE 大小：`120,667,528` 字节
- EXE SHA256：`BA41DBB61BCE35926C0FB0677CA8722A9F9F71BC8A815A59FE0C82EAC0AC8403`
- DLL 大小：`1,606,144` 字节
- DLL SHA256：`E3E2030003A7DA725446A3873C3EC2E19D9442B98A67F24A771E76BD0BAD5089`
- 说明：这是首轮独立验收使用的历史候选，不是 Release 身份，也不包含 2026-07-18 后冻结的新动画输入/事件合同；最终验收不得继续使用该身份。

## 实施起点

- 分支：`main`
- HEAD：`c4290823f888a9f6092b125c41d88bb731576772`
- 描述：`v0.8-beta-1-gc429082-dirty`
- v0.8 发布标签：`v0.8-beta`
- v0.8 发布 Zip 预期路径：`releases/v0.8/LetsMakeMoney-v0.8-beta-windows-x86_64.zip`
- v0.8 发布 Zip 已记录 SHA256：`A2065B82F7674E5A19AC4FD467E7DEA3E8D665E3C148634C3721B7BD90AE098E`
- 当前本地未保留上述 Zip，不能用其他构建冒充该发布产物。

## V09-M0 行为矩阵

### 窗口、托盘与任务栏

| 模式 | 初始显示 | 托盘左键隐藏 | 托盘左键恢复 | 恢复后任务栏入口 | 证据 |
|---|---|---|---|---|---|
| 普通模式 | 桌宠与 Panel 可见 | 窗口隐藏、进程保留 | 窗口恢复 | 显示 | v0.8 验收事实 + M4/M5 门禁 |
| 纯桌宠 | 桌宠与 Panel 可见 | 窗口隐藏、进程保留 | 窗口恢复 | 不显示 | v0.8 验收事实 + window policy 门禁 |
| 原生能力不可用 | 可交互窗口 | 按能力降级 | 可由普通窗口找回 | 显示 | 兼容降级合同 |

### 模态、Popup 与点击穿透

| 入口 | 打开时 | 关闭时 | 证据 |
|---|---|---|---|
| Settings | 暂停点击穿透，主桌宠输入受保护 | 恢复窗口策略与点击穿透 | `passthrough_suspended/resumed` 日志合同 |
| Wizard | 暂停点击穿透，避免输入穿过 | 恢复窗口策略与点击穿透 | `passthrough_suspended/resumed` 日志合同 |
| Godot Popup/菜单 | 暂停点击穿透 | Popup 关闭后刷新命中区 | Overlay 生命周期门禁 |
| 原生托盘菜单 | 由 Windows 原生窗口处理 | 不改变桌宠持久状态 | Windows native 门禁 |

## 自动验证

| 命令 | 作用 | 当前结果 |
|---|---|---|
| `scripts/test_v09_verification_contract.ps1` | v0.9 验证入口完整性 | 通过 |
| `scripts/test_v09_behavior_baseline.ps1` | 动画回退、1.55 秒恢复和输入分类基线 | 通过 |
| `scripts/test_v09_schedule.ps1` | 跨端工资向量、官方日历、跨夜作息与状态边界 | 通过 |
| `scripts/verify_v09.ps1 -SkipExport` | v0.8、M4 与 v0.9 基线 | 通过，5.5 秒 |
| `scripts/verify_v09.ps1` | 含 M5 导出烟测的完整基线 | 通过，15.9 秒 |
| `scripts/test_v09_configuration_experience.ps1` | Wizard/Settings 草稿、推算、保存事务 | 通过 |
| `scripts/test_v09_window_experience.ps1` | Panel、今日详情、窗口回落与模态引用 | 通过 |
| `scripts/test_v09_pet_package.ps1` | 包校验、导入、透明帧、命中区与方向 | 通过；可重复执行 |
| `scripts/test_v09_pet_animation.ps1` | 事件状态机、输入仲裁与动作恢复 | 通过 |
| `scripts/test_v09_pet_integration.ps1` | Classic/多多、选择、回退、尺寸与基线 | 通过 |
| `scripts/verify_v09_package.ps1` | 包内容、许可、哈希和独立解压烟测 | 通过 |
| `scripts/check_asset_licenses.ps1` | 源码素材许可清单；排除生成型构建/发布副本 | 通过 |
| `scripts/test_check_asset_licenses.ps1` | 发布副本不误报、未知源码素材仍阻断 | 通过 |
| `scripts/check_third_party_compliance.ps1` | 第三方依赖、许可和分发边界 | 通过 |
| `scripts/check_docs_status.ps1` | v0.9 候选与历史发布事实一致性 | 通过 |

M5 导出烟测生成 `build/LetsMakeMoney.exe`，大小为 113,026,776 字节；使用隔离的 `.tmp_appdata/verify_v09_m5` 启动、响应和退出均通过。该产物仅为开发烟测，不是候选发布包。

## V09-M1 计薪与日程门禁

- Windows 直接复用 iOS `salary-schema/v1` 的 7 组黄金向量，单双休、大小周、午休、官方调休、手动覆盖、缺失年份和闰年结果误差不超过 0.01 元。
- 2026 官方节假日数据版本为 `cn-2026-gov-20251104`；缺失年份与损坏 JSON 均降级为周规则，并通过 `calendar.dataset.*` 语义日志标明。
- `WorkScheduleResolver` 支持日班与跨夜班次，夜班按开始日归属；工作覆盖夜间睡眠，午休覆盖工作。
- 状态边界 `23:00`、`07:30`、跨午夜午休、调休夜班与系统时间倒退均通过。
- 配置由 v4 安全迁移到 v5，保留旧字段并新增日历版本、今日窗口位置/尺寸及宠物包身份字段。
- v0.8 全量自动回归与 M5 隔离导出烟测通过。

## V09-M4 至 M6 宠物门禁

- Classic 与多多使用同一 v1 宠物包 schema、validator 和 importer，不存在按 `pet_id` 的一次性导入特判。
- 图集逐帧时长、pivot、脚底线、动作偏移、命中策略、许可、来源和文件 SHA256 已进入运行时包合同。
- 修正两套图集清单中指向全透明单元格的声明；所有已声明帧均包含可见像素。
- 全透明纹理的命中区现在为空，不再错误扩张成整张图片可点击。
- Godot 自动生成的 `.import` 元数据不属于宠物包载荷，重复导入后校验保持稳定。
- 动画由请求 token、优先级、完成事件和超时保护驱动，不再依赖固定 1.55 秒恢复。
- single/double/hold/drag 分类、环境动作、指针跟随、逐帧命中区及 union 降级已有自动门禁。
- 运行时将宠物包逻辑尺寸和 pivot 归一化到 v0.8 视觉基线；旧资源保持原场景几何。
- Classic 是新配置默认候选；旧用户选择保持不变；Settings 提供回滚；多多以通用动作映射进入真实观感验收。

## 候选包验证

- `package_v09.ps1 -SkipExport` 生成便携 Zip并包含项目许可、受限素材许可、第三方声明与许可证原文。
- `verify_v09_package.ps1` 校验包名、版本、manifest、内部 checksums、未登记二进制及许可结构。
- 验证器把 Zip 解压到 `.tmp_release/verify_v09_package`，以隔离 APPDATA 启动 EXE 5 秒；进程保持存活并可终止。
- 启动烟测不等于真实桌面工作流通过，不能替代下方人工门禁。
- 素材许可检查只审计源码候选素材；`build/`、`releases/` 和 `.tmp*` 中的生成副本由包内 manifest、checksums 与第三方合规检查负责，避免把同一图标副本误报为新素材。

## 结论约束

- 自动化通过只表示开发门禁通过，不代表真实 Windows GUI 验收通过。
- `V09-ACC-001` 必须使用候选发布包、日志、配置和截图执行。
- 在独立验收完成前，不得写“可发布”。
- 尚未通过或尚未完成：`V09-M2-011/012`、`V09-M3-011`、`V09-M6-003/004`、`V09-M7-009` 至 `013`，以及除身份锁定和验收结论外的 `V09-ACC` 项。

## 2026-07-18 独立验收

### 验收对象

- 分支：`main`
- HEAD：`c4290823f888a9f6092b125c41d88bb731576772`
- Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`
- Zip SHA256：`72972CB344FEE25549DC930A45809C2DAE82F29F9DA4915CE341B995A956E83F`
- 独立解压目录：`.tmp_acceptance/v0.9-20260718-102105/extracted`
- EXE SHA256：`BA41DBB61BCE35926C0FB0677CA8722A9F9F71BC8A815A59FE0C82EAC0AC8403`
- Native DLL SHA256：`E3E2030003A7DA725446A3873C3EC2E19D9442B98A67F24A771E76BD0BAD5089`
- 启动时间：`2026-07-18 10:23:57 +08:00`

### 结论

**未通过。** 候选身份与预期一致，独立解压 EXE 可以启动，Windows 原生窗口、托盘和任务栏策略初始化成功；但发布包运行时拒绝 Classic Pro 与多多两套 v0.9 宠物包，并回退到 `cat_orange_v2`。该问题直接阻断动画、宠物包、回滚和多宠物相关验收，也阻断发布。

### 发布阻塞证据

实际候选运行日志记录：

```text
PetManager.package rejected root=res://assets/pets/packages/letsmakemoney-classic-pro errors=["missing package file: spritesheet.webp", "missing package file: extra-actions.webp", "missing package file: LICENSE.md", "missing package file: SOURCE.md"]
PetManager.package rejected root=res://assets/pets/packages/duoduo-cat errors=["missing package file: spritesheet.webp", "missing package file: extra-actions.webp", "missing package file: LICENSE.md", "missing package file: SOURCE.md"]
PetManager._ready: scanned pets=3
PetManager._ready: current_pet=cat_orange_v2
```

现有 `verify_v09_package.ps1` 复跑返回退出码 `0` 并打印 `Package verification passed: 0.9-beta`，但其隔离运行日志同时出现上述两条 `package rejected`。因此当前包验证只证明 EXE 存活，不能证明 v0.9 宠物包在导出产物中可消费。

### 分项结果

| 验收模块 | 结论 | 证据 | 备注 |
|---|---|---|---|
| 候选身份 | 通过 | `identity.json`、文件哈希 | Zip、EXE、DLL 与锁定身份一致 |
| 独立解压启动 | 通过 | `candidate-debug.log` | 仅证明进程和基础窗口链路可启动 |
| Classic Pro 与多多加载 | 未通过 | `runtime-evidence.txt` | 两套包均被拒绝，实际只加载 3 个旧宠物 |
| 包验证门禁 | 未通过 | `package-verifier-runtime.txt` | 出现运行时拒绝仍返回成功 |
| 工资、Wizard、Settings、DPI、输入、穿透、托盘、回滚、稳定运行 | 待验证 | 本轮未继续 | 核心候选身份已失真，继续验收不能代表 v0.9 目标 |
| v0.8 回归 | 部分通过 | 启动与原生初始化日志、既有自动门禁 | 独立候选的完整桌面回归未执行 |

### 证据位置与环境恢复

- 证据目录：`.tmp_acceptance/v0.9-20260718-102105/evidence`
- 候选日志：`candidate-debug.log`
- 候选配置：`candidate-config.json`
- 关键日志摘录：`runtime-evidence.txt`
- 包验证器隔离日志摘录：`package-verifier-runtime.txt`
- 原候选进程已结束。
- `%APPDATA%\LetsMakeMoney\config.json` 与 `debug.log` 已按验收前备份恢复，恢复后 SHA256 与备份一致。

## 2026-07-18 V09-BUG-001 定向复验

### 新候选身份

- Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`
- Zip SHA256：`7D1D7199362779AE2EE4E5DC9F8278C0B730D26AD39DB761A9680930E0AFD4BD`
- EXE SHA256：`B6CACC6D802E85DE6FBEB0D8BD0C5864B3ADEC2E72E9EDF72F0B6BD88D1D1E07`
- Native DLL SHA256：`E3E2030003A7DA725446A3873C3EC2E19D9442B98A67F24A771E76BD0BAD5089`

### 结果

| 项目 | 结论 | 证据 |
|---|---|---|
| 原始宠物图集导出 | 通过 | 四个 WebP 使用 `Keep File (exported as is)`，原始字节和 manifest SHA256 保持一致 |
| Classic 运行时加载 | 通过 | 包验证隔离日志包含 `PetManager.package shadow_loaded id=letsmakemoney-classic-pro` |
| 多多运行时加载 | 通过 | 包验证隔离日志包含 `PetManager.package shadow_loaded id=duoduo-cat` |
| 运行时拒绝断言 | 通过 | 任一包出现 `PetManager.package rejected root=res://assets/pets/packages/` 时验证器返回非零 |
| 旧坏包识别 | 通过 | `test_v09_exported_pet_payload.ps1` 能拒绝缺少原始 WebP 的旧候选 |
| 新候选包验证 | 通过 | `verify_v09_package.ps1` 返回 `Package verification passed: 0.9-beta` |

`V09-BUG-001` 的导出阻塞已关闭。该结果仅证明宠物包可被候选运行时真实消费，不替代动画观感、输入仲裁、DPI、托盘和长时间运行验收。由于产品随后取消双击并将长按/拖动统一为方向跑步，新动作合同实现后必须重新生成最终候选并从头执行独立验收。

## 2026-07-18 动画输入合同定向验证

| 项目 | 结论 | 证据 |
|---|---|---|
| 快速单击 | 通过 | 释放后立即产生状态感知 `single`，不再等待双击窗口 |
| 连续快速点击 | 通过 | 两次输入保持为两次单击，不产生独立双击产品动作 |
| 跑动进入 | 通过 | 按住 500ms 后产生 `run_prepare`，阈值前移动不接管窗口 |
| 跑动移动与释放 | 通过 | `run_move` 驱动窗口并保持最近水平朝向；释放产生 `run_settle`，不补发单击 |
| 旧宠物降级 | 通过 | 缺少跑动帧时仍可移动窗口，并恢复最新基础状态 |
| 自动回归 | 通过 | `verify_v09.ps1 -SkipExport`，包含 v0.9、v0.8、v0.7、v0.6 与 M4 门禁 |

该验证只证明运行时输入与回退合同。Classic 新跑动、工作、环境和业务事件素材尚未完成 S2-S5，真实动作观感与最终候选仍不得写为通过。

## 2026-07-19 业务事件层定向验证

| 项目 | 结论 | 证据 |
|---|---|---|
| 首次观察 | 通过 | 只建立当日快照与收益桶基线，不补播启动前已经发生的事件 |
| 午休开始与复工 | 通过 | `scheduled_work -> lunch` 只产生一次 `lunch_started`；`lunch -> scheduled_work` 产生 `work_resumed` |
| 下班 | 通过 | 有效工作进度完成后离开工作/午休区间，产生一次 `work_finished` |
| 收益里程碑 | 通过 | 工作状态跨越 100 元内部里程碑时产生 `income_milestone`，同一收益桶不重复 |
| 跨日去重 | 通过 | 日期变化重建基线，不把前一日状态跳变补播到新日期 |
| 显式交互与 Modal | 通过 | 事件仍被观察和去重，但动作活跃、跑步、显式输入或 Overlay 期间只记录跳过原因，不排队补播 |
| 缺失素材 | 通过 | 通用候选无法解析到专用动作时记录 `missing_frames` 并保持最新基础状态 |
| 全量回归 | 通过 | `verify_v09.ps1 -SkipExport` 覆盖 v0.9 全模块及 v0.6-v0.8、M4/native 历史门禁 |

语义日志入口为 `pet.business_event.observed`、`pet.business_event.requested` 和 `pet.business_event.skipped`。该结果证明事件触发和安全降级，不证明 S2-S5 最终动画的观感、锚点与流畅度。

## 2026-07-22 多多 S5.5 接入定向验证

### 载荷身份

- PetManager 提交：`59d52801e3360a6daf20a4033f42db3623303e51`
- Profile：`duoduo.s5` / `0.2.0`
- Motion manifest：`AAFE57B1E912E9306F7E01E14001160543DEE1A1FC9D1A51F5EFC7780C69ABB1`
- `atlas-00.webp`：`9B57CAD73DEF1372D5ACE7190434A2F0B7B1772BF356011839D1380F22CD7B62`
- `atlas-01.webp`：`CBF2F0FE0C03ADC8C920695F6FA69E0131483B36F9EECB18748E404DB1D66283`
- 人工审查：`approved / ready:true / published:false`
- Review SHA256：`8EF7CF921DB4FA3113EECADDD63B9412BB4DD5FF1FF256C3DCD5B325876E12CC`
- QA evidence SHA256：`EC540B9E9E79C487010904DBB3B02E9E75D7A6D478C6D1F62DC148C1B800FB01`

### 自动结果

| 项目 | 结论 | 证据 |
|---|---|---|
| 运行时文件同源 | 通过 | LMM 三份 motion 文件与 PetManager 受控文件逐一核对，SHA256 全部一致 |
| 通用包校验 | 通过 | 校验 profile、review、manifest、atlas、动作、逐帧时长、锚点、脚底线和图集范围 |
| 负向门禁 | 通过 | `ready:false`、profile 身份不一致、motion atlas 与发布清单哈希不一致均被拒绝 |
| 通用导入 | 通过 | 同一导入器加载 8 个动作；`working_loop` 总时长为 1520ms，语义与来源 Profile 保留 |
| 运行时映射 | 通过 | working、三种状态感知单击、run prepare/stop、lunch relief/return 优先解析新动作并保留旧资源回退 |
| 定向回归 | 通过 | `test_v09_pet_package.ps1`、`test_v09_pet_animation.ps1`、`test_v09_behavior_baseline.ps1` |

### 边界

该结果关闭“多多 S5.5 可被通用运行时安全消费”的自动门禁。项目所有者于 2026-07-22 确认 Classic 暂不大改，继续使用当前稳定包和通用回退，因此不再等待 Classic motion payload。真实桌面动画观感、DPI、输入仲裁、动态命中区和长时间稳定性仍必须通过新候选独立验收。

## 2026-07-22 S5.5 新候选身份与包内烟测

### 验收对象

- 分支：`agent/v0.9-ui-pause`
- 构建基线 HEAD：`02745126945b58a74e2d84c269cc30af8ff67519`
- 说明：候选包含该 HEAD 之后尚未提交的 v0.9 S5.5 接入、导出门禁和范围收敛改动；独立验收以以下产物 SHA256 为唯一运行身份，不以旧候选或 `build/` 目录代替。
- Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`
- Zip 大小：51,705,927 字节
- Zip SHA256：`36CEE0D4C73CDBBA876F59BA84C259C04F3E2F95D959EF147135009985A84465`
- EXE 大小：122,158,328 字节
- EXE SHA256：`B30E5E4409B8411738ABDE84AD0EC52E92DF3F975A9D69EFA1DB6CE6E5DD2FA1`
- Native DLL 大小：1,606,144 字节
- Native DLL SHA256：`E3E2030003A7DA725446A3873C3EC2E19D9442B98A67F24A771E76BD0BAD5089`

### 自动与包内结果

| 项目 | 结论 | 证据 |
|---|---|---|
| 完整自动回归 | 通过 | `verify_v09.ps1` 覆盖 v0.9、v0.6-v0.8、M4、安装器、更新、原生窗口和公开治理门禁 |
| 导出与打包 | 通过 | Godot 4.7 导出、M5 启动烟测、许可暂存和 Zip 生成均成功 |
| 独立解压包验证 | 通过 | `verify_v09_package.ps1 -SmokeSeconds 8` 返回 `Package verification passed: 0.9-beta` |
| Classic 运行时加载 | 通过 | 隔离日志包含 `PetManager.package shadow_loaded id=letsmakemoney-classic-pro version=1.0.0` |
| 多多 S5.5 运行时加载 | 通过 | 隔离日志包含 `PetManager.package shadow_loaded id=duoduo-cat version=1.1.0` |
| 宠物包拒绝 | 通过 | 隔离日志未出现 `PetManager.package rejected root=res://assets/pets/packages/` |

### 正常模式真实启动补证

| 项目 | 结论 | 证据 |
|---|---|---|
| 独立解压 EXE 启动 | 通过 | 从 `.tmp_acceptance/v0.9-s55-20260722-163359/extracted/LetsMakeMoney.exe` 启动，进程响应正常并取得有效窗口句柄 |
| 透明桌宠与 Panel | 通过 | `.tmp_acceptance/v0.9-s55-20260722-163359/evidence/desktop-normal-mode.png`；正常模式未出现蓝底或黑色窗口底板 |
| Windows 原生窗口策略 | 通过 | `debug.log` 记录 `setup_pet_window ok=true`、托盘初始化成功、任务栏策略应用成功 |
| Classic 与多多加载 | 通过 | 同次运行日志记录 Classic `1.0.0` 与多多 `1.1.0` 均为 `shadow_loaded` |

首次截图中的黑色主区域与蓝色命中区域来自用户配置中的 `debug_mode=true`，关闭调试模式后同一候选 EXE 的透明窗口显示正常，因此不判定为候选包透明度缺陷。测试前配置已备份，结束后已恢复；临时证据目录不进入发布包和提交范围。

该候选可以进入独立 `/acceptance`，但尚未完成真实 Windows DPI、动画观感、输入仲裁、动态命中、托盘/任务栏策略和两小时稳定运行，不得写为可发布。

## 2026-07-22 S5.5 真实 GUI 定向验收

### 结论

**未通过。** 锁定候选可以从独立解压目录正常启动，Classic 与多多均被运行时加载，基础 Windows 交互和模态点击穿透保护取得真实证据；但状态感知单击动作没有进入动画控制器。真实 Pet 场景探针确认存在运行时数组类型合同错误，记录为发布阻塞 `V09-BUG-002`。

### 分项结果

| 项目 | 结论 | 证据与说明 |
|---|---|---|
| 候选身份与独立启动 | 通过 | Zip SHA256 `36CEE0D4C73CDBBA876F59BA84C259C04F3E2F95D959EF147135009985A84465`；从 `.tmp_acceptance/v0.9-s55-20260722-163359/extracted/LetsMakeMoney.exe` 启动 |
| Classic 与多多加载 | 通过 | 同次运行日志包含两套包的 `shadow_loaded`，未出现目标包 `rejected` |
| 单击输入分类 | 通过 | 连续五次真实单击均产生 `pet.input.pressed` 和 `pet.input.interaction: type=clicked_single base=working` |
| 双击产品语义取消 | 通过 | 五组快速双击形成十次单击，没有产生 `clicked_double` |
| 长按拖动分类 | 通过 | 日志包含 `pet.input.run_prepare`、方向变化和 `pet.input.run_settle`；受控拖动结束后未补发单击 |
| 右键、Settings 与模态保护 | 通过 | 右键菜单和 Settings 可打开；Popup/Modal 点击穿透暂停与恢复事件成对出现 |
| 状态感知动作播放 | 未通过 | 输入状态进入 `clicked_single`，但没有 `pet.animation.requested/started/finished`；画面保持 `working_loop` |
| DPI、托盘、资源损坏回退、两小时稳定运行 | 待验证 | 发现发布阻塞后停止扩展验收，避免把失真的动画候选继续签核 |

### 根因证据

真实 Pet 场景集成探针执行状态感知单击后记录：

```text
SCRIPT ERROR: Trying to assign an array of type "Array" to a variable of type "Array[String]".
at: _request_interaction_action (res://src/scenes/pet/pet.gd:146)
PROBE after_interaction=2
PROBE after_animation=working_loop
PROBE active_token=0
PROBE final_interaction=2
PROBE final_animation=working_loop
PROBE final_token=0
```

`src/scenes/pet/pet.gd:146` 把 `ActionProfileScript.interaction_candidates(...)` 返回的未类型化 `Array` 赋给 `Array[String]`。错误发生在 `_animation_controller.request_action(...)` 之前，因此没有动作令牌，交互状态停留在单击状态，基础动画继续播放。

现有宠物包和动画自动测试分别证明动作资源存在、元数据正确及控制器可独立工作，但没有实例化真实 Pet 场景并覆盖 `PetManager.state_changed -> pet.gd -> action profile -> animation controller` 完整链路，因此没有发现该运行时错误。

### 证据位置

- `.tmp_acceptance/v0.9-s55-20260722-163359/evidence/gui-before-input.png`
- `.tmp_acceptance/v0.9-s55-20260722-163359/evidence/gui-after-single-clicks.png`
- `.tmp_acceptance/v0.9-s55-20260722-163359/evidence/gui-settings-closed.png`
- `.tmp_acceptance/v0.9-s55-20260722-163359/evidence/gui-modal-closed.png`
- `.tmp_acceptance/v0.9-s55-20260722-163359/evidence/gui-after-run-left.png`
- `.tmp_acceptance/v0.9-s55-20260722-163359/evidence/probe-runtime-action.log`

### 发布判断

当前候选不可发布。下一步进入 `V09-BUG-002` 与 `V09-BUG-003` 定向修复，补齐真实 Pet 场景集成测试和 Panel 多比例布局测试，重新导出、打包并记录新候选身份；旧候选不得继续用于发布签核。

## 2026-07-22 Panel 低比例缩放补充验收

### 结论

**未通过。** 将显示缩放调至 58% 后，Panel 白色外壳按比例收缩，但折叠态状态文字、进度条和下一节点仍向右延伸，脱离 Panel 并进入桌宠区域。该问题记录为发布阻塞 `V09-BUG-003`。

### 代码证据

- `src/scenes/panel/panel.gd` 会按 `_display_scale` 缩放 Panel 外壳、内容最小尺寸、字体和大部分行高。
- `src/scenes/panel/panel.tscn` 为 `$Collapsed/CollapsedContent/CollapsedProgress` 固定了 `custom_minimum_size = Vector2(268, 5)`。
- `_apply_collapsed_text_style()` 没有按 `_display_scale` 更新该进度条宽度；固定 `268px` 子节点会反向撑开已缩小的内容容器。
- 同一场景还存在需要在修复阶段核对的其他固定宽度节点；本轮只把真实截图已经证明的折叠态问题标为已确认。

### 证据

- `.tmp_acceptance/v0.9-s55-20260722-163359/evidence/gui-scale-058-layout-failure.png`

### 复验门禁

1. Panel 外壳、内容容器、进度条、Header/Footer 和命中区必须使用同一缩放合同。
2. 至少覆盖 50%、58%、100%、150% 的折叠态和展开态布局。
3. 状态、金额、工作进度和下一节点在最长中文文案下不得溢出或进入桌宠区域。
4. 修复后重新生成候选身份，并与 `V09-BUG-002` 一并定向复验。

## 2026-07-22 BUG-002/003 修复后定向复验

### 新候选身份

- 分支：`agent/v0.9-ui-pause`
- 构建基线 HEAD：`02745126945b58a74e2d84c269cc30af8ff67519`
- Zip：`releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip`
- Zip 大小：51,706,374 字节
- Zip SHA256：`A7238EDA4F712FB177D9C9820F5201CC25CFCAABA12A00B2423115BEB161125C`
- EXE 大小：122,158,824 字节
- EXE SHA256：`39A52FCFEC320604BD8C4A686C25429BDA4FA6B4A5A394EA3F78738E899830C0`
- Native DLL 大小：1,606,144 字节
- Native DLL SHA256：`E3E2030003A7DA725446A3873C3EC2E19D9442B98A67F24A771E76BD0BAD5089`
- 旧候选 `36CEE0...` / `B30E5E...` 只保留为失败历史，不得继续用于验收或发布。

### 结果

| 项目 | 结论 | 证据 |
|---|---|---|
| 真实 Pet 场景集成测试 | 通过 | `scripts/verify_v09_pet_integration.gd` 实例化 `pet.tscn`，验证多多单击产生请求、开始、完成和基础状态恢复 |
| 真实桌面多多单击 | 通过 | `.tmp_acceptance/v0.9-bugfix-20260722/evidence/working-ack-after-fix.png`；隔离 `debug.log` 含完整 `working_ack` 事件链 |
| Panel 50%/58%/100%/150% 布局 | 通过 | `scripts/verify_v09_window_experience.gd` 实例化真实 Panel 并核对固定子节点不超出外壳 |
| 真实桌面 58% Panel | 通过 | `.tmp_acceptance/v0.9-bugfix-20260722/evidence/panel-scale-058-after-fix.png` |
| v0.9 全量无导出回归 | 通过 | `verify_v09.ps1 -SkipExport` 覆盖 v0.9、v0.6-v0.8 与 M4 |
| 导出、打包与包验证 | 通过 | `package_v09.ps1`、M5 启动烟测、`verify_v09_package.ps1` 均通过 |

### 真实日志语义

```text
pet.input.interaction: type=clicked_single base=working
pet.animation.requested: token=1 animation=working_ack priority=50 base=working
pet.animation.play: animation=working_ack reason=action_requested frames=8 duration_ms=870
pet.animation.started: token=1 animation=working_ack
pet.animation.finished: token=1 animation=working_ack reason=animation_finished
pet.animation.play: animation=working_loop reason=base_resolved:base_changed frames=16 duration_ms=1520
```

### 当前判断

`V09-BUG-002` 与 `V09-BUG-003` 已关闭。新候选满足重新进入独立 `/acceptance` 的条件，但 DPI 全量截图、通知区真实鼠标、普通/纯桌宠任务栏策略、损坏资源回退、完整动画观感和两小时稳定运行尚未签核，因此本节不将版本写为可发布。
