import '../shared.dart';
import 'suggested_part.dart';

class SearchResponse {
  SearchResponse({
    required this.partsCount,
    required this.vehiclesCount,
    this.parts,
    this.vehicles,
  });
  final int partsCount;
  final int vehiclesCount;
  final List<SuggestedPart>? parts;
  final List<Vehicle>? vehicles;

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> partsJson = json['parts'] != null
        ? List<Map<String, dynamic>>.from(json['parts'])
        : [];
    List<Map<String, dynamic>> vehiclesJson = json['vehicles'] != null
        ? List<Map<String, dynamic>>.from(json['vehicles'])
        : [];

    return SearchResponse(
      partsCount: json['parts_count'] ?? 0,
      vehiclesCount: json['vehicles_count'] ?? 0,
      parts: partsJson.isNotEmpty
          ? List<SuggestedPart>.from(
              partsJson.map((part) => SuggestedPart.fromJson(part)),
            )
          : null,
      vehicles: vehiclesJson.isNotEmpty
          ? List<Vehicle>.from(
              vehiclesJson.map((vehicle) => Vehicle.fromJson(vehicle)),
            )
          : null,
    );
  }

  factory SearchResponse.empty() {
    return SearchResponse(partsCount: 0, vehiclesCount: 0);
  }
}
