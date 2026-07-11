# LetsMakeMoney Windows 原生桥接

本目录保存 LetsMakeMoney 的 Windows x86_64 GDExtension / 原生桥接代码。

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

锁定和实测环境记录在 `third_party/native-toolchain.lock.json`：

- Godot 4.7 stable，官方 Windows x86_64 归档和可执行文件均有 SHA256；
- Python 3.12.8；
- SCons 4.10.1；
- MSYS2 UCRT64、GCC 16.1.0 和 MinGW-w64 CRT 14；
- `godot-cpp` 固定为 `ba0edfed90512ec64aba51d4295a3e7e30112f86`。

不要依赖维护者本机路径。通过环境变量指定工具：

```text
$env:LMM_MSYS2_BASH
$env:LMM_PYTHON_EXE
$env:LMM_GODOT_EXE
```

## 获取固定依赖

联网环境首次运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_native_dependencies.ps1
```

脚本将官方 godot-cpp 镜像缓存到 `.cache/dependencies/godot-cpp.git`，并仅检出 lock 中的固定 commit。缓存目录可删除，删除后联网重新生成：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_native_dependencies.ps1 -CleanCache
```

离线环境先从另一台机器复制 `.cache/dependencies/godot-cpp.git`，再运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_native_dependencies.ps1 -Offline
```

离线缓存缺失、commit 不存在或工作副本版本不符都会以非零退出码失败，不会退回最新分支。

## 本地构建

先只验证依赖与工具链身份：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -ValidateOnly
```

在项目根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -Target template_debug
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -Target template_release
```

如果 MSYS2 安装在其他位置：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -Msys2Bash "<MSYS2_ROOT>\usr\bin\bash.exe"
```

如果缺少 `godot-cpp`，也可以由构建入口调用固定 bootstrap：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -BootstrapDependencies
```

旧参数 `-FetchGodotCpp` 保留为兼容别名，但不再获取最新分支。脚本会把 MSYS2 的 `HOME`、`TMP`、`TEMP`、`TMPDIR` 指向仓库内已忽略的 `.cache/native-build`，避免写入 MSYS2 安装目录。

第一次 Debug 或 Release 构建会分别编译完整 `godot-cpp` 绑定层。本机冷构建实测每个目标约 10-15 分钟；后续增量构建通常只需几秒。不要并行构建两个目标到同一 native 目录。

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

v0.7 B1 已验证：

- 无缓存在线 bootstrap 与固定 commit 校验；
- 仅使用镜像缓存的离线恢复；
- 全新 native 目录的 `template_debug` 和 `template_release` 构建；
- 缓存缺失、错误 commit、错误 Godot SHA256 和缺失工具的可读失败；
- v0.4-v0.6、M4/M5 和托盘回归仍由对应脚本持续保护。
