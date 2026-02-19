import './item_pricing_location.dart';

class ItemPricing {
  const ItemPricing({
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
  final List<ItemPricingLocation> locations;
  final String mfrCode;
  final String mfrDescription;
  final String? partDescription;
  final String partNumber;
  final int statusCode;

  factory ItemPricing.fromJson(Map<String, dynamic> json) {
    return ItemPricing(
      comment: json['comment'],
      id: json['id'],
      locations: List<ItemPricingLocation>.from(
        json['locations'].map(
          (location) => ItemPricingLocation.fromJson(location),
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
