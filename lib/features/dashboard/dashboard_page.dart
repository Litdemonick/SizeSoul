import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/models/storage_models.dart';
import '../../core/storage/local_database.dart';
import '../../shared/widgets/panel.dart';
import '../disks/windows_service.dart';
import '../scan/scan_service.dart';
import '../updates/updates_panel.dart';
import '../../shared/widgets/soul_mark.dart';
import 'widgets/disk_strip.dart';
import 'widgets/scan_workspace.dart';

class DashboardPage extends StatefulWidget {
  final LocalDatabase database;
  final bool dark;
  final ValueChanged<bool> onTheme;
  const DashboardPage({
    super.key,
    required this.database,
    required this.dark,
    required this.onTheme,
  });
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final windows = WindowsService();
  final scanner = ScanService();
  final path = TextEditingController();
  final search = TextEditingController();
  List<DiskVolume> disks = [];
  List<Map<String, Object?>> history = [];
  ScanResult? result;
  final trail = <FileNode>[];
  bool loading = true, scanning = false, deleting = false;
  String? error;
  String currentPath = '';
  int files = 0, page = 0;
  @override
  void initState() {
    super.initState();
    refresh();
    loadHistory();
    widget.database.setting('path').then((v) {
      if (mounted && path.text.isEmpty) {
        path.text = v ?? Platform.environment['USERPROFILE'] ?? r'C:\';
      }
    });
  }

  @override
  void dispose() {
    scanner.cancel();
    path.dispose();
    search.dispose();
    super.dispose();
  }

  Future<void> loadHistory() async {
    final h = await widget.database.history();
    if (mounted) setState(() => history = h);
  }

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final d = await windows.disks();
      if (mounted) setState(() => disks = d);
    } catch (e) {
      if (mounted) {
        setState(() => error = 'No se pudieron leer las unidades: $e');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> action(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      message('$e');
    }
  }

  Future<void> scan([String? target]) async {
    if (scanning || deleting) return;
    final value = (target ?? path.text).trim();
    if (value.isEmpty) {
      message('Escribe una ruta o selecciona una unidad.');
      return;
    }
    path.text = value;
    setState(() {
      scanning = true;
      result = null;
      trail.clear();
      files = 0;
      currentPath = value;
      page = 0;
    });
    try {
      final data = await scanner.scan(value, (count, current) {
        if (mounted) {
          setState(() {
            files = count;
            currentPath = current;
          });
        }
      });
      if (!mounted) return;
      setState(() {
        result = data;
        trail.add(data.root);
      });
      await widget.database.save(data);
      await widget.database.set('path', value);
      await loadHistory();
    } catch (e) {
      message('$e');
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  Future<void> recycle(FileNode file) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar a la Papelera'),
        content: SizedBox(
          width: 480,
          child: SelectableText(
            '${file.path}\n\n${bytes(file.size)}\n\nWindows puede mostrar otra confirmación. El espacio no se libera hasta vaciar la Papelera. La operación se bloquea si el archivo cambió, está protegido o no es un archivo normal de una unidad local fija.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar a la Papelera'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => deleting = true);
    try {
      await windows.recycle(
        file.path,
        size: file.size,
        modified: file.modifiedMs,
      );
      message('Archivo enviado a la Papelera. Actualizando el análisis…');
    } catch (e) {
      message('$e');
    } finally {
      if (mounted) setState(() => deleting = false);
    }
    if (mounted) {
      await scan();
      await refresh();
    }
  }

  void openNode(FileNode n) {
    setState(() => trail.add(n));
  }

  Text heading(String text) =>
      Text(text, style: Theme.of(context).textTheme.titleLarge);
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final labels = ['Explorador', 'Herramientas', 'Historial', 'Configuración'];
    const icons = [
      Icons.space_dashboard_outlined,
      Icons.tune,
      Icons.history,
      Icons.settings_outlined,
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  const SoulMark(size: 25),
                  const SizedBox(width: 10),
                  const Text(
                    'SizeSoul',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 1,
                    height: 18,
                    color: Theme.of(context).dividerColor,
                  ),
                  const SizedBox(width: 20),
                  Text(labels[page], style: const TextStyle(fontSize: 12)),
                  const Spacer(),
                  const Icon(Icons.shield_outlined, size: 15),
                  const SizedBox(width: 6),
                  const Text(
                    'Limpieza protegida',
                    style: TextStyle(fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Cambiar tema',
                    onPressed: () => widget.onTheme(!widget.dark),
                    icon: Icon(
                      widget.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: wide ? 164 : 58,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < labels.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Tooltip(
                              message: wide ? '' : labels[i],
                              child: Material(
                                color: page == i
                                    ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: .12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(5),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(5),
                                  onTap: () => setState(() => page = i),
                                  child: SizedBox(
                                    height: 39,
                                    child: Row(
                                      mainAxisAlignment: wide
                                          ? MainAxisAlignment.start
                                          : MainAxisAlignment.center,
                                      children: [
                                        if (wide) const SizedBox(width: 12),
                                        Icon(
                                          icons[i],
                                          size: 19,
                                          color: page == i
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                              : Theme.of(context).hintColor,
                                        ),
                                        if (wide) ...[
                                          const SizedBox(width: 11),
                                          Text(
                                            labels[i],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: page == i
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (wide)
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'HECHO PARA\nENTENDER TU DISCO',
                              style: TextStyle(
                                fontSize: 9,
                                height: 1.7,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: page == 0
                          ? overview()
                          : page == 1
                          ? toolsPage()
                          : page == 2
                          ? historyPage()
                          : settingsPage(),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 27,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scanning
                          ? '$files archivos · $currentPath'
                          : '${disks.length} unidades conectadas · ${Platform.localHostname} · Datos locales',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  const Text(
                    'WINDOWS / x64',
                    style: TextStyle(fontSize: 9, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget overview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Text(
            'UNIDADES',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          if (loading)
            const SizedBox.square(
              dimension: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: loading ? null : refresh,
            icon: const Icon(Icons.refresh, size: 15),
            label: const Text('Actualizar', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            error!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 11,
            ),
          ),
        ),
      if (disks.isNotEmpty)
        DiskStrip(
          disks: disks,
          busy: scanning || deleting,
          selected: path.text,
          onScan: scan,
        ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: path,
                enabled: !scanning && !deleting,
                onSubmitted: (_) => scan(),
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.folder_outlined, size: 18),
                  hintText: r'C:\Users\TuUsuario\Downloads',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: FilledButton.icon(
              onPressed: deleting
                  ? null
                  : scanning
                  ? scanner.cancel
                  : () => scan(),
              icon: Icon(scanning ? Icons.stop : Icons.play_arrow, size: 18),
              label: Text(scanning ? 'Cancelar' : 'Analizar'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (scanning) ...[
        const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 8),
      ],
      Expanded(
        child: result != null
            ? ScanWorkspace(
                result: result!,
                trail: trail,
                filter: search.text,
                busy: scanning || deleting,
                onFilter: (v) => setState(() => search.text = v),
                onOpen: openNode,
                onBack: () => setState(() => trail.removeLast()),
                onReveal: (file) => action(() => windows.reveal(file.path)),
                onRecycle: recycle,
              )
            : startPage(),
      ),
    ],
  );
  Widget startPage() => LayoutBuilder(
    builder: (context, c) => ListView(
      children: [
        const SizedBox(height: 8),
        if (scanning)
          Panel(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.radar, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analizando · $files archivos',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentPath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (!scanning) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: Row(
              children: [
                heading('Empieza por lo que más acumulas'),
                const Spacer(),
                const Text(
                  'Solo lectura durante el análisis',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in [
                (Icons.download_outlined, 'Descargas', 'Downloads'),
                (Icons.movie_outlined, 'Vídeos', 'Videos'),
                (Icons.desktop_windows_outlined, 'Escritorio', 'Desktop'),
                (Icons.person_outline, 'Mi perfil', ''),
              ])
                SizedBox(
                  width: (c.maxWidth - 24) / 4,
                  child: OutlinedButton(
                    onPressed: () => scan(
                      '${Platform.environment['USERPROFILE']}\\${item.$3}',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 8,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(item.$1, size: 22),
                        const SizedBox(height: 8),
                        Text(item.$2, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Panel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DÓNDE ESTÁ EL ESPACIO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              for (final disk in disks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          disk.id,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value: disk.total == 0 ? 0 : disk.used / disk.total,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(2),
                          color: disk.free / disk.total < .1
                              ? const Color(0xFFDB8A68)
                              : Theme.of(context).colorScheme.primary
                                    .withValues(alpha: .7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 150,
                        child: Text(
                          '${bytes(disk.used)} / ${bytes(disk.total)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      TextButton(
                        onPressed: scanning ? null : () => scan(disk.root),
                        child: const Text(
                          'Explorar',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              if (disks.isEmpty)
                const Text(
                  'Actualiza las unidades o escribe una ruta para analizarla.',
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Analiza una unidad para ver sus carpetas y archivos grandes. Revisa cada archivo antes de enviarlo a la Papelera. Para temporales y aplicaciones, usa Herramientas; no borres sus carpetas manualmente.',
                  style: TextStyle(fontSize: 12, height: 1.6),
                ),
              ),
            ],
          ),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'ÚLTIMO ANÁLISIS',
            style: TextStyle(fontSize: 10, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history, size: 19),
            title: Text(
              '${history.first['path']}',
              style: const TextStyle(fontSize: 12),
            ),
            subtitle: Text(
              '${bytes(history.first['bytes'] as int)} · ${history.first['files']} archivos',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.arrow_forward, size: 18),
            onTap: scanning
                ? null
                : () => scan(history.first['path'] as String),
          ),
        ],
      ],
    ),
  );
  Widget tool(
    IconData icon,
    String title,
    String description,
    String button,
    VoidCallback callback,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Panel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading(title),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(onPressed: callback, child: Text(button)),
        ],
      ),
    ),
  );
  Widget toolsPage() => ListView(
    children: [
      tool(
        Icons.storage,
        'Particiones y formato',
        'Administración de discos de Windows. Comprueba la unidad y realiza una copia antes de formatear. El formato destruye los datos y no equivale a un borrado seguro.',
        'Abrir Windows',
        () => action(windows.diskManager),
      ),
      tool(
        Icons.apps,
        'Aplicaciones instaladas',
        'Libera espacio usando el desinstalador oficial. Eliminar la carpeta de un programa puede dañar su instalación.',
        'Ver aplicaciones',
        () => action(windows.installedApps),
      ),
      tool(
        Icons.auto_delete_outlined,
        'Temporales y Papelera',
        'Revisa archivos temporales, Papelera y Sensor de almacenamiento en Windows. SizeSoul no vacía la Papelera automáticamente.',
        'Revisar limpieza',
        () => action(windows.storageSettings),
      ),
      tool(
        Icons.download_outlined,
        'Revisar Descargas',
        'Encuentra instaladores, archivos comprimidos y descargas que ya no necesitas.',
        'Analizar',
        () => scan('${Platform.environment['USERPROFILE']}\\Downloads'),
      ),
    ],
  );
  Widget historyPage() => history.isEmpty
      ? const Center(child: Text('Los análisis completados aparecerán aquí.'))
      : ListView.separated(
          itemCount: history.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final h = history[i];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.history, size: 18),
              title: Text('${h['path']}'),
              subtitle: Text(
                '${h['created']} · ${h['files']} archivos · ${h['skipped']} omitidos',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Text(bytes(h['bytes'] as int)),
              onTap: scanning || deleting
                  ? null
                  : () => scan(h['path'] as String),
            );
          },
        );
  Widget settingsPage() => ListView(
    children: [
      const Panel(padding: EdgeInsets.all(18), child: UpdatesPanel()),
      const SizedBox(height: 10),
      Panel(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading('Preferencias'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tema oscuro', style: TextStyle(fontSize: 13)),
              value: widget.dark,
              onChanged: widget.onTheme,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Historial · ${history.length} análisis'),
              subtitle: SelectableText(
                widget.database.db.path,
                style: const TextStyle(fontSize: 11),
              ),
              trailing: TextButton(
                onPressed: () => action(() async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Borrar historial local'),
                      content: const Text(
                        'Se borrarán los resúmenes de análisis. No se modificará ningún archivo de tus discos.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Borrar historial'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await widget.database.clearHistory();
                    await loadHistory();
                  }
                }),
                child: const Text('Borrar'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      const Panel(
        padding: EdgeInsets.all(18),
        child: Text(
          'Protecciones de limpieza\n\nSolo archivos individuales en unidades locales fijas. Se bloquean raíces, carpetas del sistema, AppData, enlaces, archivos ocultos y archivos que cambiaron desde el análisis. Windows vuelve a validar la operación antes de enviarlos a la Papelera. No hay borrado permanente ni elevación de privilegios desde SizeSoul.\n\nEl análisis muestra tamaño lógico visible, no espacio físico exacto. Omite enlaces y accesos denegados; conserva agregados y los 200 archivos más grandes. No lee la MFT.\n\nTus preferencias e historial permanecen en SQLite en este equipo. Solo se contacta GitHub cuando solicitas comprobar versiones. Ninguna protección sustituye una copia de seguridad.',
          style: TextStyle(fontSize: 12, height: 1.6),
        ),
      ),
    ],
  );
}
