<div align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="LetsMakeMoney v1.1.0：本地收入进度与可选 Classic 桌面陪伴">
</div>

<div align="center">
  <a href="README.en.md">English</a> ·
  <a href="https://github.com/NzyZzz1998/LetsMakeMoney/releases/latest">下载稳定版</a> ·
  <a href="doc/current.md">项目状态</a> ·
  <a href="doc/releases/v1.1.0/release-notes.md">v1.1.0 发布说明</a>
</div>

## 今天的工作，值多少钱？

LetsMakeMoney 是一款本地优先的 Windows 收入进度工具。设置月薪、工作时间与休息方式后，它会把抽象的月薪换算为今日已赚、工作进度、阶段倒计时和月度工时总结。

v1.1.0 带回了可选的 Classic 橘猫桌面陪伴。Mini 收入视图与 Classic 严格互斥：默认使用 Mini，也可以在设置中切换为小猫。无需账号，工资、作息、日期调整、加班记录和日志都保存在本机。

## 真实界面

<div align="center">
  <img src="assets/readme/workbench.png" width="900" alt="LetsMakeMoney 今日收入工作台，使用演示数据">
  <br>
  <sub>真实 Windows 工作台，金额、日期和工时均为演示数据。</sub>
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

## v1.1.0：Classic 小猫回归

- **三种陪伴状态：** `working`、`awake_rest`、`sleeping` 跟随权威工作状态切换。
- **状态化互动：** 每种状态拥有独立单击反馈；长按 500ms 后进入跑动，支持即时转向和释放收势。
- **透明桌面交互：** 可见像素参与命中，透明区域穿透，不以矩形窗口遮挡桌面。
- **Mini / Classic 二选一：** Workbench 打开期间隐藏当前陪伴，关闭后恢复进入前状态。
- **主线隔离：** 宠物包损坏或运行异常时安全回落 Mini，不影响收入、日历、设置与托盘。

## 核心体验

| 看见收入进度 | 理解每个工作日 | 保持桌面私密 | 本地可靠运行 |
| --- | --- | --- | --- |
| 今日已赚、工作进度与阶段倒计时 | 单休、双休、大小周与跨夜班次 | Mini 贴边自动收起敏感金额 | 配置事务、损坏恢复与诊断摘要 |
| 今日安排、日薪、时薪与月度累计 | 官方日历、估算年份与日期调整 | 悬停展开、移开收起、托盘找回 | 浅色/深色主题与本地持久化 |
| 按日记录加班与月度工时总结 | 带薪休息、不带薪休息与调休 | Workbench 打开时隐藏桌面陪伴 | 100% / 125% / 150% DPI 验证 |
| Mini / Classic 自主选择 | 状态化单击与长按拖拽 | 透明像素穿透 | 包异常时安全回落 Mini |

## 三步开始使用

1. 从 [Releases](https://github.com/NzyZzz1998/LetsMakeMoney/releases/latest) 下载 `LetsMakeMoney-v1.1.0-windows-x86_64.zip`。
2. 完整解压后运行 `LetsMakeMoney.exe`，按引导填写月薪、休息模式和工作时间。
3. 使用 Mini 查看实时进度，或在设置中切换为 Classic；从托盘打开今日工作台、设置与重新配置。

> [!NOTE]
> 当前提供免安装便携 Zip。Windows SmartScreen 可能因程序尚未代码签名而显示“未知发布者”；请只从本仓库 Release 下载并核对 SHA256。

## 数据与隐私

```text
%APPDATA%\io.letsmakemoney.windows\
```

- 无需注册或登录，不上传工资、作息、日期调整或加班记录。
- 诊断摘要会隐藏本机路径等机器特定信息。
- Mini 可在工作区左右边缘收起金额，只保留非金额阶段提示。
- 未覆盖年份明确标记为“估算”，不会伪造官方节假日或调休数据。
- Classic 仅在用户显式选择后启用；动画素材不适用 MIT，详见 [视觉素材许可](ASSETS_LICENSE.md)。

## 支持边界

- **已验证：** Windows 11 x86_64，单显示器，100% / 125% / 150% DPI。
- **尽力兼容：** Windows 10 x86_64；当前缺少真实设备或 VM 证据。
- **暂未验证：** 多显示器，不进入已验证通过声明。
- **运行前提：** Microsoft Edge WebView2 Runtime。

完整候选身份、哈希与验收边界见 [v1.1.0 验证记录](doc/releases/v1.1.0/verification.md)。

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
# 仓库根目录：唯一 current gate
powershell -ExecutionPolicy Bypass -File .\scripts\verify_windows_current.ps1

# 创建隔离候选，不覆盖正式 Release
powershell -ExecutionPolicy Bypass -File .\scripts\package_v110.ps1
```

## 仓库结构

```text
apps/windows-v1/       Tauri 2 + React 19 Windows 客户端
shared/                官方日历与共享数据
scripts/               current gate、打包与合规检查
doc/current.md         当前项目事实入口
doc/releases/v1.1.0/   v1.1.0 验收与发布证据
```

## 参与与许可

欢迎提交代码、文档、测试和 Windows 体验改进。请先阅读 [贡献指南](CONTRIBUTING.md)、[行为准则](CODE_OF_CONDUCT.md) 与 [安全策略](SECURITY.md)。

项目原创代码与文档采用 [MIT License](LICENSE)。Classic 橘猫及其衍生运行时素材不适用 MIT，仅允许随 LetsMakeMoney 官方源码和官方二进制分发；详见 [视觉素材许可](ASSETS_LICENSE.md) 与 [第三方声明](THIRD_PARTY_NOTICES.md)。
