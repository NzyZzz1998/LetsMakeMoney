const PAGE_NAME = "LMM 01 Full Product Flow";
const LEGACY_PAGE_NAMES = [
  "00 Foundations & Components",
  "01 Windows v0.9 Product UI",
  "02 Animation Contract"
];
const OWNER_NAMESPACE = "lmm";
const OWNER_NAME = "LetsMakeMoney";
const BUILDER_VERSION = "v0.9-quickrec-aligned-5";
const GRID_WIDTH = 5120;
const DOCUMENT_WIDTH = 5200;
const SECTION_PADDING = 24;
const GROUP_GAP = 18;
const CONTRACT_COLUMNS = 5;
const CONTRACT_CARD_HEIGHT = 420;
const CONTRACT_ROW_GAP = 16;
const CONTRACT_BOARD_TOP = 74;
const CONTRACT_BOARD_BOTTOM = 18;

const COLORS = {
  canvas: "#E8E7E1", canvasDeep: "#DDE2DA", paper: "#FFFDFA", warm: "#FBF5E9",
  warmStrong: "#F3E5CA", ink: "#302B26", muted: "#76695D", subtle: "#9B8F84",
  line: "#DED7D0", lineStrong: "#C9BDB2", coin: "#F2B43A", coinStrong: "#DF951E",
  coinSoft: "#FCE8B3", orange: "#E97832", mint: "#709B74", mintSoft: "#DFEADC",
  sageDeep: "#56765B", cool: "#F1F4EF", danger: "#A94F43", dangerSoft: "#F7E7E3",
  white: "#FFFFFF", native: "#DDE9F5", nativeInk: "#466987"
};

const DOC = {
  canvas: "#F1F1ED", surface: "#FFFFFF", soft: "#F7F9FC", line: "#D7D7D2",
  text: "#202020", muted: "#626262", blue: "#2563EB", blueSoft: "#E8F0FE",
  purple: "#5B5FC7", purpleSoft: "#EFEFFD", green: "#107C41", greenSoft: "#E7F5EC",
  amber: "#9A6A00", amberSoft: "#FFF4CE"
};

const TYPE = {
  display: { size: 36, line: 44, weight: "bold" }, title: { size: 24, line: 32, weight: "bold" },
  heading: { size: 18, line: 26, weight: "semibold" }, body: { size: 14, line: 22, weight: "regular" },
  label: { size: 13, line: 18, weight: "semibold" }, caption: { size: 12, line: 18, weight: "regular" },
  numeric: { size: 34, line: 40, weight: "bold" }
};

const PRD_REFERENCE_SIZES = {
  panelCollapsed: [236, 64], panelExpanded: [304, 224], today: [500, 700],
  settings: [720, 540], wizard: [760, 560], menu: [240, 34]
};

const RUNTIME_BASELINES = {
  main: [900, 500], panelCollapsed: [300, 124], panelExpanded: [344, 232],
  today: [480, 620], settings: [700, 520], wizard: [720, 520], menu: [232, 34],
  about: [420, 280]
};

const DPI_SCALE_MATRIX = [
  { scale: "100%", factor: 1, status: "已实测" },
  { scale: "125%", factor: 1.25, status: "待真实 Windows 验证" },
  { scale: "150%", factor: 1.5, status: "待真实 Windows 验证" }
];

const ACTUAL_IMPLEMENTATION = {
  mainWindow: "900×500（Debug 逻辑窗口；透明发布窗口由宠物与 Panel 边界动态扩展）",
  panelScene: "折叠 300×124；展开 344×232（100% DPI 实测）",
  todayScene: "480×620（配置默认 480×600，运行时最小高度钳制为 620）",
  settingsWindow: "700×520（100% DPI 实测；内容边距 28，操作栏 57）",
  wizardWindow: "720×520（100% DPI 实测；侧栏 188，操作栏 57）",
  menu: "桌宠菜单最小宽 232、行高 34；Popup 可见宽受 Windows/Godot 主题影响",
  about: "420×280 内容合同；Debug 父窗内嵌时可能受标题栏和父窗口裁切",
  tray: "Windows 原生托盘菜单由系统主题决定，Computer Use 未覆盖通知区真实鼠标路径",
  dpi: "100% 已实测；125% / 150% 仅展示逻辑缩放矩阵，等待真实 Windows 复核"
};

let fonts;
let variables = {};
let images = {};

function contract(id, area, screen, condition, operation, signal, caller, method, persistence, transition, success, failure, cancel, target, status = "") {
  return { id, area, screen, condition, operation, signal, caller, method, persistence, transition, success, failure, cancel, target, status };
}

const CONTROL_SPECS = [
  contract("LMM-B-001", "桌面伴件", "桌宠透明窗口 / working", "桌宠可见且命中可见像素", "单击桌宠", "Pet input arbitration", "Pet / PetManager", "request_context_action", "运行态，不持久化", "working → working_ack → working", "动作完整播放并恢复", "动作缺失时回退基础动作", "双击已移除；拖拽不触发单击", "T-PET-WORKING"),
  contract("LMM-B-002", "桌面伴件", "桌宠透明窗口 / awake_rest", "非工作且非睡眠时段", "单击桌宠", "Pet input arbitration", "Pet / PetManager", "request_context_action", "运行态，不持久化", "awake_rest → rest_ack → awake_rest", "动作完整播放并恢复", "缺失时回退 awake_rest", "拖拽优先", "T-PET-AWAKE"),
  contract("LMM-B-003", "桌面伴件", "桌宠透明窗口 / sleeping", "23:00–07:30 且不覆盖用户工作时段", "单击桌宠", "Pet input arbitration", "Pet / PetManager", "request_context_action", "运行态，不持久化", "sleeping → sleep_ack → sleeping", "轻量反馈后恢复睡眠", "缺失时保持 sleeping", "拖拽优先", "T-PET-SLEEPING"),
  contract("LMM-B-004", "桌面伴件", "Panel 折叠", "Panel 可见", "单击收入卡", "Panel.details_requested", "Panel", "_on_gui_input", "panel_items / 窗口位置", "打开今日详情", "显示 TodayDetailWindow", "窗口创建失败写日志", "无", "T-TODAY"),
  contract("LMM-B-005", "桌面伴件", "Panel 展开", "Panel 展开", "单击详情区域", "Panel.details_requested", "Panel", "_on_gui_input", "panel_items", "打开今日详情", "显示 TodayDetailWindow", "失败保持 Panel 可用", "无", "T-TODAY"),
  contract("LMM-B-006", "桌面伴件", "Panel 屏幕边缘", "Panel 邻近屏幕边缘", "拖动 Panel", "Panel.layout_changed", "Panel / Main", "_on_gui_input / _on_panel_layout_changed", "window_x / window_y", "吸附并重新计算点击区", "位置保存", "越界时安全回落", "释放鼠标结束拖动", "T-PANEL-EDGE"),
  contract("LMM-B-007", "桌面伴件", "桌宠透明窗口", "长按进入拖拽", "长按并向左右拖动", "Pet input arbitration", "Pet / Main", "run_prepare → drag → run_stop", "window_x / window_y", "按方向翻转并移动窗口", "释放后停止并恢复基础状态", "超时触发 run_stop", "Esc/释放停止", "T-PET-DRAG"),

  contract("LMM-B-010", "今日详情", "今日详情", "窗口已打开", "关闭", "Button.pressed", "TodayDetailWindow", "_close_window", "today_window_*", "窗口关闭", "返回桌宠与 Panel", "关闭失败写日志", "关闭即取消", "T-DESKTOP"),
  contract("LMM-B-011", "今日详情", "今日详情", "今日安排可见", "调整今天", "Button.pressed", "TodayDetailWindow", "_open_schedule_settings", "date_overrides / 作息配置", "打开 Settings 作息页", "进入作息编辑", "Settings 不可用时保持本窗", "无", "T-SETTINGS-SCHEDULE"),

  contract("LMM-B-020", "首次配置", "Wizard 全步骤", "Wizard 已打开", "关闭 ×", "Button.pressed", "WizardDialog", "_on_cancel", "恢复进入前配置和宠物", "关闭并回滚草稿", "回到桌宠", "回滚异常记录日志", "等同取消", "T-DESKTOP"),
  contract("LMM-B-021", "首次配置", "步骤 1 / 收入与休息", "步骤 1", "输入月薪", "LineEdit.text_changed", "WizardDialog", "_on_salary_text_changed", "monthly_salary（完成时保存）", "更新草稿和预计工作日", "显示有效月薪", "非法输入显示错误", "取消不保存", "T-WIZARD-1"),
  contract("LMM-B-022", "首次配置", "步骤 1 / 收入与休息", "步骤 1", "选择单休/双休/大小周", "OptionButton.item_selected", "WizardDialog", "_on_rest_mode_selected", "rest_mode（完成时保存）", "更新工作日推算", "预计工作日更新", "无有效项时阻止下一步", "取消不保存", "T-WIZARD-1"),
  contract("LMM-B-023", "首次配置", "步骤 1 / 收入与休息", "休息模式=大小周", "选择本周大周/小周", "OptionButton.item_selected", "WizardDialog", "_on_alternating_week_selected", "alternating_week_*（完成时保存）", "更新大小周基准", "工作日推算稳定", "缺少基准日期时提示", "取消不保存", "T-WIZARD-1"),
  contract("LMM-B-024", "首次配置", "步骤 1", "输入有效", "下一步", "Button.pressed", "WizardDialog", "_on_next", "Wizard 草稿", "步骤 1 → 2", "记录 wizard_step_changed", "校验失败停留当前页", "无", "T-WIZARD-2"),
  contract("LMM-B-025", "首次配置", "步骤 2 / 上班时间", "步骤 2", "选择上班时间", "Time control.changed", "WizardDialog", "_on_work_start_changed", "work_start_*（完成时保存）", "推算午休和下班时间", "显示自动推算", "无效时间阻止下一步", "取消不保存", "T-WIZARD-2"),
  contract("LMM-B-026", "首次配置", "步骤 2", "步骤 2", "上一步", "Button.pressed", "WizardDialog", "_on_previous", "Wizard 草稿", "步骤 2 → 1", "保留草稿", "无", "无", "T-WIZARD-1"),
  contract("LMM-B-027", "首次配置", "步骤 2", "输入有效", "下一步", "Button.pressed", "WizardDialog", "_on_next", "Wizard 草稿", "步骤 2 → 3", "记录步骤日志", "校验失败停留", "无", "T-WIZARD-3"),
  contract("LMM-B-028", "首次配置", "步骤 3 / 午休", "步骤 3", "选择午休开始", "Time control.changed", "WizardDialog", "_on_lunch_start_changed", "lunch_start_*（完成时保存）", "保持午休总时长并推算结束", "午休区间更新", "越界提示", "取消不保存", "T-WIZARD-3"),
  contract("LMM-B-029", "首次配置", "步骤 3 / 午休", "步骤 3", "选择午休时长", "Duration control.changed", "WizardDialog", "_on_lunch_duration_changed", "lunch_duration_minutes（完成时保存）", "推算午休结束与下班", "有效工时维持 8 小时", "时长无效时提示", "取消不保存", "T-WIZARD-3"),
  contract("LMM-B-030", "首次配置", "步骤 3", "步骤 3", "上一步", "Button.pressed", "WizardDialog", "_on_previous", "Wizard 草稿", "步骤 3 → 2", "保留草稿", "无", "无", "T-WIZARD-2"),
  contract("LMM-B-031", "首次配置", "步骤 3", "输入有效", "下一步", "Button.pressed", "WizardDialog", "_on_next", "Wizard 草稿", "步骤 3 → 4", "展示确认摘要", "校验失败停留", "无", "T-WIZARD-4"),
  contract("LMM-B-032", "首次配置", "步骤 4 / 确认", "步骤 4", "选择宠物", "OptionButton.item_selected", "WizardDialog", "_on_pet_selected", "pet_id（完成时保存）", "更新预览宠物", "预览成功", "资源不可用显示回退", "取消恢复进入前宠物", "T-WIZARD-4"),
  contract("LMM-B-033", "首次配置", "步骤 4", "步骤 4", "完成配置", "Button.pressed", "WizardDialog", "_on_finish", "Config 安全写入", "保存 → 应用运行态 → 关闭", "wizard_completed", "保存失败保留草稿并提示", "失败后可继续编辑", "T-DESKTOP"),
  contract("LMM-B-034", "首次配置", "Wizard 全步骤", "Wizard 已打开", "取消", "Button.pressed", "WizardDialog", "_on_cancel", "恢复进入前配置和宠物", "关闭并回滚", "无半成品配置", "回滚失败记录日志", "显式取消", "T-DESKTOP"),

  contract("LMM-B-040", "偏好设置", "Settings", "窗口已打开", "关闭 ×", "Button.pressed", "SettingsDialog", "_on_cancel", "不写配置", "关闭并丢弃草稿", "返回桌宠", "无", "等同取消", "T-DESKTOP"),
  contract("LMM-B-041", "偏好设置", "Settings / 工资", "Settings 已打开", "切换工资页", "Button.pressed", "SettingsDialog", "_show_section", "不持久化", "显示工资 section", "页签高亮", "无", "无", "T-SETTINGS-SALARY"),
  contract("LMM-B-042", "偏好设置", "Settings / 作息", "Settings 已打开", "切换作息页", "Button.pressed", "SettingsDialog", "_show_section", "不持久化", "显示作息 section", "页签高亮", "无", "无", "T-SETTINGS-SCHEDULE"),
  contract("LMM-B-043", "偏好设置", "Settings / 桌宠", "Settings 已打开", "切换桌宠页", "Button.pressed", "SettingsDialog", "_show_section", "不持久化", "显示桌宠 section", "页签高亮", "无", "无", "T-SETTINGS-PET"),
  contract("LMM-B-044", "偏好设置", "Settings / 显示", "Settings 已打开", "切换显示页", "Button.pressed", "SettingsDialog", "_show_section", "不持久化", "显示显示 section", "页签高亮", "无", "无", "T-SETTINGS-DISPLAY"),
  contract("LMM-B-045", "偏好设置", "Settings / 通用", "Settings 已打开", "切换通用页", "Button.pressed", "SettingsDialog", "_show_section", "不持久化", "显示通用 section", "页签高亮", "无", "无", "T-SETTINGS-GENERAL"),
  contract("LMM-B-046", "偏好设置", "工资", "工资页", "编辑月薪", "LineEdit.text_changed", "SettingsDialog", "_on_salary_changed", "monthly_salary（保存时）", "标记 dirty", "草稿更新", "非法金额显示错误", "取消丢弃", "T-SETTINGS-SALARY"),
  contract("LMM-B-047", "偏好设置", "工资", "工资页", "选择休息模式", "OptionButton.item_selected", "SettingsDialog", "_on_rest_mode_selected", "rest_mode（保存时）", "更新预计工作日", "草稿更新", "无有效项时提示", "取消丢弃", "T-SETTINGS-SALARY"),
  contract("LMM-B-048", "偏好设置", "工资", "rest_mode=alternating", "选择本周类型", "OptionButton.item_selected", "SettingsDialog", "_on_alternating_week_selected", "alternating_week_*", "重算日历", "显示大周/小周", "基准无效时提示", "取消丢弃", "T-SETTINGS-SALARY"),
  contract("LMM-B-049", "偏好设置", "作息", "作息页", "修改上班时间", "Time control.changed", "SettingsDialog", "_on_work_start_changed", "work_start_*", "推算午休/下班", "有效工时更新", "越界提示", "取消丢弃", "T-SETTINGS-SCHEDULE"),
  contract("LMM-B-050", "偏好设置", "作息", "作息页", "修改午休开始", "Time control.changed", "SettingsDialog", "_on_lunch_start_changed", "lunch_start_*", "保持时长并推算结束", "午休区间更新", "越界提示", "取消丢弃", "T-SETTINGS-SCHEDULE"),
  contract("LMM-B-051", "偏好设置", "作息", "作息页", "修改午休时长", "Duration control.changed", "SettingsDialog", "_on_lunch_duration_changed", "lunch_duration_minutes", "推算午休结束和下班", "每日有效工时更新", "无效时提示", "取消丢弃", "T-SETTINGS-SCHEDULE"),
  contract("LMM-B-052", "偏好设置", "桌宠", "桌宠页", "选择宠物", "OptionButton.item_selected", "SettingsDialog", "_on_pet_selected", "pet_id", "影子预览，不立即强制覆盖", "保存后切换", "资源不可用回退", "取消恢复当前宠物", "T-SETTINGS-PET"),
  contract("LMM-B-053", "偏好设置", "桌宠", "桌宠页", "回滚默认宠物", "Button.pressed", "SettingsDialog", "_on_rollback_pet", "pet_id / pet_package_*", "请求恢复 v0.8 默认宠物", "回退成功", "失败显示原因", "确认框取消不变", "T-SETTINGS-PET"),
  contract("LMM-B-054", "偏好设置", "显示", "显示页", "调整透明度", "HSlider.value_changed", "SettingsDialog", "_on_opacity_changed", "window_opacity", "预览透明度", "保存后持久化", "native 不可用仍保留配置", "取消恢复", "T-SETTINGS-DISPLAY"),
  contract("LMM-B-055", "偏好设置", "显示", "显示页", "调整缩放", "HSlider.value_changed", "SettingsDialog", "_on_scale_changed", "window_scale", "预览桌宠缩放", "保存后持久化", "越界钳制", "取消恢复", "T-SETTINGS-DISPLAY"),
  contract("LMM-B-056", "偏好设置", "显示", "显示页", "选择窗口模式", "OptionButton.item_selected", "SettingsDialog", "_on_window_mode_selected", "window_mode", "top/embed 策略重应用", "窗口策略生效", "native 不可用降级置顶", "取消恢复", "T-SETTINGS-DISPLAY"),
  contract("LMM-B-057", "偏好设置", "显示", "托盘与 native 能力可用", "切换纯桌宠", "CheckButton.toggled", "SettingsDialog", "_on_pure_pet_toggled", "pure_pet_mode", "保存后重应用任务栏策略", "仅桌宠、无任务栏入口", "能力不足时禁用并说明", "取消恢复", "T-SETTINGS-DISPLAY"),
  contract("LMM-B-058", "偏好设置", "通用", "通用页", "切换 Debug", "CheckButton.toggled", "SettingsDialog", "_on_debug_toggled", "debug_mode", "保存后调整窗口策略", "调试日志启用", "无", "取消恢复", "T-SETTINGS-GENERAL"),
  contract("LMM-B-059", "偏好设置", "通用", "Windows 注册表能力可用", "切换开机自启", "CheckButton.toggled", "SettingsDialog / WindowsPlatform", "set_auto_start", "HKCU\\...\\Run", "事务保存后写注册表", "注册表与 Config 一致", "失败回滚 Config/注册表并提示", "取消恢复", "T-SETTINGS-GENERAL"),
  contract("LMM-B-060", "偏好设置", "通用", "通用页", "切换关闭到托盘", "CheckButton.toggled", "SettingsDialog", "_on_close_to_tray_toggled", "minimize_to_tray", "更新关闭语义", "关闭时隐藏", "托盘不可用时提示", "取消恢复", "T-SETTINGS-GENERAL"),
  contract("LMM-B-061", "偏好设置", "通用", "通用页", "重置窗口位置", "Button.pressed", "SettingsDialog / DragResizeSystem", "reset_window_position", "window_x / window_y", "窗口回到安全位置", "可找回窗口", "失败记录日志", "确认框取消不变", "T-SETTINGS-GENERAL"),
  contract("LMM-B-062", "偏好设置", "通用", "通用页", "恢复默认显示", "Button.pressed", "SettingsDialog", "_on_restore_display_defaults", "display 相关配置", "恢复默认并标记 dirty", "保存后应用", "失败保留旧配置", "确认框取消不变", "T-SETTINGS-GENERAL"),
  contract("LMM-B-063", "偏好设置", "诊断与支持", "通用页", "打开数据目录", "Button.pressed", "DiagnosticsService", "open_app_data_directory", "无", "调用 OS.shell_open", "打开 %APPDATA%\\LetsMakeMoney", "失败显示可读错误", "无", "WINDOWS-NATIVE-DATA"),
  contract("LMM-B-064", "偏好设置", "诊断与支持", "通用页", "复制诊断摘要", "Button.pressed", "DiagnosticsService", "copy_summary_to_clipboard", "剪贴板", "复制脱敏摘要", "显示复制成功", "写入失败显示原因；读回不确定不误报", "无", "WINDOWS-NATIVE-CLIPBOARD"),
  contract("LMM-B-065", "偏好设置", "更新", "通用页", "选择更新通道", "OptionButton.item_selected", "SettingsDialog", "_on_update_channel_selected", "update_channel", "更新检查策略变化", "保存后生效", "非法通道回退 stable", "取消恢复", "T-UPDATE"),
  contract("LMM-B-066", "偏好设置", "更新", "通用页", "切换启动检查", "CheckButton.toggled", "SettingsDialog", "_on_check_updates_on_start_toggled", "check_updates_on_start", "保存后生效", "启动时按间隔检查", "网络失败非阻塞", "取消恢复", "T-UPDATE"),
  contract("LMM-B-067", "偏好设置", "更新", "非下载中", "立即检查", "Button.pressed", "SettingsDialog / UpdateService", "check_for_updates", "last_update_check_at", "checking → latest/available/error", "显示检查结果", "网络失败保留当前版本", "无", "T-UPDATE"),
  contract("LMM-B-068", "偏好设置", "更新", "发现受信任更新", "下载更新", "Button.pressed", "SettingsDialog / UpdateService", "download_update", "updates/ 临时文件", "downloading → downloaded", "SHA256 与发布者校验通过", "失败删除临时文件并提示", "可取消", "T-UPDATE-DOWNLOAD"),
  contract("LMM-B-069", "偏好设置", "更新", "下载中", "取消下载", "Button.pressed", "UpdateService", "cancel_download", "删除临时下载", "downloading → cancelled", "当前版本不变", "取消失败记录日志", "显式取消", "T-UPDATE"),
  contract("LMM-B-070", "偏好设置", "Settings 底栏", "Settings 已打开", "恢复默认", "Button.pressed", "SettingsDialog", "_on_restore_defaults", "Config 草稿", "显示确认框", "确认后填入默认值", "失败保留当前值", "确认框取消不变", "T-SETTINGS"),
  contract("LMM-B-071", "偏好设置", "Settings 底栏", "存在或不存在更改", "保存", "Button.pressed", "SettingsDialog", "_on_save", "Config 安全写入 + 注册表补偿", "saving → saved/unchanged/failed", "成功或无变化反馈", "失败保留输入、旧配置不污染", "失败后继续编辑", "T-DESKTOP"),
  contract("LMM-B-072", "偏好设置", "Settings 底栏", "Settings 已打开", "取消", "Button.pressed", "SettingsDialog", "_on_cancel", "不写配置", "关闭并恢复运行态预览", "无配置变化", "无", "显式取消", "T-DESKTOP"),

  contract("LMM-B-080", "菜单与找回", "桌宠右键菜单", "右键桌宠", "今日详情", "PopupMenu.id_pressed", "ContextMenuBuilder / DragResizeSystem", "_on_menu_id(102)", "无", "关闭菜单并打开今日详情", "显示今日详情", "失败保留桌宠", "点击外部关闭", "T-TODAY"),
  contract("LMM-B-081", "菜单与找回", "桌宠右键菜单", "右键桌宠", "偏好设置", "PopupMenu.id_pressed", "DragResizeSystem", "_on_menu_id(100)", "无", "打开 Settings", "显示 Settings", "失败写日志", "点击外部关闭", "T-SETTINGS"),
  contract("LMM-B-082", "菜单与找回", "桌宠右键菜单", "右键桌宠", "重新配置", "PopupMenu.id_pressed", "DragResizeSystem", "_on_menu_id(101)", "无", "打开 Wizard", "显示 Wizard", "失败写日志", "点击外部关闭", "T-WIZARD-1"),
  contract("LMM-B-083", "菜单与找回", "窗口模式二级菜单", "展开窗口模式", "置顶悬浮", "PopupMenu.id_pressed", "DragResizeSystem", "_on_menu_id(300)", "window_mode=top", "应用 topmost", "窗口置顶", "native 不可用采用 Godot 能力", "点击外部关闭", "T-DESKTOP"),
  contract("LMM-B-084", "菜单与找回", "窗口模式二级菜单", "能力支持", "嵌入桌面", "PopupMenu.id_pressed", "DragResizeSystem", "_on_menu_id(301)", "window_mode=embed", "调用 WindowsPlatform", "嵌入桌面", "能力不可用禁用/回退", "点击外部关闭", "WINDOWS-NATIVE-WINDOW"),
  contract("LMM-B-085", "菜单与找回", "宠物二级菜单", "展开宠物", "选择宠物", "PopupMenu.id_pressed", "DragResizeSystem", "_switch_pet_by_menu_id", "pet_id", "切换宠物包", "宠物刷新", "资源损坏回退安全宠物", "点击外部关闭", "T-PET-WORKING"),
  contract("LMM-B-086", "菜单与找回", "桌宠右键菜单", "右键桌宠", "关于", "PopupMenu.id_pressed", "DragResizeSystem", "_on_menu_id(400)", "无", "打开关于窗口", "显示版本和许可", "失败写日志", "点击外部关闭", "T-ABOUT"),
  contract("LMM-B-087", "菜单与找回", "桌宠右键菜单", "托盘可用", "隐藏到托盘", "PopupMenu.id_pressed", "DragResizeSystem", "_on_menu_id(600)", "窗口运行态", "隐藏窗口、进程继续", "托盘可找回", "托盘不可用时不得造成失联", "再次托盘左键恢复", "WINDOWS-NATIVE-TRAY"),
  contract("LMM-B-088", "菜单与找回", "桌宠右键菜单", "右键桌宠", "退出", "PopupMenu.id_pressed", "DragResizeSystem", "quit_app", "保存位置", "清理托盘和穿透后退出", "进程退出", "清理失败写日志", "无", "T-EXIT"),
  contract("LMM-B-089", "菜单与找回", "原生托盘菜单", "通知区图标存在", "左键显示/隐藏", "Platform.tray_left_toggle_requested", "Main / DragResizeSystem", "_on_tray_left_toggle_requested", "窗口运行态", "显示 ↔ 隐藏并重应用策略", "普通/纯桌宠均可找回", "失败保持进程并写日志", "再次左键反向", "WINDOWS-NATIVE-TRAY"),
  contract("LMM-B-090", "菜单与找回", "原生托盘菜单", "右键托盘图标", "打开设置", "Platform.tray_settings_requested", "Main / DragResizeSystem", "open_settings", "无", "恢复窗口并打开 Settings", "显示 Settings", "失败写日志", "关闭 Settings", "T-SETTINGS"),
  contract("LMM-B-091", "菜单与找回", "原生托盘菜单", "右键托盘图标", "退出", "Platform.tray_exit_requested", "Main / DragResizeSystem", "quit_app", "保存位置", "清理后退出", "进程退出", "失败写日志", "无", "T-EXIT"),

  contract("LMM-B-100", "关于与更新", "关于", "关于窗口打开", "打开许可证", "Button.pressed", "About dialog", "OS.shell_open / 待确认", "无", "打开 LICENSE/声明", "用户可查看许可", "待确认：当前关于页按钮实现", "关闭窗口", "WINDOWS-NATIVE-SHELL", "待确认"),
  contract("LMM-B-101", "关于与更新", "关于", "关于窗口打开", "关闭", "Button.pressed", "About dialog", "queue_free", "无", "关闭关于", "返回原界面", "无", "关闭", "T-DESKTOP"),
  contract("LMM-B-102", "关于与更新", "安装确认", "下载与签名校验通过", "立即安装", "ConfirmationDialog.confirmed", "SettingsDialog / OS", "create_process", "安装器路径", "退出当前程序并启动安装器", "进入安装流程", "启动失败保留当前版本", "取消不安装", "WINDOWS-NATIVE-INSTALLER"),
  contract("LMM-B-103", "关于与更新", "安装确认", "确认框打开", "稍后", "ConfirmationDialog.canceled", "SettingsDialog", "dialog hide", "保留已下载文件策略待确认", "关闭确认", "继续使用当前版本", "无", "显式取消", "T-SETTINGS-GENERAL", "待确认"),
  contract("LMM-B-104", "系统反馈", "配置损坏恢复", "Config 检测到损坏", "打开数据目录", "Button.pressed", "DiagnosticsService", "open_app_data_directory", "%APPDATA%\\LetsMakeMoney", "打开备份和无效配置位置", "用户可手动取证", "失败提示路径", "关闭提示", "WINDOWS-NATIVE-DATA"),
  contract("LMM-B-105", "系统反馈", "配置损坏恢复", "恢复提示显示", "知道了", "Button.pressed", "Recovery notice", "hide", "已恢复的有效配置", "关闭提示", "继续使用安全配置", "无", "关闭", "T-DESKTOP"),
  contract("LMM-B-106", "系统反馈", "native 不可用", "能力状态 degraded/unavailable", "查看诊断", "Button.pressed", "DiagnosticsService", "build_summary / copy_summary_to_clipboard", "剪贴板", "提供脱敏诊断", "可反馈问题", "复制失败可打开目录", "关闭提示", "T-DIAGNOSTICS"),
  contract("LMM-B-107", "系统反馈", "宠物包回退", "包损坏/动作缺失", "恢复默认宠物", "Button.pressed", "PetManager / SettingsDialog", "rollback_to_default", "pet_id / package version", "回退 v0.8 默认宠物", "桌宠继续可见", "失败使用安全占位宠物", "关闭提示后保持当前安全态", "T-PET-WORKING")
];

const CONTRACT_BY_ID = new Map(CONTROL_SPECS.map((item) => [item.id, item]));

function postStatus(text) { figma.ui.postMessage({ type: "status", text }); }
function rgb(hex) { const v = hex.replace("#", ""); return { r: parseInt(v.slice(0, 2), 16) / 255, g: parseInt(v.slice(2, 4), 16) / 255, b: parseInt(v.slice(4, 6), 16) / 255 }; }
function paint(hex, opacity = 1) { return { type: "SOLID", color: rgb(hex), opacity }; }
function applyFill(node, hex, opacity = 1) { node.fills = [paint(hex, opacity)]; }
function applyStroke(node, hex = COLORS.line, width = 1) { node.strokes = [paint(hex)]; node.strokeWeight = width; node.strokeAlign = "INSIDE"; }
function applyShadow(node, floating = false) { node.effects = [{ type: "DROP_SHADOW", color: { r: 0.15, g: 0.11, b: 0.07, a: floating ? 0.16 : 0.11 }, offset: { x: 0, y: floating ? 8 : 14 }, radius: floating ? 20 : 36, spread: -8, visible: true, blendMode: "NORMAL" }]; }

function owned(node, key, phase) {
  node.setSharedPluginData(OWNER_NAMESPACE, "owner", OWNER_NAME);
  node.setSharedPluginData(OWNER_NAMESPACE, "managed", "true");
  node.setSharedPluginData(OWNER_NAMESPACE, "key", key);
  node.setSharedPluginData(OWNER_NAMESPACE, "phase", phase);
  node.setSharedPluginData(OWNER_NAMESPACE, "builder", BUILDER_VERSION);
  return node;
}

function isOwnedPage(page) {
  const owner = page.getSharedPluginData(OWNER_NAMESPACE, "owner");
  const managed = page.getSharedPluginData(OWNER_NAMESPACE, "managed");
  const builder = page.getSharedPluginData(OWNER_NAMESPACE, "builder");
  const key = page.getSharedPluginData(OWNER_NAMESPACE, "key");
  return (owner === OWNER_NAME && managed === "true") || (builder.startsWith("v0.9-local-") && key.startsWith("page/"));
}

function nodeFrame(parent, name, x, y, width, height, options = {}) {
  const node = figma.createFrame(); node.name = name; node.resize(width, height); node.x = x; node.y = y;
  node.clipsContent = options.clip === undefined ? false : options.clip; node.cornerRadius = options.radius || 0;
  if (options.fill) applyFill(node, options.fill, options.opacity === undefined ? 1 : options.opacity); else node.fills = [];
  if (options.stroke) applyStroke(node, options.stroke, options.strokeWidth || 1); if (options.shadow) applyShadow(node, options.shadow === "floating");
  parent.appendChild(node); return node;
}

function rectangle(parent, name, x, y, width, height, options = {}) {
  const node = figma.createRectangle(); node.name = name; node.resize(width, height); node.x = x; node.y = y; node.cornerRadius = options.radius || 0;
  if (options.fill) applyFill(node, options.fill, options.opacity === undefined ? 1 : options.opacity); else node.fills = [];
  if (options.stroke) applyStroke(node, options.stroke, options.strokeWidth || 1); if (options.shadow) applyShadow(node, options.shadow === "floating");
  parent.appendChild(node); return node;
}

function textNode(parent, value, x, y, kind = "body", color = COLORS.ink, width = null, options = {}) {
  const spec = TYPE[kind] || TYPE.body; const node = figma.createText(); node.name = options.name || `Text / ${value.slice(0, 24)}`;
  node.fontName = fonts[spec.weight]; node.fontSize = options.size || spec.size; node.lineHeight = { unit: "PIXELS", value: options.line || spec.line };
  node.letterSpacing = { unit: "PIXELS", value: 0 }; node.characters = value; node.fills = [paint(color)];
  node.textAlignHorizontal = options.align || "LEFT"; node.textAlignVertical = options.verticalAlign || "TOP";
  if (width !== null) { node.textAutoResize = "HEIGHT"; node.resize(width, options.height || spec.line); } else node.textAutoResize = "WIDTH_AND_HEIGHT";
  node.x = x; node.y = y; parent.appendChild(node); return node;
}

function divider(parent, x, y, width) { return rectangle(parent, "Divider", x, y, width, 1, { fill: COLORS.line }); }
function documentPill(parent, label, x, y, tone = "blue") {
  const tones = {
    blue: [DOC.blueSoft, DOC.blue], purple: [DOC.purpleSoft, DOC.purple],
    green: [DOC.greenSoft, DOC.green], amber: [DOC.amberSoft, DOC.amber]
  };
  const [background, foreground] = tones[tone] || tones.blue;
  const width = Math.max(86, label.length * 13 + 20);
  const node = nodeFrame(parent, `Document pill / ${label}`, x, y, width, 26, { fill: background, stroke: foreground, radius: 4 });
  textNode(node, label, 0, 4, "caption", foreground, width, { align: "CENTER", height: 18 });
  return node;
}
function phaseHeading(parent, key, label, detail, x, y, tone = "blue") {
  const pill = documentPill(parent, `${key} · ${label}`, x, y, tone);
  textNode(parent, detail, x + pill.width + 12, y + 3, "caption", DOC.muted, 1500);
  return pill;
}
function chip(parent, label, x, y, tone = "implemented") {
  const tones = { implemented: [COLORS.mintSoft, COLORS.mint, COLORS.sageDeep], candidate: [COLORS.coinSoft, COLORS.coinStrong, COLORS.ink], native: [COLORS.native, COLORS.nativeInk, COLORS.nativeInk], pending: [COLORS.dangerSoft, COLORS.danger, COLORS.danger] };
  const [bg, border, fg] = tones[tone] || tones.implemented; const width = Math.max(68, label.length * 13 + 22);
  const node = nodeFrame(parent, `Status / ${label}`, x, y, width, 26, { fill: bg, stroke: border, radius: 13 });
  textNode(node, label, 0, 4, "caption", fg, width, { align: "CENTER", height: 18 }); return node;
}

function attachContract(node, id) {
  const spec = CONTRACT_BY_ID.get(id); if (!spec) throw new Error(`控件缺少契约：${id}`);
  node.setSharedPluginData(OWNER_NAMESPACE, "control-contract-ids", id);
  node.setSharedPluginData(OWNER_NAMESPACE, "control-contract", JSON.stringify(spec));
  node.setSharedPluginData(OWNER_NAMESPACE, "control-contract-version", "1");
  node.name = `${id} / ${node.name}`; return node;
}

function controlButton(parent, id, label, x, y, width = 104, style = "primary", state = "default") {
  const styles = { primary: [COLORS.coin, COLORS.coinStrong, COLORS.ink], secondary: [COLORS.paper, COLORS.lineStrong, COLORS.ink], ghost: [COLORS.paper, COLORS.line, COLORS.muted], danger: [COLORS.dangerSoft, COLORS.danger, COLORS.danger] };
  const s = styles[style] || styles.primary; const node = nodeFrame(parent, `Button / ${label} / ${state}`, x, y, width, 38, { fill: state === "disabled" ? COLORS.cool : s[0], stroke: s[1], radius: 8 });
  textNode(node, label, 0, 9, "label", state === "disabled" ? COLORS.subtle : s[2], width, { align: "CENTER", height: 20 }); return attachContract(node, id);
}

function controlInput(parent, id, label, value, x, y, width = 180, state = "default") {
  textNode(parent, label, x, y, "label", COLORS.ink); const border = state === "error" ? COLORS.danger : state === "focus" ? COLORS.coinStrong : COLORS.line;
  const node = nodeFrame(parent, `Input / ${label} / ${state}`, x, y + 24, width, 36, { fill: state === "disabled" ? COLORS.cool : COLORS.paper, stroke: border, strokeWidth: state === "focus" ? 2 : 1, radius: 8 });
  textNode(node, value, 12, 8, "body", state === "disabled" ? COLORS.subtle : COLORS.ink, width - 24, { height: 20 }); return attachContract(node, id);
}

function controlSelect(parent, id, label, value, x, y, width = 180) {
  const node = controlInput(parent, id, label, value, x, y, width); textNode(node, "⌄", width - 28, 8, "body", COLORS.muted, 18, { align: "CENTER" }); node.name = `${id} / Select / ${label}`; return node;
}

function controlToggle(parent, id, label, x, y, on = false, disabled = false) {
  textNode(parent, label, x, y + 2, "label", disabled ? COLORS.subtle : COLORS.ink); const node = nodeFrame(parent, `Toggle / ${label}`, x + 180, y, 40, 22, { fill: disabled ? COLORS.cool : on ? COLORS.mint : COLORS.lineStrong, stroke: disabled ? COLORS.line : on ? COLORS.mint : COLORS.lineStrong, radius: 11 });
  rectangle(node, "Thumb", on ? 19 : 2, 2, 18, 18, { fill: COLORS.white, radius: 9, shadow: "floating" }); return attachContract(node, id);
}

function controlSlider(parent, id, label, x, y, width, progress, value) {
  textNode(parent, label, x, y, "label", COLORS.ink); const node = nodeFrame(parent, `Slider / ${label}`, x, y + 26, width, 26, { fill: COLORS.paper });
  rectangle(node, "Track", 0, 10, width - 52, 6, { fill: COLORS.line, radius: 3 }); rectangle(node, "Fill", 0, 10, (width - 52) * progress, 6, { fill: COLORS.coin, radius: 3 }); rectangle(node, "Thumb", (width - 52) * progress - 7, 5, 16, 16, { fill: COLORS.white, stroke: COLORS.coinStrong, radius: 8 }); textNode(node, value, width - 44, 4, "caption", COLORS.muted, 44, { align: "RIGHT" });
  return attachContract(node, id);
}

function imageRect(parent, image, name, x, y, width, height) { const node = figma.createRectangle(); node.name = name; node.resize(width, height); node.x = x; node.y = y; node.fills = [{ type: "IMAGE", imageHash: image.hash, scaleMode: "FIT" }]; parent.appendChild(node); return node; }

function sha256(bytes) {
  const rightRotate = (value, amount) => (value >>> amount) | (value << (32 - amount));
  const maxWord = 2 ** 32; const words = []; const hash = []; const k = []; let primeCounter = 0; const isComposite = {};
  for (let candidate = 2; primeCounter < 64; candidate += 1) if (!isComposite[candidate]) { for (let i = candidate * candidate; i < 313; i += candidate) isComposite[i] = candidate; hash[primeCounter] = (candidate ** 0.5 * maxWord) | 0; k[primeCounter++] = (candidate ** (1 / 3) * maxWord) | 0; }
  const data = Array.from(bytes); const bitLength = data.length * 8; data.push(0x80); while ((data.length % 64) !== 56) data.push(0); for (let i = 7; i >= 0; i -= 1) data.push((bitLength / (2 ** (i * 8))) & 255);
  for (let offset = 0; offset < data.length; offset += 64) { const w = new Array(64); for (let i = 0; i < 16; i += 1) w[i] = (data[offset + i * 4] << 24) | (data[offset + i * 4 + 1] << 16) | (data[offset + i * 4 + 2] << 8) | data[offset + i * 4 + 3]; for (let i = 16; i < 64; i += 1) { const x = w[i - 15], y = w[i - 2]; const s0 = rightRotate(x, 7) ^ rightRotate(x, 18) ^ (x >>> 3); const s1 = rightRotate(y, 17) ^ rightRotate(y, 19) ^ (y >>> 10); w[i] = (w[i - 16] + s0 + w[i - 7] + s1) | 0; }
    let [a, b, c, d, e, f, g, h] = hash.slice(0, 8); for (let i = 0; i < 64; i += 1) { const s1 = rightRotate(e, 6) ^ rightRotate(e, 11) ^ rightRotate(e, 25); const ch = (e & f) ^ (~e & g); const temp1 = (h + s1 + ch + k[i] + w[i]) | 0; const s0 = rightRotate(a, 2) ^ rightRotate(a, 13) ^ rightRotate(a, 22); const maj = (a & b) ^ (a & c) ^ (b & c); const temp2 = (s0 + maj) | 0; h = g; g = f; f = e; e = (d + temp1) | 0; d = c; c = b; b = a; a = (temp1 + temp2) | 0; } hash[0] = (hash[0] + a) | 0; hash[1] = (hash[1] + b) | 0; hash[2] = (hash[2] + c) | 0; hash[3] = (hash[3] + d) | 0; hash[4] = (hash[4] + e) | 0; hash[5] = (hash[5] + f) | 0; hash[6] = (hash[6] + g) | 0; hash[7] = (hash[7] + h) | 0; }
  return hash.slice(0, 8).map((value) => (value >>> 0).toString(16).padStart(8, "0")).join("");
}

async function createVerifiedImage(asset, label) {
  const decoded = figma.base64Decode(asset.base64); if (decoded.length !== asset.bytes || decoded.length < 24) throw new Error(`${label} 字节长度不一致`);
  const signature = [137, 80, 78, 71, 13, 10, 26, 10]; signature.forEach((value, index) => { if (decoded[index] !== value) throw new Error(`${label} 不是 PNG`); });
  const width = ((decoded[16] << 24) | (decoded[17] << 16) | (decoded[18] << 8) | decoded[19]) >>> 0; const height = ((decoded[20] << 24) | (decoded[21] << 16) | (decoded[22] << 8) | decoded[23]) >>> 0;
  if (width !== asset.width || height !== asset.height || width < 1 || height < 1) throw new Error(`${label} 尺寸校验失败`);
  if (sha256(decoded) !== asset.sha256.toLowerCase()) throw new Error(`${label} SHA256 校验失败`);
  const image = figma.createImage(decoded); const stored = await image.getBytesAsync(); if (stored.length !== decoded.length) throw new Error(`${label} 写入 Figma 后字节变化`); return image;
}

async function chooseFonts() {
  const available = (await figma.listAvailableFontsAsync()).map((item) => item.fontName);
  const find = (styles) => available.find((font) => ["Noto Sans SC", "Microsoft YaHei UI", "Microsoft YaHei", "Inter"].includes(font.family) && styles.includes(font.style)) || available[0];
  fonts = { regular: find(["Regular", "Normal"]), semibold: find(["SemiBold", "DemiBold", "Medium", "Bold", "Regular"]), bold: find(["Bold", "SemiBold", "DemiBold", "Medium", "Regular"]) };
  const unique = new Map(Object.values(fonts).map((font) => [`${font.family}/${font.style}`, font])); for (const font of unique.values()) await figma.loadFontAsync(font);
}

async function prepareSinglePage() {
  await figma.loadAllPagesAsync(); const warnings = []; const targetMatches = figma.root.children.filter((item) => item.name === PAGE_NAME);
  if (targetMatches.some((item) => !isOwnedPage(item))) throw new Error(`目标页“${PAGE_NAME}”存在但无法确认 LMM 所有权，已停止以保护内容。`);
  let page = targetMatches[0];
  if (!page) { const blank = figma.root.children.find((item) => item.name === "Page 1" && item.children.length === 0); page = blank || figma.createPage(); }
  await page.loadAsync(); if (page.children.length > 0 && !isOwnedPage(page)) throw new Error("目标页包含内容但没有 LMM 所有权标记。");
  for (const child of [...page.children]) child.remove(); page.name = PAGE_NAME; owned(page, "page/full-product-flow", "structure");
  await figma.setCurrentPageAsync(page);
  for (const duplicate of targetMatches.slice(1)) duplicate.remove();
  for (const legacyName of LEGACY_PAGE_NAMES) { const matches = figma.root.children.filter((item) => item.name === legacyName); for (const legacy of matches) { if (legacy === page) continue; await legacy.loadAsync(); if (isOwnedPage(legacy)) legacy.remove(); else warnings.push(`保留未确认归属的旧页：${legacyName}`); } }
  return { page, warnings };
}

async function resetDesignSystem() {
  const collections = await figma.variables.getLocalVariableCollectionsAsync(); collections.filter((item) => item.name.startsWith("LMM ")).forEach((item) => item.remove());
  (await figma.getLocalTextStylesAsync()).filter((item) => item.name.startsWith("LMM/")).forEach((item) => item.remove());
  (await figma.getLocalEffectStylesAsync()).filter((item) => item.name.startsWith("LMM/")).forEach((item) => item.remove());
  const collection = figma.variables.createVariableCollection("LMM Semantic"); const mode = collection.defaultModeId;
  Object.entries(COLORS).forEach(([name, value]) => { const variable = figma.variables.createVariable(`color/${name}`, collection, "COLOR"); variable.setValueForMode(mode, rgb(value)); variable.setVariableCodeSyntax("WEB", `var(--lmm-${name})`); variables[name] = variable; });
  for (const [name, spec] of Object.entries(TYPE)) { const style = figma.createTextStyle(); style.name = `LMM/${name}`; style.fontName = fonts[spec.weight]; style.fontSize = spec.size; style.lineHeight = { unit: "PIXELS", value: spec.line }; style.letterSpacing = { unit: "PIXELS", value: 0 }; }
  const effect = figma.createEffectStyle(); effect.name = "LMM/Window"; effect.effects = [{ type: "DROP_SHADOW", color: { r: 0.15, g: 0.11, b: 0.07, a: 0.11 }, offset: { x: 0, y: 14 }, radius: 36, spread: -8, visible: true, blendMode: "NORMAL" }];
}

function target(node, id, title) { node.setSharedPluginData(OWNER_NAMESPACE, "target-id", id); node.name = `${id} / ${title}`; return node; }
function markScreen(node) { const ids = node.findAll((child) => child.getSharedPluginData && child.getSharedPluginData(OWNER_NAMESPACE, "control-contract-ids")).map((child) => child.getSharedPluginData(OWNER_NAMESPACE, "control-contract-ids")); node.setSharedPluginData(OWNER_NAMESPACE, "control-contract-ids", ids.join(",")); return node; }
function flowCard(parent, id, title, detail, x, y, tone = "implemented") {
  const palette = tone === "native" ? [COLORS.native, COLORS.nativeInk] : tone === "candidate" ? [DOC.greenSoft, DOC.green] : [DOC.blueSoft, DOC.blue];
  const card = nodeFrame(parent, `Flow / ${id}`, x, y, 250, 92, { fill: palette[0], stroke: palette[1], radius: 6 });
  card.setSharedPluginData(OWNER_NAMESPACE, "flow-target", id);
  textNode(card, title, 14, 14, "heading", DOC.text, 222);
  textNode(card, detail, 14, 50, "caption", DOC.muted, 222, { line: 18 });
  return card;
}
function arrow(parent, x, y, width, label) { rectangle(parent, "Flow connector", x, y + 8, width - 18, 2, { fill: COLORS.lineStrong }); textNode(parent, "→", x + width - 22, y - 5, "heading", COLORS.muted); if (label) textNode(parent, label, x, y - 18, "caption", COLORS.subtle, width, { align: "CENTER" }); }
function section(root, key, title, subtitle, y, height) { const area = owned(nodeFrame(root, `${key} / ${title}`, 40, y, GRID_WIDTH, height, { fill: DOC.surface, stroke: DOC.line, radius: 8 }), `section/${key}`, "product-flow"); textNode(area, `${key} · ${title}`, SECTION_PADDING, 24, "title", DOC.text); textNode(area, subtitle, SECTION_PADDING, 60, "body", DOC.muted, 1800); return area; }
function windowShell(parent, targetId, title, x, y, width, height) { const shell = target(nodeFrame(parent, title, x, y, width, height, { fill: COLORS.paper, stroke: COLORS.lineStrong, radius: 14, shadow: "window", clip: true }), targetId, title); rectangle(shell, "Title bar", 0, 0, width, 48, { fill: COLORS.paper }); divider(shell, 0, 47, width); textNode(shell, title, 20, 13, "heading", COLORS.ink); return shell; }
function contractLine(parent, label, value, y, tone = "default") {
  const colors = { default: DOC.text, signal: DOC.blue, call: DOC.purple, success: DOC.green, failure: COLORS.danger, boundary: COLORS.nativeInk };
  textNode(parent, label, 16, y, "caption", DOC.muted, 104, { line: 18 });
  textNode(parent, value || "无", 120, y, "caption", colors[tone] || DOC.text, parent.width - 136, { line: 18 });
}
function contractCard(parent, spec, x, y, width) {
  const card = nodeFrame(parent, `Contract / ${spec.id}`, x, y, width, CONTRACT_CARD_HEIGHT, { fill: DOC.surface, stroke: DOC.line, radius: 6 });
  const idPill = documentPill(card, spec.id, 16, 14, spec.status === "待确认" ? "amber" : "blue");
  let titleX = idPill.x + idPill.width + 12;
  if (spec.status) {
    const statusPill = documentPill(card, spec.status, titleX, 14, spec.status === "待确认" ? "amber" : "purple");
    titleX = statusPill.x + statusPill.width + 12;
  }
  textNode(card, `${spec.screen} · ${spec.operation}`, titleX, 17, "label", DOC.text, width - titleX - 16, { line: 18 });
  divider(card, 16, 52, width - 32);
  contractLine(card, "显示条件", spec.condition, 68);
  contractLine(card, "信号入口", spec.signal, 108, "signal");
  contractLine(card, "调用对象", `${spec.caller}.${spec.method}`, 148, "call");
  contractLine(card, "配置/持久化", spec.persistence, 188);
  contractLine(card, "成功结果", spec.success, 228, "success");
  contractLine(card, "失败结果", spec.failure, 268, "failure");
  contractLine(card, "取消语义", spec.cancel, 308);
  contractLine(card, "跳转/边界", spec.target, 348, "boundary");
  card.setSharedPluginData(OWNER_NAMESPACE, "control-contract", JSON.stringify(spec));
  card.setSharedPluginData(OWNER_NAMESPACE, "control-contract-ids", spec.id);
  return card;
}
function contractBoardHeight(ids) {
  const rows = Math.ceil(ids.length / CONTRACT_COLUMNS);
  return CONTRACT_BOARD_TOP + rows * CONTRACT_CARD_HEIGHT + Math.max(0, rows - 1) * CONTRACT_ROW_GAP + CONTRACT_BOARD_BOTTOM;
}
function contractSectionHeight(gridY, ids) { return gridY + contractBoardHeight(ids) + SECTION_PADDING; }
function contractGrid(parent, areaName, x, y, width, ids) {
  const columns = CONTRACT_COLUMNS; const gap = CONTRACT_ROW_GAP; const boardHeight = contractBoardHeight(ids);
  const board = nodeFrame(parent, `${areaName} / Associated contracts`, x, y, width, boardHeight, { fill: DOC.soft, stroke: DOC.line, radius: 6 });
  phaseHeading(board, "B", "控件契约", `与本区上方原型直接关联，共 ${ids.length} 项；通过 LMM-B-xxx 在控件、契约和 Godot 实现之间互查。`, 18, 18, "blue");
  const cardWidth = (width - 36 - gap * (columns - 1)) / columns;
  ids.forEach((id, index) => { const spec = CONTRACT_BY_ID.get(id); if (!spec) throw new Error(`缺少契约 ${id}`); contractCard(board, spec, 18 + (index % columns) * (cardWidth + gap), CONTRACT_BOARD_TOP + Math.floor(index / columns) * (CONTRACT_CARD_HEIGHT + gap), cardWidth); });
  board.setSharedPluginData(OWNER_NAMESPACE, "control-contract-ids", ids.join(",")); board.setSharedPluginData(OWNER_NAMESPACE, "control-contract", JSON.stringify(ids.map((id) => CONTRACT_BY_ID.get(id))));
  const registry = nodeFrame(parent, `${areaName} Contract Registry`, x, y, 1, 1); registry.visible = false; registry.setSharedPluginData(OWNER_NAMESPACE, "control-contract-ids", ids.join(",")); registry.setSharedPluginData(OWNER_NAMESPACE, "control-contract", JSON.stringify(ids.map((id) => CONTRACT_BY_ID.get(id))));
  return boardHeight;
}
function contractReference(parent, x, y, width, ids) { const ref = nodeFrame(parent, `Adjacent contracts / ${ids.join(",")}`, x, y, width, 34, { fill: COLORS.cool, stroke: COLORS.line, radius: 8 }); textNode(ref, `控件契约  ${ids.join(" · ")}`, 12, 8, "caption", COLORS.sageDeep, width - 24); ref.setSharedPluginData(OWNER_NAMESPACE, "control-contract-ids", ids.join(",")); ref.setSharedPluginData(OWNER_NAMESPACE, "control-contract", JSON.stringify(ids.map((id) => CONTRACT_BY_ID.get(id)))); return ref; }
function settingsRowLine(win, y) { divider(win, 28, y + 47, RUNTIME_BASELINES.settings[0] - 56); }
function settingsInputRow(win, id, label, value, y, width = 104, state = "default") { textNode(win, label, 28, y + 12, "body", COLORS.ink); const x = RUNTIME_BASELINES.settings[0] - 28 - width; const node = nodeFrame(win, `Row input / ${label}`, x, y + 6, width, 35, { fill: state === "disabled" ? COLORS.cool : COLORS.paper, stroke: state === "focus" ? COLORS.coinStrong : state === "error" ? COLORS.danger : COLORS.line, strokeWidth: state === "focus" ? 2 : 1, radius: 8 }); textNode(node, value, 12, 7, "body", state === "disabled" ? COLORS.subtle : COLORS.ink, width - 24); settingsRowLine(win, y); return attachContract(node, id); }
function settingsSelectRow(win, id, label, value, y, width = 124) { const node = settingsInputRow(win, id, label, value, y, width); textNode(node, "⌄", width - 28, 7, "body", COLORS.muted, 18, { align: "CENTER" }); node.name = `${id} / Row select / ${label}`; return node; }
function settingsToggleRow(win, id, label, y, on = false) { textNode(win, label, 28, y + 12, "body", COLORS.ink); const x = RUNTIME_BASELINES.settings[0] - 70; const node = nodeFrame(win, `Row toggle / ${label}`, x, y + 12, 42, 24, { fill: on ? COLORS.mint : COLORS.lineStrong, stroke: on ? COLORS.mint : COLORS.lineStrong, radius: 12 }); rectangle(node, "Thumb", on ? 20 : 2, 2, 20, 20, { fill: COLORS.white, radius: 10, shadow: "floating" }); settingsRowLine(win, y); return attachContract(node, id); }
function settingsButtonRow(win, id, label, buttonLabel, y, width = 112, tone = "secondary") { textNode(win, label, 28, y + 12, "body", COLORS.ink); const button = controlButton(win, id, buttonLabel, RUNTIME_BASELINES.settings[0] - 28 - width, y + 6, width, tone); button.resize(width, 36); settingsRowLine(win, y); return button; }
function settingsSliderRow(win, id, label, y, progress, value) { textNode(win, label, 28, y + 12, "body", COLORS.ink); const width = 236; const x = RUNTIME_BASELINES.settings[0] - 28 - width; const node = nodeFrame(win, `Row slider / ${label}`, x, y + 8, width, 32, { fill: COLORS.paper }); rectangle(node, "Track", 0, 13, 184, 6, { fill: COLORS.line, radius: 3 }); rectangle(node, "Fill", 0, 13, 184 * progress, 6, { fill: COLORS.coin, radius: 3 }); rectangle(node, "Thumb", 184 * progress - 8, 8, 16, 16, { fill: COLORS.white, stroke: COLORS.coinStrong, radius: 8 }); textNode(node, value, 192, 7, "caption", COLORS.muted, 44, { align: "RIGHT" }); settingsRowLine(win, y); return attachContract(node, id); }

function buildDocumentCover(root, y) {
  const cover = owned(nodeFrame(root, "LMM Full Product Flow / Document identity", 40, y, GRID_WIDTH, 238, { fill: DOC.surface, stroke: DOC.line, radius: 8, shadow: "floating" }), "document/identity", "structure");
  imageRect(cover, images.classicWorking, "Product identity / Classic Pro", 28, 28, 164, 164);
  documentPill(cover, "WINDOWS · v0.9", 220, 30, "amber");
  textNode(cover, "LetsMakeMoney", 220, 72, "display", DOC.text);
  textNode(cover, "Windows 桌面收入进度伴件 · 完整产品流程与开发契约", 220, 124, "heading", DOC.muted, 1180);
  textNode(cover, "来源：当前 Godot 场景、运行校准、v0.9 PRD 与高保真原型。所有窗口均为可编辑图层，运行截图仅用于校准。", 220, 164, "body", DOC.muted, 1600);
  const identity = nodeFrame(cover, "Atlas identity", 3800, 28, 1292, 164, { fill: DOC.soft, stroke: DOC.line, radius: 6 });
  documentPill(identity, "单页全链路", 18, 18, "green");
  documentPill(identity, "就近契约", 140, 18, "purple");
  documentPill(identity, "Windows 原生边界", 250, 18, "blue");
  textNode(identity, `${CONTROL_SPECS.length} 项稳定控件契约`, 18, 62, "title", DOC.text);
  textNode(identity, "5120px 内容栅格 · 24px 区域内边距 · 18px 组间距 · 顶部对齐", 18, 104, "body", DOC.muted, 980);
  return y + 256;
}

function buildOverview(root, y) {
  const area = section(root, "00", "产品关系总览", "从启动到首次配置、桌宠、Panel、今日详情、设置、托盘与退出的真实 Windows 链路。", y, 480);
  const items = [["T-START", "启动", "Config 读取与恢复", "implemented"], ["T-WIZARD-1", "首次配置", "未配置时进入四步 Wizard", "implemented"], ["T-DESKTOP", "桌面伴件", "桌宠 + Panel", "implemented"], ["T-TODAY", "今日详情", "收入、进度、安排", "implemented"], ["T-SETTINGS", "偏好设置", "五个真实页签", "implemented"], ["WINDOWS-NATIVE-TRAY", "托盘", "显隐、找回与退出", "native"], ["T-EXIT", "退出", "保存位置并清理原生资源", "native"]];
  items.forEach((item, index) => { flowCard(area, item[0], item[1], item[2], 28 + index * 704, 110, item[3]); if (index < items.length - 1) arrow(area, 286 + index * 704, 152, 428, index === 0 ? "首次启动分支" : "窗口跳转 / 状态切换"); });
  textNode(area, "系统边界", 28, 292, "heading", COLORS.ink); chip(area, "Windows 原生边界", 138, 292, "native");
  textNode(area, "点击穿透在 Popup、Settings、Wizard、About 打开期间暂停，关闭后恢复。纯桌宠模式只隐藏任务栏入口，不改变托盘左键显隐语义。", 28, 338, "body", COLORS.muted, 1900);
  return y + 498;
}

function buildDesktopSection(root, y) {
  const contractIds = ["LMM-B-001", "LMM-B-002", "LMM-B-003", "LMM-B-004", "LMM-B-005", "LMM-B-006", "LMM-B-007"];
  const areaHeight = contractSectionHeight(820, contractIds);
  const area = section(root, "01", "桌面伴件、Panel 与桌宠状态", "状态关系 → 可编辑界面 → 本区控件契约。宠物图为确定性 PNG 关键帧，窗口和文字均为可编辑图层。", y, areaHeight);
  flowCard(area, "T-PET-WORKING", "工作中", "working / working_ack", 28, 110); arrow(area, 288, 152, 90, "单击"); flowCard(area, "T-PANEL-COLLAPSED", "Panel 折叠", "300×124 运行实测", 382, 110); arrow(area, 642, 152, 90, "详情"); flowCard(area, "T-TODAY", "今日详情", "独立窗口", 736, 110);
  phaseHeading(area, "A", "可编辑原型", "真实桌面状态、宠物素材关键帧与 Panel 运行尺寸。", 28, 222, "purple");
  const desktop = target(nodeFrame(area, "Desktop companion canvas", 28, 264, 980, 430, { fill: COLORS.canvasDeep, stroke: COLORS.lineStrong, radius: 16 }), "T-DESKTOP", "桌面伴件");
  const petStates = [["working", images.classicWorking, "LMM-B-001"], ["awake_rest", images.classicAwake, "LMM-B-002"], ["sleeping", images.classicSleeping, "LMM-B-003"]];
  petStates.forEach((item, index) => { const x = 38 + index * 210; const card = attachContract(nodeFrame(desktop, `Pet state / ${item[0]}`, x, 98, 184, 244, { fill: COLORS.paper, stroke: COLORS.line, radius: 12 }), item[2]); imageRect(card, item[1], item[0], 16, 18, 152, 152); chip(card, item[0], 16, 182, index === 0 ? "candidate" : "implemented"); textNode(card, index === 0 ? "工作循环 / 单击确认" : index === 1 ? "清醒休息 / 单击回应" : "深度睡眠 / 轻量回应", 16, 216, "caption", COLORS.muted, 152); });
  const drag = attachContract(nodeFrame(desktop, "Long press + drag hit area", 672, 98, 270, 108, { fill: COLORS.warm, stroke: COLORS.coinStrong, radius: 12 }), "LMM-B-007"); textNode(drag, "长按 + 拖拽", 18, 18, "heading", COLORS.ink); textNode(drag, "run_prepare → 水平跑动/镜像 → run_stop", 18, 52, "caption", COLORS.muted, 230);
  const collapsed = attachContract(nodeFrame(area, "Panel collapsed / runtime 100%", 1040, 264, RUNTIME_BASELINES.panelCollapsed[0], RUNTIME_BASELINES.panelCollapsed[1], { fill: COLORS.paper, stroke: COLORS.lineStrong, radius: 18, shadow: "floating" }), "LMM-B-004"); rectangle(collapsed, "Coin", 16, 18, 40, 40, { fill: COLORS.coin, radius: 20 }); textNode(collapsed, "¥", 16, 27, "heading", COLORS.ink, 40, { align: "CENTER" }); textNode(collapsed, "¥186.42", 70, 16, "numeric", COLORS.ink); textNode(collapsed, "工作中", 228, 18, "caption", COLORS.sageDeep, 56, { align: "RIGHT" }); rectangle(collapsed, "Progress track", 70, 76, 214, 6, { fill: COLORS.line, radius: 3 }); rectangle(collapsed, "Progress fill", 70, 76, 120, 6, { fill: COLORS.coin, radius: 3 }); textNode(collapsed, "工作进度 56%", 70, 92, "caption", COLORS.muted); textNode(collapsed, "距离午休 38 分钟", 174, 92, "caption", COLORS.muted, 110, { align: "RIGHT" });
  const expanded = attachContract(nodeFrame(area, "Panel expanded / runtime 100%", 1040, 418, RUNTIME_BASELINES.panelExpanded[0], RUNTIME_BASELINES.panelExpanded[1], { fill: COLORS.paper, stroke: COLORS.lineStrong, radius: 18, shadow: "floating" }), "LMM-B-005"); textNode(expanded, "今日已赚", 18, 16, "caption", COLORS.muted); textNode(expanded, "¥186.42", 18, 42, "numeric", COLORS.ink); chip(expanded, "工作中", 260, 18, "implemented"); textNode(expanded, "本月累计", 18, 94, "caption", COLORS.muted); textNode(expanded, "¥3,842.00", 214, 92, "label", COLORS.ink, 112, { align: "RIGHT" }); textNode(expanded, "时薪", 18, 120, "caption", COLORS.muted); textNode(expanded, "¥62.50 / 小时", 214, 118, "label", COLORS.ink, 112, { align: "RIGHT" }); textNode(expanded, "工作进度", 18, 148, "caption", COLORS.muted); rectangle(expanded, "Progress track", 18, 172, 308, 6, { fill: COLORS.line, radius: 3 }); rectangle(expanded, "Progress fill", 18, 172, 172, 6, { fill: COLORS.coin, radius: 3 }); textNode(expanded, "56% · 08:00–18:00 · 8.00 小时", 18, 190, "caption", COLORS.muted, 308);
  const edge = attachContract(nodeFrame(area, "Panel edge state", 1414, 264, RUNTIME_BASELINES.panelExpanded[0], RUNTIME_BASELINES.panelExpanded[1], { fill: COLORS.paper, stroke: COLORS.coinStrong, radius: 18 }), "LMM-B-006"); rectangle(edge, "Screen edge", RUNTIME_BASELINES.panelExpanded[0] - 8, 0, 8, RUNTIME_BASELINES.panelExpanded[1], { fill: COLORS.coin }); textNode(edge, "屏幕边缘状态", 18, 18, "heading", COLORS.ink); textNode(edge, "保持四角圆角与 16px 内边距；内容不裁切。释放后保存位置并重新计算透明命中区。", 18, 56, "body", COLORS.muted, 292);
  contractReference(area, 1040, 680, 718, ["LMM-B-004", "LMM-B-005", "LMM-B-006"]);
  textNode(area, `100% DPI 实测：折叠 ${RUNTIME_BASELINES.panelCollapsed.join("×")} · 展开 ${RUNTIME_BASELINES.panelExpanded.join("×")}\nPRD 历史参考：折叠 ${PRD_REFERENCE_SIZES.panelCollapsed.join("×")} · 展开 ${PRD_REFERENCE_SIZES.panelExpanded.join("×")}`, 1040, 730, "caption", COLORS.muted, 720);
  contractGrid(area, "desktop", 28, 820, 5064, contractIds); markScreen(desktop); return y + areaHeight + GROUP_GAP;
}

function buildTodaySection(root, y) {
  const contractIds = ["LMM-B-010", "LMM-B-011"];
  const areaHeight = contractSectionHeight(966, contractIds);
  const area = section(root, "02", "今日详情", "独立窗口承载今日收入、进度、安排和月度摘要。", y, areaHeight);
  flowCard(area, "T-PANEL-COLLAPSED", "Panel", "单击打开", 28, 110); arrow(area, 288, 152, 90, "打开"); flowCard(area, "T-TODAY", "今日详情", "480×620 运行实测", 382, 110); arrow(area, 642, 152, 90, "调整今天"); flowCard(area, "T-SETTINGS-SCHEDULE", "作息设置", "保存后回到详情", 736, 110);
  phaseHeading(area, "A", "可编辑原型", "收入、进度、时间轴、月度摘要与关闭路径。", 28, 222, "purple");
  const win = windowShell(area, "T-TODAY", "今日详情", 28, 274, RUNTIME_BASELINES.today[0], RUNTIME_BASELINES.today[1]); const close = controlButton(win, "LMM-B-010", "×", 426, 8, 36, "ghost"); close.resize(36, 32);
  chip(win, "工作中", 28, 68, "candidate"); textNode(win, "今日已赚", 28, 108, "body", COLORS.muted); textNode(win, "¥ 186.42", 28, 136, "numeric", COLORS.ink); textNode(win, "日薪 ¥500.00 · 时薪 ¥62.50", 28, 180, "caption", COLORS.muted); rectangle(win, "Income progress track", 28, 208, 424, 6, { fill: COLORS.line, radius: 3 }); rectangle(win, "Income progress fill", 28, 208, 237, 6, { fill: COLORS.coin, radius: 3 }); textNode(win, "工作进度", 28, 224, "caption", COLORS.muted); textNode(win, "56%", 408, 224, "caption", COLORS.ink, 44, { align: "RIGHT" }); divider(win, 28, 254, 424);
  textNode(win, "今天", 28, 270, "caption", COLORS.orange); textNode(win, "今日安排", 28, 294, "heading", COLORS.ink); controlButton(win, "LMM-B-011", "调整今天", 336, 284, 116, "ghost");
  const rows = [["08:00", "开始工作", "已完成 3 小时 22 分钟"], ["12:00", "午休", "12:00–14:00"], ["18:00", "结束工作", "预计今日收入 ¥500.00"]]; rows.forEach((row, index) => { const ry = 344 + index * 64; textNode(win, row[0], 28, ry, "caption", COLORS.muted); rectangle(win, "Timeline dot", 90, ry + 4, 10, 10, { fill: index === 1 ? COLORS.coin : index === 0 ? COLORS.mint : COLORS.lineStrong, radius: 5 }); textNode(win, row[1], 116, ry - 3, "heading", COLORS.ink); textNode(win, row[2], 116, ry + 24, "caption", COLORS.muted); if (index < 2) rectangle(win, "Timeline line", 94, ry + 18, 2, 46, { fill: COLORS.line }); });
  const summary = nodeFrame(win, "Monthly summary", 28, 552, 424, 50, { fill: COLORS.warm, stroke: COLORS.line, radius: 10 }); textNode(summary, "本月累计  ¥3,842.00   工作日 23 天   距离下班 4:38:20", 14, 16, "caption", COLORS.ink, 396);
  contractReference(area, 28, 910, 480, ["LMM-B-010", "LMM-B-011"]);
  textNode(area, `100% DPI 实测：${RUNTIME_BASELINES.today.join("×")}；PRD 历史参考：${PRD_REFERENCE_SIZES.today.join("×")}\n${ACTUAL_IMPLEMENTATION.todayScene}`, 540, 910, "caption", COLORS.muted, 1200);
  contractGrid(area, "today", 28, 966, 5064, contractIds); markScreen(win); return y + areaHeight + GROUP_GAP;
}

function wizardStep(area, targetId, step, title, subtitle, x) {
  const width = RUNTIME_BASELINES.wizard[0]; const height = RUNTIME_BASELINES.wizard[1]; const win = target(nodeFrame(area, `Wizard / step ${step}`, x, 264, width, height, { fill: COLORS.paper, stroke: COLORS.lineStrong, radius: 14, shadow: "window", clip: true }), targetId, `开始配置 · 第 ${step} 步`); rectangle(win, "Top bar", 0, 0, width, 49, { fill: COLORS.paper }); divider(win, 0, 48, width); rectangle(win, "Sidebar", 0, 49, 188, height - 106, { fill: COLORS.cool }); rectangle(win, "Sidebar divider", 187, 49, 1, height - 106, { fill: COLORS.line }); textNode(win, "开始配置", 20, 70, "heading", COLORS.ink); textNode(win, "四步完成收入进度", 20, 98, "caption", COLORS.muted);
  const labels = ["收入与休息", "上班时间", "午休时长", "确认配置"]; labels.forEach((label, index) => { const sy = 136 + index * 44; rectangle(win, `Step ${index + 1}`, 20, sy, 24, 24, { fill: index + 1 < step ? COLORS.mint : index + 1 === step ? COLORS.coin : COLORS.paper, stroke: index + 1 <= step ? (index + 1 < step ? COLORS.mint : COLORS.coinStrong) : COLORS.lineStrong, radius: 12 }); textNode(win, index + 1 < step ? "✓" : String(index + 1), 20, sy + 3, "caption", index + 1 <= step ? COLORS.white : COLORS.muted, 24, { align: "CENTER" }); textNode(win, label, 54, sy + 3, "body", index + 1 === step ? COLORS.ink : COLORS.muted); }); textNode(win, "配置仅保存在本机", 20, 434, "caption", COLORS.sageDeep);
  textNode(win, `第 ${step} 步，共 4 步`, 222, 66, "caption", COLORS.muted); textNode(win, title, 222, 98, "title", COLORS.ink); textNode(win, subtitle, 222, 134, "body", COLORS.muted, 464); divider(win, 222, 176, 464); divider(win, 0, 462, width); return win;
}

function buildWizardSection(root, y) {
  const contractIds = CONTROL_SPECS.filter((item) => item.area === "首次配置").map((item) => item.id);
  const areaHeight = contractSectionHeight(900, contractIds);
  const area = section(root, "03", "首次配置 Wizard", "四步渐进式配置，所有退出路径都必须恢复进入前配置与宠物运行态。", y, areaHeight);
  [1, 2, 3, 4].forEach((step, index) => { flowCard(area, `T-WIZARD-${step}`, `步骤 ${step}`, ["收入与休息", "上班时间", "午休时长", "确认配置"][index], 28 + index * 330, 110); if (index < 3) arrow(area, 288 + index * 330, 152, 80, "下一步"); });
  phaseHeading(area, "A", "可编辑原型", "四个真实步骤共享同一配置草稿和视觉组件。", 28, 222, "purple");
  const w1 = wizardStep(area, "T-WIZARD-1", 1, "你的月薪是多少？", "先填写收入，再选择休息模式；工作时间会在下一步推算。", 28); controlButton(w1, "LMM-B-020", "×", 664, 8, 36, "ghost"); controlInput(w1, "LMM-B-021", "月薪", "10,000", 222, 200, 210, "focus"); controlSelect(w1, "LMM-B-022", "休息模式", "双休", 454, 200, 212); controlSelect(w1, "LMM-B-023", "本周类型（大小周时显示）", "小周", 222, 278, 210); const estimate = nodeFrame(w1, "Estimated workdays", 222, 356, 464, 54, { fill: COLORS.mintSoft, radius: 10 }); textNode(estimate, "预计本月工作日", 16, 17, "caption", COLORS.sageDeep); textNode(estimate, "23 天", 384, 15, "label", COLORS.sageDeep, 64, { align: "RIGHT" }); controlButton(w1, "LMM-B-034", "取消", 206, 474, 92, "ghost"); controlButton(w1, "LMM-B-024", "下一步", 596, 474, 96);
  const w2 = wizardStep(area, "T-WIZARD-2", 2, "几点开始工作？", "默认按 8 小时有效工时推算完整安排。", 766); controlInput(w2, "LMM-B-025", "上班时间", "08:00", 222, 200, 210, "focus"); const auto2 = nodeFrame(w2, "Auto inference", 222, 286, 464, 132, { fill: COLORS.warm, stroke: COLORS.line, radius: 10 }); textNode(auto2, "自动推算", 16, 14, "label", COLORS.sageDeep); textNode(auto2, "午休时长       2 小时\n午休区间       12:00–14:00\n下班时间       18:00\n有效工时       8 小时", 16, 42, "body", COLORS.muted, 432, { line: 20 }); controlButton(w2, "LMM-B-026", "上一步", 492, 474, 92, "secondary"); controlButton(w2, "LMM-B-027", "下一步", 596, 474, 96);
  const w3 = wizardStep(area, "T-WIZARD-3", 3, "午休怎么安排？", "默认 12:00 开始；修改开始时间时保持午休总时长。", 1504); controlInput(w3, "LMM-B-028", "午休开始", "12:00", 222, 200, 210); controlSelect(w3, "LMM-B-029", "午休时长", "2 小时", 454, 200, 212); const auto3 = nodeFrame(w3, "Lunch inference", 222, 306, 464, 76, { fill: COLORS.mintSoft, radius: 10 }); textNode(auto3, "预计午休区间", 16, 26, "caption", COLORS.sageDeep); textNode(auto3, "12:00–14:00 · 下班 18:00", 192, 24, "label", COLORS.sageDeep, 256, { align: "RIGHT" }); controlButton(w3, "LMM-B-030", "上一步", 492, 474, 92, "secondary"); controlButton(w3, "LMM-B-031", "下一步", 596, 474, 96);
  const w4 = wizardStep(area, "T-WIZARD-4", 4, "确认你的工作安排", "核对收入、作息和桌宠；完成后一次性安全写入。", 2242); controlSelect(w4, "LMM-B-032", "桌宠伙伴", "Classic Pro", 222, 200, 240); const summary = nodeFrame(w4, "Configuration summary", 222, 286, 464, 132, { fill: COLORS.warm, stroke: COLORS.line, radius: 10 }); textNode(summary, "月薪  ¥10,000     休息模式  双休\n上班  08:00       午休  12:00–14:00\n下班  18:00       有效工时  8 小时", 16, 22, "body", COLORS.ink, 432, { line: 30 }); controlButton(w4, "LMM-B-033", "完成配置", 572, 474, 120); controlButton(w4, "LMM-B-034", "取消", 206, 474, 92, "ghost");
  [[w1, 28, ["LMM-B-020", "LMM-B-021", "LMM-B-022", "LMM-B-023", "LMM-B-024", "LMM-B-034"]], [w2, 766, ["LMM-B-025", "LMM-B-026", "LMM-B-027"]], [w3, 1504, ["LMM-B-028", "LMM-B-029", "LMM-B-030", "LMM-B-031"]], [w4, 2242, ["LMM-B-032", "LMM-B-033", "LMM-B-034"]]].forEach((item) => contractReference(area, item[1], 800, 720, item[2]));
  textNode(area, `100% DPI 实测：${RUNTIME_BASELINES.wizard.join("×")}；PRD 历史参考：${PRD_REFERENCE_SIZES.wizard.join("×")}；侧栏 188 · 顶栏 49 · 操作栏 57`, 28, 850, "caption", COLORS.muted, 1400);
  contractGrid(area, "wizard", 28, 900, 5064, contractIds); [w1, w2, w3, w4].forEach(markScreen); return y + areaHeight + GROUP_GAP;
}

function settingsShell(area, targetId, active, title, subtitle, x, y, sectionLabel = "设置") {
  const width = RUNTIME_BASELINES.settings[0]; const height = RUNTIME_BASELINES.settings[1]; const win = target(nodeFrame(area, `Settings / ${title}`, x, y, width, height, { fill: COLORS.paper, stroke: COLORS.lineStrong, radius: 14, shadow: "window", clip: true }), targetId, title); rectangle(win, "Tab bar", 0, 0, width, 49, { fill: COLORS.paper }); divider(win, 0, 48, width); const tabs = [["工资", "LMM-B-041"], ["作息", "LMM-B-042"], ["桌宠", "LMM-B-043"], ["显示", "LMM-B-044"], ["通用", "LMM-B-045"]]; tabs.forEach((item, index) => { const node = controlButton(win, item[1], item[0], 20 + index * 66, 0, 64, index === active ? "primary" : "ghost"); node.resize(64, 49); node.cornerRadius = 0; }); controlButton(win, "LMM-B-040", "×", 656, 8, 32, "ghost"); textNode(win, title, 28, 70, "title", COLORS.ink); textNode(win, subtitle, 28, 102, "caption", COLORS.muted, 620); textNode(win, sectionLabel, 28, 130, "caption", COLORS.sageDeep); divider(win, 28, 150, width - 56); return win;
}

function settingsFooter(win, statusText = "没有未保存的更改") { const width = RUNTIME_BASELINES.settings[0]; divider(win, 0, 462, width); const statusColor = statusText.includes("失败") ? COLORS.danger : statusText.includes("成功") || statusText.includes("已保存") ? COLORS.sageDeep : COLORS.muted; textNode(win, statusText, 28, 484, "caption", statusColor, 350); controlButton(win, "LMM-B-070", "恢复默认", 402, 473, 92, "secondary"); controlButton(win, "LMM-B-072", "取消", 504, 473, 92, "ghost"); controlButton(win, "LMM-B-071", "保存", 606, 473, 92); }

function buildSettingsSection(root, y) {
  const contractIds = CONTROL_SPECS.filter((item) => item.area === "偏好设置").map((item) => item.id);
  const areaHeight = contractSectionHeight(900, contractIds);
  const area = section(root, "04", "偏好设置 Settings", "五个真实页签与保存成功、无变化、失败状态；Panel 设置构建器当前不可达，标为待确认而不伪造页签。", y, areaHeight);
  const flow = [["T-SETTINGS-SALARY", "工资"], ["T-SETTINGS-SCHEDULE", "作息"], ["T-SETTINGS-PET", "桌宠"], ["T-SETTINGS-DISPLAY", "显示"], ["T-SETTINGS-GENERAL", "通用"]]; flow.forEach((item, index) => { flowCard(area, item[0], item[1], "同一设置壳内切换", 28 + index * 330, 110); if (index < flow.length - 1) arrow(area, 288 + index * 330, 152, 80, "页签"); });
  phaseHeading(area, "A", "可编辑原型", "五个真实页签、反馈状态与系统确认边界。", 28, 222, "purple");
  const s1 = settingsShell(area, "T-SETTINGS-SALARY", 0, "工资设置", "收入小票的计算来源。", 28, 264, "基础收入"); settingsInputRow(s1, "LMM-B-046", "月薪", "10,000", 156, 104); settingsSelectRow(s1, "LMM-B-047", "休息模式", "双休", 204, 124); settingsSelectRow(s1, "LMM-B-048", "本周类型", "小周", 252, 124); const daily = nodeFrame(s1, "Read only daily hours", 28, 318, 644, 46, { fill: COLORS.mintSoft, radius: 8 }); textNode(daily, "每日有效工时", 14, 14, "caption", COLORS.sageDeep); textNode(daily, "8.0 小时（只读）", 474, 12, "label", COLORS.sageDeep, 156, { align: "RIGHT" }); settingsFooter(s1);
  const s2 = settingsShell(area, "T-SETTINGS-SCHEDULE", 1, "作息设置", "默认 8 小时有效工时，午休不计入。", 746, 264, "工作安排"); settingsInputRow(s2, "LMM-B-049", "上班时间", "08:00", 156, 76); settingsInputRow(s2, "LMM-B-050", "午休开始", "12:00", 204, 76); settingsSelectRow(s2, "LMM-B-051", "午休时长", "2 小时", 252, 100); const autoSchedule = nodeFrame(s2, "Schedule inference", 28, 318, 644, 46, { fill: COLORS.mintSoft, radius: 8 }); textNode(autoSchedule, "自动推算", 14, 14, "caption", COLORS.sageDeep); textNode(autoSchedule, "午休结束 14:00 · 下班 18:00 · 有效工时 8 小时", 184, 12, "label", COLORS.sageDeep, 446, { align: "RIGHT" }); settingsFooter(s2, "保存成功。");
  const s3 = settingsShell(area, "T-SETTINGS-PET", 2, "桌宠设置", "选择伙伴与状态感知行为。", 1464, 264, "伙伴"); settingsSelectRow(s3, "LMM-B-052", "当前宠物", "Classic Pro", 156, 164); settingsToggleRow(s3, "LMM-B-053", "状态感知动作", 204, true); settingsButtonRow(s3, "LMM-B-053", "回滚默认宠物", "↶ 恢复", 252, 104, "secondary"); textNode(s3, "宠物资源损坏时会自动回退，不影响收入计算与窗口找回。", 28, 326, "caption", COLORS.muted, 644); settingsFooter(s3);
  const s4 = settingsShell(area, "T-SETTINGS-DISPLAY", 3, "显示设置", "调整桌面挂件的比例与窗口行为。", 2182, 264, "视觉"); settingsSliderRow(s4, "LMM-B-054", "透明度", 156, 1, "100%"); settingsSliderRow(s4, "LMM-B-055", "缩放", 204, 0.5, "100%"); settingsSelectRow(s4, "LMM-B-056", "窗口模式", "置顶悬浮", 252, 136); settingsToggleRow(s4, "LMM-B-057", "纯桌宠模式", 300, false); textNode(s4, "点击穿透由透明区域自动计算；菜单与模态窗口打开时暂停。", 28, 368, "caption", COLORS.muted, 644); settingsFooter(s4, "保存失败：无法写入配置，输入已保留");
  const s5 = settingsShell(area, "T-SETTINGS-GENERAL", 4, "通用设置", "系统、诊断和更新。", 2900, 264, "系统"); const generalViewport = nodeFrame(s5, "Scrollable general viewport", 0, 151, 700, 311, { fill: COLORS.paper, clip: true }); settingsToggleRow(generalViewport, "LMM-B-058", "Debug 日志", 0, false); settingsToggleRow(generalViewport, "LMM-B-059", "开机自启", 48, false); settingsToggleRow(generalViewport, "LMM-B-060", "关闭时隐藏到托盘", 96, true); settingsButtonRow(generalViewport, "LMM-B-061", "窗口位置", "重置位置", 144, 112); settingsButtonRow(generalViewport, "LMM-B-062", "显示设置", "恢复默认", 192, 112); settingsButtonRow(generalViewport, "LMM-B-063", "本地数据", "打开目录", 240, 112, "ghost"); settingsButtonRow(generalViewport, "LMM-B-064", "诊断摘要", "复制摘要", 288, 112, "ghost"); settingsSelectRow(generalViewport, "LMM-B-065", "更新通道", "测试通道", 336, 124); settingsToggleRow(generalViewport, "LMM-B-066", "启动时检查", 384, true); settingsButtonRow(generalViewport, "LMM-B-067", "版本更新", "立即检查", 432, 112); settingsButtonRow(generalViewport, "LMM-B-068", "下载更新", "开始下载", 480, 112); settingsButtonRow(generalViewport, "LMM-B-069", "下载任务", "取消下载", 528, 112, "ghost"); rectangle(generalViewport, "Scrollbar thumb", 694, 12, 4, 86, { fill: COLORS.lineStrong, radius: 2 }); settingsFooter(s5);
  const saveStates = nodeFrame(area, "Settings feedback and confirmation states", 3618, 264, 1474, 520, { fill: COLORS.warm, stroke: COLORS.line, radius: 14 }); textNode(saveStates, "真实反馈与确认状态", 24, 22, "title", COLORS.ink); const states = [["保存成功。", "配置与运行态已同步", "implemented"], ["没有需要保存的更改。", "不写磁盘，2–3 秒后隐藏", "implemented"], ["保存失败：temp_open_failed", "输入保留，旧配置与注册表不污染", "pending"]]; states.forEach((item, index) => { const card = nodeFrame(saveStates, item[0], 24, 72 + index * 76, 690, 60, { fill: COLORS.paper, stroke: item[2] === "pending" ? COLORS.danger : COLORS.line, radius: 8 }); chip(card, item[0], 14, 10, item[2]); textNode(card, item[1], 14, 38, "caption", COLORS.muted, 650); }); const modalState = nodeFrame(saveStates, "Restore display confirmation", 738, 72, 712, 260, { fill: COLORS.ink, radius: 10, clip: true }); modalState.opacity = 0.88; const confirm = nodeFrame(modalState, "ConfirmationDialog", 96, 62, 520, 138, { fill: COLORS.paper, stroke: COLORS.lineStrong, radius: 12, shadow: "floating" }); textNode(confirm, "恢复默认显示设置", 20, 16, "heading", COLORS.ink); textNode(confirm, "将恢复透明度、缩放与窗口模式。", 20, 52, "body", COLORS.muted, 480); controlButton(confirm, "LMM-B-070", "Cancel", 302, 92, 92, "ghost"); controlButton(confirm, "LMM-B-070", "OK", 406, 92, 92); textNode(saveStates, "100% DPI 实测：确认框仍显示系统英文 OK / Cancel；属于待本地化事实，不在原型中伪装已修复。", 738, 350, "caption", COLORS.danger, 690);
  [[s1, 28, ["LMM-B-040", "LMM-B-041", "LMM-B-046", "LMM-B-047", "LMM-B-048", "LMM-B-070", "LMM-B-071", "LMM-B-072"]], [s2, 746, ["LMM-B-042", "LMM-B-049", "LMM-B-050", "LMM-B-051", "LMM-B-070", "LMM-B-071", "LMM-B-072"]], [s3, 1464, ["LMM-B-043", "LMM-B-052", "LMM-B-053", "LMM-B-070", "LMM-B-071", "LMM-B-072"]], [s4, 2182, ["LMM-B-044", "LMM-B-054", "LMM-B-055", "LMM-B-056", "LMM-B-057", "LMM-B-070", "LMM-B-071", "LMM-B-072"]], [s5, 2900, ["LMM-B-045", "LMM-B-058", "LMM-B-059", "LMM-B-060", "LMM-B-061", "LMM-B-062", "LMM-B-063", "LMM-B-064", "LMM-B-065", "LMM-B-066", "LMM-B-067", "LMM-B-068", "LMM-B-069", "LMM-B-070", "LMM-B-071", "LMM-B-072"]]].forEach((item) => contractReference(area, item[1], 800, 700, item[2]));
  textNode(area, `100% DPI 实测：${RUNTIME_BASELINES.settings.join("×")}；PRD 历史参考：${PRD_REFERENCE_SIZES.settings.join("×")}；内容边距 28 · 行高约 48 · 操作栏 57`, 28, 850, "caption", COLORS.muted, 1500);
  contractGrid(area, "settings", 28, 900, 5064, contractIds); [s1, s2, s3, s4, s5].forEach(markScreen); return y + areaHeight + GROUP_GAP;
}

function menuWindow(parent, title, x, y, rows, tray = false) { const width = RUNTIME_BASELINES.menu[0]; const rowHeight = RUNTIME_BASELINES.menu[1]; const height = 52 + rows.length * rowHeight; const win = target(nodeFrame(parent, title, x, y, width, height, { fill: COLORS.paper, stroke: tray ? COLORS.nativeInk : COLORS.lineStrong, radius: 10, shadow: "floating", clip: true }), tray ? "WINDOWS-NATIVE-TRAY" : `T-${title.toUpperCase().replaceAll(" ", "-")}`, title); textNode(win, title, 14, 12, "label", tray ? COLORS.nativeInk : COLORS.ink); divider(win, 0, 43, width); rows.forEach((row, index) => { const item = attachContract(nodeFrame(win, `Menu item / ${row[1]}`, 0, 44 + index * rowHeight, width, rowHeight, { fill: row[2] ? COLORS.coinSoft : COLORS.paper }), row[0]); textNode(item, row[1], 14, 8, "body", row[3] ? COLORS.danger : COLORS.ink, width - 48); if (row[4]) textNode(item, "›", width - 30, 7, "body", COLORS.muted, 18, { align: "CENTER" }); }); return win; }

function buildMenuSection(root, y) {
  const contractIds = CONTROL_SPECS.filter((item) => item.area === "菜单与找回").map((item) => item.id);
  const areaHeight = contractSectionHeight(820, contractIds);
  const area = section(root, "05", "菜单、托盘、纯桌宠与窗口找回", "Godot PopupMenu 与 Windows 原生通知区分层；所有菜单打开期间暂停点击穿透。", y, areaHeight);
  flowCard(area, "T-PET-MENU", "桌宠右键", "产品命令入口", 28, 110); arrow(area, 288, 152, 90, "二级菜单"); flowCard(area, "WINDOWS-NATIVE-TRAY", "原生托盘", "显隐与找回", 382, 110, "native"); arrow(area, 642, 152, 90, "纯桌宠"); flowCard(area, "T-PURE-PET", "纯桌宠模式", "无任务栏入口，托盘仍可找回", 736, 110);
  phaseHeading(area, "A", "可编辑原型", "Godot 菜单、Windows 原生菜单和恢复路径。", 28, 222, "purple");
  const petMenu = menuWindow(area, "桌宠菜单", 28, 264, [["LMM-B-080", "今日详情", true], ["LMM-B-081", "偏好设置"], ["LMM-B-082", "重新运行向导"], ["LMM-B-083", "窗口模式", false, false, true], ["LMM-B-085", "选择宠物", false, false, true], ["LMM-B-086", "关于 LetsMakeMoney"], ["LMM-B-087", "隐藏到托盘"], ["LMM-B-088", "退出", false, true]]);
  const sub = menuWindow(area, "窗口模式", 280, 264, [["LMM-B-083", "置顶悬浮", true], ["LMM-B-084", "嵌入桌面"]]); const tray = menuWindow(area, "原生托盘菜单", 532, 264, [["LMM-B-089", "显示 / 隐藏窗口", true], ["LMM-B-090", "偏好设置"], ["LMM-B-086", "关于"], ["LMM-B-091", "退出", false, true]], true);
  const pure = target(nodeFrame(area, "Pure pet recovery path", 784, 264, 798, 320, { fill: COLORS.cool, stroke: COLORS.nativeInk, radius: 14 }), "T-PURE-PET", "纯桌宠恢复路径"); textNode(pure, "纯桌宠窗口策略", 20, 20, "title", COLORS.ink); chip(pure, "Windows 原生边界", 538, 18, "native"); textNode(pure, "显示时：桌宠可见，任务栏无 LetsMakeMoney 入口\n隐藏时：进程与托盘图标保留\n托盘左键：隐藏 ↔ 恢复，并强制重应用 taskbar/window_policy\nSettings/Wizard：打开期间暂时恢复可操作窗口，关闭后重应用纯桌宠策略", 20, 72, "body", COLORS.muted, 748, { line: 30 });
  contractReference(area, 28, 620, 734, ["LMM-B-080", "LMM-B-081", "LMM-B-082", "LMM-B-083", "LMM-B-084", "LMM-B-085", "LMM-B-086", "LMM-B-087", "LMM-B-088"]); contractReference(area, 784, 620, 798, ["LMM-B-089", "LMM-B-090", "LMM-B-091"]);
  textNode(area, `100% DPI 代码/运行合同：${ACTUAL_IMPLEMENTATION.menu}\n托盘：${ACTUAL_IMPLEMENTATION.tray}`, 28, 672, "caption", COLORS.muted, 1500);
  contractGrid(area, "menus", 28, 820, 5064, contractIds); [petMenu, sub, tray].forEach(markScreen); return y + areaHeight + GROUP_GAP;
}

function buildSupportSection(root, y) {
  const contractIds = CONTROL_SPECS.filter((item) => ["关于与更新", "系统反馈"].includes(item.area)).map((item) => item.id);
  const areaHeight = contractSectionHeight(914, contractIds);
  const area = section(root, "06", "关于、诊断、更新与失败回退", "真实用户可见反馈；Windows shell、剪贴板、安装器和 native 能力明确标注系统边界。", y, areaHeight);
  flowCard(area, "T-ABOUT", "关于", "许可与版本身份", 28, 110); arrow(area, 288, 152, 90, "支持"); flowCard(area, "T-DIAGNOSTICS", "诊断", "本地数据与摘要", 382, 110); arrow(area, 642, 152, 90, "更新"); flowCard(area, "T-UPDATE", "更新", "下载、取消与安装确认", 736, 110, "native");
  phaseHeading(area, "A", "可编辑原型", "关于、诊断、更新和三类用户可见回退状态。", 28, 222, "purple");
  const about = windowShell(area, "T-ABOUT", "关于 LetsMakeMoney", 28, 264, RUNTIME_BASELINES.about[0], RUNTIME_BASELINES.about[1]); textNode(about, "LetsMakeMoney", 24, 76, "title", COLORS.ink); textNode(about, "v0.9 Beta · Windows x86_64\nMIT 代码许可 · 受限视觉素材许可", 24, 116, "body", COLORS.muted, 360, { line: 26 }); controlButton(about, "LMM-B-100", "查看许可证", 24, 190, 140, "secondary"); controlButton(about, "LMM-B-101", "关闭", 288, 224, 104);
  const update = windowShell(area, "T-UPDATE", "发现新版本", 470, 264, 500, 360); chip(update, "Windows 原生边界", 294, 62, "native"); textNode(update, "v0.9.1 Beta 可用", 24, 82, "title", COLORS.ink); textNode(update, "下载完成后将校验 SHA256 和 Authenticode 发布者。安装前必须再次确认。", 24, 124, "body", COLORS.muted, 452); const progress = nodeFrame(update, "Download state", 24, 184, 452, 74, { fill: COLORS.warm, radius: 10 }); textNode(progress, "正在下载  64%", 14, 14, "label", COLORS.ink); rectangle(progress, "Track", 14, 48, 424, 6, { fill: COLORS.line, radius: 3 }); rectangle(progress, "Fill", 14, 48, 271, 6, { fill: COLORS.coin, radius: 3 }); controlButton(update, "LMM-B-069", "取消下载", 24, 286, 116, "ghost"); controlButton(update, "LMM-B-102", "安装更新", 354, 286, 122); controlButton(update, "LMM-B-103", "稍后", 244, 286, 96, "secondary");
  const diag = windowShell(area, "T-DIAGNOSTICS", "诊断与支持", 992, 264, 500, 360); textNode(diag, "本地数据与日志", 24, 78, "heading", COLORS.ink); textNode(diag, "诊断摘要会脱敏用户名和用户目录；不会上传数据。", 24, 112, "body", COLORS.muted, 452); controlButton(diag, "LMM-B-063", "打开数据目录", 24, 172, 140, "secondary"); controlButton(diag, "LMM-B-064", "复制诊断摘要", 176, 172, 152); const status = nodeFrame(diag, "Diagnostic feedback", 24, 238, 452, 66, { fill: COLORS.mintSoft, radius: 10 }); textNode(status, "已复制诊断摘要", 14, 12, "label", COLORS.sageDeep); textNode(status, "立即读回不确定只记诊断日志，不再误报失败。", 14, 36, "caption", COLORS.sageDeep, 420);
  const recoveries = [["T-CONFIG-RECOVERY", "配置损坏已恢复", "已从 previous/backup 恢复有效配置。", "LMM-B-104", "打开数据目录", "LMM-B-105", "知道了"], ["T-NATIVE-DEGRADED", "原生能力不可用", "托盘/点击穿透降级；主功能继续可用。", "LMM-B-106", "查看诊断", "LMM-B-105", "关闭"], ["T-PET-FALLBACK", "宠物包已回退", "资源损坏，已恢复 v0.8 默认宠物。", "LMM-B-107", "恢复默认宠物", "LMM-B-105", "关闭"]]; recoveries.forEach((item, index) => { const card = target(nodeFrame(area, item[0], 28 + index * 508, 678, 480, 210, { fill: COLORS.paper, stroke: index === 0 ? COLORS.coinStrong : index === 1 ? COLORS.nativeInk : COLORS.danger, radius: 12 }), item[0], item[1]); textNode(card, item[1], 18, 18, "heading", COLORS.ink); textNode(card, item[2], 18, 54, "body", COLORS.muted, 444); controlButton(card, item[3], item[4], 18, 140, 160, index === 1 ? "secondary" : "primary"); controlButton(card, item[5], item[6], 348, 140, 104, "ghost"); });
  contractReference(area, 28, 564, 420, ["LMM-B-100", "LMM-B-101"]); contractReference(area, 470, 642, 500, ["LMM-B-069", "LMM-B-102", "LMM-B-103"]); contractReference(area, 992, 642, 500, ["LMM-B-063", "LMM-B-064"]); textNode(area, `关于窗口：${ACTUAL_IMPLEMENTATION.about}`, 28, 612, "caption", COLORS.muted, 420);
  contractGrid(area, "support", 28, 914, 5064, contractIds); [about, update, diag].forEach(markScreen); return y + areaHeight + GROUP_GAP;
}

function buildAnimationSection(root, y) {
  const area = section(root, "07", "产品可见的宠物动作与回退", "动画作为桌宠产品状态的一部分展示，不再保留独立动画合同页面。", y, 900);
  phaseHeading(area, "A", "产品可见状态", "基础状态、互动动作、业务事件和安全回退均留在产品链路中。", 28, 102, "purple");
  const states = [["working", images.classicWorking, "工作循环 / making-money"], ["awake_rest", images.classicAwake, "清醒休息 / eating-idle"], ["sleeping", images.classicSleeping, "夜间睡眠"], ["多多 working", images.duoduoWorking, "同一通用包合同"], ["多多 awake_rest", images.duoduoAwake, "无 pet_id 特判"], ["多多 sleeping", images.duoduoSleeping, "资源损坏安全回退"]];
  states.forEach((item, index) => { const x = 28 + index * 338; const card = nodeFrame(area, `Visible pet state / ${item[0]}`, x, 144, 310, 350, { fill: COLORS.paper, stroke: COLORS.line, radius: 8 }); imageRect(card, item[1], item[0], 30, 24, 250, 230); textNode(card, item[0], 18, 270, "heading", COLORS.ink); textNode(card, item[2], 18, 304, "caption", COLORS.muted, 274); });
  const actions = nodeFrame(area, "Visible action rules", 2060, 144, 1460, 350, { fill: COLORS.warm, stroke: COLORS.line, radius: 8 }); textNode(actions, "动作语义", 24, 22, "title", COLORS.ink); textNode(actions, "基础：working / awake_rest / sleeping\n单击：working_ack / rest_ack / sleep_ack（与基础状态关联）\n长按拖拽：run_prepare → 水平移动与镜像 → run_stop\n业务事件：lunch_relief / lunch_return / celebration\n环境动作：pointer_follow（B 方案，低频；无高频逐帧重算）\n回退：目标动作 → 同基础状态通用动作 → 旧动作映射 → v0.8 默认宠物", 24, 78, "body", COLORS.muted, 1380, { line: 34 });
  const boundary = nodeFrame(area, "Implementation boundary", 3540, 144, 1552, 350, { fill: COLORS.cool, stroke: COLORS.nativeInk, radius: 8 }); textNode(boundary, "实现边界", 24, 22, "title", COLORS.ink); textNode(boundary, "状态机、输入仲裁、动态命中区和资源回退", 24, 76, "body", COLORS.muted); textNode(boundary, "Classic Pro 最终默认切换仍需 Play-first 素材门禁", 24, 116, "body", COLORS.muted); chip(boundary, "Windows 原生边界", 24, 158, "native"); textNode(boundary, "动态点击穿透由 native bridge 消费命中矩形", 180, 161, "body", COLORS.muted); textNode(boundary, "素材许可、包 schema、逐帧时长、锚点、脚底线和 SHA256 由 PetManager 交付合同约束。", 24, 224, "body", COLORS.muted, 1480);
  return y + 918;
}

function createComponent(parent, name, x, y, width, height, draw) { const component = figma.createComponent(); component.name = `LMM/${name}`; component.resize(width, height); component.x = x; component.y = y; component.clipsContent = false; component.fills = []; parent.appendChild(component); draw(component); return component; }

function buildDesignSystem(root, y) {
  const area = section(root, "08", "变量、样式与紧凑组件注册区", "单页底部集中设计系统；业务契约仍跟随各自界面。", y, 1080);
  const swatches = Object.entries(COLORS).slice(0, 18); swatches.forEach(([name, value], index) => { const x = 28 + (index % 9) * 264; const sy = 126 + Math.floor(index / 9) * 96; const card = nodeFrame(area, `Color / ${name}`, x, sy, 240, 78, { fill: COLORS.paper, stroke: COLORS.line, radius: 10 }); rectangle(card, name, 10, 10, 58, 58, { fill: value, radius: 8 }); textNode(card, name, 82, 16, "label", COLORS.ink); textNode(card, value, 82, 42, "caption", COLORS.muted); });
  const typeCard = nodeFrame(area, "Typography", 2430, 126, 860, 270, { fill: COLORS.paper, stroke: COLORS.line, radius: 12 }); textNode(typeCard, "Display 36 / 44", 24, 22, "display", COLORS.ink); textNode(typeCard, "Title 24 / 32", 24, 82, "title", COLORS.ink); textNode(typeCard, "Heading 18 / 26", 24, 128, "heading", COLORS.ink); textNode(typeCard, "Body 14 / 22 · Label 13 / 18 · Caption 12 / 18", 24, 176, "body", COLORS.muted); textNode(typeCard, "数字使用等宽数字能力时由 Godot 字体主题提供；中文优先 Noto Sans SC / 微软雅黑。", 24, 220, "caption", COLORS.muted, 812);
  const registry = nodeFrame(area, "Compact component registry", 28, 430, 5064, 610, { fill: COLORS.paper, stroke: COLORS.line, radius: 14 }); textNode(registry, "Warm Fluent Compact / 组件注册", 24, 24, "title", COLORS.ink); createComponent(registry, "Button/Primary", 24, 82, 104, 38, (node) => { applyFill(node, COLORS.coin); applyStroke(node, COLORS.coinStrong); node.cornerRadius = 8; textNode(node, "保存", 0, 9, "label", COLORS.ink, 104, { align: "CENTER" }); }); createComponent(registry, "Button/Secondary", 154, 82, 104, 38, (node) => { applyFill(node, COLORS.paper); applyStroke(node, COLORS.lineStrong); node.cornerRadius = 8; textNode(node, "取消", 0, 9, "label", COLORS.ink, 104, { align: "CENTER" }); }); createComponent(registry, "Input/Default", 284, 82, 180, 36, (node) => { applyFill(node, COLORS.paper); applyStroke(node, COLORS.line); node.cornerRadius = 8; textNode(node, "10,000", 12, 8, "body", COLORS.ink); }); createComponent(registry, "Toggle/On", 490, 88, 40, 22, (node) => { applyFill(node, COLORS.mint); node.cornerRadius = 11; rectangle(node, "Thumb", 19, 2, 18, 18, { fill: COLORS.white, radius: 9 }); });
  textNode(registry, "100% DPI 运行尺寸合同", 24, 164, "heading", COLORS.ink); textNode(registry, `Panel 折叠 ${RUNTIME_BASELINES.panelCollapsed.join("×")} · 展开 ${RUNTIME_BASELINES.panelExpanded.join("×")}\n今日详情 ${RUNTIME_BASELINES.today.join("×")} · Settings ${RUNTIME_BASELINES.settings.join("×")} · Wizard ${RUNTIME_BASELINES.wizard.join("×")}\n菜单最小宽 ${RUNTIME_BASELINES.menu[0]} / 行高 ${RUNTIME_BASELINES.menu[1]} · 关于 ${RUNTIME_BASELINES.about.join("×")}\n区域宽 ${GRID_WIDTH} · 内边距 ${SECTION_PADDING} · 组间距 ${GROUP_GAP} · 顶部对齐`, 24, 204, "body", COLORS.muted, 920, { line: 30 });
  textNode(registry, "运行证据与历史参考", 1020, 164, "heading", COLORS.ink); textNode(registry, `${Object.values(ACTUAL_IMPLEMENTATION).join("\n")}\nPRD 历史参考：Panel ${PRD_REFERENCE_SIZES.panelCollapsed.join("×")} / ${PRD_REFERENCE_SIZES.panelExpanded.join("×")} · Today ${PRD_REFERENCE_SIZES.today.join("×")} · Settings ${PRD_REFERENCE_SIZES.settings.join("×")} · Wizard ${PRD_REFERENCE_SIZES.wizard.join("×")}`, 1020, 204, "body", COLORS.muted, 1400, { line: 26 }); textNode(registry, "DPI 逻辑缩放矩阵", 2540, 164, "heading", COLORS.ink); DPI_SCALE_MATRIX.forEach((item, index) => { const card = nodeFrame(registry, `DPI / ${item.scale}`, 2540 + index * 360, 204, 336, 112, { fill: COLORS.cool, stroke: item.status === "已实测" ? COLORS.mint : COLORS.lineStrong, radius: 10 }); textNode(card, item.scale, 14, 12, "heading", COLORS.ink); textNode(card, `逻辑倍率 ${item.factor.toFixed(2)}\n${item.status}`, 14, 46, "caption", item.status === "已实测" ? COLORS.sageDeep : COLORS.muted, 300, { line: 22 }); }); textNode(registry, "125% / 150% 只按 Godot 逻辑尺寸推导，禁止把 100% 位图直接放大当作验收。", 2540, 338, "caption", COLORS.danger, 1070); textNode(registry, "系统边界", 3700, 164, "heading", COLORS.ink); chip(registry, "Windows 原生边界", 3700, 204, "native"); chip(registry, "待确认", 3870, 204, "pending");
  const allIds = CONTROL_SPECS.map((item) => item.id); registry.setSharedPluginData(OWNER_NAMESPACE, "control-contract-ids", allIds.join(",")); registry.setSharedPluginData(OWNER_NAMESPACE, "control-contract", JSON.stringify(CONTROL_SPECS));
  return y + 1098;
}

function rectanglesOverlap(a, b) {
  return a.x < b.x + b.width && a.x + a.width > b.x && a.y < b.y + b.height && a.y + a.height > b.y;
}

function validateSiblingFrameLayout(parent) {
  const peers = parent.children.filter((node) => ["FRAME", "COMPONENT"].includes(node.type) && node.visible !== false && node.width > 2 && node.height > 2);
  for (let left = 0; left < peers.length; left += 1) {
    for (let right = left + 1; right < peers.length; right += 1) {
      if (rectanglesOverlap(peers[left], peers[right])) throw new Error(`同级模块重叠：${parent.name} / ${peers[left].name} / ${peers[right].name}`);
    }
  }
  for (const child of peers) validateSiblingFrameLayout(child);
}

function validateClippedTextBounds(root) {
  const clippedFrames = root.findAll((node) => node.type === "FRAME" && node.visible !== false && node.clipsContent);
  for (const frame of clippedFrames) {
    const frameBounds = frame.absoluteBoundingBox;
    if (!frameBounds) continue;
    const textNodes = frame.findAll((node) => node.type === "TEXT" && node.visible !== false);
    for (const text of textNodes) {
      let ancestor = text.parent;
      let belongsToScrollableRegion = false;
      while (ancestor && ancestor !== frame) {
        if (ancestor.type === "FRAME" && ancestor.name.startsWith("Scrollable ")) { belongsToScrollableRegion = true; break; }
        ancestor = ancestor.parent;
      }
      if (frame.name.startsWith("Scrollable ") || belongsToScrollableRegion) continue;
      const textBounds = text.absoluteBoundingBox;
      if (!textBounds) continue;
      const outside = textBounds.x < frameBounds.x - 1 || textBounds.y < frameBounds.y - 1 || textBounds.x + textBounds.width > frameBounds.x + frameBounds.width + 1 || textBounds.y + textBounds.height > frameBounds.y + frameBounds.height + 1;
      if (outside) throw new Error(`窗口文字越界：${frame.name} / ${text.name}`);
    }
  }
}

function validateGeneratedLayout(root) {
  const bands = root.children.filter((node) => node.type === "FRAME" && node.visible !== false).sort((a, b) => a.y - b.y);
  for (let index = 1; index < bands.length; index += 1) {
    const previous = bands[index - 1]; const current = bands[index];
    if (previous.y + previous.height > current.y) throw new Error(`顶层区域重叠：${previous.name} → ${current.name}`);
  }
  const boards = root.findAll((node) => node.type === "FRAME" && node.name.endsWith("/ Associated contracts"));
  for (const board of boards) {
    const cards = board.children.filter((node) => node.type === "FRAME" && node.name.startsWith("Contract /"));
    for (const card of cards) {
      if (card.height !== CONTRACT_CARD_HEIGHT) throw new Error(`契约卡高度不一致：${card.name}`);
      const textNodes = card.findAll((node) => node.type === "TEXT");
      for (const text of textNodes) {
        if (text.x < -1 || text.y < -1 || text.x + text.width > card.width + 1 || text.y + text.height > card.height + 1) throw new Error(`契约文字越界：${card.name} / ${text.name}`);
      }
    }
    for (let left = 0; left < cards.length; left += 1) {
      for (let right = left + 1; right < cards.length; right += 1) {
        if (rectanglesOverlap(cards[left], cards[right])) throw new Error(`契约卡重叠：${cards[left].name} / ${cards[right].name}`);
      }
    }
  }
  validateSiblingFrameLayout(root);
  validateClippedTextBounds(root);
  root.setSharedPluginData(OWNER_NAMESPACE, "layout-validation", `bands:${bands.length};boards:${boards.length};contracts:${CONTROL_SPECS.length};sibling-overlaps:0;text-overflows:0`);
}

async function buildAll(assetPayload) {
  postStatus("加载字体并检查页面所有权…"); await chooseFonts(); const prepared = await prepareSinglePage(); postStatus("重建 LMM 变量和样式…"); await resetDesignSystem();
  postStatus("校验并写入 6 张确定性宠物 PNG 关键帧…"); images = { classicWorking: await createVerifiedImage(assetPayload.classicWorking, "Classic working"), classicAwake: await createVerifiedImage(assetPayload.classicAwake, "Classic awake_rest"), classicSleeping: await createVerifiedImage(assetPayload.classicSleeping, "Classic sleeping"), duoduoWorking: await createVerifiedImage(assetPayload.duoduoWorking, "多多 working"), duoduoAwake: await createVerifiedImage(assetPayload.duoduoAwake, "多多 awake_rest"), duoduoSleeping: await createVerifiedImage(assetPayload.duoduoSleeping, "多多 sleeping") };
  const root = owned(nodeFrame(prepared.page, "LMM 01 Full Product Flow / 5120 Grid", 0, 0, DOCUMENT_WIDTH, 1000, { fill: DOC.canvas }), "root/full-product-flow", "structure"); let y = 40; y = buildDocumentCover(root, y); y = buildOverview(root, y); y = buildDesktopSection(root, y); y = buildTodaySection(root, y); y = buildWizardSection(root, y); y = buildSettingsSection(root, y); y = buildMenuSection(root, y); y = buildSupportSection(root, y); y = buildAnimationSection(root, y); y = buildDesignSystem(root, y); root.resize(DOCUMENT_WIDTH, y + 40); root.setSharedPluginData(OWNER_NAMESPACE, "control-contract-ids", CONTROL_SPECS.map((item) => item.id).join(",")); root.setSharedPluginData(OWNER_NAMESPACE, "control-contract", JSON.stringify(CONTROL_SPECS)); root.setSharedPluginData(OWNER_NAMESPACE, "managed-page-count", "1"); validateGeneratedLayout(root);
  await figma.setCurrentPageAsync(prepared.page); figma.currentPage.selection = [root]; figma.viewport.scrollAndZoomIntoView([root]); return { pageCount: 1, contractCount: CONTROL_SPECS.length, warnings: prepared.warnings };
}

figma.showUI(__html__, { width: 420, height: 360, themeColors: true });
figma.ui.onmessage = async (message) => {
  if (!message || message.type !== "build") return;
  try { const result = await buildAll(message.assets); const warningText = result.warnings.length ? `；${result.warnings.join("；")}` : ""; figma.ui.postMessage({ type: "done", text: `完成：${result.pageCount} 个 LMM 管理页，${result.contractCount} 个控件契约${warningText}` }); figma.notify("LetsMakeMoney 单页全链路已更新", { timeout: 3500 }); }
  catch (error) { const detail = error && error.stack ? error.stack : String(error); console.error(detail); figma.ui.postMessage({ type: "error", text: `生成失败：${error.message || String(error)}` }); }
};
