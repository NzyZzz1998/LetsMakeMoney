# v0.7 公开与发布前检查清单

- [ ] A-E 所有任务已完成或有明确 Acceptance 边界。
- [ ] 当前树、完整历史、资产与依赖合规扫描无 P0。
- [ ] 中英 README 命令和版本事实一致。
- [ ] v0.7 自动验证、历史回归、便携 Zip smoke 通过。
- [ ] 候选 Zip 的 EXE/DLL/manifest/checksum/LICENSES 一致。
- [ ] 安装器仅在 Authenticode、发布者、SmartScreen 和人工安装/卸载通过后作为附件。
- [ ] 真实托盘、纯桌宠任务栏、点击穿透、DPI、多显示器有实机证据。
- [ ] Private Vulnerability Reporting 与必要分支保护由所有者确认。
- [ ] 候选树和产物不含用户配置、日志、缓存、私钥、token 或本地证据。
- [ ] `/acceptance` 给出“通过 / 可发布”后才允许 commit、push、tag 和 Release。
