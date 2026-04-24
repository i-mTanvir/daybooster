import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const _keyName = 'architect_name';
  static const _keyOnboarded = 'onboarded';

  static Future<String?> getArchitectName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<void> setArchitectName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setBool(_keyOnboarded, true);
  }

  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarded) ?? false;
  }
}
