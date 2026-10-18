import 'dart:convert';

import 'package:web/web.dart' as web;

/// Web counterpart of the file-backed device store: same map, persisted in
/// localStorage so the module choice and theme survive reloads. Cleared
/// entirely by visiting the app with `?fresh=1`.
class DeviceStore {
  DeviceStore._(this._values);

  final Map<String, String> _values;

  static const _key = 'bechakena.device';

  /// Loads the store from localStorage (empty if absent or unreadable).
  static Future<DeviceStore> load() async {
    var values = <String, String>{};
    final raw = web.window.localStorage.getItem(_key);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          values = {
            for (final e in decoded.entries) '${e.key}': '${e.value}',
          };
        }
      } catch (_) {
        // Corrupt entry → start empty rather than block launch.
      }
    }
    return DeviceStore._(values);
  }

  String? get(String key) => _values[key];

  Future<void> set(String key, String? value) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
    web.window.localStorage.setItem(_key, jsonEncode(_values));
  }
}
