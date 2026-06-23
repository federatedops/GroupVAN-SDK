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

  /// Create a campaign, returning the created [Campaign].
  Future<Result<Campaign>> createCampaign(CampaignCreate campaign) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/catman/ads/campaigns',
        data: campaign.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(Campaign.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to create campaign: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to create campaign: $e'),
      );
    }
  }

  /// Update a campaign, returning the updated [Campaign].
  Future<Result<Campaign>> updateCampaign(
    int campaignId,
    CampaignUpdate update,
  ) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/catman/ads/campaigns/$campaignId',
        data: update.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(Campaign.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to update campaign: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to update campaign: $e'),
      );
    }
  }

  /// Soft-delete a campaign, returning the deleted campaign id.
  Future<Result<int>> deleteCampaign(int campaignId) async {
    try {
      final response = await delete<Map<String, dynamic>>(
        '/v3/catman/ads/campaigns/$campaignId',
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(response.data['campaign_id'] as int);
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to delete campaign: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to delete campaign: $e'),
      );
    }
  }

  /// Create an ad under a campaign, returning the new ad id.
  Future<Result<int>> createAd(int campaignId, AdUpdate ad) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/catman/ads/$campaignId/ads',
        data: ad.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(response.data['ad_id'] as int);
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to create ad: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to create ad: $e'),
      );
    }
  }

  /// Update an ad, returning the ad id.
  Future<Result<int>> updateAd(int adId, AdUpdate ad) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/catman/ads/ads/$adId',
        data: ad.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(response.data['ad_id'] as int);
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to update ad: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to update ad: $e'),
      );
    }
  }

  /// Soft-delete an ad, returning the deleted ad id.
  Future<Result<int>> deleteAd(int adId) async {
    try {
      final response = await delete<Map<String, dynamic>>(
        '/v3/catman/ads/ads/$adId',
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(response.data['ad_id'] as int);
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to delete ad: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to delete ad: $e'),
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

  /// Create a campaign, returning the created [Campaign].
  Future<Campaign> createCampaign(CampaignCreate campaign) async {
    final result = await _client.createCampaign(campaign);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Update a campaign, returning the updated [Campaign].
  Future<Campaign> updateCampaign(int campaignId, CampaignUpdate update) async {
    final result = await _client.updateCampaign(campaignId, update);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Soft-delete a campaign, returning the deleted campaign id.
  Future<int> deleteCampaign(int campaignId) async {
    final result = await _client.deleteCampaign(campaignId);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Create an ad under a campaign, returning the new ad id.
  Future<int> createAd(int campaignId, AdUpdate ad) async {
    final result = await _client.createAd(campaignId, ad);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Update an ad, returning the ad id.
  Future<int> updateAd(int adId, AdUpdate ad) async {
    final result = await _client.updateAd(adId, ad);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Soft-delete an ad, returning the deleted ad id.
  Future<int> deleteAd(int adId) async {
    final result = await _client.deleteAd(adId);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }
}
