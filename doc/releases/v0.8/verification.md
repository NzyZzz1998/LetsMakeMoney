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
| Zip | 生成后填写 |
| Zip SHA256 | 生成后填写 |
| 包内 EXE SHA256 | 生成后填写 |
| 包内 DLL SHA256 | 生成后填写 |
| 源码提交 | 候选提交后填写 |

## 验收门禁

- 自动验证、包内许可和 isolated smoke 全部通过。
- 必须从新解压目录运行候选 EXE，不使用 `build/` 旧产物替代。
- 工资、休息模式、午休和大小周配置保存后重启仍一致。
- Panel 在上班前、工作中、午休、下班后和休息日的金额与进度符合规则。
- v0.7 的 Settings、Wizard、菜单、托盘、纯桌宠和点击穿透无回退。
- 未执行的真实桌面项目只能写“待验证”或“暂不验证”，不得冒充通过。
