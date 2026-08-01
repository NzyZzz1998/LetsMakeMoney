# LetsMakeMoney Windows v1.0.5 人工验证

## 当前结论

结论：**修复后独立候选验收通过，可进入发布收口。**

修复后 clean 候选通过 M6 聚合与真实 Windows 定向复验。Mini 在左右边缘首次贴边后保持焦点也会按合同自动收起；深色工作态隐私竖条、点击与键盘找回、关闭 Workbench 后保持收起，以及真实通知区左键隐藏/恢复均已通过。V105-BUG-001 已关闭，当前无发布阻塞。本结论不授权 commit、push、tag 或 Release。

## 历史失败候选

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

## 修复后候选锁定（复验前历史状态）

- 候选 ID：`V105-20260801T013259Z-6c9f010a-clean`。
- 源码状态：`clean`；源码 HEAD：`6c9f010a164fb2b73c9068bd4fdcb6e863bd5100`。
- Zip SHA256：`0FED6256E1E979D4BEC41E64C4290EF1917A6A6AB2B04D9A6EF47F1DD3C48826`。
- 当时结论：**不可发布**。该记录只锁定新验收对象，不代表人工验收通过；后续最终结果见“修复后独立复验”。

## 修复后独立复验

- 验收 ID：`ACC-20260801-105930-retest`。
- 候选 ID：`V105-20260801T013259Z-6c9f010a-clean`。
- 源码 HEAD：`6c9f010a164fb2b73c9068bd4fdcb6e863bd5100`，`source_tree_dirty=false`。
- Zip SHA256：`0FED6256E1E979D4BEC41E64C4290EF1917A6A6AB2B04D9A6EF47F1DD3C48826`。
- EXE SHA256：`BCF2309F3EF12FC494BEC7A4E43A5FDD62612CB7D086CB1C04AA5533AAE75112`。
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。

| 范围 | 结论 | 真实证据 |
| --- | --- | --- |
| 候选身份、M6 聚合与全新解压启动 | 通过 | 候选大小、SHA256、BUILD-INFO 和 M6 聚合输出一致 |
| 左右边缘首次贴边自动收起 | 通过 | 保持焦点时约 1.45 秒内收起为 21px 可见隐私条 |
| 悬停展开与移开收回 | 通过 | 左右边缘均完成真实鼠标链路 |
| 深色工作态隐私竖条 | 通过 | 仅显示“距离休息 25分钟”，零金额与工资字段泄露 |
| 点击与键盘找回 | 通过 | 单击和 Return 均恢复完整 Mini |
| 关闭 Workbench 后 Mini 状态 | 通过 | Mini 保持收起，未出现非预期菜单或展开 |
| Windows 通知区左键隐藏/恢复 | 通过 | 真实通知区图标、真实鼠标事件；第一次隐藏、第二次恢复，进程持续运行 |
| v1.0.4 核心回归 | 通过 | M6 完整回归与受影响 Mini 真实 GUI 复验通过 |
| 用户环境恢复 | 通过 | 正常与虚拟化配置、日志、注册表状态按哈希恢复；进程数为 0 |

无效尝试说明：`acc-003-right-first-dock-expanded-after-1150ms.png` 发生在自动隐藏前置配置尚未保存时，只能作为无效前置条件证据，不计入失败或通过结论。

## 延期与环境边界

- 多显示器、负坐标与显示器移除回落：项目所有者批准延期，当前不阻塞 v1.0.5。
- Windows 10：当前没有对应设备或 VM，保持环境待补证，不以 Windows 11 推断通过。
- 125%/150% DPI：沿用当前候选修复前已通过且未受本次焦点锁修复影响的 M5 真实 Windows 证据；本轮未冒充重新执行。
- published 模式、GitHub 回下载和 Release 附件核验属于获得发布授权后的发布收口阶段。

## 最终判断

当前候选独立验收结论为：**通过，可进入发布收口**。项目所有者已在验收完成后单独授权远端发布操作；验收证据本身不替代最终干净构建与 published 验证。

## 最终合并后重建候选

- 候选 ID：`V105-20260801T075629Z-ffc431af-clean`。
- 源码 HEAD：`ffc431af3fbf7c3b54bca8aaff44946cc8d6aeaf`；源码状态 `clean`，`source_tree_dirty=false`。
- Zip SHA256：`019B706E18E7D57D0B7E6DBFB6300762422B5723A11EB6ACCB601DA438215889`。
- EXE SHA256：`68FA8FC443B12A2BA8BD757F532EC6B90E09E3DA7E1027255267150C4DAEC37A`。
- WebView2Loader.dll SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 从已通过独立验收的业务提交到最终合并提交，产品业务代码无变化；最终候选仍需执行 M6 和受控桌面启动冒烟，原独立验收结论按证据失效规则继承。
- 在 tag、Release、published 模式与 GitHub 回下载完成前，本候选仍**不可发布**，不得以本节替代旧候选的真实操作记录。
- 最终候选已执行非交互 FirstRun 启动冒烟 `LMM-V105-SMOKE-20260801080945`：新解压 Mini 成功出现，哈希与候选身份一致，环境精确恢复、残留进程为 0。该脚本按合同记录为 `partial`，仅证明最终二进制可启动；业务 GUI 通过结论仍来自 `ACC-20260801-105930-retest`。
