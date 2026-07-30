# LetsMakeMoney Windows v1.0.4 发布检查

## 当前判断

状态：**开发验收部分通过，不可进入发布收口。**

Mini 隐私贴边核心行为与全部自动门禁已通过，但当前候选来自脏工作树，且真实 125%/150% DPI、深色/减少动态效果和多显示器证据未完成。

## 测试候选身份

- [x] 版本统一为 `1.0.4`。
- [x] Zip、EXE、WebView2Loader、README 和 BUILD-INFO 身份已记录。
- [x] `SHA256SUMS.txt` 与当前测试 Zip 一致。
- [ ] 候选来自干净提交，且 `source_tree_dirty=false`。
- [ ] 最终候选身份已经锁定并完成独立复验。

当前测试 Zip SHA256：

`C67E730BF81741D03BFAF6D14F3F16EB74FD8591D8B3AB76D45A980E854C249B`

## 自动门禁

- [x] `scripts/verify_v104.ps1`。
- [x] TypeScript/Vite 生产构建。
- [x] Rust test、format 与 clippy。
- [x] `scripts/package_v104.ps1`。
- [x] `scripts/verify_v104_package.ps1`。
- [x] v1.0.3 历史产品回归与架构继承门禁。
- [x] 验收摘要生成与 schema 复核。
- [ ] 从无 spike 的新鲜 clone 完成同一链路。

## Mini 隐私贴边

- [x] 左边缘停靠、收起和唤回。
- [x] 右边缘停靠、收起和唤回。
- [x] 收起态不显示工资、阶段、时间和日期。
- [x] Settings 关闭开关后立即展开并停止自动收起。
- [x] 重启后关闭状态持久化。
- [x] 100% DPI 真实 Windows 通过。
- [ ] 125% DPI 真实 Windows。
- [ ] 150% DPI 真实 Windows。
- [ ] 深色主题真实观感。
- [ ] 减少动态效果真实观感。
- [ ] 多显示器、负坐标与显示器移除回落。

## 主要窗口与系统入口

- [x] Mini、Workbench 和 Settings 在开发验收中可打开。
- [ ] 最终候选首次启动与 Wizard 完整冒烟。
- [ ] 最终候选通知区真实鼠标隐藏、恢复和窗口找回。
- [ ] 最终候选主要窗口无重复、可聚焦且退出无残留进程。

## 证据与环境

- [x] 仓库内脱敏摘要已生成并可验证。
- [x] 普通用户数据恢复结果为 `7/7` 一致。
- [x] 验收结束后 LetsMakeMoney 进程数为 `0`。
- [ ] Computer Use 原始截图或录屏建立外部归档。
- [ ] 最终候选的环境、身份和日志摘要重新生成。

## 文档与远端

- [x] verification、manual verification、release notes、progress、current 和本检查表使用部分通过口径。
- [x] 未把待人工补证写成通过。
- [x] 未提交、推送、打 tag、创建 Release 或修改远端 Release 正文。
- [ ] 最终候选通过后更新 release notes 与最终哈希。
- [ ] 获得独立发布授权。

## 发布停止条件

出现以下任一情况时不得发布：

- 工作树不干净或 `source_tree_dirty=true`。
- 最终候选哈希变化后沿用当前测试候选证据。
- 收起态仍能读取工资、阶段、日期或时间。
- 关闭自动隐藏后 Mini 仍为空白、保持收起或重启后设置失效。
- 必须补证的 DPI、主题或显示器门禁没有完成，也没有项目所有者明确延期决定。
- 用户环境未恢复，或存在残留 LetsMakeMoney 进程。
