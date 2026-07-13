# v0.7 当前阶段摘要

**阶段**：最终 Acceptance 通过；进入 v0.7 Beta 发布收口
**仓库状态**：GitHub 已实际切换为 Public 并通过公共 API 核验；源码进入公开开发
**发布状态**：便携 Zip 可发布；未签名安装器禁止公开附件

## 已完成

- A0：冻结 Git、v0.6 发布身份、公开候选与排除边界。
- A1：MIT 代码许可、受限素材许可、资产清单和所有者签核。
- A2：第三方人工/机器清单、许可证原文、notices、`LICENSES/` 结构、staging 与检查脚本。
- A3：重写后当前树与全部可达提交的双专业秘密扫描、Git 对象/路径/资产审计和诊断隐私回归；P0 为 0。

## 当前门禁

- 项目所有者选择的方案 3 已执行：远端 `main`、`test` 和 v0.2-v0.6 tags 已替换，fresh clone 的双扫描、公开候选和核心回归通过。项目所有者随后批准仓库先公开，B-E 作为公开后的 v0.7 工程与分发工作继续推进。
- B1 已完成固定 godot-cpp 获取、工具链锁定、在线/离线 bootstrap 和从零 Debug/Release 构建。
- Inno Setup 已固定为 6.7.3；测试安装器为 `NotSigned`，不得作为公开附件。真实证书与 SmartScreen 暂不验证，不阻塞便携 Zip 和 v0.7 收口。
- v0.7 便携 Zip 已包含 `LICENSES/`、manifest 和 checksums，并通过解压启动 smoke。
- Windows Actions 已最小权限并固定第三方 Action commit；`Protect main` 和 Private Vulnerability Reporting 已由项目所有者启用并取证。
- 多平台、主题和宠物扩展规划已完成；平台优先级为 iOS、macOS、Android，v0.7 不实现这些能力。
- Settings 保存失败反馈已移入固定底部操作栏；新候选包真实故障注入证明提示可见、输入保留、旧配置未污染，`V07-BUG-001` 已关闭。
- 真实通知区左键、普通/纯桌宠任务栏策略、125%/150%/200% DPI 与显式删除数据已通过实机验收。多显示器、干净 Windows 用户/VM、Authenticode/SmartScreen 暂不验证，均不得写为通过。

## 事实入口

- 项目入口：`doc/current.md`
- A2 依赖清单：`doc/releases/v0.7/third-party-dependencies.md`
- 机器清单：`third_party/dependencies.json`
- 验证：`doc/releases/v0.7/verification.md`
- 公开门禁：`doc/releases/v0.7/public-readiness.md`
