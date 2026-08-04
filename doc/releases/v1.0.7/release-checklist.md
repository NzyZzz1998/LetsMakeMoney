# LetsMakeMoney Windows v1.0.7 发布检查

> 状态：全部通过，v1.0.7 Stable 已发布。

## 代码与身份

- [x] 项目所有者批准 v1.0.7 有意变更并授权创建发布提交。
- [x] `main` 发布源工作树干净，候选 `source_head` 等于发布提交 `f500ed4e7de28ec68b2a848da6fa2340420b91b2`。
- [x] npm、Cargo、Tauri、应用可见版本、README 和更新检查口径一致。
- [x] current manifest 与 required CI 使用唯一入口。

## 自动门禁

- [x] `scripts/verify_windows_current.ps1` 通过。
- [x] `scripts/package_v107.ps1` 从干净提交生成唯一候选。
- [x] `scripts/verify_v107.ps1 -Milestone M7 -CandidatePath <dirty acceptance Zip>` 通过。
- [x] candidate/published 负向夹具通过。
- [x] TypeScript strict、行为测试、Vite、Rust test/fmt/clippy/release 通过。
- [x] 文档、UTF-8、乱码、链接、隐私、敏感路径和 `git diff --check` 通过。

## 候选与包体

- [x] Zip、EXE、WebView2Loader、README、README.en、BUILD-INFO 和许可文件 SHA256 已锁定。
- [x] dirty 验收候选包内只包含登记文件，无日志、配置、缓存、截图、证据、临时目录或未知二进制。
- [x] `BUILD-INFO.json` 记录干净 HEAD、UTC 构建时间和完整文件身份。
- [x] `SHA256SUMS.txt` 与最终 Zip 一致。

## Dirty 验收候选

- [x] `V107-M7-DIRTY-20260803-01` 的 Zip、EXE、DLL、README 和 BUILD-INFO 身份已锁定。
- [x] 该候选已明确标记 `publication_allowed=false`。
- [x] 独立 GUI 验收完成，结论为未通过。
- [x] `V107-M7-DIRTY-20260804-02` 的 Zip、EXE 和 DLL 身份已锁定，包体验证通过。
- [x] 修复候选已明确标记 `publication_allowed=false`。
- [x] 版本读取与 Workbench 两项阻塞的真实 GUI 定向复验通过；首次失败记录未被覆盖。
- [x] `V107-M7-DIRTY-20260804-03` 的 Zip、EXE、DLL 和 BUILD-INFO 身份已锁定，包体验证通过。
- [x] 高 DPI 首次失败与修复后通过证据并存，DPI 修复候选明确标记 `publication_allowed=false`。
- [x] 创建干净发布提交并重新生成最终候选 `V107-RELEASE-20260804-FINAL`。

## 真实 Windows 验收

- [x] Windows 11 单显示器 100% DPI 已执行；多数视觉与业务路径通过。
- [x] Windows 11 单显示器 125% DPI 通过。
- [x] Windows 11 单显示器 150% DPI 通过。
- [x] Mini/Workbench、日期调整、加班、日历与核心回归通过。
- [x] 通知区真实鼠标左键隐藏、再次左键恢复、右键菜单及任务栏组合通过。
- [x] Windows 10 未进入已验证支持声明。
- [x] 多显示器标记暂不验证，未进入通过声明。
- [x] 用户环境已恢复且无残留进程。

## 缺陷与剩余发布门禁

- [x] `V107-BUG-001`：最小版本读取 capability 已接入，关于页显示 `1.0.7` 且更新检查恢复可用。
- [x] `V107-BUG-002`：Workbench 复用窗口按精确 transaction 确认，连续打开三次均未触发 watchdog。
- [x] `V107-BUG-003`：六周日历摘要在真实 125%/150% DPI 下修复后通过。
- [x] 三项修复均有自动行为测试、新候选哈希和真实 GUI 定向复验。
- [x] 真实 Windows 125%/150% DPI 已补证。

## 发布授权

- [x] 项目所有者单独批准提交、推送、tag 和 GitHub Release。
- [x] Release 只上传便携 Zip 与 `SHA256SUMS.txt`。
- [x] Annotated tag `v1.0.7` 指向发布源提交。
- [x] GitHub Release 已创建，附件重新下载后 SHA256 一致。
- [x] downloaded published package verification 通过。
