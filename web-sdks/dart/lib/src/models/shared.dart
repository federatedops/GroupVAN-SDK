/// Shared models used across different API endpoints
class PaginatedRequest {
  final int? offset;
  final int? limit;

  const PaginatedRequest({
    this.offset = 0,
    this.limit = 20,
  });

  Map<String, dynamic> toJson() => {
    if (offset != null) 'offset': offset,
    if (limit != null) 'limit': limit,
  };
}

/// Vehicle model representing basic vehicle information
class Vehicle {
  final int? vehicleId;
  final int year;
  final String make;
  final String model;
  final String? engineId;
  final String? engine;
  final String? vin;
  final int? previousVehicleId;
  final String? description;
  final int? fleetVehicleId;
  final int? index;

  const Vehicle({
    this.vehicleId,
    required this.year,
    required this.make,
    required this.model,
    this.engineId,
    this.engine,
    this.vin,
    this.previousVehicleId,
    this.description,
    this.fleetVehicleId,
    this.index,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    vehicleId: json['vehicle_id'],
    year: json['year'],
    make: json['make'],
    model: json['model'],
    engineId: json['engine_id'],
    engine: json['engine'],
    vin: json['vin'],
    previousVehicleId: json['previous_vehicle_id'],
    description: json['description'],
    fleetVehicleId: json['fleet_vehicle_id'],
    index: json['index'],
  );

  Map<String, dynamic> toJson() => {
    if (vehicleId != null) 'vehicle_id': vehicleId,
    'year': year,
    'make': make,
    'model': model,
    if (engineId != null) 'engine_id': engineId,
    if (engine != null) 'engine': engine,
    if (vin != null) 'vin': vin,
    if (previousVehicleId != null) 'previous_vehicle_id': previousVehicleId,
    if (description != null) 'description': description,
    if (fleetVehicleId != null) 'fleet_vehicle_id': fleetVehicleId,
    if (index != null) 'index': index,
  };
}

