# v1.0.7 候选、证据与环境恢复合同

## 目录职责

| 位置 | 内容 | 是否进入 Git |
| --- | --- | --- |
| `doc/releases/v1.0.7/evidence/` | 脱敏、可长期复核的 JSON/Markdown 摘要 | 是 |
| `.artifacts/candidates/v1.0.7/<candidate-id>/` | 唯一候选、BUILD-INFO、SHA256SUMS、自动验证摘要 | 否 |
| 外部原始证据目录 | 截图、录屏、完整日志、性能采样、环境备份 | 否，仅在摘要中记录逻辑 ID |
| `releases/v1.0.7/` | 项目所有者批准后复制的发布缓存 | 发布阶段决定 |

## 候选身份

候选 ID 必须包含版本、UTC 时间、source HEAD 前缀和 clean/dirty 状态。每个候选至少记录：

- 分支、完整 HEAD、`source_tree_dirty`；
- Zip、EXE、WebView2Loader.dll、BUILD-INFO 的大小与 SHA256；
- Node、Python、Rust、MSVC、Windows SDK、WebView2 版本；
- current gate、Rust、TypeScript、打包和包体验证结论；
- 证据目录逻辑 ID。

候选目录不可覆盖。dirty candidate 不得进入正式 Release，也不得通过改名冒充 clean candidate。

## 用户环境保护

真实 GUI、失败注入或发布验收前必须备份：

- `%APPDATA%\LetsMakeMoney\config.json`；
- `%APPDATA%\LetsMakeMoney\overtime-records.json`（存在后）；
- `%APPDATA%\LetsMakeMoney\debug.log`；
- 开机启动状态；
- Mini/Workbench/Settings/Wizard 可见性和窗口位置；
- 测试涉及的 DPI、缩放、时区、系统时间和显示设置。

结束时必须停止候选进程、恢复文件与系统状态、解除失败注入权限、确认无残留进程。不得删除用户唯一数据，不得把原始日志或本机绝对路径写入仓库。

## 失败注入

- 配置和加班仓储失败使用临时副本或受控 ACL；不得直接破坏用户原文件。
- 损坏文件测试必须先复制，验证“拒绝覆盖 + 可恢复”后恢复。
- show/hide、IPC、CSP 和更新失败使用 fixture 或隔离候选。
- 失败场景必须保留输入、预期、实际、补偿结果和脱敏日志事件。

## 证据失效

候选 SHA256、HEAD、依赖、构建参数、业务合同或相关 UI 变化时，绑定证据立即失效。重构后的新证据不得冒充旧候选的原始证据；历史失败和回退结论不得删除。

## 发布边界

M0 不构建候选。只有 M7 从干净提交生成的唯一候选才可交给 ACC；ACC 通过后仍需项目所有者批准，才能提交、推送、打 tag 或创建 Release。
