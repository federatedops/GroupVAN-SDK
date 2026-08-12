import 'package:flutter_test/flutter_test.dart';
import 'package:groupvan/groupvan.dart';

void main() {
  group('Vehicle.fromJson', () {
    test('decodes a standard vehicle', () {
      final vehicle = Vehicle.fromJson({
        'index': 42,
        'year': 2019,
        'make': 'Ford',
        'model': 'F-150',
        'engine': '3.5L V6',
      });

      expect(vehicle, isNot(isA<NonStandardVehicle>()));
      expect(vehicle.isNonStandard, isFalse);
      expect(vehicle.displayName, '2019 Ford F-150');
    });

    test('returns a NonStandardVehicle when the flag is set', () {
      final vehicle = Vehicle.fromJson({
        'index': 7,
        'is_non_standard': true,
        'name': 'Yard Forklift #3',
        'year': 2019,
        'make': 'Ford',
        'model': 'F-150',
      });

      expect(vehicle, isA<NonStandardVehicle>());
      expect(vehicle.isNonStandard, isTrue);
      expect(vehicle.displayName, 'Yard Forklift #3');
    });

    test('returns a NonStandardVehicle when year/make/model are missing', () {
      final vehicle = Vehicle.fromJson({
        'index': 7,
        'description': 'Unit 44 trailer',
        'vin': '1FTFW1E50MFA12345',
      });

      expect(vehicle, isA<NonStandardVehicle>());
      expect(vehicle.displayName, 'Unit 44 trailer');
      expect(vehicle.vin, '1FTFW1E50MFA12345');
    });

    test('returns a NonStandardVehicle when make/model are blank', () {
      final vehicle = Vehicle.fromJson({
        'index': 7,
        'year': 2019,
        'make': '  ',
        'model': '',
      });

      expect(vehicle, isA<NonStandardVehicle>());
      expect(vehicle.displayName, 'Unspecified vehicle');
    });

    test('falls back to the name when no description is present', () {
      final vehicle = Vehicle.fromJson({
        'index': 7,
        'is_non_standard': true,
        'name': 'Shop compressor',
      });

      expect(vehicle.displayName, 'Shop compressor');
      expect(vehicle.description, isNull);
    });
  });

  group('NonStandardVehicle', () {
    test('round-trips through toJson', () {
      const vehicle = NonStandardVehicle(
        index: -1,
        name: 'Yard Forklift #3',
        vin: 'ABC123',
        fleetVehicleId: 44,
      );

      final decoded = Vehicle.fromJson(vehicle.toJson());

      expect(decoded, isA<NonStandardVehicle>());
      expect(decoded.displayName, 'Yard Forklift #3');
      expect(decoded.vin, 'ABC123');
      expect(decoded.fleetVehicleId, 44);
    });

    test('is assignable wherever a Vehicle is expected', () {
      const Vehicle vehicle = NonStandardVehicle(index: -1, name: 'Trailer');

      expect(vehicle.isNonStandard, isTrue);
      expect(vehicle.year, 0);
      expect(vehicle.make, isEmpty);
      expect(vehicle.model, isEmpty);
    });

    test('copyWith preserves the non-standard type', () {
      const vehicle = NonStandardVehicle(index: -1, name: 'Trailer');
      final renamed = vehicle.copyWith(name: 'Trailer B');

      expect(renamed.isNonStandard, isTrue);
      expect(renamed.displayName, 'Trailer B');
      expect(renamed.index, -1);
    });
  });
}
