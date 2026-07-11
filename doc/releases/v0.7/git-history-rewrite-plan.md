# LetsMakeMoney v0.7 Git 历史重写方案

**状态**：已执行；远端历史替换与 fresh clone 复验通过
**目标**：保留有效版本演进，彻底清除明确排除内容、本机绝对路径和个人作者邮箱
**执行边界**：只在独立镜像仓库中操作；当前工作区和远端在验收通过前保持不变

## 1. 为什么需要重写

完整历史没有真实秘密或无权公开资产，但包含项目所有者明确要求不公开的临时素材、实验能力、本机路径和个人邮箱。清理当前树无法改变旧提交，因此必须重写所有分支和 tag。

## 2. 精确清除范围

### 整路径移除

- `temp/`
- `experiments/ai_cat_assets/`
- `doc/v0.4-comfyui-spike.md`
- `scripts/check_comfyui_aki_prereqs.ps1`
- `scripts/check_comfyui_prereqs.ps1`
- `scripts/collect_comfyui_candidates.ps1`
- `scripts/setup_comfyui.ps1`
- `scripts/start_comfyui.ps1`
- `scripts/start_comfyui_aki.ps1`

### 文本替换

- Windows 用户目录替换为 `%USERPROFILE%` 或 `<USER_HOME>`。
- 项目绝对路径替换为仓库相对路径或 `<PROJECT_ROOT>`。
- APPDATA 真实路径替换为 `%APPDATA%/LetsMakeMoney`。
- 微信、聊天输入、系统临时目录替换为 `<PRIVATE_INPUT>` 或删除仅用于过程记录的整行。
- 不使用宽泛的盘符删除规则；每条替换必须来自 A3 脱敏 inventory，避免误伤代码字符串、测试样例和文档语义。

### 作者身份重写

- 将两组个人邮箱身份统一为公开 GitHub noreply 身份。
- 作者显示名统一为 `NzyZzz1998`，除非执行前另行确认保留旧显示名。
- 旧邮箱到新身份的映射保存在仓库外的私有文件，不写入脚本、日志或提交。
- 提交作者和提交者字段同时处理；提交时间和提交消息保持不变。

## 3. 执行工具与隔离

1. 冻结当前工作区，先将未提交 v0.7 改动导出为补丁和独立文件归档。
2. 创建本地 bare mirror 与第二份只读备份，记录所有 refs、tag peel 值和对象统计。
3. 使用固定版本 `git-filter-repo`，不直接在当前工作目录运行。
4. 在 mirror 中依次执行路径移除、文本替换和作者/提交者身份重写。
5. 禁止在验证完成前 force push；远端私有仓库保持原状。

## 4. 执行前门禁

- 当前工作区所有未提交文件均有可恢复备份。
- `main`、`test`、远端追踪分支和 v0.2-v0.6 tag 的旧 SHA 清单已冻结。
- GitHub Release 与 tag 的对应关系、附件和说明已导出。
- 私有邮箱映射和绝对路径替换表已人工复核，不在仓库内保存。
- filter-repo 版本和安装来源已校验。
- 项目所有者再次确认允许改变提交 SHA、重建 tag 并最终 force push。

## 5. 重写后验证

### 历史与隐私

- Gitleaks 与 TruffleHog 重新扫描当前树及完整历史，结果必须为 0。
- `temp/`、实验素材和 7 个 ComfyUI 路径在所有 refs 中必须为 0。
- 个人邮箱在作者、提交者、文件内容和 tagger 元数据中必须为 0。
- 私有路径 inventory 在所有历史 blob 中必须为 0。
- 运行 Git fsck、对象统计和大文件审计。

### 产品与工程

- checkout `main` 和 `test`，运行文档、资产许可、第三方合规与公开候选检查。
- 运行 v0.6 回归、native 构建和包体验证；历史重写不得改变目标树业务内容。
- 对每个历史 tag 比较清洗前后目标树差异：只允许计划内移除/替换。
- 验证当前 v0.7 未提交工作可以无冲突地重新应用到清洗后的 `main`。

### GitHub

- 重建受影响的 annotated tag，并保存旧 tag 到新 tag 映射。
- Release 说明与附件不重新打包；如果 GitHub Release 的 tag 关联变化，逐个重新指向新 tag。
- 强制推送使用 `--force-with-lease` 或镜像替换前的等价保护，并在最终执行前再次人工确认。

## 6. 回滚

- 保留两个不联网的 bare 备份和旧 refs 清单。
- 远端替换前回滚：丢弃测试 mirror，不影响当前仓库。
- 远端替换后回滚：从只读备份恢复全部 heads/tags，并重新核对 Release 关联。
- 强制推送后所有旧 clone 必须重新克隆，不允许普通 pull 混合新旧历史。

## 7. 风险

- 所有受影响提交和 tag 的 SHA 会变化。
- 现有 clone、分支、PR、commit 链接和 Release 关联可能失效。
- 文本替换过宽会破坏代码或历史文档，因此必须采用精确 inventory。
- GitHub 缓存、fork 或第三方镜像可能继续保留旧对象；历史重写不能保证互联网层面的绝对删除。当前仓库尚未公开，可显著降低该风险。

## 8. 完成定义

双扫描、路径/邮箱归零、树差异审计、构建回归、heads/tags 替换和 fresh clone 复验已通过。GitHub Release 页面附件关联保留为登录态只读确认；仓库继续保持私有，不进入公开审批。

本地演练证据见 `git-history-rewrite-dry-run.md`。该演练不代表远端已经重写。
