/// Search API: low-level [SearchClient] and public [GroupVANSearch].
library;

import '../core/exceptions.dart';
import '../core/response.dart';
import '../logging.dart';
import '../models/models.dart';
import 'base_client.dart';
import 'websocket.dart';

/// Search API client for omni search functionality
class SearchClient extends ApiClient {
  final MultiplexedSocket _socket;

  SearchClient(super.httpClient, super.authManager, this._socket);

  /// Stream omni search results for [query].
  ///
  /// The returned stream emits a growing [OmniSearchResponse] as each
  /// result category (part types, catalog parts, member parts, vehicles,
  /// member categories) arrives. Closes on the server's done signal or on
  /// subscription cancellation.
  Stream<OmniSearchResponse> omniSearch({
    required String query,
    int? vehicleIndex,
    bool? disableFilters,
  }) {
    final response = OmniSearchResponse(
      partTypes: [],
      catalogParts: [],
      memberParts: [],
      vehicles: [],
      memberCategories: [],
    );

    final payload = <String, dynamic>{'query': query};
    if (vehicleIndex != null) payload['vehicle_index'] = vehicleIndex;
    if (disableFilters != null) payload['disable_filters'] = disableFilters;

    return streamMultiplexRequest<OmniSearchResponse>(
      socket: _socket,
      type: 'omni_search',
      payload: payload,
      onData: (data) {
        if (data.containsKey('part_types')) {
          response.partTypes.addAll((data['part_types'] as List)
              .map((e) => PartType.fromJson(e as Map<String, dynamic>)));
        }
        if (data.containsKey('catalog_parts')) {
          response.catalogParts.addAll((data['catalog_parts'] as List)
              .map((e) => Part.fromJson(e as Map<String, dynamic>)));
        }
        if (data.containsKey('member_parts')) {
          response.memberParts.addAll((data['member_parts'] as List)
              .map((e) => Part.fromJson(e as Map<String, dynamic>)));
        }
        if (data.containsKey('vehicles')) {
          response.vehicles.addAll((data['vehicles'] as List)
              .map((e) =>
                  VehicleAndPartType.fromJson(e as Map<String, dynamic>)));
        }
        if (data.containsKey('member_categories')) {
          response.memberCategories.addAll((data['member_categories'] as List)
              .map((e) => MemberCategory.fromJson(e as Map<String, dynamic>)));
        }
        return response;
      },
    );
  }

  /// Stream product search results for [query].
  ///
  /// Emits a growing `List<Part>` as the server pushes catalog and member
  /// parts (with assets embedded), then pricing (and equivalents/equivalent
  /// pricing, when available) onto the same list. Closes on done or
  /// cancellation.
  Stream<List<Part>> searchProducts({
    required String query,
    bool? disableFilters,
    int? vehicleIndex,
  }) {
    final products = <Part>[];
    final payload = <String, dynamic>{'query': query};
    if (disableFilters != null) payload['disable_filters'] = disableFilters;
    if (vehicleIndex != null) payload['vehicle_index'] = vehicleIndex;

    return streamMultiplexRequest<List<Part>>(
      socket: _socket,
      type: 'products_search',
      payload: payload,
      onData: (data) {
        if (data.containsKey('catalog_parts')) {
          for (final product in data['catalog_parts'] as List) {
            products.add(Part.fromJson(product as Map<String, dynamic>));
          }
        } else if (data.containsKey('member_parts')) {
          for (final product in data['member_parts'] as List) {
            products.add(Part.fromJson(product as Map<String, dynamic>));
          }
        } else if (data.containsKey('pricing')) {
          applyPricing(
            products,
            data['pricing'] as Map<String, dynamic>,
            isPrimary: data['is_primary'] == true,
          );
        } else if (data.containsKey('equivalents')) {
          applyEquivalents(
            products,
            data['equivalents'] as Map<String, dynamic>,
          );
        } else if (data.containsKey('equivalent_pricing')) {
          applyEquivalentPricing(
            products,
            data['equivalent_pricing'] as Map<String, dynamic>,
          );
        }
        return products;
      },
    );
  }

  /// Get VIN data
  Future<Result<List<Map<String, String>>>> vinData(String vin) async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/search/vin',
        queryParameters: {'vin': vin},
        decoder: (data) => data as List<dynamic>,
      );

      final vinData = response.data
          .map((item) {
            final map = item as Map<String, dynamic>;
            return {
              'display': map['display']?.toString() ?? '',
              'value': map['value']?.toString() ?? '',
            };
          })
          .toList();

      return Success(vinData);
    } catch (e) {
      GroupVanLogger.sdk.severe('VIN data search failed: $e');
      return Failure(
        e is GroupVanException ? e : NetworkException('VIN data search failed: $e'),
      );
    }
  }

}

/// Namespaced search API
class GroupVANSearch {
  final SearchClient _client;

  const GroupVANSearch(this._client);

  /// Stream omni search results for [query].
  ///
  /// Emits a growing [OmniSearchResponse] as each result category arrives.
  /// The stream closes when the server signals completion or the
  /// subscription is cancelled.
  Stream<OmniSearchResponse> omniSearch({
    required String query,
    int? vehicleIndex,
    bool? disableFilters,
  }) => _client.omniSearch(
        query: query,
        vehicleIndex: vehicleIndex,
        disableFilters: disableFilters,
      );

  /// Get VIN data
  Future<List<Map<String, String>>> vinData(String vin) async {
    final result = await _client.vinData(vin);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Stream product search results for [query].
  ///
  /// Emits a growing `List<Part>` as products, assets, and pricing arrive.
  /// Closes on completion or cancellation.
  Stream<List<Part>> searchProducts({
    required String query,
    bool? disableFilters,
    int? vehicleIndex,
  }) => _client.searchProducts(
        query: query,
        disableFilters: disableFilters,
        vehicleIndex: vehicleIndex,
      );
}
