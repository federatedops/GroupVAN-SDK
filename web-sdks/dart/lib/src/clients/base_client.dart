/// Base API client shared by all GroupVAN domain clients.
library;

import 'package:dio/dio.dart';

import '../auth/auth_manager.dart';
import '../core/http_client.dart';
import '../core/response.dart';

/// Base API client with common functionality
abstract class ApiClient {
  final GroupVanHttpClient httpClient;
  final AuthManager authManager;

  const ApiClient(this.httpClient, this.authManager);

  /// Make an authenticated GET request
  Future<GroupVanResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
    Options? options,
  }) async {
    // Ensure we have a valid (non-expired) token, refreshing if necessary,
    // before merging it into the request headers.
    final token = await authManager.getValidAccessToken();
    final headers = <String, dynamic>{
      'Authorization': 'Bearer $token',
      ...?options?.headers,
    };

    return await httpClient.get<T>(
      path,
      queryParameters: queryParameters,
      decoder: decoder,
      options: Options(
        headers: headers,
        method: options?.method,
        sendTimeout: options?.sendTimeout,
        receiveTimeout: options?.receiveTimeout,
        extra: options?.extra,
        followRedirects: options?.followRedirects,
        maxRedirects: options?.maxRedirects,
        persistentConnection: options?.persistentConnection,
        requestEncoder: options?.requestEncoder,
        responseDecoder: options?.responseDecoder,
        responseType: options?.responseType,
        validateStatus: options?.validateStatus,
      ),
    );
  }

  /// Make an authenticated POST request
  Future<GroupVanResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
    Options? options,
  }) async {
    // Ensure we have a valid (non-expired) token, refreshing if necessary,
    // before merging it into the request headers.
    final token = await authManager.getValidAccessToken();
    final headers = <String, dynamic>{
      'Authorization': 'Bearer $token',
      ...?options?.headers,
    };

    return await httpClient.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      decoder: decoder,
      options: Options(
        headers: headers,
        method: options?.method,
        sendTimeout: options?.sendTimeout,
        receiveTimeout: options?.receiveTimeout,
        extra: options?.extra,
        followRedirects: options?.followRedirects,
        maxRedirects: options?.maxRedirects,
        persistentConnection: options?.persistentConnection,
        requestEncoder: options?.requestEncoder,
        responseDecoder: options?.responseDecoder,
        responseType: options?.responseType,
        validateStatus: options?.validateStatus,
      ),
    );
  }

  /// Make an authenticated PUT request
  Future<GroupVanResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
    Options? options,
  }) async {
    // Ensure we have a valid (non-expired) token, refreshing if necessary,
    // before merging it into the request headers.
    final token = await authManager.getValidAccessToken();
    final headers = <String, dynamic>{
      'Authorization': 'Bearer $token',
      ...?options?.headers,
    };

    return await httpClient.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      decoder: decoder,
      options: Options(
        headers: headers,
        method: options?.method,
        sendTimeout: options?.sendTimeout,
        receiveTimeout: options?.receiveTimeout,
        extra: options?.extra,
        followRedirects: options?.followRedirects,
        maxRedirects: options?.maxRedirects,
        persistentConnection: options?.persistentConnection,
        requestEncoder: options?.requestEncoder,
        responseDecoder: options?.responseDecoder,
        responseType: options?.responseType,
        validateStatus: options?.validateStatus,
      ),
    );
  }

  /// Make an authenticated PATCH request
  Future<GroupVanResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
    Options? options,
  }) async {
    // Ensure we have a valid (non-expired) token, refreshing if necessary,
    // before merging it into the request headers.
    final token = await authManager.getValidAccessToken();
    final headers = <String, dynamic>{
      'Authorization': 'Bearer $token',
      ...?options?.headers,
    };

    return await httpClient.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      decoder: decoder,
      options: Options(
        headers: headers,
        method: options?.method,
        sendTimeout: options?.sendTimeout,
        receiveTimeout: options?.receiveTimeout,
        extra: options?.extra,
        followRedirects: options?.followRedirects,
        maxRedirects: options?.maxRedirects,
        persistentConnection: options?.persistentConnection,
        requestEncoder: options?.requestEncoder,
        responseDecoder: options?.responseDecoder,
        responseType: options?.responseType,
        validateStatus: options?.validateStatus,
      ),
    );
  }

  /// Make an authenticated DELETE request
  Future<GroupVanResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
    Options? options,
  }) async {
    // Ensure we have a valid (non-expired) token, refreshing if necessary,
    // before merging it into the request headers.
    final token = await authManager.getValidAccessToken();
    final headers = <String, dynamic>{
      'Authorization': 'Bearer $token',
      ...?options?.headers,
    };

    return await httpClient.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      decoder: decoder,
      options: Options(
        headers: headers,
        method: options?.method,
        sendTimeout: options?.sendTimeout,
        receiveTimeout: options?.receiveTimeout,
        extra: options?.extra,
        followRedirects: options?.followRedirects,
        maxRedirects: options?.maxRedirects,
        persistentConnection: options?.persistentConnection,
        requestEncoder: options?.requestEncoder,
        responseDecoder: options?.responseDecoder,
        responseType: options?.responseType,
        validateStatus: options?.validateStatus,
      ),
    );
  }
}
