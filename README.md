<div align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="LetsMakeMoney：在 Windows 桌面随时看见今天的收入进度">
</div>

<div align="center">
  <a href="README.en.md">English</a> ·
  <a href="https://github.com/NzyZzz1998/LetsMakeMoney/releases">下载稳定版</a> ·
  <a href="doc/current.md">项目状态</a> ·
  <a href="doc/releases/v1.1.0/README.md">v1.1.0 候选</a>
</div>

## 今天的工作，值多少钱？

LetsMakeMoney 是一款本地优先的 Windows 收入进度工具。设置月薪、工作时间和休息方式后，它会把抽象的月薪换算成今日已赚、工作进度、距离下一阶段的时间和月度工时汇总。

Mini 收入视图可以安静地留在桌面；v1.1.0 也可由用户显式切换为 Classic 橘猫陪伴，二者严格互斥。需要调整日期、记录加班或查看整月安排时，再打开完整工作台。无需账号，工资、作息、加班记录和日志都保存在本机。

## 真实界面

<div align="center">
  <img src="assets/readme/workbench.png" width="900" alt="LetsMakeMoney 今日收入工作台，使用演示数据">
  <br>
  <sub>v1.0.8 Windows 主界面基线，图中为演示数据；v1.1.0 Classic 陪伴未混入旧截图。</sub>
</div>

<table>
  <tr>
    <th align="center">Mini 迷你收入视图</th>
    <th align="center">收入日历与月度工时</th>
  </tr>
  <tr>
    <td align="center"><img src="assets/readme/mini.png" width="344" alt="LetsMakeMoney Mini 迷你收入视图"></td>
    <td align="center"><img src="assets/readme/calendar.png" width="560" alt="LetsMakeMoney 收入日历、日期状态和月度工时总结"></td>
  </tr>
</table>

<p align="center"><sub>截图来自 v1.0.8 Windows 实际运行界面；金额、日期与工时仅用于演示。</sub></p>

## 核心体验

| 随时看见进度 | 理解每个工作日 | 保持桌面私密 | 本地可靠运行 |
| --- | --- | --- | --- |
| 今日已赚、阶段倒计时、工作进度 | 单休、双休、大小周与跨夜班次 | Mini 贴边自动收起敏感金额 | 配置事务、损坏恢复与诊断摘要 |
| 今日安排、日薪、时薪和月度累计 | 官方日历、估算年份和手动日期调整 | 悬停展开、移开收起、托盘找回 | 浅色/深色主题与本地持久化 |
| 按日记录加班和月度工时总结 | 带薪休息、不带薪休息与调休工作日 | Workbench 打开时自动隐藏 Mini | 100%、125%、150% DPI 验证 |
| Mini / Classic 二选一陪伴 | Classic 三基础状态与状态化单击 | 透明像素穿透、可见像素交互 | 包损坏时安全回落 Mini |

## 三步开始使用

1. 从 [Releases](https://github.com/NzyZzz1998/LetsMakeMoney/releases) 下载最新稳定版便携 Zip。
2. 解压后运行 `LetsMakeMoney.exe`，按引导填写月薪、休息模式和工作时间。
3. 在 Mini 查看实时进度；从托盘打开今日工作台、设置或重新配置。

当前不提供安装器或静默更新。应用只会在用户确认后检查和打开更新页面。

## v1.1.0 候选

| 事实 | 当前状态 |
| --- | --- |
| 当前公开稳定版 | [v1.0.7 Stable](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.7) |
| v1.0 系列本地收官 | `v1.0.8` annotated tag，保持历史不变 |
| 当前开发候选 | 精确版本 `v1.1.0` |
| 候选定位 | Classic-only 桌面陪伴回归；默认 Mini，用户显式启用 Classic |
| 已淘汰候选 | `V110-20260812T163314Z-d9d51cfe-clean`，因 `V110-BUG-001` 不得发布 |
| 修复状态 | 拖拽失焦恢复已完成 TDD 与 125% DPI 定向复验，最终干净候选待重建 |
| 发布前剩余 | 最终候选 125%/150% DPI、托盘、环境恢复与精确桌面坏包补证 |

v1.1.0 候选增加：

- Classic 橘猫的 working、awake_rest、sleeping 基础状态与独立单击反馈。
- 500ms 长按跑动、左右方向即时切换、释放收势与透明像素命中。
- Mini 与 Classic 严格互斥；Workbench 打开期间隐藏当前陪伴并按进入前状态恢复。
- Classic manifest、图集或哈希异常时安全回落 Mini，不阻断收入主线。
- 净化运行时包只包含正式图集、命中数据、manifest 与必要许可摘要。

候选身份、哈希和验收边界见 [v1.1.0 验证记录](doc/releases/v1.1.0/verification.md)。本地候选不能替代正式 Release。

## 数据与隐私

```text
%APPDATA%\io.letsmakemoney.windows\
```

- 无需注册或登录，不上传工资、作息、日期调整或加班记录。
- 诊断摘要会隐藏本机路径等机器特定信息。
- Mini 贴近工作区左右边缘后可以收起金额，只保留非金额阶段提示。
- 官方日历未覆盖的年份会明确标记为“估算”，不会伪造官方节假日或调休数据。
- Classic 仅在用户显式选择后启用；动画素材不适用 MIT，详见 [视觉素材许可](ASSETS_LICENSE.md)。
- v0.9 桌宠版保留在 [`v0.9-beta`](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.9-beta)，仅作为历史基线。

## 支持边界

- **已验证：** Windows 11 x86_64，单显示器，100% / 125% / 150% DPI。
- **运行前提：** Microsoft Edge WebView2 Runtime。
- **尽力兼容：** Windows 10 x86_64；当前缺少真实设备或 VM 证据。
- **暂未验证：** 多显示器，不进入已验证通过声明。

v1.1.0 最终三档 DPI 结论将在同一干净候选完成后写入 [验证记录](doc/releases/v1.1.0/verification.md)。

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

# 生成隔离的 v1.1.0 本地候选，不覆盖正式发布附件
powershell -ExecutionPolicy Bypass -File .\scripts\package_v110.ps1
```

本地候选只写入 `.artifacts\candidates\v1.1.0\<candidate-id>\`。同名本地 Zip 不能证明 GitHub Release 身份，正式下载始终以 Releases 页面及其 SHA256 文件为准。

## 仓库结构

```text
apps/windows-v1/       Tauri 2 + React 19 Windows 客户端
shared/                官方日历与共享数据
scripts/               current gate、打包和合规检查
doc/current.md         当前项目事实入口
doc/releases/v1.1.0/   v1.1.0 候选、验收与发布准备
```

## 参与与许可

欢迎提交代码、文档、测试和 Windows 体验改进。请先阅读 [贡献指南](CONTRIBUTING.md)、[行为准则](CODE_OF_CONDUCT.md) 与 [安全策略](SECURITY.md)。

项目原创代码与文档采用 [MIT License](LICENSE)。Classic 橘猫及其衍生运行时素材不适用 MIT，仅允许随 LetsMakeMoney 官方源码和官方二进制分发；详见 [视觉素材许可](ASSETS_LICENSE.md) 与 [第三方声明](THIRD_PARTY_NOTICES.md)。
