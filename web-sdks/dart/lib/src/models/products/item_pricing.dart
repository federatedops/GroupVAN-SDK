import './item_pricing_location.dart';

class ItemPricingModel {
  const ItemPricingModel({
    required this.comment,
    required this.id,
    required this.locations,
    required this.mfrCode,
    required this.mfrDescription,
    required this.partDescription,
    required this.partNumber,
    required this.statusCode,
  });
  final String comment;
  final String id;
  final List<ItemPricingLocationModel> locations;
  final String mfrCode;
  final String mfrDescription;
  final String? partDescription;
  final String partNumber;
  final int statusCode;

  factory ItemPricingModel.fromJson(Map<String, dynamic> json) {
    return ItemPricingModel(
      comment: json['comment'],
      id: json['id'],
      locations: List<ItemPricingLocationModel>.from(
        json['locations'].map(
          (location) => ItemPricingLocationModel.fromJson(location),
        ),
      ),
      mfrCode: json['mfr_code'],
      mfrDescription: json['mfr_description'],
      partDescription: json['part_description'],
      partNumber: json['part_number'],
      statusCode: json['status_code'],
    );
  }
}

class ItemPricingRequestModel {
  const ItemPricingRequestModel({
    required this.id,
    required this.mfrCode,
    required this.partNumber,
  });
  final String id;
  final String mfrCode;
  final String partNumber;

  Map<String, dynamic> toJson() => {
    'id': id,
    'mfr_code': mfrCode,
    'part_number': partNumber,
  };
}
