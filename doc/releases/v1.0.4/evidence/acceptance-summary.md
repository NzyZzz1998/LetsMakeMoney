# LetsMakeMoney v1.0.4 验收摘要

## 候选身份

- 分支：`main`
- 提交：`09f838d05c67efb5219437ec2208920e441f3f52`
- 工作树：有未提交变更
- 结论：`partial`
- 生成时间：`2026-07-30T20:27:00Z`

| 产物 | 字节 | SHA256 |
| --- | ---: | --- |
| `LetsMakeMoney-v1.0.4-windows-x86_64.zip` | 3228960 | `C67E730BF81741D03BFAF6D14F3F16EB74FD8591D8B3AB76D45A980E854C249B` |
| `LetsMakeMoney.exe` | 10108416 | `B2A1831D0F7832C77033582871C12A2148CC8F3279753A5B812C293869ED1C66` |
| `WebView2Loader.dll` | 160320 | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |
| `README.md` | 2140 | `70DEAA1D916B6C5694F927B10D280D3E829F6F0954DF0E5F8B2C75104DB0C030` |
| `README.en.md` | 2399 | `B91FA03E155CEEF7B9D9BF690EB3F85948DA6A469DA5D73614BC0C5A951D035D` |
| `BUILD-INFO.json` | 1782 | `8CBE58AA5761C797B10741196A80C6BF0270F902D20FF560C8B24D5E3C9B5721` |

## 环境

- Windows：Windows 11 Pro 10.0.26200
- 架构：x86_64
- DPI：100%
- WebView2：150.0.4078.105

## 检查

| ID | 方法 | 结果 | 证据 |
| --- | --- | --- | --- |
| `V104-AUTO-FULL` | automatic | passed | `repo:doc/releases/v1.0.4/verification.md` |
| `V104-AUTO-PACKAGE` | automatic | passed | `repo:doc/releases/v1.0.4/verification.md` |
| `V104-GUI-MINI-EDGE` | computer_use | passed | `repo:doc/releases/v1.0.4/manual-verification.md` |
| `V104-GUI-CONFIG-REFRESH` | computer_use | passed | `repo:doc/releases/v1.0.4/manual-verification.md` |
| `V104-GUI-RESTART-PERSISTENCE` | computer_use | passed | `repo:doc/releases/v1.0.4/manual-verification.md` |
| `V104-GUI-DPI` | manual | partial | `repo:doc/releases/v1.0.4/manual-verification.md` |
| `V104-GUI-MULTI-MONITOR` | manual | not_run | `repo:doc/releases/v1.0.4/manual-verification.md` |

## 限制

- 真实 Windows 仅完成 100% DPI；125% 与 150% DPI 仍待人工补证。
- 深色主题与减少动态效果下的真实贴边观感仍待人工补证。
- 当前环境未完成真实多显示器和负坐标工作区补证。
- 候选由脏工作树构建，只用于开发验收，不是正式发布候选。

## 原始证据

- 归档 ID：`LMM-V104-ACCEPTANCE-M6-001`
- 可用状态：`not_collected`
- 责任角色：`project-owner`

本文件由同目录 JSON 确定性生成。仓库摘要不包含用户名、绝对路径、真实薪资、完整配置、秘密或未脱敏日志。
