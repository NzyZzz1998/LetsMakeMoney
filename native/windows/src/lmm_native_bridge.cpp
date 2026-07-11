#include "lmm_native_bridge.h"

#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <windows.h>
#include <wincrypt.h>
#include <wintrust.h>
#include <softpub.h>

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
    ClassDB::bind_method(D_METHOD("verify_authenticode", "file_path", "expected_publisher"), &LMMNativeBridge::verify_authenticode);
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

Dictionary LMMNativeBridge::verify_authenticode(const String &p_file_path, const String &p_expected_publisher) {
    Dictionary result;
    result["valid"] = false;
    result["publisher"] = "";
    std::wstring path = to_wstring(p_file_path);
    WINTRUST_FILE_INFO file_info{};
    file_info.cbStruct = sizeof(file_info);
    file_info.pcwszFilePath = path.c_str();
    WINTRUST_DATA trust_data{};
    trust_data.cbStruct = sizeof(trust_data);
    trust_data.dwUIChoice = WTD_UI_NONE;
    trust_data.fdwRevocationChecks = WTD_REVOKE_NONE;
    trust_data.dwUnionChoice = WTD_CHOICE_FILE;
    trust_data.pFile = &file_info;
    trust_data.dwStateAction = WTD_STATEACTION_VERIFY;
    trust_data.dwProvFlags = WTD_CACHE_ONLY_URL_RETRIEVAL;
    GUID policy = WINTRUST_ACTION_GENERIC_VERIFY_V2;
    LONG status = WinVerifyTrust(nullptr, &policy, &trust_data);
    trust_data.dwStateAction = WTD_STATEACTION_CLOSE;
    WinVerifyTrust(nullptr, &policy, &trust_data);
    if (status != ERROR_SUCCESS) {
        result["error"] = String("WinVerifyTrust failed: 0x") + String::num_int64(static_cast<uint32_t>(status), 16);
        return result;
    }

    HCERTSTORE store = nullptr;
    HCRYPTMSG message = nullptr;
    DWORD encoding = 0, content_type = 0, format_type = 0;
    if (!CryptQueryObject(CERT_QUERY_OBJECT_FILE, path.c_str(), CERT_QUERY_CONTENT_FLAG_PKCS7_SIGNED_EMBED,
            CERT_QUERY_FORMAT_FLAG_BINARY, 0, &encoding, &content_type, &format_type, &store, &message, nullptr)) {
        result["error"] = "The signature is valid but the publisher certificate could not be read.";
        return result;
    }
    DWORD signer_size = 0;
    CryptMsgGetParam(message, CMSG_SIGNER_INFO_PARAM, 0, nullptr, &signer_size);
    std::vector<BYTE> signer_buffer(signer_size);
    PCMSG_SIGNER_INFO signer = reinterpret_cast<PCMSG_SIGNER_INFO>(signer_buffer.data());
    if (!CryptMsgGetParam(message, CMSG_SIGNER_INFO_PARAM, 0, signer, &signer_size)) {
        CertCloseStore(store, 0); CryptMsgClose(message);
        result["error"] = "The signature is valid but signer information could not be read.";
        return result;
    }
    CERT_INFO cert_info{};
    cert_info.Issuer = signer->Issuer;
    cert_info.SerialNumber = signer->SerialNumber;
    PCCERT_CONTEXT cert = CertFindCertificateInStore(store, encoding, 0, CERT_FIND_SUBJECT_CERT, &cert_info, nullptr);
    std::wstring publisher;
    if (cert != nullptr) {
        DWORD length = CertGetNameStringW(cert, CERT_NAME_SIMPLE_DISPLAY_TYPE, 0, nullptr, nullptr, 0);
        if (length > 1) {
            publisher.resize(length - 1);
            CertGetNameStringW(cert, CERT_NAME_SIMPLE_DISPLAY_TYPE, 0, nullptr, publisher.data(), length);
        }
        CertFreeCertificateContext(cert);
    }
    CertCloseStore(store, 0); CryptMsgClose(message);
    String publisher_string = from_wstring(publisher);
    result["publisher"] = publisher_string;
    if (!p_expected_publisher.is_empty() && publisher_string.findn(p_expected_publisher) < 0) {
        result["error"] = "The Authenticode publisher does not match the expected publisher.";
        return result;
    }
    result["valid"] = true;
    result["error"] = "";
    return result;
}
