enum DisplayTier { primary, secondary }

/// Catalog models for the V3 Catalogs API
class Catalog {
  final int id;
  final String name;
  final String type;

  const Catalog({required this.id, required this.name, required this.type});

  factory Catalog.fromJson(Map<String, dynamic> json) =>
      Catalog(id: json['id'], name: json['name'], type: json['type']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'type': type};
}

/// Part type information used in categories
class PartType {
  final DisplayTier displayTier;
  final int id;
  final String name;
  final int popularityGroup;
  final List<String> slangList;

  const PartType({
    required this.displayTier,
    required this.id,
    required this.name,
    required this.popularityGroup,
    required this.slangList,
  });

  factory PartType.fromJson(Map<String, dynamic> json) => PartType(
    displayTier: json['display_tier'],
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
  final String displayTier;
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
        displayTier: json['display_tier'],
        id: json['id'],
        name: json['name'],
        partTypes: (json['part_types'] as List<dynamic>)
            .map((pt) => PartType.fromJson(pt as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'display_tier': displayTier,
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

/// Cart item information
class CartItem {
  final String sku;
  final String mfrCode;
  final String partNumber;
  final double list;
  final double cost;
  final double core;
  final int orderQuantity;
  final String locationId;
  final String partDescription;
  final int baseVehicleId;

  const CartItem({
    required this.sku,
    required this.mfrCode,
    required this.partNumber,
    required this.list,
    required this.cost,
    required this.core,
    required this.orderQuantity,
    required this.locationId,
    required this.partDescription,
    required this.baseVehicleId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    sku: json['sku'],
    mfrCode: json['mfr_code'],
    partNumber: json['part_number'],
    list: (json['list'] as num).toDouble(),
    cost: (json['cost'] as num).toDouble(),
    core: (json['core'] as num).toDouble(),
    orderQuantity: json['order_quantity'],
    locationId: json['location_id'],
    partDescription: json['part_description'],
    baseVehicleId: json['base_vehicle_id'],
  );

  Map<String, dynamic> toJson() => {
    'sku': sku,
    'mfr_code': mfrCode,
    'part_number': partNumber,
    'list': list,
    'cost': cost,
    'core': core,
    'order_quantity': orderQuantity,
    'location_id': locationId,
    'part_description': partDescription,
    'base_vehicle_id': baseVehicleId,
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
  final int vehicleIndex;
  final List<int> partTypeIds;

  const ProductListingRequest({
    required this.vehicleIndex,
    required this.partTypeIds,
  });

  Map<String, dynamic> toJson() => {
    'vehicle_index': vehicleIndex,
    'part_type_ids': partTypeIds.join(','),
  };
}
