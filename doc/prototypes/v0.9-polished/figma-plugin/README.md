# LetsMakeMoney v1.0.8 Figma Development Plugin

这是 LetsMakeMoney 项目内的本地 Figma Development Plugin。它在现有 v0.9 Figma 文件中维护当前 v1.0.8 产品设计，不创建第二个 Figma 文件，也不调用 Figma MCP。

插件只管理一个页面：

`LMM 01 产品全链路`

## 当前覆盖

- Rust + Tauri 2 + React 19 产品关系总览。
- Mini 正常、上班前、休息、错误和隐私贴边状态。
- Workbench 今日收入、阶段倒计时、今日安排和月度摘要。
- 收入日历、六周月份、复合日期状态、日期调整和加班事务。
- Wizard 三步首次配置与退出确认。
- Settings 五个任务分类、浅色/深色主题、保存和失败补偿。
- Windows 原生托盘、窗口找回、配置恢复、诊断和更新检查。
- 每个交互控件对应稳定 `LMM-B-xxx` 编号及就近开发契约。
- 第 07 区集中留档正式 L2「燕麦石墨」Logo、尺寸预览、主题适配、来源和 SHA256。

旧 v0.9 的桌宠、Panel、Godot 信号和动画合同不再属于当前产品。旧页面只有通过 `lmm` Shared Plugin Data 所有权验证后才会删除，非 LMM 页面不会被修改。

## 文件

- `manifest.json`：保持原插件 ID。
- `code.js`：v1.0.8 单页生成器和增量优化器。
- `ui.template.html`：插件面板模板。
- `ui.html`：构建生成，内嵌经过完整性校验的品牌素材。
- `build.ps1`：从正式应用图标确定性生成 `generated-assets/appLogo.png`。
- `test-plugin.ps1`：页面保护、产品事实、控件契约、素材、幂等、UTF-8 和布局门禁。
- `generated-assets/asset-manifest.json`：品牌素材来源、尺寸、字节数和 SHA256。

## 构建与验证

```powershell
cd E:\codex\LetsMakeMoney\doc\prototypes\v0.9-polished\figma-plugin
.\build.ps1
.\test-plugin.ps1
```

## 在 Figma Desktop 中运行

1. 打开现有 LetsMakeMoney Figma 文件。
2. 选择 `Plugins` → `Development` → `Import plugin from manifest...`。
3. 选择 `E:\codex\LetsMakeMoney\doc\prototypes\v0.9-polished\figma-plugin\manifest.json`。
4. 运行 `LetsMakeMoney 产品全链路生成器`。
5. 已手动调整画布时，选择“增量优化现有画布（保留手动修改）”。
6. 只有确实需要从代码重新生成整页时，才选择“完整重建 v1.0.8 设计”。

### 增量优化

增量模式不会重建整个页面，并遵守以下保护规则：

- 契约字段仍等于旧生成值时，更新为当前中文业务说明。
- 已被手动修改的契约字段原样保留。
- 已知的旧版英文受管图层名会迁移为中文；用户手动命名及无法确认归属的名称保持不变。
- 变量集合、主题模式、阴影样式和新生成图层统一使用中文菜单名；必要的技术名词放在中文语义中保留。
- 压缩第 04 区 Wizard 原型与契约之间的异常空白；后续受管区块作为整体移动，不重排其内部手动内容。
- 第 07 区属于本轮明确批准的替换范围，会重建为“Logo 相关素材留档”。
- 第 07 区以外的手动图层、文字、尺寸和内部布局不重建。

### 完整重建

完整重建会清空并重新生成已确认归属的受管页面。它是幂等的，不会重复创建页面、变量、样式、组件或契约，但会覆盖受管页面中的手动修改。

## 设计事实

| 窗口 | 逻辑尺寸 |
| --- | --- |
| Mini | 344×108 |
| Workbench | 820×620 |
| Settings | 760×560，最小 720×520 |
| Wizard | 780×580，最小 740×540 |
| Mini 隐私竖条 | 34×108 |

当前强制支持边界为 Windows 11 单显示器。100%、125%、150% DPI 已进入设计矩阵；Windows 10 与多显示器不得仅依据 Figma 原型写为已通过。

## Logo 留档合同

第 07 区仅保存品牌交付事实，不再承担通用设计系统展示：

- 正式候选：L2「燕麦石墨」。
- 原始来源：`apps/windows-v1/src-tauri/icons/icon.png`。
- 插件输出：`generated-assets/appLogo.png`。
- 展示 256、128、64、32、16px 尺寸预览。
- 展示浅色和深色背景适配。
- 展示 PNG 尺寸、字节数和 SHA256，便于开发与发布核对。

## 素材边界

- 最终页面不嵌入运行截图。
- 唯一位图素材为当前产品正式 L2 品牌 PNG。
- 品牌 PNG 在构建时校验可见像素、PNG 签名、尺寸、字节数和 SHA256。
- 其他窗口、控件和状态均由可编辑 Figma 图层重建。
- Figma Starter 的单集合 mode 数量有限，因此浅色和深色分别生成单 mode 变量集合，不调用 `addMode`。
