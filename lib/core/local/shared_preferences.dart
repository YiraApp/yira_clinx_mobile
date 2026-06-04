import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  final SharedPreferences _prefs;
  SharedPrefsService(this._prefs);

  Future<bool> setValue<T>(String key, T value) async {
    try {
      if (value is String) return await _prefs.setString(key, value);
      if (value is bool) return await _prefs.setBool(key, value);
      if (value is int) return await _prefs.setInt(key, value);
      if (value is double) return await _prefs.setDouble(key, value);
      if (value is List<String>) return await _prefs.setStringList(key, value);
      throw Exception("Unsupported Type");
    } catch (e) {
      print("SharedPrefsService Error: $e");
      return false;
    }
  }

  T? getValue<T>(String key) {
    try {
      return _prefs.get(key) as T?;
    } catch (e) {
      print("SharedPrefsService Read Error: $e");
      return null;
    }
  }
  Future<bool> clearAll() async {
    try {
      return await _prefs.clear();
    } catch (e) {
      print("SharedPrefsService Clear Error: $e");
      return false;
    }
  }
  List<String> getStringList(String key) {
    return _prefs.getStringList(key) ?? [];
  }

  Future<void> addIdToList(String key, String id) async {
    List<String> current = _prefs.getStringList(key) ?? [];
    if (!current.contains(id)) {
      current.add(id);
      await _prefs.setStringList(key, current);
    }
  }

  Future<void> removeIdFromList(String key, String id) async {
    List<String> current = _prefs.getStringList(key) ?? [];
    current.remove(id);
    await _prefs.setStringList(key, current);
  }
}