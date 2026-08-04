# v1.0.F 品牌资产分层
## 正式资产

- 唯一源：`apps/windows-v1/brand/app-icon-l2.svg`
- 确定性生成器：`apps/windows-v1/scripts/generate_brand_icon.ps1`
- 发布输出：`apps/windows-v1/src-tauri/icons/icon.png` 与 `icon.ico`
- 身份清单：`apps/windows-v1/brand/brand-assets.json`

正式 L2“燕麦石墨”资产必须由身份清单校验 SHA256、PNG 尺寸和 ICO 尺寸目录。手工替换输出但不更新源和清单应使 current gate 失败。

## 设计证据

`doc/prototypes/v1.0/` 中的 Logo 候选 HTML、预览 PNG、材质探索和落选方案属于设计历史证据，不属于运行时资产，也不得进入发布 Zip。

最终发布前可单独审批归档或清理候选；在正式源、生成器和哈希锁定前不得批量删除。仓库外缓存、失败生成和本机派生物不应进入版本控制。
