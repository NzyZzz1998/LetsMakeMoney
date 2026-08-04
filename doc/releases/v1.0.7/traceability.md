# LetsMakeMoney Windows v1.0.7 需求追踪矩阵

## 1. 使用说明

本矩阵连接 Review、项目所有者观察、Idea、正式需求、原型和验收门禁。`条件`表示只有 Spike 通过才实施；`基线`表示保留历史事实但不重复开发。

## 2. FR 与 IDEA 追踪

| FR | IDEA | REV | OBS | 原型入口 | 自动门禁 | GUI/人工门禁 |
| --- | --- | --- | --- | --- | --- | --- |
| FR-001 | IDEA-001 | REV-002 | — | 无 UI | current gate 自检、误用负向测试 | 不适用 |
| FR-002 | IDEA-002 | REV-003 | — | Settings 保存失败态 | v8 四层合同、迁移测试 | 旧配置读取与保存 |
| FR-003 | IDEA-003 | REV-008 | — | Settings 数据与支持 | 版本六点一致性 | 关于页、更新检查 |
| FR-004 | IDEA-004 | — | OBS-001 | Mini | window policy 行为测试 | 冷启动置顶 |
| FR-005 | IDEA-005 | REV-004 | OBS-002 | Mini → Workbench | visibility lease 组合测试 | 打开、关闭、失败补偿 |
| FR-006 | IDEA-006 | — | OBS-003 | Mini 左/右停靠 | 10,000 随机序列 | 30 次真实贴边 |
| FR-007 | IDEA-007 | — | OBS-006 | 今日页“调整今天” | 共享事务 reducer/service | 应用、取消、关闭、失败 |
| FR-008 | IDEA-008 | — | OBS-004 | 日期加班弹窗 | overtime 仓储/精度/损坏测试 | 新建、修改、删除、重启 |
| FR-009 | IDEA-009 | — | OBS-005、OBS-007 | 日历与月度总结 | 聚合公式、5/6 周布局 | 三 DPI 一屏可见 |
| FR-010 | IDEA-010 | — | OBS-008 | Settings Combobox | 键盘、ARIA、翻转 | 焦点、读屏、DPI |
| FR-011 | IDEA-011 | — | OBS-009 | 窗口表面对照 | 截图像素摘要 | 四窗口四角审查 |
| FR-012 | IDEA-012 | — | OBS-010 | 拖动/隐私竖条 | move/finalize/recover | 出屏、找回、DPI |
| FR-013 | IDEA-013 | REV-005、REV-006 | — | 日期/加班/月总结 | 依赖方向、薄 command | 行为等价回归 |
| FR-014 | IDEA-014 | REV-007、REV-009、REV-011 | — | 无产品新增 UI | manifest、隐私与链接检查 | Win11 必须；Win10 补证或收窄 |
| FR-015 | IDEA-015 | REV-010 | — | 无 UI | 四类 IPC 成功/失败 fixture | 不适用 |
| FR-016 | IDEA-016 | REV-013 | — | 无 UI | lifecycle、调用图、误用失败 | 文档可执行性 |
| FR-017 | IDEA-017 | REV-012 | — | 全窗口回归 | CSP 资源/IPC/更新检查 | 条件启用后完整 GUI |
| FR-018 | IDEA-018 | REV-014 | — | Mini/Workbench | 10 次冷暖基线、阈值判断 | 首帧主观可用性 |

## 3. Review 完整覆盖

| 上游 | 结论 | 正式去向 |
| --- | --- | --- |
| V107-REV-001 | 主线曾分叉，现已对账 | `GATE-BASE-001`：开发前确认 main/origin 0/0，保护分支保留；不重复开发 |
| V107-REV-002 | CI 调用旧聚合脚本 | FR-001 |
| V107-REV-003 | config v8 与 Schema/defaults 漂移 | FR-002 |
| V107-REV-004 | desktop show/hide 错误语义混淆 | FR-005、FR-013、FR-015 |
| V107-REV-005 | 前端/Rust 编排集中 | FR-013 |
| V107-REV-006 | 结构门禁不能证明责任迁移 | FR-013 |
| V107-REV-007 | GUI 原始证据只在本机 | FR-014 |
| V107-REV-008 | 版本多点硬编码 | FR-003 |
| V107-REV-009 | current 历史膨胀 | FR-014、FR-016 |
| V107-REV-010 | IPC 字符串和泛型漂移风险 | FR-015 |
| V107-REV-011 | Windows 10/多显示器证据不足 | FR-014；Win10 补证或收窄，多显示器排除 |
| V107-REV-012 | CSP 为 null | FR-017 条件 Spike |
| V107-REV-013 | 版本脚本继承链 | FR-016 |
| V107-REV-014 | Bundle 体积缺少用户影响证据 | FR-018 条件测量 |

覆盖率：`14/14`。

## 4. 项目所有者观察完整覆盖

| 上游 | 真实问题 | 正式去向 |
| --- | --- | --- |
| V107-OBS-001 | 首次启动置顶不可靠 | FR-004 |
| V107-OBS-002 | Workbench 与 Mini 重叠 | FR-005 |
| V107-OBS-003 | Mini 自动隐藏偶发失效 | FR-006 条件修复 |
| V107-OBS-004 | 缺少按日加班 | FR-008 |
| V107-OBS-005 | 缺少月度工时总结 | FR-009 |
| V107-OBS-006 | 调整今天跳错页面 | FR-007 |
| V107-OBS-007 | 六周月份显示不全 | FR-009 |
| V107-OBS-008 | 原生下拉弹层视觉割裂 | FR-010 条件实现 |
| V107-OBS-009 | 窗口四角双层弧线 | FR-011 条件实现 |
| V107-OBS-010 | 拖动边缘闪影 | FR-012 |

覆盖率：`10/10`。

## 5. 数据追踪

| 数据对象 | 权威所有者 | 存储 | 版本 | 兼容 |
| --- | --- | --- | --- | --- |
| AppConfig | Rust config + v8 machine contract | `%APPDATA%\LetsMakeMoney\config.json` | 8 | 保留 v5-v7 migration |
| DateOverride | AppConfig `date_overrides` | config.json | 随 config v8 | v1.0.6 行为不变 |
| OvertimeRecord | 新 overtime repository | `%APPDATA%\LetsMakeMoney\overtime-records.json` | 1 | 缺失等于空；旧版忽略 |
| DashboardSnapshot | Rust domain/service | 内存与 IPC | fixture 版本随 v1.0.7 | 不改变现有收入公式 |
| EvidenceManifest | 发布/验收脚本 | 仓库内脱敏摘要 | 1 | 历史证据不改写 |

## 6. 状态与失败追踪

| 状态机 | 正常出口 | 失败出口 | 回滚 |
| --- | --- | --- | --- |
| Mini/Workbench lease | Workbench 可见、Mini 隐藏；关闭后恢复原状态 | show/hide 失败并可读反馈 | 恢复进入前 Mini 状态 |
| Mini 自动隐藏 | expanded ↔ retracted | fallback + 语义日志 | 保持展开可交互 |
| 日期调整 | saved/unchanged | failed + 保留草稿 | 旧 config 不变 |
| 加班记录 | created/updated/deleted/unchanged | failed/corrupt | 旧文件和最后有效记录不变 |
| 月度总结 | ready/stale | error + 独立重试 | 保留最后有效聚合 |
| Combobox | selected/closed | rejected Spike | 保留原生 select |
| 窗口表面 | accepted | rejected Spike | 回滚 v1.0.6 表面 |
| CSP | enabled | incompatible | 保持 `csp: null` 并记录风险 |
| 性能 | baseline accepted/optimized | 无阈值或优化无收益 | 不拆包或回滚优化 |

## 7. 开发前门禁

- [ ] 项目所有者确认 `prd.md`。
- [ ] 浏览器原型交互、主题、长内容和控制台验证通过。
- [ ] FR-006、010、011、017、018 的继续/停止阈值写入开发计划。
- [ ] `main` 与 `origin/main` 仍为 0/0；无业务代码变更混入 PRD 提交。
- [ ] 仅在以上条件满足后生成 `dev_plan_v1.0.7.md` 和 `progress_v1.0.7.md`。
