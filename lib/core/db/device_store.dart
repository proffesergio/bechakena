import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Device-level key/value store, kept in a small JSON file *outside* any module
/// database. It holds the few things that must be known before a module DB is
/// even opened: which module the device is running (`module`) and the UI theme
/// (`themeMode`, device-global so the app can paint before a DB exists).
///
/// Everything else stays inside the per-module Drift database (`Settings`
/// table) so it is isolated per module along with that module's data.
class DeviceStore {
  DeviceStore(this._file, this._values);

  final File _file;
  final Map<String, String> _values;

  static const _fileName = 'bechakena.device.json';

  /// Loads the store from disk once at startup (empty if absent or unreadable).
  static Future<DeviceStore> load() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, _fileName));
    var values = <String, String>{};
    if (await file.exists()) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map) {
          values = {
            for (final e in decoded.entries) '${e.key}': '${e.value}',
          };
        }
      } catch (_) {
        // Corrupt file → start empty rather than block launch.
      }
    }
    return DeviceStore(file, values);
  }

  String? get(String key) => _values[key];

  Future<void> set(String key, String? value) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
    await _file.writeAsString(jsonEncode(_values));
  }
}
