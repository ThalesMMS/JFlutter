// Base service class to consolidate common patterns
// Reduces duplication across service implementations

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jflutter/core/result.dart';

/// Base service class with common HTTP and serialization patterns
abstract class BaseService {
  final http.Client _client;
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  BaseService({
    required this.baseUrl,
    http.Client? client,
    Map<String, String>? headers,
  }) : _client = client ?? http.Client(),
       defaultHeaders = headers ?? {
         'Content-Type': 'application/json',
         'Accept': 'application/json',
       };

  /// Execute HTTP GET request with error handling
  Future<Result<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _client.get(
        url,
        headers: {...defaultHeaders, ...?headers},
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return Failure('GET request failed: $e');
    }
  }

  /// Execute HTTP POST request with error handling
  Future<Result<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _client.post(
        url,
        headers: {...defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return Failure('POST request failed: $e');
    }
  }

  /// Execute HTTP PUT request with error handling
  Future<Result<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _client.put(
        url,
        headers: {...defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return Failure('PUT request failed: $e');
    }
  }

  /// Execute HTTP DELETE request with error handling
  Future<Result<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _client.delete(
        url,
        headers: {...defaultHeaders, ...?headers},
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return Failure('DELETE request failed: $e');
    }
  }

  /// Handle HTTP response with common error handling
  Result<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (fromJson != null) {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          final result = fromJson(jsonData);
          return Success(result);
        } else {
          return Success(response.body as T);
        }
      } catch (e) {
        return Failure('Failed to parse response: $e');
      }
    } else {
      return Failure('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// Serialize object to JSON
  String serializeToJson(Map<String, dynamic> data) {
    try {
      return jsonEncode(data);
    } catch (e) {
      throw Exception('Failed to serialize to JSON: $e');
    }
  }

  /// Deserialize JSON to object
  Map<String, dynamic> deserializeFromJson(String json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to deserialize from JSON: $e');
    }
  }

  /// Create query parameters from map
  String createQueryString(Map<String, dynamic> params) {
    final queryParams = params.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value.toString())}')
        .join('&');
    
    return queryParams.isNotEmpty ? '?$queryParams' : '';
  }

  /// Dispose of HTTP client
  void dispose() {
    _client.close();
  }
}
