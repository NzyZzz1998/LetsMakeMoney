# LetsMakeMoney Windows v1.0.5 发布检查

## 当前判断

状态：**不可发布。**

M0 至 M5 已完成。M6 已完成 9/10，受控 dirty 候选通过完整聚合；干净提交候选、独立验收和项目所有者发布授权尚未完成。

## 受控候选身份

- [ ] 候选来自干净提交且 `source_tree_dirty=false`。
- [x] 受控候选 ID：`V105-20260731T204214Z-8a63da78-dirty`。
- [x] 受控候选源码状态：`dirty`；Zip SHA256：`ED69EEB4E58A98CF336C31C781AADD905C9E025D4C7376FBA91B4F2EAB355BD5`。
- [x] EXE SHA256：`1CD25830AE3465E6FBE62CA346DB2B59475E4D8C00C202AB17291797682311F2`。
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
