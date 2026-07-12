import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The on-device SQLite file — the offline source of truth.
Future<File> databaseFile() async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, 'bechakena.db'));
}

/// A restore drops the picked backup here; it is swapped in on next launch
/// (the live file can't be replaced while the database is open).
Future<File> pendingRestoreFile() async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, 'bechakena.restore.db'));
}

QueryExecutor openAppDatabase() {
  return LazyDatabase(() async {
    final file = await databaseFile();
    final restore = await pendingRestoreFile();
    if (await restore.exists()) {
      await restore.copy(file.path);
      await restore.delete();
    }
    return NativeDatabase.createInBackground(file);
  });
}
