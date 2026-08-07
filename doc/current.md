# LetsMakeMoney 当前状态

> 本文件只保留当前公开版本、当前开发阶段、支持边界和事实入口。历史结论由各版本 release 文档承接。

## 当前身份

| 字段 | 内容 |
| --- | --- |
| 当前公开版本 | Windows v1.0.7 Stable |
| 当前公开 tag | `v1.0.7` |
| v1.0.7 发布源提交 | `f500ed4e7de28ec68b2a848da6fa2340420b91b2` |
| 当前开发版本 | v1.0.F（公开版本固定为 v1.0.8） |
| 本地发布源 | `main@81abae364ad577a394c3c9dcda3a1d1c15e83b99` |
| 当前里程碑 | v1.0.F / v1.0.8 发布收口与最终候选重建 |
| 总体状态 | 锁定候选验收全部通过；`test` 已推送；尚未重建最终候选且未获发布授权，当前不可发布 |

v1.0.7 已从干净源提交构建、通过 current gate、候选包验证、真实 GUI 身份冒烟与 GitHub 下载包复核，并完成 GitHub Stable Release。正式便携 Zip SHA256 为 `D656B96973F64632896715ADCBB9CAFEAED4D06D44BA1C098824335AC673E3F2`，发布地址为 [GitHub Release v1.0.7](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.7)。此前 dirty 候选的首次失败、修复与 DPI 定向复验证据继续按历史事实保留，均不得冒充正式附件。

v1.0.F 是 v1.0 系列收官质量版本的内部代号，公开版本固定为 `v1.0.8`。发布源提交 `81abae364ad577a394c3c9dcda3a1d1c15e83b99` 生成的锁定候选 `V10F-20260804-final-81abae36` 已完成 M1-M7、候选身份、核心 GUI、浅深主题、Windows 11 单显示器 100%/125%/150% DPI 及通知区真实鼠标验收，结论为通过。候选 Zip SHA256 为 `07D9B1766CECE8DA092CE31C234E6018D4820049F3D2A310033478BF5EB69DDA`。当前 `test` 已推送至 `b691af76817e6b743a8207825629431ed8da14d2`；由于最终 README 更新晚于锁定候选，正式发布前必须从最终发布提交重新构建、更新哈希并复核包身份。尚未推送 `main`、创建 tag 或 GitHub Release，也未取得这些动作的单独授权，因此当前不可发布。

## v1.0.7 范围

- 统一 current CI、config v8、版本 metadata 与高风险 IPC 合同；
- 修复首次置顶、Mini/Workbench 显示事务、自动隐藏和窗口找回；
- 今日调整与日历日期调整共用事务；
- 按日期记录加班小时和费率快照，支持创建、修改、删除与跨月汇总；
- 月度总结展示计划工时、已流逝计划工时和加班工时；
- 收敛六周日历、Combobox、窗口圆角/阴影和自由拖动；
- 建立脚本生命周期、证据耐久、支持矩阵、CSP 与性能条件门禁。

不恢复宠物，不加入账号、云同步、安装器、自动更新、多平台、完整考勤、加班审批、主题扩展或技术栈重写。

## 支持边界

- 已验证环境：Windows 11 x86_64、单显示器、100%/125%/150% DPI。
- Windows 10：缺少真实设备或 VM 证据，不进入 v1.0.7 已验证支持声明。
- 多显示器：项目所有者确认暂不验证，不进入 v1.0.7 通过声明。
- 历史桌宠回退基线：`v0.9-beta` tag 与 Release；不进入当前产品主线。

完整矩阵见 [v1.0.7 支持矩阵](releases/v1.0.7/support-matrix.md)。

## 当前入口

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
