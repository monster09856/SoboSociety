import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'sobo_jwt_token';

  static Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isAuthenticated() async {
    final String? token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
