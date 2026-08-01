# LetsMakeMoney Windows v1.0.5 人工验证

## 当前结论

结论：**独立候选验收未通过，存在发布阻塞。**

M6 唯一 clean 候选通过自动聚合，但独立真实 Windows 验收确认：Mini 首次贴边后仍需窗口失焦才会收起。该行为不满足隐私自动隐藏合同，V105-BUG-001 已复开，候选不得发布。

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

## 独立验收结果

- 验收目录：`.artifacts/acceptance/v1.0.5/ACC-20260801-083448/`
- 运行对象：全新解压目录中的候选 EXE；未使用构建目录或旧进程。

| 范围 | 结论 | 真实证据 |
| --- | --- | --- |
| 候选身份、全新解压与启动 | 通过 | Zip、EXE、WebView2Loader 的大小与 SHA256 均匹配锁定对象 |
| Mini 首次贴边自动收起 | 未通过 | 右侧贴边 1.4 秒后仍展开；失焦后才收起 |
| 隐私竖条零泄露 | 部分通过 | 休息态只显示“今日休息”；完整状态矩阵被首次收起缺陷阻塞 |
| Workbench 拖动与关闭 | 通过 | 全窗口拖动成功，关闭后仅保留 Mini，未出现非预期菜单 |
| 通知区显式找回 | 待人工补证 | 本轮未完成真实通知区鼠标链路 |
| Wizard 与 Settings | 通过 | Wizard 四步、返回、完成；Settings 五页、保存、无变化、失败与关闭路径已有真实 GUI 证据 |
| 日历与日期调整 | 通过 | 自动、工作日、带薪休息、不带薪休息与恢复自动判断均通过 |
| 三窗与 DPI | 部分通过 | 本轮 100% DPI 通过；125%/150% 只继承 M5 开发证据 |
| 多显示器 | 待人工补证 | 当前仅一台显示器，无法验证 |
| 用户环境恢复 | 通过 | 原配置与日志哈希恢复，开机自启未变化，结束后进程数为 0 |

## 发布阻塞复现

1. 启动全新解压的锁定候选。
2. 将 Mini 拖到右侧工作区边缘并释放，不再点击其他窗口。
3. 等待 1.4 秒，Mini 仍保持完整展开。
4. 使用 `Alt+Tab` 使窗口失焦，Mini 随即收起。
5. 日志在失焦前没有 retract 调度；失焦后出现 `mini.edge.retract.scheduled source=lock_released`。

证据文件：

- `ACC-MINI-RIGHT-RETRACT-FIRST.jpg`
- `ACC-MINI-RIGHT-DOCK-config.json`
- `ACC-MINI-RIGHT-DOCK-debug.log`
- `ACC-MINI-RIGHT-RETRACT-AFTER-BLUR.jpg`

## 环境边界

- Windows 11 与三档 DPI 已有开发阶段真实证据；独立 ACC 本轮只在 100% DPI 执行。
- Windows 10、真实多显示器和负坐标工作区尚无对应环境证据，不得写成通过。
- 本轮因发布阻塞停止扩展性补证；修复后应以新候选补齐受影响链路。
- 本文件不授权 commit、push、tag 或 Release。

## ACC 后修复准备状态

- 已新增左右边缘“保持窗口焦点也必须首次收起”的自动回归，修复前稳定失败、修复后通过。
- 修复只释放贴边拖拽遗留的焦点锁，menu/modal 锁和浮动窗口行为未改变。
- TypeScript、Vite、前端行为与结构门禁、Rust `54/54`、fmt 和 clippy 已通过。
- 本节不是人工通过结论；必须使用新 clean 候选重新执行受影响 ACC，旧候选的失败结论继续有效。
