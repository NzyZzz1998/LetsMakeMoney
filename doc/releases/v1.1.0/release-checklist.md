# LetsMakeMoney Windows v1.1.0 发布检查

> 状态：本地候选准备中，未发布。

## 代码与身份

- [ ] 桌宠正式实现形成单独本地提交。
- [ ] 发布源工作树干净；Spike、缓存、截图、日志和临时证据未暂存。
- [ ] npm、Cargo、Tauri、Cargo.lock 与 current manifest 均为 `1.1.0`。
- [ ] `v1.0.8` tag 仍指向原收官提交。
- [ ] 唯一 current gate 为 `scripts/verify_windows_current.ps1`。

## 自动门禁

- [ ] current gate、TypeScript strict、Vite、Rust test/fmt/clippy 全部通过。
- [ ] config v9、Mini/Classic 互斥、状态机、动态命中和坏包 fixture 通过。
- [ ] Classic 包 allowlist、哈希、许可与 provenance 通过。
- [ ] UTF-8、乱码、绝对路径、敏感信息和 `git diff --check` 通过。

## 候选与包体

- [ ] `scripts/package_v110.ps1` 从干净提交生成候选。
- [ ] `scripts/verify_v110_package.ps1 -Mode candidate` 通过。
- [ ] Zip、EXE、DLL、README 和 BUILD-INFO 身份锁定。
- [ ] 包内无配置、日志、截图、验收证据、PetManager 生产目录或 Spike 中间产物。

## 真实验收

- [ ] 100%、125%、150% DPI 通过。
- [ ] 托盘、任务栏与退出通过。
- [ ] 包损坏桌面回落通过。
- [ ] 30 分钟连续观感通过。
- [ ] 两小时稳定运行通过。
- [ ] 用户配置、日志、DPI 和进程状态已恢复。

## 发布授权

- [ ] 项目所有者批准推送 `main`。
- [ ] 项目所有者批准创建并推送 `v1.1.0` tag。
- [ ] 项目所有者批准创建 GitHub Release。
- [ ] Release 只上传便携 Zip 与 `SHA256SUMS.txt`。

未勾选项完成前不得公开发布。
