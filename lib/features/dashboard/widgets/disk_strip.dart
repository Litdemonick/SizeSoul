import 'package:flutter/material.dart';

import '../../../core/models/storage_models.dart';

class DiskStrip extends StatelessWidget {
  final List<DiskVolume> disks;
  final bool busy;
  final String selected;
  final ValueChanged<String> onScan;
  const DiskStrip({
    super.key,
    required this.disks,
    required this.busy,
    required this.selected,
    required this.onScan,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 90,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: disks.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final disk = disks[i];
        final fraction = disk.total == 0 ? 0.0 : disk.used / disk.total;
        final active = selected.toLowerCase().startsWith(disk.id.toLowerCase());
        final color = fraction > .9
            ? const Color(0xFFE18E65)
            : Theme.of(context).colorScheme.primary;
        return SizedBox(
          width: 236,
          child: Material(
            color: active
                ? Theme.of(context).colorScheme.primary.withValues(alpha: .08)
                : Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: active ? color : Theme.of(context).dividerColor,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: busy ? null : () => onScan(disk.root),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          disk.type == 2 ? Icons.usb : Icons.storage_outlined,
                          size: 17,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          disk.id,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            disk.label.isEmpty ? 'Disco local' : disk.label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          '${(fraction * 100).round()}%',
                          style: TextStyle(fontSize: 12, color: color),
                        ),
                      ],
                    ),
                    const Spacer(),
                    LinearProgressIndicator(
                      value: fraction.clamp(0, 1),
                      minHeight: 3,
                      color: color,
                      backgroundColor: color.withValues(alpha: .12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${bytes(disk.free)} libres',
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          disk.fileSystem,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
