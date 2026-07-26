# LetsMakeMoney Windows v1.0 Stable 候选说明

## 当前状态

v1.0 已完成业务实现、自动门禁、便携 Zip 打包和独立解压核心 GUI 验收。当前结论为**通过，可进入 Stable 发布收口**。

## 核心变化

- 使用 Rust + Tauri + TypeScript/React 重建 Windows 客户端。
- 暂时完整下线宠物入口、运行时、资源和配置。
- 新增无宠物迷你收入视图、Today 工作台和收入日历。
- 统一单休、双休、大小周、午休、跨夜班次和节假日计算。
- 将首次配置收敛为三步 Wizard，并与四任务组 Settings 共用配置口径。
- 保留原子保存、无变化、失败补偿、诊断、日志轮换、托盘和本地更新查询能力。

## 当前候选

- Zip：`LetsMakeMoney-v1.0-windows-x86_64.zip`
- 源码提交：`88f1e2a8a66dd7b97ffd7d0b6e127b7ac06189a9`
- Zip SHA256：`647AA441F3FB7FFB5CF60EDE6A0AE2CE89D98FEEA5459565C7CDB593C9FB57B3`
- EXE SHA256：`CF28374BA84960EAB894AD2654B25489CE96EEB9120295C879F29CAA1BA20C83`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`

该候选由干净实现提交生成；包内 `BUILD-INFO.json` 记录 `source_tree_dirty=false`。

新候选已使用实际 EXE 定向复验迷你收入视图、Today、Calendar、Settings 四任务组、无变化保存反馈、真实通知区左键双向切换和 Explorer 重启后的托盘重注册；配置哈希在复验前后保持一致。迷你窗口恢复后重新应用 `skip_taskbar=true`，Settings 关闭后任务栏入口正常消失。首次配置全链路仍引用上一候选的独立验收证据。

## 已知验证边界

- 多显示器变化后的窗口安全回落因当前设备只有一台显示器而待补证；项目所有者批准其不阻塞本次 Stable，不得写为已通过。

## 回退

v0.9 桌宠版继续由 `v0.9-beta` tag 和 GitHub Release 保留。v1.0 不修改该历史基线。
