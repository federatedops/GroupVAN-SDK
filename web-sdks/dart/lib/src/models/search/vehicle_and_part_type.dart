import '../catalogs.dart';
import '../shared.dart';

class VehicleAndPartType {
  final Vehicle vehicle;
  final PartType partType;

  VehicleAndPartType({required this.vehicle, required this.partType});

  factory VehicleAndPartType.fromJson(Map<String, dynamic> json) => VehicleAndPartType(
    vehicle: Vehicle.fromJson(json['vehicle']),
    partType: PartType.fromJson(json['part_type']),
  );

  Map<String, dynamic> toJson() => {
    'vehicle': vehicle.toJson(),
    'part_type': partType.toJson(),
  };
}