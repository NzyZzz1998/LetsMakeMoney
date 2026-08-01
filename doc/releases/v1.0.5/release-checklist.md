# LetsMakeMoney Windows v1.0.5 发布检查

## 当前判断

状态：**验收通过，发布收口已授权并开始执行。**

M0 至 M6 和修复后独立 ACC 已完成。修复后 clean 候选通过左右贴边隐私状态机、深色隐私条、Workbench 关闭、真实通知区左键隐藏/恢复和核心回归；V105-BUG-001 已关闭，当前无发布阻塞。项目所有者已授权执行远端发布收口。

当前验收 candidate 本身不可发布，只可用于发布收口输入；正式发布对象必须从最终合并后的干净提交重新构建并通过 published 模式验证。

## 历史失败候选身份

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

- [x] Mini 隐私贴边、竖条和全部找回路径：修复后候选通过。
- [x] Workbench 关闭与通知区显式找回：真实 Windows 通过。
- [x] 日历方案 A 与日期调整复合状态。
- [x] 三窗单一表面和三档 DPI：本轮 100%，125%/150% 采用未受修复影响且未失效的 M5 真实证据。
- [x] v1.0.4 核心行为回归。
- [x] 用户环境恢复和证据合同。
- [x] 发布收口判断：**通过，可进入发布收口**。

## 当前发布阻塞

- 无。`V105-BUG-001` 已由修复后 clean 候选的自动门禁和真实 Windows 定向复验关闭。
- 旧候选哈希和 GUI 证据只作为历史失败记录保留，不得复用为当前发布对象。
- 多显示器经项目所有者批准延期；Windows 10 因环境不可用保持待补证，均不阻塞本版。

## 发布停止条件

- 源工作树不干净，或 BUILD-INFO 声明 `source_tree_dirty=true`。
- 候选哈希变化后沿用旧 GUI 证据。
- 独立验收未通过，或存在未关闭的 V105-BUG-001。
- 隐私竖条泄露金额、工资制度、时间或日期。
- 正式发布对象无法通过 published 模式验证。

## 修复后替代候选

- [x] 候选 ID：`V105-20260801T013259Z-6c9f010a-clean`。
- [x] 源码状态：`clean`；源码 HEAD：`6c9f010a164fb2b73c9068bd4fdcb6e863bd5100`。
- [x] Zip SHA256：`0FED6256E1E979D4BEC41E64C4290EF1917A6A6AB2B04D9A6EF47F1DD3C48826`。
- [x] EXE SHA256：`BCF2309F3EF12FC494BEC7A4E43A5FDD62612CB7D086CB1C04AA5533AAE75112`。
- [x] WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- [x] 修复后真实 Windows ACC 通过：`ACC-20260801-105930-retest`。
- [x] M6 聚合复核通过。
- [x] 用户配置、日志、注册表状态恢复，结束后进程数为 0。
- 状态：**发布收口执行中**；published 模式、GitHub 回下载和 Release 附件核验在最终干净构建发布后执行。

## 最终合并后重建候选

- [x] 候选 ID：`V105-20260801T075629Z-ffc431af-clean`。
- [x] 源码 HEAD：`ffc431af3fbf7c3b54bca8aaff44946cc8d6aeaf`。
- [x] 源码状态：`clean`，`source_tree_dirty=false`。
- [x] Zip SHA256：`019B706E18E7D57D0B7E6DBFB6300762422B5723A11EB6ACCB601DA438215889`。
- [x] EXE SHA256：`68FA8FC443B12A2BA8BD757F532EC6B90E09E3DA7E1027255267150C4DAEC37A`。
- [x] WebView2Loader.dll SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- [x] 最终候选 M6 聚合通过。
- [x] 最终候选受控桌面启动冒烟完成：`LMM-V105-SMOKE-20260801080945`，非交互启动范围为 `partial`，Mini 出现、环境精确恢复且无残留进程；完整 GUI 结论继承独立 ACC。
- [ ] annotated tag `v1.0.5` 已推送并指向发布源码 HEAD。
- [ ] GitHub Release 仅上传便携 Zip 与 `SHA256SUMS.txt`。
- [ ] GitHub 回下载 SHA256 与本节锁定值一致，published 模式通过。
- 状态：上述未完成项关闭前，本候选仍**不可发布**。
