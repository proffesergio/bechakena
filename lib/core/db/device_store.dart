// Device-level key/value store (module choice + theme) persisted *outside*
// any module database. Native writes a small JSON file; web uses
// localStorage — same API either way.
export 'device_store_io.dart'
    if (dart.library.js_interop) 'device_store_web.dart';
