import 'shared.dart';

/// Vehicle group information
class VehicleGroup {
  final int id;
  final String name;
  final String description;

  const VehicleGroup({
    required this.id,
    required this.name,
    required this.description,
  });

  factory VehicleGroup.fromJson(Map<String, dynamic> json) => VehicleGroup(
    id: json['id'],
    name: json['name'],
    description: json['description'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };
}

/// VIN search request
class VinSearchRequest {
  final String vin;

  const VinSearchRequest({required this.vin});

  Map<String, dynamic> toJson() => {'vin': vin};
}

/// Plate search request
class PlateSearchRequest {
  final String plate;
  final String state;

  const PlateSearchRequest({required this.plate, required this.state});

  Map<String, dynamic> toJson() => {'plate': plate, 'state': state};
}

/// Vehicle filter request
class VehicleFilterRequest {
  final int groupId;
  final int? yearId;
  final int? makeId;
  final int? modelId;

  const VehicleFilterRequest({
    required this.groupId,
    this.yearId,
    this.makeId,
    this.modelId,
  });

  Map<String, dynamic> toJson() => {
    'group_id': groupId,
    if (yearId != null) 'year_id': yearId,
    if (makeId != null) 'make_id': makeId,
    if (modelId != null) 'model_id': modelId,
  };
}

/// Vehicle filter option
class VehicleFilterOption {
  final int id;
  final String name;
  final List<String> regions;
  final int? rank;

  const VehicleFilterOption({
    required this.id,
    required this.name,
    required this.regions,
    this.rank,
  });

  factory VehicleFilterOption.fromJson(Map<String, dynamic> json, String type) {
    return VehicleFilterOption(
      id: json['${type}_id'],
      name: json['${type}_name'],
      regions: List<String>.from(json['${type}_regions'] ?? []),
      rank: json['${type}_rank'] as int?,
    );
  }
}

class VehicleFilterResponse {
  final List<VehicleFilterOption> models;
  final List<VehicleFilterOption> makes;
  final List<VehicleFilterOption> years;

  const VehicleFilterResponse({
    required this.models,
    required this.makes,
    required this.years,
  });

  factory VehicleFilterResponse.fromJson(
    Map<String, dynamic> json,
  ) => VehicleFilterResponse(
    models: ((json['models'] as List<dynamic>?) ?? [])
        .map(
          (m) =>
              VehicleFilterOption.fromJson(m as Map<String, dynamic>, 'model'),
        )
        .toList(),
    makes: ((json['makes'] as List<dynamic>?) ?? [])
        .map(
          (m) =>
              VehicleFilterOption.fromJson(m as Map<String, dynamic>, 'make'),
        )
        .toList(),
    years: ((json['years'] as List<dynamic>?) ?? [])
        .map(
          (y) =>
              VehicleFilterOption.fromJson(y as Map<String, dynamic>, 'year'),
        )
        .toList(),
  );
}

/// Fleet information
class Fleet {
  final int id;
  final String name;
  final String timestamp;

  const Fleet({required this.id, required this.name, required this.timestamp});

  factory Fleet.fromJson(Map<String, dynamic> json) =>
      Fleet(id: json['id'], name: json['name'], timestamp: json['timestamp']);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'timestamp': timestamp,
  };
}

/// A row in a fleet listing.
///
/// [vehicle] is null when Polk recognised the VIN but could not map it to a
/// catalog vehicle (trailers, heavy equipment). Such rows are listed but
/// cannot be selected or passed to any other endpoint.
class FleetVehicle {
  final int fleetVehicleId;
  final String? description;
  final String? vin;
  final String? finId;
  final Vehicle? vehicle;

  const FleetVehicle({
    required this.fleetVehicleId,
    this.description,
    this.vin,
    this.finId,
    this.vehicle,
  });

  bool get isSelectable => vehicle != null;

  factory FleetVehicle.fromJson(Map<String, dynamic> json) => FleetVehicle(
    fleetVehicleId: json['fleet_vehicle_id'],
    description: json['description'],
    vin: json['vin'],
    finId: json['fin_id'],
    vehicle: json['vehicle_id'] != null ? Vehicle.fromJson(json) : null,
  );

  Map<String, dynamic> toJson() => {
    ...?vehicle?.toJson(),
    'fleet_vehicle_id': fleetVehicleId,
    if (description != null) 'description': description,
    if (vin != null) 'vin': vin,
    if (finId != null) 'fin_id': finId,
  };
}

/// Fleet create request
class FleetCreateRequest {
  final String name;

  const FleetCreateRequest({required this.name});

  Map<String, dynamic> toJson() => {'name': name};
}

/// Fleet update request; only the name can change
class FleetUpdateRequest {
  final String name;

  const FleetUpdateRequest({required this.name});

  Map<String, dynamic> toJson() => {'name': name};
}

/// Fleet add vehicle request
class FleetAddVehicleRequest {
  final String vehicleId;
  final String? description;
  final String? finId;

  const FleetAddVehicleRequest({
    required this.vehicleId,
    this.description,
    this.finId,
  });

  Map<String, dynamic> toJson() => {
    'vehicle_id': vehicleId,
    if (description != null) 'description': description,
    if (finId != null) 'fin_id': finId,
  };
}

/// Acknowledgement that a fleet upload was queued
class FleetUploadSubmitResponse {
  final String jobId;
  final String status;
  final int rowCount;

  const FleetUploadSubmitResponse({
    required this.jobId,
    required this.status,
    required this.rowCount,
  });

  factory FleetUploadSubmitResponse.fromJson(Map<String, dynamic> json) =>
      FleetUploadSubmitResponse(
        jobId: json['job_id'],
        status: json['status'],
        rowCount: json['row_count'],
      );

  Map<String, dynamic> toJson() => {
    'job_id': jobId,
    'status': status,
    'row_count': rowCount,
  };
}

/// A row of a fleet upload that could not be added to the fleet
class FleetUploadFailure {
  final int rowNo;
  final String? finId;
  final String? vin;
  final String reason;

  const FleetUploadFailure({
    required this.rowNo,
    this.finId,
    this.vin,
    required this.reason,
  });

  factory FleetUploadFailure.fromJson(Map<String, dynamic> json) =>
      FleetUploadFailure(
        rowNo: json['row_no'],
        finId: json['fin_id'],
        vin: json['vin'],
        reason: json['reason'],
      );

  Map<String, dynamic> toJson() => {
    'row_no': rowNo,
    if (finId != null) 'fin_id': finId,
    if (vin != null) 'vin': vin,
    'reason': reason,
  };
}

/// Progress of a fleet upload job.
///
/// [status] is one of `queued`, `processing`, `complete`, `failed` or
/// `stalled`. [failures] is a preview capped at 100 rows; page through
/// the full list with `getFleetUploadFailures` when [failureCount] is larger.
class FleetUploadStatusResponse {
  final String jobId;
  final String status;
  final int rowCount;
  final int rowsProcessed;
  final int outputRows;
  final double percent;
  final String? error;
  final int vehiclesDecoded;
  final int failureCount;
  final List<FleetUploadFailure> failures;

  const FleetUploadStatusResponse({
    required this.jobId,
    required this.status,
    required this.rowCount,
    required this.rowsProcessed,
    required this.outputRows,
    required this.percent,
    this.error,
    required this.vehiclesDecoded,
    required this.failureCount,
    required this.failures,
  });

  bool get isTerminal =>
      status == 'complete' || status == 'failed' || status == 'stalled';

  factory FleetUploadStatusResponse.fromJson(Map<String, dynamic> json) =>
      FleetUploadStatusResponse(
        jobId: json['job_id'],
        status: json['status'],
        rowCount: json['row_count'],
        rowsProcessed: json['rows_processed'],
        outputRows: json['output_rows'],
        percent: (json['percent'] as num).toDouble(),
        error: json['error'],
        vehiclesDecoded: json['vehicles_decoded'],
        failureCount: json['failure_count'],
        failures: (json['failures'] as List<dynamic>)
            .map((f) => FleetUploadFailure.fromJson(f as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'job_id': jobId,
    'status': status,
    'row_count': rowCount,
    'rows_processed': rowsProcessed,
    'output_rows': outputRows,
    'percent': percent,
    if (error != null) 'error': error,
    'vehicles_decoded': vehiclesDecoded,
    'failure_count': failureCount,
    'failures': failures.map((f) => f.toJson()).toList(),
  };
}

/// One page of a fleet upload's failures
class FleetUploadFailuresResponse {
  final int total;
  final int offset;
  final int limit;
  final List<FleetUploadFailure> failures;

  const FleetUploadFailuresResponse({
    required this.total,
    required this.offset,
    required this.limit,
    required this.failures,
  });

  factory FleetUploadFailuresResponse.fromJson(Map<String, dynamic> json) =>
      FleetUploadFailuresResponse(
        total: json['total'],
        offset: json['offset'],
        limit: json['limit'],
        failures: (json['failures'] as List<dynamic>)
            .map((f) => FleetUploadFailure.fromJson(f as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'total': total,
    'offset': offset,
    'limit': limit,
    'failures': failures.map((f) => f.toJson()).toList(),
  };
}

/// Engine search request
class EngineSearchRequest {
  final int groupId;
  final int yearId;
  final int makeId;
  final int modelId;

  const EngineSearchRequest({
    required this.groupId,
    required this.yearId,
    required this.makeId,
    required this.modelId,
  });

  Map<String, dynamic> toJson() => {
    'group_id': groupId,
    'year_id': yearId,
    'make_id': makeId,
    'model_id': modelId,
  };
}

/// Engine search response
class EngineSearchResponse {
  final List<Vehicle> vehicles;

  const EngineSearchResponse({required this.vehicles});

  factory EngineSearchResponse.fromJson(Map<String, dynamic> json) =>
      EngineSearchResponse(
        vehicles: (json['vehicles'] as List<dynamic>)
            .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}

/// Vehicle swap request
class VehicleSwapRequest {
  final String vehicleId;
  final int? year;

  const VehicleSwapRequest({required this.vehicleId, this.year});

  Map<String, dynamic> toJson() => {
    'vehicle_id': vehicleId,
    if (year != null) 'year': year,
  };
}

/// Vehicle swap response containing compatible years and vehicles
class VehicleSwapResponse {
  final List<int> years;
  final List<Vehicle> vehicles;

  const VehicleSwapResponse({required this.years, required this.vehicles});

  factory VehicleSwapResponse.fromJson(Map<String, dynamic> json) =>
      VehicleSwapResponse(
        years: (json['years'] as List<dynamic>).cast<int>(),
        vehicles: (json['vehicles'] as List<dynamic>)
            .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}
