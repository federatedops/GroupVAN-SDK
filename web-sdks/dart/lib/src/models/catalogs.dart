import 'package:flutter/material.dart' show Colors, Color;

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

class PartApplicationDisplay {
  final String name;
  final String value;

  const PartApplicationDisplay({required this.name, required this.value});

  factory PartApplicationDisplay.fromJson(Map<String, dynamic> json) =>
      PartApplicationDisplay(name: json['name'], value: json['value']);
}

class PartApplication {
  final int id;
  final bool assets;
  final List<PartApplicationDisplay> displays;

  const PartApplication({
    required this.id,
    required this.assets,
    required this.displays,
  });

  factory PartApplication.fromJson(Map<String, dynamic> json) =>
      PartApplication(
        id: json['id'],
        assets: json['assets'],
        displays: json['displays'],
      );
}

class Part implements Comparable {
  final int sku;
  final int rank;
  final int tier;
  final String mfrCode;
  final String mfrName;
  final String autoCareBrandId;
  final String partNumber;
  final int? parentPartTypeId;
  final int partTypeId;
  final String partTypeName;
  final bool buyersGuide;
  final bool productInfo;
  final bool interchange;
  final List<PartApplication> applications;

  const Part({
    required this.sku,
    required this.rank,
    required this.tier,
    required this.mfrCode,
    required this.mfrName,
    required this.autoCareBrandId,
    required this.partNumber,
    this.parentPartTypeId,
    required this.partTypeId,
    required this.partTypeName,
    required this.buyersGuide,
    required this.productInfo,
    required this.interchange,
    required this.applications,
  });

  factory Part.fromJson(Map<String, dynamic> json) => Part(
    sku: json['sku'],
    rank: json['rank'],
    tier: json['tier'],
    mfrCode: json['mfr_code'],
    mfrName: json['mfr_name'],
    autoCareBrandId: json['auto_care_brand_id'],
    partNumber: json['part_number'],
    parentPartTypeId: json['parent_part_type_id'],
    partTypeId: json['part_type_id'],
    partTypeName: json['part_type_name'],
    buyersGuide: json['buyers_guide'],
    productInfo: json['product_info'],
    interchange: json['interchange'],
    applications: json['applications'],
  );

  @override
  int compareTo(other) {
    int tierCompare = tier.compareTo(other.tier);
    if (tierCompare != 0) return tierCompare;

    int rankCompare = rank.compareTo(other.rank);
    if (rankCompare != 0) return rankCompare;

    int mfrCodeCompare = mfrCode.compareTo(other.mfrCode);
    if (mfrCodeCompare != 0) return mfrCodeCompare;

    int partTypeNameCompare = partTypeName.compareTo(other.partTypeName);
    if (partTypeNameCompare != 0) return partTypeNameCompare;

    return partNumber.compareTo(other.partNumber);
  }

  String perCarQuantity() {
    return '1';
  }

  Color quantityAtLocationColor() {
    return Colors.grey;
  }

  String quantityAtLocationText() {
    return '100+';
  }

  double cost() {
    return 1.0;
  }

  double list() {
    return 10.0;
  }

  double core() {
    return 5.0;
  }
}

class Brand {
  final String code;
  final String name;

  const Brand({required this.code, required this.name});

  factory Brand.fromJson(Map<String, dynamic> json) =>
      Brand(code: json['code'], name: json['name']);
}

class Attribute {
  final String name;
  final int id;

  const Attribute({required this.name, required this.id});

  factory Attribute.fromJson(Map<String, dynamic> json) =>
      Attribute(name: json['name'], id: json['id']);
}

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

/// Product listing response
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
