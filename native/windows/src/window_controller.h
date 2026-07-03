#pragma once

#ifdef _WIN32
#include <windows.h>
#include <windowsx.h>
#endif

#include <cstdint>
#include <string>
#include <vector>

struct NativeRect {
    int x = 0;
    int y = 0;
    int width = 0;
    int height = 0;
};

class WindowController {
public:
    ~WindowController();

    bool setup_pet_window(int64_t hwnd_value, bool transparent, bool topmost);
    bool set_window_visible(int64_t hwnd_value, bool visible);
    bool set_mouse_passthrough(int64_t hwnd_value, const std::vector<NativeRect> &interactive_rects);
    bool clear_mouse_passthrough(int64_t hwnd_value);
    bool set_taskbar_visible(int64_t hwnd_value, bool visible);
    std::wstring last_error() const;

private:
#ifdef _WIN32
    HWND to_hwnd(int64_t hwnd_value) const;
    bool ensure_valid_window(HWND hwnd);
    bool install_passthrough_subclass(HWND hwnd);
    bool restore_passthrough_subclass(HWND hwnd);
    bool is_point_interactive(POINT client_point) const;
    bool is_point_in_pet_context_rect(POINT client_point) const;
    LRESULT handle_passthrough_message(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam);
    static LRESULT CALLBACK passthrough_wnd_proc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam);

    HWND _passthrough_hwnd = nullptr;
    WNDPROC _original_wnd_proc = nullptr;
    std::vector<NativeRect> _interactive_rects;
#endif

    std::wstring _last_error;
};
