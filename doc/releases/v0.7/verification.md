# LetsMakeMoney v0.7 验证记录

**当前阶段**：V07-A3
**总体状态**：A0/A1/A2/A3 与远端历史重写复验已完成
**公开判断**：安全、许可、历史和隐私门禁已通过；项目所有者批准源码仓库公开。v0.7 发布门禁仍未通过。

## A0 验证对象

- Git：`main` / `e6f25ae8cb4d9583aa3e629cb79416e278060117` 加脏工作区。
- v0.6 tag：`v0.6-beta` → `e6f25ae8cb4d9583aa3e629cb79416e278060117`。
- v0.6 验收 Zip：`releases/v0.6/LetsMakeMoney-v0.6-beta-windows-x86_64.zip`。
- Zip SHA256：`CECD3C3ABACFCB5EF594584E2AEB0E25C1824BAE97AB84B224073E7444E72615`。
- EXE SHA256：`749F18E35E757A250EDA8D3DE5B712BD554861082E33D607E1D07835AA943E3B`。
- native DLL SHA256：`AB57D3720FDDADA94397F2249C2827C43D1ADB0BDE3641BDC91AFD8AFCEFF696`。

## A0 定向回归（2026-07-12）

- 执行基线：实施阶段；事实源为 `doc/releases/v0.7/prd.md`、`doc/releases/v0.7/dev_plan_v0.7.md`、`doc/releases/v0.7/progress_v0.7.md`；本轮不重写 PRD 或 dev plan。
- V07-A0-001：当前分支为 `main`，HEAD 为 `44858879f21d82984bbce471612679974edfde35`，`v0.6-beta` tag 为 `5d1681b5d0647609245957569edf23d87243d007`；工作树有未提交改动，本轮未提交、未推送、未创建 tag 或 Release。
- V07-A0-002 至 V07-A0-005：`check_docs_status.ps1` 通过；v0.7 开发态、v0.6 发布基线、状态/验证/readiness、候选清单和排除清单入口均存在且可访问。
- V07-A0-006：9 类私有路径均被 `.gitignore` 命中；README、current、PRD、dev plan 和 progress 5 类候选入口均未被误忽略。
- V07-A0-007：`check_public_candidate.ps1` 只读扫描 460 个候选文件，0 失败、0 警告；公开候选正反夹具均通过，风险夹具按预期非零失败。资产许可检查及正反夹具也通过。
- V07-A0-008：`git diff --check` 通过；`doc/releases/v0.6/` 和 `doc/logs/dev_log_v0.6.md` 无工作树差异。v0.7 便携 Zip SHA256 为 `205C60CAF2B42A6B19EE2249D5623752A9F1624CF5B3ECE1DE3473B2BA5B74D8`，测试安装器 SHA256 为 `0036EAF2026A679B838C6AE4C4F203B14CF4FCB78404A713D1978A083621E923`。
- 结论：A0-001 至 A0-008 定向回归通过；仍处于未提交工作树，未进入 Acceptance 或发布写操作。

## A0 检查矩阵

| 检查 | 命令/入口 | 预期 | 结果 |
|---|---|---|---|
| 当前树公开候选扫描 | `scripts/check_public_candidate.ps1` | 工具正确返回非零并列出尚未关闭的公开门禁，不泄露秘密值 | 工具通过；当前树未通过：432 文件、44 失败、31 警告 |
| 检查器测试 | `scripts/test_check_public_candidate.ps1` | 正常夹具通过，风险夹具失败 | 通过 |
| 当前文档事实 | `scripts/check_docs_status.ps1` | v0.7 私有开发与 v0.6 已发布口径不冲突 | 通过 |
| UTF-8/乱码 | 公开候选扫描 | 活跃文档与脚本无非法 UTF-8、无常见乱码 | 通过；严格 UTF-8 异常 0 |
| Markdown 本地链接 | 公开候选扫描 | 活跃文档链接存在 | 通过；未发现失效本地链接 |
| ignore 命中/误伤 | `git check-ignore` + 测试脚本 | 私有证据被忽略，源码/文档未误伤 | 通过；8 类私有路径命中，4 类候选路径未误伤 |
| 敏感信息/绝对路径/大文件 | 公开候选扫描 | 只报告路径和规则；完整历史留 A3 | 当前树未发现可输出的真实秘密；31 个绝对路径警告；已跟踪 `temp/` 产生 43 个排除失败和 1 个 Zip 二进制失败 |
| 补丁格式 | `git diff --check` | 无空白错误 | 修正行尾空格后通过 |

## A0 结论

- A0 边界冻结：通过。
- A0 当时的当前树公开准备：不通过，阻塞项转交 A1/A2/A3；这些阻塞随后已关闭。
- v0.6 历史文档差异数为 0，未改写既有验收结论。
- 检查器只覆盖当前树；完整 Git 历史仍必须由 V07-A3 执行。

## V07-A1 许可验证

| 检查 | 结果 | 证据 |
|---|---|---|
| 根 MIT 许可 | 通过 | `LICENSE`；2026 NzyZzz1998 |
| 受限素材许可 | 通过 | `ASSETS_LICENSE.md` 定义适用范围、允许和禁止行为 |
| 视觉资产盘点 | 通过 | `ASSETS_MANIFEST.md`、`assets/asset-license-manifest.json` |
| 橘猫/占位猫/图标权属 | 通过 | `asset-owner-attestation.md`；所有者确认个人主导 AI 生成和修改 |
| 目录许可入口 | 通过 | `assets/README.md`、`icons/README.md`、`doc/prototypes/README.md` 及角色 README |
| 中英文 README 双许可入口 | 通过 | `README.md`、`README.en.md` |
| 外部素材贡献边界 | 通过 | `CONTRIBUTING.md` 明确暂不接收外部素材文件 |
| 许可范围自动检查 | 通过 | `scripts/check_asset_licenses.ps1` 返回 0 |
| 检查器正反测试 | 通过 | 已登记夹具通过；未登记 PNG 夹具返回非零 |
| 未知权属 | 通过 | 公开候选无 unknown；审阅、实验和临时素材均明确排除 |

### A1 边界

- A1 不证明 Godot、godot-cpp、Inno Setup 或其他第三方依赖合规；这些属于 A2。
- `excluded_private` 不是公开许可。相关已跟踪文件仍由 A3 决定处置。
- 本轮未修改业务代码、运行配置、发布包或 Git 历史。

## V07-A2 第三方与 Release 合规验证

| 检查 | 结果 | 证据 |
|---|---|---|
| 实际依赖盘点 | 通过 | Godot、godot-cpp、MinGW/GCC、Python、SCons、Pillow、Git、PowerShell 及计划工具均已登记 |
| 本机身份 | 通过 | Godot `4.7.stable.official.5b4e0cb0f`；godot-cpp `ba0edfed...`；Python 3.12.8；SCons 4.10.1；GCC 16.1.0-5 |
| 第三方许可证原文 | 通过 | `licenses/third-party/` 共 13 个文件；`license-files.json` 固定 SHA256 |
| 人工/机器清单 | 通过 | `third-party-dependencies.md`、`third_party/dependencies.json` |
| THIRD_PARTY_NOTICES | 通过 | 运行时、开发依赖和计划工具分层明确 |
| Release `LICENSES/` 合同 | 通过 | `release-licenses-layout.md`、`stage_release_licenses.ps1` |
| 项目合规检查 | 通过 | `check_third_party_compliance.ps1` 返回 0 |
| 受控正常包 | 通过 | staging 后所有必需许可、manifest 和二进制白名单一致 |
| 缺 manifest 条目 | 通过 | 删除 Godot 条目后按预期非零 |
| 缺许可证原文 | 通过 | 删除 Godot LICENSE 后按预期非零 |
| 未登记 DLL / 字体 | 通过 | 分别加入测试文件后均按预期非零 |
| notices 版本不一致 | 通过 | 修改 Godot 版本后按预期非零 |
| v0.6 原包只读审计 | 不满足 v0.7 公开合规 | 缺 `LICENSES/`、dependencies manifest 和运行时许可原文；未修改原包 |

### A2 边界与转交

- Inno Setup 当前未安装、版本待 C1 选择；安装器不得据此标为合规或可发布。
- GitHub Actions 当前未选择，B2/E3 必须固定不可变 commit、许可和最小权限。
- godot-cpp 当前 commit 已取证，但固定下载、哈希和无缓存构建属于 B1。
- A2 未删除已跟踪 `temp/` 或历史 Zip，也未执行完整历史审计。

## V07-A3 完整历史、隐私与资产审计

| 检查 | 结果 | 证据 |
|---|---|---|
| Gitleaks 当前候选快照 | 通过 | 8.30.1；469 个候选文件；0 命中 |
| Gitleaks 完整历史 | 通过 | 所有本地/远端可达分支与 tag；33 commits；0 命中 |
| TruffleHog 当前候选快照 | 通过 | 3.95.9；467 chunks / 2,650,501 bytes；0 verified/unverified |
| TruffleHog 完整历史 | 通过 | 1,109 chunks / 2,252,008 bytes；0 verified/unverified |
| Git 对象、大文件和二进制 | 通过并记录 | 844 objects、551 blobs、97 binary blobs；7 个大于 1 MiB，0 个大于 5 MiB |
| 私有运行数据和验收证据 | 通过 | Git 历史中 `.manual-test/`、`.tmp_acceptance/`、`config.json`、`debug.log` 均为 0 |
| 历史排除内容 | 已签核重写、未执行 | 43 个 `temp/`、20 个实验素材、7 个 ComfyUI 路径仍可从历史访问 |
| 绝对路径和身份披露 | 已签核重写、未执行 | 72 个历史 blob 含绝对路径；个人作者邮箱将统一为 GitHub noreply 身份 |
| A1 资产清单交叉检查 | 通过 | 运行时素材可按受限许可公开；历史实验素材权属明确但政策上排除 |
| A2 依赖清单交叉检查 | 通过 | 未发现未登记第三方二进制或无权公开依赖进入历史 |
| 诊断摘要隐私样例 | 通过 | `scripts/verify_v07_privacy.ps1` 注入用户名、路径、薪资、坐标和伪 token 后均未泄露 |

### A3 能力边界

- 两种专业秘密扫描器均为 0 命中，因此没有凭据需要执行联网有效性验证或轮换；TruffleHog 使用 `--no-verification`，避免将潜在值发送至外部端点。
- 原始扫描结果只保存在系统临时目录，不进入仓库；正式文档仅保留脱敏计数与路径类别。
- P0 真实秘密为 0。所有者已选择方案 3；历史重写本身是后续公开阻塞，不改变 A3 审计任务已完成的结论。
- 当前树清理由 B3 承接；A3 没有删除、移动、取消跟踪或重写任何文件与提交。

## Git 历史重写本地演练

| 门禁 | 结果 |
|---|---|
| 独立 mirror 与 pristine/完整 bundle | 通过 |
| 计划删除路径 | 残留 0 |
| Windows 本机绝对路径 | 残留 0 |
| 旧个人作者邮箱 | 元数据与内容残留 0 |
| 作者身份 | 统一为 1 个 GitHub noreply 身份 |
| 树差异 | 70 个计划内删除、25 个文本/验证调整、0 个非预期删除 |
| Gitleaks / TruffleHog | 均为 0 命中 |
| `git fsck --full` | 通过 |
| v0.4/v0.5/v0.6、配置、M4/M5 | 通过 |
| 托盘普通/纯桌宠 | 各 3 轮通过 |
| 远端替换 | 已执行；fresh clone 复验通过；项目所有者随后批准仓库公开 |

完整演练证据与 SHA 映射见 `git-history-rewrite-dry-run.md`；后续远端执行证据见下一节。

### 远端 fresh clone 复验

- 远端 `main`：作者身份最终规范化前为 `451311a3e10b9099d84874b83dcd0c2f01682ebd`；规范化后以 `git ls-remote origin refs/heads/main` 返回值为准。
- `test` 与 v0.2-v0.6 tags 均已替换为重写后的 refs。
- Gitleaks、TruffleHog：0 命中；目标路径、绝对路径、旧邮箱：0。
- 公开候选：407 文件、0 失败、0 警告。
- 第三方合规、文档、隐私、v0.4-v0.6、M4/M5 和托盘普通/纯桌宠回归：通过。
- GitHub Release 页面附件关联：因当前自动化浏览器没有私有仓库登录态，保留一次只读人工确认，不影响 refs 已成功替换的事实。
- 最终身份复核发现顶部 3 个 v0.7 提交继承了本机 Git 邮箱；现已在文件树不变的前提下统一改写为 `101812716+NzyZzz1998@users.noreply.github.com`。重写后的全部可达提交仅保留这一种作者、提交者与 tagger 身份。

## 边界

本页记录 A0-A3 与后续工程门禁证据。源码仓库已经公开，但 B/C/E 工程门禁和独立 Acceptance 仍约束 v0.7 产物发布。本页也不将 v0.6 的“开机自启暂不验证”改写为通过。

## V07-C1-C4 安装器、签名与更新

| 检查 | 结果 | 证据 |
|---|---|---|
| Inno Setup | 通过 | 6.7.3；当前用户安装脚本、许可、快捷方式、运行检测和卸载数据确认合同通过 |
| 测试安装器 | 部分通过 | `LetsMakeMoney-Setup-v0.7-beta-windows-x86_64.exe` 编译和结构校验通过，签名为 `NotSigned`，禁止公开附件 |
| 签名脚本 | 通过 | 仅从 `LMM_SIGN_*` 环境变量读取证书、密码和时间戳；缺失/无效签名阻止公开门禁 |
| 更新服务 | 通过 | semver、稳定/测试通道、GitHub Release、频率、SHA256、可信来源、磁盘预检、取消和脱敏日志合同通过 |
| Authenticode 运行时 | 通过 | native `WinVerifyTrust` + 证书发布者读取；能力不可用或发布者不匹配时拒绝自动安装 |
| 安装确认与回退 | 通过 | 下载校验后第二次确认、配置 `.pre-update` 备份、托盘关闭、安装器启动失败恢复和 GitHub Release 回退入口 |
| 实机安装/更新 | 待 Acceptance | 安装取消/修复/覆盖、显式删除数据、SmartScreen、断网/限流和双实例需真实 Windows 操作 |

## V07-D/E 公开入口与候选产物

| 检查 | 结果 | 证据 |
|---|---|---|
| 未来规划 | 通过 | 平台、主题、宠物三份路线文档；iOS 优先；无业务实现 |
| 双语与治理 | 通过 | 中英 README、CONTRIBUTING、CODE_OF_CONDUCT、SECURITY、Issue/PR 模板合同通过 |
| Actions 供应链 | 通过 | 最小权限；checkout/setup-python/msys2/cache/upload-artifact 固定不可变 commit |
| v0.7 自动验证 | 通过 | `verify_v07.ps1` 与 docs suite；当前树 457 文件、0 失败、0 警告 |
| v0.7 便携 Zip | 通过 | 解压、版本、EXE/DLL、manifest/checksum/LICENSES 与启动 smoke 通过 |
| 干净环境与 GUI | 暂不验证 | 当前无独立 Windows 用户或 VM；自动化、本机构建与 GUI 证据不冒充干净环境通过，见 `manual-verification.md` |

### 候选产物身份

- Zip：`releases/v0.7/LetsMakeMoney-v0.7-beta-windows-x86_64.zip`
- Zip SHA256：`205C60CAF2B42A6B19EE2249D5623752A9F1624CF5B3ECE1DE3473B2BA5B74D8`
- EXE SHA256：`2A1365672507C34F78C2EE5E49E9790C44C86758374169484F0953F5057EDA57`
- native DLL SHA256：`5D21CFFAA2A26F25958CD50FF138449D8575B1A1E512B5F30304AC58A28D1BE4`
- 测试安装器 SHA256：`0036EAF2026A679B838C6AE4C4F203B14CF4FCB78404A713D1978A083621E923`，签名 `NotSigned`

## 最终候选 Acceptance（2026-07-11）

**结论**：部分通过；暂不可进入发布收口。

| 验收项 | 实际结果 | 结论 | 证据 |
|---|---|---|---|
| 身份锁定 | 分支、HEAD、干净工作区、Zip/安装器 SHA256 全部匹配 | 通过 | `environment-before.json` 与本页候选身份 |
| Zip 首次启动 | 从独立解压目录启动；Wizard 四步、橘猫、Panel 正常 | 通过 | `01`-`05` 截图，`wizard_*` 日志 |
| Settings 五页与更新 | 五页无裁切；无变化、成功日志正确；真实 GitHub 检查返回已是最新 | 通过 | `07`-`15` 截图与日志 |
| Settings 保存失败 | 输入保留、配置哈希不变、失败语义日志完整；UI 未显示失败提示 | 未通过 | `19`、`20` 截图；`save-failure-before-hash.txt`；`settings_save_failed` |
| Wizard 取消/关闭 | 状态恢复且未写入半成品 | 通过 | `17`、`18` 截图；`wizard_state_restored`、`wizard_cancelled` |
| Popup/Modal 穿透保护 | 打开/关闭日志成对，关闭后恢复 | 通过 | `passthrough_suspended/resumed` 日志 |
| 纯桌宠任务栏策略 | 进程继续运行，Computer Use 应用列表不再暴露窗口，native 隐藏返回 true；项目所有者人工确认托盘左键恢复后无任务栏入口 | 通过 | `set_taskbar_visible ... false / ok=true`；`V07-MAN-001` 人工记录 |
| DPI/多显示器 | 100%、125%、150%、200% DPI 的 Panel、菜单、Settings、Wizard 实机通过；本机仅单显示器 | 部分通过 | `.tmp_acceptance/v0.7-dpi-20260712/evidence/`；多显示器暂不验证 |
| 安装器取消 | 取消后无程序目录和卸载记录残留 | 通过 | `22`、`23` 截图与文件检查 |
| 正常安装与覆盖/修复 | 当前用户目录正确；EXE/DLL 哈希一致；两次 GUI 安装完成 | 通过 | `24`-`27` 截图与安装文件哈希 |
| 卸载保留数据 | 程序目录删除，APPDATA 配置保留 | 通过 | `28` 截图与卸载后文件检查 |
| 卸载主动删除数据 | 使用 LetsMakeMoney 精确卸载路径，勾选删除数据并通过不可恢复二次确认；隔离测试 APPDATA 与安装目录均清除，原用户配置随后恢复 | 通过 | `.tmp_acceptance/v0.7-delete-data-20260712-203736/evidence/` |
| SmartScreen/签名 | 安装器为 `NotSigned`；证书尚未获批 | 暂不验证（非阻塞，安装器不发布） | installer manifest / Get-AuthenticodeSignature |
| 包内许可和双语入口 | LICENSES、notices、README、manifest/checksum 完整 | 通过 | 包验证与 `LICENSES/` 清单 |
| 环境恢复 | 原 APPDATA、注册表恢复；安装目录移除；进程 0 | 通过 | `environment-restored.json` |

### 发布判断

- 源码仓库：可继续公开。历史、许可、安全和当前树门禁未回退。
- 便携 Zip：`V07-BUG-001` 已由新候选包定向复验关闭；仍需完成或明确接受剩余系统级人工补证边界后再作最终发布判断。
- 未签名安装器：不可公开发布。
- v0.7：Acceptance 仍为部分通过；真实通知区/任务栏、高 DPI 与显式删除数据已通过。多显示器、干净 Windows 用户/VM、签名暂不验证，不阻塞便携 Zip 和版本收口。

## V07-BUG-001 定向复验（2026-07-11）

| 检查 | 结果 | 证据 |
|---|---|---|
| 运行态布局合同 | 修复前因反馈不在固定 action row 按预期失败；修复后反馈可见且矩形完全位于 Settings Shell 内 | `scripts/verify_v07_ui_contract.gd` |
| v0.7 / v0.5 / v0.4 回归 | 通过 | `verify_v07.ps1`、`verify_v05.ps1`、`verify_v04.ps1` |
| 新候选包 | 导出、许可 staging、包验证与启动 smoke 通过 | Zip SHA256 `205C60CAF2B42A6B19EE2249D5623752A9F1624CF5B3ECE1DE3473B2BA5B74D8` |
| 保存失败反馈 | 0.6 秒和 1.5 秒稳定观察点均清晰显示 `保存失败` 及原因 | `.tmp_acceptance/v0.7-bugfix-20260711-235257/evidence/03-settings-save-failed-600ms.png`、`04-settings-save-failed-1500ms.png` |
| 输入保留 | 失败后输入框继续显示 `15322` | 同上截图 |
| 旧配置保护 | 配置 SHA256 前后均为 `E003D145D827576200040C4351B486A1737E5E625D2C8036AA543FAE78FE3378` | `config-before-sha256.txt` 与复验输出 |
| 失败语义日志 | 同时包含 `config_save_failed` 与 `settings_save_failed` | `.tmp_acceptance/v0.7-bugfix-20260711-235257/evidence/debug-tail.txt` |
| 环境恢复 | 进程为 0，原 APPDATA 已恢复，故障注入目录不存在 | 定向复验恢复检查 |

**结论**：`V07-BUG-001` 通过，关闭功能发布阻塞；安装器保持未签名且不发布，签名相关验收按项目所有者决定暂不验证。

### 本地测试安装清理（2026-07-12）

- `V07-MAN-004` 已补测：使用精确 LetsMakeMoney 卸载器勾选“同时删除设置和日志”，确认不可恢复提示后，隔离测试数据与安装目录均被清除；验收结束后恢复原用户配置。
- 使用精确安装路径启动 LetsMakeMoney 卸载器，保持删除数据复选框未勾选并完成标准卸载确认。
- 结果：`%LOCALAPPDATA%\Programs\LetsMakeMoney` 不存在，卸载注册项为 0，相关进程为 0；`%APPDATA%\LetsMakeMoney\config.json` 保留。
- 证据：`.tmp_acceptance/v0.7-uninstall-delete-20260712-004740/evidence/01-uninstall-success-preserve-data.png`。
- 观察：`InitializeUninstall()` 的自定义确认页不区分静默卸载，传入 `/VERYSILENT` 仍会弹窗；记录为安装器自动化边界，不冒充显式删除数据通过。

## V07-B1 固定依赖与可复现构建

| 检查 | 结果 | 证据 |
|---|---|---|
| Godot 4.7 stable 身份 | 通过 | 官方 Windows x86_64 归档 SHA256 `02A5312236F4E0209C78BCB2F52135B1963E6B8888C873C9CEE81459E60BCD71`；本机可执行文件 SHA256 `B2CA888D5115A6CEDEE564764A2EE494A625F2EC2EDBABD010FE33C9A88A6BF8` |
| godot-cpp lock | 通过 | `ba0edfed90512ec64aba51d4295a3e7e30112f86`；在线 mirror 与离线 clone 均检出同一 commit |
| bootstrap 正反向测试 | 通过 | 正常在线、离线缓存通过；缺缓存和错误 commit 非零失败 |
| 构建合同测试 | 通过 | Python、SCons、MSYS2/GCC、Godot、godot-cpp、缓存和目标身份可读；错误 Godot SHA256 与缺 MSYS2 非零失败 |
| 干净 Debug 构建 | 通过 | 仓库外全新 native 目录，不使用项目内 godot-cpp 或旧 DLL |
| 干净 Release 构建 | 通过 | 同一 lock 和 mirror 完成；DLL 长度 1,600,000，SHA256 `DE2144D92F6D30796B8872BB706089FC031C6DAACF02F66D1483A5F7E0CB06E7` |
| 冷构建耗时 | 记录 | Debug 与 Release 分别需要完整 godot-cpp 目标，双目标总耗时超过 15 分钟；B2 需设计缓存与独立 job 超时 |

## V07-B2 CI 与验证/打包脚本治理

| 检查 | 结果 | 证据 |
|---|---|---|
| 公共 package/verify 契约 | 通过 | `test_ci_script_contract.ps1`、`test_package_common.ps1` |
| 阻塞错误故障注入 | 通过 | Parser/Parse/Script/Invalid call/缺资源均非零失败 |
| 包故障注入 | 通过 | 错版本和额外 DLL 被拒绝；A2 许可缺失/未知字体与 DLL 测试继续通过 |
| 隔离 APPDATA | 通过 | 公共 runner 使用 try/finally 恢复调用进程环境 |
| 本机摘要 | 通过 | `.tmp_ci/verification-summary.json` 使用与 Actions 相同入口 |
| 活跃回归 | 通过 | v0.6、v0.5、v0.4、M4、M5 |
| 真实 GUI 边界 | 转交 Acceptance | 见 `ci-and-manual-boundaries.md` |

## V07-B3 低风险代码与仓库瘦身

| 检查 | 结果 | 证据 |
|---|---|---|
| Settings/Wizard 运行态合同 | 通过 | `verify_v07_ui_contract.gd` 覆盖五页、四步和共享壳节点 |
| Settings 旧路径删除 | 通过 | `test_settings_slimming_contract.ps1`；全仓 scene/signal/dynamic call 无引用 |
| 历史兼容 | 通过 | v0.2、v0.4、v0.5、v0.6、M4、M5 |
| 临时/实验运行时引用 | 通过 | 当前 Git 树无 `temp/`、`experiments/` 或 ComfyUI 脚本；export 继续显式排除 |
| 当前源码包内启动 | 通过 | M5 重新导出后公共 package/verify smoke 通过 |

## V07-B4 Main/native 行为测试与状态合同

| 检查 | 结果 | 证据 |
|---|---|---|
| 状态所有权与模式矩阵 | 通过 | `window-native-state-contract.md` |
| native 协议 | 通过 | `native-protocol.json` 与 `test_window_state_contract.ps1` |
| 普通/纯桌宠托盘 | 通过 | 当前导出 EXE 各 2 轮；任务栏策略断言通过 |
| Settings/Wizard/Popup | 通过 | v0.4-v0.7 UI、模态与穿透日志合同 |
| 多显示器/DPI | 待 E4/Acceptance | 已建立 100%-200% 人工矩阵，不在 headless/CI 冒充通过 |

## V07-B5 Main/native 分阶段治理

| 切面 | 结果 | 证据 |
|---|---|---|
| Window/overlay policy | 通过 | `verify_v07_window_policy_coordinator.gd` 与 v0.4/v0.6 回归 |
| native capability health | 通过 | `test_native_health_contract.ps1`；兼容布尔字段保留 |
| shared native protocol | 通过 | JSON/header 合同与 native Release 编译 |
| 托盘与任务栏 | 通过 | 当前源码导出后 normal/pure 各 10 轮 |
| DPI | 通过 | 100%、125%、150%、200% 实机截图证据齐全，测试后恢复 100% |
| 多显示器 | 暂不验证 | 当前仅单显示器，不冒充跨屏、记忆与断开回落通过 |

## 最终发布前复核（2026-07-13）

**结论**：通过；产品、便携 Zip、本机回归和 GitHub 网页治理门禁均闭环，可进入发布收口。

| 验收项 | 结果 | 证据 |
|---|---|---|
| 候选身份 | 通过 | `main` / `44858879f21d82984bbce471612679974edfde35`；最终文档快照重新打包后 Zip SHA256 `16F47A844EFD78D387E9D08FBCD3DE76C8C8BDD518731C1B0BA022E7F598121F`；测试安装器 SHA256 `0036EAF2026A679B838C6AE4C4F203B14CF4FCB78404A713D1978A083621E923` |
| 安装取消、覆盖/修复、卸载 | 通过 | 既有真实 GUI 证据继续有效；安装目录、卸载项和用户数据边界符合文档 |
| 安装失败提示与残留 | 通过 | 受控使用“同名文件占用目标目录”触发 Error 183；安装器显示可读错误；结束后默认安装目录不存在、卸载注册项为 0、相关进程为 0 |
| 更新链路 | 通过 | 真实 GitHub 检查返回已是最新；版本比较、稳定/测试通道、可信来源、缺失 SHA256、取消、HTTP/下载/校验/签名失败清理和当前版本保护由 `verify_v07_update_service.gd`、`test_update_contract.ps1` 与实现日志合同覆盖 |
| 配置兼容 | 通过 | 安装版和便携版按设计共享 `%APPDATA%\LetsMakeMoney`；不得同时运行；安全写入、损坏恢复、保存失败不污染旧配置和历史回归通过 |
| 英文 README | 通过 | 自然表达、术语、链接、构建命令、安装/便携边界已人工复核；真实托盘/任务栏/DPI 与暂不验证项口径已同步 |
| 自动与历史回归 | 通过 | v0.7、v0.6 config、v0.5、v0.4、M4、M5、文档、公开候选、素材许可、第三方合规和包验证全部通过；`git diff --check` 通过 |
| GitHub 仓库身份 | 通过 | GitHub 插件确认仓库为 public、默认分支 `main`、当前账号具备 admin/push 权限 |
| Release dry run | 通过（仓库内合同） | 新增 `windows-release-dry-run.yml`；仅 `workflow_dispatch`，`contents: read`，不读取 secrets，不创建 Release，只上传 Zip 与 SHA256 dry-run artifact |
| 分支保护与 Private Vulnerability Reporting | 通过 | 项目所有者截图确认 `Protect main` 为 Active，要求 PR、必要 CI、禁止 force push/删除；Advanced Security 页面确认 Private Vulnerability Reporting 已启用 |

**暂不验证且不阻塞便携 Beta**：多显示器、干净 Windows 用户/VM、Authenticode/SmartScreen、真实 Windows 登录后的开机自启。未签名安装器不得上传 Release。
| 真实通知区 | 通过 | 项目所有者完成人工补证，普通/纯桌宠左键隐藏恢复及任务栏策略符合预期 |
