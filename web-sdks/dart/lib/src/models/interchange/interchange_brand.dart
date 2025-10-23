class InterchangeBrand {
  InterchangeBrand({required this.name, required this.id});
  final String name;
  final String id;

  factory InterchangeBrand.fromJson(Map<String, dynamic> json) {
    return InterchangeBrand(name: json['brand_name'], id: json['brand_id']);
  }
}
