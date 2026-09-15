import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiClient {
  static const String baseUrl = 'https://sobosociety.com/api/v1';

  static Future<Map<String, String>> _getHeaders() async {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final String? token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String _extractErrorMessage(http.Response response) {
    try {
      final dynamic body = jsonDecode(response.body);
      if (body is Map) {
        final dynamic detail = body['detail'] ?? body['detay'] ?? body['message'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
          return first.toString();
        }
      }
    } catch (_) {}
    return 'İşlem tamamlanamadı (${response.statusCode})';
  }

  static Future<dynamic> get(String endpoint) async {
    final String url = '$baseUrl$endpoint';
    final Map<String, String> headers = await _getHeaders();
    final http.Response response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final String url = '$baseUrl$endpoint';
    final Map<String, String> headers = await _getHeaders();
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final String url = '$baseUrl$endpoint';
    final Map<String, String> headers = await _getHeaders();
    final http.Response response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    final String url = '$baseUrl$endpoint';
    final Map<String, String> headers = await _getHeaders();
    final http.Response response = await http.delete(Uri.parse(url), headers: headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }
}
