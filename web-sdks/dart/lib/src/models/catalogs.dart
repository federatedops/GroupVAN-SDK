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

/// View type for buyers guide
enum BuyersGuideViewType {
  basic,
  expanded;

  String toJson() => name;
}

/// Request for buyers guide
class BuyersGuideRequest {
  final int? sku;
  final String? partNumber;
  final String? mfrCode;
  final String? memberId;
  final int vehicleGroupTypeId;
  final int? yearId;
  final int? makeId;
  final int? modelId;
  final bool? flat;
  final BuyersGuideViewType? view;

  const BuyersGuideRequest({
    this.sku,
    this.partNumber,
    this.mfrCode,
    this.memberId,
    required this.vehicleGroupTypeId,
    this.yearId,
    this.makeId,
    this.modelId,
    this.flat,
    this.view,
  });

  Map<String, dynamic> toJson() => {
    if (sku != null) 'sku': sku,
    if (partNumber != null) 'part_number': partNumber,
    if (mfrCode != null) 'mfr_code': mfrCode,
    if (memberId != null) 'member_id': memberId,
    'vehicle_group_type_id': vehicleGroupTypeId,
    if (yearId != null) 'year_id': yearId,
    if (makeId != null) 'make_id': makeId,
    if (modelId != null) 'model_id': modelId,
    if (flat != null) 'flat': flat,
    if (view != null) 'view': view!.toJson(),
  };
}

/// Part term in buyers guide vehicle
class BuyersGuidePartTerm {
  final int id;
  final String name;

  const BuyersGuidePartTerm({required this.id, required this.name});

  factory BuyersGuidePartTerm.fromJson(Map<String, dynamic> json) =>
      BuyersGuidePartTerm(
        id: json['partterm_id'],
        name: json['partterm_name'],
      );

  Map<String, dynamic> toJson() => {
    'partterm_id': id,
    'partterm_name': name,
  };
}

/// Vehicle group in buyers guide response
class BuyersGuideGroup {
  final int id;
  final String name;

  const BuyersGuideGroup({required this.id, required this.name});

  factory BuyersGuideGroup.fromJson(Map<String, dynamic> json) =>
      BuyersGuideGroup(
        id: json['vehicle_group_id'],
        name: json['vehicle_group_name'],
      );

  Map<String, dynamic> toJson() => {
    'vehicle_group_id': id,
    'vehicle_group_name': name,
  };
}

/// Make in buyers guide response
class BuyersGuideMake {
  final int id;
  final String name;
  final int rank;
  final String regions;

  const BuyersGuideMake({
    required this.id,
    required this.name,
    required this.rank,
    required this.regions,
  });

  factory BuyersGuideMake.fromJson(Map<String, dynamic> json) =>
      BuyersGuideMake(
        id: json['make_id'],
        name: json['make_name'],
        rank: json['make_rank'],
        regions: json['make_regions'],
      );

  Map<String, dynamic> toJson() => {
    'make_id': id,
    'make_name': name,
    'make_rank': rank,
    'make_regions': regions,
  };
}

/// Model in buyers guide response
class BuyersGuideModel {
  final int id;
  final String name;
  final String regions;

  const BuyersGuideModel({
    required this.id,
    required this.name,
    required this.regions,
  });

  factory BuyersGuideModel.fromJson(Map<String, dynamic> json) =>
      BuyersGuideModel(
        id: json['model_id'],
        name: json['model_name'],
        regions: json['model_regions'],
      );

  Map<String, dynamic> toJson() => {
    'model_id': id,
    'model_name': name,
    'model_regions': regions,
  };
}

/// Year in buyers guide response
class BuyersGuideYear {
  final int id;
  final String name;
  final String regions;

  const BuyersGuideYear({
    required this.id,
    required this.name,
    required this.regions,
  });

  factory BuyersGuideYear.fromJson(Map<String, dynamic> json) =>
      BuyersGuideYear(
        id: json['year_id'],
        name: json['year_name'],
        regions: json['year_regions'],
      );

  Map<String, dynamic> toJson() => {
    'year_id': id,
    'year_name': name,
    'year_regions': regions,
  };
}

/// Vehicle with terms for buyers guide response
class BuyersGuideVehicle {
  final int index;
  final int year;
  final String make;
  final String model;
  final String? engine;
  final List<BuyersGuidePartTerm> terms;

  const BuyersGuideVehicle({
    required this.index,
    required this.year,
    required this.make,
    required this.model,
    this.engine,
    required this.terms,
  });

  factory BuyersGuideVehicle.fromJson(Map<String, dynamic> json) =>
      BuyersGuideVehicle(
        index: json['index'],
        year: json['year'],
        make: json['make'],
        model: json['model'],
        engine: json['engine'],
        terms: (json['terms'] as List<dynamic>?)
                ?.map(
                  (t) => BuyersGuidePartTerm.fromJson(t as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
    'index': index,
    'year': year,
    'make': make,
    'model': model,
    if (engine != null) 'engine': engine,
    'terms': terms.map((t) => t.toJson()).toList(),
  };
}

/// Response from buyers guide endpoint
class BuyersGuideResponse {
  final List<BuyersGuideGroup> groups;
  final List<BuyersGuideMake> makes;
  final List<BuyersGuideModel> models;
  final List<BuyersGuideVehicle> vehicles;
  final List<BuyersGuideYear> years;

  const BuyersGuideResponse({
    required this.groups,
    required this.makes,
    required this.models,
    required this.vehicles,
    required this.years,
  });

  factory BuyersGuideResponse.fromJson(Map<String, dynamic> json) =>
      BuyersGuideResponse(
        groups: (json['groups'] as List<dynamic>?)
                ?.map(
                  (g) => BuyersGuideGroup.fromJson(g as Map<String, dynamic>),
                )
                .toList() ??
            [],
        makes: (json['makes'] as List<dynamic>?)
                ?.map(
                  (m) => BuyersGuideMake.fromJson(m as Map<String, dynamic>),
                )
                .toList() ??
            [],
        models: (json['models'] as List<dynamic>?)
                ?.map(
                  (m) => BuyersGuideModel.fromJson(m as Map<String, dynamic>),
                )
                .toList() ??
            [],
        vehicles: (json['vehicles'] as List<dynamic>?)
                ?.map(
                  (v) => BuyersGuideVehicle.fromJson(v as Map<String, dynamic>),
                )
                .toList() ??
            [],
        years: (json['years'] as List<dynamic>?)
                ?.map(
                  (y) => BuyersGuideYear.fromJson(y as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
    'groups': groups.map((g) => g.toJson()).toList(),
    'makes': makes.map((m) => m.toJson()).toList(),
    'models': models.map((m) => m.toJson()).toList(),
    'vehicles': vehicles.map((v) => v.toJson()).toList(),
    'years': years.map((y) => y.toJson()).toList(),
  };
}
