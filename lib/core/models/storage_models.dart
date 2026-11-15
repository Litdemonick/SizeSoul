import 'package:path/path.dart' as p;

String bytes(int value) {
  const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];
  var number = value.toDouble();
  var unit = 0;
  while (number >= 1024 && unit < units.length - 1) {
    number /= 1024;
    unit++;
  }
  return '${number.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}

class DiskVolume {
  final String id, label, fileSystem;
  final int total, free, type;
  const DiskVolume(
    this.id,
    this.label,
    this.fileSystem,
    this.total,
    this.free,
    this.type,
  );
  String get root => '$id\\';
  int get used => total - free;
  factory DiskVolume.fromJson(Map<String, dynamic> j) => DiskVolume(
    j['DeviceID'] ?? '',
    j['VolumeName'] ?? 'Sin etiqueta',
    j['FileSystem'] ?? 'Desconocido',
    (j['Size'] as num?)?.toInt() ?? 0,
    (j['FreeSpace'] as num?)?.toInt() ?? 0,
    j['DriveType'] ?? 0,
  );
}

class FileNode {
  final String path;
  final bool directory;
  int size = 0, files = 0, modifiedMs = 0;
  final List<FileNode> children = [];
  FileNode(this.path, this.directory);
  String get name => p.basename(path).isEmpty ? path : p.basename(path);
}

class ScanResult {
  final FileNode root;
  final int skipped, elapsedMs;
  final List<FileNode> largest;
  ScanResult(this.root, this.skipped, this.elapsedMs, this.largest);
}
