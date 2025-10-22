import 'attribute.dart';

class AttributeFamily {
  final String name;
  final String key;
  final List<Attribute> attributes;

  const AttributeFamily({
    required this.name,
    required this.key,
    required this.attributes,
  });

  factory AttributeFamily.fromJson(Map<String, dynamic> json) =>
      AttributeFamily(
        name: json['name'],
        key: json['key'],
        attributes: json['attributes'],
      );
}
