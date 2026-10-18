// Opens the per-module SQLite database. Native uses a real file via
// `NativeDatabase`; web uses Drift's WASM build backed by IndexedDB.
export 'open_io.dart' if (dart.library.js_interop) 'open_web.dart';
