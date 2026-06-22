/// Catman API: low-level [CatmanClient] and public [GroupVANCatman].
library;

import '../core/exceptions.dart';
import '../core/response.dart';
import '../logging.dart';
import '../models/models.dart';
import 'base_client.dart';

/// Catman (catalog management) API client.
class CatmanClient extends ApiClient {
  const CatmanClient(super.httpClient, super.authManager);

  /// Get active ad campaigns for the authenticated member.
  Future<Result<List<Campaign>>> getCampaigns() async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/catman/ads/campaigns',
        decoder: (data) => data as List<dynamic>,
      );

      final campaigns = response.data
          .map((item) => Campaign.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(campaigns);
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to get campaigns: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get campaigns: $e'),
      );
    }
  }
}

/// Namespaced catman API
class GroupVANCatman {
  final CatmanClient _client;

  const GroupVANCatman(this._client);

  /// Get active ad campaigns for the authenticated member.
  Future<List<Campaign>> getCampaigns() async {
    final result = await _client.getCampaigns();
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }
}
