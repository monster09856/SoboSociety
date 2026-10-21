import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static const String baseUrl = 'https://sobosociety.com/api/v1';
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 3;

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
    if (response.statusCode >= 500) {
      return 'Sunucu ile bağlantı kurulurken geçici bir gecikme yaşandı. Lütfen birkaç saniye sonra tekrar deneyin.';
    }
    try {
      final dynamic body = jsonDecode(response.body);
      if (body is Map) {
        final dynamic detail = body['detail'] ?? body['detay'] ?? body['message'];
        if (detail is String && detail.isNotEmpty) {
          if (detail.contains('Cloudflare') || detail.contains('origin server') || detail.contains('TCP')) {
            return 'Sunucu ile bağlantı kurulurken geçici bir gecikme yaşandı. Lütfen tekrar deneyin.';
          }
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

  static bool _shouldRetryStatus(int statusCode) {
    return statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504 ||
        statusCode >= 520;
  }

  static Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() requestFn,
  ) async {
    Object? lastError;
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final http.Response response = await requestFn().timeout(_timeout);
        if (_shouldRetryStatus(response.statusCode) && attempt < _maxRetries) {
          await Future<void>.delayed(Duration(milliseconds: 800 * attempt));
          continue;
        }
        return response;
      } catch (e) {
        lastError = e;
        if (attempt < _maxRetries) {
          await Future<void>.delayed(Duration(milliseconds: 800 * attempt));
          continue;
        }
      }
    }
    throw ApiException(
      'İnternet veya sunucu bağlantısı kurulamadı. Lütfen bağlantınızı kontrol edip tekrar deneyin. (${lastError ?? ""})',
    );
  }

  static Future<dynamic> get(String endpoint) async {
    final String url = '$baseUrl$endpoint';
    final Map<String, String> headers = await _getHeaders();
    final http.Response response = await _sendWithRetry(
      () => http.get(Uri.parse(url), headers: headers),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        _extractErrorMessage(response),
        statusCode: response.statusCode,
      );
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final String url = '$baseUrl$endpoint';
    final Map<String, String> headers = await _getHeaders();
    final http.Response response = await _sendWithRetry(
      () => http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        _extractErrorMessage(response),
        statusCode: response.statusCode,
      );
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final String url = '$baseUrl$endpoint';
    final Map<String, String> headers = await _getHeaders();
    final http.Response response = await _sendWithRetry(
      () => http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        _extractErrorMessage(response),
        statusCode: response.statusCode,
      );
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    final String url = '$baseUrl$endpoint';
    final Map<String, String> headers = await _getHeaders();
    final http.Response response = await _sendWithRetry(
      () => http.delete(Uri.parse(url), headers: headers),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return <String, dynamic>{};
      }
    } else {
      throw ApiException(
        _extractErrorMessage(response),
        statusCode: response.statusCode,
      );
    }
  }
}
