# v0.7 发布许可检查清单

**当前状态**：最终候选 Acceptance 部分通过；存在发布阻塞，v0.7 尚未发布。

- [x] 项目 MIT、受限素材许可和资产清单存在。
- [x] 第三方人工/机器清单和原许可证原文存在。
- [x] 便携包与安装器的 `LICENSES/` 结构已定义。
- [x] 许可 staging 与包体验证脚本已建立。
- [x] v0.7 便携候选包实际包含并通过 `LICENSES/` 检查。
- [x] Inno Setup 版本已固定并通过安装器许可检查。
- [x] 完整 Git 历史与排除内容已通过 A3。
- [x] B1 固定依赖身份与 bootstrap 已通过。
- [x] B2/E3 选择的 GitHub Actions 已固定 commit 并登记许可。
- [ ] 安装器签名、更新、真实 Windows 验收和独立 Acceptance 已通过。

当前阻塞：`V07-BUG-001` Settings 保存失败提示不可见；测试安装器 `NotSigned`，不得作为附件。

任何未登记 DLL、字体、Action、依赖或缺失许可证均阻塞对应产物发布。
