# v0.7 CI 与真实桌面验收边界

## CI 自动门禁

- 文档状态、公开候选、素材许可、第三方许可与脚本契约。
- 固定依赖 bootstrap、native Release 构建、Godot v0.4-v0.6 与 M4 回归。
- Parser/Script/Invalid call/缺资源、错版本、许可缺失、包缺文件与未知二进制故障注入。
- 测试使用隔离 `APPDATA`，结束后恢复调用进程环境变量。
- Fork PR workflow 权限仅为 `contents: read`，不读取签名、发布或仓库秘密。

本机和 CI 都由 `scripts/run_ci_verification.ps1` 生成 `.tmp_ci/verification-summary.json`。比较依据是步骤名、状态和退出码；耗时与 runner 字段允许不同。

## 必须留给 Computer Use 或人工验收

- Windows 通知区图标的真实鼠标左键、右键与隐藏图标区域行为。
- 普通模式与纯桌宠模式恢复后的真实任务栏入口。
- 透明窗口、Panel、小猫和 Popup 的像素级点击穿透边界。
- 多显示器、100%-200% DPI、不同任务栏位置与缩放组合。
- Authenticode 发布者、时间戳、SmartScreen 和真实证书链。
- 安装器覆盖、修复、取消、卸载与用户数据保留的真实桌面路径。

CI 通过只代表自动门禁通过，不等同于 v0.7 可发布。上述路径必须在 `V07-E4` 形成候选产物后进入独立 `/acceptance`。
