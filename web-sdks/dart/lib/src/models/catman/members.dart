/// A catalog region belonging to a member.
class CatalogRegion {
  final String regionId;
  final String name;

  const CatalogRegion({required this.regionId, required this.name});

  factory CatalogRegion.fromJson(Map<String, dynamic> json) => CatalogRegion(
    regionId: json['region_id'] as String,
    name: json['name'] as String? ?? '',
  );
}
