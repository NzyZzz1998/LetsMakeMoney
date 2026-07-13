# v0.8 C5 Settings、素材与发布边界验证

**日期**：2026-07-13
**结论**：通过；项目所有者已确认并执行发布目录清理方案 A。

## 1. Settings 职责拆分

- `settings_dialog.gd` 从 1615 行降至 1445 行。
- 新增 `SettingsSectionBuilder`，负责设置页滚动容器、页标题、分组标题、设置行、说明区和控件尺寸。
- 新增 `SettingsTransactionController`，负责无变化、校验失败、配置保存失败、外部状态应用失败及回滚结果。
- `settings_dialog.gd` 继续拥有字段采集、Config 适配、注册表/运行态适配、反馈文案和信号连接，不改变配置字段与用户流程。

保存事务顺序保持为：

```text
采集表单 -> 检查变化 -> 捕获配置/外部状态 -> 校验预应用
-> 写内存配置 -> 安全保存 -> 应用外部状态
-> 成功反馈
```

失败补偿保持为：

```text
校验失败：恢复配置快照 + 恢复外部状态
保存失败：恢复配置快照 + 恢复外部状态
外部应用失败：恢复配置快照 + 再次保存旧配置 + 恢复外部状态
```

## 2. 宠物资源回退审计

公开版当前必须保留三套运行资源：

| 资源 | 角色 | 删除影响 |
| --- | --- | --- |
| `cat_orange_v2` | 默认宠物 | 应用失去当前默认形象 |
| `cat_orange_v1` | 显式二级回退 | v2 缺失、旧配置或资源异常时失去稳定回退 |
| `cat` 占位猫 | 最后一级可运行回退 | v2/v1 同时不可用时没有可显示宠物 |

`PetManager` 的合同顺序为：请求 ID -> v2 默认 -> v1 回退 -> 第一个可用宠物。`verify_v04` 已覆盖三套资源加载和扫描，`test_v08_pet_fallback.ps1` 锁定路径、常量和回退顺序。因此本批不删除 v1、占位猫或其运行时资源。

## 3. 导出边界

- `export_presets.cfg` 新增 `deliverables/**` 排除规则。
- `doc/**`、`scripts/**`、`build/**`、`temp/**`、`tmp/**`、`releases/**` 继续排除。
- v0.4-v0.7 包验证脚本均在 `.tmp_release/` 下解压，不再把 smoke 展开目录写入 `releases/`。
- 临时 Release 导出成功，EXE 为 113,013,520 字节（107.78 MiB）。导出清单未出现 `deliverables/`，临时目录已清理。

## 4. 自动验证

| 验证 | 结果 |
| --- | --- |
| `test_v08_settings_governance.ps1` | 通过 |
| `test_v08_pet_fallback.ps1` | 通过 |
| `test_v08_release_boundaries.ps1` | 通过 |
| `test_script_tiers.ps1` | 通过，91 个脚本（含 Godot UID）全部归类 |
| `verify_m4.ps1` | 通过 |
| `verify_v04.ps1` | 通过 |
| `verify_v05.ps1` | 通过 |
| `verify_v06.ps1` | 通过 |
| `verify_v07.ps1` | 通过 |

## 5. 发布目录清理结果

- 已删除 v0.4-v0.7 的四个展开目录和 v0.7 未签名安装器目录，释放 492,303,680 字节（469.50 MiB）。
- 保留 v0.4-v0.7 四个 Zip、v0.7 `SHA256SUMS.txt`、Changelog 和历史发布说明。
- 四个保留 Zip 均重新通过包体验证，smoke 解压目录随后从 `.tmp_release/`、`.tmp_appdata/` 清理。
- 修复 v0.6/v0.7 历史包验证器错误读取当前项目版本的问题；历史验证入口现在固定验证各自版本。
