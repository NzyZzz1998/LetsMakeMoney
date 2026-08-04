# LetsMakeMoney Windows v1.0.8 发布检查
> 状态：开发实现完成；候选、独立验收与发布授权未完成。

## 代码与身份

- [ ] 项目所有者确认全部有意变更并授权创建发布提交。
- [ ] 发布源工作树干净；不得从 dirty 工作区发布。
- [ ] npm、Cargo、Tauri、应用可见版本、README 与更新检查均为 `1.0.8`。
- [ ] current manifest 与 required CI 使用唯一 current 入口。

## 自动门禁

- [ ] `scripts/verify_windows_current.ps1` 在最终有意变更上通过。
- [ ] TypeScript strict、Vite、Rust test/fmt/clippy 通过。
- [ ] v1.0.8 package candidate/published 正负 fixture 通过。
- [ ] 文档、UTF-8、乱码、隐私、绝对路径和 `git diff --check` 通过。

## 候选与包体

- [ ] `scripts/package_v10f.ps1` 从干净提交生成唯一候选。
- [ ] `scripts/verify_v10f_package.ps1 -Mode candidate` 通过。
- [ ] Zip、EXE、DLL、README、BUILD-INFO 与 SHA256SUMS 身份已锁定。
- [ ] 包内无配置、日志、截图、证据、缓存、临时目录或未知二进制。

## 独立验收

- [ ] Windows 11 单显示器 100%、125%、150% DPI 通过。
- [ ] 加班动态上限、周末联动、迁移、失败回滚和月度统计通过。
- [ ] Mini/Workbench、隐私、拖动、窗口表面、托盘和找回通过。
- [ ] 浅色/深色、TimeField、Combobox、Wizard 和 Settings 通过。
- [ ] 用户环境已恢复，无候选进程残留。
- [ ] Windows 10 未验证时已收窄支持声明；多显示器标记暂不验证。

## 发布授权

- [ ] 项目所有者单独批准 commit、push、annotated tag 与 GitHub Release。
- [ ] Tag `v1.0.8` 指向锁定发布源提交。
- [ ] Release 只上传 `LetsMakeMoney-v1.0.8-windows-x86_64.zip` 与 `SHA256SUMS.txt`。
- [ ] GitHub 附件重新下载后，published 模式验证与 SHA256 一致。
