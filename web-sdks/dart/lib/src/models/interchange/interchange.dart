import 'interchange_brand.dart';
import 'interchange_part_type.dart';
import 'interchange_part.dart';

class Interchange {
  Interchange({this.brands, this.partTypes, this.parts});

  final List<InterchangeBrand>? brands;
  final List<InterchangePartType>? partTypes;
  final List<InterchangePart>? parts;

  factory Interchange.fromJson(Map<String, dynamic> json) {
    return Interchange(
      brands: json['brands'] != null
          ? List<InterchangeBrand>.from(
              json['brands'].map((brands) => InterchangeBrand.fromJson(brands)),
            )
          : null,
      partTypes: json['terms'] != null
          ? List<InterchangePartType>.from(
              json['terms'].map(
                (partType) => InterchangePartType.fromJson(partType),
              ),
            )
          : null,
      parts: json['interchanges'] != null
          ? List<InterchangePart>.from(
              json['interchanges'].map(
                (interchange) => InterchangePart.fromJson(interchange),
              ),
            )
          : null,
    );
  }
}
