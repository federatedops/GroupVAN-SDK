import '../catalogs.dart';
import '../shared.dart';

class VehicleAndPartType {
  final Vehicle vehicle;
  final PartType partType;
  final List<Map<String, dynamic>> vehicleHighlights;
  final List<Map<String, dynamic>> partTypeHighlights;

  VehicleAndPartType({
    required this.vehicle,
    required this.partType,
    this.vehicleHighlights = const [],
    this.partTypeHighlights = const [],
  });

  factory VehicleAndPartType.fromJson(Map<String, dynamic> json) => VehicleAndPartType(
    vehicle: Vehicle.fromJson(json['vehicle']),
    partType: PartType.fromJson(json['part_type']),
    vehicleHighlights: (json['vehicle_highlights'] as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [],
    partTypeHighlights: (json['part_type_highlights'] as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'vehicle': vehicle.toJson(),
    'part_type': partType.toJson(),
    'vehicle_highlights': vehicleHighlights,
    'part_type_highlights': partTypeHighlights,
  };
}