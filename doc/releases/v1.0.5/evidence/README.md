# v1.0.5 证据目录

本目录只保存可提交、脱敏、可复核的证据摘要。原始截图、录屏、完整日志、系统资源曲线和候选解压目录保存在仓库外，并通过外部索引记录身份和可用状态。

## 当前文件

| 文件 | 作用 | 隐私边界 |
| --- | --- | --- |
| `m0-baseline.json` | M0 Git、正式 Release、dirty candidate、决策、FR 与 Mini 基线 | 不含用户名、绝对路径、工资、配置正文或秘密 |
| `m1-contract.json` | M1 candidate、published cache、证据目录和删除授权合同 | 仅含仓库相对路径与公开哈希 |
| `m2-characterization-summary.json` | M2 Mini 行为刻画、20 轮 Workbench 关闭复现、根因和环境恢复摘要 | 不含金额、精确坐标、完整日志、截图、用户名或绝对路径 |
| `m3-mini-privacy-summary.json` | M3 Mini 首次收起、焦点分离、隐私竖条与环境恢复摘要 | 不含金额、精确坐标、完整日志、截图、用户名或绝对路径 |
| `m4-calendar-presentation-summary.json` | M4 日历可信度、复合状态、候选身份与环境恢复摘要 | 不含用户配置正文、截图、完整日志或绝对路径 |
| `m5-window-surface-summary.json` | M5 三窗表面职责、真实 DPI、候选决策与环境恢复摘要 | 只含公开对象哈希、相对索引和脱敏系统状态 |
| `m6-candidate-summary.json` | 修复后 clean 候选身份、哈希与 M6 聚合结果 | 不含用户配置、原始截图、完整日志或绝对路径 |
| `acc-retest-summary.json` | 修复后独立 ACC 结果、真实链路索引、延期项与环境恢复摘要 | 只记录证据文件名和脱敏结论，不跟踪原始用户数据 |

后续候选证据使用 `doc/releases/v1.0.5/evidence/<candidate-id>/`，并分别遵循 acceptance summary 与 raw evidence index schema。

## 共同规则

1. Release、candidate 和测试对象使用 Git commit 与 SHA256 标识。
2. 仓库路径只使用 repo-relative 形式；外部证据只记录不含用户名的稳定索引。
3. 原始证据丢失时标记 `missing`，不得由后来对象的证据冒充。
4. dirty candidate 可以登记和验收，但不能通过 published 模式。
5. 所有失败门禁必须返回非零退出码。
6. 证据对应对象或合同变化时，保留历史摘要并新增重验，不改写旧结论。
7. 唯一原始证据副本不得删除；先创建可校验的第二份副本并更新索引。
8. 本地 dirty v1.0.4 candidate 的实际删除仍需项目所有者单独授权。
正式发布身份与 GitHub 回下载结果见 `release-summary.json`。该文件只保存可公开、可复核的 tag、Release、附件与 SHA256 事实，不保存本机绝对路径或原始用户数据。
