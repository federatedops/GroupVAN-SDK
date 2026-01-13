import '../catalogs.dart';
import '../products/part.dart';
import 'member_category.dart';
import 'vehicle_and_part_type.dart';

/// Omni search response
class OmniSearchResponse {
  final List<PartType> partTypes;
  final List<Part> parts;
  final List<VehicleAndPartType> vehicles;
  final List<MemberCategory> memberCategories;

  const OmniSearchResponse({
    required this.partTypes,
    required this.parts,
    required this.vehicles,
    required this.memberCategories,
  });

  factory OmniSearchResponse.fromJson(Map<String, dynamic> json) =>
      OmniSearchResponse(
        partTypes: ((json['part_types'] as List<dynamic>?) ?? [])
            .map((item) => PartType.fromJson(item as Map<String, dynamic>))
            .toList(),
        parts: ((json['parts'] as List<dynamic>?) ?? [])
            .map((item) => Part.fromJson(item as Map<String, dynamic>))
            .toList(),
        vehicles: ((json['vehicles'] as List<dynamic>?) ?? [])
            .map((item) => VehicleAndPartType.fromJson(item as Map<String, dynamic>))
            .toList(),
        memberCategories: ((json['member_categories'] as List<dynamic>?) ?? [])
            .map(
              (item) => MemberCategory.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'part_types': partTypes.map((pt) => pt.toJson()).toList(),
    'parts': parts,
    'vehicles': vehicles.map((v) => v.toJson()).toList(),
  };
}
