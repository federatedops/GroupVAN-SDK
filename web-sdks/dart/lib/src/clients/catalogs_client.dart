/// Catalogs API: low-level [CatalogsClient] and public [GroupVANCatalogs].
library;

import '../core/exceptions.dart';
import '../core/response.dart';
import '../logging.dart';
import '../models/models.dart';
import 'base_client.dart';
import 'websocket.dart';

/// Catalogs API client with comprehensive catalog management
class CatalogsClient extends ApiClient {
  final MultiplexedSocket _socket;

  CatalogsClient(super.httpClient, super.authManager, this._socket);

  /// Stream product listings for a catalog request.
  ///
  /// The returned stream emits a growing `List<ProductListing>` as frames
  /// arrive from the server: first the listings themselves, then assets,
  /// pricing, equivalents, and equivalent pricing as they enrich the
  /// already-emitted parts. The stream closes when the server signals the
  /// request is complete. Cancel the subscription to abort early.
  Stream<List<ProductListing>> getProducts({
    required ProductListingRequest request,
  }) {
    final listings = <ProductListing>[];
    return _streamRequest<List<ProductListing>>(
      type: 'products_listing',
      payload: request.toJson(),
      onData: (data) {
        if (data.containsKey('product_listings')) {
          for (final l in data['product_listings'] as List) {
            listings.add(ProductListing.fromJson(l as Map<String, dynamic>));
          }
        } else {
          final allParts = listings.expand((l) => l.parts).toList();
          if (data.containsKey('assets')) {
            applyAssets(allParts, data['assets'] as Map<String, dynamic>);
          } else if (data.containsKey('pricing')) {
            applyPricing(
              allParts,
              data['pricing'] as Map<String, dynamic>,
              isPrimary: data['is_primary'] == true,
            );
          } else if (data.containsKey('equivalents')) {
            applyEquivalents(
              allParts,
              data['equivalents'] as Map<String, dynamic>,
            );
          } else if (data.containsKey('equivalent_pricing')) {
            applyEquivalentPricing(
              allParts,
              data['equivalent_pricing'] as Map<String, dynamic>,
            );
          }
        }
        return listings;
      },
    );
  }

  Stream<T> _streamRequest<T>({
    required String type,
    required Map<String, dynamic> payload,
    required T Function(Map<String, dynamic> data) onData,
  }) => streamMultiplexRequest(
        socket: _socket,
        type: type,
        payload: payload,
        onData: onData,
      );

  /// Get available catalogs
  Future<Result<List<Catalog>>> getCatalogs() async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/catalogs/list',
        decoder: (data) => data as List<dynamic>,
      );

      final catalogs = response.data
          .map((item) => Catalog.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(catalogs);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get catalogs: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get catalogs: $e'),
      );
    }
  }

  /// Get vehicle categories with validation
  Future<Result<List<VehicleCategory>>> getVehicleCategories({
    required int catalogId,
    required int engineIndex,
    bool? disableFilters,
  }) async {
    final queryParams = <String, dynamic>{};
    if (disableFilters != null) {
      queryParams['disable_filters'] = disableFilters;
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/catalogs/$catalogId/vehicle/$engineIndex/categories',
        queryParameters: queryParams,
        decoder: (data) => data as List<dynamic>,
      );

      final categories = response.data
          .map((item) => VehicleCategory.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(categories);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get vehicle categories: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get vehicle categories: $e'),
      );
    }
  }

  /// Get supply categories with validation
  Future<Result<List<SupplyCategory>>> getSupplyCategories({
    required int catalogId,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/catalogs/$catalogId/categories',
        decoder: (data) => data as List<dynamic>,
      );

      final categories = response.data
          .map((item) => SupplyCategory.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(categories);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get supply categories: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get supply categories: $e'),
      );
    }
  }

  /// Get application assets with validation
  Future<Result<List<ApplicationAsset>>> getApplicationAssets({
    required List<int> applicationIds,
    String? languageCode,
  }) async {
    // Validate application IDs
    try {
      if (applicationIds.isEmpty) {
        throw ValidationException(
          'Application IDs cannot be empty',
          errors: [
            ValidationError(
              field: 'application_ids',
              message: 'Application IDs cannot be empty',
              value: applicationIds,
              rule: 'required',
            ),
          ],
        );
      }
    } catch (e) {
      return Failure(e as ValidationException);
    }

    try {
      final queryParams = <String, dynamic>{
        'application_ids': applicationIds.join(','),
      };

      if (languageCode != null) {
        queryParams['language_code'] = languageCode;
      }

      final response = await get<List<dynamic>>(
        '/v3/catalogs/application_assets',
        queryParameters: queryParams,
        decoder: (data) => data as List<dynamic>,
      );

      final assets = response.data
          .map(
            (item) => ApplicationAsset.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      return Success(assets);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get application assets: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get application assets: $e'),
      );
    }
  }

  Future<Result<List<Asset>>> getProductAssets({
    List<int>? catalogSkus,
    List<int>? memberSkus,
    bool primaryOnly = true,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/catalogs/products/assets',
        data: {'catalog_skus': catalogSkus, 'member_skus': memberSkus, 'primary_only': primaryOnly},
      );
      final catalogAssets = response.data['catalog_assets'] as List<dynamic>? ?? const [];
      final memberAssets = response.data['member_assets'] as List<dynamic>? ?? const [];
      final assets = [
        ...catalogAssets.map((item) => Asset.fromJson(item as Map<String, dynamic>)),
        ...memberAssets.map((item) => Asset.fromJson(item as Map<String, dynamic>)),
      ];
      return Success(assets);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get product assets: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get product assets: $e'),
      );
    }
  }

  Future<Result<Interchange>> getInterchanges({
    required String partNumber,
    List<String>? brands,
    List<int>? partTypes,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/catalogs/interchange',
        data: {
          'part_number': partNumber,
          'brands': brands,
          'part_types': partTypes,
        },
      );
      return Success(Interchange.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get interchange: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get interchange: $e'),
      );
    }
  }

  Future<Result<List<ItemPricing>>> getProductPricing({
    required ProductPricingRequest request,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/json/federated/v3_2/item_inquiry',
        data: {
          'items': request.products.asMap().entries.map((entry) => {
            'id': entry.key.toString(),
            'mfr_code': entry.value.mfrCode,
            'part_number': entry.value.partNumber,
          }).toList(),
          if (request.member != null) 'member': request.member,
        },
      );

      final items = (response.data['items'] as List<dynamic>)
          .map((item) => ItemPricing.fromJson(item as Map<String, dynamic>))
          .toList();
      return Success(items);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get product pricing: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get product pricing: $e'),
      );
    }
  }

  Future<Result<ProductInfoResponse>> getProductInfo({required int sku}) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/catalogs/product/info',
        queryParameters: {'sku': sku},
      );
      return Success(ProductInfoResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get product info: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get product info: $e'),
      );
    }
  }

  /// Get Identifix URL
  Future<Result<String>> getIdentifixUrl({required int vehicleIndex}) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/catalogs/identifix',
        queryParameters: {'vehicle_index': vehicleIndex},
        decoder: (data) => data as Map<String, dynamic>,
      );

      final url = response.data['identifix_login_url'];
      if (url is! String) {
        return Failure(
          NetworkException(
            'Invalid response format: identifix_login_url is not a string',
          ),
        );
      }
      return Success(url);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get Identifix URL: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get Identifix URL: $e'),
      );
    }
  }

  /// Get buyers guide for a part
  Future<Result<BuyersGuideResponse>> getBuyersGuide({
    required BuyersGuideRequest request,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/catalogs/buyers_guide',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(BuyersGuideResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get buyers guide: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get buyers guide: $e'),
      );
    }
  }

  /// Get flat buyers guide for a part
  Future<Result<FlatBuyersGuideResponse>> getFlatBuyersGuide({
    required FlatBuyersGuideRequest request,
  }) async {
    try {
      final response = await post<List<dynamic>>(
        '/v3/catalogs/buyers_guide/flat',
        data: request.toJson(),
        decoder: (data) => data as List<dynamic>,
      );

      return Success(FlatBuyersGuideResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get flat buyers guide: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get flat buyers guide: $e'),
      );
    }
  }

  /// Get invoices via the v3.2 gateway
  Future<Result<InvoiceResponse>> getInvoices({
    required InvoiceRequest request,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/json/federated/v3_2/invoice',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(InvoiceResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get invoices: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get invoices: $e'),
      );
    }
  }

  /// Get statements via the v3.2 gateway
  Future<Result<StatementResponse>> getStatements({
    required StatementRequest request,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/json/federated/v3_2/statement',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(StatementResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get statements: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get statements: $e'),
      );
    }
  }

  /// Get PDF bytes from a link URL
  Future<Result<List<int>>> getPdfBytes({required String linkUrl}) async {
    try {
      final response = await get<List<dynamic>>(
        '/internal/catalog/pdf_bytes',
        queryParameters: {'link_url': linkUrl},
        decoder: (data) => data as List<dynamic>,
      );

      final bytes = response.data.cast<int>();
      return Success(bytes);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get PDF bytes: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get PDF bytes: $e'),
      );
    }
  }
}

/// Namespaced catalogs API
class GroupVANCatalogs {
  final CatalogsClient _client;

  const GroupVANCatalogs(this._client);

  /// Get available catalogs
  Future<List<Catalog>> getCatalogs() async {
    final result = await _client.getCatalogs();
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get vehicle categories
  Future<List<VehicleCategory>> getVehicleCategories({
    required int catalogId,
    required int engineIndex,
    bool? disableFilters,
  }) async {
    final result = await _client.getVehicleCategories(
      catalogId: catalogId,
      engineIndex: engineIndex,
      disableFilters: disableFilters,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get supply categories
  Future<List<SupplyCategory>> getSupplyCategories({
    required int catalogId,
  }) async {
    final result = await _client.getSupplyCategories(catalogId: catalogId);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get application assets
  Future<List<ApplicationAsset>> getApplicationAssets({
    required List<int> applicationIds,
    String? languageCode,
  }) async {
    final result = await _client.getApplicationAssets(
      applicationIds: applicationIds,
      languageCode: languageCode,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Stream product listings for [request].
  ///
  /// Emits a growing `List<ProductListing>` as listings, assets, pricing,
  /// equivalents, and equivalent pricing arrive. The stream closes when
  /// the request is complete; cancel the subscription to abort early.
  Stream<List<ProductListing>> getProducts({
    required ProductListingRequest request,
  }) => _client.getProducts(request: request);

  Future<List<Asset>> getProductAssets({
    List<int>? catalogSkus,
    List<int>? memberSkus,
    bool primaryOnly = true
  }) async {
    final result = await _client.getProductAssets(
      catalogSkus: catalogSkus,
      memberSkus: memberSkus,
      primaryOnly: primaryOnly,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  Future<Interchange> getInterchanges({
    required String partNumber,
    List<String>? brands,
    List<int>? partTypes,
  }) async {
    final result = await _client.getInterchanges(
      partNumber: partNumber,
      brands: brands,
      partTypes: partTypes,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  Future<List<ItemPricing>> getProductPricing({
    required ProductPricingRequest request,
  }) async {
    final result = await _client.getProductPricing(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  Future<ProductInfoResponse> getProductInfo({required int sku}) async {
    final result = await _client.getProductInfo(sku: sku);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get Identifix URL
  Future<String> getIdentifixUrl(int vehicleIndex) async {
    final result = await _client.getIdentifixUrl(vehicleIndex: vehicleIndex);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get buyers guide for a part
  Future<BuyersGuideResponse> getBuyersGuide({
    required BuyersGuideRequest request,
  }) async {
    final result = await _client.getBuyersGuide(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  Future<FlatBuyersGuideResponse> getFlatBuyersGuide({
    required FlatBuyersGuideRequest request,
  }) async {
    final result = await _client.getFlatBuyersGuide(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get invoices via the v3.2 gateway
  Future<InvoiceResponse> getInvoices({
    required InvoiceRequest request,
  }) async {
    final result = await _client.getInvoices(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get statements via the v3.2 gateway
  Future<StatementResponse> getStatements({
    required StatementRequest request,
  }) async {
    final result = await _client.getStatements(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get PDF bytes from a link URL
  Future<List<int>> getPdfBytes({required String linkUrl}) async {
    final result = await _client.getPdfBytes(linkUrl: linkUrl);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }
}
