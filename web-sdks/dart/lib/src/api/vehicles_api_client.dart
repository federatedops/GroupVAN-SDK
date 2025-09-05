import './base_api_client.dart';
import '../logging.dart';

/// API client specifically for vehicle-related operations
class VehiclesApiClient extends BaseApiClient {
  
  /// Fetches vehicle groups from the GroupVan API.
  ///
  /// This method retrieves all available vehicle group types
  /// that can be used for filtering and categorizing vehicles.
  ///
  /// Returns:
  /// A [Future<List<dynamic>>] containing an array of vehicle group objects:
  /// ```json
  /// [
  ///   {
  ///     "id": 200,
  ///     "name": "Passenger Car",
  ///     "description": "Standard passenger vehicles"
  ///   },
  ///   {
  ///     "id": 300,
  ///     "name": "Light Truck",
  ///     "description": "Light duty trucks and SUVs"
  ///   }
  /// ]
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<List<dynamic>> fetchVehicleGroups() async {
    const endpoint = 'v3/vehicles/groups';
    return await getList(endpoint, baseUrl: ApiConfig.v3BaseUrl);
  }
  /// Fetches user vehicles from the GroupVan API with pagination support.
  ///
  /// This method makes an authenticated API request to retrieve vehicles
  /// associated with the current user. The response is paginated to
  /// handle large datasets efficiently.
  ///
  /// Parameters:
  /// - [offset]: The number of records to skip (defaults to 0)
  /// - [limit]: The maximum number of records to return (defaults to 20)
  ///
  /// Returns:
  /// A [Future<ApiResponse>] containing:
  /// - body: Json with array of vehicle objects
  /// - sessionId: Session ID from 'gv-session-id' header
  ///
  /// Body structure:
  /// ```json
  /// [
  ///   {
  ///     "vehicle_id": 1535,
  ///     "make": "Chrysler",
  ///     "model": "PT Cruiser",
  ///     "year": 2001,
  ///     "engine": "2.4L L4 DOHC GAS FI B",
  ///     "engine_id": "1535_239_4707",
  ///     "vin": null,
  ///     "previous_vehicle_id": 58774394
  ///   }
  /// ]
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<ApiResponse> fetchUserVehicles({int offset = 0, int limit = 20}) async {
    String endpoint = 'v3/vehicles/user?offset=$offset&limit=$limit';
    return await getWithSession(endpoint, baseUrl: ApiConfig.v3BaseUrl);
  }

  /// Fetches account vehicles from the GroupVan API with pagination support.
  ///
  /// This method makes an authenticated API request to retrieve vehicles
  /// associated with the current account. The response is paginated to
  /// handle large datasets efficiently.
  ///
  /// Parameters:
  /// - [offset]: The number of records to skip (defaults to 0)
  /// - [limit]: The maximum number of records to return (defaults to 20)
  ///
  /// Returns:
  /// A [Future<ApiResponse>] containing:
  /// - body: Json with array of vehicle objects
  /// - sessionId: Session ID from 'gv-session-id' header
  ///
  /// Body structure:
  /// ```json
  /// [
  ///   {
  ///     "vehicle_id": 1535,
  ///     "make": "Chrysler",
  ///     "model": "PT Cruiser",
  ///     "year": 2001,
  ///     "engine": "2.4L L4 DOHC GAS FI B",
  ///     "engine_id": "1535_239_4707",
  ///     "vin": null,
  ///     "previous_vehicle_id": 58774394
  ///   }
  /// ]
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<ApiResponse> fetchAccountVehicles({int offset = 0, int limit = 20}) async {
    String endpoint = 'v3/vehicles/account?offset=$offset&limit=$limit';
    return await getWithSession(endpoint, baseUrl: ApiConfig.v3BaseUrl);
  }

  /// Fetches fleet information from the GroupVan API.
  ///
  /// Returns:
  /// A [Future<List<dynamic>>] containing an array of fleet objects:
  /// ```json
  /// [
  ///   {
  ///     "id": 109,
  ///     "name": "Adam test fleet",
  ///     "timestamp": "2025-08-07T17:41:09"
  ///   }
  /// ]
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<List<dynamic>> fetchFleets() async {
    const endpoint = 'v3/vehicles/fleets';
    return await getList(endpoint, baseUrl: ApiConfig.v3BaseUrl);
  }

  /// Fetches vehicles for a specific fleet from the GroupVan API.
  ///
  /// Parameters:
  /// - [fleetId]: The ID of the fleet to fetch vehicles for
  ///
  /// Returns:
  /// A [Future<ApiResponse>] containing:
  /// - body: Json with array of vehicle objects
  /// - sessionId: Session ID from 'gv-session-id' header
  ///
  /// Body structure:
  /// ```json
  /// [
  ///   {
  ///     "description": "My Vehicle",
  ///     "index": 0,
  ///     "fleet_vehicle_id": 12345,
  ///     "engine": "2.5L V6 DOHC 24V",
  ///     "year": 2021,
  ///     "make": "Toyota",
  ///     "model": "Camry"
  ///   }
  /// ]
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<ApiResponse> fetchFleetVehicles(int fleetId) async {
    final endpoint = 'v3/vehicles/fleets/$fleetId';
    return await getWithSession(endpoint, baseUrl: ApiConfig.v3BaseUrl);
  }

  /// Fetches vehicle information by VIN number.
  ///
  /// Parameters:
  /// - [vin]: The VIN number to look up
  ///
  /// Returns:
  /// A [Future<Json?>] containing vehicle information or null if not found
  ///
  /// Response example:
  /// ```json
  /// [
  ///   {
  ///     "index": 0,
  ///     "engine": "2.5L V6 DOHC 24V",
  ///     "year": 2021,
  ///     "make": "Toyota",
  ///     "model": "Camry"
  ///   }
  /// ]
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<Json?> fetchVehicleByVIN(String vin) async {
    final endpoint = 'v3/vehicles/vin?vin=$vin';
    try {
      return await get(endpoint, baseUrl: ApiConfig.v3BaseUrl);
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return null; // VIN not found
      }
      rethrow;
    }
  }

  /// Fetches vehicle information by license plate.
  ///
  /// **Important**: This endpoint is restricted for B2C (Business-to-Consumer) users
  /// and is only available for B2B (Business-to-Business) accounts.
  ///
  /// Parameters:
  /// - [plate]: The license plate number (1-8 characters)
  /// - [state]: The state where the plate is registered (US state abbreviation)
  ///
  /// Returns:
  /// A [Future<Json>] containing vehicle information
  ///
  /// Response example:
  /// ```json
  /// [
  ///   {
  ///     "vehicle_id": 12345,
  ///     "engine_id": "V6-2.5L",
  ///     "engine": "2.5L V6 DOHC 24V",
  ///     "year": 2021,
  ///     "make": "Toyota",
  ///     "model": "Camry"
  ///   }
  /// ]
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  /// - [ApiException] with status 403 if user is B2C (not authorized)
  Future<Json> fetchVehicleByPlate(String plate, String state) async {
    final endpoint = 'v3/vehicles/plate?plate=$plate&state=$state';
    return await get(endpoint, baseUrl: ApiConfig.v3BaseUrl);
  }

  /// Searches for vehicles using the V3 search API.
  ///
  /// This method provides comprehensive vehicle search functionality
  /// using the modern V3 API endpoint with session support.
  ///
  /// Parameters:
  /// - [query]: The search query string
  /// - [groupId]: Optional vehicle group ID to filter results
  /// - [pageNumber]: Optional page number for pagination (defaults to 1)
  ///
  /// Returns:
  /// A [Future<ApiResponse>] containing search results with session ID:
  /// ```json
  /// {
  ///   "vehicles": [
  ///     {
  ///       "index": 0,
  ///       "vehicle_id": 12345,
  ///       "year": 2021,
  ///       "make": "Toyota",
  ///       "model": "Camry",
  ///       "engine": "2.5L L4 DOHC 16V",
  ///       "engine_id": "12345_567_890"
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
  Future<ApiResponse> searchVehicles(String query, {int? groupId, int pageNumber = 1}) async {
    GroupVanLogger.vehicles.info('Searching vehicles: "$query"${groupId != null ? ' (group: $groupId)' : ''}');
    
    String endpoint = 'v3/vehicles/search?query=${Uri.encodeQueryComponent(query)}&page=$pageNumber';
    if (groupId != null) {
      endpoint += '&group_id=$groupId';
    }
    return await getWithSession(endpoint, baseUrl: ApiConfig.v3BaseUrl);
  }


  /// Filters vehicles based on provided criteria.
  ///
  /// **Regional Filtering**: Results automatically exclude regions restricted
  /// for the current user. Supports US, CA (Canada), and MX (Mexico) regions.
  ///
  /// Parameters:
  /// - [groupId]: Required group ID for filtering
  /// - [yearId]: Optional year ID filter
  /// - [makeId]: Optional make ID filter
  /// - [modelId]: Optional model ID filter
  ///
  /// Request example:
  /// GET /v3/vehicles/filter?group_id=<group_id>&year_id=<year_id>&make_id=<make_id>&model_id=<model_id>
  ///
  /// Returns:
  /// A [Future<Json>] containing filtered vehicle data
  ///
  /// Response example:
  /// ```json
  /// {
  ///   "models": [
  ///     {
  ///       "model_id": 1,
  ///       "model_name": "Camry",
  ///       "model_regions": ["US", "CA"]
  ///     }
  ///   ],
  ///   "makes": [
  ///     {
  ///       "make_id": 1,
  ///       "make_name": "Toyota",
  ///       "make_regions": ["US"]
  ///     }
  ///   ],
  ///   "years": [
  ///     {
  ///       "year_id": 2021,
  ///       "year_name": "2021",
  ///       "year_regions": ["US"]
  ///     }
  ///   ]
  /// }
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<Json> filterVehicles(
      {required int groupId, int? yearId, int? makeId, int? modelId}) async {
    String endpoint = 'v3/vehicles/filter?group_id=$groupId';
    if (yearId != null) endpoint += '&year_id=$yearId';
    if (makeId != null) endpoint += '&make_id=$makeId';
    if (modelId != null) endpoint += '&model_id=$modelId';

    return await get(endpoint, baseUrl: ApiConfig.v3BaseUrl);
  }

  /// Fetches filtered vehicle data with session ID from the GroupVan API.
  ///
  /// This method retrieves vehicle data filtered by group and optionally by
  /// year, make, and model IDs, and returns the session ID.
  ///
  /// Parameters:
  /// - [groupId]: Required group ID for filtering
  /// - [yearId]: Optional year ID for filtering
  /// - [makeId]: Optional make ID for filtering
  /// - [modelId]: Optional model ID for filtering
  ///
  /// Returns:
  /// A [Future<ApiResponse>] containing filtered vehicle data and session ID
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<ApiResponse> filterVehiclesWithSession(
      {required int groupId, int? yearId, int? makeId, int? modelId}) async {
    String endpoint = 'v3/vehicles/filter?group_id=$groupId';
    if (yearId != null) endpoint += '&year_id=$yearId';
    if (makeId != null) endpoint += '&make_id=$makeId';
    if (modelId != null) endpoint += '&model_id=$modelId';

    return await getWithSession(endpoint, baseUrl: ApiConfig.v3BaseUrl);
  }

  /// Fetches engines for a specific vehicle configuration.
  ///
  /// **Regional Filtering**: Results automatically exclude regions restricted
  /// for the current user. Creates a session with vehicle data for subsequent requests.
  ///
  /// Parameters:
  /// - [groupId]: Required group ID for filtering
  /// - [yearId]: Required year ID for filtering
  /// - [makeId]: Required make ID for filtering
  /// - [modelId]: Required model ID for filtering
  ///
  /// Returns:
  /// A [Future<ApiResponse>] containing engine data and session ID
  ///
  /// Response example:
  /// ```json
  /// {
  ///   "session_id": "aa2f189e-f489-4420-a6a7",
  ///   "vehicles": [
  ///     {
  ///       "engine": "4.8L V6 OHV GAS MFI FI W L35",
  ///       "index": 0,
  ///       "make": "Chevrolet",
  ///       "model": "Silverado 1500",
  ///       "year": 2000
  ///     }
  ///   ]
  /// }
  /// ```
  ///
  /// Throws:
  /// - [ApiException] when the API returns an error response
  /// - [ApiException] when network connectivity is unavailable
  Future<ApiResponse> fetchEngines({
    required int groupId,
    required int yearId,
    required int makeId,
    required int modelId,
  }) async {
    final endpoint =
        'v3/vehicles/engines?group_id=$groupId&year_id=$yearId&make_id=$makeId&model_id=$modelId';

    return await getWithSession(endpoint, baseUrl: ApiConfig.v3BaseUrl);
  }
}
