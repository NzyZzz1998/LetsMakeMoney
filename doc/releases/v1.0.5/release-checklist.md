# LetsMakeMoney Windows v1.0.5 发布检查

## 当前判断

状态：**不可发布。**

M0 至 M6 已完成。唯一 clean 候选通过完整聚合；独立验收和项目所有者发布授权尚未完成。

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

- [ ] Mini 隐私贴边、竖条和全部找回路径。
- [ ] Workbench 关闭与通知区显式找回。
- [ ] 日历方案 A 与风险状态。
- [ ] 三窗单一表面和三档 DPI。
- [ ] v1.0.4 核心行为回归。
- [ ] 用户环境恢复和证据合同。
- [ ] 发布收口判断。

## 发布停止条件

- 源工作树不干净，或 BUILD-INFO 声明 `source_tree_dirty=true`。
- 候选哈希变化后沿用旧 GUI 证据。
- 独立验收未完成。
- 隐私竖条泄露金额、工资制度、时间或日期。
- 正式发布对象无法通过 published 模式验证。
