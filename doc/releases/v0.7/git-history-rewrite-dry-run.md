# LetsMakeMoney v0.7 Git 历史重写演练记录

**日期**：2026-07-11
**状态**：本地演练、远端执行和 fresh clone 复验通过
**工具**：git-filter-repo 2.47.0、Gitleaks 8.30.1、TruffleHog 3.95.9

## 1. 隔离与备份

- 当前工作区保持原状，没有执行 reset、checkout、filter-repo 或提交。
- 完整 11 refs Git bundle 已创建并通过 `git bundle verify`。
- tracked 差异保存为 binary patch，59 个 untracked 文件单独归档并生成 SHA256 清单。
- 重写只发生在仓库外的 `<PRIVATE_REWRITE_MIRROR>`。
- mirror 旁保留 pristine 副本；远端没有 push、force push、tag 或 Release 写操作。

## 2. 规则修正记录

首次演练发现 PowerShell UTF-8 BOM 使第一条 `temp/` 规则失效，并污染首条 mailmap 作者名。规则文件改为无 BOM ASCII 后从 pristine 重新执行。

第二次回归发现：

- 路径占位符直接进入 PowerShell 候选数组会产生非法路径；改为环境变量 `LMM_GODOT_EXE`、`LMM_GODOT_ROOT` 和 `LMM_MSYS2_BASH`。
- v0.4 验证脚本仍强制要求已删除的 ComfyUI Spike 文件；同步删除这组实验能力断言，保留产品和动画资源回归。

每次规则变化均从 pristine mirror 重新生成，没有在已重写历史上叠加处理。

## 3. 最终身份映射

| Ref | 旧对象 | 新对象 |
|---|---|---|
| `main` | `e6f25ae8cb4d9583aa3e629cb79416e278060117` | `bec93b9cd7f5de00ca00694a9196d87073fe6c8d` |
| `test` | `9c3092ed1a191e9a4af86b8bd668f7df69ff81ff` | `d604c369a84a309837c294e46436310dcc0f7d3b` |
| `v0.2-beta` | `4af18b53e4c3b640c02b9ddd6dde45cb1201c7a9` | `563aaa81c6e64178f42ecb22839c832386229518` |
| `v0.3-beta` | `903109a1be7b81bbd8ceae6cce0e29204a201299` | `cbdad48bc9c7181950874b777f74cb17dbf3a444` |
| `v0.4-beta` | `1f57c96ebf8d87a5ba8452d38c38c77e0cb73b00` | `4808049e8d50c4557fb7fae77b936c026cb3225a` |
| `v0.5-beta` | `7d27665f7599915fbb0e7ca456d732cd5773a9e0` | `e37c27ec5944311ca34724feea5678a7b13ec9f1` |
| `v0.6-beta` | `3cc947f2294825c49fca5106508dc16b2f4d77b5` | `5d1681b5d0647609245957569edf23d87243d007` |

annotated tag 的 peeled commit 映射保存在私有演练目录，不在公开文档重复全部内部对象关系。

## 4. 树差异

- 提交数：33 → 32。临时素材包提交清空后被自动删除。
- `main` 树变化：95 个路径。
- 删除：70，全部位于计划删除范围。
- 修改：25，均为路径文本、构建/验证环境变量或 ComfyUI 实验断言调整。
- 新增：0。
- 非预期删除：0。

## 5. 隐私与历史验证

| 检查 | 结果 |
|---|---|
| 目标临时/实验/ComfyUI 路径残留 | 0 |
| Windows 本机绝对路径残留 | 0 |
| 旧个人邮箱元数据/内容残留 | 0 |
| 作者/提交者身份 | 1 个 GitHub noreply 身份 |
| Gitleaks 完整历史 | 0 命中 |
| TruffleHog 完整历史 | 0 命中；1,096 chunks / 约 2.20 MB |
| `git fsck --full` | 通过 |
| Git 对象 | 785；pack 约 3.98 MiB |

## 6. 产品回归

在重写镜像的独立 checkout 中执行：

- v0.6 自动验证：通过。
- v0.6 配置验证：通过。
- v0.5 自动验证：通过。
- v0.4 自动验证：通过。
- M4 自动验证：通过。
- M5 导出与启动冒烟：通过，生成约 112.98 MB EXE。
- v0.6 托盘验证：普通模式和纯桌宠模式各 3 轮通过。

native DLL 由当前已验收构建复制到临时 checkout，仅用于加载现有 native 能力；没有写入重写镜像。

## 7. v0.7 工作迁移

- 原工作区最新 tracked 差异和 60 个 untracked 条目已再次冻结并校验。
- 68 个实际文件无损复制到清洗后的独立 `main`，随后清理 5 条当前树绝对路径警告。
- v0.7 工作已形成本地候选提交，作者使用 GitHub noreply 身份。
- 候选树公开检查：407 文件、0 失败、0 警告。
- 候选提交完整历史再次通过 Gitleaks、TruffleHog、目标路径/绝对路径/旧邮箱归零和 v0.4-v0.6 回归。

## 8. 远端执行结果

- 使用逐 ref lease 和原子推送替换 `main`、`test` 与 v0.2-v0.6 五个 tags；旧 SHA 全部与冻结值匹配。
- v0.7 候选提交随后修复 fresh clone 发现的 Inno Setup 许可证 EOL 哈希问题，并以新 lease 安全更新 `main`。
- 从 GitHub SSH 全新克隆后确认 `main`、`test` 和五个 tag 均指向新历史。
- fresh clone 通过公开候选 407/0/0、双扫描 0、目标路径/绝对路径/旧邮箱 0，以及 v0.4-v0.6、M4/M5 和托盘双模式回归。
- 正式本地项目已切换到新 `.git`；旧 `.git`、完整 bundle 和排除内容保存在仓库外备份。
- 仓库可见性没有修改，仍为 private；Release 页面附件关联等待登录态只读确认。

## 9. 下一门禁

进入 B1 前完成 GitHub Release 页面只读确认，并保留旧历史备份直至 v0.7 独立 Acceptance 结束。仓库公开仍受 B-E 与公开批准门禁约束。
