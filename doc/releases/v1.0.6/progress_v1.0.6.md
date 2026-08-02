# LetsMakeMoney Windows v1.0.6 进度

## 状态

- 当前阶段：定向 Bugfix、自动回归和受控 dirty 候选真实 Windows 验收完成；等待干净提交重建正式候选。
- 基线：v1.0.5 Stable，发布源码提交 `ffc431af3fbf7c3b54bca8aaff44946cc8d6aeaf`。
- 当前分支：`release/v1.0.5`。
- 当前开发版本：`1.0.6`。
- 发布判断：当前 dirty 候选不可发布；定向验收通过后可进入干净提交、重建与新身份冒烟。

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
- [ ] 从干净提交重建正式候选并对新哈希执行身份冒烟。

## 阻塞

- 当前候选由 dirty 工作树构建，身份文件明确禁止发布。
- 干净提交后的 Zip、EXE 与 DLL 将产生新哈希，必须重新锁定并冒烟。
- Windows 10 无受控设备或 VM；真实多显示器延续既有补证边界。

## 证据入口

- [自动与候选验证](verification.md)
- [问题池](issue-pool.md)
- [实现与根因记录](../../logs/v1.0.6-bugfix-log.md)
- 本地原始证据：`.artifacts/acceptance/v1.0.6/20260802-204009/`（Git 忽略）。
