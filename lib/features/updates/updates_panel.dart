import 'package:flutter/material.dart';

import 'update_service.dart';

class UpdatesPanel extends StatefulWidget {
  const UpdatesPanel({super.key});
  @override
  State<UpdatesPanel> createState() => _UpdatesPanelState();
}

class _UpdatesPanelState extends State<UpdatesPanel> {
  final service = UpdateService();
  String version = 'Leyendo versión…',
      status = 'Consulta manual. Sin descargas automáticas.';
  bool busy = false;
  @override
  void initState() {
    super.initState();
    service
        .installed()
        .then((info) {
          if (mounted) {
            setState(() => version = '${info.version}+${info.buildNumber}');
          }
        })
        .catchError((Object e) {
          if (mounted) setState(() => version = 'No disponible');
        });
  }

  Future<void> check() async {
    setState(() => busy = true);
    try {
      final installed = await service.installed();
      final latest = await service.latest();
      final newer =
          latest != null &&
          latest.compareTo(ReleaseVersion.parse(installed.version)) > 0;
      if (mounted) {
        setState(
          () => status = latest == null
              ? 'Todavía no hay una versión pública estable.'
              : newer
              ? 'Disponible: $latest. Abre las versiones y ejecuta el instalador para actualizar.'
              : 'Tienes la versión estable más reciente ($version).',
        );
      }
    } catch (e) {
      if (mounted) setState(() => status = 'No se pudo comprobar: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.system_update_alt, size: 20),
          const SizedBox(width: 10),
          Text(
            'SizeSoul $version',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(status),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: busy ? null : check,
            icon: const Icon(Icons.sync, size: 18),
            label: Text(busy ? 'Consultando…' : 'Buscar actualizaciones'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await service.openReleases();
              } catch (e) {
                if (mounted) setState(() => status = '$e');
              }
            },
            child: const Text('Versiones en GitHub'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'La consulta contacta api.github.com y comparte tu IP y el agente de la app. No envía rutas ni resultados de análisis.',
        style: TextStyle(fontSize: 11),
      ),
    ],
  );
}
