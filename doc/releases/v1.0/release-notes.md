# LetsMakeMoney Windows v1.0 Stable 候选说明

## 当前状态

v1.0 已完成业务实现、自动门禁、便携 Zip 打包和独立解压核心 GUI 验收。当前结论为**通过，可进入 Stable 发布收口**。

## 核心变化

- 使用 Rust + Tauri + TypeScript/React 重建 Windows 客户端。
- 暂时完整下线宠物入口、运行时、资源和配置。
- 新增无宠物迷你收入视图、Today 工作台和收入日历。
- 统一单休、双休、大小周、午休、跨夜班次和节假日计算。
- 首次配置中的预计工作日会随当前休息模式实时重算；大小周在用户明确选择本周类型前不显示推测结果。
- 将首次配置收敛为三步 Wizard，并与四任务组 Settings 共用配置口径。
- 优化窗口首次出现位置、内容区长按拖动、日历跨月浏览和重新配置重置流程。
- 修正 Settings“数据与支持”的重复分隔线，以及“收入与作息”标题、分隔线和表单之间的留白。
- 保留原子保存、无变化、失败补偿、诊断、日志轮换、托盘和本地更新查询能力。

## 当前候选

- Zip：`LetsMakeMoney-v1.0-windows-x86_64.zip`
- 源码提交：`88f1e2a8a66dd7b97ffd7d0b6e127b7ac06189a9`
- Zip SHA256：`E0A8ACE0DE2ACBC6F733900FFE537B21912B654F7BDEC937FCE060FC7147CF74`
- EXE SHA256：`30C6FAB3813E6DA318C54096E8659D902EDF281EFBE508C6A12FCDEB0094446D`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`

以上为已完成核心验收的干净 Stable 候选身份，不因后续定向修正而覆写。

窗口与导航定向验收包：

- Zip SHA256：`99DB494245F207B420B9B3CCDBA96D8DC65EC4F444926DF4DE03AD021A8911A8`
- EXE SHA256：`78E5ECDABC2F710569942F1918E80601136A8638A92DCBCD76A90B0E5D03F820`
- 源码 HEAD：`da4326e18536d8846fdd6ef49ae894de4a8975c5`

该定向包的 `BUILD-INFO.json` 记录 `source_tree_dirty=true`，只用于项目所有者复验窗口与导航修正。正式发布前必须先提交有意变更，再从干净提交重新打包并更新最终哈希。

新候选已使用实际 EXE 定向复验迷你收入视图、Today、Calendar、Settings 四任务组、无变化保存反馈、真实通知区左键双向切换和 Explorer 重启后的托盘重注册；配置哈希在复验前后保持一致。迷你窗口恢复后重新应用 `skip_taskbar=true`，Settings 关闭后任务栏入口正常消失。首次配置全链路仍引用上一候选的独立验收证据。

## 已知验证边界

- 多显示器变化后的窗口安全回落因当前设备只有一台显示器而待补证；项目所有者批准其不阻塞本次 Stable，不得写为已通过。

## 回退

v0.9 桌宠版继续由 `v0.9-beta` tag 和 GitHub Release 保留。v1.0 不修改该历史基线。
