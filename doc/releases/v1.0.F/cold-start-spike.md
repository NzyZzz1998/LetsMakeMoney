# LetsMakeMoney Windows v1.0.F 冷启动条件 Spike

## 结论

`V10F-M6` 已完成 10 次冷缓存与 10 次暖缓存的前后对照。基线同时超过冷启动、Mini 首帧和 Workbench 首帧阈值，因此按 PRD 只执行了一次可回退的定向优化。

优化目标为启动阶段的 WebView2 能力探测。Tauri 已成功创建启动 WebView 后，旧实现仍串行启动最多三个 `reg.exe query`；这些子进程没有提供更强的能力证据，却在本机稳定增加约 5.9 秒。优化后直接使用“启动 WebView 已创建”这一进程内事实，不新增依赖，也不改变不支持 WebView2 时由 Tauri 负责的启动失败边界。

优化达到并明显超过 15% 保留门槛，予以保留。

## 测量合同

- 环境：Windows 11 x86_64，单显示器。
- 样本：冷缓存 10 次，暖缓存 10 次。
- 配置：确定性 v8 测试配置；采集器自动备份并恢复用户 `config.json` 与 `debug.log`。
- 采集：CDP 读取 Mini 与 Workbench 完整内容帧、首屏、资源和长任务。
- Bundle：生产 Vite 输出的全部 JavaScript 文件，使用 gzip 最优压缩测量。
- 源树：dirty 开发树，只能证明开发阶段性能，不构成 Release 候选身份。

阈值：

| 指标 | 阈值 |
| --- | ---: |
| 冷启动 P95 | 2,000 ms |
| Mini 首帧 P95 | 1,200 ms |
| Workbench 首帧 P95 | 1,500 ms |
| JS gzip | 180 KiB |
| 关键长任务 | 100 ms |
| 优化最低保留收益 | 15% |

## 前后对照

| 指标 | 优化前 | 优化后 | 改善 | 判定 |
| --- | ---: | ---: | ---: | --- |
| 冷缓存 Mini 完整帧 P95 | 6,217 ms | 861 ms | 86.151% | 通过 |
| 冷缓存 Workbench 完整帧 P95 | 6,589 ms | 1,211 ms | 81.621% | 通过 |
| 暖缓存 Mini 完整帧 P95 | 6,067 ms | 652 ms | 89.253% | 通过 |
| 暖缓存 Workbench 完整帧 P95 | 6,414 ms | 1,004 ms | 84.347% | 通过 |
| JS gzip | 144,751 bytes | 144,751 bytes | 0% | 通过 |
| 最大 WebView 长任务 | 0 ms | 0 ms | 0% | 通过 |

## 候选身份

| 对象 | SHA256 |
| --- | --- |
| 优化前 EXE | `E7549DD4AD267EA890DAB2847727CDDDDDBD1B41DC6FFC3074FD8BFFB0C123E2` |
| 优化后 EXE | `CDC691225683AE9270314D7A6D3F657880B847F1292525D528E4F7F3CBD0132D` |
| 优化前证据 | `7244C6E9C3719BD7D853A404EAAC03BB4D9F3AF15B72F7BAF206A1DBDABC8C94` |
| 优化后证据 | `421D9B3FF90FF05FC7C044DBC58232F5EA6F76D28373F3486F5C2012A9E7ED80` |

证据入口：

- `doc/releases/v1.0.F/evidence/m6-cold-start-performance-baseline.json`
- `doc/releases/v1.0.F/evidence/m6-cold-start-performance.json`

## 风险与回退

- 风险：平台诊断不再通过注册表枚举 WebView2 安装记录。
- 风险接受依据：该状态只在 Tauri `setup` 后建立，此时当前应用的 WebView 已创建；它描述的是当前进程能力，而不是系统安装清单。
- 回退：恢复 `platform::webview2_runtime_available` 的旧实现即可，不涉及配置、数据或 schema 迁移。
- 回归要求：Rust 测试、clippy、Mini/Workbench 启动、诊断摘要与 Windows 11 单显示器真实 GUI 验收必须继续通过。

## 停止结论

本轮只保留上述一项定向优化。优化后冷启动、Mini 首帧、Workbench 首帧、JS gzip 和长任务均未超过阈值，不再继续拆分 Bundle、延迟托盘或调整启动架构。M6 在此停止，剩余真实 DPI 和发布候选回归转交 M7 与独立验收。
