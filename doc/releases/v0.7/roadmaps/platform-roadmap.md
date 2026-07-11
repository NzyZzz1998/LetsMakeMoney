# LetsMakeMoney 多平台路线规划

**状态**：v0.7 规划完成
**实现边界**：v0.7 只做规划，不实现任何非 Windows 客户端
**平台优先级**：iOS > macOS > Android

## 1. 决策

项目所有者确认 iOS 为未来多平台工作的最高优先级。该优先级用于安排研究、产品形态验证和后续 `/idea`，不构成发布日期或 v0.7 实现承诺。

| 优先级 | 平台 | 当前目标 | v0.7 是否开发 |
|---:|---|---|---|
| P0 | iOS | 先确认移动端产品形态、后台限制、Widget/Live Activity 可行性、签名与 App Store 边界 | 否 |
| P1 | macOS | 评估与 Windows 桌宠体验最接近的窗口、菜单栏、签名与公证路径 | 否 |
| P2 | Android | 评估悬浮窗、前台服务、触控交互和商店政策 | 否 |

## 2. iOS 优先研究范围

1. 桌面桌宠无法原样迁移时，比较 Widget、Live Activity、锁屏组件和应用内陪伴四种替代形态。
2. 核对 Godot iOS 导出、原生插件、签名、Provisioning Profile 和 App Store 审核要求。
3. 明确后台运行、持续动画、透明悬浮窗和跨应用覆盖的系统限制。
4. 评估工资计算、配置、日志与诊断在 iOS 沙盒中的数据边界。
5. 形成独立 iOS `/idea` 前，不修改当前 Platform 接口或加入移动端条件分支。

## 3. 后续平台

- macOS：重点研究透明无边框窗口、菜单栏、点击穿透、登录项、签名和公证。
- Android：重点研究悬浮窗权限、前台服务、通知、触控拖拽和应用商店政策。

## 4. 能力矩阵

| 能力 | iOS | macOS | Android |
|---|---|---|---|
| 桌面常驻形态 | 不支持 Windows 式跨应用透明桌宠；优先 Widget、Live Activity、锁屏与应用内陪伴 | 可研究透明无边框窗口与菜单栏 | 需悬浮窗权限与前台服务，商店政策风险较高 |
| 后台运行 | 受系统预算严格限制，不能承诺持续动画 | 登录项与普通后台应用可行，需节能约束 | 依赖前台服务与通知 |
| 原生扩展 | Swift/Objective-C Godot 插件、签名与 Provisioning | Objective-C++/Swift、签名与公证 | Kotlin/Java 插件、权限与生命周期 |
| 配置目录 | 应用沙盒 Documents/Application Support | Application Support | 应用私有存储 |
| 分发门禁 | App Store 审核、隐私清单、签名 | Developer ID、公证、Gatekeeper | 商店政策、权限说明、签名 |

未来 Platform 接口应继续按“能力查询 + 明确降级”设计，但 v0.7 不为尚未验证的平台预先增加代码分支。iOS 候选形态确认后才进入独立 `/idea` 和原型验证。

## 5. v0.7 非目标

- 不创建 iOS、macOS 或 Android 工程。
- 不修改 Godot 导出配置、Platform 接口或 native DLL。
- 不承诺平台版本号和发布日期。
- 不把规划完成标记为平台能力已经支持。

## 6. 完成条件

V07-D1 后续任务需要分别形成三平台的能力矩阵、产品形态、技术阻塞、许可/商店边界和候选后续版本，并通过项目所有者评审。
