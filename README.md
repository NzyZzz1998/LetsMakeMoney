<div align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="LetsMakeMoney：把工作时间变成看得见的收入进度">
</div>

<div align="center">
  <a href="README.en.md">English</a> ·
  <a href="https://github.com/NzyZzz1998/LetsMakeMoney/releases">下载</a> ·
  <a href="doc/current.md">当前状态</a> ·
  <a href="doc/releases/v1.0.1/README.md">v1.0.1 文档</a>
</div>

## 一眼知道今天赚了多少

LetsMakeMoney 是一款本地优先的 Windows 收入进度工具。配置月薪、休息模式和工作时间后，它会把抽象的月薪换算成今日已赚、工作进度、距离下班时间和月度累计。

迷你收入视图适合常驻桌面；需要更多信息时，再打开今日与日历工作台。无需账号，配置和日志都保存在本机。

<div align="center">
  <img src="assets/readme/workbench.png" width="900" alt="LetsMakeMoney v1.0 今日收入工作台">
</div>

## 主要能力

| 日常查看 | 配置与可靠性 | Windows 体验 |
| --- | --- | --- |
| 今日已赚、工作进度、距离下班 | 三步首次配置与任务化设置 | 可拖动的迷你收入视图 |
| 今日安排、日薪、时薪、月度累计 | 保存成功、无变化与失败保留输入 | 原生托盘隐藏、找回与退出 |
| 单休、双休、大小周与午休计算 | 配置损坏恢复与本地诊断摘要 | 100%、125%、150% DPI 验证 |
| 工作日、周末、节假日与手动调整 | 用户确认式更新检查 | 不静默更新，不强占任务栏 |

## 当前版本

**v1.0.1 Stable 候选**在 v1.0 的无宠物产品结构上修正日历、日期调整、跨夜班次和金额精度。

- 当前公开版本为 [v1.0 Stable](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0)。
- v1.0.1 已完成实现与独立验收，尚未发布。
- v1.0.1 内置 2025/2026 中国大陆节假日与调休数据，支持工作日、带薪休息、不带薪休息和恢复自动。
- 收入按秒展示并定期权威同步，整月金额按分守恒。
- v1.0 已完成自动门禁、真实 Windows 验收和发布收口。
- v1.0 暂不包含宠物、透明宠物窗口、点击穿透、纯桌宠模式、云同步、主题系统或安装器。
- 需要桌宠体验时，可以继续使用 `v0.9-beta` tag 对应的 v0.9 Beta；它也是 v1.0 的明确回退基线。

最新事实与发布哈希以 [当前状态入口](doc/current.md) 为准。

## 从源码运行

### 环境

- Windows 10/11 x86_64
- Node.js 22+
- Rust stable MSVC 工具链
- Microsoft Edge WebView2 Runtime

### 启动

```powershell
git clone https://github.com/NzyZzz1998/LetsMakeMoney.git
cd LetsMakeMoney\apps\windows-v1
npm install
npm run tauri dev
```

### 构建便携程序

```powershell
# 在仓库根目录执行
powershell -ExecutionPolicy Bypass -File .\scripts\package_v101.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v101_package.ps1
```

候选产物位于 `releases\v1.0.1\`。构建和验证不应依赖未声明的本机路径或私有文件。

## 数据、隐私与回退

v1.0 的配置与日志目录：

```text
%APPDATA%\io.letsmakemoney.windows\
```

- 不需要账号，不上传工资或作息配置。
- 诊断摘要会对本机路径等信息进行脱敏。
- 从 v0.9 首次迁移时保留兼容备份。
- 回退前请退出 v1.0，并按 [v0.9 回退指南](doc/releases/v1.0/v0.9-rollback.md) 恢复旧配置。

## 验证

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v101.ps1 -SkipReleaseBuild
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_docs.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v101_package.ps1
```

自动测试覆盖工资计算、配置事务、窗口合同、托盘桥接、文档和包完整性。真实通知区、任务栏、DPI 与重启恢复仍以 Windows 桌面验收为准。

## 项目结构

```text
apps/windows-v1/       v1.0 Tauri + React 正式客户端
shared/                节假日与共享数据
scripts/               验证、打包和合规检查
doc/current.md         当前唯一内部事实入口
doc/releases/v1.0.1/   v1.0.1 PRD、进度、验收与发布文档
```

## 参与项目

欢迎代码、文档、测试与 Windows 体验贡献。开始前请阅读：

- [贡献指南](CONTRIBUTING.md)
- [行为准则](CODE_OF_CONDUCT.md)
- [安全策略](SECURITY.md)

## 许可

项目原创代码与文档采用 [MIT License](LICENSE)。v1.0 当前发布包不包含宠物或其他受限视觉素材；v0.9 历史视觉资产仍适用对应版本的受限素材许可。第三方组件与再分发信息见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
