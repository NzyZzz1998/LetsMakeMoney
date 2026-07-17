# LetsMakeMoney v0.8 Beta 验证记录

**当前结论**：自动回归、导出、候选包校验与新解压 smoke 通过；待真实桌面人工验收

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
