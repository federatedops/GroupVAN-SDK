class InterchangeBrandModel {
  InterchangeBrandModel({required this.name, required this.id});
  final String name;
  final String id;

  factory InterchangeBrandModel.fromJson(Map<String, dynamic> json) {
    return InterchangeBrandModel(
      name: json['brand_name'],
      id: json['brand_id'],
    );
  }
}
