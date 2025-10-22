class Attribute {
  final String name;
  final int id;

  const Attribute({required this.name, required this.id});

  factory Attribute.fromJson(Map<String, dynamic> json) =>
      Attribute(name: json['name'], id: json['id']);
}
