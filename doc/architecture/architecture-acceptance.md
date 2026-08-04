# LetsMakeMoney 架构优化验收报告

验收日期：2026-07-30
验收类型：渐进式架构优化独立验收
结论：通过，有 2 项非阻塞观察

## 1. 验收边界

本轮验证以下架构切片在真实 Windows 候选程序中的行为等价性：

- 前端 Runtime Adapter 与 Tauri Service 边界。
- 配置领域模型、草稿事务、版本迁移与旧配置保护。
- Mini、Workbench、Settings 的跨窗口配置收敛。
- TimeService 与呈现纯函数。
- Rust Command、Service、Repository、Model 分层。
- Calendar Provider 抽象。
- 窗口隐藏、WebView2 挂起、timer 暂停与恢复。
- TypeScript strict、Rust test、Clippy、rustfmt 和聚合回归门禁。

本轮不是 v1.0.4 发布验收，不重复执行完整首次配置、通知区托盘、系统睡眠、真实 DPI 和长时间稳定运行。

## 2. 基线与候选身份

| 项目 | 结果 |
| --- | --- |
| 分支 | `main` |
| 基线 HEAD | `eb57e0b3af726f552afe68acccaa927345714da9` |
| 工作区 | 包含本轮架构优化和既有未提交文档变更 |
| 候选目录 | `E:\codex\.tmp-lmm-architecture-acceptance-20260730-224226\candidate` |
| EXE | `LetsMakeMoney.exe`，10,013,184 字节 |
| EXE SHA256 | `B7D9DEF9CBD86BBAF8F8362CF844AC23024FA74F33ED057EDC3B98A0A9433389` |
| WebView2Loader.dll | 160,320 字节 |
| DLL SHA256 | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |

候选由基线 HEAD 加当前工作区中的架构优化构建，因此发布身份以以上哈希为准，不能仅以 HEAD 代替。

## 3. 真实 Windows 验收

| 模块 | 操作与证据 | 结论 |
| --- | --- | --- |
| Mini | 正常显示下班后状态、当日金额和 100% 进度；可打开 Workbench | 通过 |
| Workbench 今日 | 显示工作状态、收入、日薪、时薪、进度和今日安排 | 通过 |
| Workbench 日历 | 2026 年 7 月官方日历、日期状态和图例正常 | 通过 |
| Settings 五页 | 五个任务页均可进入，草稿跨页保留 | 通过 |
| 无变化保存 | 未修改配置时显示“没有需要保存的更改” | 通过 |
| 成功保存 | 月薪从 10000 修改为 10001，显示成功反馈 | 通过 |
| 配置持久化 | 同一 Computer Use 环境重启后仍为 10001 | 通过 |
| 跨窗口同步 | Mini 与 Workbench 同步显示新金额 434.82 | 通过 |
| 主题草稿 | 切换深色后即时预览；关闭时弹出放弃更改确认 | 通过 |
| 取消保护 | 选择继续编辑后草稿保留；恢复浅色后无脏状态 | 通过 |
| 数据与支持 | 版本、运行环境和原生能力状态可见；数据目录可打开 | 通过 |
| Settings 隐藏 | 关闭后记录 hidden、WebView suspend，窗口不残留可见 | 通过 |
| Workbench 隐藏 | 隐藏后暂停该窗口的本地 tick 和权威同步 | 通过 |
| Workbench 恢复 | 恢复后 WebView resume、timer 重启并立即权威同步 | 通过 |
| timer 去重 | 恢复后的后续同步频率正常，没有重复注册证据 | 通过 |
| 运行日志 | 未发现 panic、fatal 或 exception | 通过 |

配置同步的手工复算：

```text
月薪 10001 ÷ 2026 年 7 月 23 个收入分配日
= 当日显示 434.82
```

Mini 与 Workbench 的真实显示结果均为 434.82。

## 4. 自动门禁

| 门禁 | 结果 |
| --- | --- |
| 架构 Runtime 行为测试 | 15/15 通过 |
| 配置领域行为测试 | 10/10 通过 |
| Desktop Service 行为测试 | 21/21 通过 |
| 呈现纯函数测试 | 18/18 通过 |
| 架构结构检查 | 22/22 通过 |
| 工具解析检查 | 2/2 通过 |
| `verify_architecture.ps1` | 退出码 0 |
| `verify_v103.ps1 -SkipExport` | 退出码 0 |
| Rust 核心测试 | 46/46 通过 |
| 配置迁移定向测试 | 11/11 通过 |
| TypeScript strict | 通过 |
| Vite 生产构建 | 通过 |
| `cargo fmt --check` | 通过 |
| `cargo clippy --all-targets --all-features -- -D warnings` | 通过 |
| `git diff --check` | 通过 |
| v1.0 至 v1.0.3 聚合验证 | 通过 |

完整命令输出保存在：

`E:\codex\.tmp-lmm-architecture-acceptance-20260730-224226\evidence`

## 5. 配置与数据安全

- 验收前备份真实用户目录中的 7 个文件。
- Computer Use 使用隔离 APPDATA，隔离配置与真实用户配置不会互相覆盖。
- 真实用户目录在普通启动检查期间只产生了日志和 previous 快照变化。
- 验收结束后已按文件恢复全部备份。
- 7 个恢复文件的 SHA256 均与验收前备份一致。
- 所有 `LetsMakeMoney.exe` 进程已结束。
- 本轮无数据库影响。

真实用户目录：

`C:\Users\win\AppData\Roaming\io.letsmakemoney.windows`

备份目录：

`E:\codex\.tmp-lmm-architecture-acceptance-20260730-224226\user-data-backup`

## 6. 非阻塞观察

### ACC-OBS-001：Mini 右键出现 WebView2 浏览器菜单

- 证据状态：已确认。
- 严重度：Minor。
- 现象：在 Mini 非交互区域右键会显示 WebView2 的浏览器菜单，包括刷新、打印和更多工具。
- 影响：不影响收入、配置、窗口同步或数据安全，但削弱桌面应用质感，并可能暴露无意义入口。
- 建议：作为后续 UI/窗口行为候选，禁用生产窗口默认浏览器上下文菜单；不要混入本轮架构提交。

### ACC-OBS-002：专用 Rust 工具链缺少质量组件

- 证据状态：已确认。
- 严重度：Minor。
- 现象：项目专用工具链最初只有 cargo、rustc 和 rust-std，缺少 clippy 与 rustfmt。
- 处置：在专用目录中安装 `clippy`、`rustfmt` 后，两项门禁均通过。
- 影响：代码无失败，但干净环境无法仅凭原工具链直接执行全部工程门禁。
- 建议：在开发环境说明或 bootstrap 中声明并验证这两个组件。

## 7. 未重复执行项

以下项目没有在本轮架构验收中重新宣称通过：

- 首次安装或全新用户的完整 Wizard。
- Windows 通知区的真实托盘左键和右键路径。
- 100%、125%、150% DPI 的完整视觉矩阵。
- Windows 睡眠、恢复、系统时间与时区跳变。
- 两小时长期稳定运行。
- 正式便携 Zip 的包内许可、README 与 Release 附件检查。

这些项目仍应由对应产品版本的发布验收负责。

## 8. 最终判断

本轮渐进式架构优化通过独立验收：

- 已验证的用户可见行为保持一致。
- 配置保存、取消、迁移和跨窗口同步没有发现数据回归。
- 窗口生命周期暂停与恢复符合设计，未发现 timer 重复注册。
- 前端、Rust 和聚合回归门禁全部通过。
- 没有发布阻塞缺陷。

可以进入架构变更代码审查与提交准备，但提交前应将本轮架构文件与工作区中既有的 `doc/current.md`、`doc/releases/v1.0.4/` 变更逐项核对，避免把无关内容混入同一提交。

## 9. 提交前审查复核

提交前代码审查随后补充修复了配置事件重复刷新、晚到监听器释放和 Mini
拖动后按钮误触发三处非阻塞稳定性问题。新增或更新的行为门禁结果为：

- 前端运行时行为测试：15/15 通过。
- Desktop Service 行为测试：21/21 通过。
- v1.0 M3 静态交互门禁：23/23 通过。
- v1.0-v1.0.3 聚合回归：通过。

这些修正不改变本报告第 7 节的发布验收边界，也不将尚未重复执行的系统级
项目改写为通过。
