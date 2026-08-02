# LetsMakeMoney Windows v1.0.6 发布说明

> 状态：**已发布。** 本文件描述正式范围；最终提交、附件大小和 SHA256 已与 GitHub Release 及回下载附件核对一致。

## 本版重点

### 主题首帧一致性

- Rust 配置与进程内 ThemeSession 成为浅色/深色主题的唯一权威来源。
- Mini、Workbench、Settings 与 Wizard 在 React 首帧前读取同一权威主题。
- 清除旧 WebView `localStorage` 主题缓存的权威性，避免浅色配置首次打开辅助窗口时闪成深色。
- 晚注册监听器、窗口隐藏与恢复会主动补读当前主题快照。

### 配置事务安全

- Settings 与 Wizard 在权威配置 hydration 完成前禁止保存默认草稿。
- 主题预览、保存、无变化、放弃和异常退出保持同一事务语义。
- Settings/Wizard 的原生 Alt+F4 关闭请求进入 React 未保存确认，不再绕过主题回滚。

### 可诊断性与回归门禁

- 增加主题加载、窗口应用、预览提交、回滚和窗口关闭路由的语义日志。
- 增加首帧、跨窗口、晚监听、代际、非法值回退和 hydration 行为测试。
- 发布包继续使用隔离候选目录、干净源码身份和 published 回下载复核。

## 兼容性与边界

- Windows 10/11 x86_64；本轮真实 GUI 环境为 Windows 11。
- Windows 10 与真实多显示器保持环境待补证，不冒充通过，也不阻塞该定向维护版。
- 不改变收入、日历、日期调整、配置 schema、Mini 隐私贴边或窗口视觉。
- 不恢复宠物，不新增账号、云同步、安装器或静默更新。

## 发布附件

正式 GitHub Release 只允许包含：

1. `LetsMakeMoney-v1.0.6-windows-x86_64.zip`
2. `SHA256SUMS.txt`

历史 dirty 候选、rebase 前干净候选、截图、日志和临时目录不得作为 Release 附件。

## 正式发布身份

- 发布源提交：`51e4c08da5260af9b9f4808c4f6d29591319e655`。
- tag：`v1.0.6`。
- Release：`https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.6`。
- Zip：3,245,194 字节；SHA256 `AEE4BC4A41D3839E421138D0B152EA5A8B0FBDC60C5B189EA11790DE4ED8B66A`。
- EXE：10,140,160 字节；SHA256 `21EAC751534F4D0787DEC07545F315326E9C5D773F39D65D9F46AA1879518659`。
- WebView2Loader：160,320 字节；SHA256 `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- Release 仅包含便携 Zip 与 `SHA256SUMS.txt`；published 模式验证通过。
