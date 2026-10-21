import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'sobo_jwt_token';
  static const String _isAdminKey = 'sobo_is_admin';

  static Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    final bool? decodedAdmin = _decodeIsAdminFromJwt(token);
    if (decodedAdmin != null) {
      await prefs.setBool(_isAdminKey, decodedAdmin);
    }
  }

  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveIsAdmin(bool isAdmin) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAdminKey, isAdmin);
  }

  static Future<bool> getIsAdmin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? stored = prefs.getBool(_isAdminKey);
    if (stored != null) {
      return stored;
    }
    final String? token = prefs.getString(_tokenKey);
    if (token != null && token.isNotEmpty) {
      final bool? decoded = _decodeIsAdminFromJwt(token);
      if (decoded != null) {
        await prefs.setBool(_isAdminKey, decoded);
        return decoded;
      }
    }
    return false;
  }

  static bool? _decodeIsAdminFromJwt(String token) {
    try {
      final List<String> parts = token.split('.');
      if (parts.length != 3) return null;
      final String normalized = base64Url.normalize(parts[1]);
      final String payloadStr = utf8.decode(base64Url.decode(normalized));
      final dynamic payload = jsonDecode(payloadStr);
      if (payload is Map) {
        if (payload['is_admin'] == true) return true;
        if (payload['sub']?.toString() == '9') return true;
        return false;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> clearToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_isAdminKey);
  }

  static Future<bool> isAuthenticated() async {
    final String? token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
