# LetsMakeMoney 当前状态

> 本文件只保留当前公开版本、当前开发阶段、支持边界和事实入口。历史结论由各版本 release 文档承接。

## 当前身份

| 字段 | 内容 |
| --- | --- |
| 当前公开版本 | Windows v1.1.0 Stable（tag 发布，GitHub Release 待授权） |
| 当前公开 tag | `v1.1.0` |
| v1.1.0 发布候选源提交 | `642b0dd3cf5af5347aa9d9d92000f200eafb7850` 之后的发布事实收口提交 |
| v1.0 系列收官版本 | v1.0.F（版本号 `v1.0.8`） |
| 本地收官身份 | annotated tag `v1.0.8`，指向本次收官提交 |
| 当前开发候选 | v1.1.0 clean tag 基线 |
| 当前里程碑 | Classic 显示、Mini 贴边竞态与净化包哈希阻塞已关闭，tag 发布获批 |
| 总体状态 | 默认仍为 Mini，Classic 为用户显式选择且二者互斥；`Tag publication approved = true`，`GitHub Release approved = false` |

v1.0.7 已从干净源提交构建、通过 current gate、候选包验证、真实 GUI 身份冒烟与 GitHub 下载包复核，并完成 GitHub Stable Release。正式便携 Zip SHA256 为 `D656B96973F64632896715ADCBB9CAFEAED4D06D44BA1C098824335AC673E3F2`，发布地址为 [GitHub Release v1.0.7](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.7)。此前 dirty 候选的首次失败、修复与 DPI 定向复验证据继续按历史事实保留，均不得冒充正式附件。

Windows v1.1.0 已获项目所有者批准推送并创建 tag；GitHub Release 与附件上传尚未授权。旧 clean 候选 `V110-20260817T031659Z-71616e2e-clean` 已因三项新发现阻塞淘汰，不得作为发布附件。

v1.0.F 是 v1.0 系列收官质量版本的内部代号，版本号固定为 `v1.0.8`。历史锁定候选 `V10F-20260804-final-81abae36` 已完成 M1-M7、候选身份、核心 GUI、浅深主题、Windows 11 单显示器 100%/125%/150% DPI 及通知区真实鼠标验收，结论为通过；其 Zip SHA256 `07D9B1766CECE8DA092CE31C234E6018D4820049F3D2A310033478BF5EB69DDA` 仅作为当时候选证据保留，不代表本次收官提交的正式发布附件。最终隐私竖条与日历布局修正已通过完整 current gate。本次仅创建本地 annotated tag `v1.0.8`，不推送 `main` 或 tag，也不创建 GitHub Release；如后续决定公开发布，必须从该 tag 对应的干净提交重新构建、更新哈希并完成包体验证。

## v1.1.0 桌面陪伴回归候选

- 原内部代号 `pet-return` 已绑定当前开发候选 `v1.1.0`；公开版本不使用 Beta 后缀。
- 已完成产品合同、四域状态机、宠物包 vNext、首轮 Runtime/Quality Spike，以及正式主线中的 Mini/Pet 互斥、配置 v9、透明 WebView、动态命中和故障回落；Classic-only 本地产品候选已获项目所有者批准。
- `PetManager reduced-scope ready = true` 适用于 Classic 首轮 12 动作精简包；18 动作完整目录仍为 `PetManager full-catalog ready = false`。
- `Runtime Spike pass = true` 适用于 S1.9 技术运行时；当前 12 动作首轮包已完成三基础状态、状态化单击、500ms 拖拽与方向同步、隐藏恢复、100%/125%/150% DPI、动态命中、坏包、真实 Windows 睡眠恢复和最终两小时稳定运行，故 `LMM sandbox pass = true` 仅在该隔离首轮范围内成立。
- 首轮精简包包含 working 4 项、awake_rest 2 项、sleeping 3 项和 drag 3 项，共 12 动作、118 帧。`working` 只表示用户工作期间的安静陪伴；`working_pounce` 已退役，跑动三动作只用于长按拖拽。A2 的理毛与伸展因多肢、缺肢和身份漂移延后，四个业务事件动作继续阻塞；首轮业务边界直接切换权威基础状态。
- 隔离沙盒历史包 manifest SHA256 为 `73A722D022EB4138B5FA8F7469D5304F08DC026EB3CB98D480A9C56CAE911E0E`，package tree SHA256 为 `745AB4A26B4B149FC279686D9FA236384BDDF150DF2D18C2DBDA643A1A596A4E`；历史桌面候选 EXE SHA256 为 `2463940CA9AFC0BECD2DB9252F558315FA1AE1CA19CCB89BD480B27BABEB826B`，其 121 样本双心跳和两小时稳定性继续作为沙盒证据保留。
- 当前产品候选包为 `0.4.1-rc.1`，规范化 LF manifest SHA256 `8E0396EA5CC0E3D089D77E0739C25C2AC2142F69CFEC28F4D110804FB20901B4`，package tree SHA256 `5EAE933DA004EAC7BF8391DA78AA2A68DC9B5D773561E9B8C9CCBD372366519E`；状态为 `approved / ready:true / productReturnApproved:true / published:false`。
- 先导产品候选 EXE SHA256 为 `D1F4E8B006D0A2E0C7091313886CCA4EC3C03F52F51EAD2B19E8744AA7D56A88`，大小 `14,957,568` 字节。100% DPI 真实 GUI 已证明默认 Mini、Workbench 租约、Mini/Classic 互斥切换与持久化、桌宠可见渲染、状态单击、动态命中和左右拖拽链路；该 EXE 来自 dirty 工作树，只是先导证据，不是 v1.1.0 发布附件。
- 旧电脑夹具仅保留为 historical，不再是当前联调或产品素材。
- 当前默认行为仍为 Mini。旧配置和非法陪伴模式迁移到 Mini；Settings 允许用户显式选择 Classic，Mini 与 Pet 严格互斥，运行时或包故障自动回落 Mini。
- `PetManager ready`、`LMM sandbox pass`、`Product candidate approved`、`Tag publication approved` 与 `GitHub Release approved` 分层管理：前四层成立，GitHub Release 仍为 false。候选 `V110-20260817T031659Z-71616e2e-clean` 已因 `V110-BUG-003` 至 `V110-BUG-005` 淘汰；最终修复已进入 clean 主线。
- 事实入口：[桌宠回归沙盒 PRD](architecture/pet-return-prd.md) / [专项追踪矩阵](architecture/pet-return-traceability.md)。

## v1.0.7 范围

- 统一 current CI、config v8、版本 metadata 与高风险 IPC 合同；
- 修复首次置顶、Mini/Workbench 显示事务、自动隐藏和窗口找回；
- 今日调整与日历日期调整共用事务；
- 按日期记录加班小时和费率快照，支持创建、修改、删除与跨月汇总；
- 月度总结展示计划工时、已流逝计划工时和加班工时；
- 收敛六周日历、Combobox、窗口圆角/阴影和自由拖动；
- 建立脚本生命周期、证据耐久、支持矩阵、CSP 与性能条件门禁。

v1.0.7 原发布范围不恢复宠物，也不加入账号、云同步、安装器、自动更新、多平台、完整考勤、加班审批、主题扩展或技术栈重写；当前桌宠工作属于发布后的独立 `pet-return` 候选，不改写 v1.0.7 历史范围。

## 支持边界

- 已验证环境：Windows 11 x86_64、单显示器、100%/125%/150% DPI。
- Windows 10：缺少真实设备或 VM 证据，不进入 v1.0.7 已验证支持声明。
- 多显示器：项目所有者确认暂不验证，不进入 v1.0.7 通过声明。
- 历史桌宠回退基线：`v0.9-beta` tag 与 Release；不进入当前产品主线。

完整矩阵见 [v1.0.7 支持矩阵](releases/v1.0.7/support-matrix.md)。

## 当前入口

- [v1.1.0 发布前总览](releases/v1.1.0/README.md)
- [v1.1.0 验证记录](releases/v1.1.0/verification.md)
- [v1.1.0 手动验收](releases/v1.1.0/manual-verification.md)
- [v1.1.0 发布检查](releases/v1.1.0/release-checklist.md)

- [v1.0.F PRD](releases/v1.0.F/prd.md)
- [v1.0.F 追踪矩阵](releases/v1.0.F/traceability.md)
- [v1.0.F Idea Pool](releases/v1.0.F/idea-pool.md)
- [v1.0.F Review](releases/v1.0.F/review.md)
- [v1.0.F 进度](releases/v1.0.F/progress_v1.0.F.md)
- [v1.0.F 验证](releases/v1.0.F/verification.md)
- [v1.0.F 手动验收](releases/v1.0.F/manual-verification.md)

- [v1.0.7 PRD](releases/v1.0.7/prd.md)
- [v1.0.7 追踪矩阵](releases/v1.0.7/traceability.md)
- [v1.0.7 开发计划](releases/v1.0.7/dev_plan_v1.0.7.md)
- [v1.0.7 进度](releases/v1.0.7/progress_v1.0.7.md)
- [v1.0.7 验证](releases/v1.0.7/verification.md)
- [v1.0.7 手动验收](releases/v1.0.7/manual-verification.md)
- [v1.0.7 缺陷日志](logs/v1.0.7-bugfix-log.md)
- [v1.0.7 脚本生命周期](releases/v1.0.7/script-lifecycle.md)
- [v1.0.7 安全与性能门禁](releases/v1.0.7/security-performance-gates.md)
- [v1.0.7 脱敏证据](releases/v1.0.7/evidence/README.md)
- [v1.0.7 开发日志](logs/dev_log_v1.0.7.md)

当前唯一开发验证入口：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_windows_current.ps1
```

## 历史入口

| 版本 | 事实入口 |
| --- | --- |
| v0.9-beta 桌宠回退基线 | [v0.9 README](releases/v0.9/README.md) |
| v1.0 Stable | [v1.0 README](releases/v1.0/README.md) |
| v1.0.1 Stable | [v1.0.1 README](releases/v1.0.1/README.md) |
| v1.0.2 Stable | [v1.0.2 README](releases/v1.0.2/README.md) |
| v1.0.3 Stable | [v1.0.3 release notes](releases/v1.0.3/release-notes.md) |
| v1.0.4 Stable | [v1.0.4 release notes](releases/v1.0.4/release-notes.md) |
| v1.0.5 Stable | [v1.0.5 README](releases/v1.0.5/README.md) |
| v1.0.6 Stable | [v1.0.6 README](releases/v1.0.6/README.md) |
| v1.0.7 Stable | [v1.0.7 README](releases/v1.0.7/README.md) |

旧版完整 PRD、进度、验收、发布说明和 bugfix log 继续保留在对应 release 目录，不在本文件复述。
