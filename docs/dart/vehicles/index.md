---
layout: default
title: Vehicles API
parent: Flutter/Dart SDK
nav_order: 3
has_children: true
permalink: /dart/vehicles/
description: "Complete vehicles API reference for the GroupVAN Flutter/Dart SDK with all 10 endpoints and comprehensive examples."
---

# Vehicles API
{: .no_toc }

The Vehicles API provides comprehensive vehicle management capabilities including user vehicles, vehicle search, VIN lookup, fleet management, and advanced filtering. The Dart SDK provides **complete 100% parity** with all Python API endpoints.

{: .fs-6 .fw-300 }

---

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Quick Start

```dart
import 'package:groupvan/groupvan.dart';

void main() async {
  await GroupVAN.initialize(isProduction: false);
  
  // Authenticate first
  await GroupVAN.instance.auth.signInWithPassword(
    username: 'your-username',
    password: 'your-password',
    developerId: 'your-developer-id',
  );

  // Access vehicles API
  final vehicles = GroupVAN.instance.client.vehicles;
  
  // Get user vehicles
  final result = await vehicles.getUserVehicles(limit: 10);
  result.fold(
    (error) => print('Error: $error'),
    (vehicleList) => print('Found ${vehicleList.length} vehicles'),
  );
}
```

---

## API Coverage

The Dart SDK provides complete coverage of all Vehicles API endpoints:

| **Endpoint** | **Method** | **Description** |
|:-------------|:-----------|:----------------|
| `GET /vehicles/groups` | `getGroups()` | Get available vehicle groups |
| `GET /vehicles/user` | `getUserVehicles()` | Get user's vehicles with pagination |
| `GET /vehicles/search` | `search()` | Search vehicles by query |
| `GET /vehicles/vin` | `searchByVin()` | Search by VIN number |
| `GET /vehicles/plate` | `searchByPlate()` | Search by license plate |
| `GET /vehicles/filter` | `filter()` | Filter vehicles by criteria |
| `GET /vehicles/engines` | `getEngines()` | Get engine data |
| `GET /vehicles/fleets` | `getFleets()` | Get user fleets |
| `GET /vehicles/fleets/{id}` | `getFleetVehicles()` | Get vehicles in fleet |
| `GET /vehicles/account` | `getAccountVehicles()` | Get account vehicles |

---

## Core Methods

### Get Vehicle Groups

Get all available vehicle groups for filtering and organization:

```dart
Future<Result<List<VehicleGroup>>> getGroups()
```

**Example:**
```dart
final result = await GroupVAN.instance.client.vehicles.getGroups();
result.fold(
  (error) => print('Failed to get groups: $error'),
  (groups) {
    print('Available groups:');
    for (final group in groups) {
      print('• ${group.name}: ${group.description}');
    }
  },
);
```

### Get User Vehicles

Get vehicles associated with the authenticated user:

```dart
Future<Result<List<Vehicle>>> getUserVehicles({
  int offset = 0,
  int limit = 20,
})
```

**Parameters:**
- `offset` - Starting index for pagination (default: 0)
- `limit` - Maximum number of results (default: 20, max: 100)

**Example:**
```dart
final result = await GroupVAN.instance.client.vehicles.getUserVehicles(
  offset: 0,
  limit: 10,
);

result.fold(
  (error) => print('Error loading vehicles: $error'),
  (vehicles) {
    print('User vehicles:');
    for (final vehicle in vehicles) {
      print('• ${vehicle.year} ${vehicle.make} ${vehicle.model}');
      if (vehicle.engine != null) {
        print('  Engine: ${vehicle.engine}');
      }
    }
  },
);
```

### Search Vehicles

Search for vehicles using a query string:

```dart
Future<Result<VehicleSearchResponse>> search({
  required String query,
  int? groupId,
  int page = 1,
})
```

**Parameters:**
- `query` - Search query (make, model, year, etc.)
- `groupId` - Optional vehicle group filter
- `page` - Page number for pagination (default: 1)

**Example:**
```dart
final result = await GroupVAN.instance.client.vehicles.search(
  query: 'Toyota Camry',
  page: 1,
);

result.fold(
  (error) => print('Search failed: $error'),
  (searchResponse) {
    print('Found ${searchResponse.totalCount} vehicles');
    print('Showing page ${searchResponse.page}:');
    for (final vehicle in searchResponse.vehicles) {
      print('• ${vehicle.year} ${vehicle.make} ${vehicle.model}');
    }
  },
);
```

---

## Advanced Methods

### VIN Lookup

Search for vehicles using a VIN (Vehicle Identification Number):

```dart
Future<Result<List<Vehicle>?>> searchByVin(String vin)
```

**Example:**
```dart
final result = await GroupVAN.instance.client.vehicles.searchByVin(
  '1HGCM82633A123456'
);

result.fold(
  (error) => print('VIN search failed: $error'),
  (vehicles) {
    if (vehicles == null || vehicles.isEmpty) {
      print('No vehicle found for this VIN');
    } else {
      final vehicle = vehicles.first;
      print('Found: ${vehicle.year} ${vehicle.make} ${vehicle.model}');
    }
  },
);
```

### License Plate Search

Search for vehicles using license plate and state:

```dart
Future<Result<List<Vehicle>>> searchByPlate({
  required String plate,
  required String state,
})
```

**Example:**
```dart
final result = await GroupVAN.instance.client.vehicles.searchByPlate(
  plate: 'ABC1234',
  state: 'CA',
);

result.fold(
  (error) => print('Plate search failed: $error'),
  (vehicles) {
    print('Found ${vehicles.length} vehicles for plate ABC1234:');
    for (final vehicle in vehicles) {
      print('• ${vehicle.year} ${vehicle.make} ${vehicle.model}');
    }
  },
);
```

### Vehicle Filtering

Filter vehicles by specific criteria (group, year, make, model):

```dart
Future<Result<VehicleFilterResponse>> filter({
  required VehicleFilterRequest request,
})
```

**Example:**
```dart
final filterRequest = VehicleFilterRequest(
  groupId: 1,
  yearId: 2021,
  makeId: 123, // Optional
  modelId: 456, // Optional
);

final result = await GroupVAN.instance.client.vehicles.filter(
  request: filterRequest,
);

result.fold(
  (error) => print('Filtering failed: $error'),
  (filterResponse) {
    print('Filter results:');
    if (filterResponse.years != null) {
      print('Available years: ${filterResponse.years!.length}');
    }
    if (filterResponse.makes != null) {
      print('Available makes: ${filterResponse.makes!.length}');
      for (final make in filterResponse.makes!.take(5)) {
        print('• ${make.name}');
      }
    }
    if (filterResponse.models != null) {
      print('Available models: ${filterResponse.models!.length}');
    }
  },
);
```

---

## Fleet Management

### Get User Fleets

Get all fleets associated with the authenticated user:

```dart
Future<Result<List<Fleet>>> getFleets()
```

**Example:**
```dart
final result = await GroupVAN.instance.client.vehicles.getFleets();
result.fold(
  (error) => print('Failed to get fleets: $error'),
  (fleets) {
    print('User fleets:');
    for (final fleet in fleets) {
      print('• ${fleet.name} (${fleet.timestamp})');
    }
  },
);
```

### Get Fleet Vehicles

Get all vehicles in a specific fleet:

```dart
Future<Result<List<Vehicle>>> getFleetVehicles({
  required String fleetId,
})
```

**Example:**
```dart
final result = await GroupVAN.instance.client.vehicles.getFleetVehicles(
  fleetId: '123',
);

result.fold(
  (error) => print('Failed to get fleet vehicles: $error'),
  (vehicles) {
    print('Fleet vehicles:');
    for (final vehicle in vehicles) {
      print('• ${vehicle.year} ${vehicle.make} ${vehicle.model}');
    }
  },
);
```

---

## Engine and Account Methods

### Get Engine Data

Get engine information for specific vehicle configurations:

```dart
Future<Result<List<Vehicle>>> getEngines({
  required EngineSearchRequest request,
})
```

**Example:**
```dart
final engineRequest = EngineSearchRequest(
  groupId: 1,
  yearId: 2021,
  makeId: 123,
  modelId: 456,
);

final result = await GroupVAN.instance.client.vehicles.getEngines(
  request: engineRequest,
);

result.fold(
  (error) => print('Engine search failed: $error'),
  (vehicles) {
    print('Available engines:');
    for (final vehicle in vehicles) {
      if (vehicle.engine != null) {
        print('• ${vehicle.engine}');
      }
    }
  },
);
```

### Get Account Vehicles

Get vehicles at the account level (broader than user vehicles):

```dart
Future<Result<List<Vehicle>>> getAccountVehicles({
  int offset = 0,
  int limit = 20,
})
```

**Example:**
```dart
final result = await GroupVAN.instance.client.vehicles.getAccountVehicles(
  limit: 15,
);

result.fold(
  (error) => print('Failed to get account vehicles: $error'),
  (vehicles) {
    print('Account vehicles (${vehicles.length}):');
    for (final vehicle in vehicles) {
      print('• ${vehicle.year} ${vehicle.make} ${vehicle.model}');
    }
  },
);
```

---

## Data Models

### Vehicle

```dart
class Vehicle {
  final int? id;
  final int year;
  final String make;
  final String model;
  final String? engine;
  final String? vin;
  final int? previousVehicleId;
  final String? description;
  final int? fleetVehicleId;
}
```

### VehicleGroup

```dart
class VehicleGroup {
  final int id;
  final String name;
  final String description;
}
```

### VehicleSearchResponse

```dart
class VehicleSearchResponse {
  final List<Vehicle> vehicles;
  final int totalCount;
  final int page;
}
```

### VehicleFilterRequest

```dart
class VehicleFilterRequest {
  final int groupId;
  final int? yearId;
  final int? makeId;
  final int? modelId;
}
```

### Fleet

```dart
class Fleet {
  final int id;
  final String name;
  final String timestamp;
}
```

---

## Error Handling

All methods return `Result<T>` types for safe error handling:

```dart
final result = await GroupVAN.instance.client.vehicles.getUserVehicles();

result.fold(
  (error) {
    if (error is NetworkException) {
      print('Network error: ${error.message}');
      // Show retry option
    } else if (error is ValidationException) {
      print('Validation error: ${error.errors}');
      // Show field-specific errors
    } else if (error is AuthenticationException) {
      print('Auth error: ${error.message}');
      // Redirect to login
    } else {
      print('Unknown error: $error');
    }
  },
  (vehicles) {
    // Handle success
    print('Loaded ${vehicles.length} vehicles');
  },
);
```

---

## Complete Example

Here's a complete example showing multiple vehicles API calls:

```dart
import 'package:flutter/material.dart';
import 'package:groupvan/groupvan.dart';

class VehiclesExample extends StatefulWidget {
  @override
  _VehiclesExampleState createState() => _VehiclesExampleState();
}

class _VehiclesExampleState extends State<VehiclesExample> {
  List<Vehicle> _vehicles = [];
  List<VehicleGroup> _groups = [];
  List<Fleet> _fleets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load multiple data sources in parallel
    final results = await Future.wait([
      GroupVAN.instance.client.vehicles.getUserVehicles(limit: 10),
      GroupVAN.instance.client.vehicles.getGroups(),
      GroupVAN.instance.client.vehicles.getFleets(),
    ]);

    // Handle user vehicles
    results[0].fold(
      (error) => print('Failed to load vehicles: $error'),
      (vehicles) => setState(() => _vehicles = vehicles),
    );

    // Handle vehicle groups
    results[1].fold(
      (error) => print('Failed to load groups: $error'),
      (groups) => setState(() => _groups = groups),
    );

    // Handle fleets
    results[2].fold(
      (error) => print('Failed to load fleets: $error'),
      (fleets) => setState(() => _fleets = fleets),
    );

    setState(() => _isLoading = false);
  }

  Future<void> _searchVehicles(String query) async {
    if (query.isEmpty) return;

    final result = await GroupVAN.instance.client.vehicles.search(
      query: query,
      page: 1,
    );

    result.fold(
      (error) => _showError('Search failed: $error'),
      (searchResponse) {
        setState(() => _vehicles = searchResponse.vehicles);
        _showSuccess('Found ${searchResponse.totalCount} vehicles');
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vehicles API Demo')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                _buildStats(),
                Expanded(child: _buildVehicleList()),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Search vehicles...',
          suffixIcon: Icon(Icons.search),
        ),
        onSubmitted: _searchVehicles,
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Vehicles', _vehicles.length),
          _buildStatCard('Groups', _groups.length),
          _buildStatCard('Fleets', _fleets.length),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            Text('$count', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleList() {
    if (_vehicles.isEmpty) {
      return Center(child: Text('No vehicles found'));
    }

    return ListView.builder(
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        return ListTile(
          leading: Icon(Icons.directions_car),
          title: Text('${vehicle.year} ${vehicle.make} ${vehicle.model}'),
          subtitle: vehicle.engine != null ? Text(vehicle.engine!) : null,
          trailing: vehicle.vin != null
              ? IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () => _showVehicleDetails(vehicle),
                )
              : null,
        );
      },
    );
  }

  void _showVehicleDetails(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${vehicle.year} ${vehicle.make} ${vehicle.model}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vehicle.engine != null) Text('Engine: ${vehicle.engine}'),
            if (vehicle.vin != null) Text('VIN: ${vehicle.vin}'),
            if (vehicle.description != null) Text('Description: ${vehicle.description}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
```

---

## Next Steps

- **[Catalogs API](../catalogs/)** - Browse catalogs and products
- **[Authentication](../authentication)** - Advanced authentication patterns
- **[Error Handling](../error-handling)** - Comprehensive error handling
- **[Logging](../logging)** - Debugging and monitoring