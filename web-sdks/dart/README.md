# GroupVAN Web SDK for Dart & Flutter

A comprehensive Dart/Flutter SDK for integrating with the GroupVAN V3 API. This package provides clean, type-safe access to vehicle data, catalogs, and parts information.

## Features

- **Complete V3 API Coverage** - All vehicle and catalog endpoints
- **Type-Safe Models** - Strongly typed request/response models
- **Session Management** - Automatic session handling for stateful operations
- **Professional Logging** - Comprehensive logging with configurable levels
- **Regional Support** - Built-in support for US, CA, and MX regions
- **Error Handling** - Detailed API exceptions with status codes
- **Flutter Integration** - Seamless integration with Flutter DevTools

## Getting Started

### Prerequisites

- Dart SDK 3.4.3 or higher
- Flutter 1.17.0 or higher (for Flutter apps)
- GroupVAN API credentials

### Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  groupvan_web_sdk: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Setup

```dart
import 'package:groupvan_web_sdk/groupvan_api.dart';
import 'package:logging/logging.dart';

void main() async {
  // Initialize logging (recommended)
  GroupVanLogger.initialize(level: Level.INFO);
  
  // Configure API client
  ApiConfig.token = 'your-jwt-token';
  ApiConfig.v3BaseUrl = 'https://api.groupvan.com/api';
  
  // Create API clients
  final vehiclesClient = VehiclesApiClient();
  final catalogsClient = CatalogsApiClient();
}
```

### Vehicle Operations

```dart
// Search for vehicles
final searchResponse = await vehiclesClient.searchVehicles('Honda Civic');
print('Found ${searchResponse.body['vehicles'].length} vehicles');

// Get user's vehicles with pagination  
final userVehicles = await vehiclesClient.fetchUserVehicles(
  offset: 0, 
  limit: 20
);

// Lookup vehicle by VIN
final vinResult = await vehiclesClient.fetchVehicleByVIN('1HGBH41JXMN109186');

// Filter vehicles by criteria
final filters = await vehiclesClient.filterVehicles(
  groupId: 200,
  yearId: 2020,
  makeId: 123
);
```

### Catalog Operations

```dart
// Get available catalogs
final catalogs = await catalogsClient.fetchCatalogs();

// Get vehicle categories (requires session)
final categories = await catalogsClient.fetchVehicleCategories(
  1, // catalog ID
  0, // engine index
  sessionId: 'your-session-id'
);

// Search for products
final productRequest = {
  'catalog_id': 1,
  'vehicle_index': 0,
  'part_types': [{'id': 123, 'name': 'Oil Filter'}]
};
final products = await catalogsClient.fetchProducts(
  productRequest,
  sessionId: 'your-session-id'
);
```

### Using Type-Safe Models

```dart
// Create search request with model
const searchRequest = VehicleSearchRequest(
  query: 'Toyota Camry 2020',
  groupId: 200,
  pageNumber: 1,
);

// Create vehicle model
const vehicle = Vehicle(
  year: 2020,
  make: 'Toyota', 
  model: 'Camry',
  engine: '2.5L 4-Cylinder'
);

print('Search: ${searchRequest.toJson()}');
print('Vehicle: ${vehicle.toJson()}');
```

## Logging

The SDK includes comprehensive logging using the official Dart `logging` package:

```dart
// Initialize with different log levels
GroupVanLogger.initialize(level: Level.INFO);     // Production
GroupVanLogger.initialize(level: Level.FINE);     // Development
GroupVanLogger.enableDebugLogging();              // Debug mode

// Access different logger categories
GroupVanLogger.sdk.info('Application started');
GroupVanLogger.vehicles.info('Searching vehicles');
GroupVanLogger.catalogs.info('Fetching products');
GroupVanLogger.apiClient.fine('HTTP request details');
```

For detailed logging configuration, see [LOGGING.md](LOGGING.md).

## API Reference

### Vehicle Endpoints

- `fetchVehicleGroups()` - Get vehicle groups
- `searchVehicles(query)` - Search vehicles
- `fetchUserVehicles()` - Get user's vehicles
- `fetchAccountVehicles()` - Get account vehicles  
- `fetchFleets()` - Get user's fleets
- `fetchFleetVehicles(fleetId)` - Get fleet vehicles
- `fetchVehicleByVIN(vin)` - Lookup by VIN
- `fetchVehicleByPlate(plate, state)` - Lookup by plate (B2B only)
- `filterVehicles()` - Filter by criteria
- `fetchEngines()` - Get engine configurations

### Catalog Endpoints

- `fetchCatalogs()` - Get available catalogs
- `fetchVehicleCategories()` - Get vehicle categories
- `fetchSupplyCategories()` - Get supply categories
- `fetchApplicationAssets()` - Get application assets
- `fetchCart(cartId)` - Get cart contents
- `fetchProducts()` - Search products (POST)

### Configuration

- `ApiConfig.token` - JWT token for authentication
- `ApiConfig.v3BaseUrl` - API base URL
- `GroupVanLogger` - Logging configuration

## Error Handling

All SDK methods throw `ApiException` for API errors:

```dart
try {
  final result = await vehiclesClient.searchVehicles('invalid');
} on ApiException catch (e) {
  print('API Error: ${e.message}');
  print('Status Code: ${e.statusCode}');
  print('Endpoint: ${e.endpoint}');
}
```

## Regional Support

The SDK automatically handles regional restrictions:
- Results exclude regions restricted for your user
- Supports US, CA (Canada), and MX (Mexico) regions
- Plate lookup is restricted to B2B accounts only

## Contributing

This SDK is part of the [GroupVAN-SDK](https://github.com/federatedops/GroupVAN-SDK) repository. Please submit issues and pull requests there.

## License

See the [LICENSE](../../../LICENSE) file in the repository root.