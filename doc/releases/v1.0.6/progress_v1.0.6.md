# LetsMakeMoney Windows v1.0.6 进度

## 状态

- 当前阶段：定向 Bugfix、全量自动回归、候选构建、真实 Windows 身份冒烟与发布授权完成；进入受保护分支发布收口。
- 基线：v1.0.5 Stable，发布源码提交 `ffc431af3fbf7c3b54bca8aaff44946cc8d6aeaf`。
- 当前分支：`release/v1.0.6`。
- 当前开发版本：`1.0.6`。
- 发布判断：技术门禁与授权通过；必须先合并 PR，再从合并后的干净 `main` 重建，禁止复用历史候选附件。

## Checklist

- [x] 完成 v1.0.6 维护版本 Review 与问题池。
- [x] 建立 Rust 进程内 persisted/preview ThemeSession。
- [x] 四窗口在 React 渲染前读取权威主题。
- [x] 删除旧 `lmm.theme` 的读取和写入权威性。
- [x] 晚注册监听器补读当前主题快照。
- [x] hidden/shown 恢复时重新收敛主题。
- [x] Settings/Wizard hydration 未完成时拒绝保存。
- [x] 补齐主题事务、代际、晚监听和 hydration 行为测试。
- [x] 补齐 v1.0.6 版本与候选发布入口。
- [x] 修正公开 v1.0.5 / 开发 v1.0.6 文档事实。
- [x] 构建并锁定受控 dirty 隔离候选 Zip、EXE 与 DLL 身份。
- [x] 完成浅色/深色冷启动和四窗口首帧真实 GUI 验收。
- [x] 完成预览、放弃、保存、隐藏恢复、异常退出和非法值回退复验。
- [x] 修复并复验 Settings/Wizard 原生 Alt+F4 绕过未保存事务的问题。
- [x] 恢复用户环境并给出最终发布判断。
- [x] 从干净提交重建正式候选并对新哈希执行身份冒烟。
- [x] 项目所有者授权执行 v1.0.6 发布收口。
- [ ] 通过受保护分支 PR 和必需 Windows CI 合入 `main`。
- [ ] 从合并后的干净 `main` 重建最终候选并执行 M6 与桌面冒烟。
- [ ] 创建并推送 annotated tag `v1.0.6`。
- [ ] 创建 Stable GitHub Release，仅上传便携 Zip 与 `SHA256SUMS.txt`。
- [ ] 回下载附件并通过 published 模式与 SHA256 复核。

## 阻塞

- 无技术或授权阻塞；最终合并提交、附件哈希和回下载证据尚待生成。
- Windows 10 无受控设备或 VM；真实多显示器延续既有补证边界。

## 证据入口

- [自动与候选验证](verification.md)
- [问题池](issue-pool.md)
- [实现与根因记录](../../logs/v1.0.6-bugfix-log.md)
- 本地原始证据：`.artifacts/acceptance/v1.0.6/20260802-204009/`（Git 忽略）。
- 干净候选身份：`.artifacts/candidates/v1.0.6/V106-20260802T151034Z-ced768ab-clean/candidate-identity.json`（Git 忽略）。
- 干净候选 GUI 冒烟：`.artifacts/acceptance/v1.0.6/20260802-231417-clean-smoke/`（10 张截图，Git 忽略）。
