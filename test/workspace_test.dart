import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizesoul/core/models/storage_models.dart';
import 'package:sizesoul/features/dashboard/widgets/scan_workspace.dart';
import 'package:sizesoul/features/dashboard/widgets/disk_strip.dart';

void main() {
  testWidgets('dense workspace fits minimum supported window', (tester) async {
    tester.view.physicalSize = const Size(750, 330);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final root = FileNode(r'D:\Example', true)
      ..size = 1024
      ..files = 1;
    final folder = FileNode(r'D:\Example\Long folder name with spaces', true)
      ..size = 1024;
    root.children.add(folder);
    final file = FileNode(r'D:\Example\film.mp4', false)..size = 1024;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanWorkspace(
            result: ScanResult(root, 0, 100, [file]),
            trail: [root],
            filter: '',
            busy: false,
            onFilter: (_) {},
            onOpen: (_) {},
            onReveal: (_) {},
            onRecycle: (_) {},
            onBack: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('film.mp4'), findsOneWidget);
  });
  testWidgets('drive strip scrolls instead of overflowing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            child: DiskStrip(
              disks: List.generate(
                10,
                (i) => DiskVolume('$i:', 'Example', 'NTFS', 100, 20, 3),
              ),
              busy: false,
              selected: '',
              onScan: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
