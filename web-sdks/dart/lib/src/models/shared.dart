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

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
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
}
