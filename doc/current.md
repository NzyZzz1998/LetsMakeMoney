# LetsMakeMoney 当前状态入口

**最后更新**：2026-07-11
**项目名**：LetsMakeMoney 赚钱模拟器  
**当前开发版本**：v0.6 Beta
**当前发布版本**：v0.6 Beta（Pre-release）
**当前分支**：`main`  
**当前阶段**：v0.6 Beta 已发布，进入发布后观察
**当前结论**：最终验收通过，无发布阻塞项；tag 为 `v0.6-beta`

本文件是后续人工或 agent 接手时的第一入口。先读这里，再进入 v0.6 专属文档；v0.5 文档只作为已发布基线与回归证据。

## 1. v0.6 版本目标

v0.6 是“发布后体验稳定与验证能力增强版”，主线包括：

- 默认日志口径、轮换和交互截图门控。
- 活跃验证脚本可信退出。
- 外部托盘 PostMessage 验收工具。
- 打开数据目录与复制脱敏诊断摘要。
- Settings/Wizard 事务、取消、关闭和失败恢复。
- 配置损坏恢复、恢复默认和开机自启专项验证。
- 菜单职责、点击穿透边界和有证据的有限体验精修。

不做主题系统、安装器、自动更新、多平台、更多宠物、动画素材大修或 ComfyUI 产品化。

## 2. 当前发布门禁

- 最终 Acceptance：通过。
- 发布阻塞项：无。
- 候选包身份、真实桌面操作、配置、日志、托盘和历史回归证据：已收口。
- 真实 Windows 登录后的开机自启：暂不验证，不得写为通过；作为 Beta 已知限制与发布后观察项披露。
- 发布提交、`main` 推送、Beta tag 和 GitHub Pre-release：已完成。

## 3. 推荐阅读顺序

1. [doc/current.md](current.md)
2. [doc/releases/v0.6/status.md](releases/v0.6/status.md)
3. [doc/releases/v0.6/progress_v0.6.md](releases/v0.6/progress_v0.6.md)
4. [doc/releases/v0.6/dev_plan_v0.6.md](releases/v0.6/dev_plan_v0.6.md)
5. [doc/releases/v0.6/prd.md](releases/v0.6/prd.md)
6. [doc/releases/v0.6/verification.md](releases/v0.6/verification.md)
7. [doc/releases/v0.6/release-notes.md](releases/v0.6/release-notes.md)
8. [doc/releases/v0.6/release-checklist.md](releases/v0.6/release-checklist.md)
9. [doc/prototypes/prototype-spec.md](prototypes/prototype-spec.md)
10. [doc/prototypes/index.html](prototypes/index.html)

## 4. 当前可信文档

| 文件 | 用途 |
|---|---|
| `doc/current.md` | 当前项目状态唯一入口 |
| `doc/releases/v0.6/prd.md` | v0.6 范围与验收事实源 |
| `doc/releases/v0.6/dev_plan_v0.6.md` | 实施顺序、影响文件和验证入口 |
| `doc/releases/v0.6/progress_v0.6.md` | v0.6 执行状态事实源 |
| `doc/logs/dev_log_v0.6.md` | 开发过程与技术决策，不代表完成度 |
| `doc/releases/v0.6/verification.md` | 自动与人工验证入口 |
| `doc/releases/v0.6/release-notes.md` | v0.6 用户价值、已知限制与回滚说明 |
| `doc/releases/v0.6/release-checklist.md` | 发布动作前的最终门禁与待授权事项 |
| `doc/prototypes/index.html` | 当前高保真交互原型 |
| `doc/releases/v0.5/verification.md` | v0.5 已验证回归基线 |

## 5. 发布产物状态

- v0.5 稳定基线：`releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip`
- v0.6 已验收候选包：`releases/v0.6/LetsMakeMoney-v0.6-beta-windows-x86_64.zip`。
- Zip 大小：`42,778,715` 字节。
- Zip SHA256：`CECD3C3ABACFCB5EF594584E2AEB0E25C1824BAE97AB84B224073E7444E72615`。
- 验收分支与 HEAD：`main` / `77cef5cf3f8dc39e695f12d03e12598aa7260fee`。
- v0.6 已通过 `v0.6-beta` tag 发布为 GitHub Pre-release；v0.5 继续作为回滚基线。
- `doc/releases/v0.6/` 只放版本文档；`releases/v0.6/` 只放真实产物。

## 6. 历史参考

- `doc/releases/v0.5/`：上一版本完整基线。
- `doc/releases/v0.4/` 与 `doc/verification/v0.1.md` 至 `v0.4.md`：历史版本。
- `doc/LetsMakeMoneyPRD.md`、`doc/implementation-plan.md`、`doc/progress.md`：历史总文档，不覆盖当前版本事实源。

## 7. 下一步

进入发布后 24 小时观察，重点记录启动、托盘找回、配置恢复、诊断摘要与真实登录开机自启反馈；如触发回滚条件，退回 v0.5 Beta。
