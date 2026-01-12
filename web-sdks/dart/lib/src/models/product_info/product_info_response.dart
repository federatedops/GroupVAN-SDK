import '../assets/spin_asset.dart';

class Document {
  final String? type;
  final String? title;
  final String? format;
  final String? language;
  final String? url;

  const Document({this.type, this.title, this.format, this.language, this.url});

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      type: json['type'],
      title: json['title'],
      format: json['format'],
      language: json['lang'],
      url: json['url'],
    );
  }
}

class InfoAttribute {
  final String? name;
  final String? value;
  final int? group;
  final int? sequence;

  const InfoAttribute({this.name, this.value, this.group, this.sequence});

  factory InfoAttribute.fromJson(Map<String, dynamic> json) {
    return InfoAttribute(
      name: json['name'],
      value: json['value'],
      group: json['group'],
      sequence: json['sequence'],
    );
  }
}

class ProductInfoResponse {
  final String? logo;
  final String? brandId;
  final String? brandName;
  final String? parentId;
  final String? parentName;
  final int? partTypeId;
  final String? mfrCode;
  final String? partNumber;
  final String? stripPart;
  final List<SpinAsset>? spinAssets;
  final List<Document>? documents;
  final List<InfoAttribute>? attributes;

  const ProductInfoResponse({
    this.logo,
    this.brandId,
    this.brandName,
    this.parentId,
    this.parentName,
    this.partTypeId,
    this.mfrCode,
    this.partNumber,
    this.stripPart,
    this.spinAssets,
    this.documents,
    this.attributes,
  });

  factory ProductInfoResponse.fromJson(Map<String, dynamic> json) {
    return ProductInfoResponse(
      logo: json['logo'],
      brandId: json['brand_id'],
      brandName: json['brand_name'],
      parentId: json['parent_id'],
      parentName: json['parent_name'],
      partTypeId: json['part_type_id'],
      mfrCode: json['mfr_code'],
      partNumber: json['part_number'],
      stripPart: json['strip_part'],
      spinAssets: (json['spin_assets'] as List?)
          ?.map((spinAsset) => SpinAsset.fromJson(spinAsset))
          .toList(),
      documents: (json['documents'] as List?)
          ?.map((document) => Document.fromJson(document))
          .toList(),
      attributes: (json['attributes'] as List?)
          ?.map((attribute) => InfoAttribute.fromJson(attribute))
          .toList(),
    );
  }
}
