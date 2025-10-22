class Asset {
  const Asset({
    required this.images,
    required this.brandLogo,
    required this.sku,
    required this.spinAsset,
  });

  final List<AssetImage> images;
  final String brandLogo;
  final int sku;
  final bool spinAsset;

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      images: List<AssetImage>.from(
        json['images'].map((image) => AssetImage.fromJson(image)),
      ),
      brandLogo: json['logo_file'],
      sku: json['sku'],
      spinAsset: json['spin_exists'] == 0 ? false : true,
    );
  }
}

class AssetImage {
  const AssetImage({
    required this.primary,
    required this.large,
    required this.medium,
    required this.thumb,
  });

  final bool primary;
  final String large;
  final String medium;
  final String thumb;

  factory AssetImage.fromJson(Map<String, dynamic> json) {
    return AssetImage(
      primary: json['is_primary'] == 0 ? false : true,
      large: json['large_path'],
      medium: json['medium_path'],
      thumb: json['thumb_path'],
    );
  }
}
