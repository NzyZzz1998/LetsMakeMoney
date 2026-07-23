# LetsMakeMoney Windows v0.9 Beta

> **版本状态：部分通过，已冻结归档。**
>
> v0.9 完成了计薪、配置体验、窗口界面和宠物运行时的大范围重构，但仍有真实 DPI、系统托盘、长按跑动、完整动画观感和长时稳定性项目未验证。它不是当前公开稳定版本，也没有对应 GitHub Release。

## 一句话结论

v0.9 是 Windows 体验重塑的冻结候选：实现和定向修复已经结束，没有已确认的代码阻塞；项目所有者接受当前前端质感债与未执行验收项，决定停止扩展并将其作为后续版本的工程与产品基线。

当前公开版本仍是 [v0.8 Beta](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.8-beta)。

## 版本身份

| 项目 | 冻结事实 |
|---|---|
| 产品版本 | Windows v0.9 Beta |
| 验收结论 | **部分通过** |
| 发布结论 | 仅冻结归档，不宣称完整验收通过或正式稳定发布 |
| 稳定回退 | Windows v0.8 Beta |
| 候选 Zip | `releases/v0.9/LetsMakeMoney-v0.9-beta-windows-x86_64.zip` |
| Zip SHA256 | `65A04A1BAFF6681FF335DD2966A528E6BD6517A81232BC107EFAF5AF42C9F685` |
| EXE SHA256 | `B867D515772B4C1D220C98FD7C75B253C42EF689504CE7BB731E80B529A9532D` |
| Native DLL SHA256 | `E3E2030003A7DA725446A3873C3EC2E19D9442B98A67F24A771E76BD0BAD5089` |

候选产物包含开发基线之后的定向修复与多多 S5.5 接入，因此验收应以三个产物 SHA256 为最终身份，不能只凭某个 Git HEAD 替代。

## 主要完成内容

- 统一单休、双休、大小周、每日 8 小时、午休、节假日和调休的计薪与进度口径。
- 统一 Wizard 与 Settings 的配置草稿、默认推算、校验、保存和失败恢复。
- 重组 Panel，并增加单实例今日详情窗口、位置记忆和显示器安全回落。
- 完成 Settings 与 Wizard 的生产级结构和视觉还原，统一暖色控件状态。
- 统一 Popup、菜单、Settings、Wizard 打开期间的点击穿透保护。
- 建立通用宠物包 schema、校验、导入、缓存、哈希、许可和损坏回退合同。
- 保留 Classic 稳定实现和旧资源回退链，接入多多 S5.5 运行时动画载荷。
- 引入事件驱动动画状态机、状态感知单击、长按拖动、环境事件和动态命中区。
- 关闭导出包宠物加载、动画入口、Panel 缩放、Classic 动作结束和今日详情作息漂移等定向缺陷。

## 已验证范围

- v0.9 计薪、配置、窗口、宠物包、动画与集成自动验证通过。
- v0.8、M4、M5、配置、托盘和历史兼容回归通过。
- 独立解压候选包能够启动，Classic 与多多均可加载。
- 100% DPI 下 Settings 五页、Wizard 四步、今日详情、右键菜单和模态穿透恢复通过真实桌面复验。
- 多多与 Classic 的状态感知单击链路、窗口拖动、Panel 缩放及今日详情作息同步完成定向复验。
- 普通模式与纯桌宠模式的 native 托盘消息自动验证各 10 轮通过。

完整证据见 [verification.md](verification.md) 和 [manual-verification.md](manual-verification.md)。

## 暂不验证

以下项目没有被写成通过：

- 真实 Windows 125% 与 150% DPI 全窗口复验。
- Windows 通知区真实鼠标左键显隐与可见任务栏入口。
- 500ms 长按进入方向跑动及释放收势。
- Classic 与多多三种基础状态和全部事件动作的完整视觉质量。
- 受控损坏宠物包在真实桌面上的回退观感。
- 连续两小时 GUI 稳定运行。

## 为什么冻结

自动与定向验证没有发现新的代码阻塞，但当前 Windows 前端质感、动画流畅度和整体一致性仍未达到项目所有者预期。继续在 v0.9 上补丁式调整的收益已经低于重新收敛体验方向的价值，因此本版本停止开发：

- 保留实现、验证和候选包作为可追溯基线。
- 不创建 v0.9 GitHub Release，不将其标记为稳定版。
- 未完成验收项与视觉体验债进入后续版本重新设计。
- 需要稳定使用时回退到 v0.8 Beta。

## 文档导航

建议按以下顺序阅读：

1. [progress_v0.9.md](progress_v0.9.md)：版本状态、任务完成度和冻结结论。
2. [verification.md](verification.md)：自动验证、Computer Use 与真实桌面证据。
3. [manual-verification.md](manual-verification.md)：人工操作边界和未完成项目。
4. [release-checklist.md](release-checklist.md)：候选身份与发布门禁。
5. [release-notes.md](release-notes.md)：面向版本使用者的变化与回滚说明。
6. [prd.md](prd.md)：完整需求、范围和验收合同。
7. [dev_plan_v0.9.md](dev_plan_v0.9.md)：实施顺序、风险和回退方案。
8. [structure-retention.md](structure-retention.md)：冻结后的目录与证据保留边界。

体验方向与动画决策的上游材料：

- [review.md](review.md)
- [windows-ios-gap-analysis.md](windows-ios-gap-analysis.md)
- [petmanager-animation-review.md](petmanager-animation-review.md)
- [pet-package-contract-gap.md](pet-package-contract-gap.md)

## 验证入口

```powershell
# v0.9 聚合验证
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v09.ps1

# 重新生成本地候选包
powershell -ExecutionPolicy Bypass -File .\scripts\package_v09.ps1

# 验证候选包身份、结构和运行时载荷
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v09_package.ps1
```

重新打包会产生新的候选身份，不得沿用本页记录的旧 SHA256。任何重新开启都必须先更新验证文档、候选哈希和冻结状态。

## 口径保护

- 不把“自动验证通过”写成“完整桌面验收通过”。
- 不把“无已确认代码阻塞”写成“可公开发布”。
- 不把暂不验证项写成通过。
- 不用旧 Zip、`build/` 产物或单独 Git HEAD 冒充锁定候选。
- 不在未重新验收时创建 v0.9 tag 或 GitHub Release。

