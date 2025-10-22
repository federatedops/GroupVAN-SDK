# Session Management Implementation Plan (Simplified)

## Overview
Implement simple session ID management for GroupVAN SDK to handle `gv-session-id` headers across VehiclesClient and CatalogsClient endpoints, with persistent state using HydratedBloc.

## Current Architecture Analysis

### Session ID Flow
1. **Session ID Sources** (VehiclesClient methods):
   - `getUserVehicles()`
   - `getEngines()`
   - `getFleetVehicles()`
   - `getAccountVehicles()`
   - `searchByPlate()`
   - `searchByVin()`

2. **Session ID Consumers** (CatalogsClient methods):
   - `getVehicleCategories()`
   - `getProducts()`

3. **Existing Infrastructure**:
   - HTTP client already extracts `gv-session-id` from response headers (lines 321-325 in `http_client.dart`)
   - `GroupVanResponse<T>` includes `sessionId` field

## Implementation Plan

### Phase 1: Add Dependencies
**File**: `web-sdks/dart/pubspec.yaml`

```yaml
dependencies:
  # Existing dependencies...
  hydrated_bloc: ^9.1.5
  path_provider: ^2.1.2
```

### Phase 2: Create Session Cubit
**File**: `web-sdks/dart/lib/src/session/session_cubit.dart`

```dart
import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../logging.dart';

/// Simple session management cubit with persistence
/// Only stores the current session ID string
class SessionCubit extends HydratedCubit<String?> {
  SessionCubit() : super(null);

  /// Update session with new session ID
  void updateSession(String sessionId) {
    GroupVanLogger.sdk.fine('Updating session: $sessionId');
    emit(sessionId);
  }

  /// Clear current session
  void clearSession() {
    GroupVanLogger.sdk.fine('Clearing session');
    emit(null);
  }

  /// Get current session ID
  String? get currentSessionId => state;

  /// Check if session exists
  bool get hasSession => state != null;

  @override
  String? fromJson(Map<String, dynamic> json) {
    try {
      return json['session_id'] as String?;
    } catch (e) {
      GroupVanLogger.sdk.severe('Failed to restore session from storage: $e');
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(String? state) {
    try {
      return state != null ? {'session_id': state} : null;
    } catch (e) {
      GroupVanLogger.sdk.severe('Failed to persist session to storage: $e');
      return null;
    }
  }
}
```

### Phase 3: Integrate Session Manager into SDK

#### 3.1 Update GroupVanClient
**File**: `web-sdks/dart/lib/src/client.dart`

```dart
class GroupVanClient {
  final GroupVanClientConfig _config;
  late final GroupVanHttpClient _httpClient;
  late final AuthManager _authManager;
  late final SessionCubit _sessionCubit;
  late final VehiclesClient _vehiclesClient;
  late final CatalogsClient _catalogsClient;
  late final ReportsClient _reportsClient;

  GroupVanClient(this._config);

  /// Session manager
  SessionCubit get session => _sessionCubit;

  /// Current session ID (if available)
  String? get currentSessionId => _sessionCubit.currentSessionId;

  /// Initialize the client
  Future<void> initialize() async {
    // ... existing initialization ...

    // Initialize session cubit
    _sessionCubit = SessionCubit();
    GroupVanLogger.sdk.warning('DEBUG: Session manager initialized');

    // Initialize API clients with session cubit
    _vehiclesClient = VehiclesClient(httpClient, _authManager, _sessionCubit);
    _catalogsClient = CatalogsClient(httpClient, _authManager, _sessionCubit);
    _reportsClient = ReportsClient(httpClient, _authManager);

    // ... rest of initialization ...
  }

  /// Clean up resources
  void dispose() {
    _authManager.dispose();
    _sessionCubit.close();
    GroupVanLogger.sdk.info('GroupVAN SDK Client disposed');
  }
}
```

#### 3.2 Update VehiclesClient
**File**: `web-sdks/dart/lib/src/client.dart`

```dart
class VehiclesClient extends ApiClient {
  final SessionCubit _sessionCubit;

  const VehiclesClient(
    super.httpClient,
    super.authManager,
    this._sessionCubit,
  );

  /// Get user vehicles - stores session ID
  Future<Result<List<Vehicle>>> getUserVehicles({
    int offset = 0,
    int limit = 20,
  }) async {
    // ... existing validation ...

    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/user',
        queryParameters: {'offset': offset, 'limit': limit},
        decoder: (data) => data as List<dynamic>,
      );

      // Store session ID if present
      if (response.sessionId != null) {
        _sessionCubit.updateSession(response.sessionId!);
      }

      final vehicles = response.data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(vehicles);
    } catch (e) {
      // ... existing error handling ...
    }
  }

  // Add same session storage to these methods:
  // - searchByVin()
  // - searchByPlate()
  // - getEngines()
  // - getFleetVehicles()
  // - getAccountVehicles()
  
  // Pattern: if (response.sessionId != null) { _sessionCubit.updateSession(response.sessionId!); }
}
```

#### 3.3 Update CatalogsClient
**File**: `web-sdks/dart/lib/src/client.dart`

```dart
class CatalogsClient extends ApiClient {
  final SessionCubit _sessionCubit;

  const CatalogsClient(
    super.httpClient,
    super.authManager,
    this._sessionCubit,
  );

  /// Get vehicle categories - uses session ID
  Future<Result<List<VehicleCategory>>> getVehicleCategories({
    required int catalogId,
    required int engineIndex,
    String? sessionId,
  }) async {
    // Use provided sessionId or get from cubit
    final effectiveSessionId = sessionId ?? _sessionCubit.currentSessionId;

    try {
      final response = await get<List<dynamic>>(
        '/v3/catalogs/$catalogId/vehicle/$engineIndex/categories',
        decoder: (data) => data as List<dynamic>,
        options: effectiveSessionId != null
            ? Options(
                headers: {
                  'Authorization': 'Bearer ${authManager.currentStatus.accessToken}',
                  'gv-session-id': effectiveSessionId,
                },
              )
            : null,
      );

      final categories = response.data
          .map((item) => VehicleCategory.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(categories);
    } catch (e) {
      // ... existing error handling ...
    }
  }

  // Add same session injection to getProducts()
}
```

### Phase 4: Initialize HydratedBloc Storage

#### 4.1 Update SDK Initialization
**File**: `web-sdks/dart/lib/src/client.dart`

```dart
class GroupVAN {
  static Future<GroupVAN> initialize({
    // ... existing parameters ...
  }) async {
    // Initialize HydratedBloc storage
    final storage = await HydratedStorage.build(
      storageDirectory: await getApplicationDocumentsDirectory(),
    );
    HydratedBloc.storage = storage;

    // ... rest of initialization ...
  }
}
```

### Phase 5: Export Session Management

#### 5.1 Update Main Export
**File**: `web-sdks/dart/lib/groupvan.dart`

```dart
// Export session management
export 'src/session/session_cubit.dart' show SessionCubit;
```

## Usage Example

### Basic Flow (Automatic)
```dart
// Initialize SDK
await GroupVAN.initialize(
  clientId: 'your-client-id',
  isProduction: false,
);

final client = GroupVAN.instance.client;

// Step 1: Get vehicles (automatically stores session ID)
final vehicles = await client.vehicles.getUserVehicles();

// Step 2: Get categories (automatically uses stored session ID)
final categories = await client.catalogs.getVehicleCategories(
  catalogId: 1,
  engineIndex: vehicles.first.index,
);