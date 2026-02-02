import 'package:shared_preferences/shared_preferences.dart';

class AuthPrefs {
  static const _keyToken = 'user_token';

  /// Save / update the current user token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  /// Read the current user token, or null if not logged in
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Convenience: check if a token exists
  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyToken) &&
        (prefs.getString(_keyToken)?.isNotEmpty ?? false);
  }

  /// Remove the saved token (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }
}
