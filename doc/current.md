# LetsMakeMoney 当前状态

> 本文件只保留当前公开版本、当前开发阶段、支持边界和事实入口。历史结论由各版本 release 文档承接。

## 当前身份

| 字段 | 内容 |
| --- | --- |
| 当前公开版本 | Windows v1.0.6 Stable |
| 当前公开 tag | `v1.0.6` |
| v1.0.6 发布源提交 | `51e4c08da5260af9b9f4808c4f6d29591319e655` |
| 当前开发版本 | Windows v1.0.7 Stable |
| 开发基线 | `main@12b6b03ce91b716d49590e21eb8dd7fe90fa283c` |
| 当前里程碑 | V107-ACC 锁定 dirty 候选验收通过，项目所有者已批准发布收口 |
| 总体状态 | 验收通过，尚无可发布候选 |

v1.0.6 已完成 GitHub Stable Release，现有 tag、附件和哈希保持不变。v1.0.7 已完成 V107-M0 至 V107-M6，并完成 M7 的聚合门禁、隔离打包和 dirty 候选审计。首次独立 GUI 验收发现的版本读取、Workbench 复用超时和高 DPI 六周日历摘要重叠均已修复；`V107-M7-DIRTY-20260804-03` 的自动门禁、包体验证、真实 100%/125%/150% DPI、业务矩阵和托盘真实鼠标组合均通过，首次失败记录继续保留。项目所有者已批准提交、推送、tag 和 GitHub Release；当前进入干净发布提交、最终候选重建和身份复核，dirty 候选禁止发布。

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

旧版完整 PRD、进度、验收、发布说明和 bugfix log 继续保留在对应 release 目录，不在本文件复述。
