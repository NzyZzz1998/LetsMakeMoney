# LetsMakeMoney Windows v1.0 说明书取证问题清单

## LMM-V10-GUIDE-001：日历手动调整未持久化

- 严重度：中
- 状态：已确认
- 现象：点击日期后可选“跟随规则 / 工作日 / 休息日”，但覆盖仅保存在 `useCalendarOverrides()` 的 React 状态中。
- 影响：关闭工作台或重启应用后，手动日期调整丢失；配置中的 `date_overrides` 没有更新。
- 证据：
  - `apps/windows-v1/src/App.tsx` 的 `CalendarView`
  - `apps/windows-v1/src/model.ts` 的 `useCalendarOverrides`
  - `LMM-V10-CALENDAR-005-DATE-EDITOR.png`
  - `LMM-V10-CALENDAR-006-MANUAL-REST.png`
- 建议：在正式发布前接入配置草稿/安全保存，或明确将入口标为“仅本次查看”。

## LMM-V10-GUIDE-002：日历“允许手动调整”开关未接入配置

- 严重度：低
- 状态：已确认
- 现象：开关使用 `defaultChecked`，没有读取或写入配置。
- 影响：用户可能误以为该开关会长期启用或禁用日期调整。
- 证据：`apps/windows-v1/src/App.tsx` 的 `CalendarSettings`。
- 建议：接入配置字段，或在没有真实开关语义前移除该控件。

## 环境限制

- Computer Use 无法稳定操作 Windows 通知区图标，因此托盘左键、右键和退出需要人工补证。
- Codex 沙箱启动应用时，数据目录会映射到应用容器；含本机路径的截图未写入公开说明书。

