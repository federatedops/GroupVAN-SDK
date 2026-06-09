class MemberCategory {
  final String? name;
  final int subcategoryId;
  final String subcategoryName;
  final List<Map<String, dynamic>> highlights;

  MemberCategory({
    required this.name,
    required this.subcategoryId,
    required this.subcategoryName,
    this.highlights = const [],
  });

  factory MemberCategory.fromJson(Map<String, dynamic> json) => MemberCategory(
    name: json['name'],
    subcategoryId: json['subcategory_id'],
    subcategoryName: json['subcategory_name'],
    highlights: (json['highlights'] as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'subcategory_id': subcategoryId,
    'subcategory_name': subcategoryName,
    'highlights': highlights,
  };
}
