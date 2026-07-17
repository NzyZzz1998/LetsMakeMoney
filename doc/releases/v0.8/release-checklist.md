# LetsMakeMoney v0.8 Beta 发布检查清单

**当前状态**：最终验收通过，Windows x86_64 便携 Zip 已发布

- [x] `project.godot` 版本为 `0.8-beta`。
- [x] v0.8 完整回归通过。
- [x] 文档、许可、UTF-8、乱码和公开候选检查通过。
- [x] 候选 Zip 由候选源码提交 `08f7820bfd95ff56132eb87eb9255078adb9572a` 生成。
- [x] Zip、EXE、DLL SHA256 已记录。
- [x] 包内 README、发布说明、许可、manifest 和 checksums 完整。
- [x] 新解压候选包 smoke 通过。
- [x] SignPath Foundation 申请未获批准的事实已记录；便携 EXE 未签名、安装器不公开的边界已披露。
- [x] 新解压候选 EXE 已完成 Settings 五页、Wizard 四步、保存、无变化保存、重启持久化、右键菜单和点击穿透回归。
- [x] 工资与作息人工验收通过。
- [x] v0.7 核心桌面体验回归通过。
- [x] 单休、双休、大小周分别完成人工确认。
- [x] 午休时段 Panel 金额与进度冻结完成补测。
- [x] 休息日收入与当月工作日数量完成补测。
- [x] 真实通知区左键及普通/纯桌宠任务栏策略完成补测。
- [x] 最终 Acceptance 明确为“通过 / 可发布”。
- [x] PR #3 已通过必需 CI 并 squash 合并至 `main`，发布提交为 `a330d14230add1537b18c35c8ad38c6ae43430a2`。
- [x] annotated tag `v0.8-beta` 已创建并推送。
- [x] GitHub Pre-release 已创建，只包含便携 Zip 与 `SHA256SUMS.txt`。

发布地址：<https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.8-beta>

任何候选身份不一致、配置污染、工资计算错误或核心窗口回退都阻塞发布。

签名申请未获批准本身不阻塞便携 Zip Beta，但若后续计划公开安装器，必须先获得有效 Authenticode 证书并重新验收。
