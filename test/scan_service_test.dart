import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sizesoul/core/models/storage_models.dart';
import 'package:sizesoul/features/scan/scan_service.dart';
import 'package:sizesoul/features/disks/windows_service.dart';

void main() {
  test('immediate cancellation cannot leak into the next scan', () async {
    final dir = await Directory.systemTemp.createTemp('sizesoul_cancel_');
    final scanner = ScanService();
    try {
      final first = scanner.scan(dir.path, (_, _) {});
      final failure = expectLater(first, throwsStateError);
      scanner.cancel();
      await failure;
      final second = await scanner.scan(dir.path, (_, _) {});
      expect(second.root.files, 0);
      expect(second.root.path, dir.path);
    } finally {
      scanner.cancel();
      await dir.delete();
    }
  });
  test('formats binary units', () {
    expect(bytes(1024), '1.0 KiB');
    expect(bytes(0), '0 B');
  });
  test('quotes PowerShell paths without interpolation', () {
    expect(
      WindowsService.literal("D:\\it's here\\a.txt"),
      "'D:\\it''s here\\a.txt'",
    );
  });
  test('scan aggregates nested files and keeps largest first', () async {
    final dir = await Directory.systemTemp.createTemp('sizesoul_test_');
    try {
      await File('${dir.path}/small.txt').writeAsBytes(List.filled(11, 0));
      final nested = await Directory('${dir.path}/nested').create();
      await File('${nested.path}/large.bin').writeAsBytes(List.filled(4096, 0));
      final scanner = ScanService();
      final result = await scanner.scan(dir.path, (_, _) {});
      expect(result.root.size, 4107);
      expect(result.root.files, 2);
      expect(result.root.children.single.size, 4096);
      expect(result.largest.first.size, 4096);
      expect(result.skipped, 0);
    } finally {
      await dir.delete(recursive: true);
    }
  });
  test('invalid folder produces an error', () async {
    final scanner = ScanService();
    await expectLater(
      scanner.scan('Z:\\nonexistent_sizesoul_test_8271', (_, _) {}),
      throwsStateError,
    );
  });
  test('recycling a directory is prohibited', () async {
    await expectLater(
      WindowsService().recycle(Directory.systemTemp.path),
      throwsStateError,
    );
  });
}
