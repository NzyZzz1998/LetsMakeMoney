# LetsMakeMoney Windows v1.0.7 发布说明

> 状态：已发布。

## 本版重点

- 统一当前 CI、config v8、版本元数据和高风险 IPC 合同。
- 修复首次始终置顶、Mini/Workbench 显示事务、贴边隐私收起、窗口找回和自由拖动回落。
- “调整今天”与日历共用安全的日期调整事务。
- 新增按业务日期保存的小数加班时长与录入时费率快照。
- 新增月度计划工时、已流逝计划工时和加班工时总结，并完整支持五周/六周月份。
- 统一圆角 Combobox、窗口边框、阴影和透明表面所有权。
- 建立 current/historical 脚本生命周期、候选包身份和可持续验收证据门禁。

## 兼容与边界

- 保持 v1.0.6 的收入、日历、日期调整、主题、托盘和更新口径。
- 加班记录独立于 config v8；回退 v1.0.6 时会被安全忽略。
- Windows 11 x86_64 单显示器为强制验收环境。
- Windows 10 尚无真实证据时仅保留尽力兼容；多显示器暂不验证。
- 本版不恢复宠物，不加入账号、云同步、安装器、自动更新或多平台。

## 发布附件

正式 Release 仅允许：

1. `LetsMakeMoney-v1.0.7-windows-x86_64.zip`
2. `SHA256SUMS.txt`

## 发布身份

| 对象 | 身份 |
| --- | --- |
| 发布源提交 | `f500ed4e7de28ec68b2a848da6fa2340420b91b2` |
| Tag | `v1.0.7` |
| 便携 Zip | `LetsMakeMoney-v1.0.7-windows-x86_64.zip`，3,317,879 字节，SHA256 `D656B96973F64632896715ADCBB9CAFEAED4D06D44BA1C098824335AC673E3F2` |
| EXE | 10,271,744 字节，SHA256 `58F7F64060584FCAF6BABE0720DC3EF61067669D088DC0CCFBF25DA703E45C3C` |
| Native DLL | 160,320 字节，SHA256 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |
| SHA256SUMS.txt | 107 字节，SHA256 `E16B8EFDBD89C478598821E7A08312587F4377AF200C4D8F65D60068D2202CE4` |
| Release | [GitHub Release v1.0.7](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.7) |

GitHub Release 仅包含便携 Zip 与 `SHA256SUMS.txt`。附件已重新下载并通过 published 模式包体验证。
