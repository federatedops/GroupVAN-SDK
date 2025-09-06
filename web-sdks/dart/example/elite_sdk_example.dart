/// Elite GroupVAN SDK Example
/// 
/// Demonstrates the singleton pattern for GroupVAN SDK usage.
/// This is the only supported way to use the SDK.

library elite_sdk_example;

import 'dart:io';
import 'package:groupvan/groupvan.dart';

void main() async {
  print('🚀 Elite GroupVAN SDK Example');
  print('=====================================');

  try {
    // Initialize SDK with elegant singleton pattern
    await GroupVAN.initialize(
      isProduction: false,          // Use staging: https://api.staging.groupvan.com
      enableLogging: true,          // Enable for demo purposes
      enableCaching: true,          // Enable response caching
      autoRefreshTokens: true,      // Automatic token refresh
      // baseUrl: 'https://my-feature-branch.dev.groupvan.com', // Override for review branches
      // tokenStorage: SecureTokenStorage(), // Used by default
    );
    print('✅ SDK initialized successfully (using secure token storage)');

    // Extract client for reuse (like Supabase pattern)
    final groupvan = GroupVAN.instance.client;
    print('✅ Client extracted for reuse');

    // Example 1: Authentication
    await demonstrateAuthentication(groupvan);

    // Example 2: Vehicle Operations  
    await demonstrateVehicleOperations(groupvan);

    // Example 3: Catalog Operations
    await demonstrateCatalogOperations(groupvan);

    // Example 4: Authentication Status Monitoring
    demonstrateAuthStatusMonitoring();

    print('\n🎉 All examples completed successfully!');
    
    // Keep the program running to see auth state changes
    await Future.delayed(const Duration(seconds: 2));
    
  } catch (e) {
    print('❌ Example failed: $e');
  } finally {
    // Always dispose the SDK to clean up resources
    await GroupVAN.dispose();
    print('🧹 SDK disposed');
  }
}

/// Demonstrate authentication with the client pattern
Future<void> demonstrateAuthentication(GroupVANClient groupvan) async {
  print('\n🔐 Authentication Example');
  print('-------------------------');

  try {
    // Prompt for credentials
    stdout.write('Enter username (or press enter to skip): ');
    final username = stdin.readLineSync() ?? '';
    
    if (username.isEmpty) {
      print('⏭️  Skipping authentication demo');
      return;
    }
    
    stdout.write('Enter password: ');
    final password = stdin.readLineSync() ?? '';
    
    stdout.write('Enter developer ID: ');
    final developerId = stdin.readLineSync() ?? '';

    // Authenticate using the extracted client
    print('🔄 Authenticating...');
    await groupvan.auth.signInWithPassword(
      username: username,
      password: password,
      developerId: developerId,
    );

    print('✅ Authentication successful!');
    
    // Access current user information
    final user = groupvan.auth.currentUser;
    if (user != null) {
      print('   User ID: ${user.userId}');
      print('   Developer ID: ${user.developerId}');
      print('   Integration: ${user.integration ?? 'N/A'}');
    }

    // Access current session
    final session = groupvan.auth.currentSession;
    if (session != null) {
      print('   Session expires at: ${session.expiresAt}');
      print('   Session expired: ${session.isExpired}');
    }

  } catch (e) {
    print('❌ Authentication failed: $e');
  }
}

/// Demonstrate vehicle operations using the client
Future<void> demonstrateVehicleOperations(GroupVANClient groupvan) async {
  print('\n🚗 Vehicle Operations Example');
  print('-----------------------------');

  // Check if we're authenticated
  final user = groupvan.auth.currentUser;
  if (user == null) {
    print('ℹ️  Not authenticated - skipping vehicle demos');
    return;
  }

  // Example 1: Get vehicle groups
  print('📋 Getting vehicle groups...');
  final groupsResult = await groupvan.vehicles.getGroups();
  
  groupsResult.fold(
    (error) => print('❌ Failed to get groups: $error'),
    (groups) {
      print('✅ Retrieved ${groups.length} vehicle groups:');
      for (final group in groups.take(3)) {
        print('   • ${group.name}: ${group.description}');
      }
    },
  );

  // Example 2: Get user vehicles
  print('\n🔍 Getting user vehicles (first 5)...');
  final vehiclesResult = await groupvan.vehicles.getUserVehicles(limit: 5);
  
  vehiclesResult.fold(
    (error) => print('❌ Failed to get vehicles: $error'),
    (vehicles) {
      print('✅ Retrieved ${vehicles.length} user vehicles:');
      for (final vehicle in vehicles) {
        print('   • ${vehicle.year} ${vehicle.make} ${vehicle.model}');
        if (vehicle.engine != null) {
          print('     Engine: ${vehicle.engine}');
        }
      }
    },
  );

  // Example 3: Search vehicles
  print('\n🔎 Searching for Toyota vehicles...');
  final searchResult = await groupvan.vehicles.search(
    query: 'Toyota',
    page: 1,
  );
  
  searchResult.fold(
    (error) => print('❌ Search failed: $error'),
    (searchResponse) {
      print('✅ Search found ${searchResponse.totalCount} vehicles');
      print('   Showing page ${searchResponse.page}:');
      for (final vehicle in searchResponse.vehicles.take(3)) {
        print('   • ${vehicle.year} ${vehicle.make} ${vehicle.model}');
      }
    },
  );

  // Example 4: VIN search
  print('\n🏷️  Searching by VIN...');
  const testVin = '1HGCM82633A123456'; // Valid format
  final vinResult = await groupvan.vehicles.searchByVin(testVin);
  
  vinResult.fold(
    (error) => print('❌ VIN search failed: $error'),
    (vehicles) {
      if (vehicles == null) {
        print('ℹ️  No vehicle found for VIN: $testVin');
      } else {
        print('✅ Found ${vehicles.length} vehicles for VIN');
      }
    },
  );

  // Example 5: Vehicle filtering
  if (groupsResult.isSuccess && groupsResult.value.isNotEmpty) {
    print('\n🎯 Filtering vehicles...');
    final firstGroup = groupsResult.value.first;
    final filterRequest = VehicleFilterRequest(
      groupId: firstGroup.id,
      yearId: 2021,
    );
    
    final filterResult = await groupvan.vehicles.filter(request: filterRequest);
    filterResult.fold(
      (error) => print('❌ Vehicle filtering failed: $error'),
      (filterResponse) {
        print('✅ Filter results:');
        if (filterResponse.years != null) {
          print('   Years: ${filterResponse.years!.length}');
        }
        if (filterResponse.makes != null) {
          print('   Makes: ${filterResponse.makes!.length}');
        }
        if (filterResponse.models != null) {
          print('   Models: ${filterResponse.models!.length}');
        }
      },
    );
  }

  // Example 6: Get fleets
  print('\n🚛 Getting user fleets...');
  final fleetsResult = await groupvan.vehicles.getFleets();
  
  fleetsResult.fold(
    (error) => print('❌ Failed to get fleets: $error'),
    (fleets) {
      print('✅ Retrieved ${fleets.length} fleets:');
      for (final fleet in fleets.take(3)) {
        print('   • ${fleet.name} (${fleet.timestamp})');
      }
    },
  );

  // Example 7: Get fleet vehicles for first fleet
  if (fleetsResult.isSuccess && fleetsResult.value.isNotEmpty) {
    print('\n🚗 Getting vehicles for first fleet...');
    final firstFleet = fleetsResult.value.first;
    final fleetVehiclesResult = await groupvan.vehicles.getFleetVehicles(
      fleetId: firstFleet.id.toString(),
    );
    
    fleetVehiclesResult.fold(
      (error) => print('❌ Failed to get fleet vehicles: $error'),
      (vehicles) {
        print('✅ Retrieved ${vehicles.length} vehicles from fleet "${firstFleet.name}":');
        for (final vehicle in vehicles.take(3)) {
          print('   • ${vehicle.year} ${vehicle.make} ${vehicle.model}');
        }
      },
    );
  }

  // Example 8: Get account vehicles
  print('\n🏢 Getting account vehicles...');
  final accountVehiclesResult = await groupvan.vehicles.getAccountVehicles(limit: 5);
  
  accountVehiclesResult.fold(
    (error) => print('❌ Failed to get account vehicles: $error'),
    (vehicles) {
      print('✅ Retrieved ${vehicles.length} account vehicles:');
      for (final vehicle in vehicles) {
        print('   • ${vehicle.year} ${vehicle.make} ${vehicle.model}');
      }
    },
  );
}

/// Demonstrate catalog operations using the client
Future<void> demonstrateCatalogOperations(GroupVANClient groupvan) async {
  print('\n📚 Catalog Operations Example');
  print('-----------------------------');

  // Check if we're authenticated
  final user = groupvan.auth.currentUser;
  if (user == null) {
    print('ℹ️  Not authenticated - skipping catalog demos');
    return;
  }

  // Get catalogs
  print('📖 Getting available catalogs...');
  final catalogsResult = await groupvan.catalogs.getCatalogs();
  
  catalogsResult.fold(
    (error) => print('❌ Failed to get catalogs: $error'),
    (catalogs) {
      print('✅ Retrieved ${catalogs.length} catalogs:');
      for (final catalog in catalogs.take(3)) {
        print('   • ${catalog.name} (${catalog.type})');
      }
    },
  );

  // Example: Get supply categories for first catalog
  if (catalogsResult.isSuccess && catalogsResult.value.isNotEmpty) {
    print('\n🏷️  Getting supply categories for first catalog...');
    final firstCatalog = catalogsResult.value.first;
    final supplyCategoriesResult = await groupvan.catalogs.getSupplyCategories(
      catalogId: firstCatalog.id,
    );
    
    supplyCategoriesResult.fold(
      (error) => print('❌ Failed to get supply categories: $error'),
      (categories) {
        print('✅ Retrieved ${categories.length} supply categories:');
        for (final category in categories.take(3)) {
          print('   • ${category.name}');
        }
      },
    );
  }

  // Example: Get application assets
  print('\n🔧 Getting application assets...');
  final assetsResult = await groupvan.catalogs.getApplicationAssets(
    applicationIds: [1, 2, 3],
    languageCode: 'en-US',
  );
  
  assetsResult.fold(
    (error) => print('❌ Failed to get application assets: $error'),
    (assets) {
      print('✅ Retrieved ${assets.length} application assets:');
      for (final asset in assets.take(2)) {
        print('   • ${asset.type} (${asset.language}): ${asset.uri}');
      }
    },
  );

  // Example: Demonstrate product listing request structure
  print('\n📦 Product listing request example...');
  final productRequest = ProductListingRequest(
    catalogId: 1,
    vehicleIndex: 0,
    partTypes: [
      PartTypeRequest(id: 123, name: 'Brake Pads'),
      PartTypeRequest(id: 456, name: 'Oil Filters'),
    ],
    filters: ProductFilters(
      brandIds: [1, 2, 3],
      priceRange: PriceRange(min: 10.0, max: 100.0),
    ),
  );
  print('✅ Created product listing request for ${productRequest.partTypes.length} part types');
  print('   Filter: \$${productRequest.filters?.priceRange?.min}-\$${productRequest.filters?.priceRange?.max}');
}

/// Demonstrate real-time authentication state monitoring
void demonstrateAuthStatusMonitoring() {
  print('\n📡 Authentication State Monitoring');
  print('----------------------------------');

  // Listen to auth state changes with reactive streams
  GroupVAN.instance.auth.onAuthStateChange.listen((state) {
    switch (state.event) {
      case AuthChangeEvent.signedIn:
        print('🔐 Event: User signed in');
        print('    User ID: ${state.user?.userId}');
        print('    Developer ID: ${state.user?.developerId}');
        break;
        
      case AuthChangeEvent.signedOut:
        print('🔓 Event: User signed out');
        break;
        
      case AuthChangeEvent.tokenRefreshed:
        print('🔄 Event: Token refreshed');
        print('    New expiration: ${state.session?.expiresAt}');
        break;
        
      case AuthChangeEvent.passwordRecovery:
        print('🔑 Event: Password recovery initiated');
        break;
    }
  });

  print('✅ Auth state monitoring enabled');
  print('   Listening for: sign in, sign out, token refresh events');
}