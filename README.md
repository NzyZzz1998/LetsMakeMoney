<div align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="LetsMakeMoney：在 Windows 桌面随时看见今天的收入进度">
</div>

<div align="center">
  <a href="README.en.md">English</a> ·
  <a href="https://github.com/NzyZzz1998/LetsMakeMoney/releases">下载稳定版</a> ·
  <a href="doc/current.md">项目状态</a> ·
  <a href="doc/releases/v1.0.F/README.md">v1.0 Final 候选</a>
</div>

## 今天的工作，值多少钱？

LetsMakeMoney 是一款本地优先的 Windows 收入进度工具。设置月薪、工作时间和休息方式后，它会把抽象的月薪换算成今日已赚、工作进度、距离下一阶段的时间和月度工时汇总。

Mini 收入视图可以安静地留在桌面；需要调整日期、记录加班或查看整月安排时，再打开完整工作台。无需账号，工资、作息、加班记录和日志都保存在本机。

<div align="center">
  <img src="assets/readme/workbench.png" width="900" alt="LetsMakeMoney 今日收入工作台，使用演示数据">
  <br>
  <sub>真实 Windows 界面，图中为演示数据。</sub>
</div>

## 核心体验

| 随时看见进度 | 理解每个工作日 | 保持桌面私密 | 本地可靠运行 |
| --- | --- | --- | --- |
| 今日已赚、阶段倒计时、工作进度 | 单休、双休、大小周与跨夜班次 | Mini 贴边自动收起敏感金额 | 配置事务、损坏恢复与诊断摘要 |
| 今日安排、日薪、时薪和月度累计 | 官方日历、估算年份和手动日期调整 | 悬停展开、移开收起、托盘找回 | 浅色/深色主题与本地持久化 |
| 按日记录加班和月度工时总结 | 带薪休息、不带薪休息与调休工作日 | Workbench 打开时自动隐藏 Mini | 100%、125%、150% DPI 验证 |

## 三步开始使用

1. 从 [Releases](https://github.com/NzyZzz1998/LetsMakeMoney/releases) 下载最新稳定版便携 Zip。
2. 解压后运行 `LetsMakeMoney.exe`，按引导填写月薪、休息模式和工作时间。
3. 在 Mini 查看实时进度；从托盘打开今日工作台、设置或重新配置。

当前不提供安装器或静默更新。应用只会在用户确认后检查和打开更新页面。

## v1.0 Final 候选

| 事实 | 当前状态 |
| --- | --- |
| 当前公开稳定版 | [v1.0.7 Stable](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.7) |
| `test` 分支候选 | v1.0.8，内部代号 v1.0.F |
| 候选定位 | v1.0 系列最终质量版本，尚未打 tag 或创建 Release |
| 已完成 | 自动门禁、核心 GUI、浅/深主题、Windows 11 单显示器 100%/125%/150% DPI |
| 待补证 | Windows 通知区真实鼠标流程与任务栏策略 |

v1.0.8 候选进一步收口了：

- 采用 L2“燕麦石墨”Logo，统一应用、窗口、任务栏和托盘品牌入口。
- 加班记录使用动态上限；自然周末手动设为工作日时，可在同一事务中联动记录加班。
- 日期调整与加班保存具备失败回滚和旧数据保护，不静默裁剪历史记录。
- 统一 TimeField、Combobox、窗口表面与隐私竖条的交互和视觉合同。
- 冷启动、候选身份、版本事实源和发布包完整性由唯一 current gate 约束。

候选身份、哈希和验收边界见 [v1.0 Final 验证记录](doc/releases/v1.0.F/verification.md)。`test` 分支仅用于发布前复核，不能替代正式 Release。

## 数据与隐私

```text
%APPDATA%\io.letsmakemoney.windows\
```

- 无需注册或登录，不上传工资、作息、日期调整或加班记录。
- 诊断摘要会隐藏本机路径等机器特定信息。
- Mini 贴近工作区左右边缘后可以收起金额，只保留非金额阶段提示。
- 官方日历未覆盖的年份会明确标记为“估算”，不会伪造官方节假日或调休数据。
- v0.9 桌宠版保留在 [`v0.9-beta`](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.9-beta)，不进入当前 v1.0 产品主线。

## 支持边界

- **已验证：** Windows 11 x86_64，单显示器，100% / 125% / 150% DPI。
- **运行前提：** Microsoft Edge WebView2 Runtime。
- **尽力兼容：** Windows 10 x86_64；当前缺少真实设备或 VM 证据。
- **暂未验证：** 多显示器，不进入已验证通过声明。

完整边界见 [v1.0 Final 支持矩阵](doc/releases/v1.0.F/support-matrix.md)。

## 从源码运行

### 环境

- Node.js 22+
- Python 3.12
- Rust 1.97.1 MSVC 工具链
- Visual Studio 2022 Build Tools（Desktop development with C++）
- Windows SDK 与 Microsoft Edge WebView2 Runtime

```powershell
git clone https://github.com/NzyZzz1998/LetsMakeMoney.git
cd LetsMakeMoney\apps\windows-v1
npm install
npm run tauri dev
```

### 验证与打包

```powershell
# 仓库根目录：唯一当前验证入口
powershell -ExecutionPolicy Bypass -File .\scripts\verify_windows_current.ps1

# 生成隔离的 v1.0.8 本地候选，不覆盖正式发布附件
powershell -ExecutionPolicy Bypass -File .\scripts\package_v10f.ps1
```

本地候选只写入 `.artifacts\candidates\v1.0.8\<candidate-id>\`。同名本地 Zip 不能证明 GitHub Release 身份，正式下载始终以 Releases 页面及其 SHA256 文件为准。

## 仓库结构

```text
apps/windows-v1/       Tauri 2 + React 19 Windows 客户端
shared/                官方日历与共享数据
scripts/               current gate、打包和合规检查
doc/current.md         当前项目事实入口
doc/releases/v1.0.F/   v1.0.8 PRD、进度、验收与发布准备
```

## 参与与许可

欢迎提交代码、文档、测试和 Windows 体验改进。请先阅读 [贡献指南](CONTRIBUTING.md)、[行为准则](CODE_OF_CONDUCT.md) 与 [安全策略](SECURITY.md)。

项目原创代码与文档采用 [MIT License](LICENSE)。v1.0 发布包不包含宠物或其他受限视觉素材；第三方组件与再分发信息见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
