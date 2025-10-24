class SuggestedPart {
  SuggestedPart({
    required this.brandName,
    required this.partNumber,
    required this.description,
    required this.categoryName,
    required this.subcategoryName,
    this.catalogSku,
    this.memberSku,
    this.imagePathThumb,
    this.imagePathMedium,
  });
  final String brandName;
  final String partNumber;
  final String description;
  final String categoryName;
  final String subcategoryName;
  final int? catalogSku;
  final int? memberSku;
  final String? imagePathThumb;
  final String? imagePathMedium;

  factory SuggestedPart.fromJson(Map<String, dynamic> json) {
    return SuggestedPart(
      brandName: json['fapbrandname'] ?? '',
      partNumber: json['partnumber'] ?? '',
      description: json['parttermname'] ?? '',
      categoryName: json['category_name'] ?? '',
      subcategoryName: json['subcategory_name'] ?? '',
      catalogSku: json['sku'] == 0 ? null : json['sku'],
      memberSku: json['member_item_id'],
      imagePathThumb: json['image_path_thumb'] as String?,
      imagePathMedium: json['image_path_medium'] as String?,
    );
  }
}
