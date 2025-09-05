import 'dart:convert';
import 'package:http/http.dart' as http;
import './base_api_client.dart';

/// API client specifically for catalog-related operations
class CatalogsApiClient extends BaseApiClient {
  /// Fetches catalogs from the GroupVan API.
  ///
  /// This method makes an authenticated API request to retrieve all
  /// available catalogs from the system.
  ///
  /// Returns:
  /// A [Future<List<dynamic>>] containing an array of catalog objects:
  /// ```json
  /// [
  ///   {
  ///     "id": 1,
  ///     "name": "Supply Catalog",
  ///     "type": "supply"
  ///   },
  ///   {
  ///     "id": 2,
  ///     "name": "Vehicle Catalog",
  ///     "type": "vehicle"
  ///   }
  /// ]
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<List<dynamic>> fetchCatalogs() async {
    const endpoint = 'v3/catalogs/list';
    return await getList(endpoint, baseUrl: ApiConfig.v3BaseUrl);
  }

  /// Fetches vehicle categories from the GroupVan API for a specific catalog.
  ///
  /// This method retrieves categories for a vehicle in a catalog, including
  /// associated part types with their display tiers and popularity groups.
  ///
  /// Parameters:
  /// - [catalogId]: The ID of the catalog to query
  /// - [engineIndex]: The engine index in the current session
  /// - [sessionId]: The ID of the current session (required)
  ///
  /// Returns:
  /// A [Future<List<dynamic>>] containing an array of category objects:
  /// ```json
  /// [
  ///   {
  ///     "display_tier": "primary",
  ///     "id": 1,
  ///     "name": "Engine",
  ///     "part_types": [
  ///       {
  ///         "display_tier": "primary",
  ///         "id": 123,
  ///         "name": "Oil Filter",
  ///         "popularity_group": 1,
  ///         "slang_list": ["filter", "oil"]
  ///       }
  ///     ]
  ///   }
  /// ]
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<List<dynamic>> fetchVehicleCategories(int catalogId, int engineIndex,
      {String? sessionId}) async {
    final endpoint = 'v3/catalogs/$catalogId/vehicle/$engineIndex/categories';
    return await getList(endpoint,
        sessionId: sessionId, baseUrl: ApiConfig.v3BaseUrl);
  }

  /// Fetches supply categories from the GroupVan API for a specific catalog.
  ///
  /// This method retrieves supply categories for a catalog, including
  /// their subcategories with names and IDs.
  ///
  /// Parameters:
  /// - [catalogId]: The ID of the catalog to query
  ///
  /// Returns:
  /// A [Future<List<dynamic>>] containing an array of supply category objects:
  /// ```json
  /// [
  ///   {
  ///     "id": 1,
  ///     "name": "Engine",
  ///     "subcategories": [
  ///       {
  ///         "id": 123,
  ///         "name": "Oil Filter"
  ///       }
  ///     ]
  ///   }
  /// ]
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<List<dynamic>> fetchSupplyCategories(int catalogId,
      {String? sessionId}) async {
    final endpoint = 'v3/catalogs/$catalogId/categories';
    return await getList(endpoint,
        sessionId: sessionId, baseUrl: ApiConfig.v3BaseUrl);
  }

  /// Fetches application assets from the GroupVan API for specified applications.
  ///
  /// This method retrieves application assets such as images and other media
  /// for the specified applications, with optional language localization.
  ///
  /// Parameters:
  /// - [applicationIds]: List of application IDs to retrieve assets for
  /// - [languageCode]: Optional language code for localized assets
  ///
  /// Returns:
  /// A [Future<List<dynamic>>] containing an array of application asset objects:
  /// ```json
  /// [
  ///   {
  ///     "application_id": 123,
  ///     "type": "diagram",
  ///     "language": "EN",
  ///     "uri": "https://example.com/assets/image1.jpg"
  ///   },
  ///   {
  ///     "application_id": 456,
  ///     "type": "diagram",
  ///     "language": "EN",
  ///     "uri": "https://example.com/assets/image2.jpg"
  ///   }
  /// ]
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<List<dynamic>> fetchApplicationAssets(List<int> applicationIds,
      {String? languageCode, String? sessionId}) async {
    final applicationIdsParam = applicationIds.join(',');
    var endpoint =
        'v3/catalogs/application_assets?application_ids=$applicationIdsParam';

    if (languageCode != null) {
      endpoint += '&language_code=$languageCode';
    }

    return await getList(endpoint,
        sessionId: sessionId, baseUrl: ApiConfig.v3BaseUrl);
  }

  /// Fetches the contents of a user's cart from the GroupVan API.
  ///
  /// This method retrieves all items in a specific cart, including
  /// part details, pricing information, and quantities.
  ///
  /// Parameters:
  /// - [cartId]: ID of the cart to retrieve
  ///
  /// Returns:
  /// A [Future<List<dynamic>>] containing an array of cart item objects:
  /// ```json
  /// [
  ///   {
  ///     "sku": "ABC123",
  ///     "mfr_code": "MFR",
  ///     "part_number": "123456",
  ///     "list": 25.99,
  ///     "cost": 19.99,
  ///     "core": 5.00,
  ///     "order_quantity": 2,
  ///     "location_id": "MAIN",
  ///     "part_description": "Oil Filter",
  ///     "base_vehicle_id": 12345
  ///   }
  /// ]
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<List<dynamic>> fetchCart(String cartId, {String? sessionId}) async {
    final endpoint = 'v3/catalogs/cart/$cartId';
    return await getList(endpoint,
        sessionId: sessionId, baseUrl: ApiConfig.v3BaseUrl);
  }

  /// Fetches products from the GroupVan API using a POST request.
  ///
  /// This method makes a POST request to retrieve product listings based
  /// on vehicle configuration and part type criteria. Requires a session ID
  /// for vehicle context.
  ///
  /// Parameters:
  /// - [productRequest]: Map containing the product search criteria
  /// - [sessionId]: Required session ID for vehicle context
  ///
  /// Request body example:
  /// ```json
  /// {
  ///   "catalog_id": 1,
  ///   "vehicle_index": 0,
  ///   "part_types": [
  ///     {
  ///       "id": 123,
  ///       "name": "Oil Filter"
  ///     }
  ///   ],
  ///   "filters": {
  ///     "brand_ids": [1, 2, 3],
  ///     "price_range": {
  ///       "min": 10.00,
  ///       "max": 50.00
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// Returns:
  /// A [Future<Json>] containing product listing data:
  /// ```json
  /// {
  ///   "products": [
  ///     {
  ///       "sku": "ABC123",
  ///       "part_number": "123456",
  ///       "brand": "ACME",
  ///       "description": "Oil Filter",
  ///       "list_price": 25.99,
  ///       "your_cost": 19.99
  ///     }
  ///   ],
  ///   "total_count": 42,
  ///   "page": 1
  /// }
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  /// - [ArgumentError] when sessionId is null or empty
  Future<Json> fetchProducts(Json productRequest, {required String sessionId}) async {
    if (sessionId.isEmpty) {
      throw ArgumentError('Session ID is required for product requests');
    }

    const endpoint = 'v3/catalogs/products';
    
    // Add session ID to headers by using the base post method and manually adding headers
    final fullUrl = Uri.parse('${ApiConfig.v3BaseUrl}/$endpoint');

    try {
      final client = http.Client();
      final response = await client.post(
        fullUrl,
        headers: {
          'Authorization': 'Bearer ${ApiConfig.token}',
          'Content-Type': 'application/json',
          'gv-session-id': sessionId,
        },
        body: jsonEncode(productRequest),
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'POST request failed',
          statusCode: response.statusCode,
          endpoint: endpoint,
        );
      }

      return jsonDecode(response.body) as Json;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', endpoint: endpoint);
    }
  }
}
