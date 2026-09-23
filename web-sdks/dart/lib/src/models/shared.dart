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

/// Anything a user can select and service in the catalog: a catalog
/// [Vehicle], or a [NonStandardVehicle] that has no catalog match.
///
/// [id] is the opaque vehicle id the /vehicles endpoints mint; pass it to
/// other endpoints as `vehicle_id`. Endpoints that need catalog fitment reject
/// a [NonStandardVehicle] with a 400.
sealed class Serviceable {
  final String id;
  final String? vin;
  final int? previousVehicleId;
  final String? description;
  final int? fleetVehicleId;
  final String? finId;

  const Serviceable({
    required this.id,
    this.vin,
    this.previousVehicleId,
    this.description,
    this.fleetVehicleId,
    this.finId,
  });

  /// The label to show for this selection: year make model for a [Vehicle],
  /// the description (or VIN, or unit id) for a [NonStandardVehicle].
  String get displayName;

  /// A [Vehicle] when the row carries catalog data, else a [NonStandardVehicle].
  factory Serviceable.fromJson(Map<String, dynamic> json) =>
      json['year'] != null
          ? Vehicle.fromJson(json)
          : NonStandardVehicle.fromJson(json);

  Map<String, dynamic> toJson();
}

/// Vehicle model representing basic vehicle information
class Vehicle extends Serviceable {
  final int year;
  final String make;
  final String model;
  final String? engineId;
  final String? engine;

  const Vehicle({
    required super.id,
    required this.year,
    required this.make,
    required this.model,
    this.engineId,
    this.engine,
    super.vin,
    super.previousVehicleId,
    super.description,
    super.fleetVehicleId,
    super.finId,
  });

  @override
  String get displayName => '$year $make $model';

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['vehicle_id'],
    year: json['year'],
    make: json['make'],
    model: json['model'],
    engineId: json['engine_id'],
    engine: json['engine'],
    vin: json['vin'],
    previousVehicleId: json['previous_vehicle_id'],
    description: json['description'],
    fleetVehicleId: json['fleet_vehicle_id'],
    finId: json['fin_id'],
  );

  @override
  Map<String, dynamic> toJson() => {
    'vehicle_id': id,
    'year': year,
    'make': make,
    'model': model,
    if (engineId != null) 'engine_id': engineId,
    if (engine != null) 'engine': engine,
    if (vin != null) 'vin': vin,
    if (previousVehicleId != null) 'previous_vehicle_id': previousVehicleId,
    if (description != null) 'description': description,
    if (fleetVehicleId != null) 'fleet_vehicle_id': fleetVehicleId,
    if (finId != null) 'fin_id': finId,
  };
}

/// A selectable vehicle with no catalog match: the row had no VIN, an invalid
/// or unrecognised VIN, or one Polk recognises but cannot map to a catalog
/// vehicle (trailers, heavy equipment). It has no year, make, model or fitment.
class NonStandardVehicle extends Serviceable {
  const NonStandardVehicle({
    required super.id,
    super.vin,
    super.previousVehicleId,
    super.description,
    super.fleetVehicleId,
    super.finId,
  });

  @override
  String get displayName => description ?? vin ?? finId ?? '';

  factory NonStandardVehicle.fromJson(Map<String, dynamic> json) =>
      NonStandardVehicle(
        id: json['vehicle_id'],
        vin: json['vin'],
        previousVehicleId: json['previous_vehicle_id'],
        description: json['description'],
        fleetVehicleId: json['fleet_vehicle_id'],
        finId: json['fin_id'],
      );

  @override
  Map<String, dynamic> toJson() => {
    'vehicle_id': id,
    if (vin != null) 'vin': vin,
    if (previousVehicleId != null) 'previous_vehicle_id': previousVehicleId,
    if (description != null) 'description': description,
    if (fleetVehicleId != null) 'fleet_vehicle_id': fleetVehicleId,
    if (finId != null) 'fin_id': finId,
  };
}
