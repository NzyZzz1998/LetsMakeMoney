# LetsMakeMoney Windows v1.0.8 验证记录

## 当前结论

开发实现完成，M1-M7 current gate 已通过。当前尚无可发布结论：工作区未提交且为 dirty，候选身份、真实 Windows GUI、三档 DPI 和独立验收仍未锁定。

## 候选身份

| 字段 | 当前值 |
| --- | --- |
| 开发基线 | `main@1801626a153a9644f448729dabc51ee9f88a0d9e` |
| 公开目标 | `v1.0.8` |
| Source tree | dirty |
| Candidate ID | 尚未生成 |
| Zip / EXE / DLL SHA256 | 尚未生成 |
| 发布许可 | 禁止 |

正式候选必须从项目所有者批准的干净提交重新构建。开发期 `target/release` EXE 与 M6 性能证据不能替代最终候选身份。

## 自动验证

| 范围 | 结论 | 证据 |
| --- | --- | --- |
| M1 版本、品牌与 current 合同 | 通过 | npm、Cargo、Tauri、L2 资产与 current manifest |
| M2 加班 schema v2 与事务 | 通过 | 迁移、动态边界、联动保存、失败回滚与兼容导出 |
| M3 加班和日期界面 | 通过 | 日历双击、周末联动、动态上限、创建/修改/删除与月度汇总 |
| M4 UI 与窗口质量 | 通过 | TimeField、Combobox、单一窗口表面、隐私竖条及行为测试 |
| M5 治理与支持边界 | 通过 | 浏览器预览边界、支持矩阵、证据、品牌和 v2 债务合同 |
| M6 冷启动条件 Spike | 通过并保留优化 | 冷启动 Mini `6217ms → 861ms`，收益 `86.151%` |
| M7 发布工程与聚合门禁 | 通过 | current manifest、candidate/published fixture、私密日志拒绝、TypeScript/Vite、77 项 Rust 测试、fmt、clippy 与 `git diff --check` |

自动化脱敏摘要：`evidence/m7-automation-summary.json`。该摘要记录的是 dirty 开发树门禁，不是正式候选验收结果。

## M6 性能证据

- 基线：`evidence/m6-cold-start-performance-baseline.json`。
- 优化后：`evidence/m6-cold-start-performance.json`。
- 根因：Tauri 已成功创建 WebView 后，启动路径仍同步运行多次 `reg.exe query` 探测 WebView2。
- 定向修复：Windows 运行时以已创建的 Tauri WebView 作为能力证据，不再重复执行注册表子进程。
- 未宣称：CPU 降低、内存泄漏修复或最终发布环境性能。

## 待验证

1. 从干净提交生成唯一候选并锁定 Zip、EXE、WebView2Loader、README 和 BUILD-INFO 哈希。
2. 真实 Windows 11 单显示器 100%、125%、150% DPI。
3. 浅色/深色、Mini、Workbench、Settings、Wizard、日期事务、加班事务、托盘与窗口找回。
4. 独立 `/acceptance` 和用户环境恢复。
5. Windows 10 无真实证据时继续收窄支持声明；多显示器暂不验证。
