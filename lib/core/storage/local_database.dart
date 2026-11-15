import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/storage_models.dart';

class LocalDatabase {
  final Database db;
  LocalDatabase._(this.db);
  static Future<LocalDatabase> open() async {
    sqfliteFfiInit();
    final folder = await getApplicationSupportDirectory();
    await folder.create(recursive: true);
    final db = await databaseFactoryFfi.openDatabase(
      p.join(folder.path, 'sizesoul.db'),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE scans (id INTEGER PRIMARY KEY, path TEXT NOT NULL, bytes INTEGER NOT NULL, files INTEGER NOT NULL, skipped INTEGER NOT NULL, duration INTEGER NOT NULL, created TEXT NOT NULL)',
          );
        },
      ),
    );
    return LocalDatabase._(db);
  }

  Future<String?> setting(String key) async {
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> set(String key, String value) async {
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> save(ScanResult r) async {
    await db.transaction((txn) async {
      await txn.insert('scans', {
        'path': r.root.path,
        'bytes': r.root.size,
        'files': r.root.files,
        'skipped': r.skipped,
        'duration': r.elapsedMs,
        'created': DateTime.now().toIso8601String(),
      });
      await txn.execute(
        'DELETE FROM scans WHERE id NOT IN (SELECT id FROM scans ORDER BY id DESC LIMIT 100)',
      );
    });
  }

  Future<List<Map<String, Object?>>> history() =>
      db.query('scans', orderBy: 'id DESC', limit: 100);
  Future<void> clearHistory() async {
    await db.delete('scans');
  }
}
