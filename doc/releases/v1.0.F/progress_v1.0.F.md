# LetsMakeMoney Windows v1.0.F 进度

## 当前状态

| 字段 | 内容 |
| --- | --- |
| 内部代号 | v1.0.F |
| 公开版本 | v1.0.8 Stable |
| 当前阶段 | 发布收口与最终候选重建 |
| 总体结论 | 锁定候选自动门禁和 GUI 验收全部通过；`test` 已推送；正式发布仍待重建候选与单独授权 |
| 发布源 | `main@81abae364ad577a394c3c9dcda3a1d1c15e83b99` |
| Candidate ID | `V10F-20260804-final-81abae36` |
| 当前公开版本 | v1.0.7 Stable |
| 最后更新 | 2026-08-05 |

## 里程碑

| 里程碑 | 状态 | 说明 |
| --- | --- | --- |
| M0-M6 | 已完成 | 范围、实现、治理与冷启动定向优化完成 |
| M7 聚合门禁 | 已完成 | current gate、候选身份和包体验证通过 |
| 独立 GUI 验收 | 已完成 | 业务、主题、窗口、隐私、三档 DPI 与托盘真实鼠标流程通过 |
| 发布收口 | 进行中 | README 更新后需从最终提交重建候选并更新哈希 |
| 发布授权 | 未开始 | `main`、tag 和 Release 不得由本地验收自动触发 |

## 当前清单

- [x] v1.0.8 有意实现已形成干净本地发布源提交。
- [x] 唯一候选已从干净提交生成并锁定哈希。
- [x] M1-M7、TypeScript、Vite、77 项 Rust 测试、fmt 和 clippy 通过。
- [x] 首次启动、Mini、Workbench、日期调整、加班和月度总结完成真实 GUI 验收。
- [x] 浅色/深色、Settings、Wizard、TimeField 和 Combobox 完成真实 GUI 验收。
- [x] Windows 11 单显示器 100%、125%、150% DPI 完成真实走查。
- [x] Windows 通知区左键/右键、任务栏策略和退出由项目所有者真实鼠标补证通过。
- [x] 用户原始 roaming/local 数据、注册表状态和 100% 显示缩放已恢复；候选进程为 0。
- [ ] 项目所有者单独批准发布动作。

## 阻塞与边界

- 生命周期规则保持不变：当前 dirty 工作区不得生成正式候选；本候选构建时发布源为 clean。
- 当前没有已确认的产品发布阻塞缺陷。
- 锁定候选的最终验收已通过，没有已确认的产品发布阻塞缺陷。
- 最终 README 更新晚于锁定候选；正式发布前必须从最终发布提交重建候选、更新哈希并复核身份。
- Windows 10 无真实证据，只能声明尽力兼容。
- 多显示器暂不验证，不进入通过声明。
- 不恢复宠物，不扩展 v1.0.8 已冻结范围。
- 项目所有者已授权仅推送 `test` 分支用于发布前复核；仍禁止推送 `main`、创建远端 tag 或 GitHub Release。

## 证据入口

- 验证：`doc/releases/v1.0.F/verification.md`
- 手动验收：`doc/releases/v1.0.F/manual-verification.md`
- 发布检查：`doc/releases/v1.0.F/release-checklist.md`
- 自动摘要：`doc/releases/v1.0.F/evidence/m7-automation-summary.json`
- 本机原始 GUI 证据：验收临时目录（不进入发布包）
