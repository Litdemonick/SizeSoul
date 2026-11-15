import 'package:flutter/material.dart';

import '../../core/models/storage_models.dart';

class SpaceMap extends StatelessWidget {
  final FileNode node;
  final ValueChanged<FileNode> onOpen;
  const SpaceMap({super.key, required this.node, required this.onOpen});
  static const colors = [
    Color(0xFFE4AF73),
    Color(0xFF849CAD),
    Color(0xFF9AAA88),
    Color(0xFFBB8C79),
    Color(0xFFA49BAF),
    Color(0xFF8CAEA8),
  ];
  @override
  Widget build(BuildContext context) {
    final entries = node.children.where((n) => n.size > 0).take(12).toList();
    final direct =
        node.size - node.children.fold<int>(0, (sum, n) => sum + n.size);
    final remainder =
        node.size - entries.fold<int>(0, (sum, n) => sum + n.size);
    if (remainder > 0) {
      final other = FileNode(
        direct == remainder
            ? 'Archivos de esta carpeta'
            : 'Archivos y otras carpetas',
        false,
      )..size = remainder;
      entries.add(other);
    }
    if (entries.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Sin contenido visible')),
      );
    }
    return SizedBox(
      height: 230,
      child: LayoutBuilder(
        builder: (context, box) {
          final rectangles = <Widget>[];
          void partition(List<FileNode> items, Rect rect, int offset) {
            if (rect.width < 5 || rect.height < 5) return;
            if (items.length == 1) {
              final item = items.first;
              rectangles.add(
                Positioned.fromRect(
                  rect: rect.deflate(2),
                  child: Material(
                    color: colors[offset % colors.length].withValues(alpha: .8),
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: item.directory ? () => onOpen(item) : null,
                      child: Tooltip(
                        message: '${item.path}\n${bytes(item.size)}',
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: rect.width < 90 || rect.height < 76
                              ? const SizedBox()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF10151E),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (rect.height > 80)
                                      Text(
                                        bytes(item.size),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF10151E),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              return;
            }
            final total = items.fold<int>(0, (s, n) => s + n.size);
            var sum = 0, split = 0;
            while (split < items.length - 1 && sum < total / 2) {
              sum += items[split].size;
              split++;
            }
            final ratio = sum / total;
            if (rect.width > rect.height) {
              partition(
                items.sublist(0, split),
                Rect.fromLTWH(
                  rect.left,
                  rect.top,
                  rect.width * ratio,
                  rect.height,
                ),
                offset,
              );
              partition(
                items.sublist(split),
                Rect.fromLTWH(
                  rect.left + rect.width * ratio,
                  rect.top,
                  rect.width * (1 - ratio),
                  rect.height,
                ),
                offset + split,
              );
            } else {
              partition(
                items.sublist(0, split),
                Rect.fromLTWH(
                  rect.left,
                  rect.top,
                  rect.width,
                  rect.height * ratio,
                ),
                offset,
              );
              partition(
                items.sublist(split),
                Rect.fromLTWH(
                  rect.left,
                  rect.top + rect.height * ratio,
                  rect.width,
                  rect.height * (1 - ratio),
                ),
                offset + split,
              );
            }
          }

          partition(entries, Offset.zero & box.biggest, 0);
          return Stack(children: rectangles);
        },
      ),
    );
  }
}
