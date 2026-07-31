# LetsMakeMoney Windows v1.0.4 发布检查

## 当前判断

状态：**已通过并发布。**

Mini 隐私贴边核心行为、全部自动门禁、隔离干净提交构建、真实 100%/125%/150% DPI、深色主题、减少动态效果、首次配置、日历事务和 Windows 通知区真实鼠标找回已通过。真实多显示器场景由项目所有者批准延期并明确标记“暂不验证”。

## 最终发布身份

- [x] 版本统一为 `1.0.4`。
- [x] Zip、EXE、WebView2Loader、README 和 BUILD-INFO 身份已记录。
- [x] `SHA256SUMS.txt` 与最终发布 Zip 一致。
- [x] 最终发布产物来自发布源提交 `4d06dc73dbc5c27d7a97462d8262a553dd97d5b6`，且 `source_tree_dirty=false`。
- [x] 最终发布身份已经锁定并完成复验。
- [x] `v1.0.4` annotated tag 指向最终发布源提交。
- [x] GitHub Stable Release 仅包含便携 Zip 与 `SHA256SUMS.txt`。
- [x] 从 GitHub 回下载的附件身份和 SHA256 已复核。

最终发布 Zip SHA256：

`C4F28892831891A4266C4D9B12D432CD5C970BB3C9B36A6B8DB21FA2566DE50E`

## 自动门禁

- [x] `scripts/verify_v104.ps1`。
- [x] TypeScript/Vite 生产构建。
- [x] Rust test、format 与 clippy。
- [x] `scripts/package_v104.ps1`。
- [x] `scripts/verify_v104_package.ps1`。
- [x] v1.0.3 历史产品回归与架构继承门禁。
- [x] 验收摘要生成与 schema 复核。
- [x] 从无 spike 的新鲜 clone 完成同一链路。

## Mini 隐私贴边

- [x] 左边缘停靠、收起和唤回。
- [x] 右边缘停靠、收起和唤回。
- [x] 收起态不显示工资、阶段、时间和日期。
- [x] Settings 关闭开关后立即展开并停止自动收起。
- [x] 重启后关闭状态持久化。
- [x] 100% DPI 真实 Windows 通过。
- [x] 125% DPI 真实 Windows。
- [x] 150% DPI 真实 Windows。
- [x] 深色主题真实观感。
- [x] 减少动态效果真实观感。
- [x] 多显示器、负坐标与显示器移除回落已批准延期，不阻塞 v1.0.4。

## 主要窗口与系统入口

- [x] Mini、Workbench 和 Settings 在开发验收中可打开。
- [x] 独立验收候选首次启动与 Wizard 完整冒烟。
- [x] 最终候选通知区真实鼠标隐藏、恢复和窗口找回。
- [x] 独立验收候选主要窗口无重复、可聚焦且退出无残留进程。

## 证据与环境

- [x] 仓库内脱敏摘要已生成并可验证。
- [x] 主验收结束时普通与隔离用户配置、前一版本配置和日志哈希恢复一致；通知区补证未保存配置，仅追加真实托盘日志。
- [x] 验收结束后 LetsMakeMoney 进程数为 `0`。
- [ ] Computer Use 原始截图或录屏建立外部归档。
- [x] 独立验收候选的环境、身份和日志摘要重新生成。

## 文档与远端

- [x] verification、manual verification、release notes、progress、current 和本检查表使用“通过 / 已发布”口径。
- [x] 未把暂不验证的多显示器场景写成通过。
- [x] 已获得独立发布授权。
- [x] 发布提交已通过 PR #20 合入 `main`。
- [x] 最终候选通过后已更新 release notes 与最终哈希。
- [x] `v1.0.4` tag 与 GitHub Stable Release 已创建。
- [x] Release 附件数量、名称、大小和回下载哈希已验证。

## 发布停止条件

出现以下任一情况时不得发布：

- 最终发布源工作树不干净或 `source_tree_dirty=true`。
- 最终候选哈希变化后沿用当前测试候选证据。
- 收起态仍能读取工资、阶段、日期或时间。
- 关闭自动隐藏后 Mini 仍为空白、保持收起或重启后设置失效。
- 用户环境未恢复，或存在残留 LetsMakeMoney 进程。
