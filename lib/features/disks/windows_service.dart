import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/security/path_policy.dart';

import '../../core/models/storage_models.dart';

class WindowsService {
  static String literal(String value) => "'${value.replaceAll("'", "''")}'";
  Future<String> powershell(String script) async {
    final encoded = base64Encode(
      script.codeUnits.expand((u) => [u & 255, u >> 8]).toList(),
    );
    final result = await Process.run('powershell.exe', [
      '-NoLogo',
      '-NoProfile',
      '-NonInteractive',
      '-WindowStyle',
      'Hidden',
      '-EncodedCommand',
      encoded,
    ], stdoutEncoding: utf8);
    if (result.exitCode != 0) {
      throw Exception(result.stderr.toString().trim());
    }
    return result.stdout.toString().trim();
  }

  Future<List<DiskVolume>> disks() async {
    final output = await powershell(
      r"[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $ErrorActionPreference='Stop'; @(Get-CimInstance Win32_LogicalDisk | Where-Object { $_.Size -gt 0 } | Select-Object DeviceID,VolumeName,FileSystem,Size,FreeSpace,DriveType) | ConvertTo-Json -Compress",
    );
    if (output.isEmpty) return [];
    final data = jsonDecode(output);
    return (data is List ? data : [data])
        .map((j) => DiskVolume.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<void> reveal(String path) async {
    await Process.run('explorer.exe', ['/select,', path]);
  }

  Future<void> diskManager() async {
    final r = await Process.run('mmc.exe', ['diskmgmt.msc']);
    if (r.exitCode != 0) {
      throw StateError('Windows no pudo abrir el administrador de discos.');
    }
  }

  Future<void> installedApps() async {
    await Process.run('explorer.exe', ['ms-settings:appsfeatures']);
  }

  Future<void> storageSettings() async {
    await Process.run('explorer.exe', ['ms-settings:storagesense']);
  }

  Future<void> recycle(String path, {int? size, int? modified}) async {
    final blocked = PathPolicy.reason(path);
    if (blocked != null) throw StateError(blocked);
    if (await FileSystemEntity.type(path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw StateError('Solo se permiten archivos normales.');
    }
    final resolved = (await File(path).resolveSymbolicLinks()).toLowerCase();
    final protected = [
      Platform.environment['SystemRoot'] ?? r'C:\Windows',
      Platform.environment['ProgramFiles'],
      Platform.environment['ProgramFiles(x86)'],
      Platform.environment['ProgramData'],
    ].whereType<String>();
    if (protected.any(
          (p) =>
              resolved == p.toLowerCase() ||
              resolved.startsWith('${p.toLowerCase()}\\'),
        ) ||
        resolved.split('\\').length <= 2) {
      throw StateError('Archivo protegido. Gestiona el sistema desde Windows.');
    }
    if (size == null || modified == null) {
      throw StateError('Analiza el archivo antes de eliminarlo.');
    }
    await const MethodChannel('sizesoul/storage').invokeMethod<void>(
      'recycle',
      {'path': path, 'size': size, 'modified': modified},
    );
  }
}
