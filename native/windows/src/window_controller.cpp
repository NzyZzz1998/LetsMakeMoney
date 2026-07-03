#include "window_controller.h"

#ifdef _WIN32

namespace {
constexpr wchar_t PASSTHROUGH_CONTROLLER_PROP[] = L"LMMWindowController";
constexpr int HIT_TEST_PADDING = 2;
constexpr int RIGHT_CLICK_PET_CONTEXT_PADDING_X = 70;
constexpr int RIGHT_CLICK_PET_CONTEXT_PADDING_TOP = 86;
constexpr int RIGHT_CLICK_PET_CONTEXT_PADDING_BOTTOM = 58;
}

WindowController::~WindowController() {
    if (_passthrough_hwnd != nullptr && IsWindow(_passthrough_hwnd)) {
        restore_passthrough_subclass(_passthrough_hwnd);
    }
}

bool WindowController::setup_pet_window(int64_t hwnd_value, bool transparent, bool topmost) {
    HWND hwnd = to_hwnd(hwnd_value);
    if (!ensure_valid_window(hwnd)) {
        return false;
    }

    LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_STYLE);
    style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
    style |= WS_POPUP;
    SetWindowLongPtrW(hwnd, GWL_STYLE, style);

    (void)transparent;

    SetWindowPos(
        hwnd,
        topmost ? HWND_TOPMOST : HWND_NOTOPMOST,
        0,
        0,
        0,
        0,
        SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED | SWP_NOACTIVATE
    );

    _last_error.clear();
    return true;
}

bool WindowController::set_window_visible(int64_t hwnd_value, bool visible) {
    HWND hwnd = to_hwnd(hwnd_value);
    if (!ensure_valid_window(hwnd)) {
        return false;
    }

    ShowWindow(hwnd, visible ? SW_SHOWNOACTIVATE : SW_HIDE);
    if (visible) {
        SetWindowPos(
            hwnd,
            HWND_TOPMOST,
            0,
            0,
            0,
            0,
            SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW
        );
    }

    _last_error.clear();
    return true;
}

bool WindowController::set_taskbar_visible(int64_t hwnd_value, bool visible) {
    HWND hwnd = to_hwnd(hwnd_value);
    if (!ensure_valid_window(hwnd)) {
        return false;
    }

    LONG_PTR ex_style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
    if (visible) {
        ex_style &= ~WS_EX_TOOLWINDOW;
        ex_style |= WS_EX_APPWINDOW;
    } else {
        ex_style &= ~WS_EX_APPWINDOW;
        ex_style |= WS_EX_TOOLWINDOW;
    }
    SetWindowLongPtrW(hwnd, GWL_EXSTYLE, ex_style);
    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED | SWP_NOACTIVATE);

    _last_error.clear();
    return true;
}

bool WindowController::set_mouse_passthrough(int64_t hwnd_value, const std::vector<NativeRect> &interactive_rects) {
    HWND hwnd = to_hwnd(hwnd_value);
    if (!ensure_valid_window(hwnd)) {
        return false;
    }
    if (interactive_rects.empty()) {
        return clear_mouse_passthrough(hwnd_value);
    }

    std::vector<NativeRect> valid_rects;
    valid_rects.reserve(interactive_rects.size());
    for (const NativeRect &rect : interactive_rects) {
        if (rect.width <= 0 || rect.height <= 0) {
            continue;
        }
        valid_rects.push_back(rect);
    }

    if (valid_rects.empty()) {
        return clear_mouse_passthrough(hwnd_value);
    }

    if (!install_passthrough_subclass(hwnd)) {
        return false;
    }

    _interactive_rects = valid_rects;
    _last_error.clear();
    return true;
}

bool WindowController::clear_mouse_passthrough(int64_t hwnd_value) {
    HWND hwnd = to_hwnd(hwnd_value);
    if (!ensure_valid_window(hwnd)) {
        return false;
    }
    if (!restore_passthrough_subclass(hwnd)) {
        return false;
    }
    _interactive_rects.clear();
    _last_error.clear();
    return true;
}

std::wstring WindowController::last_error() const {
    return _last_error;
}

HWND WindowController::to_hwnd(int64_t hwnd_value) const {
    return reinterpret_cast<HWND>(static_cast<intptr_t>(hwnd_value));
}

bool WindowController::ensure_valid_window(HWND hwnd) {
    if (hwnd == nullptr || !IsWindow(hwnd)) {
        _last_error = L"Invalid HWND";
        return false;
    }
    return true;
}

bool WindowController::install_passthrough_subclass(HWND hwnd) {
    if (_passthrough_hwnd == hwnd && _original_wnd_proc != nullptr) {
        SetPropW(hwnd, PASSTHROUGH_CONTROLLER_PROP, this);
        return true;
    }

    if (_passthrough_hwnd != nullptr && _passthrough_hwnd != hwnd) {
        restore_passthrough_subclass(_passthrough_hwnd);
    }

    SetPropW(hwnd, PASSTHROUGH_CONTROLLER_PROP, this);
    LONG_PTR previous = SetWindowLongPtrW(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(&WindowController::passthrough_wnd_proc));
    if (previous == 0) {
        RemovePropW(hwnd, PASSTHROUGH_CONTROLLER_PROP);
        _last_error = L"SetWindowLongPtrW GWLP_WNDPROC failed";
        return false;
    }

    _passthrough_hwnd = hwnd;
    _original_wnd_proc = reinterpret_cast<WNDPROC>(previous);
    return true;
}

bool WindowController::restore_passthrough_subclass(HWND hwnd) {
    if (_passthrough_hwnd != hwnd || _original_wnd_proc == nullptr) {
        RemovePropW(hwnd, PASSTHROUGH_CONTROLLER_PROP);
        return true;
    }

    SetWindowLongPtrW(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(_original_wnd_proc));
    RemovePropW(hwnd, PASSTHROUGH_CONTROLLER_PROP);
    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED | SWP_NOACTIVATE);
    _passthrough_hwnd = nullptr;
    _original_wnd_proc = nullptr;
    return true;
}

bool WindowController::is_point_interactive(POINT client_point) const {
    for (const NativeRect &rect : _interactive_rects) {
        int left = rect.x - HIT_TEST_PADDING;
        int top = rect.y - HIT_TEST_PADDING;
        int right = rect.x + rect.width + HIT_TEST_PADDING;
        int bottom = rect.y + rect.height + HIT_TEST_PADDING;
        if (client_point.x >= left && client_point.x <= right && client_point.y >= top && client_point.y <= bottom) {
            return true;
        }
    }
    return false;
}

bool WindowController::is_point_in_pet_context_rect(POINT client_point) const {
    if (_interactive_rects.empty()) {
        return false;
    }

    const NativeRect &rect = _interactive_rects.front();
    int left = rect.x - RIGHT_CLICK_PET_CONTEXT_PADDING_X;
    int top = rect.y - RIGHT_CLICK_PET_CONTEXT_PADDING_TOP;
    int right = rect.x + rect.width + RIGHT_CLICK_PET_CONTEXT_PADDING_X;
    int bottom = rect.y + rect.height + RIGHT_CLICK_PET_CONTEXT_PADDING_BOTTOM;
    return client_point.x >= left && client_point.x <= right && client_point.y >= top && client_point.y <= bottom;
}

LRESULT WindowController::handle_passthrough_message(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
    if (msg == WM_NCHITTEST && !_interactive_rects.empty()) {
        POINT point;
        point.x = GET_X_LPARAM(lparam);
        point.y = GET_Y_LPARAM(lparam);
        if (ScreenToClient(hwnd, &point) && !is_point_interactive(point)) {
            const bool right_button_down = (GetAsyncKeyState(VK_RBUTTON) & 0x8000) != 0;
            if (right_button_down && is_point_in_pet_context_rect(point)) {
                return HTCLIENT;
            }
            return HTTRANSPARENT;
        }
    }

    if (_original_wnd_proc != nullptr) {
        return CallWindowProcW(_original_wnd_proc, hwnd, msg, wparam, lparam);
    }
    return DefWindowProcW(hwnd, msg, wparam, lparam);
}

LRESULT CALLBACK WindowController::passthrough_wnd_proc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
    auto *controller = reinterpret_cast<WindowController *>(GetPropW(hwnd, PASSTHROUGH_CONTROLLER_PROP));
    if (controller != nullptr) {
        return controller->handle_passthrough_message(hwnd, msg, wparam, lparam);
    }
    return DefWindowProcW(hwnd, msg, wparam, lparam);
}

#else

WindowController::~WindowController() {}

bool WindowController::setup_pet_window(int64_t hwnd_value, bool transparent, bool topmost) {
    (void)hwnd_value;
    (void)transparent;
    (void)topmost;
    _last_error = L"WindowController is only implemented on Windows";
    return false;
}

bool WindowController::set_taskbar_visible(int64_t hwnd_value, bool visible) {
    (void)hwnd_value;
    (void)visible;
    _last_error = L"WindowController is only implemented on Windows";
    return false;
}

bool WindowController::set_window_visible(int64_t hwnd_value, bool visible) {
    (void)hwnd_value;
    (void)visible;
    _last_error = L"WindowController is only implemented on Windows";
    return false;
}

bool WindowController::set_mouse_passthrough(int64_t hwnd_value, const std::vector<NativeRect> &interactive_rects) {
    (void)hwnd_value;
    (void)interactive_rects;
    _last_error = L"WindowController is only implemented on Windows";
    return false;
}

bool WindowController::clear_mouse_passthrough(int64_t hwnd_value) {
    (void)hwnd_value;
    _last_error = L"WindowController is only implemented on Windows";
    return false;
}

std::wstring WindowController::last_error() const {
    return _last_error;
}

#endif
