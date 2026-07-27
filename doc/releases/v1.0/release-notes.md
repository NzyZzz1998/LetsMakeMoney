# LetsMakeMoney Windows v1.0 Stable 发布说明

## 当前状态

v1.0 已完成业务实现、自动门禁、便携 Zip 打包、独立解压核心 GUI 验收和发布收口。当前结论为**通过 / 已发布**。

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
- 零午休按连续工作日计算，Today 不再绘制虚假的午休节点。
- 收入计算失败时提供可读原因、“检查设置”和“重试”出口，并记录脱敏语义日志。

## 发布包

- Zip：`LetsMakeMoney-v1.0-windows-x86_64.zip`
- 源码提交：`806bda6503f1b5ac61212d47abaf5e389fa1948a`
- `BUILD-INFO.json`：`source_tree_dirty=false`
- Zip 大小：`3,044,917` 字节
- Zip SHA256：`A5C33B9DB8787536145AE4B9A1AC00213E692C99A2201CC91EB811A0A0F3BBE6`
- EXE SHA256：`BD25B13F084A0F101DD77239F215019C0BB9E246847BBD15B2D0BEE98B381C44`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`

以上为纳入全部定向修正后重新生成并通过包体验证的 Stable 发布包身份。发布收口提交为 `76a480602af9a3429f9919ec9f9ee66a2add089d`，tag 为 `v1.0`。

窗口与导航定向验收包：

- Zip SHA256：`99DB494245F207B420B9B3CCDBA96D8DC65EC4F444926DF4DE03AD021A8911A8`
- EXE SHA256：`78E5ECDABC2F710569942F1918E80601136A8638A92DCBCD76A90B0E5D03F820`
- 源码 HEAD：`da4326e18536d8846fdd6ef49ae894de4a8975c5`

该定向包的 `BUILD-INFO.json` 记录 `source_tree_dirty=true`，仅作为窗口与导航修正的历史验收证据；其内容已经纳入上方最终干净候选。

新候选已使用实际 EXE 定向复验迷你收入视图、Today、Calendar、Settings 四任务组、无变化保存反馈、真实通知区左键双向切换和 Explorer 重启后的托盘重注册；配置哈希在复验前后保持一致。迷你窗口恢复后重新应用 `skip_taskbar=true`，Settings 关闭后任务栏入口正常消失。首次配置全链路仍引用上一候选的独立验收证据。

## 已知验证边界

- 多显示器变化后的窗口安全回落因当前设备只有一台显示器而待补证；项目所有者批准其不阻塞本次 Stable，不得写为已通过。

## 回退

v0.9 桌宠版继续由 `v0.9-beta` tag 和 GitHub Release 保留。v1.0 不修改该历史基线。
