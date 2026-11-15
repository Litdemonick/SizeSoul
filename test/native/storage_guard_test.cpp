#include "../../windows/runner/storage_guard.h"
#include <windows.h>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
int wmain() {
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  int failures = 0, passed = 0;
  auto blocked = [&](const std::wstring& path, const char* name, int64_t size = 0, int64_t modified = 0) {
    if (RecycleGuarded(nullptr, path, size, modified).empty()) {
      std::cerr << "FAIL: " << name << '\n'; failures++;
    } else { std::cout << "PASS: " << name << '\n'; passed++; }
  };
  blocked(L"C:\\Windows\\System32\\kernel32.dll", "system path");
  blocked(L"C:\\pagefile.sys", "root file");
  blocked(L"\\\\server\\share\\file.txt", "network path");
  blocked(L"C:\\Users\\A\\file.txt:stream", "alternate data stream");
  blocked(L"C:\\Users\\A\\..\\file.txt", "parent traversal");
  blocked(L"D:\\Archive\\AppData\\file.db", "sensitive component");
  const auto fixtures = std::filesystem::current_path() / L".tools" / L"guard-fixtures";
  std::filesystem::create_directories(fixtures);
  const auto file = fixtures / L"sizesoul-guard-test.txt";
  { std::ofstream out(file); out << "SizeSoul synthetic test fixture"; }
  blocked(file.wstring(), "changed scan metadata", 99999, 1);
  SetFileAttributesW(file.c_str(), FILE_ATTRIBUTE_HIDDEN);
  blocked(file.wstring(), "hidden file");
  SetFileAttributesW(file.c_str(), FILE_ATTRIBUTE_NORMAL);
  const auto hardlink = fixtures / L"hardlink.txt";
  if (CreateHardLinkW(hardlink.c_str(), file.c_str(), nullptr)) {
    blocked(file.wstring(), "multiple hard links");
    DeleteFileW(hardlink.c_str());
  } else { std::cerr << "FAIL: cannot create hard-link fixture\n"; failures++; }
  blocked(fixtures.wstring(), "directory");
  if (!std::filesystem::exists(file)) { std::cerr << "FAIL: fixture unexpectedly removed\n"; failures++; }
  // Only exact synthetic fixture paths created above are cleaned up.
  DeleteFileW(file.c_str());
  RemoveDirectoryW(fixtures.c_str());
  CoUninitialize();
  std::cout << passed << " native guard checks passed; " << failures << " failed\n";
  return failures == 0 ? 0 : 1;
}
