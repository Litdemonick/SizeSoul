# Contributing

Use Flutter 3.47.1, Dart 3.13.1 and the Visual Studio C++ desktop workload. Windows is the supported target.

1. Keep models, storage, Windows integration and widgets in their feature/core directories.
2. Run `dart format lib test`, `flutter analyze` and `flutter test`.
3. Build with `flutter build windows --release` and test at 100%, 150% and 200% scaling.
4. Any change to cleanup must include policy tests and a review of the native guard. Never test deletion against personal data.
5. Do not commit generated builds, databases, scan output, signing keys or local screenshots.

Version is sourced from `pubspec.yaml`. Increment semantic version and build number, update CHANGELOG.md, then run `scripts/build-release.ps1`. Public tags must match the package version (`v1.1.0`). Do not reuse an existing release tag or replace published binaries silently.
