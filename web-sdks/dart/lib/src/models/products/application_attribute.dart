class ApplicationAttribute {
  ApplicationAttribute({required this.name, required this.value});

  final String name;
  final String value;

  factory ApplicationAttribute.fromJson(Map<String, dynamic> json) =>
      ApplicationAttribute(name: json['name'], value: json['value']);
}
