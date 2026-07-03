# LetsMakeMoney Windows 原生桥接

本目录保存 LetsMakeMoney v0.3 Beta 使用的 Windows x86_64 GDExtension / 原生桥接代码。

这层代码只负责桌面系统能力，不承载业务逻辑：

- 系统托盘图标与托盘菜单
- 透明无边框桌宠窗口初始化
- 透明空白区域点击穿透
- 任务栏 / Alt+Tab 可见性控制
- 原生能力健康检查

薪资计算、角色动画、设置界面、Panel 布局、配置读写等逻辑仍保留在 Godot 侧。Godot 代码应通过 `PlatformInterface`、`WindowsPlatform` 和 `Platform` Autoload 调用本桥接，不应在 Main / Settings / 业务模块中直接写 Win32 细节。

## 目录结构

```text
native/windows/
├── README.md
├── SConstruct
├── letsmakemoney_native.gdextension
├── bin/win64/
│   └── letsmakemoney_native.dll        # 本机构建产物，不提交
└── src/
    ├── lmm_native_bridge.*
    ├── register_types.*
    ├── tray_controller.*
    └── window_controller.*
```

`godot-cpp/` 是本地第三方依赖目录，已加入 `.gitignore`，不随项目提交。

## 构建产物

预期 DLL 路径：

```text
native/windows/bin/win64/letsmakemoney_native.dll
```

导出的 Windows exe 必须能找到这个 DLL。若 DLL 缺失或加载失败，Godot 侧必须回退到 v0.2 的紧凑普通窗口，并保留任务栏 / Alt+Tab 找回入口，避免窗口不可找回。

## 构建环境

当前本机推荐环境：

- Godot 4.7 stable
- Python 3
- SCons
- MSYS2 UCRT64 / MinGW x86_64 `g++`
- `godot-cpp` 位于 `native/windows/godot-cpp`

默认 MSYS2 路径：

```text
$env:LMM_MSYS2_BASH
```

## 本地构建

在项目根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1
```

如果 MSYS2 安装在其他位置：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -Msys2Bash "<MSYS2_ROOT>\usr\bin\bash.exe"
```

如果缺少 `godot-cpp`，且当前环境允许访问网络：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -FetchGodotCpp
```

脚本会把 MSYS2 的 `HOME`、`TMP`、`TEMP`、`TMPDIR` 指向 `<WORKSPACE_ROOT>` 下的临时目录，避免写入 MSYS2 安装目录时遇到权限问题。

第一次构建会编译完整 `godot-cpp` 绑定层，耗时可能较长；后续增量构建通常只需几秒。

## 验证命令

构建完成后，建议依次运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v02.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v03.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_m4.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v03_export.ps1
```

其中 `verify_v03_export.ps1` 会短暂启动 `build\LetsMakeMoney.exe` 做冒烟测试，用于确认导出 exe 能加载 native DLL 且不会立即崩溃。

## 当前状态

当前本机已经验证：

- MSYS2 UCRT64 可用
- `letsmakemoney_native.dll` 可成功构建
- v0.2 兼容验证通过
- v0.3 自动验证通过
- M4 设置回归验证通过
- v0.3 导出 exe 冒烟测试通过

仍需用户完成 `doc/v0.3-manual-verification.md` 中的手动验证，确认真实托盘、透明窗口、点击穿透、关闭隐藏到托盘和纯桌宠模式在桌面环境中符合预期。
