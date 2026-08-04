# LetsMakeMoney v1.0 第三方声明

**最后更新**：2026-07-28

v1.0 使用 Rust、Tauri、TypeScript 和 React。项目自身代码采用 MIT License；第三方组件保留各自许可。

## 运行时与前端

| 组件 | 锁定版本 | 用途 | 许可/来源 |
|---|---:|---|---|
| Tauri | 2.11.1 | Windows 桌面壳、窗口、托盘和命令桥 | Apache-2.0 / MIT，https://github.com/tauri-apps/tauri |
| React | 19.1.1 | 用户界面 | MIT，https://github.com/facebook/react |
| React DOM | 19.1.1 | React DOM 渲染 | MIT，https://github.com/facebook/react |
| Lucide React | 1.27.0 | 今日、日历、设置、月份切换、关闭、重试及状态入口图标 | ISC，https://github.com/lucide-icons/lucide |
| webview2-com / webview2-com-sys | 0.38.2 | WebView2 COM Rust 绑定；提供构建所需的 x64 `WebView2Loader.dll` | MIT，https://github.com/wravery/webview2-rs |
| Microsoft WebView2Loader | 随 webview2-com-sys 0.38.2 锁定 | 帮助应用定位设备上的 WebView2 Runtime；x64 `WebView2Loader.dll` 随便携 Zip 分发 | Microsoft WebView2 SDK 组件；Microsoft 官方部署文档明确要求随对应架构应用提供，https://learn.microsoft.com/zh-cn/microsoft-edge/webview2/concepts/distribution |
| Microsoft Edge WebView2 Runtime | 用户设备上的系统安装版本 | Windows Web 内容运行时 | 由 Microsoft 独立安装和许可；本项目便携 Zip 不包含 Runtime |

Rust 传递依赖由 `apps/windows-v1/src-tauri/Cargo.lock` 锁定，npm 依赖由 `apps/windows-v1/package-lock.json` 锁定。发布包不得携带旧 Godot、godot-cpp、MinGW native bridge 或宠物运行时。

`WebView2Loader.dll` 与 WebView2 Runtime 是不同组件：前者是随应用分发的架构相关加载器，后者是用户设备上独立安装和更新的运行时。本项目仅分发 x64 Loader，不捆绑 Evergreen 或 Fixed Version Runtime。

Machine-readable distribution boundary: `WebView2Loader.dll is bundled; WebView2 Runtime is not bundled.`

## 仅开发与构建

| 组件 | 用途 | 分发 |
|---|---|---|
| Rust stable MSVC toolchain | 编译 Tauri 后端 | 不进入发布包 |
| Node.js / npm | 安装依赖、构建前端 | 不进入发布包 |
| TypeScript 5.9.2 | 静态类型检查 | 不进入发布包 |
| Vite 7.3.6 | 前端构建 | 不进入发布包 |
| Python 3 | 合同与静态验证脚本 | 不进入发布包 |
| PowerShell | Windows 构建、验证和打包 | 不进入发布包 |

完整版本以两个 lockfile 为准。新增依赖必须更新本文件、锁文件和包体验证，不得只修改源码引用。
