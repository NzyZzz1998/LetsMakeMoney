const PAGE_NAME = "LMM 01 产品全链路";
const LEGACY_PAGE_NAMES = [
  "LMM 01 Full Product Flow",
  "00 Foundations & Components",
  "01 Windows v0.9 Product UI",
  "02 Animation Contract"
];
const OWNER_NAMESPACE = "lmm";
const OWNER_NAME = "LetsMakeMoney";
const BUILDER_VERSION = "v1.0.8-full-product-flow-1";
const GRID_WIDTH = 5120;
const DOCUMENT_WIDTH = 5200;
const SECTION_PADDING = 24;
const GROUP_GAP = 18;
const CONTRACT_COLUMNS = 5;
const CONTRACT_CARD_WIDTH = 880;
const CONTRACT_CARD_HEIGHT = 408;
const CONTRACT_GAP = 14;
const INVENTORY_ITEM_WIDTH = 320;
const INVENTORY_ROW_HEIGHT = 48;
const INVENTORY_GAP = 12;
const INVENTORY_MAX_COLUMNS = 5;

const LIGHT = {
  canvas: "#E8E7E1", surface: "#FFFDFA", elevated: "#FFFFFF", subtle: "#F7F4EE",
  ink: "#302B26", muted: "#76695D", faint: "#9B8F84", line: "#DED7D0",
  lineStrong: "#C9BDB2", coin: "#EAA71A", coinSoft: "#FFF0BE", orange: "#E97832",
  mint: "#709B74", mintSoft: "#E4EEE3", danger: "#A94F43", dangerSoft: "#F7E7E3",
  blue: "#4E7298", blueSoft: "#E6EEF6", native: "#EEF3F8"
};
const DARK = {
  canvas: "#171714", surface: "#23231F", elevated: "#2B2B26", subtle: "#303029",
  ink: "#F4F0E8", muted: "#C0B8AB", faint: "#8D887D", line: "#44433B",
  lineStrong: "#5B594F", coin: "#F2B43A", coinSoft: "#4A3B17", orange: "#F08A43",
  mint: "#86AE8A", mintSoft: "#263B2B", danger: "#D77B70", dangerSoft: "#4A2925",
  blue: "#8EADD0", blueSoft: "#273646", native: "#242B32"
};
const DOC = {
  canvas: "#F1F1ED", surface: "#FFFFFF", soft: "#F7F9FC", line: "#D7D7D2",
  text: "#202020", muted: "#626262", blue: "#2563EB", blueSoft: "#E8F0FE",
  green: "#107C41", greenSoft: "#E7F5EC", amber: "#8B6200", amberSoft: "#FFF4CE"
};
const TYPE = {
  display: { size: 40, line: 50, weight: "bold" }, title: { size: 28, line: 36, weight: "bold" },
  heading: { size: 20, line: 28, weight: "semibold" }, body: { size: 16, line: 24, weight: "regular" },
  label: { size: 14, line: 20, weight: "semibold" }, caption: { size: 14, line: 20, weight: "regular" },
  numeric: { size: 38, line: 46, weight: "bold" }
};
const RUNTIME_BASELINES = {
  mini: [344, 108], workbench: [820, 620], settings: [760, 560], wizard: [780, 580],
  privacyTab: [34, 108], trayRow: [240, 34]
};
const DPI_SCALE_MATRIX = [
  { scale: "100%", status: "Windows 11 已验收" },
  { scale: "125%", status: "Windows 11 已验收" },
  { scale: "150%", status: "Windows 11 已验收" }
];

let fonts;
let brandImage;
let brandAssetMetadata;

function c(id, area, screen, label, kind, condition, operation, signal, method, persistence, result, failure, cancel, target) {
  return { id, area, screen, label, kind, condition, operation, signal, method, persistence, result, failure, cancel, target };
}

const CONTROL_SPECS = [
  c("LMM-B-001", "Mini", "迷你收入视图", "打开今日工作台", "button", "Mini 可见", "单击金额卡", "onClick", "show_window('workbench')", "无", "隐藏 Mini 并显示 Workbench", "显示失败恢复 Mini 并记录日志", "无", "T-WORKBENCH-TODAY"),
  c("LMM-B-002", "Mini", "迷你收入视图", "拖动窗口", "drag", "非交互控件区域", "按住任意空白区域拖动", "pointerdown", "start_window_drag", "mini_window_position", "自由拖动；释放后安全回落", "原生拖动失败保持当前位置", "释放结束", "T-MINI"),
  c("LMM-B-003", "Mini", "隐私竖条", "展开 Mini", "button", "贴边自动收起", "悬停或单击竖条", "pointerenter/onClick", "reveal_mini", "mini_edge", "恢复完整 Mini", "失败保留可找回竖条", "移开后重新收起", "T-MINI"),
  c("LMM-B-004", "Mini", "迷你收入视图", "重试收入同步", "button", "Dashboard error", "单击重试", "onClick", "refresh_dashboard", "无", "恢复最新有效快照", "继续显示错误与旧快照", "无", "T-MINI-ERROR"),
  c("LMM-B-005", "Mini", "迷你收入视图", "打开设置", "button", "Dashboard 无法计算", "单击设置", "onClick", "show_window('settings')", "无", "显示 Settings", "显示失败写日志", "无", "T-SETTINGS-INCOME"),
  c("LMM-B-006", "Mini", "托盘隐藏状态", "托盘找回", "native", "Mini 被用户隐藏", "托盘左键", "tray-toggle-mini", "toggle_mini_window", "窗口可见性", "恢复 Mini 并重应用置顶", "失败保留托盘入口", "再次左键隐藏", "WINDOWS-NATIVE-TRAY"),
  c("LMM-B-007", "Settings", "窗口与启动 → 迷你收入视图", "贴边自动隐藏设置", "toggle", "设置窗口已打开，迷你收入视图可用", "开启该设置并保存；之后将迷你收入视图拖到屏幕左侧或右侧边缘并释放", "dragCompleted", "finalize_mini_drag", "mini_edge_auto_hide", "贴边后延迟收起，仅保留 34px 隐私竖条且不展示收入金额；悬停时展开", "贴边判断或窗口移动失败时保持迷你收入视图可见，并保留托盘找回入口", "保存前取消或关闭设置不生效；拖动时离开屏幕边缘不收起", "T-MINI-PRIVACY"),
  c("LMM-B-008", "Mini", "迷你收入视图", "关闭到托盘", "native", "关闭按钮或系统关闭", "关闭 Mini", "WindowEvent::CloseRequested", "hide_window", "窗口可见性", "隐藏窗口，进程继续运行", "托盘不可用时安全退出提示", "无", "WINDOWS-NATIVE-TRAY"),

  c("LMM-B-010", "今日", "今日工作台", "今日页签", "tab", "Workbench 已打开", "切换到今日", "onClick", "setWorkbenchView('today')", "无", "显示今日收入进度", "无", "无", "T-WORKBENCH-TODAY"),
  c("LMM-B-011", "今日", "今日工作台", "日历页签", "tab", "Workbench 已打开", "切换到日历", "onClick", "setWorkbenchView('calendar')", "无", "显示收入日历", "无", "无", "T-WORKBENCH-CALENDAR"),
  c("LMM-B-012", "今日", "今日工作台", "设置入口", "button", "Workbench 已打开", "单击设置", "onClick", "show_window('settings')", "无", "显示 Settings", "失败留在 Workbench", "无", "T-SETTINGS-INCOME"),
  c("LMM-B-013", "今日", "今日工作台", "关闭工作台", "button", "Workbench 已打开", "单击关闭", "onClick", "close_workbench_transaction", "Mini 进入前状态", "关闭 Workbench 并恢复 Mini", "失败补偿恢复 Mini", "无", "T-MINI"),
  c("LMM-B-014", "今日", "今日收入进度", "调整今天", "button", "日期可编辑", "单击调整今天", "onClick", "open_date_override(owner_date)", "date_overrides", "打开统一日期调整事务", "加载失败显示可读错误", "关闭不修改", "T-DATE-OVERRIDE"),
  c("LMM-B-015", "今日", "今日收入进度", "记录加班", "button", "日期允许录入", "单击记录加班", "onClick", "open_overtime(owner_date)", "overtime_records", "打开加班事务", "边界计算失败禁止保存", "关闭不修改", "T-OVERTIME"),
  c("LMM-B-016", "今日", "今日收入进度", "重试同步", "button", "Dashboard error", "单击重试", "onClick", "refresh_dashboard", "无", "保留旧快照并重新同步", "继续显示失败原因", "无", "T-WORKBENCH-ERROR"),
  c("LMM-B-017", "今日", "今日安排", "阶段倒计时", "status", "快照有效", "查看距离上班/休息/恢复/下班", "dashboard snapshot", "next_boundary_seconds", "无", "每秒本地推进，权威同步收敛", "失败显示最后有效值", "无", "T-WORKBENCH-TODAY"),
  c("LMM-B-018", "今日", "今日安排", "时间线阶段", "status", "存在计划班次", "查看开始/休息/恢复/结束", "dashboard snapshot", "schedule_timeline", "无", "三列对齐并标记当前阶段", "无计划时显示休息态", "无", "T-WORKBENCH-TODAY"),
  c("LMM-B-019", "今日", "今日统计", "月度摘要", "status", "月度快照有效", "查看本月累计/工作日/倒计时", "dashboard snapshot", "monthly_summary", "无", "展示当前事实", "失败不伪造数据", "无", "T-WORKBENCH-TODAY"),

  c("LMM-B-020", "日历", "收入日历", "上个月", "button", "日历可导航", "单击左箭头", "onClick", "moveMonth(-1)", "当前查看月份", "加载上个月", "失败保留当前月", "无", "T-WORKBENCH-CALENDAR"),
  c("LMM-B-021", "日历", "收入日历", "下个月", "button", "日历可导航", "单击右箭头", "onClick", "moveMonth(1)", "当前查看月份", "加载下个月", "失败保留当前月", "无", "T-WORKBENCH-CALENDAR"),
  c("LMM-B-022", "日历", "收入日历", "选择日期", "date", "日期可用", "单击日期", "onClick", "setSelectedDate", "无", "更新选中态和操作对象", "无", "再次选择覆盖", "T-WORKBENCH-CALENDAR"),
  c("LMM-B-023", "日历", "收入日历", "双击调整日期", "date", "日期可编辑", "双击日期", "onDoubleClick", "open_date_override", "date_overrides", "打开日期调整事务", "失败保持日历", "关闭不修改", "T-DATE-OVERRIDE"),
  c("LMM-B-024", "日历", "收入日历", "调整日期", "button", "已选择日期", "单击调整日期", "onClick", "open_date_override", "date_overrides", "打开日期调整事务", "失败保持日历", "关闭不修改", "T-DATE-OVERRIDE"),
  c("LMM-B-025", "日历", "收入日历", "记录加班", "button", "已选择日期", "单击记录加班", "onClick", "open_overtime", "overtime_records", "打开加班事务", "失败保持日历", "关闭不修改", "T-OVERTIME"),
  c("LMM-B-026", "日历", "收入日历", "重试日历", "button", "calendar error/stale", "单击重试", "onClick", "refresh_calendar", "官方数据缓存", "重新加载且保护旧数据", "继续显示 stale/error", "无", "T-CALENDAR-ERROR"),
  c("LMM-B-027", "日历", "日期调整", "自动判断", "choice", "调整弹窗打开", "选择自动判断", "onClick", "setOverride('auto')", "date_overrides", "提交后删除手动覆盖", "保存失败保留旧值", "取消不变", "T-DATE-OVERRIDE"),
  c("LMM-B-028", "日历", "日期调整", "工作日", "choice", "调整弹窗打开", "选择工作日", "onClick", "setOverride('workday')", "date_overrides", "日期按工作日重算", "保存失败回滚", "取消不变", "T-DATE-OVERRIDE"),
  c("LMM-B-029", "日历", "日期调整", "带薪休息", "choice", "调整弹窗打开", "选择带薪休息", "onClick", "setOverride('paid_rest')", "date_overrides", "保留计薪但无有效工时", "保存失败回滚", "取消不变", "T-DATE-OVERRIDE"),
  c("LMM-B-030", "日历", "日期调整", "不带薪休息", "choice", "调整弹窗打开", "选择不带薪休息", "onClick", "setOverride('unpaid_rest')", "date_overrides", "不计薪且无有效工时", "保存失败回滚", "取消不变", "T-DATE-OVERRIDE"),
  c("LMM-B-031", "日历", "日期调整", "应用调整", "button", "选择有效", "单击应用", "onClick", "save_date_override", "date_overrides", "原子保存并全链路重算", "失败保留旧配置与输入", "无", "T-WORKBENCH-CALENDAR"),
  c("LMM-B-032", "日历", "日期调整", "取消调整", "button", "弹窗打开", "单击取消/关闭", "onClick", "close_date_override", "无", "关闭且不保存", "无", "显式取消", "T-WORKBENCH-CALENDAR"),
  c("LMM-B-033", "日历", "加班记录", "加班时长", "input", "加班弹窗打开", "输入小数小时", "onChange", "set_overtime_hours", "overtime_records.minutes", "按分钟精度与动态上限校验", "非法值阻止保存", "取消不变", "T-OVERTIME"),
  c("LMM-B-034", "日历", "加班记录", "保存加班", "button", "值有效", "单击保存", "onClick", "save_overtime_record", "hours/rate snapshot/source", "保存并刷新月度总结", "事务失败回滚", "无", "T-WORKBENCH-CALENDAR"),
  c("LMM-B-035", "日历", "加班记录", "删除加班", "button", "已有记录", "单击删除", "onClick", "delete_overtime_record", "overtime_records", "删除并刷新汇总", "失败保留记录", "取消确认不变", "T-OVERTIME"),
  c("LMM-B-036", "日历", "加班记录", "取消加班编辑", "button", "加班弹窗打开", "单击取消/关闭", "onClick", "close_overtime", "无", "关闭且不保存", "无", "显式取消", "T-WORKBENCH-CALENDAR"),

  c("LMM-B-040", "Wizard", "首次配置", "关闭 Wizard", "button", "Wizard 打开", "单击关闭", "onClick", "requestWizardClose", "配置草稿", "显示退出确认", "失败保持 Wizard", "继续编辑或退出应用", "T-WIZARD-CONFIRM-EXIT"),
  c("LMM-B-041", "Wizard", "步骤 1", "输入月薪", "input", "步骤 1", "输入金额", "onChange", "updateDraft.salary", "monthly_salary", "更新预计工作日与收入", "非法输入显示错误", "取消不保存", "T-WIZARD-1"),
  c("LMM-B-042", "Wizard", "步骤 1", "双休", "choice", "步骤 1", "选择双休", "onClick", "updateDraft.restMode", "rest_mode", "预计工作日重算", "无", "取消不保存", "T-WIZARD-1"),
  c("LMM-B-043", "Wizard", "步骤 1", "单休", "choice", "步骤 1", "选择单休", "onClick", "updateDraft.restMode", "rest_mode", "预计工作日重算", "无", "取消不保存", "T-WIZARD-1"),
  c("LMM-B-044", "Wizard", "步骤 1", "大小周", "choice", "步骤 1", "选择大小周", "onClick", "updateDraft.restMode", "rest_mode", "显示本周类型选择", "未选本周类型阻止下一步", "取消不保存", "T-WIZARD-1"),
  c("LMM-B-045", "Wizard", "步骤 1", "本周大周/小周", "select", "休息模式=大小周", "选择本周类型", "onChange", "updateDraft.alternatingWeek", "alternating_week", "锁定用户选择的大小周基准", "缺失时提示", "取消不保存", "T-WIZARD-1"),
  c("LMM-B-046", "Wizard", "步骤 2", "上班时间", "time", "步骤 2", "选择时间", "onChange", "updateDraft.workStart", "work_start", "推算休息与下班", "非法区间提示", "取消不保存", "T-WIZARD-2"),
  c("LMM-B-047", "Wizard", "步骤 2", "休息开始", "time", "步骤 2", "选择时间", "onChange", "updateDraft.restStart", "lunch_start", "保持休息时长并推算", "非法区间提示", "取消不保存", "T-WIZARD-2"),
  c("LMM-B-048", "Wizard", "步骤 2", "休息时长", "input", "步骤 2", "输入小数小时", "onChange", "updateDraft.restDuration", "lunch_duration_minutes", "按分钟推算休息结束与下班", "越界提示", "取消不保存", "T-WIZARD-2"),
  c("LMM-B-049", "Wizard", "步骤 2", "时间选择器确定", "button", "TimeField 弹层打开", "单击确定", "onClick", "commitTime", "对应时间字段", "关闭弹层并更新草稿", "无", "取消恢复旧值", "T-WIZARD-2"),
  c("LMM-B-050", "Wizard", "步骤 3", "完成配置", "button", "确认摘要有效", "单击完成", "onClick", "save_configuration", "config v8", "安全写入并打开 Mini", "失败保留草稿和旧配置", "无", "T-MINI"),
  c("LMM-B-051", "Wizard", "全步骤", "上一步", "button", "非步骤 1", "单击上一步", "onClick", "setWizardStep(step-1)", "草稿", "返回并保留输入", "无", "无", "T-WIZARD-1"),
  c("LMM-B-052", "Wizard", "步骤 1/2", "下一步", "button", "当前步骤有效", "单击下一步", "onClick", "setWizardStep(step+1)", "草稿", "进入下一步", "校验失败停留", "无", "T-WIZARD-2"),
  c("LMM-B-053", "Wizard", "全步骤", "取消", "button", "Wizard 打开", "单击取消", "onClick", "requestWizardClose", "草稿", "显示退出确认", "无", "继续编辑或退出应用", "T-WIZARD-CONFIRM-EXIT"),
  c("LMM-B-054", "Wizard", "退出确认", "继续编辑/退出应用", "choice", "存在未完成首次配置", "选择操作", "onClick", "continueEditing/exitApp", "无", "继续 Wizard 或退出进程", "退出失败记录日志", "关闭确认继续编辑", "T-WIZARD-CONFIRM-EXIT"),

  c("LMM-B-060", "Settings", "设置", "收入与作息", "tab", "Settings 打开", "切换分类", "onClick", "setSettingsSection('income')", "无", "显示收入与作息", "无", "无", "T-SETTINGS-INCOME"),
  c("LMM-B-061", "Settings", "设置", "日历", "tab", "Settings 打开", "切换分类", "onClick", "setSettingsSection('calendar')", "无", "显示日历配置", "无", "无", "T-SETTINGS-CALENDAR"),
  c("LMM-B-062", "Settings", "设置", "外观", "tab", "Settings 打开", "切换分类", "onClick", "setSettingsSection('appearance')", "无", "显示主题设置", "无", "无", "T-SETTINGS-APPEARANCE"),
  c("LMM-B-063", "Settings", "设置", "窗口与启动", "tab", "Settings 打开", "切换分类", "onClick", "setSettingsSection('window')", "无", "显示窗口设置", "无", "无", "T-SETTINGS-WINDOW"),
  c("LMM-B-064", "Settings", "设置", "数据与支持", "tab", "Settings 打开", "切换分类", "onClick", "setSettingsSection('support')", "无", "显示维护入口", "无", "无", "T-SETTINGS-SUPPORT"),
  c("LMM-B-065", "Settings", "收入与作息", "月薪", "input", "收入页", "编辑月薪", "onChange", "updateSettingsDraft", "monthly_salary", "标记未保存更改", "非法金额提示", "取消恢复", "T-SETTINGS-INCOME"),
  c("LMM-B-066", "Settings", "收入与作息", "休息模式", "select", "收入页", "选择单双休/大小周", "onChange", "updateSettingsDraft", "rest_mode", "重算草稿", "非法值回退", "取消恢复", "T-SETTINGS-INCOME"),
  c("LMM-B-067", "Settings", "收入与作息", "本周类型", "select", "大小周", "选择大周/小周", "onChange", "updateSettingsDraft", "alternating_week", "更新大小周基准", "缺失时阻止保存", "取消恢复", "T-SETTINGS-INCOME"),
  c("LMM-B-068", "Settings", "收入与作息", "上班时间", "time", "收入页", "选择时间", "onChange", "updateSettingsDraft", "work_start", "更新计划班次", "越界提示", "取消恢复", "T-SETTINGS-INCOME"),
  c("LMM-B-069", "Settings", "收入与作息", "下班时间", "time", "收入页", "选择时间", "onChange", "updateSettingsDraft", "work_end", "更新计划班次", "越界提示", "取消恢复", "T-SETTINGS-INCOME"),
  c("LMM-B-070", "Settings", "收入与作息", "休息开始", "time", "收入页", "选择时间", "onChange", "updateSettingsDraft", "lunch_start", "更新休息区间", "越界提示", "取消恢复", "T-SETTINGS-INCOME"),
  c("LMM-B-071", "Settings", "收入与作息", "休息结束", "time", "收入页", "选择时间", "onChange", "updateSettingsDraft", "lunch_end", "更新有效工时", "越界提示", "取消恢复", "T-SETTINGS-INCOME"),
  c("LMM-B-072", "Settings", "日历", "官方数据状态", "status", "日历页", "查看官方/估算/stale/error", "calendar state", "calendar_provider", "年度数据缓存", "展示真实来源", "失败保护旧数据", "无", "T-SETTINGS-CALENDAR"),
  c("LMM-B-073", "Settings", "外观", "浅色主题", "choice", "外观页", "选择浅色", "onClick", "preview_theme('light')", "theme_mode", "全部 WebView 即时预览", "预览失败回退已保存主题", "取消恢复", "T-SETTINGS-APPEARANCE"),
  c("LMM-B-074", "Settings", "外观", "深色主题", "choice", "外观页", "选择深色", "onClick", "preview_theme('dark')", "theme_mode", "全部 WebView 即时预览", "预览失败回退已保存主题", "取消恢复", "T-SETTINGS-APPEARANCE"),
  c("LMM-B-075", "Settings", "窗口与启动", "启动时显示", "toggle", "窗口页", "切换", "onChange", "updateSettingsDraft", "show_on_launch", "保存后影响下次启动", "保存失败保持旧值", "取消恢复", "T-SETTINGS-WINDOW"),
  c("LMM-B-076", "Settings", "窗口与启动", "始终置顶", "toggle", "窗口页", "切换", "onChange", "set_always_on_top", "always_on_top", "保存后重应用全部窗口", "原生失败提示并回滚", "取消恢复", "T-SETTINGS-WINDOW"),
  c("LMM-B-077", "Settings", "窗口与启动", "贴边自动隐藏", "toggle", "窗口页", "切换", "onChange", "set_edge_auto_hide", "mini_edge_auto_hide", "启用 Mini 隐私状态机", "失败保持 Mini 可见", "取消恢复", "T-SETTINGS-WINDOW"),
  c("LMM-B-078", "Settings", "窗口与启动", "开机启动", "toggle", "Windows 原生能力可用", "切换", "onChange", "set_auto_start", "HKCU Run + config", "事务写入注册表与配置", "失败补偿并提示", "取消恢复", "WINDOWS-NATIVE-STARTUP"),
  c("LMM-B-079", "Settings", "数据与支持", "打开数据目录", "button", "支持页", "单击", "onClick", "open_data_directory", "无", "打开本地数据目录", "失败显示可读错误", "无", "WINDOWS-NATIVE-DATA"),
  c("LMM-B-080", "Settings", "数据与支持", "复制诊断摘要", "button", "支持页", "单击", "onClick", "copy_diagnostic_summary", "系统剪贴板", "复制脱敏摘要", "失败提示", "无", "WINDOWS-NATIVE-CLIPBOARD"),
  c("LMM-B-081", "Settings", "数据与支持", "检查更新", "button", "支持页", "单击", "onClick", "evaluate_update", "last_update_check", "显示最新/有更新/失败", "失败不破坏当前版本", "无", "T-UPDATE"),
  c("LMM-B-082", "Settings", "设置底栏", "恢复默认", "button", "Settings 打开", "单击", "onClick", "restore_defaults_draft", "配置草稿", "填入默认值并标记 dirty", "无", "确认取消不变", "T-SETTINGS"),
  c("LMM-B-083", "Settings", "设置底栏", "保存", "button", "Settings 打开", "单击", "onClick", "save_configuration", "config v8", "saved/unchanged 反馈并同步窗口", "failed 保留输入和旧配置", "失败后继续编辑", "T-SETTINGS"),
  c("LMM-B-084", "Settings", "设置", "关闭/取消", "button", "Settings 打开", "单击关闭", "onClick", "close_settings", "配置草稿", "无改动直接关闭；有改动确认", "失败保持窗口", "取消关闭继续编辑", "T-SETTINGS"),

  c("LMM-B-090", "系统", "原生托盘", "显示/隐藏 Mini", "native", "托盘可用", "左键托盘图标", "tray-toggle-mini", "toggle_mini_window", "窗口可见性", "隐藏或恢复 Mini", "失败记录日志", "无", "WINDOWS-NATIVE-TRAY"),
  c("LMM-B-091", "系统", "原生托盘", "今日工作台", "native", "托盘菜单打开", "选择今日工作台", "tray-workbench", "show_window('workbench')", "无", "隐藏 Mini 并显示 Workbench", "失败恢复 Mini", "菜单外点击关闭", "T-WORKBENCH-TODAY"),
  c("LMM-B-092", "系统", "原生托盘", "设置", "native", "托盘菜单打开", "选择设置", "tray-settings", "show_window('settings')", "无", "显示 Settings", "失败记录日志", "菜单外点击关闭", "T-SETTINGS"),
  c("LMM-B-093", "系统", "原生托盘", "重新配置", "native", "托盘菜单打开", "选择重新配置", "tray-wizard", "show_window('wizard')", "无", "Wizard 从第一页打开", "失败记录日志", "菜单外点击关闭", "T-WIZARD-1"),
  c("LMM-B-094", "系统", "原生托盘", "打开数据目录", "native", "托盘菜单打开", "选择数据目录", "tray-data-dir", "open_data_directory", "无", "打开目录", "失败记录日志", "菜单外点击关闭", "WINDOWS-NATIVE-DATA"),
  c("LMM-B-095", "系统", "原生托盘", "退出", "native", "托盘菜单打开", "选择退出", "tray-exit", "exit_app", "无", "停止进程", "失败记录日志", "取消菜单不退出", "WINDOWS-NATIVE-EXIT"),
  c("LMM-B-096", "系统", "更新状态", "打开发布页", "button", "检测到新版本", "单击查看更新", "onClick", "open_release_page", "无", "在浏览器打开 GitHub Release", "失败显示链接", "无", "WINDOWS-NATIVE-BROWSER"),
  c("LMM-B-097", "系统", "更新状态", "重试检查", "button", "检查失败", "单击重试", "onClick", "evaluate_update", "无", "重新请求", "保留当前可运行版本", "无", "T-UPDATE"),
  c("LMM-B-098", "系统", "配置恢复", "打开数据目录", "button", "配置损坏已恢复", "单击", "onClick", "open_data_directory", "无", "查看恢复文件", "失败提示", "关闭提示", "WINDOWS-NATIVE-DATA"),
  c("LMM-B-099", "系统", "配置恢复", "知道了", "button", "恢复提示可见", "单击", "onClick", "dismiss_feedback", "无", "关闭提示", "无", "无", "T-SETTINGS-SUPPORT"),
  c("LMM-B-100", "系统", "窗口找回", "恢复安全位置", "native", "窗口不可达", "托盘找回或显示环境变化", "window shown", "recover_window_position", "window positions", "保持可见抓取区", "失败居中显示", "无", "T-MINI"),
  c("LMM-B-101", "系统", "主题同步", "跨窗口主题", "event", "主题预览或保存", "广播主题事件", "lmm://theme-updated", "applyTheme", "theme_mode", "Mini/Workbench/Settings/Wizard 同步", "非法值回退浅色", "取消预览恢复已保存主题", "T-DESIGN-SYSTEM"),
  c("LMM-B-102", "系统", "配置同步", "跨窗口配置", "event", "配置保存成功", "广播配置事件", "lmm://configuration-updated", "refreshConfiguration", "config v8", "全部窗口收敛到权威配置", "失败保留最后有效配置", "无", "T-DESIGN-SYSTEM"),
  c("LMM-B-103", "系统", "窗口生命周期", "隐藏/恢复暂停", "event", "窗口隐藏或显示", "原生发送事件", "lmm:window-hidden/shown", "pause/resume timers", "无", "隐藏停止 tick；恢复立即权威同步", "避免重复注册 timer", "无", "T-WINDOW-LIFECYCLE")
];

function hex(value) {
  const raw = value.replace("#", "");
  return { r: parseInt(raw.slice(0, 2), 16) / 255, g: parseInt(raw.slice(2, 4), 16) / 255, b: parseInt(raw.slice(4, 6), 16) / 255 };
}
function solid(value, opacity = 1) { return { type: "SOLID", color: hex(value), opacity }; }
function setFill(node, value) { node.fills = [solid(value)]; }
function setStroke(node, value, width = 1) { node.strokes = [solid(value)]; node.strokeWeight = width; }
function owned(node, role = "node", kind = "design") {
  node.setSharedPluginData(OWNER_NAMESPACE, "owner", OWNER_NAME);
  node.setSharedPluginData(OWNER_NAMESPACE, "builder", BUILDER_VERSION);
  node.setSharedPluginData(OWNER_NAMESPACE, "role", role);
  node.setSharedPluginData(OWNER_NAMESPACE, "kind", kind);
  return node;
}
function frame(parent, name, x, y, width, height, fill = DOC.surface, stroke = DOC.line, radius = 12, clip = false) {
  const node = owned(figma.createFrame(), name, "frame"); node.name = name; node.x = x; node.y = y; node.resize(width, height);
  setFill(node, fill); if (stroke) setStroke(node, stroke); node.cornerRadius = radius; node.clipsContent = clip; parent.appendChild(node); return node;
}
function rect(parent, name, x, y, width, height, fill, radius = 8, stroke = "") {
  const node = owned(figma.createRectangle(), name, "shape"); node.name = name; node.x = x; node.y = y; node.resize(width, height); setFill(node, fill);
  if (stroke) setStroke(node, stroke); node.cornerRadius = radius; parent.appendChild(node); return node;
}
function line(parent, x1, y1, x2, y2, color, width = 1) {
  const node = owned(figma.createLine(), "分隔线", "shape"); node.name = "分隔线"; node.x = x1; node.y = y1; node.resize(Math.max(1, x2 - x1), Math.max(0, y2 - y1)); setStroke(node, color, width); parent.appendChild(node); return node;
}
function text(parent, value, x, y, style = "body", color = DOC.text, width = 0, options = {}) {
  const summary = String(value).replace(/\s+/g, " ").trim().slice(0, 24) || "空文本";
  const node = owned(figma.createText(), summary, "text"); node.name = summary; node.fontName = fonts[TYPE[style].weight] || fonts.regular; node.fontSize = TYPE[style].size;
  node.lineHeight = { unit: "PIXELS", value: TYPE[style].line }; node.characters = value; node.x = x; node.y = y; node.fills = [solid(color)];
  if (width) { node.resize(width, Math.max(TYPE[style].line, options.height || TYPE[style].line)); node.textAutoResize = options.autoHeight === false ? "NONE" : "HEIGHT"; }
  else node.textAutoResize = "WIDTH_AND_HEIGHT";
  if (options.align) node.textAlignHorizontal = options.align;
  if (options.opacity !== undefined) node.opacity = options.opacity;
  parent.appendChild(node); return node;
}
function pill(parent, value, x, y, tone = "neutral") {
  const palette = tone === "coin" ? [LIGHT.coinSoft, LIGHT.ink] : tone === "success" ? [LIGHT.mintSoft, LIGHT.mint] : tone === "native" ? [LIGHT.blueSoft, LIGHT.blue] : [DOC.soft, DOC.muted];
  const width = Math.max(72, value.length * 13 + 24); const bg = frame(parent, `状态标签/${value}`, x, y, width, 28, palette[0], "", 14); text(bg, value, 12, 5, "caption", palette[1]); return bg;
}
function calendarMarker(parent, value, x, y, tone, theme = LIGHT) {
  const fill = tone === "today" ? theme.ink : theme.coin;
  const foreground = tone === "today" ? theme.surface : theme.ink;
  const markerTone = tone === "today" ? "今天" : tone === "overtime" ? "加班" : "日期状态";
  const marker = frame(parent, `日历标记/${markerTone}`, x, y, 22, 22, fill, "", 7);
  text(marker, value, 0, 1, "caption", foreground, 22, { align: "CENTER", autoHeight: false, height: 20 });
  return marker;
}
function target(node, id) { node.setSharedPluginData(OWNER_NAMESPACE, "flow-target", id); return node; }
function attachContract(node, id) {
  const spec = CONTROL_SPECS.find((item) => item.id === id); if (!spec) throw new Error(`未知控件契约：${id}`);
  node.setSharedPluginData(OWNER_NAMESPACE, "control-contract-ids", id);
  node.setSharedPluginData(OWNER_NAMESPACE, "control-contract", JSON.stringify(spec));
  node.name = `${node.name} / ${id}`; return node;
}
function button(parent, id, label, x, y, width = 112, variant = "primary", theme = LIGHT) {
  const fill = variant === "primary" ? theme.coin : variant === "danger" ? theme.danger : variant === "ghost" ? theme.surface : theme.elevated;
  const stroke = variant === "primary" ? theme.coin : variant === "danger" ? theme.danger : theme.line;
  const fg = variant === "danger" ? "#FFFFFF" : theme.ink; const node = attachContract(frame(parent, `按钮/${label}`, x, y, width, 38, fill, stroke, 9), id);
  text(node, label, 12, 8, "label", fg, width - 24, { align: "CENTER", autoHeight: false, height: 20 }); return node;
}
function input(parent, id, label, value, x, y, width = 220, theme = LIGHT) {
  text(parent, label, x, y, "label", theme.ink); const node = attachContract(frame(parent, `输入框/${label}`, x, y + 24, width, 42, theme.surface, theme.lineStrong, 9), id);
  text(node, value, 12, 10, "body", theme.ink, width - 24); return node;
}
function selectControl(parent, id, label, value, x, y, width = 220, theme = LIGHT) {
  text(parent, label, x, y, "label", theme.ink); const node = attachContract(frame(parent, `下拉选择器/${label}`, x, y + 24, width, 42, theme.surface, theme.lineStrong, 9), id);
  text(node, value, 12, 10, "body", theme.ink, width - 50); text(node, "⌄", width - 28, 8, "heading", theme.muted); return node;
}
function toggle(parent, id, label, x, y, active = true, theme = LIGHT) {
  text(parent, label, x, y + 3, "body", theme.ink); const node = attachContract(frame(parent, `开关/${label}`, x + 300, y, 42, 24, active ? theme.mint : theme.line, "", 12), id);
  rect(node, "开关滑块", active ? 20 : 2, 2, 20, 20, theme.surface, 10); return node;
}
function choice(parent, id, label, x, y, width = 146, selected = false, theme = LIGHT) {
  const node = attachContract(frame(parent, `选项/${label}`, x, y, width, 54, selected ? theme.coinSoft : theme.surface, selected ? theme.coin : theme.line, 9), id);
  text(node, label, 14, 16, "body", theme.ink, width - 28, { align: "CENTER" }); return node;
}
function contractFor(id) { const spec = CONTROL_SPECS.find((item) => item.id === id); if (!spec) throw new Error(`缺少契约 ${id}`); return spec; }
const CONTRACT_KIND_LABELS = { button: "按钮", drag: "拖动区域", native: "Windows 原生交互", toggle: "开关", status: "状态信息", tab: "页签", date: "日期单元格", choice: "选项", input: "输入框", time: "时间选择器", select: "下拉选择器" };
const CONTRACT_AREA_LABELS = { Mini: "迷你收入视图", 今日: "今日工作台", 日历: "收入日历", Wizard: "首次配置", Settings: "设置", 系统: "系统与支持" };
const CONTRACT_EVENT_LABELS = {
  onClick: "单击事件（onClick）", onChange: "输入变化事件（onChange）", onDoubleClick: "双击事件（onDoubleClick）",
  pointerdown: "指针按下事件（pointerdown）", "pointerenter/onClick": "指针进入或单击事件（pointerenter / onClick）",
  dragCompleted: "拖动结束事件（dragCompleted）", "tray-toggle-mini": "托盘切换迷你窗口事件（tray-toggle-mini）",
  "dashboard snapshot": "收入快照更新（dashboard snapshot）", "WindowEvent::CloseRequested": "Windows 窗口关闭请求（WindowEvent::CloseRequested）"
};
const CONTRACT_METHOD_LABELS = {
  finalize_mini_drag: "完成拖动并判断是否贴边（finalize_mini_drag）", start_window_drag: "启动原生窗口拖动（start_window_drag）",
  toggle_mini_window: "切换迷你窗口显示状态（toggle_mini_window）", refresh_dashboard: "重新同步收入快照（refresh_dashboard）",
  next_boundary_seconds: "读取下一个业务边界倒计时（next_boundary_seconds）", schedule_timeline: "读取今日安排时间线（schedule_timeline）",
  monthly_summary: "读取月度摘要（monthly_summary）", open_date_override: "打开日期调整事务（open_date_override）",
  open_overtime: "打开加班记录事务（open_overtime）", save_date_override: "保存日期调整事务（save_date_override）",
  save_overtime_record: "保存加班记录（save_overtime_record）", delete_overtime_record: "删除加班记录（delete_overtime_record）",
  refresh_calendar: "重新加载日历数据（refresh_calendar）"
};
const CONTRACT_DATA_LABELS = {
  mini_edge_auto_hide: "读取贴边自动隐藏设置，并更新迷你窗口贴边状态（mini_edge_auto_hide）",
  mini_window_position: "保存迷你窗口位置（mini_window_position）", "窗口可见性": "更新窗口显示与隐藏状态",
  date_overrides: "更新手动日期调整记录（date_overrides）", overtime_records: "更新加班记录（overtime_records）",
  "overtime_records.minutes": "更新加班分钟数（overtime_records.minutes）", "当前查看月份": "更新当前查看月份",
  "官方数据缓存": "更新官方日历数据缓存"
};
const CONTRACT_TARGET_LABELS = {
  "T-MINI": "迷你收入视图（T-MINI）", "T-MINI-PRIVACY": "迷你窗口隐私竖条状态（T-MINI-PRIVACY）",
  "T-MINI-ERROR": "迷你窗口错误状态（T-MINI-ERROR）", "T-WORKBENCH-TODAY": "今日工作台（T-WORKBENCH-TODAY）",
  "T-WORKBENCH-CALENDAR": "收入日历（T-WORKBENCH-CALENDAR）", "T-WORKBENCH-ERROR": "今日工作台错误状态（T-WORKBENCH-ERROR）",
  "T-DATE-OVERRIDE": "日期调整事务（T-DATE-OVERRIDE）", "T-OVERTIME": "加班记录事务（T-OVERTIME）",
  "T-SETTINGS-INCOME": "设置中的收入与作息页（T-SETTINGS-INCOME）", "WINDOWS-NATIVE-TRAY": "Windows 原生托盘边界（WINDOWS-NATIVE-TRAY）"
};
function technicalFallback(value, field) {
  if (!value || value === "无") return value || "无";
  if (/[\u3400-\u9fff]/.test(value)) return value;
  const prefixes = { signal: "技术事件", method: "调用方法", persistence: "配置或运行状态", target: "目标界面或系统边界" };
  return `${prefixes[field] || "技术标识"}（${value}）`;
}
function localizedContractValue(value, field) {
  if (field === "condition") {
    const conditions = { "Settings 已启用": "已在设置中开启“贴边自动隐藏”", "Mini 可见": "迷你收入视图当前可见", "Mini 被用户隐藏": "迷你收入视图已被用户隐藏", "Workbench 已打开": "今日工作台已经打开", "Dashboard error": "收入快照同步失败" };
    return conditions[value] || value.replace(/Mini/g, "迷你收入视图").replace(/Workbench/g, "今日工作台").replace(/Settings/g, "设置").replace(/Dashboard/g, "收入快照");
  }
  if (field === "signal") return CONTRACT_EVENT_LABELS[value] || technicalFallback(value, field);
  if (field === "method") return CONTRACT_METHOD_LABELS[value] || technicalFallback(value, field);
  if (field === "persistence") return CONTRACT_DATA_LABELS[value] || technicalFallback(value, field);
  if (field === "target") return CONTRACT_TARGET_LABELS[value] || technicalFallback(value, field);
  return value;
}
function contractRows(spec, localized = true) {
  const value = (field) => localized ? localizedContractValue(spec[field], field) : spec[field];
  return [
    ["控件类型", CONTRACT_KIND_LABELS[spec.kind] || spec.kind],
    ["所在界面", `${CONTRACT_AREA_LABELS[spec.area] || spec.area} / ${spec.screen}`],
    ["出现条件", value("condition")],
    ["用户操作", spec.operation],
    [localized ? "触发事件" : "触发信号", value("signal")],
    [localized ? "调用链路" : "调用对象", value("method")],
    [localized ? "数据与状态" : "数据影响", value("persistence")],
    [localized ? "用户可见结果" : "成功结果", spec.result],
    [localized ? "失败与恢复" : "失败补偿", spec.failure],
    ["取消 / 关闭", spec.cancel],
    [localized ? "去向 / 系统边界" : "跳转 / 边界", value("target")]
  ];
}
function contractCard(parent, spec, x, y) {
  const card = frame(parent, `控件契约/${spec.label} / ${spec.id}`, x, y, CONTRACT_CARD_WIDTH, CONTRACT_CARD_HEIGHT, DOC.surface, DOC.line, 8);
  card.setSharedPluginData(OWNER_NAMESPACE, "control-contract-ids", spec.id); card.setSharedPluginData(OWNER_NAMESPACE, "control-contract", JSON.stringify(spec)); card.setSharedPluginData(OWNER_NAMESPACE, "control-contract-localized", JSON.stringify(contractRows(spec, true)));
  text(card, spec.label, 16, 18, "heading", DOC.text, CONTRACT_CARD_WIDTH - 32);
  const rows = contractRows(spec, true);
  rows.forEach((row, index) => { const yy = 64 + index * 29; text(card, row[0], 16, yy, "caption", DOC.muted, 108); text(card, row[1], 132, yy, "caption", DOC.text, CONTRACT_CARD_WIDTH - 148); }); return card;
}
function contractBoard(parent, ids, y) {
  const rows = Math.ceil(ids.length / CONTRACT_COLUMNS); const boardWidth = 32 + CONTRACT_COLUMNS * CONTRACT_CARD_WIDTH + (CONTRACT_COLUMNS - 1) * CONTRACT_GAP; const board = frame(parent, "本区控件契约", SECTION_PADDING, y, boardWidth, 54 + rows * (CONTRACT_CARD_HEIGHT + CONTRACT_GAP), DOC.soft, DOC.line, 10);
  text(board, "本区控件契约", 16, 14, "heading", DOC.text); text(board, "逐项说明出现条件、用户操作、调用链路、数据影响、成功结果、失败补偿、取消语义与跳转边界。", 172, 17, "caption", DOC.muted);
  ids.forEach((id, index) => { const col = index % CONTRACT_COLUMNS; const row = Math.floor(index / CONTRACT_COLUMNS); contractCard(board, contractFor(id), 16 + col * (CONTRACT_CARD_WIDTH + CONTRACT_GAP), 54 + row * (CONTRACT_CARD_HEIGHT + CONTRACT_GAP)); });
  return y + board.height + GROUP_GAP;
}
function inventory(parent, ids, x, y, width, height) {
  const availableColumns = Math.max(1, Math.floor((width - 36 + INVENTORY_GAP) / (INVENTORY_ITEM_WIDTH + INVENTORY_GAP)));
  const columns = Math.max(1, Math.min(ids.length, INVENTORY_MAX_COLUMNS, availableColumns));
  const rows = Math.ceil(ids.length / columns);
  const actualWidth = 36 + columns * INVENTORY_ITEM_WIDTH + (columns - 1) * INVENTORY_GAP;
  const actualHeight = 82 + rows * INVENTORY_ROW_HEIGHT;
  const box = frame(parent, "交互控件清单", x, y, actualWidth, actualHeight, DOC.surface, DOC.line, 10, true); text(box, "交互清单", 18, 14, "heading", DOC.text); text(box, "可编辑控件实例；详细行为见下方契约。", 18, 44, "caption", DOC.muted);
  ids.forEach((id, index) => { const spec = contractFor(id); const col = index % columns; const row = Math.floor(index / columns); const xx = 18 + col * (INVENTORY_ITEM_WIDTH + INVENTORY_GAP); const yy = 76 + row * INVENTORY_ROW_HEIGHT; const item = attachContract(frame(box, `控件实例/${spec.label}`, xx, yy, INVENTORY_ITEM_WIDTH, 40, DOC.soft, DOC.line, 7), id); text(item, spec.label, 12, 10, "label", DOC.text, INVENTORY_ITEM_WIDTH - 24); }); return box;
}
function flowCard(parent, id, title, detail, x, y, width = 300, native = false) {
  const card = target(frame(parent, `流程节点/${title}`, x, y, width, 92, native ? DOC.blueSoft : DOC.surface, native ? DOC.blue : DOC.line, 8), id); text(card, title, 14, 18, "heading", DOC.text, width - 28); text(card, detail, 14, 52, "caption", DOC.muted, width - 28); return card;
}
function connector(parent, x, y, width, label) { line(parent, x, y + 12, x + width, y + 12, DOC.muted, 1); if (label) text(parent, label, x + 8, y - 18, "caption", DOC.muted, width - 16, { align: "CENTER" }); }
function section(parent, index, title, subtitle, y, height) {
  const area = owned(frame(parent, `第 ${String(index).padStart(2, "0")} 区 / ${title}`, 40, y, GRID_WIDTH, height, DOC.canvas, "", 0), `section/${index}`, "section");
  text(area, `${String(index).padStart(2, "0")}  ${title}`, 24, 18, "title", DOC.text); text(area, subtitle, 24, 54, "body", DOC.muted, 5000); line(area, 24, 86, GRID_WIDTH - 24, 86, DOC.line); return area;
}
function windowShell(parent, id, title, x, y, width, height, dark = false) {
  const theme = dark ? DARK : LIGHT; const shell = target(frame(parent, `应用窗口/${title}`, x, y, width, height, theme.surface, theme.lineStrong, 14, true), id);
  shell.effects = [{ type: "DROP_SHADOW", color: { ...hex("#000000"), a: dark ? 0.42 : 0.18 }, offset: { x: 0, y: 12 }, radius: 28, spread: -4, visible: true, blendMode: "NORMAL" }];
  rect(shell, "标题栏", 0, 0, width, 50, theme.elevated, 0); line(shell, 0, 50, width, 50, theme.line); if (brandImage) { const icon = rect(shell, "L2 品牌标识", 16, 12, 26, 26, theme.surface, 7); icon.fills = [{ type: "IMAGE", imageHash: brandImage.hash, scaleMode: "FILL" }]; }
  text(shell, title, 52, 15, "label", theme.ink); text(shell, "×", width - 30, 11, "heading", theme.muted); return shell;
}
function stat(parent, label, value, x, y, width, theme = LIGHT) { const card = frame(parent, `数据摘要/${label}`, x, y, width, 70, theme.subtle, theme.line, 9); text(card, label, 12, 10, "caption", theme.muted); text(card, value, 12, 32, "heading", theme.ink); return card; }
function progress(parent, x, y, width, value, theme = LIGHT) { rect(parent, "进度轨道", x, y, width, 6, theme.line, 3); rect(parent, "进度值", x, y, Math.max(8, width * value), 6, theme.coin, 3); }

function drawMini(parent, x, y, dark = false, state = "working") {
  const stateNames = { before: "上班前", working: "工作中", resting: "休息中", rest: "休息日", error: "错误状态" }; const theme = dark ? DARK : LIGHT; const mini = target(frame(parent, `迷你收入视图/${stateNames[state] || state}/${dark ? "深色" : "浅色"}`, x, y, 344, 108, theme.surface, theme.lineStrong, 14, true), state === "error" ? "T-MINI-ERROR" : "T-MINI");
  mini.effects = [{ type: "DROP_SHADOW", color: { ...hex("#000000"), a: dark ? 0.38 : 0.2 }, offset: { x: 0, y: 8 }, radius: 20, spread: -2, visible: true, blendMode: "NORMAL" }];
  if (state === "error") { text(mini, "暂时无法计算", 18, 18, "heading", theme.ink); text(mini, "保留上一次有效结果", 18, 48, "caption", theme.muted); button(mini, "LMM-B-004", "重试", 252, 34, 74, "secondary", theme); return mini; }
  if (state === "rest") { pill(mini, "休息日", 16, 14, "success"); text(mini, "今天好好休息", 16, 48, "heading", theme.ink); text(mini, "下个工作日继续记录", 16, 76, "caption", theme.muted); return mini; }
  pill(mini, state === "before" ? "上班前" : state === "resting" ? "休息中" : "工作中", 16, 12, "success"); text(mini, "今日已赚", 16, 44, "caption", theme.muted); text(mini, state === "before" ? "¥0.00" : "¥186.42", 16, 62, "title", theme.ink); progress(mini, 164, 66, 160, state === "before" ? 0 : .56, theme); text(mini, state === "before" ? "距离上班 00:38:20" : state === "resting" ? "距离恢复工作 00:42:00" : "距离下班 04:38:20", 164, 80, "caption", theme.muted, 164); return mini;
}
function drawPrivacyTab(parent, x, y, dark = false) { const theme = dark ? DARK : LIGHT; const tab = target(frame(parent, "迷你收入视图隐私竖条", x, y, 34, 108, theme.surface, theme.lineStrong, 8, true), "T-MINI-PRIVACY"); text(tab, "距\n离\n下\n班", 8, 12, "caption", theme.ink, 18, { align: "CENTER" }); text(tab, "4h", 8, 82, "caption", theme.coin, 18, { align: "CENTER" }); return tab; }
function drawToday(parent, x, y, dark = false) {
  const theme = dark ? DARK : LIGHT; const shell = windowShell(parent, "T-WORKBENCH-TODAY", "LetsMakeMoney", x, y, 820, 620, dark);
  rect(shell, "侧边导航", 0, 50, 148, 570, theme.subtle, 0); button(shell, "LMM-B-010", "今日", 14, 76, 120, "primary", theme); button(shell, "LMM-B-011", "日历", 14, 122, 120, "ghost", theme); button(shell, "LMM-B-012", "设置", 14, 554, 120, "ghost", theme);
  text(shell, "8月5日星期三 · 工作日", 176, 76, "caption", theme.muted); text(shell, "今日收入进度", 176, 104, "title", theme.ink); pill(shell, "工作中", 704, 76, "success");
  const hero = frame(shell, "今日收入摘要", 176, 150, 616, 170, theme.elevated, theme.line, 12); text(hero, "今日已赚", 20, 18, "body", theme.muted); text(hero, "¥611.21", 20, 46, "numeric", theme.ink); text(hero, "日薪 ¥714.29 · 时薪 ¥89.29", 20, 90, "caption", theme.muted); progress(hero, 20, 122, 576, .86, theme); text(hero, "工作进度", 20, 136, "caption", theme.muted); text(hero, "86%", 556, 136, "label", theme.ink);
  button(shell, "LMM-B-014", "调整今天", 572, 336, 104, "ghost", theme); button(shell, "LMM-B-015", "记录加班", 688, 336, 104, "secondary", theme);
  const timeline = frame(shell, "今日安排时间线", 176, 386, 388, 206, theme.elevated, theme.line, 12); text(timeline, "今日安排", 18, 16, "heading", theme.ink); [["09:00", "开始工作"], ["12:00", "开始休息"], ["13:30", "恢复工作"], ["18:30", "结束工作"]].forEach((item, index) => { const yy = 56 + index * 36; text(timeline, item[0], 18, yy, "caption", theme.muted); rect(timeline, "时间线节点", 78, yy + 4, 8, 8, index < 3 ? theme.mint : theme.coin, 4); if (index < 3) line(timeline, 82, yy + 12, 82, yy + 38, theme.lineStrong); text(timeline, item[1], 102, yy - 2, "label", theme.ink); });
  const stats = frame(shell, "月度数据摘要", 580, 386, 212, 206, theme.elevated, theme.line, 12); stat(stats, "本月累计", "¥8,342.00", 12, 12, 188, theme); stat(stats, "实际工时", "104 小时", 12, 88, 188, theme); text(stats, "距离下班 01:09:16", 16, 174, "label", theme.ink); return shell;
}
function drawCalendar(parent, x, y, dark = false) {
  const theme = dark ? DARK : LIGHT; const shell = windowShell(parent, "T-WORKBENCH-CALENDAR", "LetsMakeMoney", x, y, 820, 620, dark);
  rect(shell, "侧边导航", 0, 50, 148, 570, theme.subtle, 0); button(shell, "LMM-B-010", "今日", 14, 76, 120, "ghost", theme); button(shell, "LMM-B-011", "日历", 14, 122, 120, "primary", theme); button(shell, "LMM-B-012", "设置", 14, 554, 120, "ghost", theme);
  text(shell, "2026 年 8 月", 176, 76, "caption", theme.muted); text(shell, "收入日历", 176, 104, "title", theme.ink); button(shell, "LMM-B-024", "调整日期", 602, 84, 90, "secondary", theme); button(shell, "LMM-B-025", "记录加班", 700, 84, 92, "secondary", theme);
  const calendar = frame(shell, "收入日历网格", 176, 150, 616, 442, theme.elevated, theme.line, 12); button(calendar, "LMM-B-020", "‹", 18, 14, 36, "ghost", theme); text(calendar, "2026 年 8 月", 206, 20, "label", theme.ink, 204, { align: "CENTER" }); button(calendar, "LMM-B-021", "›", 562, 14, 36, "ghost", theme);
  ["日", "一", "二", "三", "四", "五", "六"].forEach((day, index) => text(calendar, day, 22 + index * 82, 60, "caption", theme.muted, 72, { align: "CENTER" }));
  for (let day = 1; day <= 31; day += 1) { const offset = 6; const index = day - 1 + offset; const col = index % 7; const row = Math.floor(index / 7); const xx = 18 + col * 82; const yy = 88 + row * 54; const work = col !== 0 && col !== 6; const isToday = day === 4; const cell = attachContract(frame(calendar, `日期/${day}日`, xx, yy, 72, 44, work ? theme.mintSoft : theme.subtle, isToday ? theme.mint : theme.line, 8), "LMM-B-022"); text(cell, String(day), 0, 12, "body", theme.ink, 72, { align: "CENTER" }); if (isToday) { calendarMarker(cell, "今", 4, 3, "today", theme); calendarMarker(cell, "加", 46, 3, "overtime", theme); } }
  const summary = frame(calendar, "月度总结", 18, 376, 580, 50, theme.subtle, theme.line, 8); text(summary, "月度总结", 12, 8, "caption", theme.muted); text(summary, "计划 160h", 112, 15, "label", theme.ink); text(summary, "实际 104h", 252, 15, "label", theme.ink); text(summary, "加班 5h", 402, 15, "label", theme.ink); return shell;
}
function drawDateOverride(parent, x, y, dark = false) { const theme = dark ? DARK : LIGHT; const modal = target(frame(parent, "日期调整弹窗", x, y, 520, 280, theme.elevated, theme.lineStrong, 14), "T-DATE-OVERRIDE"); text(modal, "调整 8月5日星期三", 22, 22, "title", theme.ink); text(modal, "选择这一天在收入与工时计算中的身份。", 22, 60, "body", theme.muted); choice(modal, "LMM-B-027", "自动判断", 22, 100, 110, false, theme); choice(modal, "LMM-B-028", "工作日", 140, 100, 100, true, theme); choice(modal, "LMM-B-029", "带薪休息", 248, 100, 112, false, theme); choice(modal, "LMM-B-030", "不带薪休息", 368, 100, 130, false, theme); button(modal, "LMM-B-032", "取消", 318, 220, 82, "ghost", theme); button(modal, "LMM-B-031", "应用", 410, 220, 88, "primary", theme); return modal; }
function drawOvertime(parent, x, y, dark = false) { const theme = dark ? DARK : LIGHT; const modal = target(frame(parent, "加班记录弹窗", x, y, 500, 330, theme.elevated, theme.lineStrong, 14), "T-OVERTIME"); text(modal, "记录加班", 22, 22, "title", theme.ink); text(modal, "8月5日 · 工作日", 22, 58, "body", theme.muted); input(modal, "LMM-B-033", "加班时长（小时）", "2.50", 22, 96, 214, theme); const info = frame(modal, "加班动态上限", 254, 120, 224, 66, theme.mintSoft, "", 9); text(info, "本次上限", 12, 10, "caption", theme.mint); text(info, "13.50 小时 · 1.0× 快照", 12, 32, "label", theme.ink); button(modal, "LMM-B-035", "删除记录", 22, 266, 104, "danger", theme); button(modal, "LMM-B-036", "取消", 298, 266, 82, "ghost", theme); button(modal, "LMM-B-034", "保存", 390, 266, 88, "primary", theme); return modal; }
function drawWizard(parent, x, y, step = 1, dark = false) {
  const theme = dark ? DARK : LIGHT; const shell = windowShell(parent, step === 1 ? "T-WIZARD-1" : step === 2 ? "T-WIZARD-2" : "T-WIZARD-3", "开始配置", x, y, 780, 580, dark);
  rect(shell, "首次配置步骤栏", 0, 50, 190, 530, theme.subtle, 0); text(shell, "首次配置", 22, 86, "caption", theme.muted); text(shell, "三分钟完成", 22, 112, "title", theme.ink); [[1, "收入与休息"], [2, "工作与休息"], [3, "确认配置"]].forEach((item, index) => { const yy = 170 + index * 48; rect(shell, `配置步骤/${item[0]}`, 22, yy, 28, 28, item[0] === step ? theme.coin : item[0] < step ? theme.mint : theme.surface, 14, theme.line); text(shell, String(item[0]), 22, yy + 5, "caption", theme.ink, 28, { align: "CENTER" }); text(shell, item[1], 62, yy + 5, "label", theme.ink); }); text(shell, "✓ 配置只保存在本机", 22, 538, "caption", theme.mint);
  text(shell, `第 ${step} 步，共 3 步`, 224, 84, "caption", theme.muted); const title = step === 1 ? "先告诉我们你的月薪" : step === 2 ? "安排你的工作与休息" : "确认后开始使用"; text(shell, title, 224, 116, "title", theme.ink); text(shell, step === 1 ? "用于计算日薪、时薪与实时收入。" : step === 2 ? "默认有效工时 8 小时，休息时间不计入。" : "这些设置之后仍可随时修改。", 224, 154, "body", theme.muted);
  if (step === 1) { input(shell, "LMM-B-041", "月薪", "10,000 元", 224, 208, 260, theme); choice(shell, "LMM-B-042", "双休", 224, 304, 130, true, theme); choice(shell, "LMM-B-043", "单休", 364, 304, 130, false, theme); choice(shell, "LMM-B-044", "大小周", 504, 304, 130, false, theme); selectControl(shell, "LMM-B-045", "本周类型（大小周时）", "请选择", 224, 384, 260, theme); }
  else if (step === 2) { input(shell, "LMM-B-046", "上班时间", "09:00", 224, 208, 240, theme); input(shell, "LMM-B-047", "休息开始", "12:00", 482, 208, 240, theme); input(shell, "LMM-B-048", "休息时长", "1.5 小时", 224, 304, 240, theme); const calc = frame(shell, "作息推算结果", 482, 328, 240, 68, theme.mintSoft, "", 9); text(calc, "推算结果", 12, 10, "caption", theme.mint); text(calc, "13:30 恢复 · 18:30 下班", 12, 34, "label", theme.ink); }
  else { const card = frame(shell, "首次配置确认摘要", 224, 208, 498, 190, theme.elevated, theme.line, 10); [["月薪", "¥10,000"], ["休息模式", "双休"], ["工作时间", "09:00–18:30"], ["休息", "12:00–13:30"]].forEach((row, index) => { text(card, row[0], 18, 18 + index * 42, "body", theme.muted); text(card, row[1], 260, 18 + index * 42, "label", theme.ink, 210, { align: "RIGHT" }); }); }
  button(shell, "LMM-B-053", "取消", 214, 524, 92, "ghost", theme); if (step > 1) button(shell, "LMM-B-051", "上一步", 556, 524, 92, "ghost", theme); button(shell, step === 3 ? "LMM-B-050" : "LMM-B-052", step === 3 ? "完成" : "下一步", 658, 524, 92, "primary", theme); return shell;
}
function drawSettings(parent, x, y, dark = false) {
  const theme = dark ? DARK : LIGHT; const shell = windowShell(parent, "T-SETTINGS", "设置", x, y, 760, 560, dark); rect(shell, "设置任务导航", 0, 50, 190, 510, theme.subtle, 0);
  const tabs = [["LMM-B-060", "收入与作息"], ["LMM-B-061", "日历"], ["LMM-B-062", "外观"], ["LMM-B-063", "窗口与启动"], ["LMM-B-064", "数据与支持"]]; tabs.forEach((item, index) => button(shell, item[0], item[1], 14, 78 + index * 48, 162, index === 0 ? "primary" : "ghost", theme));
  text(shell, "收入与作息", 220, 78, "title", theme.ink); text(shell, "统一管理工资、休息模式与工作时间。", 220, 114, "body", theme.muted); input(shell, "LMM-B-065", "月薪", "10,000 元", 220, 166, 250, theme); selectControl(shell, "LMM-B-066", "休息模式", "双休", 488, 166, 240, theme); input(shell, "LMM-B-068", "上班时间", "09:00", 220, 258, 240, theme); input(shell, "LMM-B-069", "下班时间", "18:30", 488, 258, 240, theme); input(shell, "LMM-B-070", "休息开始", "12:00", 220, 350, 240, theme); input(shell, "LMM-B-071", "休息结束", "13:30", 488, 350, 240, theme); line(shell, 190, 494, 760, 494, theme.line); button(shell, "LMM-B-082", "恢复默认", 510, 508, 100, "ghost", theme); button(shell, "LMM-B-083", "保存", 622, 508, 106, "primary", theme); return shell;
}
function drawSettingsStates(parent, x, y, dark = false) {
  const theme = dark ? DARK : LIGHT; const card = frame(parent, "设置关键状态", x, y, 760, 560, theme.surface, theme.lineStrong, 14); text(card, "设置关键状态", 24, 24, "title", theme.ink);
  text(card, "外观", 24, 78, "heading", theme.ink); choice(card, "LMM-B-073", "浅色", 24, 118, 150, !dark, theme); choice(card, "LMM-B-074", "深色", 186, 118, 150, dark, theme);
  text(card, "窗口与启动", 24, 202, "heading", theme.ink); toggle(card, "LMM-B-075", "启动时显示", 24, 246, true, theme); toggle(card, "LMM-B-076", "始终置顶", 24, 286, true, theme); toggle(card, "LMM-B-077", "贴边自动隐藏", 24, 326, true, theme); toggle(card, "LMM-B-078", "开机启动", 24, 366, false, theme);
  text(card, "数据与支持", 388, 78, "heading", theme.ink); button(card, "LMM-B-079", "打开数据目录", 388, 118, 140, "secondary", theme); button(card, "LMM-B-080", "复制诊断摘要", 540, 118, 150, "secondary", theme); button(card, "LMM-B-081", "检查更新", 388, 170, 140, "secondary", theme);
  const saved = frame(card, "反馈状态/保存成功", 388, 246, 302, 54, theme.mintSoft, "", 8); text(saved, "✓ 设置已保存并同步到全部窗口", 14, 16, "body", theme.mint); const failed = frame(card, "反馈状态/保存失败", 388, 316, 302, 82, theme.dangerSoft, "", 8); text(failed, "保存失败", 14, 12, "label", theme.danger); text(failed, "输入已保留，旧配置未被污染。", 14, 38, "caption", theme.ink); button(card, "LMM-B-084", "关闭/取消", 570, 488, 120, "ghost", theme); return card;
}
function drawNative(parent, x, y) {
  const panel = target(frame(parent, "Windows 原生能力边界", x, y, 760, 560, DOC.blueSoft, DOC.blue, 12), "WINDOWS-NATIVE-TRAY"); text(panel, "Windows 原生边界", 24, 24, "title", DOC.text); text(panel, "托盘菜单采用系统样式；Web 主题不模拟它。", 24, 62, "body", DOC.muted);
  const menu = frame(panel, "托盘菜单", 24, 108, 268, 310, DOC.surface, DOC.line, 8); text(menu, "LetsMakeMoney", 18, 16, "label", DOC.text); [["LMM-B-090", "显示 / 隐藏迷你视图"], ["LMM-B-091", "今日工作台"], ["LMM-B-092", "设置"], ["LMM-B-093", "重新配置"], ["LMM-B-094", "打开数据目录"], ["LMM-B-095", "退出"]].forEach((row, index) => button(menu, row[0], row[1], 12, 48 + index * 40, 244, index === 5 ? "danger" : "ghost", LIGHT));
  const support = frame(panel, "支持与恢复边界", 316, 108, 420, 394, DOC.surface, DOC.line, 8); text(support, "支持与恢复", 18, 16, "heading", DOC.text); [["更新可用", "LMM-B-096", "打开发布页"], ["更新失败", "LMM-B-097", "重试"], ["配置已恢复", "LMM-B-098", "打开数据目录"], ["反馈提示", "LMM-B-099", "知道了"], ["窗口不可达", "LMM-B-100", "恢复安全位置"]].forEach((row, index) => { const yy = 58 + index * 62; text(support, row[0], 18, yy + 9, "body", DOC.text); button(support, row[1], row[2], 236, yy, 162, "secondary", LIGHT); }); return panel;
}
function logoImage(parent, name, x, y, size, background, radius, stroke = DOC.line) {
  const tile = frame(parent, name, x, y, size, size, background, stroke, radius, true);
  if (brandImage) tile.fills = [{ type: "IMAGE", imageHash: brandImage.hash, scaleMode: "FILL" }];
  return tile;
}
function drawLogoArchive(parent, x, y) {
  const source = brandAssetMetadata && brandAssetMetadata.source ? brandAssetMetadata.source : "apps/windows-v1/src-tauri/icons/icon.png";
  const output = brandAssetMetadata && brandAssetMetadata.output ? brandAssetMetadata.output : "generated-assets/appLogo.png";
  const dimensions = brandAssetMetadata ? `${brandAssetMetadata.width} × ${brandAssetMetadata.height}px` : "512 × 512px";
  const bytes = brandAssetMetadata && brandAssetMetadata.bytes ? `${brandAssetMetadata.bytes} bytes` : "构建时校验";
  const sha = brandAssetMetadata && brandAssetMetadata.sha256 ? brandAssetMetadata.sha256.toUpperCase() : "由构建清单提供";

  const primary = frame(parent, "Logo 留档/主标识", x, y, 1600, 480, DOC.surface, DOC.line, 12);
  text(primary, "L2 · 燕麦石墨", 28, 24, "title", DOC.text); text(primary, "v1.0.8 正式应用标识", 28, 66, "body", DOC.muted);
  logoImage(primary, "L2 primary 320", 48, 116, 320, LIGHT.surface, 72);
  text(primary, "正式主图", 414, 124, "heading", DOC.text); text(primary, "平面圆角方形标识；石墨山峰、金币进度与燕麦底色构成固定识别。不得改变比例、裁切或重绘内部结构。", 414, 164, "body", DOC.muted, 1120);
  pill(primary, "正式资产", 414, 266, "success"); pill(primary, "透明 PNG", 544, 266, "native"); pill(primary, "浅深主题共用", 684, 266, "coin");
  text(primary, `源文件：${source}\n归档输出：${output}`, 414, 326, "caption", DOC.muted, 1120, { line: 24 });

  const sizes = frame(parent, "Logo 留档/尺寸预览", x + 1618, y, 1600, 480, DOC.surface, DOC.line, 12);
  text(sizes, "尺寸与清晰度留档", 28, 24, "title", DOC.text); text(sizes, "按实际像素检查轮廓、间距和小尺寸识别。", 28, 66, "body", DOC.muted);
  const variants = [[256, 40], [128, 340], [64, 520], [32, 632], [16, 712]];
  variants.forEach((item) => { const size = item[0]; const xx = item[1]; logoImage(sizes, `L2 ${size}`, xx, 126 + (256 - size), size, LIGHT.surface, Math.max(4, Math.round(size * .22))); text(sizes, `${size}`, xx, 402, "caption", DOC.muted, size, { align: "CENTER" }); });
  text(sizes, "建议交付：256 / 128 / 64 / 48 / 32 / 24 / 16px\nWindows ICO 由同一 512px 正式源图确定性生成。", 830, 132, "body", DOC.text, 700, { line: 30 });
  text(sizes, "禁止：拉伸、非等比缩放、替换配色、添加外发光、在图标内部叠加文字。", 830, 244, "body", DOC.muted, 700);

  const records = frame(parent, "Logo 留档/主题与资产记录", x + 3236, y, 1740, 480, DOC.surface, DOC.line, 12);
  text(records, "主题预览与资产记录", 28, 24, "title", DOC.text); text(records, "正式 Logo 本体保持一致，仅切换承载表面。", 28, 66, "body", DOC.muted);
  const lightPreview = frame(records, "浅色界面预览", 28, 116, 520, 144, LIGHT.canvas, LIGHT.line, 10); logoImage(lightPreview, "L2 浅色界面标识", 20, 20, 104, LIGHT.surface, 24); text(lightPreview, "浅色界面", 148, 34, "heading", LIGHT.ink); text(lightPreview, "窗口标题、任务栏与文档", 148, 72, "caption", LIGHT.muted);
  const darkPreview = frame(records, "深色界面预览", 570, 116, 520, 144, DARK.canvas, DARK.line, 10); logoImage(darkPreview, "L2 深色界面标识", 20, 20, 104, DARK.surface, 24, DARK.line); text(darkPreview, "深色界面", 148, 34, "heading", DARK.ink); text(darkPreview, "标识不切换为另一套配色", 148, 72, "caption", DARK.muted);
  const meta = frame(records, "Logo 资产元数据", 1112, 116, 600, 304, DOC.soft, DOC.line, 10); text(meta, "资产元数据", 18, 16, "heading", DOC.text); text(meta, `角色：product-brand-mark\n尺寸：${dimensions}\n体积：${bytes}\n运行截图：否`, 18, 56, "body", DOC.text, 560, { line: 29 }); text(meta, `SHA256\n${sha}`, 18, 190, "caption", DOC.muted, 560, { line: 22 });
  return Math.max(primary.height, sizes.height, records.height);
}

function sectionHeight(ids, visualBottom = 820) { return visualBottom + 76 + Math.ceil(ids.length / CONTRACT_COLUMNS) * (CONTRACT_CARD_HEIGHT + CONTRACT_GAP) + 60; }
function buildCover(root, y) {
  const cover = frame(root, "文档封面", 40, y, GRID_WIDTH, 620, LIGHT.surface, LIGHT.line, 16); if (brandImage) { const icon = rect(cover, "L2 应用图标", 80, 74, 128, 128, LIGHT.surface, 28); icon.fills = [{ type: "IMAGE", imageHash: brandImage.hash, scaleMode: "FILL" }]; }
  pill(cover, "WINDOWS · v1.0.8 FINAL", 236, 74, "coin"); text(cover, "LetsMakeMoney", 236, 118, "display", LIGHT.ink); text(cover, "Windows 本地收入进度工具 · Full Product Flow & Development Contract", 236, 170, "heading", LIGHT.muted); text(cover, "当前产品已由 Rust + Tauri 2 + React 19 重建。此页覆盖真实窗口、配置事务、收入日历、加班、隐私贴边、主题、托盘和支持边界。", 80, 250, "body", LIGHT.muted, 3100);
  const facts = [["4 个窗口", "迷你收入视图 / 今日工作台 / 设置 / 首次配置向导"], ["双主题", "浅色默认 / 深色"], ["本地优先", "配置、日志与日历数据留在设备"], ["无宠物", "v0.9 桌宠仅为历史版本"]]; facts.forEach((item, index) => { const card = frame(cover, `产品事实/${item[0]}`, 80 + index * 820, 340, 780, 140, LIGHT.subtle, LIGHT.line, 10); text(card, item[0], 18, 18, "title", LIGHT.ink); text(card, item[1], 18, 64, "body", LIGHT.muted, 744); });
  const status = frame(cover, "文档状态", 3560, 74, 1480, 406, LIGHT.warm, LIGHT.line, 12); text(status, "文档状态", 22, 20, "heading", LIGHT.ink); pill(status, "当前产品事实", 22, 62, "success"); pill(status, "可编辑图层", 176, 62, "native"); text(status, `插件 ${BUILDER_VERSION}\n管理页面：${PAGE_NAME}\n源产品：v1.0.8 / test@b691af7\n画布：5120px · 内边距 24px · 组间距 18px`, 22, 116, "body", LIGHT.muted, 1420, { line: 30 }); text(status, "运行截图：0 · 产品素材：L2 品牌 PNG 1 张", 22, 316, "label", LIGHT.ink); return y + cover.height + 24;
}
function buildOverview(root, y) {
  const area = section(root, 0, "产品关系总览", "从启动、首次配置到日常收入、日历、设置、托盘与退出的真实链路。", y, 620); const cards = [["T-START", "启动", "读取 config v8"], ["T-WIZARD-1", "首次配置", "未配置用户"], ["T-MINI", "迷你收入视图", "日常常驻入口"], ["T-WORKBENCH-TODAY", "今日工作台", "收入与安排"], ["T-WORKBENCH-CALENDAR", "收入日历", "日期与加班"], ["T-SETTINGS", "设置", "本地偏好事务"], ["WINDOWS-NATIVE-TRAY", "原生托盘", "显隐与退出"]]; cards.forEach((item, index) => { flowCard(area, item[0], item[1], item[2], 24 + index * 700, 126, 620, item[0].startsWith("WINDOWS")); if (index < cards.length - 1) connector(area, 644 + index * 700, 158, 74, index === 1 ? "完成" : "打开"); });
  const rules = frame(area, "产品架构边界", 24, 270, 4972, 288, DOC.surface, DOC.line, 10); text(rules, "产品与技术边界", 18, 16, "heading", DOC.text); const columns = [["前端界面层", "React 19 可编辑界面与草稿状态\nLucide 图标 / 自定义时间选择器 / 下拉选择器"], ["Tauri 命令层", "参数与错误映射\n窗口显示事务\n跨 WebView 事件"], ["Rust 服务层", "收入快照 / 日历 / 配置事务\n诊断日志 / 更新评估"], ["本地存储层", "config v8 配置\ndebug.log 诊断日志\n年度日历与加班记录"], ["Windows 原生层", "托盘 / 注册表自启\n窗口置顶与找回\n任务栏策略"]]; columns.forEach((item, index) => { const col = frame(rules, `架构边界/${item[0]}`, 18 + index * 980, 58, 944, 206, index === 4 ? DOC.blueSoft : DOC.soft, index === 4 ? DOC.blue : DOC.line, 8); text(col, item[0], 16, 14, "heading", DOC.text); text(col, item[1], 16, 52, "body", DOC.muted, 912, { line: 28 }); }); return y + area.height + 24;
}
function buildMini(root, y) { const ids = CONTROL_SPECS.filter((s) => s.area === "Mini").map((s) => s.id); const contractY = 450; const height = sectionHeight(ids, contractY); const area = section(root, 1, "迷你收入视图与隐私贴边", "344×108 的日常收入入口；贴边收起后只保留非金额隐私竖条。", y, height); flowCard(area, "T-MINI", "完整迷你收入视图", "工作 / 上班前 / 休息", 24, 112); connector(area, 324, 142, 90, "贴边"); flowCard(area, "T-MINI-PRIVACY", "隐私竖条", "34px 可找回", 414, 112); connector(area, 714, 142, 90, "悬停"); flowCard(area, "T-WORKBENCH-TODAY", "今日工作台", "打开时隐藏迷你收入视图", 804, 112); drawMini(area, 24, 250, false, "working"); drawMini(area, 392, 250, true, "resting"); drawMini(area, 760, 250, false, "rest"); drawMini(area, 1128, 250, true, "error"); drawPrivacyTab(area, 1510, 250, false); drawPrivacyTab(area, 1568, 250, true); inventory(area, ids, 1660, 238, 3336, 408); contractBoard(area, ids, contractY); return y + area.height + 24; }
function buildToday(root, y) { const ids = CONTROL_SPECS.filter((s) => s.area === "今日").map((s) => s.id); const height = sectionHeight(ids, 850); const area = section(root, 2, "今日工作台", "收入、阶段倒计时、三列时间线与月度摘要使用同一权威 DashboardSnapshot。", y, height); flowCard(area, "T-MINI", "Mini", "打开工作台", 24, 112); connector(area, 324, 142, 90, "显隐事务"); flowCard(area, "T-WORKBENCH-TODAY", "今日", "820×620", 414, 112); connector(area, 714, 142, 90, "调整"); flowCard(area, "T-DATE-OVERRIDE", "日期调整", "统一事务", 804, 112); connector(area, 1104, 142, 90, "加班"); flowCard(area, "T-OVERTIME", "加班记录", "动态上限", 1194, 112); drawToday(area, 24, 236, false); drawToday(area, 868, 236, true); inventory(area, ids, 1712, 236, 3284, 620); contractBoard(area, ids, 880); return y + area.height + 24; }
function buildCalendar(root, y) { const ids = CONTROL_SPECS.filter((s) => s.area === "日历").map((s) => s.id); const height = sectionHeight(ids, 1020); const area = section(root, 3, "收入日历、日期调整与加班", "六周月份、复合日期状态、原子调整与分钟精度加班记录。", y, height); flowCard(area, "T-WORKBENCH-CALENDAR", "收入日历", "选择或双击日期", 24, 112); connector(area, 324, 142, 90, "调整"); flowCard(area, "T-DATE-OVERRIDE", "日期调整", "工作/带薪/不带薪", 414, 112); connector(area, 714, 142, 90, "保存"); flowCard(area, "T-OVERTIME", "加班记录", "动态上限与费率快照", 804, 112); drawCalendar(area, 24, 236, false); drawCalendar(area, 868, 236, true); drawDateOverride(area, 1712, 236, false); drawOvertime(area, 2248, 236, false); drawDateOverride(area, 2764, 236, true); drawOvertime(area, 3300, 236, true); inventory(area, ids, 3816, 236, 1180, 748); contractBoard(area, ids, 1030); return y + area.height + 24; }
function buildWizard(root, y) { const ids = CONTROL_SPECS.filter((s) => s.area === "Wizard").map((s) => s.id); const contractY = 1200; const height = sectionHeight(ids, contractY); const area = section(root, 4, "首次配置向导", "三步渐进式输入，所有草稿在完成前不污染已保存配置。", y, height); flowCard(area, "T-WIZARD-1", "收入与休息", "月薪 / 休息模式", 24, 112); connector(area, 324, 142, 90, "下一步"); flowCard(area, "T-WIZARD-2", "工作与休息", "时间 / 小数休息", 414, 112); connector(area, 714, 142, 90, "下一步"); flowCard(area, "T-WIZARD-3", "确认配置", "安全写入 config v8", 804, 112); drawWizard(area, 24, 236, 1, false); drawWizard(area, 828, 236, 2, false); drawWizard(area, 1632, 236, 3, false); drawWizard(area, 2436, 236, 1, true); inventory(area, ids, 3240, 236, 1756, 580); const confirm = frame(area, "首次配置退出确认", 3240, 840, 760, 320, DARK.elevated, DARK.lineStrong, 14); target(confirm, "T-WIZARD-CONFIRM-EXIT"); text(confirm, "退出首次配置？", 24, 28, "title", DARK.ink); text(confirm, "完成配置后才能开始使用。你可以继续编辑，或退出应用。", 24, 72, "body", DARK.muted, 700); button(confirm, "LMM-B-054", "继续编辑", 430, 246, 136, "ghost", DARK); button(confirm, "LMM-B-054", "退出应用", 580, 246, 136, "danger", DARK); contractBoard(area, ids, contractY); return y + area.height + 24; }
function buildSettings(root, y) { const ids = CONTROL_SPECS.filter((s) => s.area === "Settings").map((s) => s.id); const contractY = 820; const height = sectionHeight(ids, contractY); const area = section(root, 5, "设置五类任务", "配置草稿、主题预览、保存/无变化/失败补偿与本地支持入口。", y, height); const flow = [["T-SETTINGS-INCOME", "收入与作息"], ["T-SETTINGS-CALENDAR", "日历"], ["T-SETTINGS-APPEARANCE", "外观"], ["T-SETTINGS-WINDOW", "窗口与启动"], ["T-SETTINGS-SUPPORT", "数据与支持"]]; flow.forEach((item, index) => { flowCard(area, item[0], item[1], "同一设置窗口内切换", 24 + index * 700, 112, 620); if (index < flow.length - 1) connector(area, 644 + index * 700, 142, 74, "页签"); }); drawSettings(area, 24, 236, false); drawSettings(area, 808, 236, true); drawSettingsStates(area, 1592, 236, false); drawSettingsStates(area, 2376, 236, true); inventory(area, ids, 3160, 236, 1836, 1120); contractBoard(area, ids, contractY); return y + area.height + 24; }
function buildSystem(root, y) { const ids = CONTROL_SPECS.filter((s) => s.area === "系统").map((s) => s.id); const height = sectionHeight(ids, 820); const area = section(root, 6, "托盘、支持与窗口生命周期", "原生系统边界、配置恢复、更新评估、窗口找回与跨窗口同步。", y, height); flowCard(area, "WINDOWS-NATIVE-TRAY", "原生托盘", "系统样式", 24, 112, 300, true); connector(area, 324, 142, 90, "找回"); flowCard(area, "T-MINI", "迷你收入视图", "显示/隐藏", 414, 112); connector(area, 714, 142, 90, "打开"); flowCard(area, "T-WORKBENCH-TODAY", "今日工作台", "进入时隐藏迷你收入视图", 804, 112); connector(area, 1104, 142, 90, "关闭"); flowCard(area, "T-WINDOW-LIFECYCLE", "生命周期", "暂停 / 恢复计时器", 1194, 112); drawNative(area, 24, 236); inventory(area, ids, 808, 236, 4188, 560); contractBoard(area, ids, 840); return y + area.height + 24; }
function buildDesign(root, y) { const area = section(root, 7, "Logo 相关素材留档", "集中保留正式 L2「燕麦石墨」Logo、尺寸、主题适配、来源和完整性校验信息。", y, 620); drawLogoArchive(area, 24, 112); return y + area.height + 24; }

async function chooseFonts() {
  const candidates = [
    { family: "Noto Sans SC", regular: "Regular", semibold: "Medium", bold: "Bold" },
    { family: "Microsoft YaHei", regular: "Regular", semibold: "Bold", bold: "Bold" },
    { family: "Microsoft YaHei UI", regular: "Regular", semibold: "Bold", bold: "Bold" },
    { family: "Source Han Sans CN", regular: "Regular", semibold: "Medium", bold: "Bold" },
    { family: "Noto Sans CJK SC", regular: "Regular", semibold: "Medium", bold: "Bold" }
  ];
  for (const item of candidates) { try { await figma.loadFontAsync({ family: item.family, style: item.regular }); await figma.loadFontAsync({ family: item.family, style: item.semibold }); await figma.loadFontAsync({ family: item.family, style: item.bold }); fonts = { regular: { family: item.family, style: item.regular }, semibold: { family: item.family, style: item.semibold }, bold: { family: item.family, style: item.bold } }; return; } catch (_) {} }
  throw new Error("缺少可用中文字体：Noto Sans SC / Microsoft YaHei / Source Han Sans CN");
}
async function resetDesignSystem() {
  const collections = await figma.variables.getLocalVariableCollectionsAsync(); for (const collection of collections) if (collection.name === "LMM v1.0.8" || collection.name.startsWith("LMM v1.0.8 / ")) collection.remove();
  const lightCollection = figma.variables.createVariableCollection("LMM v1.0.8 / 浅色"); lightCollection.renameMode(lightCollection.defaultModeId, "浅色");
  const darkCollection = figma.variables.createVariableCollection("LMM v1.0.8 / 深色"); darkCollection.renameMode(darkCollection.defaultModeId, "深色");
  const tokenPairs = [["颜色/背景/画布", LIGHT.canvas, DARK.canvas], ["颜色/背景/窗口", LIGHT.surface, DARK.surface], ["颜色/背景/浮层", LIGHT.elevated, DARK.elevated], ["颜色/文字/主要", LIGHT.ink, DARK.ink], ["颜色/文字/次要", LIGHT.muted, DARK.muted], ["颜色/边框/默认", LIGHT.line, DARK.line], ["颜色/强调/金币", LIGHT.coin, DARK.coin], ["颜色/状态/成功", LIGHT.mint, DARK.mint], ["颜色/状态/危险", LIGHT.danger, DARK.danger]];
  tokenPairs.forEach((item) => {
    const lightVariable = figma.variables.createVariable(item[0], lightCollection, "COLOR"); lightVariable.setValueForMode(lightCollection.defaultModeId, hex(item[1]));
    const darkVariable = figma.variables.createVariable(item[0], darkCollection, "COLOR"); darkVariable.setValueForMode(darkCollection.defaultModeId, hex(item[2]));
  });
  const textStyles = await figma.getLocalTextStylesAsync(); for (const style of textStyles) if (style.name.startsWith("LMM/")) style.remove();
  const textStyleNames = { display: "展示数字", title: "页面标题", heading: "区块标题", body: "正文", label: "标签", caption: "辅助文字", numeric: "收入数字" };
  for (const [name, spec] of Object.entries(TYPE)) { const style = figma.createTextStyle(); style.name = `LMM/${textStyleNames[name] || "文字"}`; style.fontName = fonts[spec.weight] || fonts.regular; style.fontSize = spec.size; style.lineHeight = { unit: "PIXELS", value: spec.line }; }
  const effects = await figma.getLocalEffectStylesAsync(); for (const style of effects) if (style.name.startsWith("LMM/")) style.remove(); const shadow = figma.createEffectStyle(); shadow.name = "LMM/窗口阴影"; shadow.effects = [{ type: "DROP_SHADOW", color: { ...hex("#000000"), a: .18 }, offset: { x: 0, y: 12 }, radius: 28, spread: -4, visible: true, blendMode: "NORMAL" }];
}
function isOwnedPage(page) { return page.getSharedPluginData(OWNER_NAMESPACE, "owner") === OWNER_NAME || page.getPluginData("lmm-owner") === OWNER_NAME; }
async function prepareSinglePage() {
  await figma.loadAllPagesAsync(); const warnings = []; const targetMatches = figma.root.children.filter((item) => item.name === PAGE_NAME || item.name === "LMM 01 Full Product Flow");
  if (targetMatches.some((item) => !isOwnedPage(item))) throw new Error(`目标页“${PAGE_NAME}”存在但无法确认 LMM 所有权，已停止以保护内容。`);
  let page = targetMatches[0]; if (!page) { const blank = figma.root.children.find((item) => item.type === "PAGE" && item.children.length === 0 && !isOwnedPage(item)); page = blank || figma.createPage(); }
  await figma.setCurrentPageAsync(page); for (const child of [...page.children]) child.remove(); page.name = PAGE_NAME; owned(page, "page/full-product-flow", "page"); page.setPluginData("lmm-owner", OWNER_NAME);
  for (const legacyName of LEGACY_PAGE_NAMES) { const matches = figma.root.children.filter((item) => item.name === legacyName); for (const legacy of matches) { if (legacy === page) continue; await legacy.loadAsync(); if (isOwnedPage(legacy)) legacy.remove(); else warnings.push(`保留未确认归属的旧页：${legacyName}`); } }
  return { page, warnings };
}
function findManagedSection(page, index) {
  return page.findOne((node) => node.type === "FRAME" && node.getSharedPluginData && node.getSharedPluginData(OWNER_NAMESPACE, "role") === `section/${index}`);
}
const MANAGED_LAYER_NAME_ZH = {
  "LMM 01 Full Product Flow / 5120 Grid": "LMM v1.0.8 产品全链路 / 5120 栅格",
  "Document cover": "文档封面",
  "Document status": "文档状态",
  "Architecture boundaries": "产品架构边界",
  "Local control contracts": "本区控件契约",
  "Interaction inventory": "交互控件清单",
  "Mini privacy tab": "迷你收入视图隐私竖条",
  "Settings states": "设置关键状态",
  "Wizard exit confirmation": "首次配置退出确认",
  "Date override modal": "日期调整弹窗",
  "Overtime modal": "加班记录弹窗",
  "overtime-cap": "加班动态上限",
  "Windows native boundaries": "Windows 原生能力边界",
  "Tray menu": "托盘菜单",
  "Support boundaries": "支持与恢复边界",
  "Logo archive / Primary": "Logo 留档/主标识",
  "Logo archive / Sizes": "Logo 留档/尺寸预览",
  "Logo archive / Records": "Logo 留档/主题与资产记录",
  "Light surface preview": "浅色界面预览",
  "Dark surface preview": "深色界面预览",
  "Logo asset metadata": "Logo 资产元数据",
  "L2 app icon": "L2 应用图标",
  "L2 brand mark": "L2 品牌标识",
  "L2 on light": "L2 浅色界面标识",
  "L2 on dark": "L2 深色界面标识",
  "titlebar": "标题栏",
  "side-nav": "侧边导航",
  "thumb": "开关滑块",
  "progress-track": "进度轨道",
  "progress-value": "进度值",
  "divider": "分隔线",
  "income-hero": "今日收入摘要",
  "today-timeline": "今日安排时间线",
  "timeline-node": "时间线节点",
  "monthly-stats": "月度数据摘要",
  "calendar-grid": "收入日历网格",
  "month-summary": "月度总结",
  "wizard-sidebar": "首次配置步骤栏",
  "calculated-schedule": "作息推算结果",
  "wizard-summary": "首次配置确认摘要",
  "settings-sidebar": "设置任务导航",
  "feedback/saved": "反馈状态/保存成功",
  "feedback/failed": "反馈状态/保存失败"
};
const FLOW_TARGET_NAME_ZH = {
  "T-START": "启动",
  "T-WIZARD-1": "首次配置第一步",
  "T-WIZARD-2": "首次配置第二步",
  "T-WIZARD-3": "首次配置确认",
  "T-WIZARD-CONFIRM-EXIT": "首次配置退出确认",
  "T-MINI": "迷你收入视图",
  "T-MINI-PRIVACY": "隐私竖条",
  "T-MINI-ERROR": "迷你收入视图错误状态",
  "T-WORKBENCH-TODAY": "今日工作台",
  "T-WORKBENCH-CALENDAR": "收入日历",
  "T-DATE-OVERRIDE": "日期调整",
  "T-OVERTIME": "加班记录",
  "T-SETTINGS": "设置",
  "T-SETTINGS-INCOME": "设置-收入与作息",
  "T-SETTINGS-CALENDAR": "设置-日历",
  "T-SETTINGS-APPEARANCE": "设置-外观",
  "T-SETTINGS-WINDOW": "设置-窗口与启动",
  "T-SETTINGS-SUPPORT": "设置-数据与支持",
  "WINDOWS-NATIVE-TRAY": "Windows 原生托盘",
  "T-WINDOW-LIFECYCLE": "窗口生命周期"
};
function localizedSectionTitle(value) {
  return value.replace("Mini 与隐私贴边", "迷你收入视图与隐私贴边").replace("首次配置 Wizard", "首次配置向导").replace("Settings 五类任务", "设置五类任务");
}
function localizedManagedLayerName(node) {
  const name = node.name || "";
  if (MANAGED_LAYER_NAME_ZH[name]) return MANAGED_LAYER_NAME_ZH[name];
  if (node.type === "TEXT" && name.startsWith("文本/")) return name.slice("文本/".length) || "空文本";
  if (node.type === "TEXT" && name === "text") {
    const summary = String(node.characters || "").replace(/\s+/g, " ").trim().slice(0, 24) || "空文本";
    return summary;
  }
  const prefixes = [["Button/", "按钮/"], ["Input/", "输入框/"], ["Select/", "下拉选择器/"], ["Toggle/", "开关/"], ["Choice/", "选项/"], ["Inventory/", "控件实例/"], ["Window/", "应用窗口/"], ["Stat/", "数据摘要/"], ["Fact/", "产品事实/"], ["pill/", "状态标签/"], ["step/", "配置步骤/"]];
  for (const [source, targetName] of prefixes) if (name.startsWith(source)) return `${targetName}${name.slice(source.length)}`;
  if (name.startsWith("Boundary/")) {
    const suffix = name.slice("Boundary/".length).replace("Windows 原生", "Windows 原生层").replace("本地存储", "本地存储层").replace("Rust Services", "Rust 服务层").replace("Tauri Commands", "Tauri 命令层").replace("前端", "前端界面层");
    return `架构边界/${suffix}`;
  }
  const sectionMatch = name.match(/^Section\s+(\d+)\s*\/\s*(.+)$/);
  if (sectionMatch) return `${String(sectionMatch[1]).padStart(2, "0")} / ${localizedSectionTitle(sectionMatch[2])}`;
  const localizedSectionMatch = name.match(/^第\s*(\d+)\s*区\s*\/\s*(.+)$/);
  if (localizedSectionMatch) return `${String(localizedSectionMatch[1]).padStart(2, "0")} / ${localizedSectionTitle(localizedSectionMatch[2])}`;
  const contractMatch = name.match(/^Contract\s*\/\s*(LMM-B-\d+)/);
  if (contractMatch) {
    const spec = CONTROL_SPECS.find((item) => item.id === contractMatch[1]);
    return `控件契约/${spec ? spec.label : "交互控件"} / ${contractMatch[1]}`;
  }
  if (name.startsWith("Flow/")) {
    const id = node.getSharedPluginData ? node.getSharedPluginData(OWNER_NAMESPACE, "flow-target") : "";
    return `流程节点/${FLOW_TARGET_NAME_ZH[id] || "产品流程"}`;
  }
  const miniMatch = name.match(/^Mini\/([^/]+)\/(light|dark)$/);
  if (miniMatch) {
    const states = { working: "工作中", before_work: "上班前", rest: "休息中", after_work: "工作结束", loading: "加载中", error: "暂时无法计算" };
    return `迷你收入视图/${states[miniMatch[1]] || miniMatch[1]}/${miniMatch[2] === "dark" ? "深色" : "浅色"}`;
  }
  const dateMatch = name.match(/^Date\/(\d+)$/); if (dateMatch) return `日期/${dateMatch[1]}日`;
  const markerMatch = name.match(/^calendar-marker\/(.+)$/); if (markerMatch) return `日历标记/${markerMatch[1] === "today" ? "今天" : markerMatch[1] === "overtime" ? "加班" : "日期状态"}`;
  return "";
}
function localizeManagedLayerNames(page) {
  let updated = 0;
  const nodes = page.findAll((node) => node.getSharedPluginData && node.getSharedPluginData(OWNER_NAMESPACE, "owner") === OWNER_NAME);
  for (const node of nodes) {
    const nextName = localizedManagedLayerName(node);
    if (nextName && nextName !== node.name) { node.name = nextName; updated += 1; }
  }
  page.setSharedPluginData(OWNER_NAMESPACE, "incremental-layer-language-version", "zh-cn-1");
  return updated;
}
function compactSectionContractGap(page, index) {
  const area = findManagedSection(page, index); if (!area) throw new Error(`未找到受管区块：第 ${String(index).padStart(2, "0")} 区`);
  const board = area.children.find((node) => node.type === "FRAME" && (node.name === "Local control contracts" || node.name === "本区控件契约")); if (!board) throw new Error(`第 ${String(index).padStart(2, "0")} 区缺少受管控件契约区`);
  const visualChildren = area.children.filter((node) => node !== board && node.y < board.y);
  const visualBottom = visualChildren.reduce((value, node) => Math.max(value, node.y + node.height), 88);
  const targetY = Math.ceil(visualBottom + 32); const currentGap = board.y - visualBottom;
  if (currentGap <= 72 || targetY >= board.y) return { moved: false, removedGap: 0, section: area };
  const oldHeight = area.height; board.y = targetY; const newHeight = Math.ceil(board.y + board.height + 40); area.resize(area.width, newHeight);
  const removedGap = oldHeight - newHeight; const root = area.parent;
  if (removedGap > 0 && root && "children" in root) {
    root.children.filter((node) => node !== area && node.type === "FRAME" && node.getSharedPluginData && node.getSharedPluginData(OWNER_NAMESPACE, "role").startsWith("section/") && node.y > area.y).forEach((node) => { node.y -= removedGap; });
    const contentBottom = root.children.reduce((value, node) => Math.max(value, node.y + node.height), 0); root.resize(root.width, contentBottom + 40);
  }
  return { moved: true, removedGap: Math.max(0, removedGap), section: area };
}
function rebuildLogoArchiveSection(page) {
  const area = findManagedSection(page, 7); if (!area) throw new Error("未找到受管区块：第 07 区");
  for (const child of [...area.children]) child.remove();
  area.name = "07 / Logo 相关素材留档"; area.resize(GRID_WIDTH, 620); owned(area, "section/7", "section");
  text(area, "07  Logo 相关素材留档", 24, 18, "title", DOC.text); text(area, "集中保留正式 L2「燕麦石墨」Logo、尺寸、主题适配、来源和完整性校验信息。", 24, 54, "body", DOC.muted, 5000); line(area, 24, 86, GRID_WIDTH - 24, 86, DOC.line); drawLogoArchive(area, 24, 112);
  const root = area.parent; if (root && "children" in root) { const contentBottom = root.children.reduce((value, node) => Math.max(value, node.y + node.height), 0); root.resize(root.width, contentBottom + 40); }
  return area;
}
async function improveExistingContracts(assetPayload) {
  setBuildStage("01 字体加载", "加载字体…"); await chooseFonts();
  setBuildStage("02 现有画布保护", "验证受管页面所有权；保留手动布局和文字…"); await figma.loadAllPagesAsync();
  const page = figma.root.children.find((item) => item.name === PAGE_NAME || item.name === "LMM 01 Full Product Flow");
  if (!page) throw new Error(`未找到受管页面“${PAGE_NAME}”，请先完整生成一次。`);
  if (!isOwnedPage(page)) throw new Error(`页面“${PAGE_NAME}”无法确认 LMM 所有权，已停止以保护内容。`);
  page.name = PAGE_NAME;
  await figma.setCurrentPageAsync(page); await page.loadAsync();
  setBuildStage("03 品牌素材校验", "校验 L2 Logo，并准备受管 Logo 留档区…"); brandAssetMetadata = assetPayload && assetPayload.appLogo ? assetPayload.appLogo : null; brandImage = await createVerifiedImage(brandAssetMetadata, "L2 app logo");
  const cards = page.findAll((node) => node.type === "FRAME" && node.getSharedPluginData && node.getSharedPluginData(OWNER_NAMESPACE, "control-contract-ids") && (node.name.startsWith("Contract / ") || node.name.startsWith("控件契约/")));
  let updatedCards = 0; let updatedFields = 0; let preservedManualFields = 0;
  for (const card of cards) {
    const id = card.getSharedPluginData(OWNER_NAMESPACE, "control-contract-ids");
    const spec = CONTROL_SPECS.find((item) => item.id === id); if (!spec) continue;
    let previousSpec = spec;
    try { const stored = card.getSharedPluginData(OWNER_NAMESPACE, "control-contract"); if (stored) previousSpec = JSON.parse(stored); } catch (_) { previousSpec = spec; }
    const oldRows = contractRows(previousSpec, false); const newRows = contractRows(spec, true); const textNodes = card.children.filter((node) => node.type === "TEXT");
    const titleNode = textNodes.find((node) => Math.abs(node.y - 18) <= 10 && node.x < 32);
    if (titleNode) {
      if (titleNode.characters === previousSpec.label) { if (titleNode.characters !== spec.label) { titleNode.characters = spec.label; updatedFields += 1; } }
      else if (titleNode.characters !== spec.label) preservedManualFields += 1;
    }
    for (let index = 0; index < oldRows.length; index += 1) {
      const expectedY = 64 + index * 29; const [oldLabel, oldValue] = oldRows[index]; const [newLabel, newValue] = newRows[index];
      const labelNode = textNodes.find((node) => Math.abs(node.y - expectedY) <= 10 && node.x < 124);
      const valueNode = textNodes.find((node) => Math.abs(node.y - expectedY) <= 10 && node.x >= 124);
      if (labelNode) {
        if (labelNode.characters === oldLabel) { if (oldLabel !== newLabel) { labelNode.characters = newLabel; updatedFields += 1; } }
        else if (labelNode.characters !== newLabel) preservedManualFields += 1;
      }
      if (valueNode) {
        if (valueNode.characters === oldValue) { if (oldValue !== newValue) { valueNode.characters = newValue; updatedFields += 1; } }
        else if (valueNode.characters !== newValue) preservedManualFields += 1;
      }
    }
    card.setSharedPluginData(OWNER_NAMESPACE, "control-contract", JSON.stringify(spec));
    card.setSharedPluginData(OWNER_NAMESPACE, "control-contract-localized", JSON.stringify(newRows));
    card.setSharedPluginData(OWNER_NAMESPACE, "contract-localization-version", "zh-cn-business-first-1"); updatedCards += 1;
  }
  if (!updatedCards) throw new Error("未找到可安全增量更新的 LMM 控件契约卡。现有画布未被修改。");
  setBuildStage("04 布局、中文菜单与 Logo 留档", "保留手动修改，压缩异常空白并中文化受管图层菜单…"); const wizardLayout = compactSectionContractGap(page, 4); const logoSection = rebuildLogoArchiveSection(page); const localizedLayerNames = localizeManagedLayerNames(page);
  page.setSharedPluginData(OWNER_NAMESPACE, "contract-localization-version", "zh-cn-business-first-1");
  page.setSharedPluginData(OWNER_NAMESPACE, "incremental-layout-version", "wizard-gap-logo-archive-1"); figma.currentPage.selection = []; figma.viewport.scrollAndZoomIntoView([wizardLayout.section, logoSection]);
  return { updatedCards, updatedFields, preservedManualFields, localizedLayerNames, wizardGapRemoved: wizardLayout.removedGap, logoSectionUpdated: true };
}
function base64Bytes(value) { const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"; const clean = value.replace(/=+$/, ""); const bytes = []; let buffer = 0; let bits = 0; for (const char of clean) { const index = chars.indexOf(char); if (index < 0) continue; buffer = (buffer << 6) | index; bits += 6; if (bits >= 8) { bits -= 8; bytes.push((buffer >> bits) & 255); } } return new Uint8Array(bytes); }
async function createVerifiedImage(metadata, label) { if (!metadata || !metadata.base64 || !metadata.sha256 || !metadata.width || !metadata.height || !metadata.bytes) throw new Error(`${label} 素材元数据不完整`); if (metadata.buildVerifiedSha256 !== metadata.sha256) throw new Error(`${label} 缺少构建时完整性证明`); const bytes = base64Bytes(metadata.base64); if (bytes.length !== metadata.bytes) throw new Error(`${label} 字节数不一致`); const signature = [137, 80, 78, 71, 13, 10, 26, 10]; if (!signature.every((value, index) => bytes[index] === value)) throw new Error(`${label} 不是有效 PNG`); return figma.createImage(bytes); }
function validateGeneratedLayout(root) {
  const ids = CONTROL_SPECS.map((item) => item.id); if (new Set(ids).size !== ids.length) throw new Error("控件契约 ID 重复"); if (ids.length < 80) throw new Error("控件契约覆盖不足");
  const pageContracts = root.findAll((node) => node.getSharedPluginData && node.getSharedPluginData(OWNER_NAMESPACE, "control-contract-ids")); const found = new Set(); pageContracts.forEach((node) => node.getSharedPluginData(OWNER_NAMESPACE, "control-contract-ids").split(",").forEach((id) => { if (id) found.add(id); })); for (const id of ids) if (!found.has(id)) throw new Error(`控件缺少可编辑实例：${id}`);
  const sections = root.children.filter((node) => node.type === "FRAME" && node.getSharedPluginData && node.getSharedPluginData(OWNER_NAMESPACE, "role").startsWith("section/")); for (let index = 1; index < sections.length; index += 1) if (sections[index].y < sections[index - 1].y + sections[index - 1].height) throw new Error(`顶层区域重叠：${sections[index - 1].name} / ${sections[index].name}`);
  root.setSharedPluginData(OWNER_NAMESPACE, "layout-validation", `sections:${sections.length};contracts:${ids.length};overlaps:0`);
}
let currentBuildStage = "等待开始";
function setBuildStage(stage, text) { currentBuildStage = stage; figma.ui.postMessage({ type: "status", text: text || stage }); }
async function buildAll(assetPayload) {
  setBuildStage("01 字体加载", "加载字体…"); await chooseFonts();
  setBuildStage("02 页面所有权", "验证页面所有权并准备唯一受管页面…"); const prepared = await prepareSinglePage();
  setBuildStage("03 设计系统", "重建设计变量和样式…"); await resetDesignSystem();
  setBuildStage("04 品牌素材", "验证并写入 L2 品牌素材…"); brandAssetMetadata = assetPayload.appLogo; brandImage = await createVerifiedImage(brandAssetMetadata, "L2 app logo");
  setBuildStage("05 可编辑画布", "生成当前产品全链路可编辑画布…");
  setBuildStage("05.01 根画布", "生成根画布…");
  const root = owned(frame(prepared.page, "LMM v1.0.8 产品全链路 / 5120 栅格", 0, 0, DOCUMENT_WIDTH, 1000, DOC.canvas, "", 0), "root/full-product-flow", "structure");
  let y = 40;
  setBuildStage("05.02 文档封面", "生成文档封面…"); y = buildCover(root, y);
  setBuildStage("05.03 产品总览", "生成产品总览…"); y = buildOverview(root, y);
  setBuildStage("05.04 Mini", "生成 Mini 视图…"); y = buildMini(root, y);
  setBuildStage("05.05 今日工作台", "生成今日工作台…"); y = buildToday(root, y);
  setBuildStage("05.06 日历", "生成收入日历…"); y = buildCalendar(root, y);
  setBuildStage("05.07 Wizard", "生成首次配置…"); y = buildWizard(root, y);
  setBuildStage("05.08 Settings", "生成设置界面…"); y = buildSettings(root, y);
  setBuildStage("05.09 系统边界", "生成系统边界与反馈状态…"); y = buildSystem(root, y);
  setBuildStage("05.10 Logo 素材留档", "生成正式 Logo 素材留档…"); y = buildDesign(root, y);
  root.resize(DOCUMENT_WIDTH, y + 40); root.setSharedPluginData(OWNER_NAMESPACE, "control-contract-ids", CONTROL_SPECS.map((item) => item.id).join(",")); root.setSharedPluginData(OWNER_NAMESPACE, "control-contract", JSON.stringify(CONTROL_SPECS)); root.setSharedPluginData(OWNER_NAMESPACE, "managed-page-count", "1"); root.setSharedPluginData(OWNER_NAMESPACE, "product-version", "v1.0.8"); validateGeneratedLayout(root);
  setBuildStage("06 布局验收", "校验布局、契约和页面定位…"); await figma.setCurrentPageAsync(prepared.page); figma.currentPage.selection = []; figma.viewport.scrollAndZoomIntoView([root]); return { pageCount: 1, contractCount: CONTROL_SPECS.length, warnings: prepared.warnings };
}

figma.showUI(__html__, { width: 430, height: 440, themeColors: true });
figma.ui.onmessage = async (message) => {
  if (!message || (message.type !== "build" && message.type !== "improve-contracts")) return;
  try {
    if (message.type === "improve-contracts") {
      const result = await improveExistingContracts(message.assets); figma.ui.postMessage({ type: "done", mode: "improve-contracts", text: `增量优化完成：检查 ${result.updatedCards} 张契约卡，更新 ${result.updatedFields} 个旧生成字段，中文化 ${result.localizedLayerNames} 个受管图层菜单，保留 ${result.preservedManualFields} 处手动修改；首次配置区压缩 ${result.wizardGapRemoved}px，第 07 区已更新为 Logo 素材留档。其他区块未重建。` }); figma.notify("现有画布已在保留手动修改的前提下完成增量优化", { timeout: 4000 }); return;
    }
    const result = await buildAll(message.assets); const warningText = result.warnings.length ? `；${result.warnings.join("；")}` : ""; figma.ui.postMessage({ type: "done", mode: "build", text: `完成：${result.pageCount} 个 LMM 管理页，${result.contractCount} 个 v1.0.8 控件契约${warningText}` }); figma.notify("LetsMakeMoney v1.0.8 单页全链路已更新", { timeout: 3500 });
  }
  catch (error) { const detail = error && error.stack ? error.stack : String(error); const compactDetail = detail.split("\n").slice(0, 4).join("\n"); console.error(`[${currentBuildStage}] ${detail}`); figma.ui.postMessage({ type: "error", text: `生成失败（${currentBuildStage}）：${error.message || String(error)}\n${compactDetail}` }); }
};
