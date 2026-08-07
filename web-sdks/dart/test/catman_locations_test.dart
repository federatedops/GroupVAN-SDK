import 'package:flutter_test/flutter_test.dart';
import 'package:groupvan/groupvan.dart';

/// Mirrors the payload served by GET /v3/catman/locations/{id}.
Map<String, dynamic> locationDetailsJson() => {
  'id': 'loc1',
  'description': 'Main Store',
  'type': 'store',
  'type_description': 'Store',
  'disabled': false,
  'co_man_ship_to': true,
  'include_in_locator': true,
  'servicing_warehouse': 'WH1',
  'account_number': '123456',
  'car_care_manager_id': 42,
  'logo_id': 7,
  'member': {
    'number': 'FED001',
    'name': 'Federated Auto',
    'doordash_enabled': true,
    'b2c_option': 1,
  },
  'contact': {
    'first_name': 'Jane',
    'last_name': 'Doe',
    'email': 'jane@example.com',
    'phone': '5405551234',
  },
  'company': {
    'name': 'Federated Auto Parts',
    'address': '123 Main St',
    'city': 'Staunton',
    'state': 'VA',
    'zip': '24401-0000',
    'country': 'US',
    'latitude': 38.149576001,
    'longitude': -79.072557001,
  },
  'integrations': {
    'aconnex_seller_id': 'ACX1',
    'vic_bill_to_id': 'B1',
    'vic_ship_to_id': 'S1',
    'vic_username': 'vicuser',
    'ow_seller_id': 'OW1',
  },
  'doordash': {
    'enabled': true,
    'billing_id': 'DDB',
    'location_id': 'DDL',
    'pickup_instructions': 'Ring bell',
    'pickup_time_offset': 15,
    'location_close_offset': 30,
  },
  'hours': {
    'sunday': {'open': null, 'close': null},
    'monday': {'open': '08:00', 'close': '17:00'},
    'tuesday': {'open': '08:00', 'close': '17:00'},
    'wednesday': {'open': '08:00', 'close': '17:00'},
    'thursday': {'open': '08:00', 'close': '17:00'},
    'friday': {'open': '08:30', 'close': '17:00'},
    'saturday': {'open': null, 'close': null},
  },
  'b2c': {
    'option': 1,
    'delivery_types': [1, 3],
  },
};

void main() {
  group('MemberLocation', () {
    test('can be deserialized', () {
      final location = MemberLocation.fromJson({
        'id': 'loc1',
        'company_name': 'Federated Auto',
        'address': '123 Main St',
        'city': 'Staunton',
        'state': 'VA',
        'type': 'store',
        'type_description': 'Store',
        'disabled': false,
      });

      expect(location.id, equals('loc1'));
      expect(location.companyName, equals('Federated Auto'));
      expect(location.address, equals('123 Main St'));
      expect(location.city, equals('Staunton'));
      expect(location.state, equals('VA'));
      expect(location.type, equals('store'));
      expect(location.typeDescription, equals('Store'));
      expect(location.disabled, isFalse);
    });

    test('reads a disabled location', () {
      final location = MemberLocation.fromJson({
        'id': 'loc2',
        'company_name': 'Federated Auto',
        'address': '123 Main St',
        'city': 'Staunton',
        'state': 'VA',
        'type': 'whse',
        'type_description': null,
        'disabled': true,
      });

      expect(location.disabled, isTrue);
      expect(location.typeDescription, isNull);
    });
  });

  group('LocationDetails', () {
    test('deserializes top-level fields', () {
      final location = LocationDetails.fromJson(locationDetailsJson());

      expect(location.id, equals('loc1'));
      expect(location.description, equals('Main Store'));
      expect(location.type, equals('store'));
      expect(location.typeDescription, equals('Store'));
      expect(location.disabled, isFalse);
      expect(location.coManShipTo, isTrue);
      expect(location.includeInLocator, isTrue);
      expect(location.servicingWarehouse, equals('WH1'));
      expect(location.accountNumber, equals('123456'));
      expect(location.carCareManagerId, equals(42));
      expect(location.logoId, equals(7));
    });

    test('deserializes the member', () {
      final member = LocationDetails.fromJson(locationDetailsJson()).member;

      expect(member.number, equals('FED001'));
      expect(member.name, equals('Federated Auto'));
      expect(member.doordashEnabled, isTrue);
      expect(member.b2cOption, equals(1));
    });

    test('deserializes the contact', () {
      final contact = LocationDetails.fromJson(locationDetailsJson()).contact;

      expect(contact.firstName, equals('Jane'));
      expect(contact.lastName, equals('Doe'));
      expect(contact.email, equals('jane@example.com'));
      expect(contact.phone, equals('5405551234'));
    });

    test('deserializes the company', () {
      final company = LocationDetails.fromJson(locationDetailsJson()).company;

      expect(company.name, equals('Federated Auto Parts'));
      expect(company.address, equals('123 Main St'));
      expect(company.city, equals('Staunton'));
      expect(company.state, equals('VA'));
      expect(company.zip, equals('24401-0000'));
      expect(company.country, equals('US'));
      expect(company.latitude, closeTo(38.149576001, 0.000001));
      expect(company.longitude, closeTo(-79.072557001, 0.000001));
    });

    test('deserializes integrations', () {
      final integrations = LocationDetails.fromJson(
        locationDetailsJson(),
      ).integrations;

      expect(integrations.aconnexSellerId, equals('ACX1'));
      expect(integrations.vicBillToId, equals('B1'));
      expect(integrations.vicShipToId, equals('S1'));
      expect(integrations.vicUsername, equals('vicuser'));
      expect(integrations.owSellerId, equals('OW1'));
    });

    test('deserializes doordash settings', () {
      final doordash = LocationDetails.fromJson(locationDetailsJson()).doordash;

      expect(doordash.enabled, isTrue);
      expect(doordash.billingId, equals('DDB'));
      expect(doordash.locationId, equals('DDL'));
      expect(doordash.pickupInstructions, equals('Ring bell'));
      expect(doordash.pickupTimeOffset, equals(15));
      expect(doordash.locationCloseOffset, equals(30));
    });

    test('deserializes hours as HH:MM strings', () {
      final hours = LocationDetails.fromJson(locationDetailsJson()).hours;

      expect(hours.monday.open, equals('08:00'));
      expect(hours.monday.close, equals('17:00'));
      expect(hours.friday.open, equals('08:30'));
      expect(hours.sunday.open, isNull);
      expect(hours.sunday.close, isNull);
      expect(hours.saturday.open, isNull);
    });

    test('deserializes b2c settings', () {
      final b2c = LocationDetails.fromJson(locationDetailsJson()).b2c;

      expect(b2c.option, equals(1));
      expect(b2c.deliveryTypes, equals([1, 3]));
    });

    test('keeps nulls null and empty delivery types empty', () {
      final json = locationDetailsJson();
      json['description'] = null;
      json['type_description'] = null;
      json['car_care_manager_id'] = null;
      json['servicing_warehouse'] = null;
      json['b2c'] = {'option': 0, 'delivery_types': <int>[]};

      final location = LocationDetails.fromJson(json);

      expect(location.description, isNull);
      expect(location.typeDescription, isNull);
      expect(location.carCareManagerId, isNull);
      expect(location.servicingWarehouse, isNull);
      expect(location.b2c.option, equals(0));
      expect(location.b2c.deliveryTypes, isEmpty);
    });

    test('reads a disabled location', () {
      final json = locationDetailsJson();
      json['disabled'] = true;
      json['co_man_ship_to'] = false;

      final location = LocationDetails.fromJson(json);

      expect(location.disabled, isTrue);
      expect(location.coManShipTo, isFalse);
    });
  });
}
