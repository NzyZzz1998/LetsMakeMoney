# v0.7 当前阶段摘要

**阶段**：主要实现与候选产物已完成，待独立 Acceptance
**仓库状态**：GitHub 已实际切换为 Public 并通过公共 API 核验；源码进入公开开发
**发布状态**：v0.7 便携候选包与未签名测试安装器已生成；未验收、未发布

## 已完成

- A0：冻结 Git、v0.6 发布身份、公开候选与排除边界。
- A1：MIT 代码许可、受限素材许可、资产清单和所有者签核。
- A2：第三方人工/机器清单、许可证原文、notices、`LICENSES/` 结构、staging 与检查脚本。
- A3：重写后当前树与全部可达提交的双专业秘密扫描、Git 对象/路径/资产审计和诊断隐私回归；P0 为 0。

## 当前阻塞

- 项目所有者选择的方案 3 已执行：远端 `main`、`test` 和 v0.2-v0.6 tags 已替换，fresh clone 的双扫描、公开候选和核心回归通过。项目所有者随后批准仓库先公开，B-E 作为公开后的 v0.7 工程与分发工作继续推进。
- B1 已完成固定 godot-cpp 获取、工具链锁定、在线/离线 bootstrap 和从零 Debug/Release 构建。
- Inno Setup 已固定为 6.7.3；测试安装器为 `NotSigned`，不得作为公开附件，真实证书与 SmartScreen 留待 Acceptance。
- v0.7 便携 Zip 已包含 `LICENSES/`、manifest 和 checksums，并通过解压启动 smoke。
- Windows Actions 已最小权限并固定第三方 Action commit；分支保护与 Private Vulnerability Reporting 仍需所有者在 GitHub 网页确认。
- 多平台、主题和宠物扩展规划已完成；平台优先级为 iOS、macOS、Android，v0.7 不实现这些能力。

## 事实入口

- 项目入口：`doc/current.md`
- A2 依赖清单：`doc/releases/v0.7/third-party-dependencies.md`
- 机器清单：`third_party/dependencies.json`
- 验证：`doc/releases/v0.7/verification.md`
- 公开门禁：`doc/releases/v0.7/public-readiness.md`
