import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizesoul/core/models/storage_models.dart';
import 'package:sizesoul/features/scan/space_map.dart';

void main() {
  testWidgets(
    'map handles extreme size differences without invalid rectangles',
    (tester) async {
      final root = FileNode('root', true)..size = 1000000001;
      root.children.add(FileNode('large', true)..size = 1000000000);
      root.children.add(FileNode('tiny', true)..size = 1);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 700,
              child: SpaceMap(node: root, onOpen: (_) {}),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('large'), findsOneWidget);
    },
  );
  testWidgets('map opens the selected folder', (tester) async {
    final root = FileNode('root', true)..size = 50;
    final folder = FileNode('folder', true)..size = 50;
    root.children.add(folder);
    FileNode? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpaceMap(node: root, onOpen: (node) => opened = node),
        ),
      ),
    );
    await tester.tap(find.text('folder'));
    expect(opened, same(folder));
  });
}
