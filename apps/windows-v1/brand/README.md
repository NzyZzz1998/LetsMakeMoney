# LetsMakeMoney 品牌图标

## 正式方案

- 方案：L2 · 燕麦石墨
- 主源文件：`app-icon-l2.svg`
- 外壳：`#EEE9DF`
- 双峰：`#30302B`
- 收入进度：`#D89B26`
- 进度轨道：`#778B7B`

双峰代表持续积累的两个阶段，底部进度条延续产品的收入进度语义。图标不使用文字、货币符号或渐变，确保在 Windows 标题栏、任务栏和通知区的小尺寸环境中仍可辨认。

## 生成资产

在 `apps/windows-v1` 中运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/generate_brand_icon.ps1
```

生成器会确定性写入：

- `src-tauri/icons/icon.ico`：16、20、24、32、40、48、64、128、256 px
- `src-tauri/icons/icon.png`：512 px RGBA

`generate_placeholder_icon.ps1` 仅作为旧构建入口的兼容包装，不再生成旧的人民币符号占位图标。

## 使用边界

- React 标题栏使用 `src/components/AppMark.tsx`，几何和配色必须与 SVG 一致。
- Tauri 窗口、任务栏、托盘和发布包使用 `src-tauri/icons/icon.ico`。
- 调整几何或配色时，必须同时更新 SVG、React 标记、生成器和静态合同测试。
- 禁止直接手工覆盖 ICO/PNG 而不更新主源和生成器。
