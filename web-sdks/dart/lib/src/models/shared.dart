/// Shared models used across different API endpoints
class PaginatedRequest {
  final int? offset;
  final int? limit;

  const PaginatedRequest({this.offset = 0, this.limit = 20});

  Map<String, dynamic> toJson() => {
    if (offset != null) 'offset': offset,
    if (limit != null) 'limit': limit,
  };
}

/// Vehicle model representing basic vehicle information
class Vehicle {
  final int index;
  final int year;
  final String make;
  final String model;
  final String? engineId;
  final String? engine;
  final String? vin;
  final int? previousVehicleId;
  final String? description;
  final int? fleetVehicleId;

  const Vehicle({
    required this.index,
    required this.year,
    required this.make,
    required this.model,
    this.engineId,
    this.engine,
    this.vin,
    this.previousVehicleId,
    this.description,
    this.fleetVehicleId,
  });

  /// Returns a [NonStandardVehicle] when the payload carries no decoded
  /// year/make/model, otherwise a fully decoded [Vehicle].
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    if (_isNonStandardJson(json)) return NonStandardVehicle.fromJson(json);
    return Vehicle(
      index: json['index'],
      year: json['year'],
      make: json['make'],
      model: json['model'],
      engineId: json['engine_id'],
      engine: json['engine'],
      vin: json['vin'],
      previousVehicleId: json['previous_vehicle_id'],
      description: json['description'],
      fleetVehicleId: json['fleet_vehicle_id'],
    );
  }

  /// Whether this vehicle has no decoded year/make/model and therefore cannot
  /// be used for catalog lookups (part types, categories, applications).
  bool get isNonStandard => false;

  /// Label to show in vehicle selectors and headers.
  String get displayName => '$year $make $model';

  Map<String, dynamic> toJson() => {
    'index': index,
    'year': year,
    'make': make,
    'model': model,
    if (engineId != null) 'engine_id': engineId,
    if (engine != null) 'engine': engine,
    if (vin != null) 'vin': vin,
    if (previousVehicleId != null) 'previous_vehicle_id': previousVehicleId,
    if (description != null) 'description': description,
    if (fleetVehicleId != null) 'fleet_vehicle_id': fleetVehicleId,
  };

  static bool _isNonStandardJson(Map<String, dynamic> json) {
    if (json['is_non_standard'] == true) return true;
    final make = json['make'];
    final model = json['model'];
    if (json['year'] == null || make == null || model == null) return true;
    if (make is String && make.trim().isEmpty) return true;
    if (model is String && model.trim().isEmpty) return true;
    return false;
  }
}

/// A vehicle the catalog could not decode into a year/make/model — for example
/// an unrecognized VIN or a piece of fleet equipment that ACES does not cover.
///
/// It carries a free-form [name] instead, and reports [isNonStandard] as true
/// so callers can skip catalog lookups that need a decoded vehicle.
class NonStandardVehicle extends Vehicle {
  /// Free-form label supplied by the user or the fleet record.
  final String name;

  const NonStandardVehicle({
    required super.index,
    required this.name,
    super.engineId,
    super.engine,
    super.vin,
    super.previousVehicleId,
    super.description,
    super.fleetVehicleId,
  }) : super(year: 0, make: '', model: '');

  factory NonStandardVehicle.fromJson(Map<String, dynamic> json) =>
      NonStandardVehicle(
        index: json['index'] ?? 0,
        name: json['name'] ?? json['description'] ?? 'Unspecified vehicle',
        engineId: json['engine_id'],
        engine: json['engine'],
        vin: json['vin'],
        previousVehicleId: json['previous_vehicle_id'],
        description: json['description'],
        fleetVehicleId: json['fleet_vehicle_id'],
      );

  @override
  bool get isNonStandard => true;

  @override
  String get displayName => name;

  @override
  Map<String, dynamic> toJson() => {
    'index': index,
    'name': name,
    'is_non_standard': true,
    if (engineId != null) 'engine_id': engineId,
    if (engine != null) 'engine': engine,
    if (vin != null) 'vin': vin,
    if (previousVehicleId != null) 'previous_vehicle_id': previousVehicleId,
    if (description != null) 'description': description,
    if (fleetVehicleId != null) 'fleet_vehicle_id': fleetVehicleId,
  };

  NonStandardVehicle copyWith({
    int? index,
    String? name,
    String? engineId,
    String? engine,
    String? vin,
    int? previousVehicleId,
    String? description,
    int? fleetVehicleId,
  }) => NonStandardVehicle(
    index: index ?? this.index,
    name: name ?? this.name,
    engineId: engineId ?? this.engineId,
    engine: engine ?? this.engine,
    vin: vin ?? this.vin,
    previousVehicleId: previousVehicleId ?? this.previousVehicleId,
    description: description ?? this.description,
    fleetVehicleId: fleetVehicleId ?? this.fleetVehicleId,
  );
}
