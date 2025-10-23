import 'interchange_brand.dart';
import 'interchange_part_type.dart';
import 'interchange_part.dart';

class InterchangeModel {
  InterchangeModel({required this.brands, this.partTypes, required this.parts});

  final List<InterchangeBrandModel> brands;
  final List<InterchangePartTypeModel>? partTypes;
  final List<InterchangePartModel> parts;

  factory InterchangeModel.fromJson(Map<String, dynamic> json) {
    return InterchangeModel(
      brands: List<InterchangeBrandModel>.from(
        json['brands'].map((brands) => InterchangeBrandModel.fromJson(brands)),
      ),
      partTypes: json['terms'] != null
          ? List<InterchangePartTypeModel>.from(
              json['terms'].map(
                (partType) => InterchangePartTypeModel.fromJson(partType),
              ),
            )
          : null,
      parts: List<InterchangePartModel>.from(
        json['interchanges'].map(
          (interchange) => InterchangePartModel.fromJson(interchange),
        ),
      ),
    );
  }
}
