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

  static Future<dynamic> get(String endpoint) async {
    final String url = '$baseUrl$endpoint';
    final Map<String, String> headers = await _getHeaders();
    final http.Response response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final dynamic body = jsonDecode(response.body);
      final String msg = body['detail'] ?? 'Bir hata oluştu (${response.statusCode})';
      throw Exception(msg);
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
      final dynamic body = jsonDecode(response.body);
      final String msg = body['detail'] ?? 'Bir hata oluştu (${response.statusCode})';
      throw Exception(msg);
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
      final dynamic body = jsonDecode(response.body);
      final String msg = body['detail'] ?? 'Bir hata oluştu (${response.statusCode})';
      throw Exception(msg);
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    final String url = '$baseUrl$endpoint';
    final Map<String, String> headers = await _getHeaders();
    final http.Response response = await http.delete(Uri.parse(url), headers: headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final dynamic body = jsonDecode(response.body);
      final String msg = body['detail'] ?? 'Bir hata oluştu (${response.statusCode})';
      throw Exception(msg);
    }
  }
}
