# LetsMakeMoney Windows v1.0.8 发布检查
> 状态：v1.0 系列本地收官完成；本地 annotated tag 已获授权，远端发布仍未授权。

## 代码与身份

- [x] 生命周期规则已复核：不得从 dirty 工作区发布；本候选来自 clean 发布源。
- [x] v1.0.8 有意变更已形成本地发布源提交。
- [x] 发布源工作树在构建时干净。
- [x] npm、Cargo、Tauri、应用可见版本、README 与更新检查均为 `1.0.8`。
- [x] current manifest 与 required CI 使用唯一 current 入口。

## 自动门禁

- [x] `scripts/verify_windows_current.ps1 -Milestone M7` 通过。
- [x] TypeScript strict、Vite、Rust test/fmt/clippy 通过。
- [x] v1.0.8 package candidate 正负 fixture 与身份复核通过。
- [x] 文档、UTF-8、乱码和 `git diff --check` 通过。
- [x] 降级文本扫描未发现明显敏感信息；未宣称专业秘密扫描能力。
- [x] 最终隐私竖条与日历布局修正后完整 current gate 通过。

## 候选与包体

- [x] `scripts/package_v10f.ps1` 从干净提交生成唯一候选。
- [x] `scripts/verify_v10f_package.ps1 -Mode candidate` 通过。
- [x] Zip、EXE、DLL、README、BUILD-INFO 与 SHA256SUMS 身份已锁定。
- [x] 包内无配置、日志、截图、验收证据、缓存或临时目录。

## 独立验收

- [x] Windows 11 单显示器 100%、125%、150% DPI 通过。
- [x] 加班动态上限、周末联动、迁移、删除和月度统计通过。
- [x] Mini/Workbench、隐私贴边、窗口恢复和主题持久化通过。
- [x] 浅色/深色、TimeField、Combobox、Wizard 和 Settings 通过。
- [x] Windows 通知区左键/右键、任务栏策略和退出由项目所有者真实鼠标补证通过。
- [x] 用户环境已恢复，无候选进程或测试配置残留。
- [x] Windows 10 未验证时收窄支持声明；多显示器标记暂不验证。

## 历史锁定候选产物

- Zip：`LetsMakeMoney-v1.0.8-windows-x86_64.zip`
- Zip SHA256：`07D9B1766CECE8DA092CE31C234E6018D4820049F3D2A310033478BF5EB69DDA`
- EXE SHA256：`8D2ABDB6EB1E32F8B568BA9E12A2BAD0A52A9099B19C6CF7CEE3A040FF71ED3B`
- WebView2Loader.dll SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`

以上哈希属于早于本次收官提交的历史验收候选，不得作为 `v1.0.8` 收官 tag 的正式发布附件。若后续公开发布，必须重新构建并生成新的锁定哈希。

## 发布授权

- [x] 项目所有者已批准将候选资料推送到 `test` 分支复核。
- [x] 项目所有者已批准创建本地 annotated tag `v1.0.8`。
- [x] 本地 tag `v1.0.8` 指向 v1.0 收官提交。
- [ ] 从包含最终 README 的发布提交重新构建候选，并更新 Zip、EXE、DLL、README 与校验文件哈希。
- [ ] 对重建候选复跑 current gate、candidate 包体验证和受影响的身份冒烟。
- [ ] 项目所有者单独批准推送 `main`、tag 与 GitHub Release。
- [ ] Release 只上传便携 Zip 与 `SHA256SUMS.txt`。
- [ ] GitHub 附件重新下载后，published 模式验证与 SHA256 一致。

未勾选项完成前不得创建公开 Release。当前仅允许保留本地 annotated tag；不得推送 `main`、tag 或 Release 附件。
