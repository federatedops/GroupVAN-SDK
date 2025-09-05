import 'package:groupvan_web_sdk/groupvan_api.dart';
import 'package:logging/logging.dart';

/// Example usage of the GroupVAN Web SDK with logging
void main() async {
  // Initialize SDK logging (call this once at startup)
  GroupVanLogger.initialize(
    level: Level.INFO, // Show INFO level and above
    enableConsoleOutput: true,
  );
  
  // Configure the API client
  ApiConfig.token = 'your-jwt-token-here';
  ApiConfig.v3BaseUrl = 'https://api.groupvan.com/api';

  // Initialize API clients
  final vehiclesClient = VehiclesApiClient();
  final catalogsClient = CatalogsApiClient();

  try {
    GroupVanLogger.sdk.info('Starting GroupVAN SDK example...');

    // Example: Fetch vehicle groups
    GroupVanLogger.sdk.info('Fetching vehicle groups...');
    final groups = await vehiclesClient.fetchVehicleGroups();
    GroupVanLogger.sdk.info('Vehicle groups: ${groups.length} found');

    // Example: Search for vehicles (this will log the search query)
    final searchResponse = await vehiclesClient.searchVehicles('Honda Civic');
    GroupVanLogger.sdk.info('Search returned ${(searchResponse.body as Map)['vehicles']?.length ?? 0} results');

    // Example: Fetch user vehicles with pagination
    final userVehicles = await vehiclesClient.fetchUserVehicles(offset: 0, limit: 10);
    GroupVanLogger.sdk.info('User vehicles session ID: ${userVehicles.sessionId}');

    // Example: Fetch catalogs
    final catalogs = await catalogsClient.fetchCatalogs();
    GroupVanLogger.sdk.info('Catalogs: ${catalogs.length} found');

    // Example: Using models
    const searchRequest = VehicleSearchRequest(
      query: 'Toyota Camry 2020',
      groupId: 200,
      pageNumber: 1,
    );
    GroupVanLogger.sdk.fine('Search request model: ${searchRequest.toJson()}');

    const vehicle = Vehicle(
      year: 2020,
      make: 'Toyota',
      model: 'Camry',
      engine: '2.5L 4-Cylinder',
    );
    GroupVanLogger.sdk.fine('Vehicle model: ${vehicle.toJson()}');

    GroupVanLogger.sdk.info('GroupVAN SDK example completed successfully!');

  } catch (e) {
    GroupVanLogger.sdk.severe('Error in GroupVAN SDK example: $e');
  }
}