#include "lmm_native_bridge.h"

#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/variant.hpp>

using namespace godot;

namespace {

std::wstring to_wstring(const String &value) {
    Char16String utf16 = value.utf16();
    const char16_t *data = utf16.get_data();
    return std::wstring(reinterpret_cast<const wchar_t *>(data));
}

String from_wstring(const std::wstring &value) {
    return String::utf16(reinterpret_cast<const char16_t *>(value.c_str()));
}

std::vector<NativeRect> to_native_rects(const Array &rects) {
    std::vector<NativeRect> native_rects;
    native_rects.reserve(rects.size());
    for (int64_t i = 0; i < rects.size(); ++i) {
        Variant value = rects[i];
        if (value.get_type() != Variant::RECT2) {
            continue;
        }
        Rect2 rect = value;
        NativeRect native_rect;
        native_rect.x = static_cast<int>(rect.position.x);
        native_rect.y = static_cast<int>(rect.position.y);
        native_rect.width = static_cast<int>(rect.size.x);
        native_rect.height = static_cast<int>(rect.size.y);
        native_rects.push_back(native_rect);
    }
    return native_rects;
}

}

void LMMNativeBridge::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_health"), &LMMNativeBridge::get_health);
    ClassDB::bind_method(D_METHOD("get_last_error"), &LMMNativeBridge::get_last_error);
    ClassDB::bind_method(D_METHOD("setup_tray", "icon_path"), &LMMNativeBridge::setup_tray);
    ClassDB::bind_method(D_METHOD("update_tray_menu", "window_visible"), &LMMNativeBridge::update_tray_menu);
    ClassDB::bind_method(D_METHOD("shutdown_tray"), &LMMNativeBridge::shutdown_tray);
    ClassDB::bind_method(D_METHOD("poll_tray_command"), &LMMNativeBridge::poll_tray_command);
    ClassDB::bind_method(D_METHOD("setup_pet_window", "hwnd", "transparent", "topmost"), &LMMNativeBridge::setup_pet_window);
    ClassDB::bind_method(D_METHOD("set_window_visible", "hwnd", "visible"), &LMMNativeBridge::set_window_visible);
    ClassDB::bind_method(D_METHOD("set_mouse_passthrough", "hwnd", "interactive_rects"), &LMMNativeBridge::set_mouse_passthrough);
    ClassDB::bind_method(D_METHOD("clear_mouse_passthrough", "hwnd"), &LMMNativeBridge::clear_mouse_passthrough);
    ClassDB::bind_method(D_METHOD("set_taskbar_visible", "hwnd", "visible"), &LMMNativeBridge::set_taskbar_visible);
}

Dictionary LMMNativeBridge::get_health() const {
    Dictionary health;
    health["native_loaded"] = true;
    health["tray_supported"] = true;
    health["window_supported"] = true;
    health["passthrough_supported"] = true;
    health["taskbar_supported"] = true;
    health["last_error"] = last_error;
    return health;
}

String LMMNativeBridge::get_last_error() const {
    return last_error;
}

bool LMMNativeBridge::setup_tray(const String &p_icon_path) {
    if (tray_controller == nullptr) {
        tray_controller = std::make_unique<TrayController>();
    }
    bool ok = tray_controller->setup(L"LetsMakeMoney", to_wstring(p_icon_path));
    if (!ok) {
        last_error = from_wstring(tray_controller->last_error());
    } else {
        last_error = "";
    }
    return ok;
}

void LMMNativeBridge::update_tray_menu(bool p_window_visible) {
    if (tray_controller != nullptr && tray_controller->is_ready()) {
        tray_controller->update_menu(p_window_visible);
    }
}

void LMMNativeBridge::shutdown_tray() {
    if (tray_controller != nullptr) {
        tray_controller->shutdown();
    }
}

int32_t LMMNativeBridge::poll_tray_command() {
    if (tray_controller == nullptr || !tray_controller->is_ready()) {
        return 0;
    }
    return tray_controller->poll_command();
}

bool LMMNativeBridge::setup_pet_window(int64_t p_hwnd, bool p_transparent, bool p_topmost) {
    if (window_controller == nullptr) {
        window_controller = std::make_unique<WindowController>();
    }
    bool ok = window_controller->setup_pet_window(p_hwnd, p_transparent, p_topmost);
    if (!ok) {
        last_error = from_wstring(window_controller->last_error());
    } else {
        last_error = "";
    }
    return ok;
}

bool LMMNativeBridge::set_window_visible(int64_t p_hwnd, bool p_visible) {
    if (window_controller == nullptr) {
        window_controller = std::make_unique<WindowController>();
    }
    bool ok = window_controller->set_window_visible(p_hwnd, p_visible);
    if (!ok) {
        last_error = from_wstring(window_controller->last_error());
    } else {
        last_error = "";
    }
    return ok;
}

bool LMMNativeBridge::set_mouse_passthrough(int64_t p_hwnd, const Array &p_interactive_rects) {
    if (window_controller == nullptr) {
        window_controller = std::make_unique<WindowController>();
    }
    bool ok = window_controller->set_mouse_passthrough(p_hwnd, to_native_rects(p_interactive_rects));
    if (!ok) {
        last_error = from_wstring(window_controller->last_error());
    } else {
        last_error = "";
    }
    return ok;
}

bool LMMNativeBridge::clear_mouse_passthrough(int64_t p_hwnd) {
    if (window_controller == nullptr) {
        window_controller = std::make_unique<WindowController>();
    }
    bool ok = window_controller->clear_mouse_passthrough(p_hwnd);
    if (!ok) {
        last_error = from_wstring(window_controller->last_error());
    } else {
        last_error = "";
    }
    return ok;
}

bool LMMNativeBridge::set_taskbar_visible(int64_t p_hwnd, bool p_visible) {
    if (window_controller == nullptr) {
        window_controller = std::make_unique<WindowController>();
    }
    bool ok = window_controller->set_taskbar_visible(p_hwnd, p_visible);
    if (!ok) {
        last_error = from_wstring(window_controller->last_error());
    } else {
        last_error = "";
    }
    return ok;
}
