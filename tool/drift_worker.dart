import 'package:drift/wasm.dart';

// Recompile with the locked dependencies whenever Drift or sqlite3 changes:
// dart compile js -O4 tool/drift_worker.dart -o web/drift_worker.js
void main() => WasmDatabase.workerMainForOpen();
