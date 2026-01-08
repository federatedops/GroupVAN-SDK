import 'package:flutter_test/flutter_test.dart';
import 'package:groupvan/groupvan.dart';

void main() {
  group('GroupVAN SDK', () {
    test('exports required classes', () {
      // Test that all main classes are exported and accessible
      expect(GroupVAN, isA<Type>());
      expect(GroupVANClient, isA<Type>());
      expect(GroupVANAuth, isA<Type>());
      expect(GroupVANVehicles, isA<Type>());
      expect(GroupVANCatalogs, isA<Type>());
      expect(AuthUser, isA<Type>());
      expect(AuthSession, isA<Type>());
      expect(AuthChangeEvent, isA<Type>());
    });

    test('exports token storage classes', () {
      expect(TokenStorage, isA<Type>());
      expect(SecureTokenStorage, isA<Type>());
      expect(MemoryTokenStorage, isA<Type>());
    });

    test('exports core response types', () {
      expect(Result, isA<Type>());
    });

    test('exports model classes', () {
      expect(Vehicle, isA<Type>());
      expect(VehicleGroup, isA<Type>());
      expect(VehicleSearchResponse, isA<Type>());
      expect(VehicleCategory, isA<Type>());
      expect(Catalog, isA<Type>());
      expect(SupplyCategory, isA<Type>());
      expect(SupplySubcategory, isA<Type>());
      expect(ApplicationAsset, isA<Type>());
      expect(ApplicationAssetsRequest, isA<Type>());
      expect(CartItem, isA<Type>());
      expect(PartTypeRequest, isA<Type>());
      expect(PriceRange, isA<Type>());
      expect(ProductFilters, isA<Type>());
      expect(ProductListingRequest, isA<Type>());
      expect(Product, isA<Type>());
      expect(ProductListingResponse, isA<Type>());
      expect(VehicleFilterRequest, isA<Type>());
      expect(VehicleFilterResponse, isA<Type>());
      expect(VehicleFilterOption, isA<Type>());
      expect(Fleet, isA<Type>());
      expect(EngineSearchRequest, isA<Type>());
      expect(VehicleSearchRequest, isA<Type>());
      expect(VinSearchRequest, isA<Type>());
      expect(PlateSearchRequest, isA<Type>());
    });

    test('GroupVAN requires initialization before use', () {
      // Reset singleton for testing
      GroupVAN.dispose();
      
      expect(
        () => GroupVAN.instance,
        throwsStateError,
      );
    });

    test('GroupVAN singleton initialization', () async {
      // Test that singleton can be initialized
      final instance = await GroupVAN.initialize(
        isProduction: false,
        enableLogging: false,
        tokenStorage: MemoryTokenStorage(),
      );

      expect(instance, isNotNull);
      expect(instance.isInitialized, isTrue);
      expect(GroupVAN.instance, equals(instance));

      // Test that subsequent calls return the same instance
      final instance2 = await GroupVAN.initialize(isProduction: false);
      expect(instance2, equals(instance));

      // Clean up
      await GroupVAN.dispose();
    });

    test('GroupVAN client extraction works', () async {
      await GroupVAN.initialize(
        isProduction: false,
        enableLogging: false,
        tokenStorage: MemoryTokenStorage(),
      );

      final client = GroupVAN.instance.client;
      expect(client, isA<GroupVANClient>());
      expect(client.auth, isA<GroupVANAuth>());
      expect(client.vehicles, isA<GroupVANVehicles>());
      expect(client.catalogs, isA<GroupVANCatalogs>());
      expect(client.search, isA<GroupVANSearch>());

      await GroupVAN.dispose();
    });

    test('search client has all expected methods', () async {
      await GroupVAN.initialize(
        isProduction: false,
        enableLogging: false,
        tokenStorage: MemoryTokenStorage(),
      );

      final search = GroupVAN.instance.client.search;
      expect(search, isA<GroupVANSearch>());

      // Test that all methods exist (method type checking)
      expect(search.startSession, isA<Function>());

      await GroupVAN.dispose();
    });

    test('catalogs client has all expected methods', () async {
      await GroupVAN.initialize(
        isProduction: false,
        enableLogging: false,
        tokenStorage: MemoryTokenStorage(),
      );

      final catalogs = GroupVAN.instance.client.catalogs;
      expect(catalogs, isA<GroupVANCatalogs>());
      
      // Test that all methods exist (method type checking)
      expect(catalogs.getCatalogs, isA<Function>());
      expect(catalogs.getVehicleCategories, isA<Function>());
      expect(catalogs.getSupplyCategories, isA<Function>());
      expect(catalogs.getApplicationAssets, isA<Function>());
      expect(catalogs.getCart, isA<Function>());
      expect(catalogs.getProducts, isA<Function>());

      await GroupVAN.dispose();
    });

    test('vehicles client has all expected methods', () async {
      await GroupVAN.initialize(
        isProduction: false,
        enableLogging: false,
        tokenStorage: MemoryTokenStorage(),
      );

      final vehicles = GroupVAN.instance.client.vehicles;
      expect(vehicles, isA<GroupVANVehicles>());
      
      // Test that all methods exist (method type checking)
      expect(vehicles.getUserVehicles, isA<Function>());
      expect(vehicles.search, isA<Function>());
      expect(vehicles.searchByVin, isA<Function>());
      expect(vehicles.searchByPlate, isA<Function>());
      expect(vehicles.getGroups, isA<Function>());
      expect(vehicles.filter, isA<Function>());
      expect(vehicles.getEngines, isA<Function>());
      expect(vehicles.getFleets, isA<Function>());
      expect(vehicles.getFleetVehicles, isA<Function>());
      expect(vehicles.getAccountVehicles, isA<Function>());

      await GroupVAN.dispose();
    });

    group('Vehicle Models', () {
      test('VehicleFilterRequest can be created and serialized', () {
        final request = VehicleFilterRequest(
          groupId: 1,
          yearId: 2021,
          makeId: 123,
          modelId: 456,
        );

        final json = request.toJson();
        expect(json['group_id'], equals(1));
        expect(json['year_id'], equals(2021));
        expect(json['make_id'], equals(123));
        expect(json['model_id'], equals(456));
      });

      test('EngineSearchRequest can be created and serialized', () {
        final request = EngineSearchRequest(
          groupId: 1,
          yearId: 2021,
          makeId: 123,
          modelId: 456,
        );

        final json = request.toJson();
        expect(json['group_id'], equals(1));
        expect(json['year_id'], equals(2021));
        expect(json['make_id'], equals(123));
        expect(json['model_id'], equals(456));
      });
    });

    group('Catalog Models', () {
      test('ProductListingRequest can be created and serialized', () {
        final request = ProductListingRequest(
          catalogId: 1,
          vehicleIndex: 0,
          partTypes: [
            PartTypeRequest(id: 123, name: 'Brake Pads'),
          ],
          filters: ProductFilters(
            brandIds: [1, 2, 3],
            priceRange: PriceRange(min: 10.0, max: 100.0),
          ),
        );

        final json = request.toJson();
        expect(json['catalog_id'], equals(1));
        expect(json['vehicle_index'], equals(0));
        expect(json['part_types'], isA<List>());
        expect(json['filters'], isA<Map>());
      });

      test('ApplicationAssetsRequest can be created and serialized', () {
        final request = ApplicationAssetsRequest(
          applicationIds: [1, 2, 3],
          languageCode: 'en-US',
        );

        final json = request.toJson();
        expect(json['application_ids'], equals('1,2,3'));
        expect(json['language_code'], equals('en-US'));
      });
    });
  });
}