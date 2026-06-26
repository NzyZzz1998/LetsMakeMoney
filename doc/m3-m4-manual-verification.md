# LetsMakeMoney M3/M4 手动验证记录

## 环境信息

- Godot 版本：
- 项目路径：`<PROJECT_ROOT>`
- 验证日期：
- 验证人：

## 运行方式

```powershell
& "$env:LMM_GODOT_EXE" --path "<PROJECT_ROOT>" --scene "res://src/scenes/main/main.tscn"
```

## 自动验证命令

手动验证前可以先跑自动检查，确认脚本解析、主场景启动、设置保存、首次向导保存没有明显错误：

```powershell
cd <PROJECT_ROOT>
powershell -ExecutionPolicy Bypass -File .\scripts\verify_m3.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_m4.ps1
```

## 1. 启动检查

- [x] 程序能正常启动
- [x] 主窗口可见
- [x] 宠物区域可见
- [x] 薪资面板可见
- [x] 底部 DebugStatus 可见
- [x] 控制台没有红色错误

结果：

```text
是否通过：通过
问题描述：
截图/录屏：
```

## 2. 宠物点击交互

### 单击

- [x] 左键单击宠物区域
- [x] 底部显示 `Debug: single click`
- [x] 宠物状态短暂变化后能恢复

结果：

```text
是否通过：通过
实际表现：
```

### 双击

- [x] 快速双击宠物区域
- [x] 底部显示 `Debug: double click`
- [x] 不会被误判成两次单击

结果：

```text
是否通过：通过
实际表现：
```

### 长按

- [x] 左键长按宠物区域
- [x] 程序不崩溃
- [x] 松开后状态能恢复

结果：

```text
是否通过：通过
实际表现：
```

## 3. 拖拽窗口

- [x] 按住宠物区域拖动窗口
- [x] 窗口移动速度与鼠标基本一致
- [x] 没有明显飞走、加速、抖动
- [x] 松开后底部显示拖拽保存信息
- [x] 关闭后重新运行，窗口恢复到上次位置

结果：

```text
是否通过：通过
实际表现：
```

## 4. 薪资面板

- [x] 折叠状态金额栏只显示一个 `¥`
- [x] 鼠标悬停面板约 0.3 秒后展开
- [x] 鼠标移开约 0.5 秒后收起
- [x] 展开/收起没有疯狂闪烁
- [x] 文字没有明显溢出

结果：

```text
是否通过：通过
实际表现：
```

## 5. 右键菜单

- [x] 右键宠物区域能打开菜单
- [x] 点击 `设置` 能打开设置面板
- [x] 点击 `关于 LetsMakeMoney` 能弹出关于窗口
- [x] `窗口模式 > 置顶悬浮` 可点击且不崩溃
- [x] `窗口模式 > 融入桌面` 可点击且不崩溃
- [x] `切换角色` 当前只有一个角色时不报错
- [x] 点击 `退出` 能正常退出

结果：

```text
是否通过：通过
实际表现：
```

## 6. M4 设置面板

### 打开设置

- [x] 右键菜单点击 `设置`
- [x] 弹出标题为 `设置` 的窗口
- [x] 能看到标签页：`Salary / Pet / Display / Panel / General`

结果：

```text
是否通过：通过
实际表现：
```

### Salary 标签页

- [x] 修改月薪，例如 `20000`
- [x] 修改休息模式
- [x] 修改每日工作小时数
- [x] 修改上下班时间
- [x] 点击确认后设置窗口关闭
- [x] 主界面薪资面板刷新
- [x] 再次打开设置，刚才的值仍然存在

结果：

```text
是否通过：通过
实际表现：
```

### Pet 标签页

- [x] 能看到角色列表
- [x] 当前至少有一个角色
- [x] 修改缩放后点击确认
- [x] 宠物大小发生变化
- [x] 再次打开设置，缩放值仍然存在

结果：

```text
是否通过：通过
实际表现：
```

### Display 标签页

- [x] 修改透明度后点击确认
- [x] 当前窗口透明度变化
- [x] 切换窗口模式后点击确认
- [x] 程序不崩溃
- [x] 再次打开设置，窗口模式值仍然存在

结果：

```text
是否通过：通过
实际表现：
```

### Panel 标签页

- [x] 取消部分面板项，例如 `状态`
- [x] 点击确认
- [x] 悬停展开面板后，被取消的项目不再显示
- [x] 再次打开设置，勾选状态仍然存在

结果：

```text
是否通过：通过
实际表现：
```

### General 标签页

- [x] 能看到开机自启选项
- [x] 开机自启当前为 disabled，不可用
- [x] 语言显示为中文
- [x] 不报错

结果：

```text
是否通过：通过
实际表现：
```

## 7. M4 首次启动向导

验证前临时备份配置：

```powershell
$cfgDir = Join-Path $env:APPDATA "LetsMakeMoney"
$cfg = Join-Path $cfgDir "config.json"
$backup = Join-Path $cfgDir "config.backup.json"
New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
if (Test-Path $backup) { Remove-Item $backup -Force }
if (Test-Path $cfg) {
    Move-Item $cfg $backup -Force
    "已备份配置到 $backup"
} else {
    "当前没有配置文件，可直接验证首次启动向导"
}
```

然后重新运行项目。

注意：运行前请先关闭所有已有的 `LetsMakeMoney (DEBUG)` 窗口和 Godot 调试进程。首次向导只会在新的主场景启动时检查配置文件。

- [x] 无配置启动时自动弹出欢迎向导
- [x] Step 1 欢迎页可见
- [x] 能看到角色预览
- [x] 点击 `下一步` 能进入薪资页
- [x] 薪资页可填写月薪、休息模式、工作时间
- [x] 点击 `下一步` 能进入角色页
- [x] 角色页能看到角色列表和预览
- [x] 点击 `下一步` 能进入确认页
- [x] 确认页显示摘要
- [x] 点击 `开始赚钱！` 后向导关闭
- [x] 主界面刷新薪资数据
- [x] 重新启动后不再重复弹出向导

结果：

```text
是否通过：通过
实际表现：
```

如果需要在不删除配置的情况下复测向导，也可以在主界面右键宠物区域，点击 `重新运行向导`。这个入口只用于验证和重新配置，不代表首次启动失败。

验证后恢复配置：

```powershell
$cfgDir = Join-Path $env:APPDATA "LetsMakeMoney"
$cfg = Join-Path $cfgDir "config.json"
$backup = Join-Path $cfgDir "config.backup.json"
if (Test-Path $cfg) { Remove-Item $cfg -Force }
if (Test-Path $backup) {
    Move-Item $backup $cfg -Force
    "已恢复原配置"
} else {
    "没有备份配置需要恢复"
}
```

## 8. 控制台错误记录

```text
Godot 版本：
运行是否成功：
控制台第一条红色错误：
复现步骤：
期望行为：
实际行为：
截图/录屏：
```

## 总结

```text
整体是否通过：不通过
阻塞问题：
非阻塞问题：
1.折叠状态金额栏垂直居中

建议优先修复：
```

## 修复记录

- 2026-06-26：已将折叠金额栏容器调整为占满折叠面板高度，并将金额 Label 设置为垂直居中；`scripts/verify_m4.gd` 已增加对应结构验证。
- 2026-06-26：进一步优化折叠金额栏，将折叠容器改为 `CenterContainer` 并占满 `150x54` 面板，金额 Label 在整块折叠面板中水平/垂直居中。
