# LetsMakeMoney v0.7 验证记录

**当前阶段**：V07-A3
**总体状态**：A0/A1/A2/A3 与远端历史重写复验已完成
**公开判断**：当前不得公开

## A0 验证对象

- Git：`main` / `e6f25ae8cb4d9583aa3e629cb79416e278060117` 加脏工作区。
- v0.6 tag：`v0.6-beta` → `e6f25ae8cb4d9583aa3e629cb79416e278060117`。
- v0.6 验收 Zip：`releases/v0.6/LetsMakeMoney-v0.6-beta-windows-x86_64.zip`。
- Zip SHA256：`CECD3C3ABACFCB5EF594584E2AEB0E25C1824BAE97AB84B224073E7444E72615`。
- EXE SHA256：`749F18E35E757A250EDA8D3DE5B712BD554861082E33D607E1D07835AA943E3B`。
- native DLL SHA256：`AB57D3720FDDADA94397F2249C2827C43D1ADB0BDE3641BDC91AFD8AFCEFF696`。

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
- 当前树公开准备：不通过，阻塞项已转交 A1/A2/A3；仓库继续保持私有。
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
| 远端替换 | 已执行；fresh clone 复验通过，仓库继续保持私有 |

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

本页记录 A0-A3 的当前证据。A3 的秘密扫描通过不等于仓库可以公开；历史披露、B/C/E 工程门禁和独立 Acceptance 仍未关闭。本页也不将 v0.6 的“开机自启暂不验证”改写为通过。
