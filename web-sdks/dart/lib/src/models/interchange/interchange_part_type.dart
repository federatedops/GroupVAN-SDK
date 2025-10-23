class InterchangePartTypeModel {
  InterchangePartTypeModel({required this.name, required this.id});
  final String name;
  final int id;

  factory InterchangePartTypeModel.fromJson(Map<String, dynamic> json) {
    return InterchangePartTypeModel(
      name: json['partterm_name'],
      id: json['partterm_id'],
    );
  }
}
