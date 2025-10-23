class InterchangePartType {
  InterchangePartType({required this.name, required this.id});
  final String name;
  final int id;

  factory InterchangePartType.fromJson(Map<String, dynamic> json) {
    return InterchangePartType(
      name: json['partterm_name'],
      id: json['partterm_id'],
    );
  }
}
