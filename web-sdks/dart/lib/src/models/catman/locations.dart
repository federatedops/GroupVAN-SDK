/// Catman locations models: a member's locations and full location detail.
library;

import '../auth.dart' show LocationType;

/// A single location in the authenticated member's location list.
class MemberLocation {
  final String id;
  final String companyName;
  final String address;
  final String city;
  final String state;

  final LocationType? type;

  /// Display name of the location type (e.g. "Store").
  final String? typeDescription;
  final bool disabled;

  const MemberLocation({
    required this.id,
    required this.companyName,
    required this.address,
    required this.city,
    required this.state,
    this.type,
    this.typeDescription,
    required this.disabled,
  });

  factory MemberLocation.fromJson(Map<String, dynamic> json) => MemberLocation(
    id: json['id'] as String,
    companyName: json['company_name'] as String,
    address: json['address'] as String,
    city: json['city'] as String,
    state: json['state'] as String,
    type: LocationType.fromValue(json['type'] as String?),
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

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
  };
}

/// A location's company name and physical address.
///
/// [latitude] and [longitude] are geocoded from the address by FedLink and are
/// read-only: they are never sent by [toJson], and the API rejects them.
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

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'city': city,
    'state': state,
    'zip': zip,
    'country': country,
  };
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

  Map<String, dynamic> toJson() => {
    'aconnex_seller_id': aconnexSellerId,
    'vic_bill_to_id': vicBillToId,
    'vic_ship_to_id': vicShipToId,
    'vic_username': vicUsername,
    'ow_seller_id': owSellerId,
  };
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

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'billing_id': billingId,
    'location_id': locationId,
    'pickup_instructions': pickupInstructions,
    'pickup_time_offset': pickupTimeOffset,
    'location_close_offset': locationCloseOffset,
  };
}

/// Opening and closing time for a single day as "HH:MM" strings. Both are null
/// when no hours are set for that day.
class DayHours {
  final String? open;
  final String? close;

  const DayHours({this.open, this.close});

  factory DayHours.fromJson(Map<String, dynamic> json) =>
      DayHours(open: json['open'] as String?, close: json['close'] as String?);

  Map<String, dynamic> toJson() => {'open': open, 'close': close};
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

  Map<String, dynamic> toJson() => {
    'sunday': sunday.toJson(),
    'monday': monday.toJson(),
    'tuesday': tuesday.toJson(),
    'wednesday': wednesday.toJson(),
    'thursday': thursday.toJson(),
    'friday': friday.toJson(),
    'saturday': saturday.toJson(),
  };
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

  Map<String, dynamic> toJson() => {
    'option': option,
    'delivery_types': deliveryTypes,
  };
}

/// Full detail for a single member location.
class LocationDetails {
  final String id;
  final String? description;

  final LocationType? type;

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
    type: LocationType.fromValue(json['type'] as String?),
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

/// Changes to apply to a location with PATCH /v3/catman/locations/{id}.
///
/// Only the fields given are sent; everything else keeps its current value.
/// A nested group ([contact], [company], ...) is sent whole, so pass the full
/// desired group, not just the changed members.
class LocationUpdate {
  final String? description;
  final LocationType? type;
  final bool? disabled;
  final bool? coManShipTo;

  /// Only stores appear in the locator; the API stores false for other types.
  final bool? includeInLocator;
  final String? servicingWarehouse;
  final String? accountNumber;
  final int? carCareManagerId;

  /// Set true to clear the car care manager, since null means "unchanged".
  final bool clearCarCareManagerId;
  final int? logoId;
  final LocationContact? contact;
  final LocationCompany? company;
  final LocationIntegrations? integrations;
  final LocationDoordash? doordash;
  final LocationHours? hours;
  final LocationB2C? b2c;

  const LocationUpdate({
    this.description,
    this.type,
    this.disabled,
    this.coManShipTo,
    this.includeInLocator,
    this.servicingWarehouse,
    this.accountNumber,
    this.carCareManagerId,
    this.clearCarCareManagerId = false,
    this.logoId,
    this.contact,
    this.company,
    this.integrations,
    this.doordash,
    this.hours,
    this.b2c,
  });

  bool get isEmpty => toJson().isEmpty;

  Map<String, dynamic> toJson() => {
    if (description != null) 'description': description,
    if (type != null) 'type': type!.value,
    if (disabled != null) 'disabled': disabled,
    if (coManShipTo != null) 'co_man_ship_to': coManShipTo,
    if (includeInLocator != null) 'include_in_locator': includeInLocator,
    if (servicingWarehouse != null) 'servicing_warehouse': servicingWarehouse,
    if (accountNumber != null) 'account_number': accountNumber,
    if (clearCarCareManagerId)
      'car_care_manager_id': null
    else if (carCareManagerId != null)
      'car_care_manager_id': carCareManagerId,
    if (logoId != null) 'logo_id': logoId,
    if (contact != null) 'contact': contact!.toJson(),
    if (company != null) 'company': company!.toJson(),
    if (integrations != null) 'integrations': integrations!.toJson(),
    if (doordash != null) 'doordash': doordash!.toJson(),
    if (hours != null) 'hours': hours!.toJson(),
    if (b2c != null) 'b2c': b2c!.toJson(),
  };
}
