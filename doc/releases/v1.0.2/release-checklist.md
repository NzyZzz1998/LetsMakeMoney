# LetsMakeMoney v1.0.2 发布检查

## 候选身份

- [x] 分支：`main`
- [x] 构建基线 HEAD：`1eb3dadbd37dcc06141e82e5e043db529821a104`
- [x] 工作树中的 v1.0.2 实现尚未提交，候选以哈希为唯一身份。
- [x] Zip：`releases/v1.0.2/LetsMakeMoney-v1.0.2-windows-x86_64.zip`
- [x] Zip 大小：3,194,384 字节
- [x] Zip SHA256：`BA7330C0C14745CE1DB355C3E28CE75255E7B64250212CE25D8B36C054653DB2`
- [x] EXE 大小：9,988,608 字节
- [x] EXE SHA256：`BE54F049F2134536564EC8222F3C5446F54C3653223206A97BDE2A3B575CB6F7`
- [x] WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`

## 实现与回归

- [x] FR-001 至 FR-008 实现完成。
- [x] v1.0.2 聚合验证通过。
- [x] Rust 36/36 通过。
- [x] 呈现行为 11/11 通过。
- [x] 主题行为 5/5 通过。
- [x] 多窗口权威同步 20/20 通过。
- [x] v1.0.1 与 v1.0 历史回归通过。
- [x] 固定 `lucide-react@1.27.0` 及 ISC notice 已进入依赖与包验证。
- [x] 打包与包体验证通过。

## 真实桌面

- [x] 新解压候选冷启动通过。
- [x] 当前候选首次配置 Wizard、小数休息推算、保存和 Mini 权威刷新通过。
- [x] 当前候选 Workbench、Settings 和首次配置 Wizard 按需窗口可见并可交互。
- [x] 当前候选浅色默认、深色草稿预览、关闭确认和放弃回滚完成真实复验。
- [x] Settings 隐藏后重新打开无残留确认框，主题与草稿恢复正确。
- [x] 配置后通过原生托盘入口重新打开 Wizard 并复验窗口复用。
- [x] WebView2 辅助窗口按需创建。
- [x] WebView2 连续 5 次冷启动压力通过。
- [x] Windows 通知区真实鼠标左键隐藏/恢复。
- [x] 真实 Windows 125%/150% DPI 清晰度；Mini、Workbench、日历、Settings、Wizard 及浅色/深色关键状态完成真实系统缩放补证。

## 环境与文档

- [x] 用户原始配置和日志已恢复。
- [x] 无残留 LetsMakeMoney 进程。
- [x] `verification.md`、`manual-verification.md`、`progress_v1.0.2.md` 和 `current.md` 已同步。
- [x] 正式文档使用简体中文 UTF-8。
- [x] `git diff --check` 通过。

## 发布动作

- [x] 关闭 `V102-BUG-005` 并对新候选完成定向复验。
- [x] 关闭 `V102-BUG-006` 并完成 Settings 真实 GUI 与双窗口静态回归。
- [x] 关闭 `V102-BUG-007` 并完成首次配置与复用 Wizard 定向复验。
- [x] 项目所有者完成最终 Acceptance 签核。
- [ ] 从签核后的干净提交重新构建并更新最终哈希。
- [ ] 创建发布提交并推送 `main`。
- [ ] 创建并推送 `v1.0.2` tag。
- [ ] 创建 GitHub Release，只上传便携 Zip 和 `SHA256SUMS.txt`。
- [ ] 核对远端分支、tag、Release 附件和 SHA256。

当前结论：**最终 Acceptance 通过，无发布阻塞，可进入发布收口。仍需从签核后的干净提交重新构建并更新最终哈希；本轮未执行发布动作。**
