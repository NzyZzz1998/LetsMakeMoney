# LetsMakeMoney v1.0.5 产物与证据合同

## 1. 目的

本合同用于区分开发候选、验收原始证据、仓库内脱敏摘要、发布收口暂存区和 GitHub Release 回下载缓存。文件名相同、包内信息自洽或位于 `releases/` 目录，均不能单独证明对象已经公开发布。

## 2. 目录所有权

| 路径 | 写入者 | 内容 | Git 策略 | 身份含义 |
| --- | --- | --- | --- | --- |
| `.artifacts/candidates/v1.0.5/<candidate-id>/` | 构建任务 | Zip、构建摘要和候选校验结果 | 忽略 | 待验收候选，不代表公开附件 |
| `.artifacts/acceptance/v1.0.5/<candidate-id>/` | 验收任务 | 原始截图、录屏、完整日志和资源曲线 | 忽略 | 受控原始证据，不直接提交 |
| `doc/releases/v1.0.5/evidence/<candidate-id>/` | 文档任务 | 脱敏摘要、哈希、结论和外部证据索引 | 跟踪 | 可复核的永久摘要 |
| `.artifacts/published/v1.0.5/<tag>/<downloaded-at>/` | 发布复核任务 | 从 GitHub Release 回下载的 Zip、校验文件和索引 | 忽略 | 仅代表已核验的远端附件副本 |
| `releases/v1.0.5/` | 发布收口任务 | 待上传的 staging 产物 | 忽略 | 不是 published cache |

`candidate-id` 采用 `V105-<UTC>-<short-head>-<clean|dirty>`；`downloaded-at` 采用 `yyyyMMddTHHmmssZ`。目录不得包含用户名、工资、Token 或本机绝对路径。

## 3. BUILD-INFO 合同

v1.0.5 候选包必须提供严格的 `BUILD-INFO.json`，字段由 `apps/windows-v1/tests/contracts/v105-build-info.schema.json` 定义。最低身份包括：

- 产品、版本、channel、平台和架构；
- 完整 `source_head` 与布尔值 `source_tree_dirty`；
- UTC 构建时间 `build_timestamp_utc`；
- EXE、WebView2Loader、双语便携 README、许可文件和日历资源 SHA256；
- README 来源与日历数据版本。

Candidate 模式允许 `source_tree_dirty=true`，但必须显式记录。Published 模式只接受 `source_tree_dirty=false`，并要求 tag 目标、`source_head`、GitHub Release URL、回下载 Zip SHA256 和 `SHA256SUMS.txt` 全部一致。

## 4. 验收证据合同

仓库内只保存脱敏摘要与索引：

- `v105-acceptance-summary.schema.json`：候选身份、环境、分项结论、限制和脱敏日志摘要；
- `v105-raw-evidence-index.schema.json`：外部原始证据的可用状态、内容种类、保管角色和哈希；
- `v105-published-cache-index.schema.json`：回下载来源、tag、提交、时间和附件哈希。

原始证据不得提交用户名、完整本机路径、工资配置、Token、未脱敏日志或其他用户数据。原始证据丢失时，索引必须标记 `missing`；后续重新运行得到的证据只能新增，不能冒充旧候选的原始证据。

## 5. 唯一副本保护

1. `unique_copy=true` 的原始证据不得删除、移动或覆盖；必须先创建可校验的第二份副本并更新索引。
2. 被验收引用的 candidate 在永久摘要、原始证据索引和结论尚未完成前不得清理。
3. Published cache 只能由 GitHub Release 回下载产生，不能从本地 candidate 复制后改名。
4. Candidate、acceptance、published cache 和仓库摘要由各自任务写入，禁止互相覆盖。
5. 对象任一 SHA256、source HEAD、dirty 状态或目录身份变化，依赖该对象的验收证据立即失效，历史摘要保留。

## 6. 本地 dirty v1.0.4 candidate

当前对象继续保留，其 Zip SHA256 为 `C67E730BF81741D03BFAF6D14F3F16EB74FD8591D8B3AB76D45A980E854C249B`；它不是 GitHub v1.0.4 正式附件。未来删除必须同时满足：

1. 已永久记录相对路径、大小、Zip SHA256、`BUILD-INFO.json`、source HEAD 和 dirty 状态；
2. GitHub v1.0.4 正式 Zip 已重新下载到 published cache；
3. 正式副本通过 published 模式，SHA256 为 `C4F28892831891A4266C4D9B12D432CD5C970BB3C9B36A6B8DB21FA2566DE50E`；
4. 相关脱敏摘要与外部原始证据索引已经保留；
5. 项目所有者对精确文件路径给出单独清理授权；
6. 操作仅删除该本地 candidate，不修改 Git 历史、tag、Release 或正式附件。

任一条件不满足都必须保留文件。本里程碑不执行删除。

## 7. 验证入口

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\verify_v105.ps1 -Milestone M1
```

该入口验证 README 当前事实、目录 ignore 边界、schema、candidate/published 身份负向夹具、M0 继承证据、业务代码零差异和 `git diff --check`。它不构建、不打包，也不把合成测试包视为发布候选。
