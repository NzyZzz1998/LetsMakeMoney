# LetsMakeMoney v0.5 Beta 发布检查清单

**最后更新**：2026-07-09  
**当前结论**：通过 / 可发布  
**发布包**：`releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip`

## 1. 范围检查

- [x] v0.5 未新增主题系统。
- [x] v0.5 未新增安装器。
- [x] v0.5 未新增自动更新。
- [x] v0.5 未新增多平台发布。
- [x] v0.5 未新增更多宠物。
- [x] v0.5 未将 ComfyUI 正式产品化。
- [x] v0.5 范围聚焦 Settings / Wizard 共享控件、托盘恢复、纯桌宠策略、点击穿透保护、日志与文档收敛。

## 2. 自动验证

- [x] `.\scripts\verify_v05.ps1`
- [x] `.\scripts\verify_v04.ps1`
- [x] `.\scripts\verify_m4.ps1`
- [x] `.\scripts\verify_m5.ps1`
- [x] `.\scripts\check_docs_status.ps1`
- [x] `.\scripts\package_v05.ps1`
- [x] `.\scripts\verify_v05_package.ps1`

说明：`verify_v05.ps1` 返回通过，但 headless 输出仍可能出现 parser 文本。发布包烟测与实际 exe 验收已通过，脚本输出质量可进入 v0.6 优化。

## 3. 人工 / 实机验收

- [x] 实际运行发布包 exe。
- [x] Settings 保存成功反馈。
- [x] Settings 无变化保存反馈。
- [x] Settings 保存失败反馈。
- [x] Wizard 下一步日志。
- [x] Wizard 上一步日志。
- [x] Wizard 取消 / 关闭日志。
- [x] Wizard 完成日志。
- [x] Settings 打开期间点击穿透保护。
- [x] Wizard 打开期间点击穿透保护。
- [x] 托盘左键隐藏 / 恢复应用内同路径补证。
- [x] `pure_pet_mode=true` 恢复后不出现任务栏入口。
- [x] `pure_pet_mode=false` 恢复后任务栏入口正常出现。
- [x] `debug.log` 中关键语义事件可检索。

## 4. 发布产物检查

- [x] zip 包存在。
- [x] 展开目录存在。
- [x] `LetsMakeMoney.exe` 存在。
- [x] `letsmakemoney_native.dll` 存在。
- [x] `app_icon.ico` 存在。
- [x] `README.md` 存在。
- [x] `release-notes.md` 存在。
- [x] `manifest.json` 存在。
- [x] `checksums.txt` 存在。
- [x] 包验证脚本通过。

## 5. 文档检查

- [x] `doc/releases/v0.5/status.md` 已更新为“通过 / 可发布”。
- [x] `doc/releases/v0.5/verification.md` 已记录最终验收结果。
- [x] `doc/releases/v0.5/progress_v0.5.md` 已更新发布状态。
- [x] `doc/releases/v0.5/release-checklist.md` 已更新发布检查清单。
- [x] `releases/v0.5-beta-notes.md` 已更新发布说明。
- [x] `releases/CHANGELOG.md` 已更新 v0.5 条目。

## 6. 发布结论

v0.5 Beta 已通过发布前补证验收，可以进入提交、推送和 `v0.5-beta` tag 收口。
