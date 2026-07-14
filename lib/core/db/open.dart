import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Each module (supershop / restaurant) runs in its **own** SQLite file, so
/// their sales, customers, staff and reports are physically isolated — one
/// module can never read another's data. [module] is the `BusinessType.name`
/// (e.g. 'superShop', 'restaurant').

/// The on-device SQLite file for [module] — that module's source of truth.
Future<File> databaseFile(String module) async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, 'bechakena_$module.db'));
}

/// A restore drops the picked backup here; it is swapped into [module]'s DB on
/// next launch (the live file can't be replaced while the database is open).
Future<File> pendingRestoreFile(String module) async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, 'bechakena_$module.restore.db'));
}

/// Sentinel written by "Clear local data": [module]'s DB file is deleted on
/// next launch so that module starts empty (fresh owner setup). Per-module, so
/// clearing one module never touches the other.
Future<File> pendingWipeFile(String module) async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, 'bechakena_$module.wipe'));
}

/// One-time retirement of the pre-split single database. Older builds kept all
/// modules in one `bechakena.db`; on first launch of the multi-DB build we move
/// it aside (kept, not deleted, so it stays recoverable) so both modules start
/// clean. No-op once archived or on fresh installs.
Future<void> archiveLegacyDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final legacy = File(p.join(dir.path, 'bechakena.db'));
  if (!await legacy.exists()) return;
  final archived = File(p.join(dir.path, 'bechakena.archived.db'));
  if (await archived.exists()) return; // already retired
  await legacy.rename(archived.path);
}

QueryExecutor openAppDatabase(String module) {
  return LazyDatabase(() async {
    final file = await databaseFile(module);
    // A pending wipe takes effect before anything else: drop the old DB.
    final wipe = await pendingWipeFile(module);
    if (await wipe.exists()) {
      if (await file.exists()) await file.delete();
      await wipe.delete();
    }
    final restore = await pendingRestoreFile(module);
    if (await restore.exists()) {
      await restore.copy(file.path);
      await restore.delete();
    }
    return NativeDatabase.createInBackground(file);
  });
}
