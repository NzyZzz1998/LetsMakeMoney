#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

#include <memory>

#include "tray_controller.h"
#include "window_controller.h"

namespace godot {

class LMMNativeBridge : public RefCounted {
    GDCLASS(LMMNativeBridge, RefCounted)

private:
    String last_error;
    std::unique_ptr<TrayController> tray_controller;
    std::unique_ptr<WindowController> window_controller;

protected:
    static void _bind_methods();

public:
    Dictionary get_health() const;
    String get_last_error() const;

    bool setup_tray(const String &p_icon_path);
    void update_tray_menu(bool p_window_visible);
    void shutdown_tray();
    int32_t poll_tray_command();

    bool setup_pet_window(int64_t p_hwnd, bool p_transparent, bool p_topmost);
    bool set_window_visible(int64_t p_hwnd, bool p_visible);
    bool set_mouse_passthrough(int64_t p_hwnd, const Array &p_interactive_rects);
    bool clear_mouse_passthrough(int64_t p_hwnd);
    bool set_taskbar_visible(int64_t p_hwnd, bool p_visible);
    Dictionary verify_authenticode(const String &p_file_path, const String &p_expected_publisher);
};

}
