import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;

  ApiException(this.statusCode, this.message, {this.data});

  @override
  String toString() {
    return 'ApiException: $statusCode - $message';
  }
}

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String _tokenKey = 'jwt_token';
  String? _jwtToken;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Para testes
  http.Client httpClient = http.Client();

  // Singleton pattern
  ApiClient._privateConstructor();
  static final ApiClient instance = ApiClient._privateConstructor();

  Future<void> init() async {
    try {
      _jwtToken = await _secureStorage.read(key: _tokenKey);
    } catch (_) {}
  }

  Future<void> saveToken(String token) async {
    _jwtToken = token;
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (_) {}
  }

  Future<void> clearToken() async {
    _jwtToken = null;
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {}
  }

  bool get isAuthenticated => _jwtToken != null;

  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_jwtToken != null) {
      headers['Authorization'] = 'Bearer $_jwtToken';
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      String message = 'Erro de requisição';
      Map<String, dynamic>? errorData;

      try {
        errorData = jsonDecode(utf8.decode(response.bodyBytes));
        // Suporta formato ProblemDetail do Spring
        if (errorData != null && errorData.containsKey('detail')) {
          message = errorData['detail'];
        } else if (errorData != null && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } catch (_) {
        message = utf8.decode(response.bodyBytes);
      }

      throw ApiException(response.statusCode, message, data: errorData);
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await httpClient.get(uri, headers: _buildHeaders(headers));
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await httpClient.post(
      uri,
      headers: _buildHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await httpClient.put(
      uri,
      headers: _buildHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await httpClient.delete(uri, headers: _buildHeaders(headers));
    return _handleResponse(response);
  }
}
