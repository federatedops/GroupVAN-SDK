/// Reports API: low-level [ReportsClient] and public [GroupVANReports].
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/exceptions.dart';
import '../core/response.dart';
import '../logging.dart';
import '../models/models.dart';
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

  /// Report a catalog discrepancy for the signed-in user
  Future<Result<Discrepancy>> createDiscrepancy(
    DiscrepancyCreateRequest request,
  ) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/reports/discrepancies',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(Discrepancy.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.reports.severe('Failed to create discrepancy: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to create discrepancy: $e'),
      );
    }
  }

  /// Get a discrepancy reported by the signed-in user
  Future<Result<Discrepancy>> getDiscrepancy(int discrepancyId) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/reports/discrepancies/$discrepancyId',
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(Discrepancy.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.reports.severe('Failed to get discrepancy: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get discrepancy: $e'),
      );
    }
  }

  /// Attach a screenshot to a discrepancy; one per discrepancy, png/jpg/jpeg
  /// up to 10 MB, so [filename] must carry the image extension
  Future<Result<DiscrepancyScreenshotResponse>> uploadDiscrepancyScreenshot({
    required int discrepancyId,
    required Uint8List screenshot,
    String filename = 'screenshot.png',
  }) async {
    try {
      final formData = FormData.fromMap({
        'screenshot': MultipartFile.fromBytes(screenshot, filename: filename),
      });

      final response = await post<Map<String, dynamic>>(
        '/v3/reports/discrepancies/$discrepancyId/screenshot',
        data: formData,
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(DiscrepancyScreenshotResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.reports.severe(
        'Failed to upload discrepancy screenshot: $e',
      );
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to upload discrepancy screenshot: $e'),
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
  }) => _client.createReport(screenshot: screenshot, title: title, body: body);

  /// Report a catalog discrepancy for the signed-in user
  Future<Discrepancy> createDiscrepancy(
    DiscrepancyCreateRequest request,
  ) async {
    final result = await _client.createDiscrepancy(request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get a discrepancy reported by the signed-in user
  Future<Discrepancy> getDiscrepancy(int discrepancyId) async {
    final result = await _client.getDiscrepancy(discrepancyId);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Attach a screenshot to a discrepancy; one per discrepancy, png/jpg/jpeg
  /// up to 10 MB, so [filename] must carry the image extension
  Future<DiscrepancyScreenshotResponse> uploadDiscrepancyScreenshot({
    required int discrepancyId,
    required Uint8List screenshot,
    String filename = 'screenshot.png',
  }) async {
    final result = await _client.uploadDiscrepancyScreenshot(
      discrepancyId: discrepancyId,
      screenshot: screenshot,
      filename: filename,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }
}
