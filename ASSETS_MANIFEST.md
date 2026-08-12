# LetsMakeMoney v1.1 视觉资产清单

**当前结论**：v1.1.0 候选包含一个经项目所有者批准、为产品运行时净化的 Classic 橘猫包。该角色素材不是通用 MIT 素材，只允许随 LetsMakeMoney 官方源码和官方二进制分发。

| ID | 路径 | 用途 | 许可 | 发布范围 |
|---|---|---|---|---|
| V11-ASSET-001 | `apps/windows-v1/src-tauri/icons/icon.ico` | LetsMakeMoney 应用图标 | 项目自有，随 MIT 项目分发 | 源码与官方发布包 |
| V11-ASSET-002 | `apps/windows-v1/src-tauri/pet-packages/classic-first-return-vnext/assets/atlas-00.webp` | Classic 橘猫动画图集 | 项目所有者生成、筛选并批准；受限产品运行时素材 | LetsMakeMoney 官方源码与官方发布包 |
| V11-ASSET-003 | `apps/windows-v1/src-tauri/pet-packages/classic-first-return-vnext/hitmasks/atlas-00.hitmask.json` | Classic 逐帧透明命中数据 | 由 V11-ASSET-002 确定性派生；沿用相同限制 | LetsMakeMoney 官方源码与官方发布包 |

Classic 净化包只包含运行时图集、命中数据、manifest 和必要的许可/来源摘要，不包含 Prompt、失败尝试、生产源文件、QA 中间文件或本机绝对路径。不得从仓库或发布包中提取、改包后独立分发，亦不得用于其他项目。

v0.9 的旧猫咪、动画和旧应用图标继续存在于 `v0.9-beta` tag 与对应 GitHub Release 中，并沿用该版本的受限素材许可。当前清单不改变任何历史版本素材权利。
