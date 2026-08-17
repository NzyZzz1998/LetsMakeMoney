# LetsMakeMoney Windows v1.1.0 发布检查

> 状态：旧干净候选已因 `V110-BUG-001` 淘汰；行为候选已通过本机真实桌面验收，最终干净候选已完成重建、自动门禁、包体审计与启动冒烟，未发布。

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

- [x] 从包含最终验收文档的干净提交运行 `scripts/package_v110.ps1` 重建最终发布候选。
- [x] 最终重建候选通过 `scripts/verify_v110_package.ps1 -Mode candidate`。
- [x] 最终 Zip、EXE、DLL、README 和 BUILD-INFO 身份锁定；旧候选明确拒绝发布。
- [x] 最终包内无配置、日志、截图、验收证据、PetManager 生产目录或 Spike 中间产物。

最终 Candidate ID：`V110-20260817T031659Z-71616e2e-clean`；Zip SHA256：`DA11AAD0928E52DEEBA366E834FBAFD6182CD5F107FCBA01E9BDFA14D1898527`。

## 真实验收

- [x] 100%、125%、150% DPI 通过，覆盖可见性、裁切、命中和 500ms 拖拽闭环。
- [x] 托盘、任务栏与退出通过，覆盖左键隐藏/恢复、右键菜单命令和退出后进程状态。
- [x] 隔离坏包夹具 3/3 回落通过；精确 EXE 内嵌资源原位损坏因无安全注入入口列为暂不验证。
- [x] 30 分钟连续观感通过。
- [x] 两小时稳定运行通过。
- [x] 拖拽期间截图/窗口失焦可安全取消并恢复后续交互。
- [x] 用户配置、日志、DPI 和进程状态已恢复。

精确桌面包损坏缺少不改变候选身份的安全注入入口；自动坏包夹具 3/3 通过，该项仍不得写成真实桌面通过。

## 发布授权

- [ ] 项目所有者批准推送 `main`。
- [x] 项目所有者批准推送 `test`，仅用于继续验收。
- [ ] 项目所有者批准创建并推送 `v1.1.0` tag。
- [ ] 项目所有者批准创建 GitHub Release。
- [ ] Release 只上传便携 Zip 与 `SHA256SUMS.txt`。

未勾选项完成前不得公开发布。
