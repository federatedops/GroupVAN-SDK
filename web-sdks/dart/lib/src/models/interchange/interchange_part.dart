class InterchangePartModel {
  InterchangePartModel({
    this.id,
    this.name,
    this.alternateName,
    this.mfrCode,
    required this.partNumber,
    this.partTypeId,
    this.partTypeName,
    required this.partTypeSort,
    required this.primarySort,
    required this.sourceSort,
    this.sku,
  });
  final String? id;
  final String? name;
  final String? alternateName;
  final String? mfrCode;
  final String partNumber;
  final int? partTypeId;
  final String? partTypeName;
  final int partTypeSort;
  final int primarySort;
  final int sourceSort;
  final int? sku;

  factory InterchangePartModel.fromJson(Map<String, dynamic> json) {
    return InterchangePartModel(
      id: json['brand_id'],
      name: json['brand_name'],
      alternateName: json['alternate_brand_name'],
      mfrCode: json['mfrcode'],
      partNumber: json['part_number'],
      partTypeId: json['partterm_id'],
      partTypeName: json['partterm_name'],
      partTypeSort: json['partterm_sort'],
      primarySort: json['primary_sort'],
      sourceSort: json['source_sort'],
      sku: json['sku'],
    );
  }
}
