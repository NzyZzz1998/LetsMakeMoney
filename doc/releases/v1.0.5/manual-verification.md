# LetsMakeMoney Windows v1.0.5 人工验证

## 当前结论

结论：**开发里程碑验证完成，独立候选验收尚未执行。**

M3 至 M5 已对 Mini 隐私贴边、日历复合状态和三窗单一表面完成真实 Windows 定向验证。M6 唯一 clean 候选已经通过完整自动聚合；它是独立验收对象，但在独立 ACC 与发布授权完成前不可发布。

## M6 受控候选

- 候选 ID：`V105-20260801T002456Z-277b121b-clean`
- 源码状态：`clean`，`source_tree_dirty=false`
- Zip SHA256：`BE2E1004427859AD30A4A4B23B12C00CF8A5EBD69F7A2442F345813F28CA521C`
- EXE SHA256：`0B650A0DF85A315104BDDA0B5E0E0B1E0D97DA21A5B96D72C26217FC3206A25A`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- 发布状态：**不可发布**。

## 已有真实桌面证据

| 范围 | 结果 | 证据边界 |
| --- | --- | --- |
| Mini 左右首次收起、指针/点击找回、移开收回 | 通过 | M3 受控候选；候选身份变化后需独立复核 |
| 普通 focus 与关闭 Workbench | 通过 | M3 受控候选；显式托盘找回仍需独立复核 |
| 日历 official、estimated、今天/选中/业务复合状态 | 通过 | M4 受控候选；loading/error 仍需补证 |
| Workbench、Settings、Wizard 单一表面 | 通过 | M5 Windows 11 真实壳 |
| 100%、125%、150% DPI | 通过 | M5 Windows 11；Windows 10 待环境补证 |

## 独立验收待执行

- [ ] 核对来自干净提交的唯一 Zip、EXE、DLL、README 与 BUILD-INFO 身份。
- [ ] 新目录解压并只运行候选 EXE，备份与恢复用户环境。
- [ ] 验证左右首次收起、全部找回路径、隐私零泄露和故障回退。
- [ ] 验证日历 normal/risk 状态、键盘导航和深色主题。
- [ ] 回归收入、日期调整、Settings、Wizard、托盘和更新检查。
- [ ] 由项目所有者决定真实多显示器补证或延期。

## 环境边界

- Windows 11 与三档 DPI 已有开发阶段真实证据。
- Windows 10、真实多显示器和负坐标工作区尚无对应环境证据，不得写成通过。
- 本文件不授权 commit、push、tag 或 Release。
