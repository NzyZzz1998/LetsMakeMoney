# v0.7 公开与发布前检查清单

- [x] A-E 所有任务已完成或有获批的 Acceptance 边界。
- [x] 当前树、完整历史、资产与依赖合规扫描无 P0。
- [x] 中英 README 命令和版本事实一致。
- [x] v0.7 自动验证、历史回归、便携 Zip smoke 通过。
- [x] 候选 Zip 的 EXE/DLL/manifest/checksum/LICENSES 一致。
- [x] 未签名安装器已明确排除出本次 Release；未来仅在 Authenticode、发布者和 SmartScreen 补证后作为附件。
- [x] 真实托盘、纯桌宠任务栏、点击穿透与 DPI 有实机证据；多显示器暂不验证。
- [x] Private Vulnerability Reporting 已开启，`main` 要求 PR 和必要 CI，且禁止失败检查合并。
- [x] 候选树和产物不含用户配置、日志、缓存、私钥、token 或本地证据。
- [x] `/acceptance` 已给出“通过 / 可发布”，允许 commit、push、tag 和便携 Zip Release。

`V07-BUG-001` 已关闭。真实通知区/任务栏、DPI 与显式删除数据已通过；签名、多显示器和干净 Windows 用户/VM 暂不验证且非版本阻塞。
