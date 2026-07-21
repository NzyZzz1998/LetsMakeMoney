# LetsMakeMoney v0.9 Figma Builder

本地 Figma Development Plugin，用于在 Starter 免费账户中生成可编辑的 LetsMakeMoney Windows v0.9 设计文件。它不调用 Figma MCP，因此不会消耗 MCP 工具额度。

## 生成内容

插件只维护以下三个页面：

1. `00 Foundations & Components`
2. `01 Windows v0.9 Product UI`
3. `02 Animation Contract`

其中包含：

- Warm Desktop 原始与语义变量；
- 8 个文字样式与 2 个阴影样式；
- Button、Input、Tab、Toggle、Slider、Status Chip 等核心控件；
- 桌面陪伴、今日详情、首次配置、偏好设置、宠物外观、菜单与找回六条链路；
- `working / awake_rest / sleeping` 状态合同；
- 单击、长按拖拽、午休和下班事件规则；
- Classic 与多多真实 Contact Sheet；
- GIF 首帧静态审查图，真实时长动画仍以仓库 GIF 为准。

## 首次安装

1. 在 Windows 上运行：

   ```powershell
   powershell -ExecutionPolicy Bypass -File ".\doc\prototypes\v0.9-polished\figma-plugin\build.ps1"
   ```

2. 使用 **Figma Desktop** 打开目标文件：
   <https://www.figma.com/design/YYUnNNHBsWTavbZi3zkGTV>
3. 在 Figma 菜单中选择 `Plugins > Development > Import plugin from manifest...`。
4. 选择：
   `doc\prototypes\v0.9-polished\figma-plugin\manifest.json`
5. 运行 `Plugins > Development > LetsMakeMoney v0.9 Design Builder`。
6. 点击“生成 / 更新设计”。

## 本地验证

```powershell
powershell -ExecutionPolicy Bypass -File ".\doc\prototypes\v0.9-polished\figma-plugin\test-plugin.ps1"
```

验证会检查：三页结构、动态页面 API、非目标页面保护、JavaScript 语法，以及六份素材确定性转换后的 PNG 格式与 SHA256。插件写入 Figma 后还会读取并校验素材字节，避免静默生成空白图片。

## 更新设计

原型或宠物 Contact Sheet 变化后，重新运行 `build.ps1`，再运行插件即可。插件会清空并重建三个同名 LMM 页面，不会删除其他页面。

## 免费版边界

- 变量、样式和组件保存在当前文件内，可正常编辑和复用。
- Starter 不能把这套内容发布成跨文件团队 Library。
- 建议 QR 与 LetsMakeMoney 使用不同 Figma 文件，避免页面混写。
