# LetsMakeMoney Windows v1.0.7 安全与性能条件门禁

## CSP 条件 Spike

隔离候选使用最小白名单 CSP，未包含 `unsafe-eval`。候选 Mini 页面可以建立文档，但首屏未完成主题和 Tauri bridge 初始化，IPC 与更新检查无法进入可验证状态。

| 项目 | 结果 |
| --- | --- |
| 隔离候选 EXE SHA256 | `6C61429F8615629D118AEC47D09355106AA002E58D3568BBACFFE3F2F0E97C09` |
| Mini document ready | 通过 |
| Theme ready | 未通过 |
| Tauri bridge ready | 未通过 |
| IPC/update probe | 未执行，bootstrap 不可用 |
| 失败代码 | `mini_bootstrap_unavailable` |
| 正式配置结论 | 撤销 CSP 候选，继续保持 `csp: null` |

本结论不是“CSP 已通过”。正式配置保持原状属于有记录的风险接受；后续重新尝试必须从隔离候选开始，并重新回归全部窗口、IPC、静态资源和更新链路。

## 性能基线

正式非 CSP Release 构建采集 10 次冷启动和 10 次暖启动，原始证据只保存在外部证据库；仓库保存脱敏聚合结果。

| 指标 | 阈值 | 结果 | 判定 |
| --- | ---: | ---: | --- |
| 冷启动 Mini P95 | 2,000 ms | 6,154 ms | 超阈值 |
| 暖启动 Mini P95 | 1,200 ms | 1,067 ms | 通过 |
| 冷启动 Workbench P95 | 1,500 ms | 6,527 ms | 超阈值 |
| 暖启动 Workbench P95 | 1,500 ms | 1,442 ms | 通过 |
| JS gzip | 180 KiB | 140,841 bytes | 通过 |
| 最大 WebView 长任务 | 100 ms | 0 ms | 通过 |

正式 EXE SHA256 为 `54A092546A1C2952A905B5788944E79D732FBDD8F4A6FD9AA2E7A23ABD0508D5`。

## 优化停止结论

冷启动超过阈值，因此执行了单点“跳过托盘初始化”诊断。结果没有达到至少 15% 的保留门槛，不能证明托盘是约 6 秒启动等待的根因；诊断代码已移除。

v1.0.7 不保留无收益的优化，也不宣称冷启动已达标。该问题记录为已量化性能债；暖启动、Bundle 和主线程长任务未触发进一步优化。

## 证据边界

- 外部 CSP 原始证据逻辑 ID：`V107-M6-CSP-RAW`。
- 外部性能原始证据逻辑 ID：`V107-M6-PERF-RAW`。
- 仓库摘要：`doc/releases/v1.0.7/evidence/m6-governance-security-performance.json`。
- 代码、依赖、Tauri 配置或候选 EXE 哈希变化后，CSP 与性能证据失效。
