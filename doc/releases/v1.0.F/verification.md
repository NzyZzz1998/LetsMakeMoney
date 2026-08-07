# LetsMakeMoney Windows v1.0.8 验证记录

## 当前结论

本地发布源提交、锁定候选、自动门禁和真实 Windows 11 单显示器 GUI 验收已完成。项目所有者使用真实鼠标完成通知区左键隐藏/恢复、右键菜单、任务栏入口策略和退出，退出后进程消失且日志记录退出语义。候选未发现新的发布阻塞缺陷，当前结论为 **通过，可进入发布收口**。

`test` 已推送；本轮未推送 `main`，未创建远端 tag、GitHub Release 或修改仓库设置。最终 README 更新晚于锁定候选，正式发布前必须从最终发布提交重建候选并更新哈希。

## 候选身份

| 字段 | 锁定值 |
| --- | --- |
| 分支 | `main` |
| 发布源 HEAD | `81abae364ad577a394c3c9dcda3a1d1c15e83b99` |
| Source tree | 构建时 clean |
| Candidate ID | `V10F-20260804-final-81abae36` |
| Build UTC | `2026-08-04T15:53:34.5718680Z` |
| Zip 大小 | `3,418,747` 字节 |
| Zip SHA256 | `07D9B1766CECE8DA092CE31C234E6018D4820049F3D2A310033478BF5EB69DDA` |
| EXE 大小 | `10,287,616` 字节 |
| EXE SHA256 | `8D2ABDB6EB1E32F8B568BA9E12A2BAD0A52A9099B19C6CF7CEE3A040FF71ED3B` |
| WebView2Loader.dll 大小 | `160,320` 字节 |
| DLL SHA256 | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |
| 包内 README SHA256 | `6B8E20D50B864A07549E1567D0E0382D2E8B361302CA0448A7B6FF12B6DCF706` |
| 包内 README.en SHA256 | `2C9C4C5DD83CECA7C930FA24B5994ACB11A377820721380A6DFA4A31C4441B5D` |
| 发布许可 | 验收通过；等待最终候选重建和项目所有者对 `main`、tag、Release 的单独批准 |

候选路径：`.artifacts/candidates/v1.0.8/V10F-20260804-final-81abae36/`。GUI 只运行独立解压目录中的 EXE，没有使用开发目录或 `target/release` 代替。

## 自动验证

| 范围 | 结论 | 证据 |
| --- | --- | --- |
| M1-M7 current gate | 通过 | `scripts/verify_windows_current.ps1 -Milestone M7` |
| 前端行为测试 | 通过 | 22 组行为测试 |
| Rust | 通过 | 77/77 tests、fmt、clippy |
| TypeScript 与构建 | 通过 | strict、Vite production build |
| 候选身份 | 通过 | candidate mode 连续复核两次 |
| 包内合同 | 通过 | BUILD-INFO、README、许可、日历 manifest 与 SHA256 |
| 文档与文本 | 通过 | UTF-8、乱码和 `git diff --check` |
| 敏感信息 | 通过（能力受限） | 降级文本扫描未发现明显命中；未将其描述为专业秘密扫描 |

## 真实 GUI 验收

| 范围 | 结论 | 真实证据摘要 |
| --- | --- | --- |
| 首次启动与 Wizard | 通过 | 空配置进入浅色 Wizard；三步默认值、禁用态、推算和完成链路正确；150% 三步无裁切 |
| Mini | 通过 | 浅/深主题、拖动、左侧贴边、34px 隐私竖条、点击展开、失焦收起、冷启动恢复正确 |
| Workbench | 通过 | 打开时 Mini 隐藏；关闭后只恢复 Mini；时间线、日历和六周布局正确 |
| 日期调整 | 通过 | 双击日期、自动判断、工作日切换、取消和应用可用 |
| 加班事务 | 通过 | 周末联动默认 8 小时；修改为 7.25 小时；重开持久化；删除确认后归零 |
| 月度总结 | 通过 | 计划工时、实际工时和加班工时随事务同步更新 |
| Settings | 通过 | 五页可达；保存、无变化、放弃未保存变更、恢复主题和维护入口正确 |
| 主题 | 通过 | 跨窗口即时预览、取消回滚、保存持久化；冷启动直接恢复深色，无浅色首帧 |
| TimeField / Combobox | 通过 | 圆角弹层、选项、取消/确认、Escape 关闭和焦点态可用 |
| 诊断与更新 | 通过 | 诊断摘要脱敏提示正确；更新检查显示当前为最新版；版本为 1.0.8 |
| 100% / 125% / 150% DPI | 通过 | Mini、Workbench、Settings、Wizard 无裁切、重叠或整月溢出；验收后已恢复 100% |
| 托盘与任务栏 | 通过 | 项目所有者真实鼠标完成左键隐藏/恢复、右键菜单和任务栏策略；托盘退出后进程消失，日志包含 `tray-exit` 与 `app.exit_requested` |

## 日志与配置

- 配置保持 `config_version: 8`，主题、日期调整、窗口位置和 Mini 隐私状态均持久化。
- 加班记录完成创建、修改和删除，最终测试数据为空集合；旧记录保留在测试目录的 previous 文件中。
- `debug.log` 包含主题加载、窗口 show/hide、WebView suspend/resume、权威同步、owner date、官方日历和隐私收起语义事件。
- 本轮原始测试配置、日志和截图只保存在本机验收目录，不进入发布包。

## 环境与支持边界

- Windows 11 x86_64、单显示器、100%/125%/150%：通过。
- Windows 10：未取得真实设备或 VM 证据，仅尽力兼容，不进入已验证支持声明。
- 多显示器：项目所有者已批准暂不验证，不进入通过声明。
- Windows 通知区和任务栏真实鼠标流程：通过。

## 下一门禁

1. 将最终 README 与验收文档纳入发布提交，从该干净提交重新构建候选并更新全部哈希。
2. 对重建候选复跑 current gate、candidate 包体验证和受影响的身份冒烟；若 EXE 或运行资源变化，重新执行受影响 GUI 验收。
3. 项目所有者单独批准 `main`、annotated tag 与 GitHub Release；未获授权前不执行这些动作。
