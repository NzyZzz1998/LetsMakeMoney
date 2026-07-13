# v0.7 发布许可检查清单

**当前状态**：最终 Acceptance 通过；便携 Zip 可发布，未签名安装器排除出 Release。

- [x] 项目 MIT、受限素材许可和资产清单存在。
- [x] 第三方人工/机器清单和原许可证原文存在。
- [x] 便携包与安装器的 `LICENSES/` 结构已定义。
- [x] 许可 staging 与包体验证脚本已建立。
- [x] v0.7 便携候选包实际包含并通过 `LICENSES/` 检查。
- [x] Inno Setup 版本已固定并通过安装器许可检查。
- [x] 完整 Git 历史与排除内容已通过 A3。
- [x] B1 固定依赖身份与 bootstrap 已通过。
- [x] B2/E3 选择的 GitHub Actions 已固定 commit 并登记许可。
- [x] 更新、真实 Windows 产品验收和便携包门禁通过；签名暂不验证，未签名安装器排除出 Release。
- [x] GitHub `main` 必要检查/分支保护和 Private Vulnerability Reporting 已启用并取证。
- [x] 独立 Acceptance 最终签核为“通过 / 可发布”。

`V07-BUG-001` 已关闭；测试安装器仍为 `NotSigned`，不得作为附件。签名不阻塞便携 Zip 和版本收口。

任何未登记 DLL、字体、Action、依赖或缺失许可证均阻塞对应产物发布。
