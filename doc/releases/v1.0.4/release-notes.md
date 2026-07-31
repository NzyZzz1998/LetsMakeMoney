# LetsMakeMoney Windows v1.0.4 发布说明

> 状态：已发布。GitHub Release：<https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.4>

## 本版重点

### Mini 隐私贴边自动隐藏

- Mini 靠近左侧或右侧工作区边缘后自动收起。
- 收起态只保留隐私唤回条，不显示工资、阶段、时间或日期。
- 悬停或点击唤回条可展开 Mini；指针移开后重新收起。
- 从屏幕边缘向内拖动可解除停靠。
- Settings 新增“贴边自动隐藏”开关；关闭后立即展开并清除停靠状态。
- 托盘找回、重启恢复和显示器失效时优先回到安全可见状态。

### 发布与维护可信度

- 便携包使用独立的中英文离线 README。
- README、BUILD-INFO、文件名、应用版本和包哈希建立交叉验证。
- 验收证据采用仓库内脱敏摘要与外部原始证据索引合同。
- Node、Python、Rust、MSVC、Windows SDK 和 WebView2 开发要求更明确。
- 正式脚本不再依赖历史 spike 或某个开发者的私有运行时路径。
- 补充窗口生命周期、配置事务、可信快照和 Tauri/React 组合行为测试。

## 兼容性

- Windows 10/11 x86_64。
- 配置继续使用 config v8；v1.0.4 新字段均为可选字段。
- v1.0.3 可以读取和保存 v1.0.4 配置，未知新字段会被安全丢弃，不损坏旧字段。
- 收入、日历、主题和既有窗口主链路保持 v1.0.3 口径。

## 最终发布身份

- 发布源提交：`4d06dc73dbc5c27d7a97462d8262a553dd97d5b6`
- annotated tag：`v1.0.4`
- tag object：`2e4fec17520524ac1e53a4e1bc993448d9255981`
- `source_tree_dirty=false`
- Zip 大小：`3,228,929` 字节
- Zip SHA256：`C4F28892831891A4266C4D9B12D432CD5C970BB3C9B36A6B8DB21FA2566DE50E`
- EXE 大小：`10,107,904` 字节
- EXE SHA256：`E0C9C603703FC2632619AFBC84F63B1B1D403273CD01D29AA0A308A95243E107`
- WebView2Loader 大小：`160,320` 字节
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- 构建时间（UTC）：`2026-07-31T06:53:13.2838601Z`
- Release 附件：`LetsMakeMoney-v1.0.4-windows-x86_64.zip`、`SHA256SUMS.txt`
- 回下载验证：通过；远端 Zip SHA256 与上述锁定值一致。

## 已通过

- v1.0.4 完整自动验证、生产构建、Rust test/format/clippy。
- 打包与包体验证。
- 100%/125%/150% DPI 下 Mini、Workbench 和 Settings 清晰度。
- 左右贴边、隐私收起、唤回、移开收回。
- 跨窗口关闭自动隐藏后立即恢复完整 Mini。
- 重启后设置持久化。
- 深色主题跨窗口同步和重启持久化。
- Windows 减少动态效果下的安全收起。
- 首次配置 Wizard、日历跨月和日期调整取消事务。
- Windows 通知区真实鼠标左键隐藏、恢复和窗口找回。
- 主验收结束时普通与隔离用户环境哈希恢复一致；通知区补证未保存配置，最终无残留进程。

## 发布结果

1. 发布改动通过 PR #20 和必需 CI 合入 `main`。
2. 最终产物从干净发布源提交重新构建，并通过完整验证、打包和包体验证。
3. `v1.0.4` annotated tag 已推送。
4. GitHub Stable Release 已创建，只上传便携 Zip 与 `SHA256SUMS.txt`。
5. Release 附件已回下载并重新计算 SHA256，结果一致。

## 暂不验证

- 真实多显示器、负坐标工作区与显示器移除回落：当前缺少硬件环境，项目所有者已批准延期，不阻塞 v1.0.4；后续具备环境时补证，不得追溯写成已通过。
