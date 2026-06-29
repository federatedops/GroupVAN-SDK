/// Catman custom catalogs models: member catalogs, import rows, and catalog data.
library;

import '../../auth/auth_models.dart' show UserType;

/// A member's custom catalog.
class CustomCatalog {
  final int id;
  final String name;
  final List<UserType> userTypes;
  final bool hideFilter;

  const CustomCatalog({
    required this.id,
    required this.name,
    required this.userTypes,
    required this.hideFilter,
  });

  factory CustomCatalog.fromJson(Map<String, dynamic> json) => CustomCatalog(
    id: json['id'] as int,
    name: json['name'] as String,
    userTypes: (json['user_types'] as List<dynamic>? ?? const [])
        .map((t) => UserType.fromValue(t as int))
        .toList(),
    hideFilter: json['hide_filter'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'user_types': userTypes.map((t) => t.value).toList(),
    'hide_filter': hideFilter,
  };
}

/// Fields to create a [CustomCatalog]. [userTypes] must contain at least one
/// value.
class CatalogCreateRequest {
  final String name;
  final List<UserType> userTypes;
  final bool hideFilter;

  const CatalogCreateRequest({
    required this.name,
    required this.userTypes,
    this.hideFilter = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'user_types': userTypes.map((t) => t.value).toList(),
    'hide_filter': hideFilter,
  };
}

/// Fields to update on a [CustomCatalog]. Omitted fields are left unchanged
/// (PATCH).
///
/// When [userTypes] is provided it must contain at least one value.
class CatalogUpdateRequest {
  final String? name;
  final List<UserType>? userTypes;
  final bool? hideFilter;

  const CatalogUpdateRequest({this.name, this.userTypes, this.hideFilter});

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (userTypes != null)
      'user_types': userTypes!.map((t) => t.value).toList(),
    if (hideFilter != null) 'hide_filter': hideFilter,
  };
}

/// A single commodity row to import into a catalog.
class CatalogImportRow {
  final String lineCode;
  final String brandName;
  final String partNumber;
  final String partDescription;
  final String? category;
  final String? subCategory;
  final String? imageFileName1;
  final String? imageFileName2;
  final String? imageFileName3;
  final String? imageFileName4;

  const CatalogImportRow({
    required this.lineCode,
    required this.brandName,
    required this.partNumber,
    required this.partDescription,
    this.category,
    this.subCategory,
    this.imageFileName1,
    this.imageFileName2,
    this.imageFileName3,
    this.imageFileName4,
  });

  Map<String, dynamic> toJson() => {
    'line_code': lineCode,
    'brand_name': brandName,
    'part_number': partNumber,
    'part_description': partDescription,
    'category': category,
    'sub_category': subCategory,
    'image_file_name_1': imageFileName1,
    'image_file_name_2': imageFileName2,
    'image_file_name_3': imageFileName3,
    'image_file_name_4': imageFileName4,
  };
}

/// Request to import commodity [rows] into the catalog [catalogId].
/// [rows] must contain at least one row.
class CatalogImportRequest {
  final int catalogId;
  final List<CatalogImportRow> rows;

  const CatalogImportRequest({required this.catalogId, required this.rows});

  Map<String, dynamic> toJson() => {
    'catalog_id': catalogId,
    'rows': rows.map((r) => r.toJson()).toList(),
  };
}

/// Result of a catalog import.
class CatalogImportResult {
  final String status;
  final int? importId;
  final int rowsImported;

  const CatalogImportResult({
    required this.status,
    this.importId,
    required this.rowsImported,
  });

  factory CatalogImportResult.fromJson(Map<String, dynamic> json) =>
      CatalogImportResult(
        status: json['status'] as String,
        importId: json['import_id'] as int?,
        rowsImported: json['rows_imported'] as int,
      );
}

/// A single part within a catalog's part type.
class CommodityPart {
  final int id;
  final String lineCode;
  final String partNumber;
  final String description;

  const CommodityPart({
    required this.id,
    required this.lineCode,
    required this.partNumber,
    required this.description,
  });

  factory CommodityPart.fromJson(Map<String, dynamic> json) => CommodityPart(
    id: json['id'] as int,
    lineCode: json['line_code'] as String,
    partNumber: json['part_number'] as String,
    description: json['description'] as String,
  );
}

/// A part type grouping its parts.
class CommoditySubCategory {
  final int id;
  final String name;
  final String description;
  final List<CommodityPart> commodityParts;

  const CommoditySubCategory({
    required this.id,
    required this.name,
    required this.description,
    this.commodityParts = const [],
  });

  factory CommoditySubCategory.fromJson(Map<String, dynamic> json) =>
      CommoditySubCategory(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String,
        commodityParts: (json['commodity_parts'] as List<dynamic>? ?? const [])
            .map((p) => CommodityPart.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

/// A category grouping its part types.
class CommodityCategory {
  final int id;
  final String name;
  final String description;
  final List<CommoditySubCategory> subCategories;

  const CommodityCategory({
    required this.id,
    required this.name,
    required this.description,
    this.subCategories = const [],
  });

  factory CommodityCategory.fromJson(Map<String, dynamic> json) =>
      CommodityCategory(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String,
        subCategories: (json['sub_categories'] as List<dynamic>? ?? const [])
            .map((c) => CommoditySubCategory.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

/// A catalog's contents as categories -> part types -> parts.
class CatalogData {
  final List<CommodityCategory> categories;

  const CatalogData({this.categories = const []});

  factory CatalogData.fromJson(Map<String, dynamic> json) => CatalogData(
    categories: (json['categories'] as List<dynamic>? ?? const [])
        .map((c) => CommodityCategory.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}
