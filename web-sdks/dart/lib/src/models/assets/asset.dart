class AssetModel {
  const AssetModel({
    required this.images,
    required this.brandLogo,
    required this.sku,
    required this.spinAsset,
  });

  final List<AssetImageModel> images;
  final String brandLogo;
  final int sku;
  final bool spinAsset;

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      images: List<AssetImageModel>.from(
        json['images'].map((image) => AssetImageModel.fromJson(image)),
      ),
      brandLogo: json['logo_file'],
      sku: json['sku'],
      spinAsset: json['spin_exists'] == 0 ? false : true,
    );
  }
}

class AssetImageModel {
  const AssetImageModel({
    required this.primary,
    required this.large,
    required this.medium,
    required this.thumb,
  });

  final bool primary;
  final String large;
  final String medium;
  final String thumb;

  factory AssetImageModel.fromJson(Map<String, dynamic> json) {
    return AssetImageModel(
      primary: json['is_primary'] == 0 ? false : true,
      large: json['large_path'],
      medium: json['medium_path'],
      thumb: json['thumb_path'],
    );
  }
}
