# v1.0 宠物能力退役审计

**审计日期**：2026-07-24  
**适用范围**：v1.0 当前工作树与未来便携 Zip  
**历史恢复基线**：`v0.9-beta` tag 与对应 GitHub Release

## 结论

v1.0 产品表面、生产运行时、配置结构、构建入口和候选发布包不再包含宠物能力。旧实现从当前树移除，但 Git tag、Release 与提交历史保持不变。

## 已从活跃树移除

| 类别 | 路径/对象 | v1.0 处理 |
|---|---|---|
| Godot 主工程 | `project.godot`、`export_presets.cfg`、`src/` | 移除 |
| 原生扩展 | `native/` | 移除 |
| 宠物资源 | `assets/pets/`、旧猫咪图标与 README 头图 | 移除 |
| 旧构建链 | Godot、native、v0.2-v0.9 验证与打包脚本 | 移除 |
| 旧安装与依赖副本 | `installer/`、`third_party/`、`licenses/` | 移除 |
| 旧 CI | Godot/native 验证与旧发布 dry-run | 替换为 v1 工作流 |

## 允许保留的宠物字段

仅迁移 fixture 与 Rust 测试可以出现以下旧字段，用于证明升级时会忽略并删除它们：

- `pet_id`
- `pet_package_id`
- `pet_package_version`
- `pure_pet_mode`
- `pet_scale`
- `click_through`

这些字段不会进入 v6 配置、生产类型、UI、托盘菜单或发布包。

## 自动门禁

`scripts/verify_v10_m6.ps1` 会检查：

1. 旧主工程与宠物目录不存在。
2. v1 生产代码没有宠物入口或能力。
3. 配置迁移测试覆盖全部退役字段。
4. 当前 README、无宠物图标和回退说明完整。
5. 提供 Zip 时，包内不存在 Godot、native 或宠物载荷。

## 历史保护

本轮没有改写 `v0.9-beta` tag、Git 历史或 GitHub Release。需要恢复桌宠体验时按 [v0.9 回退说明](v0.9-rollback.md) 操作。
