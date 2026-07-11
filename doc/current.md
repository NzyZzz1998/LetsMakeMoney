# LetsMakeMoney 当前状态入口

**最后更新**：2026-07-11
**项目名**：LetsMakeMoney 赚钱模拟器  
**当前开发版本**：v0.7 Beta
**当前发布版本**：v0.6 Beta（GitHub Pre-release）
**当前分支**：`main`  
**当前 HEAD**：以远端 `main` 为准
**当前阶段**：v0.7 公开开发，继续推进工程、分发与社区治理
**当前里程碑**：V07-A0/A1/A2/A3 已完成；进入 V07-B1

本文件是人工或 agent 接手时的唯一当前状态入口。v0.7 实施以本文件和 `doc/releases/v0.7/` 为准；v0.6 文档是已发布基线和回归证据，不代表当前开发进度。

## 1. 身份边界

| 对象 | 身份 | 说明 |
|---|---|---|
| 当前 Git 树 | 远端 `main` | v0.7 公开开发事实源；不等于已发布 v0.7 产物 |
| v0.6 验收代码 | `main` / `77cef5cf...` | 生成并验收 v0.6 候选包时记录的代码身份 |
| v0.6 发布提交与 tag | 重写后 `v0.6-beta` | 历史发布基线；tag 已随历史清理安全重写 |
| v0.6 已验收 Zip | `releases/v0.6/LetsMakeMoney-v0.6-beta-windows-x86_64.zip` | 本地未跟踪产物；SHA256 为 `CECD3C3ABACFCB5EF594584E2AEB0E25C1824BAE97AB84B224073E7444E72615` |
| v0.7 开发候选 | 远端 `main` 后续提交 | 可公开协作；不得冒充 v0.7 已发布产物 |
| v0.7 发布候选 | 尚未形成 | 仍须完成对应工程、分发和独立 Acceptance 门禁 |

## 2. 当前目标与门禁

v0.7 的目标是让项目达到可安全公开、可复现构建、可贡献、可发布和可持续维护的状态。A0-A3 已关闭仓库公开所需的法律、历史、隐私和资产门禁；B-E 继续完善构建、分发、治理与验收。

- 代码采用 MIT；素材使用独立受限许可，许可文件与资产清单已经建立。
- Git 历史已完成清理、强制替换、双扫描与 fresh clone 复验。
- ComfyUI 本机资料、临时素材、私有验收证据、用户配置/日志、签名材料和本地发布展开目录不进入公开候选。
- v0.6 真实 Windows 登录后的开机自启仍是“暂不验证”，历史结论不得改写为通过。
- 仓库公开只代表源码协作入口开放；v0.7 tag、安装器、更新与 Release 仍须单独验收。

## 3. 推荐阅读顺序

1. [当前状态](current.md)
2. [v0.7 状态](releases/v0.7/status.md)
3. [v0.7 PRD](releases/v0.7/prd.md)
4. [v0.7 实施计划](releases/v0.7/dev_plan_v0.7.md)
5. [v0.7 进度](releases/v0.7/progress_v0.7.md)
6. [v0.7 公开准备](releases/v0.7/public-readiness.md)
7. [公开候选清单](releases/v0.7/public-candidate-manifest.md)
8. [公开排除清单](releases/v0.7/public-exclusions.md)
9. [v0.7 验证](releases/v0.7/verification.md)
10. [v0.6 发布基线](releases/v0.6/status.md)

## 4. 当前可信文档

- `doc/current.md`：当前项目事实入口。
- `doc/releases/v0.7/prd.md`：v0.7 已确认需求与范围。
- `doc/releases/v0.7/dev_plan_v0.7.md`：实施顺序、门禁和回退。
- `doc/releases/v0.7/progress_v0.7.md`：最小任务状态。
- `doc/releases/v0.7/status.md`：v0.7 阶段摘要。
- `doc/releases/v0.7/public-readiness.md`：公开准备门禁状态。
- `doc/releases/v0.6/verification.md`：v0.6 已发布基线验收证据。

## 5. 历史与本地资料

- `doc/releases/v0.1/` 至 `doc/releases/v0.6/`、历史总 PRD/plan/progress：只作为历史参考或回归证据。
- `.manual-test/`、`.tmp_acceptance/`、`releases/v0.6/`：本地私有证据或发布产物，不属于源码公开候选。
- `temp/`、`experiments/`：当前仍有已跟踪内容，是否公开必须由 V07-A1/A2/A3 逐项审计，不能仅靠 `.gitignore` 排除。

## 6. 下一步

进入 V07-B1，固定 Godot/godot-cpp 与 Windows 工具链身份，建立可复现 bootstrap 和干净环境构建。多平台路线仅做规划，优先级为 iOS、macOS、Android。
