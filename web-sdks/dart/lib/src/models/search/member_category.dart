class MemberCategory {
  final String? name;
  final int subcategoryId;
  final String subcategoryName;

  MemberCategory({
    required this.name,
    required this.subcategoryId,
    required this.subcategoryName,
  });

  factory MemberCategory.fromJson(Map<String, dynamic> json) => MemberCategory(
    name: json['name'],
    subcategoryId: json['subcategory_id'],
    subcategoryName: json['subcategory_name'],
  );
}
