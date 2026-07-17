# LetsMakeMoney v0.8 Beta 验证记录

**当前结论**：最终验收通过，可发布 Windows x86_64 便携 Zip

**目标版本**：`0.8-beta`

**开发分支**：`feature/v0.8-salary-schedule`

## 自动验证

| 项目 | 结论 | 证据 |
|---|---|---|
| v0.8 工资与作息 | 通过 | `scripts/test_v08_salary_schedule.ps1` |
| v0.8 Settings 治理 | 通过 | `scripts/test_v08_settings_governance.ps1` |
| v0.8 完整回归 | 通过 | `scripts/run_ci_verification.ps1 -Suite main` |
| 文档与公开合规 | 通过，524 个候选文件，0 失败，0 警告 | `scripts/run_ci_verification.ps1 -Suite docs` |
| 候选包结构与 smoke | 通过 | `scripts/verify_v08_package.ps1` |

## 真实桌面验收

验收对象为新解压目录中的候选 EXE，不使用 `build/` 旧产物。验收时间为 2026-07-17，证据根目录为 `.tmp_acceptance/v0.8-20260717-151842/evidence/`。

| 范围 | 结论 | 证据摘要 |
|---|---|---|
| Settings 工资与作息保存 | 通过 | 月薪 10000、大小周、本周小周、09:00-18:00、午休 12:00-14:00、有效工时 7.0 小时成功保存 |
| 无变化保存与重启持久化 | 通过 | UI 显示“没有需要保存的更改”；重启后配置与界面保持一致 |
| Settings 五页与 Wizard 四步 | 通过 | 五个页签无裁切或乱码；Wizard 可前进至确认页并取消恢复 |
| Panel 与右键菜单 | 通过 | 金额随配置更新、菜单可用；项目所有者完成午休冻结补测 |
| 点击穿透保护 | 通过 | 日志存在成对的 `passthrough_suspended` / `passthrough_resumed` |
| 托盘显隐与纯桌宠恢复 | 通过 | 隐藏到托盘及进程存活通过；项目所有者完成通知区真实左键与任务栏策略补测 |
| 休息日日历 | 通过 | 项目所有者完成休息日收入与当月工作日数量补测 |
| 运行日志 | 通过 | 保存、无变化、Wizard 步骤/取消、窗口显隐及点击穿透事件完整，未见本轮 parser/runtime 红错 |

验收结束后已退出候选进程，并恢复验收前的用户配置和日志。完整逐项状态见 `manual-verification.md`。

## 候选产物

| 对象 | 身份 |
|---|---|
| Zip | `releases/v0.8/LetsMakeMoney-v0.8-beta-windows-x86_64.zip`（42,628,147 字节） |
| Zip SHA256 | `A2065B82F7674E5A19AC4FD467E7DEA3E8D665E3C148634C3721B7BD90AE098E` |
| 包内 EXE SHA256 | `8EEF15FD0F3C5130AF2422740C130A5A5E425CC4064484F05A8E759300FAE486`（113,026,776 字节） |
| 包内 DLL SHA256 | `E3E2030003A7DA725446A3873C3EC2E19D9442B98A67F24A771E76BD0BAD5089`（1,606,144 字节） |
| 源码提交 | `08f7820bfd95ff56132eb87eb9255078adb9572a` |

## 验收门禁

- 自动验证、包内许可和 isolated smoke 全部通过。
- 必须从新解压目录运行候选 EXE，不使用 `build/` 旧产物替代。
- 工资、休息模式、午休和大小周配置保存后重启仍一致。
- Panel 在上班前、工作中、午休、下班后和休息日的金额与进度符合规则。
- v0.7 的 Settings、Wizard、菜单、托盘、纯桌宠和点击穿透无回退。
- 未执行的真实桌面项目只能写“待验证”或“暂不验证”，不得冒充通过。
- 三种休息模式向导、午休冻结、休息日日历、通知区真实左键恢复及任务栏策略已由项目所有者补测通过。
- Windows 版与 iOS 原型/实现仍存在体验差距，已接受为非阻塞后续优化项，不影响本次 v0.8 Beta 便携 Zip 发布。

## 已知分发限制

- SignPath Foundation 免费签名申请于 2026-07-15 未获批准，原因是项目当前公开信任与社区可见度信号不足，不属于实现缺陷。
- v0.8 候选 EXE 未签名，Windows 可能显示未知发布者或 SmartScreen 提示；该状态必须向测试用户明确披露。
- 当前已批准的发布边界只允许验收和分发便携 Zip；未签名安装器不得作为公开 Release 附件。
- Authenticode/SmartScreen 继续标记为“暂不验证”，不能写成通过，也不阻塞本次便携 Zip Beta 验收。
