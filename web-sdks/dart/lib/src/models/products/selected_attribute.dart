/// An attribute option pre-selected by the server from the vehicle's VIN decode.
class SelectedAttribute {
  final String family;
  final String key;
  final String name;
  final int id;

  const SelectedAttribute({
    required this.family,
    required this.key,
    required this.name,
    required this.id,
  });

  factory SelectedAttribute.fromJson(Map<String, dynamic> json) =>
      SelectedAttribute(
        family: json['family'],
        key: json['key'],
        name: json['name'],
        id: json['id'],
      );
}
