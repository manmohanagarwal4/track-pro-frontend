import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin JSON key-value store over SharedPreferences (works on web & mobile).
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;
  static const _prefix = 'tp.';

  static Future<LocalStore> open() async => LocalStore(await SharedPreferences.getInstance());

  Object? readJson(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String key, Object? value) =>
      _prefs.setString('$_prefix$key', jsonEncode(value));

  Future<void> remove(String key) => _prefs.remove('$_prefix$key');

  /// Clears all TrackPro data except the keys in [keep].
  Future<void> clear({Set<String> keep = const {}}) async {
    for (final k in _prefs.getKeys().toList()) {
      if (k.startsWith(_prefix) && !keep.contains(k.substring(_prefix.length))) {
        await _prefs.remove(k);
      }
    }
  }
}
