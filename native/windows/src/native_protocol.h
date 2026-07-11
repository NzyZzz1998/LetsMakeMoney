#pragma once

#ifdef _WIN32
#include <windows.h>
#endif

namespace LmmNativeProtocol {
static constexpr int COMMAND_NONE = 0;
static constexpr int COMMAND_TOGGLE = 1;
static constexpr int COMMAND_SETTINGS = 2;
static constexpr int COMMAND_ABOUT = 3;
static constexpr int COMMAND_EXIT = 4;
static constexpr int COMMAND_LEFT_TOGGLE = 5;
#ifdef _WIN32
static constexpr UINT TRAY_UID = 1;
static constexpr UINT TRAY_CALLBACK_MESSAGE = WM_APP + 101;
#endif
}
