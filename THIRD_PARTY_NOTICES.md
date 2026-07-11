# LetsMakeMoney 第三方声明

**最后更新**：2026-07-11

本文件区分运行时分发依赖、构建/测试工具和未来计划工具。项目自身代码适用 `LICENSE`，项目视觉适用 `ASSETS_LICENSE.md`；两者不能由本文件相互替代。

## 随便携 Zip 和安装器分发

### Godot Engine（4.7.stable.official.5b4e0cb0f）

- 用途：应用运行时与 Windows 导出模板，代码包含在 `LetsMakeMoney.exe` 中。
- 来源：https://github.com/godotengine/godot/tree/4.7-stable
- 许可：MIT；Godot 自身第三方组件见其 `COPYRIGHT.txt`。
- 修改：项目未修改 Godot Engine 源码。
- 随包文件：`licenses/third-party/Godot/LICENSE.txt`、`COPYRIGHT.txt`。

### godot-cpp（ba0edfed90512ec64aba51d4295a3e7e30112f86）

- 用途：构建 Windows GDExtension；代码链接进 `letsmakemoney_native.dll`。
- 来源：https://github.com/godotengine/godot-cpp/commit/ba0edfed90512ec64aba51d4295a3e7e30112f86
- 许可：MIT。
- 修改：本地 checkout 干净，项目未修改 godot-cpp。
- 随包文件：`licenses/third-party/godot-cpp/LICENSE.md`。

### MinGW-w64 UCRT headers/runtime（14.0.0.r92.g818fa6510-1）

- 用途：Windows native DLL 的头文件与运行时；部分运行时代码可能静态进入 DLL。
- 来源：https://packages.msys2.org/packages/mingw-w64-ucrt-x86_64-crt
- 许可：ZPL-2.1、BSD、公共领域及组件特定声明，准确边界以随附原文为准。
- 修改：未修改。
- 随包文件：`licenses/third-party/MinGW-w64/COPYING`、`COPYING.RUNTIME`。

### GCC（MSYS2 mingw-w64-ucrt-x86_64-gcc 16.1.0-5）

- 用途：编译 native DLL；编译器本体不分发，运行时对象可能静态进入 DLL。
- 来源：https://packages.msys2.org/packages/mingw-w64-ucrt-x86_64-gcc
- 许可：GPL-3.0-or-later，并适用 GCC Runtime Library Exception 3.1。
- 修改：未修改。
- 随包文件：`licenses/third-party/GCC/COPYING3`、`COPYING.RUNTIME`。

Windows 系统 DLL（Kernel32、User32、Shell32、Ole32、UCRT API Set 等）由操作系统提供，不随 LetsMakeMoney 重新分发。

## 仅开发、构建或测试使用

### Python（3.12.8）

用于 native 构建、测试和素材脚本；不进入应用包。许可：Python Software Foundation License Version 2 及随附声明。原文：`licenses/third-party/Python/LICENSE.txt`。

### SCons（4.10.1.055b01f429d58b686701a56df863a817c36bb103）

用于 native 构建；不进入应用包。许可：MIT。原文：`licenses/third-party/SCons/LICENSE.txt`。

### Pillow（12.2.0）

仅用于素材生成脚本；库本身不进入源码或应用包。许可：MIT-CMU。原文：`licenses/third-party/Pillow/LICENSE.txt`。

### Git for Windows（2.54.0.windows.1）

用于源码管理、依赖获取和审计；不进入应用包。许可：GPL-2.0-only 及组件声明。原文：`licenses/third-party/Git/COPYING`。

### Windows PowerShell（5.1.26100.8655）

当前用于验证、打包和发布脚本，是 Windows 系统组件，不由本项目分发。仓库保留 PowerShell 7.5.2 的 MIT 许可原文作为跨平台 PowerShell 参考，但当前打包身份仍是 Windows PowerShell 5.1。

## 计划工具，尚未形成发布能力

### Inno Setup（版本待 V07-C1 确认）

计划用于当前用户安装器。当前机器未安装，尚未生成安装器。官方来源：https://jrsoftware.org/isinfo.php；许可原文：`licenses/third-party/Inno-Setup/LICENSE.txt`。版本未固定前，安装器发布门禁保持失败。

### GitHub Actions（Action 尚未选择）

当前仓库没有 workflow。V07-B2/E3 选择 Action 时必须记录仓库、用途、许可证和不可变 commit；Fork PR 不得获得发布 secret。未选择的 Action 不计为现有依赖。

## 完整机器清单

字段、分发范围和审核状态以 `third_party/dependencies.json` 为机器事实源。许可证原文同步脚本为 `scripts/sync_third_party_licenses.ps1`，下载内容必须通过固定 SHA256。
