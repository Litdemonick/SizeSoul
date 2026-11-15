#include "storage_guard.h"
#include <shlobj.h>
#include <wrl/client.h>
#include <algorithm>
#include <cwctype>
#include <vector>

using Microsoft::WRL::ComPtr;
namespace {
std::wstring Lower(std::wstring value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](wchar_t c) { return static_cast<wchar_t>(towlower(c)); });
  return value;
}
bool Within(const std::wstring& path, const std::wstring& root) {
  auto normalized = Lower(root);
  while (!normalized.empty() && normalized.back() == L'\\') normalized.pop_back();
  return path == normalized || path.rfind(normalized + L"\\", 0) == 0;
}
}

std::string ValidateRecyclePath(const std::wstring& input,
                           int64_t expected_size, int64_t expected_modified) {
  if (input.size() < 4 || input[1] != L':' || input[2] != L'\\' ||
      !iswalpha(input[0]) || input.find(L':', 2) != std::wstring::npos ||
      input.find(L'/') != std::wstring::npos || input.size() >= 32760) {
    return "Ruta no permitida. Solo se admiten archivos locales.";
  }
  auto path = Lower(input);
  wchar_t long_path[32768] = {};
  const DWORD long_length = GetLongPathNameW(input.c_str(), long_path, 32768);
  if (long_length == 0 || long_length >= 32768 || Lower(long_path) != path) {
    return "No se permiten alias cortos ni rutas que no se puedan verificar.";
  }
  if (path.find(L"\\..") != std::wstring::npos ||
      path.find(L"\\.\\") != std::wstring::npos ||
      path.find(L'\\', 3) == std::wstring::npos) {
    return "No se permiten raices ni rutas ambiguas.";
  }
  wchar_t root[] = {input[0], L':', L'\\', 0};
  if (GetDriveTypeW(root) != DRIVE_FIXED) {
    return "La limpieza solo se permite en unidades locales fijas.";
  }
  const KNOWNFOLDERID* folders[] = {&FOLDERID_Windows, &FOLDERID_System,
    &FOLDERID_ProgramFiles, &FOLDERID_ProgramFilesX86, &FOLDERID_ProgramData,
    &FOLDERID_LocalAppData, &FOLDERID_RoamingAppData, &FOLDERID_LocalAppDataLow};
  for (const auto* id : folders) {
    PWSTR known = nullptr;
    if (SUCCEEDED(SHGetKnownFolderPath(*id, 0, nullptr, &known))) {
      const bool blocked = Within(path, known);
      CoTaskMemFree(known);
      if (blocked) return "Ubicacion protegida. Usa las herramientas de Windows.";
    }
  }
  wchar_t executable[32768] = {};
  GetModuleFileNameW(nullptr, executable, 32768);
  std::wstring executable_path(executable);
  if (Within(path, executable_path.substr(0, executable_path.find_last_of(L'\\')))) {
    return "No se pueden eliminar archivos de SizeSoul.";
  }
  const std::vector<std::wstring> protected_names = {L"windows", L"program files",
    L"program files (x86)", L"programdata", L"appdata", L"$recycle.bin",
    L"system volume information", L"recovery", L"boot", L"efi", L"msocache",
    L".git", L".ssh", L".aws", L".codex", L".agents"};
  size_t start = 3;
  for (size_t end = path.find(L'\\', start);; end = path.find(L'\\', start)) {
    const auto part = path.substr(start, end == std::wstring::npos ? end : end - start);
    if (part.empty() || part.back() == L'.' || part.back() == L' ' ||
        std::find(protected_names.begin(), protected_names.end(), part) != protected_names.end()) {
      return "Ruta sensible o ambigua bloqueada.";
    }
    const auto prefix = input.substr(0, end);
    const DWORD attrs = GetFileAttributesW(prefix.c_str());
    if (attrs == INVALID_FILE_ATTRIBUTES ||
        (attrs & (FILE_ATTRIBUTE_REPARSE_POINT | FILE_ATTRIBUTE_SYSTEM | FILE_ATTRIBUTE_HIDDEN))) {
      return "No se permiten enlaces, archivos ocultos ni elementos del sistema.";
    }
    if (end == std::wstring::npos) break;
    start = end + 1;
  }
  HANDLE handle = CreateFileW(input.c_str(), FILE_READ_ATTRIBUTES,
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
      OPEN_EXISTING, FILE_FLAG_OPEN_REPARSE_POINT, nullptr);
  if (handle == INVALID_HANDLE_VALUE) return "No se pudo comprobar el archivo.";
  BY_HANDLE_FILE_INFORMATION info{};
  const bool valid = GetFileInformationByHandle(handle, &info) != FALSE;
  CloseHandle(handle);
  if (!valid || info.nNumberOfLinks != 1 ||
      (info.dwFileAttributes & (FILE_ATTRIBUTE_DIRECTORY | FILE_ATTRIBUTE_REPARSE_POINT |
                                FILE_ATTRIBUTE_SYSTEM | FILE_ATTRIBUTE_HIDDEN))) {
    return "Archivo protegido, enlazado o no verificable.";
  }
  const int64_t size = (static_cast<int64_t>(info.nFileSizeHigh) << 32) | info.nFileSizeLow;
  ULARGE_INTEGER time{};
  time.LowPart = info.ftLastWriteTime.dwLowDateTime;
  time.HighPart = info.ftLastWriteTime.dwHighDateTime;
  const int64_t modified = static_cast<int64_t>(time.QuadPart / 10000) - 11644473600000LL;
  if (size != expected_size || modified != expected_modified) {
    return "El archivo cambio desde el analisis. Vuelve a analizar antes de eliminar.";
  }
  return {};
}

std::string RecycleGuarded(HWND owner, const std::wstring& input,
                           int64_t expected_size, int64_t expected_modified) {
  const auto validation = ValidateRecyclePath(input, expected_size, expected_modified);
  if (!validation.empty()) return validation;
  ComPtr<IFileOperation> operation;
  HRESULT hr = CoCreateInstance(CLSID_FileOperation, nullptr, CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(&operation));
  if (FAILED(hr)) return "No se pudo iniciar la Papelera de Windows.";
  hr = operation->SetOperationFlags(FOFX_RECYCLEONDELETE | FOFX_ADDUNDORECORD |
      FOFX_EARLYFAILURE | FOF_NOERRORUI | FOF_NO_CONNECTED_ELEMENTS);
  if (FAILED(hr)) return "Windows no pudo configurar la operacion protegida.";
  operation->SetOwnerWindow(owner);
  ComPtr<IShellItem> item;
  hr = SHCreateItemFromParsingName(input.c_str(), nullptr, IID_PPV_ARGS(&item));
  if (FAILED(hr)) return "El archivo ya no esta disponible.";
  hr = operation->DeleteItem(item.Get(), nullptr);
  if (SUCCEEDED(hr)) hr = operation->PerformOperations();
  BOOL aborted = TRUE;
  operation->GetAnyOperationsAborted(&aborted);
  if (FAILED(hr) || aborted) return "Windows cancelo o no pudo enviar el archivo a la Papelera.";
  return {};
}
