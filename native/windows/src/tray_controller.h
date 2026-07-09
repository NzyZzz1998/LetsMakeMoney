#pragma once

#ifdef _WIN32
#include <windows.h>
#include <shellapi.h>
#endif

#include <string>

class TrayController {
public:
    static constexpr int COMMAND_NONE = 0;
    static constexpr int COMMAND_TOGGLE = 1;
    static constexpr int COMMAND_SETTINGS = 2;
    static constexpr int COMMAND_ABOUT = 3;
    static constexpr int COMMAND_EXIT = 4;
    static constexpr int COMMAND_LEFT_TOGGLE = 5;

    TrayController();
    ~TrayController();

    bool setup(const std::wstring &tooltip, const std::wstring &icon_path);
    void update_menu(bool window_visible);
    void shutdown();
    bool is_ready() const;
    int poll_command();
    std::wstring last_error() const;

private:
#ifdef _WIN32
    static constexpr UINT TRAY_UID = 1;
    static constexpr UINT TRAY_CALLBACK_MESSAGE = WM_APP + 101;
    static LRESULT CALLBACK window_proc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

    bool ensure_message_window();
    bool add_icon(const std::wstring &tooltip, const std::wstring &icon_path);
    HICON load_icon(const std::wstring &icon_path);
    void show_menu();
    void set_pending_command(int command);
    void set_toggle_command();
    void set_left_toggle_command();

    HWND _message_hwnd = nullptr;
    HMENU _menu = nullptr;
    HICON _icon = nullptr;
    NOTIFYICONDATAW _icon_data = {};
    DWORD _last_toggle_tick = 0;
    bool _left_down_toggle_sent = false;
#endif

    bool _ready = false;
    int _pending_command = COMMAND_NONE;
    std::wstring _last_error;
};
