# LetsMakeMoney Windows v1.0.3 开发日志

> 本文记录开发过程、关键决策、异常处理和验证结果。它不替代 `progress_v1.0.3.md`。

## 基本信息

- 版本：Windows v1.0.3 Stable
- 对应 PRD：`doc/releases/v1.0.3/prd.md`
- 对应 dev plan：`doc/releases/v1.0.3/dev_plan_v1.0.3.md`
- 对应 progress：`doc/releases/v1.0.3/progress_v1.0.3.md`
- 开发基线：`main` / `27dc11421daa8289caf06d92c2f397d64c64c5df`
- 当前阶段：实现与自动门禁完成，独立 Acceptance 进行中

## 开发记录

### 2026-07-30：PRD 确认与开发承接

- 项目所有者确认 v1.0.3 完整 PRD，允许进入开发承接阶段。
- 本轮读取并交叉核对 Idea、性能 Spike、PRD、追踪矩阵、原型、Rust 日历加载、领域模型、Tauri 窗口策略、React Dashboard timer、测试和 v1.0.2 打包链。
- 已确认现状：
  - Rust 年度数据入口仍通过 `match 2025/2026` 硬编码，manifest 尚未成为资源发现的唯一事实源。
  - React Dashboard 的 1 秒 tick 和 30 秒权威同步只受 `document.visibilityState` 保护。
  - Tauri 原生 `hide()` 不会让现有 visibility 守卫生效，隐藏窗口继续同步。
  - 已有 wall/monotonic 跳变检测，没有独立的时区标识与 offset 变化合同。
  - 当前官方年度数据只有 2025、2026；本版不得创建虚假 2027 official 数据。
- 将实施拆为 M0-M6：
  - M0 冻结合同与失败测试；
  - M1 完成覆盖、估算与 stale；
  - M2 完成年度数据工具链；
  - M3 完成窗口生命周期；
  - M4 完成时间环境与稳定性准备；
  - M5 构建唯一候选；
  - M6 执行真实 Windows 和 120 分钟门禁。
- 本轮没有修改业务代码、版本号、构建产物、tag 或 Release。

### 2026-07-30：M0-M5 实现与候选预验收

- 日历覆盖模型已区分 official、estimated、stale 和 integrity error；不支持年份按用户休息模式估算，不伪造官方节假日或调休来源。
- Rust 年度数据加载改为由 manifest 驱动，构建、BUILD-INFO、打包与包体验证共用同一年度文件和 SHA256 事实源。
- Dashboard、日历和日期调整共用覆盖结果；估算年份仍允许手动工作日、带薪休息、不带薪休息和恢复自动。
- Tauri 隐藏与显示路径发送统一生命周期事件；隐藏 WebView 暂停本地 tick 和 30 秒权威同步，恢复后立即同步且不重复注册 timer。
- 时间环境样本新增 wall clock、monotonic、时区标识和 offset；自动夹具覆盖前后跳、时区变化、跨夜和估算年份。
- 聚合验证结果：年度日历 `11/11`、权威同步 `25/25`、生命周期 `8/8`、Rust `38/38`，历史版本回归、打包与包体验证通过。
- 验收候选来自当前脏工作树，Zip SHA256 为 `C87A4D6295061724638C7EA5E43E846126D369A1EAB60CDD365A8C786E63B51D`；该身份只用于 Acceptance，不能直接作为发布产物。

### 2026-07-30：独立 Acceptance 进行中

- 新解压候选已经验证 2026 官方日历、2027 估算日历、官方/估算年份日期调整、Settings 五页、隐藏配置收敛和真实 Windows 时区切换。
- 连续 10 次显示/隐藏得到 10 组 shown/hidden 与 paused/resumed 成对事件，未发现重复 timer。
- 真实时区切换至 Tokyo 后恢复 `China Standard Time`，阶段、owner date、日历和日志收敛。
- 系统时间修改被 Windows 权限拒绝；该结果只证明权限边界，不能写成业务通过。
- 原候选 120 分钟采样发现隐藏 Workbench 后连续高 CPU，已作为 `V103-BUG-001` 进入独立 bugfix log。
- 根因是 Tauri 隐藏窗口未挂起 WebView2 渲染器；第一版直接 `TrySuspend` 被 `0x8007139F` 拒绝，修正版在挂起前调用 `SetIsVisible(false)`，恢复后重新设为可见。
- 修正版 6 分钟受控复验、连续 10 次原生挂起/恢复和隐藏后 timer 唯一性均通过。
- 同一修正版候选连续运行 `7201.27` 秒；预热后进程树平均单核 CPU `0.3302%`、最大 `2.8137%`，无持续高 CPU，`V103-BUG-001` 关闭。
- 空配置首次启动 Wizard 已完成关闭确认、三步配置、保存和 Mini 显示全流程复验；保存后的配置与日志证据已冻结。
- 真实睡眠、系统时间跳变和通知区左键仍待项目所有者配合。

## 关键决策

| 决策 | 证据与原因 | 影响 | 回归保护 |
| --- | --- | --- | --- |
| unsupported 与 integrity error 分离 | 缺少官方年份可估算，数据损坏不可降级为估算 | Rust 错误枚举、React 状态、日志 | 失败矩阵和受控损坏 fixture |
| 估算不按年份单独缓存 | 估算依赖休息模式、大小周锚点和日期调整 | `model.ts` 缓存与配置更新 | 修改配置后结果必须立即变化 |
| stale 只保护同一目标月份 | 防止旧月份或旧年份结果误用 | Calendar/Dashboard 缓存 | late result 和月份隔离测试 |
| manifest 成为年度资源唯一事实源 | 当前 Rust 年份分支和包脚本重复维护 | 构建、Rust、打包、包验证 | 双向枚举、hash 和 BUILD-INFO |
| 只治理隐藏窗口生命周期 | Spike 没有证明共享状态重构收益 | Tauri 事件、React timer | 65 秒静默和 10 次循环 |
| 时间环境同时记录时区标识和 offset | 仅 wall-clock 检测可能漏掉时区变化 | `authoritativeSync.ts` 与验收 | 时区 fixture 和真实 Windows 补证 |
| 两小时证据只接受最终候选 | timer 生命周期将在本版变化 | Acceptance | 候选 hash 与证据绑定 |

## 继承证据

| 证据 | 结论 | 本版用途 |
| --- | --- | --- |
| `performance-spike.md` | 双窗口约产生 2.05 倍请求与日志；隐藏后仍继续 | FR-005 的问题基线 |
| v1.0.2 Stable 发布身份 | 收入、日历、主题、窗口和配置事务已通过 | M0/M5 历史回归 |
| 2025、2026 官方日历 | 当前唯一已验证官方年度数据 | FR-001/004 不可变夹具 |
| v1.0.3 原型 | official/estimated/stale/error 用户可见状态已确认 | M1 GUI 合同 |

## 验证摘要

- PRD 到 FR：`FR-001` 至 `FR-008` 完整。
- FR 到任务：已映射到 `V103-M0-001` 至 `V103-M6-012`。
- 当前实现与验收证据已完成两小时稳定运行和首次启动 Wizard；最终完成度以 `progress_v1.0.3.md` 的文档收口结果为准。
- 开发计划与 progress 任务身份：`62/62` 一致。
- 定向 UTF-8、乱码和本地链接检查：通过。
- 既有 v1.0-v1.0.2 文档状态检查：通过。
- `git diff --check`：通过。
- 自动测试、构建和验收候选：已执行并通过当前自动门禁。
- 真实 Windows 验收：进行中；已通过时区切换、日历覆盖、日期调整和窗口生命周期，未完成睡眠与系统时间跳变。

## 下一记录入口

完成睡眠恢复、系统时间跳变和通知区左键人工门禁后更新最终验收结论；若允许发布，再从干净提交重建并重新锁定全部哈希。

### 2026-07-30：Acceptance 文档收口

- 用户环境按验收前 manifest 恢复，7/7 文件大小与 SHA256 一致；时区恢复为 `China Standard Time`，候选进程为 0。
- v1.0.3 聚合验证、原生 WebView2 合同、Rust 38/38、历史版本回归和包体验证通过。
- v1.0.3 相关 18 份文档严格 UTF-8、乱码和本地链接检查通过；`git diff --check` 通过。
- 当前完成度 `58/62`；真实睡眠、系统时间、通知区左键和干净提交重建仍未完成，因此结论为部分通过、不可进入发布收口。
