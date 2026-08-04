# LetsMakeMoney Windows v1.0.1 发布检查清单

## 版本与范围

- [x] 版本号为 `1.0.1`
- [x] 发布类型为 Stable 补丁版本
- [x] 只包含 `V101-FR-001` 至 `V101-FR-008`
- [x] 未恢复宠物或引入范围外能力

## 实现与数据

- [x] 2025/2026 官方日历数据与 manifest 已校验
- [x] 日期调整事务、迁移、失败补偿和持久化完成
- [x] 跨夜 owner date 完成
- [x] 秒级收益与 30 秒权威同步完成
- [x] 整数分累计与月末守恒完成

## 验证

- [x] v1.0.1 M0-M4 门禁通过
- [x] Rust 测试通过
- [x] TypeScript 行为测试通过
- [x] Web 生产构建通过
- [x] v1.0 核心回归通过
- [x] 新解压候选真实 GUI 验收通过
- [x] 包结构、版本、日历资源与哈希验证通过
- [x] `V101-BUG-001`、`V101-BUG-002` 定向复验通过
- [x] 干净提交 `4d00f97ff908d58f4ca14a6218377386c10bdc19` 重新构建并通过包体验证
- [x] 正式上传 Zip SHA256 锁定为 `DB45332F908669445B34FF40C490936B0EEAC0B41DC2FCDC2F5806924E5D1AC2`
- [ ] Windows 睡眠/恢复人工补证
- [ ] 系统时间/时区变化人工补证
- [ ] 连续两小时稳定运行

## 文档与合规

- [x] progress、verification、manual verification 已更新
- [x] release notes、traceability、current、CHANGELOG 已更新
- [x] README 中英文候选口径已更新
- [x] UTF-8、乱码、本地链接和 `git diff --check` 通过
- [x] 包内不含配置、日志、验收证据或临时目录

## 发布动作

- [x] 项目所有者确认发布
- [x] 创建发布提交
- [x] 推送 `main`
- [x] 创建并推送 `v1.0.1` tag
- [x] 创建 GitHub Release
- [x] 上传便携 Zip 与 `SHA256SUMS.txt`
- [x] 发布后核对远端哈希

当前结论：v1.0.1 Stable 已发布，无发布阻塞。
