/// Reports API: low-level [ReportsClient] and public [GroupVANReports].
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/exceptions.dart';
import '../core/response.dart';
import '../logging.dart';
import 'base_client.dart';

class ReportsClient extends ApiClient {
  const ReportsClient(super.httpClient, super.authManager);

  Future<Result<void>> createReport({
    required Uint8List screenshot,
    String? title,
    String? body,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'screenshot': MultipartFile.fromBytes(
          screenshot,
          filename: 'screenshot.png',
        ),
        'title': title,
        'body': body,
      });

      await post('/v3/reports/', data: formData);
      return const Success(null);
    } catch (e) {
      GroupVanLogger.reports.severe('Failed to create report: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to create report: $e'),
      );
    }
  }
}

/// Namespaced reports API
class GroupVANReports {
  final ReportsClient _client;

  const GroupVANReports(this._client);

  Future<void> createReport({
    required Uint8List screenshot,
    String? title,
    String? body,
  }) =>
      _client.createReport(screenshot: screenshot, title: title, body: body);
}
