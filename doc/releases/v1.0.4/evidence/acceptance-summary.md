# LetsMakeMoney v1.0.4 验收摘要

## 候选身份

- 分支：`main`
- 提交：`661b0f748798e28f7999eac23532aa7ed7510640`
- 工作树：干净
- 结论：`passed`
- 生成时间：`2026-07-31T05:47:06Z`

| 产物 | 字节 | SHA256 |
| --- | ---: | --- |
| `LetsMakeMoney-v1.0.4-windows-x86_64.zip` | 3229111 | `2BBC5B79F9A615F31CFDFFC27C55450C660363A643DE5EB33A6E7B3A1B049340` |
| `LetsMakeMoney.exe` | 10108416 | `EB0FA82F5506B775F03774E429A12DB66F838E705B608F4A7664D6F9243830DF` |
| `WebView2Loader.dll` | 160320 | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |
| `README.md` | 2140 | `70DEAA1D916B6C5694F927B10D280D3E829F6F0954DF0E5F8B2C75104DB0C030` |
| `README.en.md` | 2399 | `B91FA03E155CEEF7B9D9BF690EB3F85948DA6A469DA5D73614BC0C5A951D035D` |
| `BUILD-INFO.json` | 1783 | `EA51272263FE4CE5CE0CBC37E2E073E84AF0F472A0FBF531BA75C97FA51FF0DD` |

## 环境

- Windows：Windows 11 Pro 10.0.26200
- 架构：x86_64
- DPI：100%, 125%, 150%
- WebView2：150.0.4078.105

## 检查

| ID | 方法 | 结果 | 证据 |
| --- | --- | --- | --- |
| `V104-AUTO-FULL` | automatic | passed | `repo:doc/releases/v1.0.4/verification.md` |
| `V104-AUTO-PACKAGE` | automatic | passed | `repo:doc/releases/v1.0.4/verification.md` |
| `V104-GUI-MINI-EDGE` | computer_use | passed | `repo:doc/releases/v1.0.4/manual-verification.md` |
| `V104-GUI-CONFIG-REFRESH` | computer_use | passed | `repo:doc/releases/v1.0.4/manual-verification.md` |
| `V104-GUI-RESTART-PERSISTENCE` | computer_use | passed | `repo:doc/releases/v1.0.4/manual-verification.md` |
| `V104-GUI-DPI` | manual | passed | `repo:doc/releases/v1.0.4/manual-verification.md` |
| `V104-GUI-DARK-THEME` | computer_use | passed | `repo:doc/releases/v1.0.4/manual-verification.md` |
| `V104-GUI-REDUCED-MOTION` | computer_use | passed | `repo:doc/releases/v1.0.4/manual-verification.md` |
| `V104-GUI-WIZARD` | computer_use | passed | `repo:doc/releases/v1.0.4/manual-verification.md` |
| `V104-GUI-CALENDAR` | computer_use | passed | `repo:doc/releases/v1.0.4/manual-verification.md` |
| `V104-GUI-MULTI-MONITOR` | manual | not_run | `repo:doc/releases/v1.0.4/manual-verification.md` |
| `V104-GUI-TRAY` | manual | passed | `repo:doc/releases/v1.0.4/manual-verification.md` |

## 限制

- 当前环境只有一台显示器；项目所有者于 2026-07-31 批准将真实多显示器、负坐标工作区和显示器移除回落延期验证，不阻塞 v1.0.4。
- 减少动态效果下的真实收起已通过；3px 隐私唤回条无法由 Computer Use 独立稳定命中，正常动态下的唤回已通过。
- 当前候选来自隔离干净提交，但该提交尚不是最终发布提交；发布源发生变化时必须重新构建并锁定哈希。

## 原始证据

- 归档 ID：`LMM-V104-ACCEPTANCE-M6-001`
- 可用状态：`not_collected`
- 责任角色：`project-owner`

本文件由同目录 JSON 确定性生成。仓库摘要不包含用户名、绝对路径、真实薪资、完整配置、秘密或未脱敏日志。
