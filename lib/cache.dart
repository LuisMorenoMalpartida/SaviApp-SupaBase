import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleCache {
  final SharedPreferences _prefs;
  SimpleCache._(this._prefs);

  static Future<SimpleCache> init() async {
    final p = await SharedPreferences.getInstance();
    return SimpleCache._(p);
  }

  Future<void> setJson(String key, dynamic value) async {
    final s = jsonEncode(value);
    await _prefs.setString(key, s);
  }

  dynamic getJson(String key) {
    final s = _prefs.getString(key);
    if (s == null) return null;
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }
}
