#ifndef SIZESOUL_STORAGE_GUARD_H_
#define SIZESOUL_STORAGE_GUARD_H_
#include <windows.h>
#include <cstdint>
#include <string>
// Returns an empty string only after Windows confirms successful recycling.
std::string RecycleGuarded(HWND owner, const std::wstring& path,
                           int64_t expected_size, int64_t expected_modified);
#endif
