# LetsMakeMoney iOS v0.1 Beta 开发日志

> 本文记录开发过程、关键决策、异常处理和验证结果。它不替代 `progress_ios-v0.1.md`；progress 只保留状态看板和最小任务 checklist。

## 基本信息

- 版本：`ios-v0.1-beta`
- 目标分支：`ios-main`（独立 worktree，尚未推送）
- 对应 PRD：`doc/releases/ios-v0.1/prd.md`
- 对应 dev plan：`doc/releases/ios-v0.1/dev_plan_ios-v0.1.md`
- 对应 progress：`doc/releases/ios-v0.1/progress_ios-v0.1.md`
- 对应原型：`doc/prototypes/ios-v0.1/index.html`
- 当前阶段：M0 部分通过，等待 iPad Swift Playgrounds 人工补证

## 开发记录

### 2026-07-13 M0 基线、分支与可行性

- 从 `main` 的 `5c302efcc2edb868231c4c4d9f002e8355e03001` 创建 `ios-main`，使用独立工作区 `E:\codex\LetsMakeMoney-ios`；原工作区及其未跟踪内容未被覆盖或删除。
- 锁定 Windows v0.7 便携 Zip 身份：44,157,654 字节，SHA256 为 `16F47A844EFD78D387E9D08FBCD3DE76C8C8BDD518731C1B0BA022E7F598121F`；Apple 开发不得修改或重新包装该产物。
- 建立 `apple/`、`shared/salary-schema/v1/` 与 `scripts/apple/` 的目录职责、Target 边界和迁移合同。
- 建立无秘密的标识符模板；真实 Team ID、证书、描述文件和本地标识配置不得提交。
- 冻结最低系统版本与工具链策略，但没有伪造本机不可取得的 Xcode、SDK 或 Swift build version。
- 明确 Playgrounds 只作为 App 与纯 Swift 模块的早期验证入口；未来 Xcode workspace 直接引用同一份 `SalaryCore` 源码，不维护第二套业务实现。
- 新增 Windows PowerShell 5.1 可运行的 M0 检查器及反例测试。初版因乱码字面量和旧 .NET 缺少 `Path.GetRelativePath` 失败，改为 Unicode 码点标记和根路径前缀截取后通过。
- Windows v0.7 基线与文档状态检查通过；M0 检查器真实项目、干净夹具、绝对路径反例及缺失文件反例均符合预期。
- 当前结论：G0 通过；G2 等待 iPad 真机补证；G1、G3、G4 尚未取得，不写为通过。M0 完成度 9/10。

### 2026-07-13 开发承接

- 本轮目标：把已确认 PRD 和交互原型拆解为可执行实施计划与最小任务。
- 改动模块：仅文档、原型状态和追踪关系；未修改 Windows 或 Apple 业务代码。
- 关键处理：
  - 建立 M0-M7 八个里程碑和 G0-G5 环境/发布门禁。
  - 明确 M0/M1 可在当前环境先推进，M4-M7 受 macOS/Xcode、签名和真机门禁约束。
  - 约定 Apple 实现位于 `apple/`，跨端共享仅限 schema、测试向量和算法契约。
  - 将 14 条 FR 映射到实施里程碑与验收入口。
- 已验证：交互原型桌面/移动视口无溢出和控制台错误，核心按钮均可操作。
- 未验证/待补证：iPad Swift Playgrounds 能力、Swift 编译、Xcode 多 Target、App Group、Activity、Watch 与真实设备。
- 关联 bugfix/spike：后续 M0 需要 iPad Playgrounds 与 macOS/Xcode 环境 Spike。

## 关键决策

| 决策 | 背景 | 取舍 | 影响范围 | 后续观察 |
| --- | --- | --- | --- | --- |
| 使用独立 `ios-main` 分支 | 避免 Apple 与 Windows 版本混淆 | 保留同仓库历史与共享契约，分支隔离实现 | Git、文档、发布 tag | M0 创建前确认脏工作区处理 |
| Apple 实现统一放入 `apple/` | 降低跨产品线理解成本 | 不复用 Godot UI/native，只共享数据契约 | 目录、构建、贡献文档 | M0 固定 workspace 结构 |
| 完整首版分阶段实现 | App、Widget、Activity、Watch 均为版本门禁 | 先内核/App，再系统扩展和 Watch | 全版本 | 不因环境不足缩写为“已完成” |
| 无 Mac 时不伪造构建证据 | 当前只有 Windows、iPad/iPhone/Watch | 可先做契约和纯模块，后续取得 Xcode 环境 | M0-M7 | G3/G4 继续保持阻塞或待补证 |
| 不预埋加班字段 | 加班已延后 iOS v0.2 | 依靠 schema 版本扩展，而非提前污染配置 | FR-014、配置模型 | v0.2 重新进入 PRD |

## Bugfix 摘要

暂无。明确缺陷出现后记录到 `doc/logs/bugfix_log_ios-v0.1.md`。

## Spike / 技术探索摘要

| 主题 | 当前结论 | 是否进入本版本 | 后续动作 |
| --- | --- | --- | --- |
| iPad Swift Playgrounds | 仅 PRD 级可行性，尚无真实项目证据 | 是，作为阶段一门禁 | M0 真机验证并记录迁移边界 |
| macOS/Xcode 获取方式 | 当前无本地环境 | 是，属于完整 Beta 前置 | M0 比较云 Mac、借用或后续购置，不提前付费 |

## 验证摘要

- 自动化验证：交互原型、Windows v0.7 基线、文档状态及 M0 合同检查通过；尚无 Swift/Xcode 自动化。
- 手动验证：原型由项目所有者确认整体方向和底部导航位置。
- 打包验证：尚未开始。
- 未覆盖项：所有 Apple 原生实现、签名、系统扩展和真实设备行为。

## 收尾事项

- 文档同步：PRD 状态、追踪矩阵、dev plan、progress 与本日志已建立关联。
- 发布说明：尚未开始。
- 回滚方式：开发承接仅修改文档；若计划需调整，回退对应文档，不影响 Windows 业务代码。
- 下一阶段建议：确认开发承接后，仅执行 IOS01-M0。
