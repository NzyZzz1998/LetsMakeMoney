# LetsMakeMoney Windows v1.0.5 发布检查

## 当前判断

状态：**不可发布。**

M0 至 M6 已完成。唯一 clean 候选通过完整聚合，但独立验收未通过：Mini 首次贴边后必须失焦才收起。V105-BUG-001 已复开，本候选不得发布。

## 受控候选身份

- [x] 候选来自干净提交且 `source_tree_dirty=false`。
- [x] 唯一候选 ID：`V105-20260801T002456Z-277b121b-clean`。
- [x] 候选源码状态：`clean`；Zip SHA256：`BE2E1004427859AD30A4A4B23B12C00CF8A5EBD69F7A2442F345813F28CA521C`。
- [x] EXE SHA256：`0B650A0DF85A315104BDDA0B5E0E0B1E0D97DA21A5B96D72C26217FC3206A25A`。
- [x] WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- [x] 受控候选 README 与 BUILD-INFO 哈希已锁定。

## 自动门禁

- [x] M0 至 M5 聚合门禁。
- [x] `scripts/verify_v105.ps1 -Milestone M6 -CandidatePath <Zip>`。
- [x] TypeScript strict、行为测试与 Vite production build。
- [x] Rust test、fmt、clippy 与 release build。
- [x] candidate 包身份和目录合同。
- [x] UTF-8、乱码、链接、敏感路径、隐私文本与 `git diff --check`。
- [ ] published 模式使用锁定 tag、Release URL、回下载 SHA 和 `SHA256SUMS.txt` 复核。

## 独立验收

- [ ] Mini 隐私贴边、竖条和全部找回路径：**未通过**，V105-BUG-001 复开。
- [ ] Workbench 关闭与通知区显式找回：部分通过，通知区待补证。
- [x] 日历方案 A 与日期调整复合状态。
- [ ] 三窗单一表面和三档 DPI：100% 本轮通过，125%/150% 仅继承开发证据。
- [ ] v1.0.4 核心行为回归：隐私自动隐藏回归未通过。
- [x] 用户环境恢复和证据合同。
- [x] 发布收口判断：**未通过，停止发布**。

## 当前发布阻塞

- `V105-BUG-001`：最小代码修复和自动回归已通过，但尚未从新 clean 提交构建候选，也没有真实 Windows 复验证据。
- 修复后必须从新干净提交重建候选，旧候选哈希和 GUI 证据不得复用。
- 新候选至少重跑 ACC-001、003、004、005、008、010、012。

## 发布停止条件

- 源工作树不干净，或 BUILD-INFO 声明 `source_tree_dirty=true`。
- 候选哈希变化后沿用旧 GUI 证据。
- 独立验收未通过，或存在未关闭的 V105-BUG-001。
- 隐私竖条泄露金额、工资制度、时间或日期。
- 正式发布对象无法通过 published 模式验证。
