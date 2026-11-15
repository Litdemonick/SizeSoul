import 'package:flutter/material.dart';

import '../../../core/models/storage_models.dart';
import '../../../core/security/path_policy.dart';
import '../../scan/space_map.dart';

class ScanWorkspace extends StatelessWidget {
  final ScanResult result;
  final List<FileNode> trail;
  final String filter;
  final bool busy;
  final ValueChanged<String> onFilter;
  final ValueChanged<FileNode> onOpen, onReveal, onRecycle;
  final VoidCallback onBack;
  const ScanWorkspace({
    super.key,
    required this.result,
    required this.trail,
    required this.filter,
    required this.busy,
    required this.onFilter,
    required this.onOpen,
    required this.onReveal,
    required this.onRecycle,
    required this.onBack,
  });
  Widget section(
    BuildContext context,
    String title,
    Widget body, {
    Widget? trailing,
  }) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      children: [
        SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ?trailing,
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: body),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final node = trail.last;
    final matches = result.largest
        .where((file) => file.path.toLowerCase().contains(filter.toLowerCase()))
        .toList();
    return Column(
      children: [
        SizedBox(
          height: 32,
          child: Row(
            children: [
              Text(
                bytes(result.root.size),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 14),
              Text('${result.root.files} archivos'),
              const SizedBox(width: 14),
              Text('${(result.elapsedMs / 1000).toStringAsFixed(1)} s'),
              const Spacer(),
              Tooltip(
                message: 'Tamaño lógico visible. Puede diferir del espacio asignado de Windows por permisos, compresión o enlaces físicos.',
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${result.skipped} omitidos',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: section(
                  context,
                  'CARPETAS',
                  Column(
                    children: [
                      SizedBox(
                        height: 36,
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Carpeta anterior',
                              onPressed: trail.length > 1 ? onBack : null,
                              icon: const Icon(Icons.arrow_upward, size: 16),
                            ),
                            Expanded(
                              child: Tooltip(
                                message: node.path,
                                child: Text(
                                  node.path,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
                                bytes(node.size),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: node.children.isEmpty
                            ? const Center(
                                child: Text(
                                  'Sin subcarpetas',
                                  style: TextStyle(fontSize: 12),
                                ),
                              )
                            : ListView.builder(
                                itemCount: node.children.length,
                                itemExtent: 38,
                                itemBuilder: (context, i) {
                                  final folder = node.children[i];
                                  final fraction = node.size == 0
                                      ? 0.0
                                      : folder.size / node.size;
                                  return InkWell(
                                    onTap: () => onOpen(folder),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.folder_outlined,
                                            size: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              folder.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 45,
                                            child: LinearProgressIndicator(
                                              value: fraction,
                                              minHeight: 3,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 78,
                                            child: Text(
                                              bytes(folder.size),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: section(
                  context,
                  'MAPA DE ESPACIO',
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: SpaceMap(node: node, onOpen: onOpen),
                  ),
                  trailing: const Text(
                    'Pulsa una carpeta',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 6,
          child: section(
            context,
            'ARCHIVOS MÁS GRANDES · ${matches.length} / ${result.largest.length}',
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    height: 34,
                    child: TextField(
                      onChanged: onFilter,
                      decoration: const InputDecoration(
                        hintText: 'Filtrar los 200 archivos principales por nombre, ruta o extensión',
                        prefixIcon: Icon(Icons.search, size: 18),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'NOMBRE / UBICACIÓN',
                          style: TextStyle(fontSize: 10, letterSpacing: .8),
                        ),
                      ),
                      const SizedBox(
                        width: 88,
                        child: Text(
                          'TAMAÑO',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 85),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: matches.isEmpty
                      ? const Center(
                          child: Text('No hay archivos que coincidan.'),
                        )
                      : ListView.builder(
                          itemCount: matches.length,
                          itemExtent: 49,
                          itemBuilder: (context, i) {
                            final file = matches[i],
                                blocked = PathPolicy.reason(matches[i].path);
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context).dividerColor
                                        .withValues(alpha: .45),
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      blocked != null
                                          ? Icons.lock_outline
                                          : Icons.insert_drive_file_outlined,
                                      size: 17,
                                      color: blocked != null
                                          ? Theme.of(context).disabledColor
                                          : Theme.of(context)
                                                .colorScheme
                                                .primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Tooltip(
                                        message: file.path,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              file.path,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Theme.of(context)
                                                    .hintColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 88,
                                      child: Text(
                                        bytes(file.size),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      tooltip: 'Mostrar en Explorador',
                                      onPressed: () => onReveal(file),
                                      icon: const Icon(
                                        Icons.folder_open,
                                        size: 17,
                                      ),
                                    ),
                                    Tooltip(
                                      message:
                                          blocked ?? 'Enviar a la Papelera',
                                      child: IconButton(
                                        onPressed: busy || blocked != null
                                            ? null
                                            : () => onRecycle(file),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 17,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
