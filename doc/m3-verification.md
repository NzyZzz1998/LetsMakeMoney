# M3 验证清单

本清单用于确认 M3 已形成可运行桌宠雏形：主场景能启动，Pet 和薪资 Panel 可见，Panel 可悬停展开/收起，窗口可拖拽保存位置，右键菜单可用。

## 自动验证

在 PowerShell 中运行：

```powershell
Set-Location <PROJECT_ROOT>
.\scripts\verify_m3.ps1
```

如果 Godot 不在常见目录，显式传入 console exe：

```powershell
.\scripts\verify_m3.ps1 -GodotExe "$env:LMM_GODOT_EXE"
```

通过标准：

- `project.godot` 设置主场景为 `res://src/scenes/main/main.tscn`
- `PanelSystem` 已注册为 Autoload
- Godot headless 能加载项目
- Godot headless 能运行主场景 30 帧
- 输出中没有 `Parser Error`、`Invalid call`、`Node not found`、`null instance` 等阻塞错误

## 手动验证

1. 用 Godot 4.7 打开 `<PROJECT_ROOT>`。
2. 运行项目，确认出现无边框透明窗口，能看到宠物占位动画和薪资面板。
3. 检查 Output / Debugger，不能出现红色脚本错误。
4. 鼠标悬停面板约 0.3 秒，确认展开；移开约 0.5 秒，确认收起。
5. 鼠标移入宠物区域，测试 hover、单击、双击、长按，确认不会卡死在交互状态。
6. 拖拽宠物移动窗口，关闭后重新运行，确认窗口位置恢复。
7. 右键宠物区域，确认菜单弹出；测试关于、窗口模式、切换角色、设置提示、退出。
8. 把窗口拖到屏幕右侧和底部，确认 Panel 尽量出现在左侧或上方，避免超出屏幕。

## 问题记录模板

```text
Godot 版本：
运行是否成功：
控制台第一条红色错误：
复现步骤：
期望行为：
实际行为：
截图/录屏：
```

## 当前约束

- M4 设置面板和首次启动向导尚未实现，所以右键菜单中的“设置”只显示提示。
- 当前素材仍是兔子占位，不验证正式猫咪素材质量。
