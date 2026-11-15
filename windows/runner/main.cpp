#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <algorithm>
#include <flutter_windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  HANDLE instance_mutex = CreateMutexW(nullptr, FALSE, L"Local\\SizeSoul.Desktop.1");
  if (!instance_mutex) return EXIT_FAILURE;
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing = FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"SizeSoul");
    if (existing) { ShowWindow(existing, SW_RESTORE); SetForegroundWindow(existing); }
    CloseHandle(instance_mutex);
    return EXIT_SUCCESS;
  }
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  MONITORINFO monitor{sizeof(MONITORINFO)};
  HMONITOR display = MonitorFromPoint(POINT{0, 0}, MONITOR_DEFAULTTOPRIMARY);
  GetMonitorInfoW(display, &monitor);
  const double scale = FlutterDesktopGetDpiForMonitor(display) / 96.0;
  Win32Window::Point origin(16, 16);
  Win32Window::Size size(
      static_cast<unsigned int>(std::min(1320.0, (monitor.rcWork.right - monitor.rcWork.left) / scale - 32)),
      static_cast<unsigned int>(std::min(860.0, (monitor.rcWork.bottom - monitor.rcWork.top) / scale - 32)));
  if (!window.Create(L"SizeSoul", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  CloseHandle(instance_mutex);
  return EXIT_SUCCESS;
}
