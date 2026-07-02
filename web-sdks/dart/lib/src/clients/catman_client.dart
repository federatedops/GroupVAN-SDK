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

  /// List the authenticated member's custom catalogs.
  Future<Result<List<CustomCatalog>>> getCatalogs() async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/catman/custom_catalogs/',
        decoder: (data) => data as Map<String, dynamic>,
      );

      final catalogs = (response.data['catalogs'] as List<dynamic>? ?? const [])
          .map((c) => CustomCatalog.fromJson(c as Map<String, dynamic>))
          .toList();

      return Success(catalogs);
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to get catalogs: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get catalogs: $e'),
      );
    }
  }

  /// Create a custom catalog, returning the new catalog id.
  Future<Result<int>> createCatalog(CatalogCreateRequest catalog) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/catman/custom_catalogs/create',
        data: catalog.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(response.data['catalog_id'] as int);
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to create catalog: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to create catalog: $e'),
      );
    }
  }

  /// Update a custom catalog, returning the catalog id. Omitted fields on
  /// [update] are left unchanged (PATCH).
  Future<Result<int>> updateCatalog(
    int catalogId,
    CatalogUpdateRequest update,
  ) async {
    try {
      final response = await patch<Map<String, dynamic>>(
        '/v3/catman/custom_catalogs/$catalogId',
        data: update.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(response.data['catalog_id'] as int);
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to update catalog: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to update catalog: $e'),
      );
    }
  }

  /// Soft-delete a custom catalog, returning the deleted catalog id.
  Future<Result<int>> deleteCatalog(int catalogId) async {
    try {
      final response = await delete<Map<String, dynamic>>(
        '/v3/catman/custom_catalogs/$catalogId',
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(response.data['catalog_id'] as int);
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to delete catalog: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to delete catalog: $e'),
      );
    }
  }

  /// Import commodity rows into a catalog, returning the [CatalogImportResult].
  Future<Result<CatalogImportResult>> importCatalog(
    CatalogImportRequest request,
  ) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/catman/custom_catalogs/import',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(CatalogImportResult.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to import catalog: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to import catalog: $e'),
      );
    }
  }

  /// Get a catalog's contents (categories -> part types -> parts).
  ///
  /// [partTypeId] 0 (the default) returns the whole catalog; a specific id
  /// filters to that part type.
  Future<Result<CatalogData>> getCatalogData(
    int catalogId, {
    int partTypeId = 0,
  }) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/catman/custom_catalogs/$catalogId/data',
        queryParameters: {'part_type_id': partTypeId},
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(CatalogData.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to get catalog data: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get catalog data: $e'),
      );
    }
  }

  /// Search the authenticated member's accounts matching [query] (username
  /// substring). Optionally filter by [userType] and cap results with [limit]
  /// (1-1500, default 100).
  Future<Result<List<UserAccount>>> searchAccounts(
    String query, {
    UserType? userType,
    int limit = 100,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/catman/users/search',
        queryParameters: {
          'query': query,
          if (userType != null) 'user_type': userType.value,
          'limit': limit,
        },
        decoder: (data) => data as List<dynamic>,
      );

      final accounts = response.data
          .map((item) => UserAccount.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(accounts);
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to search accounts: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to search accounts: $e'),
      );
    }
  }

  /// Get full detail for the user [userId] within the authenticated member.
  Future<Result<UserDetail>> getUserDetail(int userId) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/catman/users/detail/$userId',
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(UserDetail.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catman.severe('Failed to get user detail: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get user detail: $e'),
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

  /// List the authenticated member's custom catalogs.
  Future<List<CustomCatalog>> getCatalogs() async {
    final result = await _client.getCatalogs();
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Create a custom catalog, returning the new catalog id.
  Future<int> createCatalog(CatalogCreateRequest catalog) async {
    final result = await _client.createCatalog(catalog);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Update a custom catalog, returning the catalog id. Omitted fields on
  /// [update] are left unchanged (PATCH).
  Future<int> updateCatalog(int catalogId, CatalogUpdateRequest update) async {
    final result = await _client.updateCatalog(catalogId, update);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Soft-delete a custom catalog, returning the deleted catalog id.
  Future<int> deleteCatalog(int catalogId) async {
    final result = await _client.deleteCatalog(catalogId);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Import commodity rows into a catalog, returning the [CatalogImportResult].
  Future<CatalogImportResult> importCatalog(
    CatalogImportRequest request,
  ) async {
    final result = await _client.importCatalog(request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get a catalog's contents (categories -> part types -> parts).
  ///
  /// [partTypeId] 0 (the default) returns the whole catalog; a specific id
  /// filters to that part type.
  Future<CatalogData> getCatalogData(
    int catalogId, {
    int partTypeId = 0,
  }) async {
    final result = await _client.getCatalogData(
      catalogId,
      partTypeId: partTypeId,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Search the authenticated member's accounts matching [query] (username
  /// substring). Optionally filter by [userType] and cap results with [limit]
  /// (1-1500, default 100).
  Future<List<UserAccount>> searchAccounts(
    String query, {
    UserType? userType,
    int limit = 100,
  }) async {
    final result = await _client.searchAccounts(
      query,
      userType: userType,
      limit: limit,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get full detail for the user [userId] within the authenticated member.
  Future<UserDetail> getUserDetail(int userId) async {
    final result = await _client.getUserDetail(userId);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }
}
