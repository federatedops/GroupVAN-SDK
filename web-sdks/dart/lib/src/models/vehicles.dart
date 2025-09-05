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

/// Vehicle search request
class VehicleSearchRequest {
  final String query;
  final int? groupId;
  final int pageNumber;

  const VehicleSearchRequest({
    required this.query,
    this.groupId,
    this.pageNumber = 1,
  });

  Map<String, dynamic> toJson() => {
    'query': query,
    if (groupId != null) 'group_id': groupId,
    'page': pageNumber,
  };
}

/// Vehicle search response
class VehicleSearchResponse {
  final List<Vehicle> vehicles;
  final int totalCount;
  final int page;

  const VehicleSearchResponse({
    required this.vehicles,
    required this.totalCount,
    required this.page,
  });

  factory VehicleSearchResponse.fromJson(Map<String, dynamic> json) => VehicleSearchResponse(
    vehicles: (json['vehicles'] as List<dynamic>)
        .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
        .toList(),
    totalCount: json['total_count'],
    page: json['page'],
  );
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

  const PlateSearchRequest({
    required this.plate,
    required this.state,
  });

  Map<String, dynamic> toJson() => {
    'plate': plate,
    'state': state,
  };
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

  const VehicleFilterOption({
    required this.id,
    required this.name,
    required this.regions,
  });

  factory VehicleFilterOption.fromJson(Map<String, dynamic> json, String type) {
    return VehicleFilterOption(
      id: json['${type}_id'],
      name: json['${type}_name'],
      regions: List<String>.from(json['${type}_regions'] ?? []),
    );
  }
}

/// Vehicle filter response
class VehicleFilterResponse {
  final List<VehicleFilterOption>? models;
  final List<VehicleFilterOption>? makes;
  final List<VehicleFilterOption>? years;

  const VehicleFilterResponse({
    this.models,
    this.makes,
    this.years,
  });

  factory VehicleFilterResponse.fromJson(Map<String, dynamic> json) => VehicleFilterResponse(
    models: (json['models'] as List<dynamic>?)
        ?.map((m) => VehicleFilterOption.fromJson(m as Map<String, dynamic>, 'model'))
        .toList(),
    makes: (json['makes'] as List<dynamic>?)
        ?.map((m) => VehicleFilterOption.fromJson(m as Map<String, dynamic>, 'make'))
        .toList(),
    years: (json['years'] as List<dynamic>?)
        ?.map((y) => VehicleFilterOption.fromJson(y as Map<String, dynamic>, 'year'))
        .toList(),
  );
}

/// Fleet information
class Fleet {
  final int id;
  final String name;
  final String timestamp;

  const Fleet({
    required this.id,
    required this.name,
    required this.timestamp,
  });

  factory Fleet.fromJson(Map<String, dynamic> json) => Fleet(
    id: json['id'],
    name: json['name'],
    timestamp: json['timestamp'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'timestamp': timestamp,
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

  factory EngineSearchResponse.fromJson(Map<String, dynamic> json) => EngineSearchResponse(
    vehicles: (json['vehicles'] as List<dynamic>)
        .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
        .toList(),
  );
}