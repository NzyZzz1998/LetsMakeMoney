# LetsMakeMoney Windows v1.1.0 发布检查

> 状态：旧干净候选已因 `V110-BUG-001` 淘汰；最新体量与拖拽调度修正已进入干净测试候选并通过自动门禁，真实桌面结论仍为部分通过，未发布。

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

- [x] 从包含拖拽失焦修复的干净提交运行 `scripts/package_v110.ps1` 生成最终候选。
- [x] 最终候选通过 `scripts/verify_v110_package.ps1 -Mode candidate`。
- [x] 最终 Zip、EXE、DLL、README 和 BUILD-INFO 身份锁定；旧候选明确拒绝发布。
- [x] 最终包内无配置、日志、截图、验收证据、PetManager 生产目录或 Spike 中间产物。

当前测试 Candidate ID：`V110-20260813T081246Z-f5ae4ac3-clean`；Zip SHA256：`E79D3716400D74E9E2F5419700B97630F273AA67761982081AED07E8C87C6EB7`。

## 真实验收

- [ ] 100%、125%、150% DPI 通过（可见性、裁切和命中已通过；最终 Zip 的 500ms 拖拽未在三档完整重复）。
- [ ] 托盘、任务栏与退出通过（左键隐藏/恢复及右键菜单渲染通过；菜单命令和退出待补证）。
- [ ] 包损坏桌面回落通过。
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
