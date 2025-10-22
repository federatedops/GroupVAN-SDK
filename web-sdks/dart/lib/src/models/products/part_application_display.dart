class PartApplicationDisplay {
  final String name;
  final String value;

  const PartApplicationDisplay({required this.name, required this.value});

  factory PartApplicationDisplay.fromJson(Map<String, dynamic> json) =>
      PartApplicationDisplay(name: json['name'], value: json['value']);
}
