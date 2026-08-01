# LetsMakeMoney Windows v1.0.5 发布说明草案

> 状态：**独立验收通过，发布收口已授权。** 正式 Release 内容和附件身份仍以最终合并提交的干净构建为准。

当前验收 candidate 不直接上传；发布收口将从最终合并后的干净提交重新构建并锁定正式附件。

## 本版重点

### Mini 隐私贴边

- 修复首次拖到屏幕边缘后必须再次交互才收起的问题。
- 收起后保留可读的非金额隐私竖条，展示“距离上班 / 休息 / 恢复工作 / 下班”等阶段信息。
- 竖条禁止显示月薪、今日已赚、日薪、时薪、日期或精确工作制度。
- 普通窗口焦点不再误触发显式找回；托盘、键盘和点击找回仍保留。

### 日历与窗口质感

- official 正常态不再常驻展示来源块；estimated、stale、loading 与 error 保留明确风险提示。
- “今天”使用角标、字重和复合 ARIA 语义，不覆盖日期原有的工作/休息/手动调整状态。
- Workbench、Settings 和 Wizard 统一为单一表面职责，减少双层边框与阴影观感。

### 发布可信度

- 开发候选只写入隔离目录，不覆盖正式发布缓存。
- candidate 与 published 包验证采用不同身份合同。
- 版本、源码 HEAD、dirty 状态、Zip、EXE、DLL 和离线 README 建立交叉验证。

## 兼容性

- Windows 10/11 x86_64；Windows 10 真实视觉证据仍待补充。
- 收入、日历数据、日期调整、主题和配置 schema 保持 v1.0.4 兼容。
- 不恢复宠物，不新增账号、云同步、安装器或静默更新。

## M6 受控候选

- 候选 ID：`V105-20260801T002456Z-277b121b-clean`
- 源码状态：`clean`，`source_tree_dirty=false`
- Zip SHA256：`BE2E1004427859AD30A4A4B23B12C00CF8A5EBD69F7A2442F345813F28CA521C`
- EXE SHA256：`0B650A0DF85A315104BDDA0B5E0E0B1E0D97DA21A5B96D72C26217FC3206A25A`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- 发布状态：**不可发布**。

## 发布前仍需完成

1. 对唯一 clean 候选执行独立验收并恢复用户环境。
2. 关闭验收发现的发布阻塞，或明确记录待补证边界。
3. 按已获得的项目所有者授权执行 push、tag 与 Release，并完成回下载核验。

## ACC 修复后替代候选

- 候选 ID：`V105-20260801T013259Z-6c9f010a-clean`
- 源码 HEAD：`6c9f010a164fb2b73c9068bd4fdcb6e863bd5100`
- 源码状态：`clean`，`source_tree_dirty=false`
- Zip SHA256：`0FED6256E1E979D4BEC41E64C4290EF1917A6A6AB2B04D9A6EF47F1DD3C48826`
- EXE SHA256：`BCF2309F3EF12FC494BEC7A4E43A5FDD62612CB7D086CB1C04AA5533AAE75112`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- 发布状态：**不可发布**；必须通过修复后的独立真实 Windows 验收。

## 修复后最终验收

- 验收 ID：`ACC-20260801-105930-retest`。
- M6 聚合：通过。
- 左右首次贴边收起、悬停与移开、点击和键盘找回：通过。
- 深色 working 隐私条：通过，未发现工资或金额泄露。
- 关闭 Workbench 后 Mini 保持收起：通过。
- 真实 Windows 通知区左键隐藏与恢复：通过，进程保持运行。
- v1.0.4 核心回归与用户环境恢复：通过。
- 多显示器：项目所有者批准延期；Windows 10：环境待补证。
- 当前发布判断：**通过，发布收口已授权并开始执行**；尚未生成最终发布提交、tag 或 Release。

## 最终合并后重建候选

- 候选 ID：`V105-20260801T075629Z-ffc431af-clean`。
- 源码 HEAD：`ffc431af3fbf7c3b54bca8aaff44946cc8d6aeaf`。
- 源码状态：`clean`，`source_tree_dirty=false`。
- Zip SHA256：`019B706E18E7D57D0B7E6DBFB6300762422B5723A11EB6ACCB601DA438215889`。
- EXE SHA256：`68FA8FC443B12A2BA8BD757F532EC6B90E09E3DA7E1027255267150C4DAEC37A`。
- WebView2Loader.dll SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- 该候选由最终合并提交重新构建；业务代码相对已通过独立验收的候选无变化，历史验收记录继续保留。
- 在 M6、受控桌面冒烟、tag、Release、published 模式和 GitHub 回下载核验完成前，本候选仍**不可发布**。
