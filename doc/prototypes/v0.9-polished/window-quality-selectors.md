# Windows 窗口质感还原清单

本文件承担 Selector 的精确定位职责。每个设计区域同时在审查稿中使用 `data-review-id` 标记，后续只按表内边界修改 Godot，避免再次全局试色。

| Review ID | HTML selector | Godot 目标 | 精确调整 |
| --- | --- | --- | --- |
| `panel.compact` | `[data-review-id="panel.compact"]` | `src/scenes/panel/panel.gd`、`panel.tscn` | 284×96；金额、状态、进度；四角完整 |
| `panel.expanded` | `[data-review-id="panel.expanded"]` | 同上 | 316×204；只增加月累计、时薪、下一节点 |
| `panel.progress` | `[data-review-id="panel.progress"]` | `panel.gd` | 5px 轨道；金币黄进度；不使用巨大横条 |
| `settings.shell` | `[data-review-id="settings.shell"]` | `src/scenes/settings/settings_dialog.gd` | 去掉宿主底色和外层 margin；一个 700×520 纸面壳 |
| `settings.tabs` | `[data-review-id="settings.tabs"]` | 同上 | 48px；纯文字 tabs；选中态 2px 金币线 |
| `settings.rows` | `[data-review-id="settings.rows"]` | `src/ui/settings_section_builder.gd` | 行式设置、44–48px、分割线，不做 row 卡片 |
| `settings.actions` | `[data-review-id="settings.actions"]` | `settings_dialog.gd` | 56px 固定 action bar；反馈左、按钮右 |
| `wizard.shell` | `[data-review-id="wizard.shell"]` | `src/scenes/wizard/wizard_dialog.gd` | 去掉外层套壳；720×520 单层窗口 |
| `wizard.steps` | `[data-review-id="wizard.steps"]` | 同上 | 188px 浅中性色侧栏；只高亮当前步骤 |
| `wizard.content` | `[data-review-id="wizard.content"]` | 同上 | 当前任务直接落在纸面，不增加内容卡 |
| `today.shell` | `[data-review-id="today.shell"]` | `src/scenes/today/` | 480×600；收益、安排、月摘要用分割线组织 |
| `menu.context` | `[data-review-id="menu.context"]` | `src/utils/context_menu_builder.gd` | 224–240px；10px 圆角；32px 菜单项 |
| `control.select` | `[data-review-id="control.select"]` | `src/ui/warm_control_theme.gd` | 34–36px；暖色 popup；selected 用浅金币底 |
| `control.switch` | `[data-review-id="control.switch"]` | 同上 | 40×22；无外框套圈 |
| `control.slider` | `[data-review-id="control.slider"]` | 同上 | 5px 轨道、15px thumb、固定数字列 |

## 落地顺序

1. 先锁定窗口宿主尺寸和透明背景。
2. 再锁定 shell、tabs、content、action bar 四个结构区域。
3. 然后统一控件 ThemeBox 和字体。
4. 最后处理 hover、focus、pressed、disabled、popup 与 scrollbar。
5. 每完成一个窗口，用真实程序截图与审查稿同尺寸对照；不凭代码推断“应该一致”。
