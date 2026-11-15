#include "flutter_window.h"

#include <optional>
#include <algorithm>
#include <flutter/standard_method_codec.h>
#include "storage_guard.h"

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  storage_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "sizesoul/storage",
      &flutter::StandardMethodCodec::GetInstance());
  storage_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() != "recycle") { result->NotImplemented(); return; }
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) { result->Error("invalid", "Argumentos no validos"); return; }
    const auto p = args->find(flutter::EncodableValue("path"));
    const auto s = args->find(flutter::EncodableValue("size"));
    const auto m = args->find(flutter::EncodableValue("modified"));
    if (p == args->end() || s == args->end() || m == args->end() ||
        !std::holds_alternative<std::string>(p->second) ||
        (!std::holds_alternative<int32_t>(s->second) && !std::holds_alternative<int64_t>(s->second)) ||
        (!std::holds_alternative<int32_t>(m->second) && !std::holds_alternative<int64_t>(m->second))) {
      result->Error("invalid", "Faltan datos del archivo"); return;
    }
    const auto& utf8 = std::get<std::string>(p->second);
    const int length = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8.data(),
                                          static_cast<int>(utf8.size()), nullptr, 0);
    if (length <= 0 || utf8.find('\0') != std::string::npos) {
      result->Error("invalid", "Ruta no valida"); return;
    }
    std::wstring path(length, 0);
    MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()), path.data(), length);
    auto error = RecycleGuarded(GetHandle(), path, s->second.LongValue(), m->second.LongValue());
    if (error.empty()) result->Success(); else result->Error("protected", error);
  });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  storage_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_GETMINMAXINFO: {
      auto* limits = reinterpret_cast<MINMAXINFO*>(lparam);
      const UINT dpi = GetDpiForWindow(hwnd);
      MONITORINFO monitor{sizeof(MONITORINFO)};
      GetMonitorInfo(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), &monitor);
      limits->ptMinTrackSize.x = std::min<LONG>(MulDiv(860, dpi, 96), monitor.rcWork.right - monitor.rcWork.left);
      limits->ptMinTrackSize.y = std::min<LONG>(MulDiv(620, dpi, 96), monitor.rcWork.bottom - monitor.rcWork.top);
      return 0;
    }
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
