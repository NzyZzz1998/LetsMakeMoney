#include "tray_controller.h"

#ifdef _WIN32

#include <sstream>

TrayController::TrayController() {}

TrayController::~TrayController() {
    shutdown();
}

bool TrayController::setup(const std::wstring &tooltip, const std::wstring &icon_path) {
    shutdown();
    _last_error.clear();

    if (!ensure_message_window()) {
        return false;
    }

    _menu = CreatePopupMenu();
    if (_menu == nullptr) {
        _last_error = L"CreatePopupMenu failed";
        shutdown();
        return false;
    }
    update_menu(true);

    if (!add_icon(tooltip, icon_path)) {
        shutdown();
        return false;
    }

    _ready = true;
    return true;
}

void TrayController::update_menu(bool window_visible) {
    if (_menu == nullptr) {
        return;
    }
    while (GetMenuItemCount(_menu) > 0) {
        DeleteMenu(_menu, 0, MF_BYPOSITION);
    }
    AppendMenuW(_menu, MF_STRING, COMMAND_TOGGLE, window_visible ? L"隐藏窗口" : L"显示窗口");
    AppendMenuW(_menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(_menu, MF_STRING, COMMAND_SETTINGS, L"设置");
    AppendMenuW(_menu, MF_STRING, COMMAND_ABOUT, L"关于 LetsMakeMoney");
    AppendMenuW(_menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(_menu, MF_STRING, COMMAND_EXIT, L"退出");
}

void TrayController::shutdown() {
    if (_ready) {
        Shell_NotifyIconW(NIM_DELETE, &_icon_data);
    }
    _ready = false;
    _pending_command = COMMAND_NONE;
    _left_down_toggle_sent = false;

    if (_menu != nullptr) {
        DestroyMenu(_menu);
        _menu = nullptr;
    }
    if (_icon != nullptr) {
        DestroyIcon(_icon);
        _icon = nullptr;
    }
    if (_message_hwnd != nullptr) {
        DestroyWindow(_message_hwnd);
        _message_hwnd = nullptr;
    }
    ZeroMemory(&_icon_data, sizeof(_icon_data));
}

bool TrayController::is_ready() const {
    return _ready;
}

int TrayController::poll_command() {
    int command = _pending_command;
    _pending_command = COMMAND_NONE;
    return command;
}

std::wstring TrayController::last_error() const {
    return _last_error;
}

bool TrayController::ensure_message_window() {
    const wchar_t *class_name = L"LetsMakeMoneyTrayMessageWindow";
    WNDCLASSW wc = {};
    wc.lpfnWndProc = TrayController::window_proc;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpszClassName = class_name;
    RegisterClassW(&wc);

    _message_hwnd = CreateWindowExW(
        0,
        class_name,
        L"LetsMakeMoneyTray",
        WS_OVERLAPPED,
        0,
        0,
        0,
        0,
        nullptr,
        nullptr,
        wc.hInstance,
        this
    );

    if (_message_hwnd == nullptr) {
        std::wstringstream ss;
        ss << L"CreateWindowExW for tray hidden window failed: " << GetLastError();
        _last_error = ss.str();
        return false;
    }
    SetWindowLongPtrW(_message_hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this));
    return true;
}

bool TrayController::add_icon(const std::wstring &tooltip, const std::wstring &icon_path) {
    _icon = load_icon(icon_path);
    if (_icon == nullptr) {
        _icon = LoadIconW(nullptr, MAKEINTRESOURCEW(32512));
    }

    ZeroMemory(&_icon_data, sizeof(_icon_data));
    _icon_data.cbSize = NOTIFYICONDATAW_V2_SIZE;
    _icon_data.hWnd = _message_hwnd;
    _icon_data.uID = TRAY_UID;
    _icon_data.uFlags = NIF_MESSAGE | NIF_TIP | NIF_ICON;
    _icon_data.uCallbackMessage = TRAY_CALLBACK_MESSAGE;
    _icon_data.hIcon = _icon;
    wcsncpy_s(_icon_data.szTip, tooltip.c_str(), _TRUNCATE);

    if (!Shell_NotifyIconW(NIM_ADD, &_icon_data)) {
        std::wstringstream ss;
        ss << L"Shell_NotifyIconW(NIM_ADD) failed: " << GetLastError();
        _last_error = ss.str();
        return false;
    }
    return true;
}

HICON TrayController::load_icon(const std::wstring &icon_path) {
    if (icon_path.empty()) {
        return nullptr;
    }
    return static_cast<HICON>(LoadImageW(
        nullptr,
        icon_path.c_str(),
        IMAGE_ICON,
        GetSystemMetrics(SM_CXSMICON),
        GetSystemMetrics(SM_CYSMICON),
        LR_LOADFROMFILE
    ));
}

void TrayController::show_menu() {
    if (_menu == nullptr || _message_hwnd == nullptr) {
        return;
    }
    POINT cursor = {};
    GetCursorPos(&cursor);
    SetForegroundWindow(_message_hwnd);
    UINT command = TrackPopupMenu(
        _menu,
        TPM_RETURNCMD | TPM_RIGHTBUTTON,
        cursor.x,
        cursor.y,
        0,
        _message_hwnd,
        nullptr
    );
    if (command != COMMAND_NONE) {
        set_pending_command(static_cast<int>(command));
    }
    PostMessageW(_message_hwnd, WM_NULL, 0, 0);
}

void TrayController::set_pending_command(int command) {
    _pending_command = command;
}

void TrayController::set_toggle_command() {
    DWORD now = GetTickCount();
    if (_last_toggle_tick != 0 && now - _last_toggle_tick < 300) {
        return;
    }
    _last_toggle_tick = now;
    set_pending_command(COMMAND_TOGGLE);
}

void TrayController::set_left_toggle_command() {
    DWORD now = GetTickCount();
    if (_last_toggle_tick != 0 && now - _last_toggle_tick < 300) {
        return;
    }
    _last_toggle_tick = now;
    set_pending_command(COMMAND_LEFT_TOGGLE);
}

LRESULT CALLBACK TrayController::window_proc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
    TrayController *self = reinterpret_cast<TrayController *>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (message == WM_NCCREATE) {
        auto *create = reinterpret_cast<CREATESTRUCTW *>(lparam);
        self = reinterpret_cast<TrayController *>(create->lpCreateParams);
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
    }

    if (self != nullptr && message == TRAY_CALLBACK_MESSAGE) {
        UINT tray_event = LOWORD(lparam);
        UINT tray_icon_id = HIWORD(lparam);
        bool target_icon = wparam == TRAY_UID || tray_icon_id == TRAY_UID;
        if (!target_icon) {
            return DefWindowProcW(hwnd, message, wparam, lparam);
        }
        if (lparam == WM_LBUTTONDOWN || tray_event == WM_LBUTTONDOWN) {
            self->_left_down_toggle_sent = true;
            self->set_left_toggle_command();
            return 0;
        }
        if (lparam == WM_LBUTTONUP || lparam == NIN_SELECT || lparam == NIN_KEYSELECT ||
                tray_event == WM_LBUTTONUP || tray_event == NIN_SELECT || tray_event == NIN_KEYSELECT) {
            if (self->_left_down_toggle_sent) {
                self->_left_down_toggle_sent = false;
                return 0;
            }
            self->set_left_toggle_command();
            return 0;
        }
        if (lparam == WM_LBUTTONDBLCLK || tray_event == WM_LBUTTONDBLCLK) {
            self->_left_down_toggle_sent = false;
            self->set_left_toggle_command();
            return 0;
        }
        if (lparam == WM_RBUTTONDOWN || lparam == WM_RBUTTONUP || lparam == WM_CONTEXTMENU ||
                tray_event == WM_RBUTTONDOWN || tray_event == WM_RBUTTONUP || tray_event == WM_CONTEXTMENU) {
            self->show_menu();
            return 0;
        }
    }
    return DefWindowProcW(hwnd, message, wparam, lparam);
}

#else

TrayController::TrayController() {}
TrayController::~TrayController() {}

bool TrayController::setup(const std::wstring &tooltip, const std::wstring &icon_path) {
    (void)tooltip;
    (void)icon_path;
    _last_error = L"TrayController is only implemented on Windows";
    return false;
}

void TrayController::update_menu(bool window_visible) {
    (void)window_visible;
}

void TrayController::shutdown() {}

bool TrayController::is_ready() const {
    return false;
}

int TrayController::poll_command() {
    return COMMAND_NONE;
}

std::wstring TrayController::last_error() const {
    return _last_error;
}

#endif
