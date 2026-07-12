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

/// Sentinel written by "Clear local data": the live DB file is deleted on next
/// launch so the app starts empty (fresh owner setup). Can't drop the open file.
Future<File> pendingWipeFile() async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, 'bechakena.wipe'));
}

QueryExecutor openAppDatabase() {
  return LazyDatabase(() async {
    final file = await databaseFile();
    // A pending wipe takes effect before anything else: drop the old DB.
    final wipe = await pendingWipeFile();
    if (await wipe.exists()) {
      if (await file.exists()) await file.delete();
      await wipe.delete();
    }
    final restore = await pendingRestoreFile();
    if (await restore.exists()) {
      await restore.copy(file.path);
      await restore.delete();
    }
    return NativeDatabase.createInBackground(file);
  });
}
