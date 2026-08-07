/// Catman locations models: a member's locations and full location detail.
library;

/// A single location in the authenticated member's location list.
class MemberLocation {
  final String id;
  final String companyName;
  final String address;
  final String city;
  final String state;

  /// Location type id (e.g. "store").
  final String type;

  /// Display name of the location type (e.g. "Store").
  final String? typeDescription;
  final bool disabled;

  const MemberLocation({
    required this.id,
    required this.companyName,
    required this.address,
    required this.city,
    required this.state,
    required this.type,
    this.typeDescription,
    required this.disabled,
  });

  factory MemberLocation.fromJson(Map<String, dynamic> json) => MemberLocation(
    id: json['id'] as String,
    companyName: json['company_name'] as String,
    address: json['address'] as String,
    city: json['city'] as String,
    state: json['state'] as String,
    type: json['type'] as String,
    typeDescription: json['type_description'] as String?,
    disabled: json['disabled'] as bool? ?? false,
  );
}

/// The member a location belongs to.
class LocationMember {
  final String number;
  final String? name;
  final bool doordashEnabled;
  final int b2cOption;

  const LocationMember({
    required this.number,
    this.name,
    this.doordashEnabled = false,
    this.b2cOption = 0,
  });

  factory LocationMember.fromJson(Map<String, dynamic> json) => LocationMember(
    number: json['number'] as String,
    name: json['name'] as String?,
    doordashEnabled: json['doordash_enabled'] as bool? ?? false,
    b2cOption: json['b2c_option'] as int? ?? 0,
  );
}

/// A location's primary contact.
class LocationContact {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;

  const LocationContact({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
  });

  factory LocationContact.fromJson(Map<String, dynamic> json) =>
      LocationContact(
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
      );
}

/// A location's company name and physical address.
class LocationCompany {
  final String? name;
  final String? address;
  final String? city;
  final String? state;
  final String? zip;
  final String? country;
  final double? latitude;
  final double? longitude;

  const LocationCompany({
    this.name,
    this.address,
    this.city,
    this.state,
    this.zip,
    this.country,
    this.latitude,
    this.longitude,
  });

  factory LocationCompany.fromJson(Map<String, dynamic> json) =>
      LocationCompany(
        name: json['name'] as String?,
        address: json['address'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        zip: json['zip'] as String?,
        country: json['country'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

/// Third-party identifiers associated with a location.
class LocationIntegrations {
  final String? aconnexSellerId;
  final String? vicBillToId;
  final String? vicShipToId;
  final String? vicUsername;
  final String? owSellerId;

  const LocationIntegrations({
    this.aconnexSellerId,
    this.vicBillToId,
    this.vicShipToId,
    this.vicUsername,
    this.owSellerId,
  });

  factory LocationIntegrations.fromJson(Map<String, dynamic> json) =>
      LocationIntegrations(
        aconnexSellerId: json['aconnex_seller_id'] as String?,
        vicBillToId: json['vic_bill_to_id'] as String?,
        vicShipToId: json['vic_ship_to_id'] as String?,
        vicUsername: json['vic_username'] as String?,
        owSellerId: json['ow_seller_id'] as String?,
      );
}

/// A location's DoorDash delivery configuration.
///
/// [enabled] is false whenever DoorDash is disabled for the member, regardless
/// of the location's own setting.
class LocationDoordash {
  final bool enabled;
  final String? billingId;
  final String? locationId;
  final String? pickupInstructions;

  /// Minutes added to the pickup time quoted to DoorDash.
  final int pickupTimeOffset;

  /// Minutes before closing after which pickups are no longer scheduled.
  final int locationCloseOffset;

  const LocationDoordash({
    this.enabled = false,
    this.billingId,
    this.locationId,
    this.pickupInstructions,
    this.pickupTimeOffset = 0,
    this.locationCloseOffset = 0,
  });

  factory LocationDoordash.fromJson(Map<String, dynamic> json) =>
      LocationDoordash(
        enabled: json['enabled'] as bool? ?? false,
        billingId: json['billing_id'] as String?,
        locationId: json['location_id'] as String?,
        pickupInstructions: json['pickup_instructions'] as String?,
        pickupTimeOffset: json['pickup_time_offset'] as int? ?? 0,
        locationCloseOffset: json['location_close_offset'] as int? ?? 0,
      );
}

/// Opening and closing time for a single day as "HH:MM" strings. Both are null
/// when no hours are set for that day.
class DayHours {
  final String? open;
  final String? close;

  const DayHours({this.open, this.close});

  factory DayHours.fromJson(Map<String, dynamic> json) =>
      DayHours(open: json['open'] as String?, close: json['close'] as String?);
}

/// A location's opening hours for each day of the week.
class LocationHours {
  final DayHours sunday;
  final DayHours monday;
  final DayHours tuesday;
  final DayHours wednesday;
  final DayHours thursday;
  final DayHours friday;
  final DayHours saturday;

  const LocationHours({
    this.sunday = const DayHours(),
    this.monday = const DayHours(),
    this.tuesday = const DayHours(),
    this.wednesday = const DayHours(),
    this.thursday = const DayHours(),
    this.friday = const DayHours(),
    this.saturday = const DayHours(),
  });

  factory LocationHours.fromJson(Map<String, dynamic> json) => LocationHours(
    sunday: _day(json['sunday']),
    monday: _day(json['monday']),
    tuesday: _day(json['tuesday']),
    wednesday: _day(json['wednesday']),
    thursday: _day(json['thursday']),
    friday: _day(json['friday']),
    saturday: _day(json['saturday']),
  );

  static DayHours _day(dynamic value) => value is Map<String, dynamic>
      ? DayHours.fromJson(value)
      : const DayHours();
}

/// A location's business-to-consumer settings.
class LocationB2C {
  final int option;

  /// Ids of the delivery types enabled for this location.
  final List<int> deliveryTypes;

  const LocationB2C({this.option = 0, this.deliveryTypes = const []});

  factory LocationB2C.fromJson(Map<String, dynamic> json) => LocationB2C(
    option: json['option'] as int? ?? 0,
    deliveryTypes: (json['delivery_types'] as List<dynamic>? ?? const [])
        .map((t) => t as int)
        .toList(),
  );
}

/// Full detail for a single member location.
class LocationDetails {
  final String id;
  final String? description;

  /// Location type id (e.g. "store").
  final String? type;

  /// Display name of the location type (e.g. "Store").
  final String? typeDescription;
  final bool disabled;
  final bool coManShipTo;
  final bool includeInLocator;
  final String? servicingWarehouse;
  final String? accountNumber;
  final int? carCareManagerId;
  final int logoId;
  final LocationMember member;
  final LocationContact contact;
  final LocationCompany company;
  final LocationIntegrations integrations;
  final LocationDoordash doordash;
  final LocationHours hours;
  final LocationB2C b2c;

  const LocationDetails({
    required this.id,
    this.description,
    this.type,
    this.typeDescription,
    this.disabled = false,
    this.coManShipTo = false,
    this.includeInLocator = false,
    this.servicingWarehouse,
    this.accountNumber,
    this.carCareManagerId,
    this.logoId = 0,
    required this.member,
    this.contact = const LocationContact(),
    this.company = const LocationCompany(),
    this.integrations = const LocationIntegrations(),
    this.doordash = const LocationDoordash(),
    this.hours = const LocationHours(),
    this.b2c = const LocationB2C(),
  });

  factory LocationDetails.fromJson(
    Map<String, dynamic> json,
  ) => LocationDetails(
    id: json['id'] as String,
    description: json['description'] as String?,
    type: json['type'] as String?,
    typeDescription: json['type_description'] as String?,
    disabled: json['disabled'] as bool? ?? false,
    coManShipTo: json['co_man_ship_to'] as bool? ?? false,
    includeInLocator: json['include_in_locator'] as bool? ?? false,
    servicingWarehouse: json['servicing_warehouse'] as String?,
    accountNumber: json['account_number'] as String?,
    carCareManagerId: json['car_care_manager_id'] as int?,
    logoId: json['logo_id'] as int? ?? 0,
    member: LocationMember.fromJson(json['member'] as Map<String, dynamic>),
    contact: LocationContact.fromJson(json['contact'] as Map<String, dynamic>),
    company: LocationCompany.fromJson(json['company'] as Map<String, dynamic>),
    integrations: LocationIntegrations.fromJson(
      json['integrations'] as Map<String, dynamic>,
    ),
    doordash: LocationDoordash.fromJson(
      json['doordash'] as Map<String, dynamic>,
    ),
    hours: LocationHours.fromJson(json['hours'] as Map<String, dynamic>),
    b2c: LocationB2C.fromJson(json['b2c'] as Map<String, dynamic>),
  );
}
