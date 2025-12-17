enum DisplayTier { primary, secondary }

enum CatalogType {
  supply,
  vehicle;

  static CatalogType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'supply':
        return CatalogType.supply;
      case 'vehicle':
        return CatalogType.vehicle;
      default:
        // Default to supply for unknown types
        return CatalogType.supply;
    }
  }

  @override
  String toString() {
    switch (this) {
      case CatalogType.supply:
        return 'supply';
      case CatalogType.vehicle:
        return 'vehicle';
    }
  }

  String get displayName {
    switch (this) {
      case CatalogType.supply:
        return 'Supply Catalog';
      case CatalogType.vehicle:
        return 'Vehicle Catalog';
    }
  }
}

/// Catalog models for the V3 Catalogs API
class Catalog {
  final int id;
  final String name;
  final CatalogType type;

  const Catalog({required this.id, required this.name, required this.type});

  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
    id: json['id'],
    name: json['name'],
    type: CatalogType.fromString(json['type']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.toString(),
  };

  Catalog copyWith({int? id, String? name, CatalogType? type}) => Catalog(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Catalog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Catalog(id: $id, name: $name, type: $type)';
  }
}

/// Part type information used in categories
class PartType {
  final DisplayTier? displayTier;
  final int id;
  final String name;
  final int? popularityGroup;
  final List<String> slangList;

  const PartType({
    required this.displayTier,
    required this.id,
    required this.name,
    required this.popularityGroup,
    required this.slangList,
  });

  factory PartType.fromJson(Map<String, dynamic> json) => PartType(
    displayTier: json['display_tier'] != null
        ? DisplayTier.values.byName(json['display_tier'])
        : null,
    id: json['id'],
    name: json['name'],
    popularityGroup: json['popularity_group'],
    slangList: List<String>.from(json['slang_list'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'display_tier': displayTier,
    'id': id,
    'name': name,
    'popularity_group': popularityGroup,
    'slang_list': slangList,
  };
}

/// Vehicle category information
class VehicleCategory {
  final DisplayTier displayTier;
  final int id;
  final String name;
  final List<PartType> partTypes;

  const VehicleCategory({
    required this.displayTier,
    required this.id,
    required this.name,
    required this.partTypes,
  });

  factory VehicleCategory.fromJson(Map<String, dynamic> json) =>
      VehicleCategory(
        displayTier: DisplayTier.values.byName(json['display_tier']),
        id: json['id'],
        name: json['name'],
        partTypes: (json['part_types'] as List<dynamic>)
            .map((pt) => PartType.fromJson(pt as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'display_tier': displayTier.name,
    'id': id,
    'name': name,
    'part_types': partTypes.map((pt) => pt.toJson()).toList(),
  };
}

class TopCategory {
  final int id;
  final String name;

  const TopCategory({required this.id, required this.name});

  factory TopCategory.fromJson(Map<String, dynamic> json) =>
      TopCategory(id: json['id'], name: json['name']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// Supply subcategory information
class SupplySubcategory {
  final int id;
  final String name;

  const SupplySubcategory({required this.id, required this.name});

  factory SupplySubcategory.fromJson(Map<String, dynamic> json) =>
      SupplySubcategory(id: json['id'], name: json['name']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// Supply category information
class SupplyCategory {
  final int id;
  final String name;
  final List<SupplySubcategory> subcategories;

  const SupplyCategory({
    required this.id,
    required this.name,
    required this.subcategories,
  });

  factory SupplyCategory.fromJson(Map<String, dynamic> json) => SupplyCategory(
    id: json['id'],
    name: json['name'],
    subcategories: (json['subcategories'] as List<dynamic>)
        .map((sc) => SupplySubcategory.fromJson(sc as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subcategories': subcategories.map((sc) => sc.toJson()).toList(),
  };
}

/// Application asset information
class ApplicationAsset {
  final int applicationId;
  final String type;
  final String language;
  final String uri;

  const ApplicationAsset({
    required this.applicationId,
    required this.type,
    required this.language,
    required this.uri,
  });

  factory ApplicationAsset.fromJson(Map<String, dynamic> json) =>
      ApplicationAsset(
        applicationId: json['application_id'],
        type: json['type'],
        language: json['language'],
        uri: json['uri'],
      );

  Map<String, dynamic> toJson() => {
    'application_id': applicationId,
    'type': type,
    'language': language,
    'uri': uri,
  };
}

/// Application assets request
class ApplicationAssetsRequest {
  final List<int> applicationIds;
  final String? languageCode;

  const ApplicationAssetsRequest({
    required this.applicationIds,
    this.languageCode,
  });

  Map<String, dynamic> toJson() => {
    'application_ids': applicationIds.join(','),
    if (languageCode != null) 'language_code': languageCode,
  };
}

/// Part type for product requests
class PartTypeRequest {
  final int id;
  final String name;

  const PartTypeRequest({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// Product listing request
class ProductListingRequest {
  final int? vehicleIndex;
  final List<int> itemIds;
  final int showAll;

  const ProductListingRequest({
    required this.vehicleIndex,
    required this.itemIds,
    required this.showAll,
  });

  Map<String, dynamic> toJson() => {
    'vehicle_index': vehicleIndex,
    'item_ids': itemIds,
    'show_all': showAll,
  };
}
