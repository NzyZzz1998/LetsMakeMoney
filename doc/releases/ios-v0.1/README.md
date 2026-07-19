# LetsMakeMoney iOS v0.1 Beta 文档入口

本目录是 iOS v0.1 Beta 的版本入口。当前开发已完成 Windows 可验证范围和 GitHub macOS 无签名编译门禁，现暂停在 Mac、签名身份与 Apple 真机系统行为门禁。

## 推荐阅读顺序

1. [`mac-codex-handoff.md`](mac-codex-handoff.md)：Mac 上 Codex 的环境初始化、无签名门禁、安全边界和启动提示词。
2. [`status.md`](status.md)：当前状态、阻塞原因、恢复开发所需条件和下一步。
3. [`progress_ios-v0.1.md`](progress_ios-v0.1.md)：各里程碑最小任务与真实完成度。
4. [`prd.md`](prd.md)：产品范围、计算规则和验收口径。
5. [`dev_plan_ios-v0.1.md`](dev_plan_ios-v0.1.md)：实施顺序、风险、门禁和回退方式。
6. [`m4-device-verification.md`](m4-device-verification.md)、[`m5-device-verification.md`](m5-device-verification.md)、[`m6-device-verification.md`](m6-device-verification.md)：Mac 到位后的真机验证入口。

## 事实源分工

| 文档 | 负责内容 |
| --- | --- |
| `mac-codex-handoff.md` | Mac Codex 首轮执行命令、停止条件、签名与安全边界 |
| `status.md` | 当前阶段、阻塞、恢复条件和接手摘要 |
| `progress_ios-v0.1.md` | 完成度、待办、最近验证和下一步 |
| `prd.md` | 需求范围与产品验收标准 |
| `dev_plan_ios-v0.1.md` | 实施顺序、技术门禁与回退 |
| `doc/logs/dev_log_ios-v0.1.md` | 开发过程与技术决策 |

## 当前边界

- Windows 可以继续运行 SalaryCore、schema、静态合同、文档、本地化、隐私和原型门禁。
- GitHub macOS 已证明正式 App、Widget/Activity、Watch App 和 Watch Widget 可进行无签名 Simulator SDK 编译。
- 真实签名、App Group、WidgetKit、ActivityKit、WatchConnectivity、系统限流和设备体验必须在 Mac/Xcode 与真机环境中补证。
- M4、M5、M6 未完成真机项前，不进入 M7 候选归档与 Beta 发布。
