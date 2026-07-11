#pragma once

#ifdef _WIN32
#include <windows.h>
#include <shellapi.h>
#endif

#include <string>
#include "native_protocol.h"

class TrayController {
public:
    static constexpr int COMMAND_NONE = LmmNativeProtocol::COMMAND_NONE;
    static constexpr int COMMAND_TOGGLE = LmmNativeProtocol::COMMAND_TOGGLE;
    static constexpr int COMMAND_SETTINGS = LmmNativeProtocol::COMMAND_SETTINGS;
    static constexpr int COMMAND_ABOUT = LmmNativeProtocol::COMMAND_ABOUT;
    static constexpr int COMMAND_EXIT = LmmNativeProtocol::COMMAND_EXIT;
    static constexpr int COMMAND_LEFT_TOGGLE = LmmNativeProtocol::COMMAND_LEFT_TOGGLE;

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
    static constexpr UINT TRAY_UID = LmmNativeProtocol::TRAY_UID;
    static constexpr UINT TRAY_CALLBACK_MESSAGE = LmmNativeProtocol::TRAY_CALLBACK_MESSAGE;
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
