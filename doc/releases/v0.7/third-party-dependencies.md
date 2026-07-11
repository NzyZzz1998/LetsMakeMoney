# v0.7 第三方依赖清单

## 1. 运行时与分发依赖

| 名称 | 版本/commit | 许可 | 进入仓库源码 | 进入 Zip/安装器 | 审核结论 |
|---|---|---|---|---|---|
| Godot Engine | `4.7.stable.official.5b4e0cb0f` | MIT + Godot `COPYRIGHT.txt` | 否 | 代码在 EXE；许可必须入包 | 已确认 |
| godot-cpp | `ba0edfed90512ec64aba51d4295a3e7e30112f86` | MIT | 本地 checkout 不提交 | 代码链接进 native DLL；许可必须入包 | 已确认；固定获取留 B1 |
| MinGW-w64 UCRT | `14.0.0.r92.g818fa6510-1` | ZPL/BSD/公共领域/组件声明 | 否 | 部分运行时代码可能静态进入 DLL；notices 必须入包 | 已确认 |
| GCC | `16.1.0-5` | GPL-3.0-or-later + Runtime Library Exception 3.1 | 否 | 编译器不入包；例外与 GPL 原文随包 | 已确认 |
| Windows 系统组件 | Windows 10/11 系统 API | Windows 系统许可 | 否 | 不重新分发，由系统提供 | 已确认边界；SDK 固定留 B1 |

`objdump -p` 证明当前 native DLL 只动态依赖 Windows/UCRT 系统 DLL，没有额外 `libstdc++`、`libgcc` 或第三方 DLL。保留 GCC/MinGW notices 是对可能静态链接运行时代码的保守合规处理。

## 2. 开发、构建和测试依赖

| 名称 | 本机身份 | 许可 | 分发 | 状态 |
|---|---|---|---|---|
| Python | 3.12.8 | PSF License v2 + notices | 不入包 | 已确认；版本固定留 B1 |
| SCons | 4.10.1.055b01f... | MIT | 不入包 | 已确认；版本固定留 B1 |
| Pillow | 12.2.0 | MIT-CMU | 不入包；仅素材脚本 | 已确认 |
| Git for Windows | 2.54.0.windows.1 | GPL-2.0-only + notices | 不入包 | 已确认 |
| Windows PowerShell | 5.1.26100.8655 | Windows 系统组件 | 不入包 | 已确认当前身份 |
| MSYS2 runtime | 3.6.9-2 | 组件集合，各自许可 | 不入包 | 当前构建环境；完整锁定留 B1 |
| MinGW binutils | 2.46-4 | GPL/LGPL 组件许可 | 不入包 | 当前构建环境；完整锁定留 B1 |

## 3. 计划依赖

| 名称 | 当前事实 | 合规约束 | 阻塞对象 |
|---|---|---|---|
| Inno Setup | 本机未安装，版本未选择 | C1 固定版本并复核官方许可；生成包携带项目/资产/第三方许可 | 安装器，不阻塞当前源码或便携包治理 |
| GitHub Actions | 当前无 `.github/workflows`，未选择 Action | B2/E3 每个 Action 固定不可变 commit、记录许可、最小权限 | CI/公开门禁，不是当前运行依赖 |

## 4. 原型、字体、音频和工具结论

- 原型是本地 HTML/CSS/JavaScript，不加载 CDN、Web Font 或第三方前端库。
- Settings/Wizard 使用 Godot `SystemFont`，仓库与 v0.6 Zip 没有字体文件。
- 当前项目没有音频文件或音频运行时依赖。
- 图标处理由项目脚本/Pillow完成；图标资产受 `ASSETS_LICENSE.md` 管理。
- 压缩由 Windows PowerShell `Compress-Archive` / .NET Framework 提供，没有随包附加压缩库。
- ComfyUI 仅为排除的本机实验环境，不是源码、运行时或 Release 依赖。

## 5. 证据和待办

- 机器事实源：`third_party/dependencies.json`。
- 原文：`licenses/third-party/`。
- 用户向 notices：`THIRD_PARTY_NOTICES.md`。
- B1：固定 Godot 下载身份、godot-cpp commit/archive SHA256、Python/SCons/MSYS2/SDK 支持矩阵。
- B2/E3：选择并固定 GitHub Actions。
- C1：选择 Inno Setup 版本；未完成前不得发布安装器。
