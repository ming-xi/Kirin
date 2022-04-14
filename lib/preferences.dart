import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

Preferences preferences = Preferences._internal();

class Preferences {
  /// 顶层变量，单例模式
  Preferences._internal();

  static const keyLastDirectoryPath = "keyLastDirectoryPath";

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint("Preferences ready");
  }

  late SharedPreferences _prefs;

  bool hasKey(String key) {
    return _prefs.containsKey(key);
  }

  String? getString(String key, {String? def}) {
    var value = _prefs.getString(key);
    return value ?? def;
  }

  int? getInt(String key, {int? def}) {
    var value = _prefs.getInt(key);
    return value ?? def;
  }

  double? getDouble(String key, {double? def}) {
    var value = _prefs.getDouble(key);
    return value ?? def;
  }

  bool? getBool(String key, {bool? def}) {
    var value = _prefs.getBool(key);
    return value ?? def;
  }

  void putString(String key, String? value) {
    if (value == null) {
      _prefs.remove(key);
      return;
    }
    _prefs.setString(key, value);
  }

  void putInt(String key, int? value) async {
    if (value == null) {
      _prefs.remove(key);
      return;
    }
    _prefs.setInt(key, value);
  }

  void putDouble(String key, double? value) async {
    if (value == null) {
      _prefs.remove(key);
      return;
    }
    _prefs.setDouble(key, value);
  }

  void putBool(String key, bool? value) async {
    if (value == null) {
      _prefs.remove(key);
      return;
    }
    _prefs.setBool(key, value);
  }
}
