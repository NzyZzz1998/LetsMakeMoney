# LetsMakeMoney Windows v1.1.0 发布检查

> 状态：`V110-BUG-003` 至 `V110-BUG-007` 已关闭并进入 clean 主线。项目所有者确认本轮问题基本解决，并明确批准推送与创建 `v1.1.0` tag；GitHub Release 仍冻结。

## 代码与身份

- [x] 桌宠正式实现形成单独本地提交。
- [x] 发布源工作树干净；Spike、缓存、截图、日志和临时证据未暂存。
- [x] npm、Cargo、Tauri、Cargo.lock 与 current manifest 均为 `1.1.0`。
- [x] `v1.0.8` tag 仍指向原收官提交。
- [x] 唯一 current gate 为 `scripts/verify_windows_current.ps1`。

## 自动门禁

- [x] current gate、TypeScript strict、Vite、Rust test/fmt/clippy 全部通过。
- [x] config v9、Mini/Classic 互斥、状态机、动态命中和坏包 fixture 通过。
- [x] Classic 包 allowlist、哈希、许可与 provenance 通过。
- [x] UTF-8、乱码、绝对路径、敏感信息和 `git diff --check` 通过。

## 候选与包体

- [x] 从干净主线提交 `642b0dd3cf5af5347aa9d9d92000f200eafb7850` 运行 `scripts/package_v110.ps1` 重建候选。
- [x] 候选 `V110-20260817T120916Z-642b0dd3-clean` 通过 `scripts/verify_v110_package.ps1 -Mode candidate`。
- [x] 该候选 Zip、EXE、DLL、README、BUILD-INFO、manifest 与 package tree 身份锁定；tag 文档提交后仍须重新构建 Release 附件。
- [x] 最终包内无配置、日志、截图、验收证据、PetManager 生产目录或 Spike 中间产物。

已淘汰 Candidate ID：`V110-20260817T031659Z-71616e2e-clean`；Zip SHA256：`DA11AAD0928E52DEEBA366E834FBAFD6182CD5F107FCBA01E9BDFA14D1898527`。当前 dirty 定向候选不可发布。

## 真实验收

- [x] 100%、125%、150% DPI 通过，覆盖可见性、裁切、命中和 500ms 拖拽闭环。
- [x] 托盘、任务栏与退出通过，覆盖左键隐藏/恢复、右键菜单命令和退出后进程状态。
- [x] 隔离坏包夹具 3/3 回落通过；精确 EXE 内嵌资源原位损坏因无安全注入入口列为暂不验证。
- [x] 30 分钟连续观感通过。
- [x] 两小时稳定运行通过。
- [x] 拖拽期间截图/窗口失焦可安全取消并恢复后续交互。
- [x] 用户配置、日志、DPI 和进程状态已恢复。
- [x] 新 clean 候选中执行“切换 Classic → 关闭 Workbench → 立即拖拽”，全程不得恢复 Mini。
- [ ] Mini 左右边缘各连续贴边 10 次，每次释放后均自动收起，移入展开和移出再收起正常。

定向真实 GUI：项目所有者确认 Workbench/Classic 恢复问题已解决，并在修复后的候选上确认贴边自动隐藏“现在好多了”。因未逐次报告左右各 10 次结果，上述统计项保持未勾选；项目所有者已接受该项作为非阻塞发布后观察风险，不将其伪写为 20/20 通过。

精确桌面包损坏缺少不改变候选身份的安全注入入口；自动坏包夹具 3/3 通过，该项仍不得写成真实桌面通过。

## 发布授权

- [x] 项目所有者批准推送 `main`。
- [x] 项目所有者批准推送 `test`，仅用于继续验收。
- [x] 项目所有者在新 clean 候选复验后重新批准创建并推送 `v1.1.0` tag。
- [ ] 项目所有者在新 clean 候选复验后重新批准创建 GitHub Release。
- [x] Release 只上传便携 Zip 与 `SHA256SUMS.txt`。

当前只允许推送 `v1.1.0` tag。GitHub Release 授权与最终 Release 附件重建仍未完成，不得创建 Release。
