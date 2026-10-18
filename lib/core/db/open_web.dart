import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// Web counterpart of the native file-backed opener. The browser has no
/// filesystem: each module becomes its own IndexedDB-backed WASM database
/// (same per-module isolation, different storage). The worker + wasm module
/// are served next to the app (`web/drift_worker.js`, `web/sqlite3.wasm`).
///
/// Without COOP/COEP headers Drift falls back from its shared-memory
/// implementation — slightly slower, entirely fine for a demo.

QueryExecutor openAppDatabase(String module) {
  return LazyDatabase(() async {
    debugPrint('[drift-web] opening $module');
    try {
      final result = await WasmDatabase.open(
        databaseName: 'bechakena_$module',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      debugPrint(
          '[drift-web] $module opened via ${result.chosenImplementation} '
          '(missing: ${result.missingFeatures})');
      return result.resolvedExecutor;
    } catch (e, st) {
      debugPrint('[drift-web] $module FAILED: $e');
      debugPrint('$st');
      rethrow;
    }
  });
}

/// No legacy single-file database exists on the web.
Future<void> archiveLegacyDatabase() async {}

/// "Clear local data" on the web: delete this module's IndexedDB database and
/// reload, which restarts the module from a fresh owner setup.
Future<void> armWipe(String module) async {
  // Databases live in IndexedDB under names like `bechakena_<module>`.
  // Deleting via the Cache/IndexedDB APIs from the UI thread is unreliable
  // while the worker holds the DB, so the web demo resets via
  // Settings → Clear data → reload after the visitor clears site data, or by
  // visiting with ?fresh=1. No sentinel file is involved.
  throw UnsupportedError(
      'Use ?fresh=1 to reset the browser demo data');
}

/// Browser backups are produced as file downloads from the receipt/report
/// screens; restoring a backup file is a desktop-app feature.
Future<void> stageRestore(String module, List<int> bytes) async {
  throw UnsupportedError('Restoring a backup file is a desktop-app feature');
}
