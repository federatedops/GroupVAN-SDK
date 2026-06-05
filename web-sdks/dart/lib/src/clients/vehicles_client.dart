/// Vehicles API: low-level [VehiclesClient] and public [GroupVANVehicles].
library;

import '../core/exceptions.dart';
import '../core/response.dart';
import '../core/validation.dart';
import '../logging.dart';
import '../models/models.dart';
import 'base_client.dart';

/// Vehicles API client with comprehensive vehicle management
class VehiclesClient extends ApiClient {
  const VehiclesClient(super.httpClient, super.authManager);

  /// Get vehicle groups with validation
  Future<Result<List<VehicleGroup>>> getVehicleGroups() async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/groups',
        decoder: (data) => data as List<dynamic>,
      );

      final groups = response.data
          .map((item) => VehicleGroup.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(groups);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get vehicle groups: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get vehicle groups: $e'),
      );
    }
  }

  /// Get user vehicles with pagination and validation
  Future<Result<List<Vehicle>>> getUserVehicles({
    int offset = 0,
    int limit = 20,
  }) async {
    // Validate pagination parameters
    try {
      GroupVanValidators.paginationOffset().validateAndThrow(offset, 'offset');
      GroupVanValidators.paginationLimit().validateAndThrow(limit, 'limit');
    } catch (e) {
      return Failure(e as ValidationException);
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/user',
        queryParameters: {'offset': offset, 'limit': limit},
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get user vehicles: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get user vehicles: $e'),
      );
    }
  }

  /// Search by VIN with validation
  Future<Result<Vehicle?>> searchByVin(String vin) async {
    // Validate VIN format
    try {
      GroupVanValidators.vin().validateAndThrow(vin, 'vin');
    } catch (e) {
      return Failure(e as ValidationException);
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/vin',
        queryParameters: {'vin': vin},
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(vehicles.firstOrNull);
    } catch (e) {
      GroupVanLogger.vehicles.severe('VIN search failed: $e');
      return Failure(
        e is GroupVanException ? e : NetworkException('VIN search failed: $e'),
      );
    }
  }

  /// Search by license plate with validation
  Future<Result<List<Vehicle>>> searchByPlate({
    required String plate,
    required String state,
  }) async {
    // Validate license plate parameters
    try {
      GroupVanValidators.licensePlate().validateAndThrow(plate, 'plate');
      GroupVanValidators.usState().validateAndThrow(state, 'state');
    } catch (e) {
      return Failure(e as ValidationException);
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/plate',
        queryParameters: {'plate': plate, 'state': state},
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe('License plate search failed: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('License plate search failed: $e'),
      );
    }
  }

  /// Filter vehicles with validation
  Future<Result<VehicleFilterResponse>> filterVehicles({
    required VehicleFilterRequest request,
  }) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/vehicles/filter',
        queryParameters: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      final filterResponse = VehicleFilterResponse.fromJson(response.data);
      return Success(filterResponse);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Vehicle filtering failed: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Vehicle filtering failed: $e'),
      );
    }
  }

  /// Get engine data with validation
  Future<Result<List<Vehicle>>> getEngines({
    required EngineSearchRequest request,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/engines',
        queryParameters: request.toJson(),
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get engine data: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get engine data: $e'),
      );
    }
  }

  /// Get user fleets
  Future<Result<List<Fleet>>> getFleets() async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/fleets',
        decoder: (data) => data as List<dynamic>,
      );

      final fleets = response.data
          .map((item) => Fleet.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(fleets);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get fleets: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get fleets: $e'),
      );
    }
  }

  /// Get fleet vehicles with validation
  Future<Result<List<Vehicle>>> getFleetVehicles({required int fleetId}) async {
    // Validate fleet ID
    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/fleets/$fleetId',
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get fleet vehicles: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get fleet vehicles: $e'),
      );
    }
  }

  /// Get account vehicles with pagination and validation
  Future<Result<List<Vehicle>>> getAccountVehicles({
    int offset = 0,
    int limit = 20,
  }) async {
    // Validate pagination parameters
    try {
      GroupVanValidators.paginationOffset().validateAndThrow(offset, 'offset');
      GroupVanValidators.paginationLimit().validateAndThrow(limit, 'limit');
    } catch (e) {
      return Failure(e as ValidationException);
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/account',
        queryParameters: {'offset': offset, 'limit': limit},
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get account vehicles: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get account vehicles: $e'),
      );
    }
  }

  /// Get previously selected part types for a vehicle
  Future<Result<List<PartType>>> getPreviousPartTypes({
    required int vehicleIndex,
  }) async {

    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/$vehicleIndex/part_types',
        decoder: (data) => data as List<dynamic>,
      );

      final partTypes = response.data
          .map((item) => PartType.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(partTypes);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get previous part types: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get previous part types: $e'),
      );
    }
  }

  /// Get vehicle swap data including compatible years and engines
  Future<Result<VehicleSwapResponse>> getSwapData({
    required VehicleSwapRequest request,
  }) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/vehicles/swap',
        queryParameters: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(VehicleSwapResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get vehicle swap data: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get vehicle swap data: $e'),
      );
    }
  }
}

/// Namespaced vehicles API
class GroupVANVehicles {
  final VehiclesClient _client;

  const GroupVANVehicles(this._client);

  /// Get user vehicles
  Future<List<Vehicle>> getUserVehicles({
    int offset = 0,
    int limit = 20,
  }) async {
    final result = await _client.getUserVehicles(offset: offset, limit: limit);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Search by VIN
  Future<Vehicle?> searchByVin(String vin) async {
    final result = await _client.searchByVin(vin);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Search by license plate
  Future<List<Vehicle>> searchByPlate({
    required String plate,
    required String state,
  }) async {
    final result = await _client.searchByPlate(plate: plate, state: state);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get vehicle groups
  Future<List<VehicleGroup>> getGroups() async {
    final result = await _client.getVehicleGroups();
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Filter vehicles
  Future<VehicleFilterResponse> filter({
    required VehicleFilterRequest request,
  }) async {
    Result<VehicleFilterResponse> result = await _client.filterVehicles(
      request: request,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get engines
  Future<List<Vehicle>> getEngines({
    required EngineSearchRequest request,
  }) async {
    final result = await _client.getEngines(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get fleets
  Future<List<Fleet>> getFleets() async {
    final result = await _client.getFleets();
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get fleet vehicles
  Future<List<Vehicle>> getFleetVehicles({required int fleetId}) async {
    final result = await _client.getFleetVehicles(fleetId: fleetId);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get account vehicles
  Future<List<Vehicle>> getAccountVehicles({
    int offset = 0,
    int limit = 20,
  }) async {
    final result = await _client.getAccountVehicles(
      offset: offset,
      limit: limit,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get previously selected part types for a vehicle
  Future<List<PartType>> getPreviousPartTypes({
    required int vehicleIndex,
  }) async {
    final result = await _client.getPreviousPartTypes(
      vehicleIndex: vehicleIndex,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get vehicle swap data including compatible years and engines
  ///
  /// Returns compatible years and vehicle/engine options for swapping
  /// a vehicle at the given index. Optionally filter by a specific year.
  Future<VehicleSwapResponse> getSwapData({
    required int vehicleIndex,
    int? year,
  }) async {
    final result = await _client.getSwapData(
      request: VehicleSwapRequest(vehicleIndex: vehicleIndex, year: year),
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }
}
