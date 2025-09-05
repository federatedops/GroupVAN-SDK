import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../logging.dart';

typedef Json = Map<String, dynamic>;

/// Response wrapper that includes both body and session ID from headers
class ApiResponse {
  final dynamic body;
  final String? sessionId;

  ApiResponse({required this.body, this.sessionId});
}

/// Custom exception for API-related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;

  ApiException(this.message, {this.statusCode, this.endpoint});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $message (Status: $statusCode)';
    }
    return 'ApiException: $message';
  }
}

/// Configuration for API endpoints and URLs
class ApiConfig {
  static String v3BaseUrl = 'https://api.staging.groupvan.com';
  static String token = const String.fromEnvironment('GROUPVAN_TOKEN');

  /// Generate a unique session ID if none exists
  static String generateSessionId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = (now * 1000 + (now % 1000)).toString();
    return 'flutter-session-$random';
  }
}

/// Base class for API clients with common HTTP functionality
abstract class BaseApiClient {
  final http.Client _client;

  BaseApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Sends a GET request to the specified endpoint
  Future<Json> get(String endpoint, {String? baseUrl}) async {
    final fullUrl = Uri.parse('${baseUrl ?? ApiConfig.v3BaseUrl}/$endpoint');

    GroupVanLogger.apiClient.fine('GET request: $fullUrl');

    try {
      final response = await _client.get(
        fullUrl,
        headers: {'Authorization': 'Bearer ${ApiConfig.token}'},
      );

      GroupVanLogger.apiClient.fine('GET response: ${response.statusCode} for $endpoint');

      if (response.statusCode != 200) {
        GroupVanLogger.apiClient.warning('GET request failed: ${response.statusCode} for $endpoint - ${response.body}');
        throw ApiException(
          'GET request failed',
          statusCode: response.statusCode,
          endpoint: endpoint,
        );
      }

      return jsonDecode(response.body) as Json;
    } catch (e) {
      if (e is ApiException) rethrow;
      GroupVanLogger.apiClient.severe('Network error for GET $endpoint: ${e.toString()}');
      throw ApiException('Network error: ${e.toString()}', endpoint: endpoint);
    }
  }

  /// Sends a GET request and returns ApiResponse with body and session ID
  Future<ApiResponse> getWithSession(String endpoint, {String? baseUrl}) async {
    final fullUrl = Uri.parse('${baseUrl ?? ApiConfig.v3BaseUrl}/$endpoint');

    GroupVanLogger.apiClient.fine('GET (with session) request: $fullUrl');

    try {
      final response = await _client.get(
        fullUrl,
        headers: {'Authorization': 'Bearer ${ApiConfig.token}'},
      );

      GroupVanLogger.apiClient.fine('GET (with session) response: ${response.statusCode} for $endpoint');

      if (response.statusCode != 200) {
        GroupVanLogger.apiClient.warning('GET (with session) request failed: ${response.statusCode} for $endpoint - ${response.body}');
        throw ApiException(
          'GET request failed',
          statusCode: response.statusCode,
          endpoint: endpoint,
        );
      }

      // Try different possible header names for session ID
      String? sessionId = response.headers['gv-session-id'] ??
          response.headers['GroupVAN-Session-ID'] ??
          response.headers['groupvan-session-id'] ??
          response.headers['session-id'];

      final body = jsonDecode(response.body);

      // If no session ID in headers, check if it's in the response body
      if (sessionId == null &&
          body is Map<String, dynamic> &&
          body.containsKey('session_id')) {
        sessionId = body['session_id'] as String?;
      }

      if (sessionId != null) {
        GroupVanLogger.apiClient.fine('Session ID received: $sessionId for $endpoint');
      }

      return ApiResponse(body: body, sessionId: sessionId);
    } catch (e) {
      if (e is ApiException) rethrow;
      GroupVanLogger.apiClient.severe('Network error for GET (with session) $endpoint: ${e.toString()}');
      throw ApiException('Network error: ${e.toString()}', endpoint: endpoint);
    }
  }


  /// Sends a POST request to the specified endpoint
  Future<Json> post(String endpoint, Json body, {String? baseUrl}) async {
    final fullUrl = Uri.parse('${baseUrl ?? ApiConfig.v3BaseUrl}/$endpoint');

    GroupVanLogger.apiClient.fine('POST request: $fullUrl');

    try {
      final response = await _client.post(
        fullUrl,
        headers: {
          'Authorization': 'Bearer ${ApiConfig.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      GroupVanLogger.apiClient.fine('POST response: ${response.statusCode} for $endpoint');

      if (response.statusCode != 200) {
        GroupVanLogger.apiClient.warning('POST request failed: ${response.statusCode} for $endpoint - ${response.body}');
        throw ApiException(
          'POST request failed',
          statusCode: response.statusCode,
          endpoint: endpoint,
        );
      }

      return jsonDecode(response.body) as Json;
    } catch (e) {
      if (e is ApiException) rethrow;
      GroupVanLogger.apiClient.severe('Network error for POST $endpoint: ${e.toString()}');
      throw ApiException('Network error: ${e.toString()}', endpoint: endpoint);
    }
  }

  /// Sends a GET request that returns a List instead of Json
  Future<List<dynamic>> getList(String endpoint,
      {String? baseUrl, String? sessionId}) async {
    final fullUrl = Uri.parse('${baseUrl ?? ApiConfig.v3BaseUrl}/$endpoint');
    http.Response? response;

    try {
      final headers = {'Authorization': 'Bearer ${ApiConfig.token}'};

      if (sessionId != null) {
        headers['gv-session-id'] = sessionId;
      }

      response = await _client.get(
        fullUrl,
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'GET request failed',
          statusCode: response.statusCode,
          endpoint: endpoint,
        );
      }

      // Handle empty response body gracefully
      if (response.body.trim().isEmpty) {
        return <dynamic>[];
      }

      return jsonDecode(response.body) as List<dynamic>;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', endpoint: endpoint);
    }
  }
}
