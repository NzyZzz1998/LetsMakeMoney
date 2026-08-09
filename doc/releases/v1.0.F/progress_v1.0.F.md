# LetsMakeMoney Windows v1.0.F 进度

## 当前状态

| 字段 | 内容 |
| --- | --- |
| 内部代号 | v1.0.F |
| 公开版本 | v1.0.8 Stable |
| 当前阶段 | v1.0 系列本地收官与 annotated tag 建立 |
| 总体结论 | 历史锁定候选验收通过；最终修正通过完整 current gate；仅创建本地 tag，不执行远端发布 |
| 本地收官身份 | annotated tag `v1.0.8`，指向本次收官提交 |
| 历史 Candidate ID | `V10F-20260804-final-81abae36`（不作为本次正式附件） |
| 当前公开版本 | v1.0.7 Stable |
| 最后更新 | 2026-08-09 |

## 里程碑

| 里程碑 | 状态 | 说明 |
| --- | --- | --- |
| M0-M6 | 已完成 | 范围、实现、治理与冷启动定向优化完成 |
| M7 聚合门禁 | 已完成 | current gate、候选身份和包体验证通过 |
| 独立 GUI 验收 | 已完成 | 业务、主题、窗口、隐私、三档 DPI 与托盘真实鼠标流程通过 |
| 本地收官 | 已完成 | 最终修正与完整 current gate 通过；本地 annotated tag 指向收官提交 |
| 远端发布 | 未授权 | 不推送 `main` 或 tag，不创建 GitHub Release |

## 当前清单

- [x] v1.0.8 有意实现已形成干净本地发布源提交。
- [x] 唯一候选已从干净提交生成并锁定哈希。
- [x] M1-M7、TypeScript、Vite、77 项 Rust 测试、fmt 和 clippy 通过。
- [x] 首次启动、Mini、Workbench、日期调整、加班和月度总结完成真实 GUI 验收。
- [x] 浅色/深色、Settings、Wizard、TimeField 和 Combobox 完成真实 GUI 验收。
- [x] Windows 11 单显示器 100%、125%、150% DPI 完成真实走查。
- [x] Windows 通知区左键/右键、任务栏策略和退出由项目所有者真实鼠标补证通过。
- [x] 用户原始 roaming/local 数据、注册表状态和 100% 显示缩放已恢复；候选进程为 0。
- [x] 隐私竖条可读性、宽度合同与日历紧凑布局完成最终修正。
- [x] 最终修正后 `verify_windows_current.ps1 -Milestone M7` 完整通过。
- [x] 项目所有者批准创建本地 annotated tag `v1.0.8`。
- [ ] 项目所有者单独批准远端推送与 GitHub Release。

## 阻塞与边界

- 生命周期规则保持不变：当前 dirty 工作区不得生成正式候选；本候选构建时发布源为 clean。
- 当前没有已确认的产品发布阻塞缺陷。
- 锁定候选的最终验收已通过，没有已确认的产品发布阻塞缺陷。
- 历史锁定候选早于最终收官提交，其哈希不得冒充本次收官提交的正式发布附件。
- Windows 10 无真实证据，只能声明尽力兼容。
- 多显示器暂不验证，不进入通过声明。
- 不恢复宠物，不扩展 v1.0.8 已冻结范围。
- 项目所有者已授权创建本地 annotated tag `v1.0.8`；仍禁止推送 `main`、推送 tag 或创建 GitHub Release。

## 证据入口

- 验证：`doc/releases/v1.0.F/verification.md`
- 手动验收：`doc/releases/v1.0.F/manual-verification.md`
- 发布检查：`doc/releases/v1.0.F/release-checklist.md`
- 自动摘要：`doc/releases/v1.0.F/evidence/m7-automation-summary.json`
- 本机原始 GUI 证据：验收临时目录（不进入发布包）
