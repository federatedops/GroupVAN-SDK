import 'package:flutter/material.dart' show Colors, Color;
import 'part_application.dart';
import './item_pricing.dart';
import '../assets/asset.dart';

class Part implements Comparable {
  final int id;
  final String itemType;
  final int sku;
  final int rank;
  final int tier;
  final String mfrCode;
  final String mfrName;
  final String? autoCareBrandId;
  final String partNumber;
  final int? parentPartTypeId;
  final int? partTypeId;
  final String? partTypeName;
  final bool buyersGuide;
  final bool primaryImageExists;
  final bool secondaryImageExists;
  final bool documentExists;
  final bool spinExists;
  final bool attributeExists;
  final bool interchange;
  final String? memberNote;
  final List<PartApplication> applications;
  final String? categoryName;
  final String? subcategoryName;
  Asset? assets;
  ItemPricing? pricing;
  List<Part> equivalents;
  List<Part> alternates;
  List<Part> supercessions;

  Part({
    required this.id,
    required this.itemType,
    required this.sku,
    required this.rank,
    required this.tier,
    required this.mfrCode,
    required this.mfrName,
    this.autoCareBrandId,
    required this.partNumber,
    this.parentPartTypeId,
    this.partTypeId,
    this.partTypeName,
    required this.buyersGuide,
    required this.primaryImageExists,
    required this.secondaryImageExists,
    required this.documentExists,
    required this.spinExists,
    required this.attributeExists,
    required this.interchange,
    this.memberNote,
    required this.applications,
    this.categoryName,
    this.subcategoryName,
    this.assets,
    this.pricing,
    List<Part>? equivalents,
    List<Part>? alternates,
    List<Part>? supercessions,
  }) : equivalents = equivalents ?? [],
       alternates = alternates ?? [],
       supercessions = supercessions ?? [];

  factory Part.fromJson(Map<String, dynamic> json) => Part(
    id: json['id'],
    itemType: json['item_type'],
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
    primaryImageExists: json['primary_image_exists'],
    secondaryImageExists: json['secondary_image_exists'],
    documentExists: json['document_exists'],
    spinExists: json['spin_exists'],
    attributeExists: json['attribute_exists'],
    interchange: json['interchange'],
    memberNote: json['member_note'],
    applications: ((json['applications'] as List<dynamic>?) ?? [])
        .map((a) => PartApplication.fromJson(a as Map<String, dynamic>))
        .toList(),
    categoryName: json['category_name'],
    subcategoryName: json['subcategory_name'],
    assets: json['asset'] != null
        ? Asset.fromJson(json['asset'] as Map<String, dynamic>)
        : null,
    pricing: json['pricing'] != null
        ? ItemPricing.fromJson(json['pricing'] as Map<String, dynamic>)
        : null,
  );

  @override
  int compareTo(other) {
    int tierCompare = tier.compareTo(other.tier);
    if (tierCompare != 0) return tierCompare;

    int rankCompare = rank.compareTo(other.rank);
    if (rankCompare != 0) return rankCompare;

    int mfrCodeCompare = mfrCode.compareTo(other.mfrCode);
    if (mfrCodeCompare != 0) return mfrCodeCompare;

    int partTypeNameCompare = (partTypeName ?? '').compareTo(
      other.partTypeName ?? '',
    );
    if (partTypeNameCompare != 0) return partTypeNameCompare;

    return partNumber.compareTo(other.partNumber);
  }

  String perCarQuantity() {
    for (final application in applications) {
      for (final display in application.displays) {
        if (display.name == 'Qty') {
          return display.value;
        }
      }
    }
    return "1";
  }

  Color quantityAtLocationColor() {
    Color color = Colors.grey;

    double totalQuantityAvailable = pricing!.locations
        .map((location) => location.quantityAvailable)
        .reduce((value, element) => value + element);

    if (totalQuantityAvailable == 0) return color;

    double quantityAtFirstLocation = pricing!.locations
        .where((location) => location.sortOrder == 1)
        .first
        .quantityAvailable;

    color = quantityAtFirstLocation > 0 ? Colors.green : Colors.amber;

    return color;
  }

  String quantityAtLocationText() {
    double totalQuantityAvailable = pricing!.locations
        .where((location) => location.sortOrder == 1)
        .first
        .quantityAvailable;

    return totalQuantityAvailable > 100
        ? '100+'
        : totalQuantityAvailable.toString();
  }

  double cost() {
    return pricing!.locations
        .where((location) => location.sortOrder == 1)
        .first
        .cost;
  }

  double list() {
    return pricing!.locations
        .where((location) => location.sortOrder == 1)
        .first
        .list;
  }

  double? core() {
    return pricing?.locations
        .where((location) => location.sortOrder == 1)
        .first
        .core;
  }
}
