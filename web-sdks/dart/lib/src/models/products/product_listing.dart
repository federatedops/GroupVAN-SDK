import 'part.dart';
import 'brand.dart';
import 'attribute_family.dart';

class ProductListing {
  final List<Part> parts;
  final List<Brand> brands;
  final List<String> shadows;
  final int partTypeId;
  final String partTypeName;
  final List<AttributeFamily> attributeFamilies;

  const ProductListing({
    required this.parts,
    required this.brands,
    required this.shadows,
    required this.partTypeId,
    required this.partTypeName,
    required this.attributeFamilies,
  });

  factory ProductListing.fromJson(Map<String, dynamic> json) => ProductListing(
    parts: (json['parts'] as List<dynamic>)
        .map((p) => Part.fromJson(p as Map<String, dynamic>))
        .toList(),
    brands: (json['brands'] as List<dynamic>)
        .map((b) => Brand.fromJson(b as Map<String, dynamic>))
        .toList(),
    shadows: (json['shadows'] as List<dynamic>)
        .map((s) => s as String)
        .toList(),
    partTypeId: json['part_type_id'],
    partTypeName: json['part_type_name'],
    attributeFamilies: (json['attribute_families'] as List<dynamic>)
        .map((af) => AttributeFamily.fromJson(af as Map<String, dynamic>))
        .toList(),
  );
}
