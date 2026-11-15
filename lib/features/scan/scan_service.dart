import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../../core/models/storage_models.dart';

class ScanService {
  Isolate? _worker;
  ReceivePort? _port;
  Completer<ScanResult>? _pending;
  Future<ScanResult> scan(String path, void Function(int, String) progress) {
    cancel();
    final port = ReceivePort();
    _port = port;
    final pending = Completer<ScanResult>();
    _pending = pending;
    port.listen((message) {
      if (!identical(_pending, pending)) return;
      if (message is ScanResult) {
        pending.complete(message);
        _cleanup();
      } else if (message is List && message.first == 'progress') {
        progress(message[1] as int, message[2] as String);
      } else if (message is List && message.first == 'error') {
        pending.completeError(StateError(message[1] as String));
        _cleanup();
      } else {
        pending.completeError(
          StateError('El motor de análisis se interrumpió.'),
        );
        _cleanup();
      }
    });
    unawaited(
      Isolate.spawn(
        _scan,
        [path, port.sendPort],
        onError: port.sendPort,
        onExit: port.sendPort,
        errorsAreFatal: true,
      ).then(
        (worker) {
          if (identical(_pending, pending)) {
            _worker = worker;
          } else {
            worker.kill(priority: Isolate.immediate);
          }
        },
        onError: (Object error, StackTrace trace) {
          if (identical(_pending, pending)) {
            pending.completeError(error, trace);
            _cleanup();
          }
        },
      ),
    );
    return pending.future;
  }

  void _cleanup() {
    _worker?.kill(priority: Isolate.immediate);
    _worker = null;
    _port?.close();
    _port = null;
    _pending = null;
  }

  void cancel() {
    final pending = _pending;
    _cleanup();
    if (pending != null && !pending.isCompleted) {
      pending.completeError(StateError('Escaneo cancelado'));
    }
  }
}

void _scan(List<Object> args) {
  final path = p.normalize(Directory(args[0] as String).absolute.path);
  final send = args[1] as SendPort;
  final clock = Stopwatch()..start();
  var skipped = 0, count = 0, lastUpdate = 0;
  final largest = <FileNode>[];
  try {
    if (FileSystemEntity.typeSync(path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw StateError('La carpeta no existe o no está disponible.');
    }
    final root = FileNode(path, true);
    final stack = <FileNode>[root], directories = <FileNode>[];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      directories.add(node);
      try {
        for (final entity in Directory(
          node.path,
        ).listSync(followLinks: false)) {
          final type = FileSystemEntity.typeSync(
            entity.path,
            followLinks: false,
          );
          if (type == FileSystemEntityType.link) {
            skipped++;
            continue;
          }
          if (type != FileSystemEntityType.file &&
              type != FileSystemEntityType.directory) {
            continue;
          }
          final child = FileNode(
            entity.path,
            type == FileSystemEntityType.directory,
          );
          if (child.directory) {
            node.children.add(child);
            stack.add(child);
          } else {
            try {
              final stat = File(entity.path).statSync();
              child.size = stat.size;
              child.modifiedMs = stat.modified.millisecondsSinceEpoch;
              child.files = 1;
              node.size += child.size;
              node.files++;
              count++;
              largest.add(child);
              if (largest.length > 400) {
                largest.sort((a, b) => b.size.compareTo(a.size));
                largest.removeRange(200, largest.length);
              }
            } on FileSystemException {
              skipped++;
            }
          }
          if (clock.elapsedMilliseconds - lastUpdate > 200) {
            send.send(['progress', count, node.path]);
            lastUpdate = clock.elapsedMilliseconds;
          }
        }
      } on FileSystemException {
        skipped++;
      }
    }
    for (final node in directories.reversed) {
      for (final child in node.children) {
        node.size += child.size;
        node.files += child.files;
      }
      node.children.sort((a, b) => b.size.compareTo(a.size));
    }
    largest.sort((a, b) => b.size.compareTo(a.size));
    send.send(
      ScanResult(
        root,
        skipped,
        clock.elapsedMilliseconds,
        largest.take(200).toList(),
      ),
    );
  } catch (error) {
    send.send(['error', error.toString()]);
  }
}
